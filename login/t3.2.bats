load ../controller/configuration

@test "3.2.2 Slurm report the correct containers for our cluster" {
   run sinfo 
   echo $output | grep -F "idle"
   echo $output | grep -v "unk"
   echo $output | grep -v "down"
}
@test "3.2.3 We can access /home from the virtual login node" {
   ls /home
}

@test "3.2.4 We can list modules" {
   [[ $(module -t avail 2>&1 | wc -l) -gt 0 ]]
}
