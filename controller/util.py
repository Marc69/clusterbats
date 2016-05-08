import re
import sh
from novaclient import client as novaclient
from keystoneclient.v2_0 import client as keystoneclient

p = re.compile(r'(?:export )?(.*?)=(.*)')

def source(config):
    c = {}
    with open(config) as file:
        for line in file:
            m = p.match(line)
            if m: 
                c[m.group(1).strip()] = m.group(2).strip()
    return novaclient.Client('2', c['OS_USERNAME'], 
                         c['OS_PASSWORD'], c['OS_TENANT_NAME'], 
                         c['OS_AUTH_URL'])

def source_2(config):
    c = {}
    with open(config) as file:
        for line in file:
            m = p.match(line)
            if m: 
                c[m.group(1).strip()] = m.group(2).strip()
    return keystoneclient.Client(username=c['OS_USERNAME'], 
                                 password=c['OS_PASSWORD'], 
                                 tenant_name=c['OS_TENANT_NAME'], 
                                 auth_url=c['OS_AUTH_URL'])

nova = source('/root/keystonerc_a')

for ip in nova.floating_ips.list():
    nova.servers.remove_floating_ip(ip.instance_id, ip.ip)
    ip.delete()
    # HTH we restore it for further resting later
    nova.floating_ips.create(ip.pool)
    nova.servers.add_floating_ip(ip.instance_id, ip.ip)

for server in nova.servers.list():
    print server
    #nova.servers.delete(server)

nova = source('/root/keystonerc_admin')
print nova.floating_ip_pools.list()
#print nova.floating_ip_pools.delete('login-a')


keystone = source_2('/root/keystonerc_admin')
#print keystone.users.list(tenant_id='a')
# Fix me: this should go into a utility method.
ids = [tenant.id for tenant in keystone.tenants.list() if tenant.name == 'a']
if len(ids) == 1:
    tenant = keystone.tenants.get(ids[0])
else:
    print 'invalid'

print keystone.users.list(tenant_id=tenant.id)

#keystone user-delete $1
#keystone tenant-delete $1

#rmdef -t group -o vc-$1
#makedns -d login-$1
#makehosts -d login-$1
#rmdef -t node -o login-$1

#makedns -d vc-$1
#makehosts -d vc-$1

#chtab -d netname=vc_${1}_net networks
#rm -rf /cluster/vc-${1}
#rm -rf /nfshome/vc-${1}
#systemctl restart trinity-api

#ssh-keygen -R login.vc-${1}



