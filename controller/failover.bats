#!/usr/bin/env bats
load config/configuration

@test "6.2.0 - Check pacemaker is installed" {
    pcs -h
}

@test "6.2.0.1 - Check sentinel is configured" {
    pcs resource | grep sentinel
}

@test "6.2.0.2 - Check drbd connection" {
    drbdadm cstate ha_disk | grep "Connected\|SyncSource"
}

@test "6.2.0.3 - See if the cluster stabilizes" {
    for i in {30..0}; do
        if (pcs resource | grep sentinel | grep Started > /dev/null) && \
           (drbd-overview | grep UpToDate/UpToDate > /dev/null); then
            return 0;
        fi
        sleep 1m 
    done
    return 1;
}

@test "6.2.0.4 - Check DNS configuration" {
    ssh controller-1.cluster cat /etc/named.conf | grep xcat_key
    ssh controller-2.cluster cat /etc/named.conf | grep xcat_key
}

@test "6.2.0.5 - Check replicator service" {
    ssh controller-1.cluster systemctl status replicator.timer | grep "Active: active"
    ssh controller-2.cluster systemctl status replicator.timer | grep "Active: active"
}

@test "6.2.0.99 - Apply changes for post-failover testing" {
    active=$(nodestat compute | grep https | awk -F: '{print $1}')
#    debug $active

    # Create a file under /drbd
    ssh $active touch /drbd/test || True

    # Create an ldap user
    ssh $active obol -w system -H ldap://controller.cluster user add test --sn test --password test || True

    # Change an xCAT table
    ssh $active chtab key=timezone site.value=CET || True
}

@test "6.2.1 - Check failover" {
    # Check if both nodes are on
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

@test "6.2.1.1 - Check DNS after failover" { 
    host controller.cluster controller.cluster
    host controller-1.cluster controller.cluster
    host login.vc-a controller.cluster
}

@test "6.2.1.2 - Check xCAT commands after failover" { 
    tabdump hosts
}

@test "6.2.1.3 - Check if the time is synchronized between controllers" { 
    t1=$(ssh controller-1 date +%s)
    t2=$(ssh controller-2 date +%s)
    [[ $(( $t1 - $t2)) < 2 ]] && [[ $(( $t2 - $t1)) < 2 ]]
}

@test "6.2.2.1 - Check if nova compute and network come up again" {
    source /root/keystonerc_admin
    for i in {30..0}; do
        nova service-list | awk -F\| '{print $3, $7}' | \
            grep "nova-network\|nova-compute" | grep -v down && break
        sleep 10
    done
    [[ $i != 0 ]]
}

@test "6.2.2.2 - Check if galera comes up again" {
    mysql=( mysql --protocol=tcp -uroot -psystem -N -B -h controller)
    "${mysql[@]}" -e "show status like 'wsrep_ready'" | grep ON
    "${mysql[@]}" -e "show status like 'wsrep_connected'" | grep ON
    "${mysql[@]}" -e "show status like 'wsrep_cluster_status'" | grep Primary
    "${mysql[@]}" -e "show status like 'wsrep_evs_state'" | grep OPERATIONAL
    "${mysql[@]}" -e "show status like 'wsrep_local_state_comment'" | grep Synced
}

@test "6.2.2.3 - Check if nova controller is up on the active node" {
    source /root/keystonerc_admin
    current=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    for i in {30..0}; do
	nova service-list | awk -F\| '{print $3, $4, $7}' | \
            grep $current | \
            grep "nova-scheduler\|nova-conductor" | grep -v down && break
            sleep 10
    done
    [[ $i != 0 ]]
}

@test "6.2.2.4 - Check drbd + failover filesystem" {
    current=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    ssh $current -f /drbd/test
}
  
@test "6.2.2.5 - Check ldap failover" {
    current=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    ssh $current obol -w system -H ldap://controller.cluster user list | grep test
}

@test "6.2.2.6 - Check xCAT data failover" {
    current=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    ssh $current lsdef -t site clustersite -c -i timezone | grep CET
}

@test "6.2.2.7 - Check OpenStack dashboard" {
    current=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    ssh $current wget -q -O- http://controller.cluster:/dashboard | grep "OpenStack"
}
