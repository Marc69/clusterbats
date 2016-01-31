@test "1.1.0 - install controller" {
    if [[ "$(cat /trinity/version)" = $(ssh -o StrictHostKeyChecking=no node001 cat /trinity/version) ]]; then
        skip
    else
        nodeset node001 osimage=
        rpower node001 reset
        while ! nodestat node001 | grep noping 2> /dev/null ; do
            sleep 1s
        done
        # now wait a very long time
        for i in {1..30}; do
            if ssh -o StrictHostKeyChecking=no node001 grep cv_fly_clusterbats /var/log/postinstall.log 2> /dev/null ; then
                break
            fi
            sleep 5m
        done
        [[ "$i" -ne 30 ]] # timeout after 2.5 hours
    fi
}
