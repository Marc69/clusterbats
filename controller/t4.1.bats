load config/configuration

# Power-user test cases

@test "4.1.0.1 - obol is installed" {
   sshpass -p system ssh login.vc-a obol -H ldap://controller -w system user list
}

@test "4.1.0.2 - allocate all resources to the first tenant" {
   TOKEN=$(http --ignore-stdin -b POST http://controller:32123/trinity/v1/login \
        X-Tenant:admin \
        username=admin \
        password=system \
        | jq --raw-output '.token')

   http --ignore-stdin --check-status \
        --timeout=600 \
       PUT http://controller:32123/trinity/v1/clusters/b \
       X-Tenant:admin \
       X-Auth-Token:$TOKEN \
       specs:='{"default":0}'

   http --ignore-stdin --check-status \
        --timeout=600 \
       PUT http://controller:32123/trinity/v1/clusters/a \
       X-Tenant:admin \
       X-Auth-Token:$TOKEN \
       specs:='{"default":2}'
}


@test "4.1.0.3 - Check if the group power-users is created" {
   sshpass -p system ssh login.vc-a obol -H ldap://controller -w system group list | grep power-users
}

@test "4.1.0.4 - Create a power-user on the system" {
   sshpass -p system ssh login.vc-a obol -H ldap://controller -w system user add --password 123 --sn "Jane" --groups power-users jane
}

@test "4.1.1.1 - Power-users have rwx access to /shared directory with software" {
   for dir in $(sshpass -p 123 ssh jane@login.vc-a ls /cluster/); do
       sshpass -p 123 ssh jane@login.vc-a ls -ltr /cluster | grep $dir | grep power-users | grep drwxrwx
   done
}

@test "4.1.1.2 - Power-users can write in apps/ and modulefiles/ directories" {
   sshpass -p 123 ssh jane@login.vc-a  touch /cluster/modulefiles/test /cluster/apps/test
}

@test "4.1.99 - Cleanup" {
   sshpass -p 123 ssh jane@login.vc-a  rm /cluster/apps/test || true
   sshpass -p 123 ssh jane@login.vc-a  rm /cluster/modulefiles/test || true
   sshpass -p system ssh login.vc-a obol -H ldap://controller -w system user delete jane || true
   sshpass -p system ssh login.vc-a rm -rf /home/jane || true
}

