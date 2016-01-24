@test "4.2.0.0 -- Download modules script" {
   [[ -d /root/modules ]] && skip
   cd /root
   mkdir -p /trinity/clustervision/CentOS/7
   # FIXME: this needs a password
   git clone https://github.com/clustervision/modules | true
}
@test "4.2.0.1 -- modules gcc" {
   [[ -d /trinity/clustervision/CentOS/7/modulefiles/gcc ]] && skip
   cd /root/modules
   ./install-gcc-4.9.3.sh > /dev/null
}
@test "4.2.0.2 -- modules freeipmi" {
   [[ -d /trinity/clustervision/CentOS/7/modulefiles/freeipmi ]] && skip
   cd /root/modules
   cd /root/modules
   ./install-freeipmi-1.4.11.sh > /dev/null
}
@test "4.2.0.3 -- modules hwloc" {
   [[ -d /trinity/clustervision/CentOS/7/modulefiles/hwloc ]] && skip
   cd /root/modules
   ./install-hwloc-1.9.1.sh > /dev/null
}
@test "4.2.0.4 -- modules munge" {
   [[ -d /trinity/clustervision/CentOS/7/modulefiles/munge ]] && skip
   cd /root/modules
   ./install-munge-0.5.11.sh > /dev/null
}
@test "4.2.0.5 -- modules netloc" {
   [[ -d /trinity/clustervision/CentOS/7/modulefiles/netloc ]] && skip
   cd /root/modules
   ./install-netloc-0.5.sh > /dev/null
}
@test "4.2.0.6 -- modules slurm" {
   [[ -d /trinity/clustervision/CentOS/7/modulefiles/slurm ]] && skip
   cd /root/modules
   ./install-slurm-15.08.7.sh > /dev/null
}
@test "4.2.0.7 -- modules openmpi" {
   [[ -d /trinity/clustervision/CentOS/7/modulefiles/openmpi ]] && skip
   cd /root/modules
   ./install-openmpi-gcc-1.10.0.sh > /dev/null
}
