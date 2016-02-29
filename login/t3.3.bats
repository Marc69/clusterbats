load ../controller/config/configuration

@test "3.3.0 - Obol exists" {
   which obol
}

@test "3.3.1.0 - We can add users from out virtual clusters" {
   if obol -w system user list | grep jane; then
      skip
   fi
   obol -w system user add jane --password jane
}

@test "3.3.3 - Users can login to the system using ssh" {
   sshpass -p jane ssh jane@login.vc-a hostname
}

@test "3.3.4 - Users have a /home directory" {
   sshpass -p jane ssh jane@login.vc-a ls /home/jane
}

@test "3.3.5 - Users have passwordless access to the containers" {
   su - jane -c "ssh jane@c001.vc-a hostname"
}

@test "3.3.1.1 - We can remove users from out virtual clusters" {
   obol -w system user delete jane
   rm -rf /home/jane
}
