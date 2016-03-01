#!/usr/env/bin/bats
load config/configuration

@test "1.2.0.0 - We can configure the switch" {
  # t1.1.19 in test sheet
  chtab node=switch hosts.ip=${SWITCH} # from configuration

  echo "${SWITCH_TABLE}" > /tmp/switch.csv
  tabrestore /tmp/switch.csv

  makehosts switch
  makedns switch || true

  #------------------------------------------
  # do a switch ping test before proceeding
  #------------------------------------------
  ping -c 1 switch &> /dev/null 
}

@test "1.2.0.1 - The dhcp server is running" {
  systemctl status dhcpd
}

@test "1.2.1 - We can discover compute nodes" {
  for i in {1..2} ; do
    for NODE in $(expand ${NODES}); do
      if ! ssh $NODE docker ps 2>/dev/null | grep trinity; then
        break 2;
      fi
    done
    skip
    break
  done

  rmnodecfg compute || true
  rmdef compute || true
  nodeadd ${NODES} groups=compute
  makehosts compute
  makedns compute > /dev/null || true
  rpower compute reset

  for i in {1..100} ; do
    for NODE in $(expand ${NODES}); do
      if ! lsdef -t node ${NODE} | grep 'standingby\|bmcready' ; then
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

@test "1.2.5 - We can assign the containers to the default virtual cluster a" {
  for i in {1..2} ; do
    for NODE in $(expand ${NODES}); do
      if ! ssh $NODE docker ps 2>/dev/null | grep trinity; then
        break 2;
      fi
    done
    skip
    break
  done

  CPUs=$(lsdef -t node -o node001 -i cpucount | grep cpucount | cut -d= -f2)
  cat > /cluster/vc-a/etc/slurm/slurm-nodes.conf << EOF
NodeName=$CONTAINERS CPUs=${CPUs} State=UNKNOWN
PartitionName=containers State=UP Nodes=$CONTAINERS Default=YES
EOF

  nodeadd $CONTAINERS groups=vc-a,hw-default
  makehosts vc-a
  makedns vc-a > /dev/null || true

  # This is test 1.2.3 in the test sheet
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

@test "1.2.6 - There is a virtual login node" {
  sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a date
}

@test "1.2.7 - Slurm and munge are running on the virtual login nodes" {
  sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a systemctl status slurm
  sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a systemctl status munge
}

@test "1.2.8 - The compute nodes can connect to the internet" {
  ssh -o StrictHostKeyChecking=no node001 ping -c5 8.8.8.8
}
