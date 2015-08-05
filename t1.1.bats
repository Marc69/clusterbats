#!/user/bin/env bats

@test "bash executes" {
  run bash --version
  [ "$status" -eq 0 ]
}

@test "1.1.4 controller connects to internet" {
  run ping -q -c1 google.com
  [ "$status" -eq 0 ]
}

@test "1.1.5 firewall is disabled" {
  run service firewall status
  [ "$status" -ne 0 ]
}

@test "1.1.6 SElinux is disabled" {
  run bash -c "sestatus | grep 'SELinux status' | egrep 'disabled'"
  [ "$status" -eq 0 ]
}

@test "1.1.7 The timezone is set correctly" {
  run bash -c "date | grep CEST"
  [ "$status" -eq 0 ]

}

@test "1.1.8 Hostname is set correctly" {
   s1=$HOSTNAME
   s2='controller'
   [ $s1 = $s2 ] 
}


@test "1.1.9 The controller node is setup to user LDAP for authentication" {
   run service slapd status
   [ "$status" -eq 0 ]
}


@test "1.1.10 The controller node hosts a docker registry with a trinity image" {
   run bash -c "docker images | grep "controller:5050/trinity""
   [ "$status" -eq 0 ]

}

@test "1.1.11 DNS is working on the controller" {
   run host controller localhost
   [ "$status" -eq 0 ]
}

@test "1.1.13 Openvswitch is available" {
   run bash -c " find /install/netboot/centos7/x86_64/trinity/rootimg/ -name "openvswitch" | grep "openvswitch""
   [ "$status" -eq 0 ]
}

@test "1.1.14 The controller hosts an openstack image" {
   run bash -c "tabdump osimage | grep "centos7-x86_64-install-openstack""
   [ "$status" -eq 0 ]
}

#@test "1.1.15 The controller has postscripts for the addition of the trinity api and dashboard"
   
