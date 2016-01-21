@test "xxx reboot controller" {
    rpower node001 reset
    for i in {1..30}; do
       if nodestat node001 | grep ssh; then 
           break;
       fi
       sleep 20
    done

    # now perform test related specifically to the reboot
    ! ssh -o StrictHostKeyChecking=no -q node001 bats /root/clusterbats/controller/t*bats | grep "not ok"
}
