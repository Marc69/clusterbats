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
  run bash -c "sestatus | grep disabled"
  [ "$status" -eq 0 ]
}

@test "1.1.8 Hostname is set correctly" {
   s1=$HOSTNAME
   s2='controller.cluster'
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
