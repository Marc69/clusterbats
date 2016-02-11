load common
@test "1.0.1 - check iptables on master" {
    todo "please create checks here"
}
@test "1.0.2 - check nfs server on master" {
    systemctl status nfs-server
    systemctl is-enabled nfs-server
    showmount -e localhost | grep trinity
    showmount -e localhost | grep install
    showmount -e localhost | grep tftpboot
}

@test "1.0.3 - check docker registry on master" {
    systemctl status docker-registry
    systemctl is-enabled docker-registry
     
}



@test "1.1.0 - install controller" {
    if [[ "$(cat /trinity/version)" = $(ssh -o StrictHostKeyChecking=no node001 cat /trinity/version) ]]; then
        skip
    else
        nodeset node001 osimage=
        rpower node001 reset
        while ! nodestat node001 | grep noping 2> /dev/null ; do
            sleep 1s
        done
        debug "node001 is up"
        # now wait a very long time
        for i in {1..30}; do
            if ssh -o StrictHostKeyChecking=no node001 grep cv_end /var/log/postinstall.log 2> /dev/null ; then
                break
            fi
            sleep 5m
            debug $(ssh -o StrictHostKeyChecking=no node001 cat /var/log/postinstall.log)
        done
        [[ "$i" -ne 30 ]] # timeout after 2.5 hours
    fi
}
