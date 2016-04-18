#!/usr/bin/env bats
load config/configuration

@test "6.2.0 - Check pacemaker is installed" {
    pcs -h
}

@test "6.2.0.1 - Check sentinel is configured" {
    pcs resource | grep sentinel
}

@test "6.2.0.2 - See if the cluster stabilizes" {
    for i in {30..0}; do
        if (pcs resource | grep sentinel | grep Started > /dev/null) && \
           (drbd-overview | grep UpToDate/UpToDate > /dev/null); then
            return 0;
        fi
        sleep 1m 
    done
    return 1;
}

@test "6.2.0.3 - Check DNS configuration" {
    ssh controller-1.cluster cat /etc/named.conf | grep xcat_key
    ssh controller-2.cluster cat /etc/named.conf | grep xcat_key
}

@test "6.2.0.4 - Check replicator service" {
    ssh controller-1.cluster systemctl status replicator.timer | grep "Active: active"
    ssh controller-2.cluster systemctl status replicator.timer | grep "Active: active"
}


@test "6.2.1 - Check failover" {
    # Check if both nodes are active
    pcs cluster status | grep Online | grep controller-1.cluster | grep controller-2.cluster
    
    # Ok continue
    active=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    pcs cluster standby $active
    while :; do
        if pcs resource | grep sentinel | grep Stopped; then
            break
        fi
        sleep 5
    done
    for i in {30..0}; do
        if pcs resource | grep sentinel | grep Started; then
            break
        fi
        sleep 10
    done
    [[ $i != 0 ]]
    pcs resource | grep sentinel | grep Started | grep -v $active
}

@test "6.2.1.0 - Check stickyness" { 
    current=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    debug echo $current
    standby=$(pcs cluster status | grep standby | awk -F: '{ print $1 }' | awk '{ print $2 }')
    pcs cluster unstandby $standby
    sleep 10 
    while :; do
        if pcs status | grep ^Online: | grep $standby; then
            break
        fi
        sleep 5
    done

    active=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    debug echo $current
    debug echo $active
    [[ ${active} = ${current} ]]
}
@test "6.2.1.1 - Check DNS after failover" { 
    host controller.cluster controller.cluster
    host controller-1.cluster controller.cluster
    host login.vc-a controller.cluster
}
