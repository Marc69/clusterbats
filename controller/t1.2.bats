#!/usr/bin/env bats
load config/configuration

@test "1.2.0.0 - We can configure the switch" {
  # t1.1.19 in test sheet
  chtab node=switch hosts.ip=${SWITCH} # from configuration
  echo "${SWITCH_TABLE}" > /tmp/switch.csv
  if [[ ! -f /root/switch-backup.csv ]]; then
      tabdump switch > /root/switch-backup.csv
  fi
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

@test "1.2.0.2 - Check if we have the hostlist command" {
  [ -x "$(which hostlist)" ]
}

@test "1.2.1 - We can discover compute nodes" {
  rmnodecfg $(expand ${NODES}) || true
  nodeadd ${NODES} groups=compute
  makehosts compute
  makedns compute > /dev/null || true
  rpower compute reset
  sleep 5

  for i in {30..0} ; do
    for NODE in $(expand ${NODES}); do
      if ! lsdef -t node ${NODE} | grep 'mac=' ; then
        sleep 10 
        continue 2;
      fi
    done
    break
  done
  # trigger the timeout condition
  [[ "$i" -ne 0 ]] 
}

@test "1.2.3 - We can netboot trinity compute nodes with serial over lan" {
  if [[ "$NO_SOL" ]]; then
      skip "No serial over LAN in this environment"
  fi
  for i in {1..2} ; do
    for NODE in $(expand ${NODES}); do
      if ! ssh $NODE docker ps 2>/dev/null | grep trinity; then
        break 2;
      fi
    done
  done
  chtab node=compute nodehm.serialport=1 nodehm.serialspeed=57600 nodehm.serialflow=hard
  makeconservercf
  nodeset ${NODES} osimage=centos7-x86_64-netboot-trinity > /dev/null
  rpower $NODES reset > /dev/null

  for i in {30..0} ; do
    for NODE in $(expand ${NODES}); do
      if ! ssh $NODE systemctl status trinity 2> /dev/null; then
        sleep 5 
        continue 2;
      fi
    done
    break
  done
  [[ "$i" -ne 0 ]] # timeout
}

@test "1.2.3.1 - We can netboot trinity compute nodes without serial over lan" {
  for i in {1..2} ; do
    for NODE in $(expand ${NODES}); do
      if ! ssh $NODE docker ps 2>/dev/null | grep trinity; then
        break 2;
      fi
    done
    skip
  done
  chtab node=compute nodehm.serialport= nodehm.serialspeed= nodehm.serialflow=
  nodeset ${NODES} osimage=centos7-x86_64-netboot-trinity > /dev/null
  rpower $NODES reset > /dev/null

  for i in {30..0} ; do
    for NODE in $(expand ${NODES}); do
      if ! ssh $NODE systemctl status trinity 2> /dev/null; then
        sleep 5 
        continue 2;
      fi
    done
    break
  done
  [[ "$i" -ne 0 ]] # timeout
}

@test "1.2.4.1 - We can access the OpenStack dashboard" {
  wget -q -O- http://controller.cluster:/dashboard | grep "OpenStack"
}

@test "1.2.5 - We can assign the containers to the default virtual cluster a" {
  skip Moved to use case 2.1
  CPUs=$(lsdef -t node -o node001 -i cpucount | grep cpucount | cut -d= -f2)
  touch /cluster/vc-a/etc/slurm/slurm-nodes.conf
  cat > /cluster/vc-a/etc/slurm/slurm-nodes.conf << EOF
NodeName=$CONTAINERS CPUs=${CPUs} State=UNKNOWN
PartitionName=containers State=UP Nodes=$CONTAINERS Default=YES
EOF
  nodeadd $CONTAINERS groups=vc-a,hw-default
  makehosts vc-a
  makedns -n > /dev/null || true
  sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a systemctl restart slurm
}

@test "1.2.6 - There is a virtual login node" {
  skip Moved to use case 2.1
  sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a date
}

@test "1.2.7 - Slurm and munge are running on the virtual login nodes" {
  skip Moved to use case 2.1
  sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a systemctl status slurm
  sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a systemctl status munge
}

@test "1.2.8 - The compute nodes can connect to the internet" {
  skip Moved to use case 2.1
  ssh -o StrictHostKeyChecking=no node001 ping -c5 8.8.8.8
}
