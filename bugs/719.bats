@test "bug 719 - docker fails to start on compute nodes after a reboot" {
  ssh node001 docker ps 
  rpower node001 reset
  for i in {30..0}; do
     nodestat node001 | grep "noping" && break
     sleep 5
  done
  [[ i != 0 ]]
  for i in {30..0}; do
     nodestat node001 | grep "sshd" && break
     sleep 5
  done
  [[ i != 0 ]]
  sleep 5
  ssh node001 docker ps
}

