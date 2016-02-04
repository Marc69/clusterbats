load ../controller/config/configuration

@test "3.3.0 Obol exists" {
   which obol
}

@test "3.3.1.a We can add users from out virtual clusters" {
   obol -w user list | grep jane || skip
   obol -w system user add jane --password jane
}

@test "3.3.3 Users can login to the system" {
   sshpass -p jane ssh jane@login.vc-a hostname
}

@test "3.3.4 Users have a /home directory" {
   sshpass -p jane ssh jane@login.vc-a ls /home/jane
}

@test "3.3.5 Users have passwordless access to the containers" {
   su - jane -c "ssh jane@c001.vc-a hostname"
}

@test "3.3.1.b We can remove users from out virtual clusters" {
   skip
   obol -w system user delete jane
   rm -rf /home/jane
}
