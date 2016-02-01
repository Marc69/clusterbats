#!/user/env/bin/bats
load configuration

@test "1.2.0.a We can configure the switch" {
  chtab node=switch hosts.ip=${SWITCH}  #10.141.253.1

  echo "${SWITCH_TABLE}" > /tmp/switch.csv
  tabrestore /tmp/switch.csv

  makehosts switch
  makedns switch || true

  #------------------------------------------
  # do a switch ping test before proceeding
  #------------------------------------------
  ping -c 1 switch &> /dev/null 
}

@test "1.2.1 We can discover compute nodes" {
  if [ -e "/tftpboot/xcat/xnba/nodes/node001" ]; then
    skip
  fi
  nodeadd ${NODES} groups=compute
  makehosts compute
  makedns compute > /dev/null || true
  rpower compute reset

  for i in {1..100} ; do
    for NODE in $(expand ${NODES}); do
      if ! lsdef -t node ${NODE} | grep standingby ; then
        sleep 10 
        continue 2;
      fi
    done
    # trigger the timeout condition
    [[ "$i" -ne 100 ]] 
    sleep 5
    break
  done
}

@test "1.2.5 We can assign the containers to the default virtual cluster a" {
  if lsdef -t node node001 | grep booted; then
    skip
  fi

  CPUs=$(lsdef -t node -o node001 -i cpucount | grep cpucount | cut -d= -f2)
  cat > /cluster/vc-a/etc/slurm/slurm-nodes.conf << EOF
NodeName=$CONTAINERS CPUs=${CPUs} State=UNKNOWN
PartitionName=containers State=UP Nodes=$CONTAINERS Default=YES
EOF

  nodeadd $CONTAINERS groups=vc-a,hw-default
  makehosts vc-a
  makedns vc-a > /dev/null || true

  nodeset ${NODES} osimage=centos7-x86_64-netboot-trinity
  rpower $NODES reset
  systemctl restart trinity_api

  # wait until the nodes are booted and trinity is started
  #while : ; do
  for i in {1..100} ; do
    for NODE in $(expand ${NODES}); do
      if ! ssh $NODE docker ps 2>/dev/null | grep trinity; then
        sleep 10 
        continue 2;
      fi
    done
    # trigger the timeout condition
    [[ "$i" -ne 100 ]] 
    sleep 5
    break
  done
  sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a systemctl restart slurm
}

@test "1.2.6 There is a virtual login node" {
  sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a date
}

@test "1.2.7 Slurm and munge are running on the virtual login nodes" {
  sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a systemctl status slurm
  sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a systemctl status munge
}

@test "1.2.8 The compute nodes can connect to the internet" {
  ssh -o StrictHostKeyChecking=no node001 ping -c5 8.8.8.8
}


@test "/cluster/vc-a/.modulespath is a file not a directory" {
  [ -f /cluster/vc-a/.modulespath ]
}

