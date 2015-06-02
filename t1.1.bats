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
   hostname==controller.cluster 
   [ "$status" -eq 0 ]
}
