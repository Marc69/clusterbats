#!/usr/bin/env bats
load config/configuration

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

@test "6.2.1 - Check failover" {
   # Check if both nodes are active
    ssh node001 pcs cluster status | grep Online | grep controller-1.cluster | grep controller-2.cluster
    
    # Ok continue
    active=$(ssh node001 pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    ssh $active "echo 1 > /proc/sys/kernel/sysrq" 
    ssh $active "echo b > /proc/sysrq-trigger" &

# todo: wait for pacemaker to resume and do post-failover tests on the current controller

