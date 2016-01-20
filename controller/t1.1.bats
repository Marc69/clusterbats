#!/usr/bin/env bats
load configuration

@test "bash executes" {
  run bash --version
  [ "$status" -eq 0 ]
}

@test "1.1.4 controller connects to internet" {
  ping -q -c1 google.com
}

@test "1.1.5 firewall is disabled" {
  systemctl status firewall | grep inactive
}

@test "1.1.6a iptables have the right masquerade rules" {
   iptables-save | grep -C3 'POSTROUTING -s 10.146.0.0/16 ! -o docker0 -j MASQUERADE' | grep 'POSTROUTING -o [0-z]*[0-1] -j MASQUERADE'
}

@test "1.1.6b iptables have the right acceptance rules" {
   iptables-save | grep -C3 'br100 -j ACCEPT'
}

@test "1.1.8 3d interface is taken over by the bridge" {
   ip a | grep 'master br100'
}

@test "1.1.9 SElinux is disabled" {
  sestatus | grep 'SELinux status' | egrep disabled
}

@test "1.1.10 The timezone is set correctly" {
  echo $TIMEZONE > TZ
  date | grep $TIMEZONE
}

@test "1.1.12 Hostname is set correctly" {
   [ $HOSTNAME == controller.cluster ] && true
}

@test "1.1.13 The controller node is setup to user LDAP for authentication" {
   systemctl status slapd
}

@test "1.1.14 The controller node hosts a docker registry with a trinity image" {
   docker images | grep "controller:5050/trinity"
}

@test "1.1.15 DNS is working on the controller" {
   host controller localhost
}

@test "1.1.17 Openvswitch is available" {
   find /install/netboot/centos7/x86_64/trinity/rootimg/ -name "openvswitch" | grep openvswitch
}

@test "1.1.18 We can generate and pack a compute image" {
   genimage centos7-x86_64-netboot-compute
   packimage centos7-x86_64-netboot-compute
}

@test "1.1.20 Openstack services are running in containers" {
   docker ps | grep nova_controller | grep -i up
   docker ps | grep glance | grep -i up
   docker ps | grep keystone | grep -i up
   docker ps | grep rabbitmq | grep -i up
   docker ps | grep mariadb | grep -i up
}

@test "1.1.21 the appropriate openstack services are active" {
   openstack-status | grep nova-api | grep inactive
   openstack-status | grep nova-compute | grep -w active
   openstack-status | grep nova-network | grep -w active
   openstack-status | grep nova-scheduler | grep inactive
   openstack-status | grep openstack-dashboard | grep -w active
   openstack-status | grep dbus | grep -w active
   openstack-status | grep memcached | grep -w active
}

@test "The controller hosts an openstack image" {
   tabdump osimage | grep "centos7-x86_64-install-openstack"
}

#@test "The controller has postscripts for the addition of the trinity api and dashboard"
   
