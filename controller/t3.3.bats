load config/configuration

# Test cases for manage users
@test "3.3.0.1 - obol is installed" {
   sshpass -p system ssh login.vc-a obol -w system user list
}

@test "3.3.0.2 - allocate all resources to the first tenant" {
   TOKEN=$(http --ignore-stdin -b POST http://10.141.255.254:32123/trinity/v1/login \
        X-Tenant:admin \
        username=admin \
        password=system \
        | jq --raw-output '.token')

   http --ignore-stdin --check-status \
        --timeout=600 \
       PUT http://10.141.255.254:32123/trinity/v1/clusters/b \
       X-Tenant:admin \
       X-Auth-Token:$TOKEN \
       specs:='{"default":0}'

   http --ignore-stdin --check-status \
        --timeout=600 \
       PUT http://10.141.255.254:32123/trinity/v1/clusters/a \
       X-Tenant:admin \
       X-Auth-Token:$TOKEN \
       specs:='{"default":2}'
}


@test "3.3.0 - Check if the group-power users is created" {
   sshpass -p system ssh login.vc-a obol -w system group list | grep power-users
}

@test "3.3.1 - We can create a user on the system" {
   sshpass -p system ssh login.vc-a obol -w system group add users
   sshpass -p system ssh login.vc-a obol -w system user add --password 123 --sn "Smith" john
   sshpass -p system ssh login.vc-a obol -w system user add --password 123 --sn "Jane" --groups power-users jane
   sshpass -p system ssh login.vc-a obol -w system group show users
   sshpass -p system ssh login.vc-a obol -w system user show john
   sshpass -p system ssh login.vc-a obol -w system user delete john
   sshpass -p system ssh login.vc-a obol -w system user list | grep -v john
}

@test "3.3.2 - We can set permissions for each group of users" {
   [[ "$(stat -c '%G' /cluster/vc-a/apps/) == "power-users" ]] 
   [[ "$(stat -c '%G' /cluster/vc-a/modulefiles/) == "power-users" ]] 
}

@test "3.3.4 - Users have a home directory" {
   sshpass -p 123 ssh jane@login.vc-a  [[ '$(pwd)' == "/home/jane" ]]
}

@test "3.3.5 - Users have passwordless login to compute nodes" {
   sshpass -p 123 ssh jane@login.vc-a sinfo
   sshpass -p 123 ssh jane@login.vc-a ssh c001 date
}

@test "3.3.6 - Cleanup" {
   sshpass -p system ssh login.vc-a obol -w system user delete john || true
   sshpass -p system ssh login.vc-a obol -w system user delete jane || true
   sshpass -p system ssh login.vc-a obol -w system group delete users || true
   sshpass -p system ssh login.vc-a rm -rf /home/jane || true
   sshpass -p system ssh login.vc-a rm -rf /home/john || true
}

