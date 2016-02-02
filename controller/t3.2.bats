load configuration

@test "3.2.2 Slurm report the correct containers for our cluster" {
   sleep 15
   run sshpass -p 'system' ssh -o StrictHostKeyChecking=no login.vc-a sinfo 
   echo $output | grep -F "idle"
   echo $output | grep -v "unk"
   echo $output | grep -v "down"
}
