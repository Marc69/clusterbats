load ../controller/config/configuration

@test "bug 564 - Floating IP is set at the wrong network interface" {
   sshpass -p system ssh login.vc-a ping -c 5 c001
}
