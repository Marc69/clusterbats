load config/configuration

@test "Trinity Api is running" {
   pip install httpie > /dev/null 2>&1
   yum -y install jq
   http --ignore-stdin GET http://10.141.255.254:32123/trinity/v1/ | grep Welcome
}

@test "2.1.1 - We can create a tenant" {
   source /root/keystonerc_admin
   if keystone user-get b; then
      skip
   fi
   keystone tenant-create --name b
   keystone user-create --name b --tenant b --pass system

cat > /root/keystonerc_b <<EOF
export OS_USERNAME=b
export OS_TENANT_NAME=b
export OS_PASSWORD=system
export OS_AUTH_URL=http://10.141.255.254:5000/v2.0/
export OS_REGION_NAME=regionOne
export PS1='[\u@\h \W(keystone_b)]\$ '
EOF
}

@test "2.1.3 - We can remove resources from a tenant." {
   TOKEN=$(http --ignore-stdin -b POST http://10.141.255.254:32123/trinity/v1/login \
        X-Tenant:admin \
        username=admin \
        password=system \
        | jq --raw-output '.token')

   http --ignore-stdin --check-status PUT http://10.141.255.254:32123/trinity/v1/clusters/a \
       X-Tenant:admin \
       X-Auth-Token:$TOKEN \
       specs:='{"default":1}' 
}

@test "2.1.4 - We can allocate resources to a tenant." {
   TOKEN=$(http --ignore-stdin -b POST http://10.141.255.254:32123/trinity/v1/login \
        X-Tenant:admin \
        username=admin \
        password=system \
        | jq --raw-output '.token')

   http --ignore-stdin --check-status --timeout 120 \
       PUT http://10.141.255.254:32123/trinity/v1/clusters/b \
       X-Tenant:admin \
       X-Auth-Token:$TOKEN \
       specs:='{"default":1}' 
}

@test "2.1.5 - Login nodes are created for active clusters." {
   source /root/keystonerc_b
   nova show login-b  
}

@test "2.1.7 - After repartitioning, the containers know to which virtual cluster they belong." {
   for NODE in $(lsdef -t node vc-a -s | awk '{print $1}'); do
      ping -c6 -i 10 $NODE.vc-a
   done
   for NODE in $(lsdef -t node vc-b -s | awk '{print $1}'); do
      ping -c6 -i 5 $NODE.vc-b
   done
}
