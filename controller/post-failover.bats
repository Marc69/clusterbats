@test "6.2.1.2 - Check xCAT commands after failover" {
    tabdump hosts
}

@test "6.2.1.3 - Check if the time is synchronized between controllers" {
    t1=$(ssh controller-1 date +%s)
    t2=$(ssh controller-2 date +%s)
    [[ $(( $t1 - $t2)) < 2 && $(( $t2 - $t1)) < 2 ]]
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
    ssh $current ls /drbd/test
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
