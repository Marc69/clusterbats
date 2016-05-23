load ../controller/config/configuration

@test "bug 563 - dockerized route" {
   sshpass -p system ssh c001 ping -c 3 login.vc-a
}
