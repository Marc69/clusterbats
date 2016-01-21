load configuration

@test "Trinity Api is running" {
   pip install httpie > /dev/null 2>&1
   http GET http://10.141.255.254:32123/trinity/v1/ | grep Welcome
}

@test "2.1.1 We can create a tenant" {
   source /root/keystonerc_admin
   if keystone user-get b; then
      skip
   fi
   keystone tenant-create --name b
   keystone user-create --name b --tenant b --pass system
}

@test "2.1.3 We can remove resources from a tenant." {
   source /root/keystonerc_admin
   TOKEN=$(http -b POST http://10.141.255.254:32123/trinity/v1/login \
        X-Tenant:admin \
        username=admin \
        password=system \
        | jq --raw-output '.token')

   http --print h PUT http://10.141.255.254:32123/trinity/v1/clusters/a \
       X-Tenant:admin \
       X-Auth-Token:$TOKEN \
       specs:='{"default":2}' | head -1 | grep "HTTP/1.1 200 OK"
}
