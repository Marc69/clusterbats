@test "6.2.1.3 - Check if the time is sychronized beteen controllers" {
    t1=$(ssh controller-1 date +%s)
    t2=$(ssh controller-2 date +%s)
    [[ $(( $t1 - $t2)) < 2 ]]
}

@test "6.2.2.1 - Check if nova compute and network come up again" {
    source /root/keystonerc_admin
    nova service-list | awk -F\| '{print $3, $7}' | \
        grep "nova-network\|nova-compute" | grep -v down
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
    nova service-list | awk -F\| '{print $3, $4, $7}' | \
        grep $current | \
        grep "nova-scheduler\|nova-conductor" | grep -v down
}

