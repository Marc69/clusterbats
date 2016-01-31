@test "xxx reboot controller" {
    sleep 2
    rpower node001 reset
    sleep 2
    for i in {1..30}; do
       if nodestat node001 | grep ssh; then 
           break;
       fi
       echo "still waiting" >&3
       sleep 20
    done
}
