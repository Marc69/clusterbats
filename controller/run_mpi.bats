#!/user/bin/env bats

@test "Can reach the virtual login node" {
    run ping -q -c1 login.vc-a
    [ "$status" -eq 0 ]
}

username=$(sshpass -p system ssh -o StrictHostKeyChecking=no login.vc-a obol -w system user list | head -1)
@test "Create a user for the login node" {
    if [[ $username != jane ]]; then  
       sshpass -p system ssh -o StrictHostKeyChecking=no login.vc-a obol -w system  user add --password 123 --cn Jane --sn Smith --givenName Jane jane
    fi;
}

@test "The user can login to login node" {
   sshpass -p 123 ssh jane@login.vc-a pwd
}

@test "The user can submit a batch script" {  
  sshpass -p 123 ssh jane@login.vc-a "
  cp /trinity/testing/clusterbats/sbatch.sample .
  sbatch sbatch.sample
  "
}  
 
