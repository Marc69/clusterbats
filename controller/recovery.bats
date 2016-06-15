#!/usr/bin/env bats
load config/configuration

@test "6.3.1 - Check stickyness" { 
    sleep 5
    current=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    standby=$(pcs cluster status | grep standby | awk -F: '{ print $1 }' | awk '{ print $2 }')
    pcs cluster unstandby $standby
    sleep 10 
    for i in {30..0}; do
        if pcs status | grep ^Online: | grep $standby; then
            break
        fi
        sleep 10
    done
    [[ $i != 0 ]]
    active=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    [[ ${active} = ${current} ]]
}

@test "6.3.2 - Check DNS after failover" { 
    host controller.cluster controller.cluster
    host controller-1.cluster controller.cluster
    host login.vc-a controller.cluster
}

@test "6.3.3 - Check xCAT commands after failover" { 
    tabdump hosts
}

@test "6.3.4 - Check if the time is synchronized between controllers" { 
    t1=$(ssh controller-1 date +%s)
    t2=$(ssh controller-2 date +%s)
    [[ $(( $t1 - $t2)) < 2 ]]
}

@test "6.3.5 - Check if galera comes up again" {
    mysql -u root -psystem --protocol=tcp -h controller -N -B -e "show status like 'wsrep_ready'" | grep ON
    mysql -u root -psystem --protocol=tcp -h controller -N -B -e "show status like 'wsrep_connected'" | grep ON
    mysql -u root -psystem --protocol=tcp -h controller -N -B -e "show status like 'wsrep_cluster_status'" | grep Primary
    mysql -u root -psystem --protocol=tcp -h controller -N -B -e "show status like 'wsrep_evs_state'" | grep OPERATIONAL
    mysql -u root -psystem --protocol=tcp -h controller -N -B -e "show status like 'wsrep_local_state_comment'" | grep Synced
}

@test "6.3.6 - Check if nova compute and network come up again" {
    source /root/keystonerc_admin
    for i in {30..0}; do
        nova service-list | awk -F\| '{print $3, $7}' | \
            grep "nova-network\|nova-compute" | grep -v down && break
        sleep 10
    done
    [[ $i != 0 ]]
}

@test "6.3.7 - Check if nova controller is up on the active node" {
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

@test "6.3.8 - Check drbd + failover filesystem" {
    current=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    ssh $current ls /drbd/test
}
   
@test "6.3.9 - Check ldap failover" {
    current=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    ssh $current obol -w system -H ldap://controller.cluster user list | grep test
}

@test "6.3.10 - Check xCAT data failover" {
    current=$(pcs resource | grep sentinel | awk -F: '{print $5}' | awk '{print $2}')
    ssh $current lsdef -t site clustersite -c -i timezone | grep CET
}
