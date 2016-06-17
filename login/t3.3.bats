load ../controller/config/configuration

# Test cases for managing users


@test "3.3.0.1 - Obol exists" {
   which obol
}

@test "3.3.0 - Check if the group-power users is created" {
   obol -H ldap://controller -w system group list | grep power-users
}

@test "3.3.1 - We can create and delete a user on the system" {
   obol -H ldap://controller -w system group add users
   obol -H ldap://controller -w system user add --password 123 --sn "Smith" john
   obol -H ldap://controller -w system user add --password 123 --sn "Jane" --groups power-users jane
   obol -H ldap://controller -w system group show users
   obol -H ldap://controller -w system user show john
   obol -H ldap://controller -w system user delete john
   obol -H ldap://controller -w system user list | grep -v john
}

# todo @test "3.3.2 - We can set permissions for each group of users" 

@test "3.3.3 - Users can login to the system using ssh" {
   sshpass -p 123 ssh jane@login.vc-a hostname
}

@test "3.3.4 - Users have a /home directory" {
   sshpass -p 123 ssh jane@login.vc-a ls /home/jane
}

@test "3.3.5 - Users have passwordless access to the containers" {
   su - jane -c "ssh jane@c001.vc-a hostname"
}

@test "3.3.4 - Users have a home directory" {
   sshpass -p 123 ssh jane@login.vc-a  [[ '$(pwd)' == "/home/jane" ]]
}

@test "3.3.5 - Users have passwordless login to compute nodes" {
   sshpass -p 123 ssh jane@login.vc-a sinfo
   CONTAINER=$(hostlist -e ${NODES} | head -1)
   sshpass -p 123 ssh jane@login.vc-a ssh ${CONTAINER} date
}

@test "3.3.7 - We can modify user data" {
   obol -H ldap://controller -w system user modify --cn jeanette jane
   obol -H ldap://controller -w system user show jane | grep jeanette
}

@test "3.3.8 - We can change a user's password" {
   obol -H ldap://controller -w system user reset --password 1234 jane
   sshpass -p 1234 ssh jane@login.vc-a pwd
}

@test "3.3.99 - Cleanup" {
   obol -H ldap://controller -w system user delete john || true
   obol -H ldap://controller -w system user delete jane || true
   obol -H ldap://controller -w system group delete users || true
   rm -rf /home/jane || true
   rm -rf /home/john || true
}

