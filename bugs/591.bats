load ../clusterbats/configuration

@test "#592 login node hostname changes after controller reboot" {
  source /root/keystonerc_a
  while ! nova reboot login-a; do
    sleep 1
  done
  while ! sshpass -p system ssh login-a date; do
    sleep 1
  done
  [[ "$(sshpass -p system ssh login-a hostname)" = "login" ]] || [[ "$(sshpass -p system ssh login-a hostname)" = "login" ]]
}

