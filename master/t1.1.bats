load common
# @test "1.0.1 - check iptables on master" {
#    todo "please create checks here"
# }

@test "1.0.2 - check nfs server on master" {
    service nfs-server status
    service nfs-server is-enabled
    showmount -e localhost | grep trinity
    showmount -e localhost | grep install
    showmount -e localhost | grep tftpboot
}

@test "1.0.3 - check docker registry on master" {
    service docker-registry status
    service docker-registry is-enabled
}

@test "1.1.0 - install controller" {
# not for HA clusters
    debug "Trinity version: $(cat /trinity/version)"
    if [[ -z "$(cat /trinity/version)" || "$(cat /trinity/version)" != $(ssh -o StrictHostKeyChecking=no node001 cat /trinity/version) ]]; then
        nodeset compute osimage=
        rpower compute reset
        debug "node001 restarted @ $(date)"
        while ! nodestat node001 | grep noping 2> /dev/null ; do
            sleep 1s
        done
        debug "node001 is up @ $(date)"
        # now wait a very long time
        for i in {30..0}; do
            if ssh -o StrictHostKeyChecking=no node001 grep cv_end /var/log/postinstall.log 2> /dev/null ; then
                break
            fi
            sleep 5m
            debug $(ssh -o StrictHostKeyChecking=no node001 cat /var/log/postinstall.log)
        done
        [[ "$i" -ne 0 ]] # timeout after 2.5 hours
    else
        skip "Current Trinity version already installed"
    fi
}
