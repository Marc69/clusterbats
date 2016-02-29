load ../controller/config/configuration

@test "#562 Containers have no ip command" {
   sshpass -p system ssh c001 ls /usr/sbin/ip
}
