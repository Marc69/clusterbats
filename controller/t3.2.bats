load config/configuration

@test "3.2.2 Slurm reports the correct containers for our cluster" {
   sleep 15
   run sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a sinfo 
   echo $output | grep -F "idle"
   echo $output | grep -v "unk"
   echo $output | grep -v "down"
}

@test "3.2.3 We can access /home from the virtual login node" {
   run sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a ls /home
}

@test "3.2.4 We can list modules" {
   run sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a [[ 1 -gt 0 ]]
}
