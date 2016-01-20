@test "xxx reboot controller" {
    rpower node001 reset
    for i in {1..30}; do
       if nodestat node001 | grep ssh; then 
           break;
       fi
       sleep 20
    done

    # now perform test related specifically to the reboot
    ! ssh node001 /xcatpost/cv_fly_clusterbats | grep "not ok"
}
