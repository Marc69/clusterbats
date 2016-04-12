load ../controller/config/configuration

@test "bug 575 - login node timezone not adjusted" {
   sshpass -p system ssh login.vc-a date | grep UTC
}
