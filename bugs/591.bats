load ../clusterbats/configuration

@test "#591 login node hostname changes after controller reboot" {
  source /root/keystonerc_a
  nova reboot login-a
  while ! sshpass -p system ssh login-a date; do
    sleep 1
  done
  [[ "$(sshpass -p system ssh login-a hostname)" = "login" ]] || [[ "$(sshpass -p system ssh login-a hostname)" = "login" ]]
}

