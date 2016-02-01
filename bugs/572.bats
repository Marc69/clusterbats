load ../clusterbats/configuration

@test "#572 dockerized mariadb is unreliable" {
  source /root/keystonerc_a
  # make sure that after a restart of mariadb
  # nova is still accessible
  for i in {1..5}; do
    systemctl stop mariadb || true
    systemctl start mariadb || true
    sleep 2
    (nova list | grep login-a) || exit
  done
}

