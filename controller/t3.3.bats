load ../controller/config/configuration
LOGIN="sshpass -p system login.vc-a"

@test "3.3.0 - Obol exists" {
   $LOGIN which obol
}

@test "3.3.1.0 - We can add users from out virtual clusters" {
   if $LOGIN obol -w system user list | grep jane; then
      skip
   fi
   $LOGIN obol -w system user add jane --password jane
}

@test "3.3.3 - Users can login to the system using ssh" {
   sshpass -p jane ssh jane@login.vc-a hostname
}

@test "3.3.4 - Users have a /home directory" {
   sshpass -p jane ssh jane@login.vc-a ls /home/jane
}

@test "3.3.5 - Users have passwordless access to the containers" {
   $LOGIN su - jane -c "ssh jane@c001.vc-a hostname"
}

@test "3.3.1.1 - We can remove users from out virtual clusters" {
   $LOGIN obol -w system user delete jane
   $LOGIN rm -rf /home/jane
}
