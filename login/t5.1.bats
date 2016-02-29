load ../controller/config/configuration

@test "5.1.5 Users can run jobs using srun" {
   obol -w user list | grep jane && obol -w system user add jane --password jane
   su - jane -c "srun -N2 hostname"
}

@test "5.1.8 Users have unlimited settings for locked memory and stack size" {
   su - jane -c "srun -N1 ulimit"
}


