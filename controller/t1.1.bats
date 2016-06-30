#!/usr/bin/env bats
load config/configuration

@test "bash executes" {
  bash --version
}

@test "1.1.4 - controller connects to internet" {
  ping -q -c1 google.com
}

@test "1.1.5 - firewall is disabled" {
  systemctl status firewall | grep inactive
}

@test "1.1.6.0 - iptables have the right masquerade rules" {
   iptables-save | grep -C3 'POSTROUTING -s 10.146.0.0/16 ! -o docker0 -j MASQUERADE' | grep 'POSTROUTING -o [0-z]*[0-1] -j MASQUERADE'
}

@test "1.1.9 - SElinux is disabled" {
  sestatus | grep 'SELinux status' | egrep disabled
}

@test "1.1.10 - The timezone is set correctly" {
  timedatectl | grep "Time zone" | grep "$TIMEZONE"
}

@test "1.1.12 - Hostname is set correctly" {
   hostname | grep 'controller'[\-]*[1-3]*
}

@test "1.1.13 - The controller node is setup to user LDAP for authentication" {
   systemctl status slapd
}

@test "1.1.14 - The controller node hosts a docker registry with a trinity image" {
   docker images | grep "controller:5050/trinity"
}

@test "1.1.15 - DNS is working on the controller" {
   host controller localhost
}

@test "1.1.16.0 - The timezone is set correctly in the site table" {
  tabdump site | grep -i timezone | grep $TIMEZONE
}

@test "1.1.16.1 - The dnshandler is set correctly in the site table" {
  tabdump site | grep dnshandler | grep ddns
}

@test "1.1.16.2 - The networks table had an entry for the internal net" {
  tabdump networks | grep internal_net
}

@test "1.1.17 - Openvswitch is available" {
   find /install/netboot/centos7/x86_64/trinity/rootimg/ -name "openvswitch" | grep openvswitch
}

@test "1.1.18 - We can generate and pack a compute image" {
   if [ -f /install/netboot/centos7/x86_64/trinity/rootimg.gz ]; then
       skip
   fi
   genimage centos7-x86_64-netboot-trinity
   packimage centos7-x86_64-netboot-trinity
}

#test "1.1.19 The switch is correctly configured for node discovery" in t1.2.bats

@test "1.1.20 - Openstack services are running in containers" {
   docker ps | grep nova_controller | grep -i up
   docker ps | grep glance | grep -i up
   docker ps | grep keystone | grep -i up
   docker ps | grep rabbitmq | grep -i up
   (docker ps | grep mariadb | grep -i up) || \
   (docker ps | grep galera | grep -i up) 
}

@test "1.1.21 - the appropriate openstack services are active" {
   status=$(openstack-status)
   echo $status | grep "nova-api:[ ]*inactive"
   echo $status | grep "nova-compute:[ ]*active"
   echo $status | grep "nova-network:[ ]*active"
   echo $status | grep "nova-scheduler:[ ]*inactive"
   echo $status | grep "openstack-dashboard:[ ]*active"
   echo $status | grep "dbus:[ ]*active"
   echo $status | grep "memcached:[ ]*active"
}

@test "1.1.22 - Check that xcat configuration is stored in the mariadb container" {
   if ! grep cv_setup_xcatdb /var/log/postinstall.log; then
       skip "xcatdb is not configured to run from mariadb"
   fi
   [[ -f /etc/xcat/cfgloc ]]
   grep mysql /etc/xcat/cfgloc
   systemctl restart xcatd
   tabdump site
}

@test "1.1.23 Check max connections on the database > 1024" {
   max_conns=$(mysql -u root -psystem --protocol=tcp -N -B -e "select @@max_connections")
   [[ $max_conns -ge 1024 ]]
}


@test "1.1.24 - Check drbd connection" {
    pcs status nodes | grep controller-2 || skip "Pacemaker does not seem to be configured for HA"
    drbdadm cstate ha_disk | grep "Connected\|SyncSource"
}
   
