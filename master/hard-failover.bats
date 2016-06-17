#!/usr/bin/env bats
load ../controller/config/configuration

@test "6.2.0 - Check pacemaker is installed" {
    ssh node001 pcs -h
}

@test "6.2.0.1 - Check sentinel is configured" {
    ssh node001 pcs resource | grep sentinel
}

@test "6.2.0.2 - Check drbd connection" {
    ssh node001 drbdadm cstate ha_disk | grep "Connected\|SyncSource"
}

@test "6.2.0.3 - See if the cluster stabilizes" {
    for i in {30..0}; do
        if (ssh node001 pcs resource | grep sentinel | grep Started > /dev/null) && \
           (ssh node001 drbd-overview | grep UpToDate/UpToDate > /dev/null); then
            return 0;
        fi
        sleep 1m
    done
    return 1;
}

@test "6.2.0.4 - Check DNS configuration" {
    ssh node001 cat /etc/named.conf | grep xcat_key
}

@test "6.2.0.5 - Check replicator service" {
    ssh node001 systemctl status replicator.timer | grep "Active: active"
}

@test "6.2.1.0 - Check failover" {
   # Check if both nodes are active
    ssh node001 pcs cluster status | grep Online | grep controller-1.cluster | grep controller-2.cluster
    
    # Ok continue
    active=$(nodestat compute | grep https | awk -F: '{print $1}')

    # Create a file under /drbd
    ssh $active touch /drbd/test >> /dev/null

    # Create an ldap user
    ssh $active obol -w system -H ldap://controller.cluster user add test --sn test --password test >> /dev/null

    # Change an xCAT table
    ssh $active chtab key=timezone site.value=CET >> /dev/null

    # Perform the failover
    ssh $active "echo 1 > /proc/sys/kernel/sysrq" 
    ssh $active "echo b > /proc/sysrq-trigger" &

    current=$(nodestat compute | grep sshd | awk -F: '{print $1}')
    for i in {30..0}; do
        if ssh $current pcs resource | grep sentinel | grep Started; then
            break
        fi
        sleep 10
    done
    [[ $i != 0 ]]
    ssh $current pcs resource | grep sentinel | grep Started | grep -v $active
}

@test "6.2.1.1 - Check DNS after failover" { 
    ssh $current host controller.cluster controller.cluster
    ssh $current "host controller-1.cluster controller.cluster || host controller-2.cluster controller.cluster"
    ssh $current host login.vc-a controller.cluster
}

@test "6.2.1.2 - Check xCAT commands after failover" { 
    ssh $current tabdump hosts
}

# todo: further post-failover tests on the current controller

@test "6.2.2 - Continue with post-failover tests on current active controller" {
    sleep 5m
    for NODE in node00[1-2]; do
        if (ssh $NODE pcs resource | grep sentinel | grep Started > /dev/null); then
            debug $NODE;
            ssh $NODE bats /root/clusterbats/controller/post-failover.bats;
            break
        fi
    done
}
