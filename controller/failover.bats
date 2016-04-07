#!/usr/bin/env bats
load config/configuration

@test "6.2.0 - Check pacemaker is installed" {
    pcs -h
}

@test "6.2.0.1 - Check sentinel is configured" {
    pcs resource | grep sentinel
}

@test "6.2.0.2 - See if the cluster stabilizes" {
    for i in {1..20}; do
        if (pcs resource | grep sentinel | grep Started > /dev/null) && \
           (drbd-overview | grep UpToDate/UpToDate > /dev/null); then
            return 0;
        fi
        sleep 5
    done
    return 1;
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
    while :; do
        if pcs resource | grep sentinel | grep Started; then
            break
        fi
        sleep 5
    done
    pcs resource | grep sentinel | grep Started | grep -v $active
}

@test "6.2.1.0 - Check stickyness" { 
    current=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    debug echo $current
    standby=$(pcs cluster status | grep standby | awk -F: '{ print $1 }' | awk '{ print $2 }')
    pcs cluster unstandby $standby
    sleep 30

    active=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    debug echo $current
    debug echo $active
    [[ $'active' = $'current' ]]
}
