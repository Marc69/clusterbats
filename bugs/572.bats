load ../clusterbats/configuration

@test "#572 dockerized mariadb is unreliable" {
  source /root/keystonerc_a
  # make sure that after a restart of mariadb
  # nova is still accessible
  for i in {1..5}; do
    systemctl stop mariadb || true
    systemctl start mariadb || true
    systemctl reset-failed keystone glance mariadb nova-controller
    sleep 2
    mysql -h localhost --password=system --protocol=TCP mysql -N -B -e "select user from user" | grep keystone
    mysql -h localhost --password=system --protocol=TCP mysql -N -B -e "select user from user" | grep glance
    mysql -h localhost --password=system --protocol=TCP mysql -N -B -e "select user from user" | grep root
    mysql -h localhost --password=system --protocol=TCP mysql -N -B -e "select user from user" | grep nova
    [[ -z $(docker exec mariadb cat /var/log/mysql.err) ]]
  done
  systemctl start keystone glance nova-controller
}

