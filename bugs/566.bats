load ../controller/config/configuration

@test "bug 566 - Controller and compute nodes have different time zones" {
   s1=$(date +%Z)
   s2=$(sshpass -p system ssh node001 date +%Z)
   [ $s1 = $s2 ]
}
