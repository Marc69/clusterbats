load config/configuration

@test "Trinity Api is running" {
   pip install httpie > /dev/null 2>&1
   yum -y install jq
   http --ignore-stdin GET http://10.141.255.254:32123/trinity/v1/ | grep Welcome
}

@test "2.0.1 - We can create a first tenant" {
   source /root/keystonerc_admin
   if keystone user-get a; then
      skip
   fi
   keystone tenant-create --name a
   keystone user-create --name a --tenant a --pass system

cat > /root/keystonerc_a <<EOF
export OS_USERNAME=a
export OS_TENANT_NAME=a
export OS_PASSWORD=system
export OS_AUTH_URL=http://10.141.255.254:5000/v2.0/
export OS_REGION_NAME=regionOne
export PS1='[\u@\h \W(keystone_a)]\\$ '
EOF
}

@test "2.0.3 - We can assign the containers to the default hardware group" {
  nodeadd $CONTAINERS groups=hw-default
  systemctl restart trinity-api
  sleep 4
}

@test "2.0.4 - We can move resources to the first tenant." {
   TOKEN=$(http --ignore-stdin -b POST http://10.141.255.254:32123/trinity/v1/login \
        X-Tenant:admin \
        username=admin \
        password=system \
        | jq --raw-output '.token')

   http --ignore-stdin --check-status \
        --timeout=600 \
       PUT http://10.141.255.254:32123/trinity/v1/clusters/a \
       X-Tenant:admin \
       X-Auth-Token:$TOKEN \
       specs:='{"default":2}'
}

@test "2.0.5 - There is a virtual login node" {
  source /root/keystonerc_a
  for i in {30..0} ; do
    nova list | grep login.vc-a | awk -F\| '{print $4}' | grep ACTIVE && break
    sleep 5
  done
  [[ "$i" -ne 0 ]] # timeout on nova start

  for i in {30..0} ; do
    ping -c1 login.vc-a > /dev/null 2>&1 && break
    sleep 3
  done
  [[ "$i" -ne 0 ]] # timeout on waiting for the login node to be booted
  sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a date
}

@test "2.0.6 - Slurm and munge are running on the virtual login nodes" {
  sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a systemctl status slurm
  sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a systemctl status munge
}

@test "2.0.7 - The compute nodes can connect to the internet" {
  ssh -o StrictHostKeyChecking=no node001 ping -c5 8.8.8.8
}

@test "2.1.1 - We can create a second tenant" {
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
export PS1='[\u@\h \W(keystone_b)]\\$ '
EOF
}

@test "2.1.3 - We can remove resources from the first tenant." {
   TOKEN=$(http --ignore-stdin -b POST http://10.141.255.254:32123/trinity/v1/login \
        X-Tenant:admin \
        username=admin \
        password=system \
        | jq --raw-output '.token')

   http --ignore-stdin --check-status \
        --timeout=600 \
       PUT http://10.141.255.254:32123/trinity/v1/clusters/a \
       X-Tenant:admin \
       X-Auth-Token:$TOKEN \
       specs:='{"default":1}'
}

@test "2.1.4 - We can allocate resources to the second tenant." {
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
