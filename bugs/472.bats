load ../clusterbats/configuration

@test "#473 After deploying a controller the repositories need to be cleaned" {
  ! grep -A 1 'baseurl=http://192.168.1.254' /etc/yum.repos.d/*.repo | grep 'enabled=1'

# same on compute nodes
  sshpass -p system ssh node002 \  
  ! grep -A 1 'baseurl=http://192.168.1.254' /etc/yum.repos.d/*.repo | grep 'enabled=1'
}
