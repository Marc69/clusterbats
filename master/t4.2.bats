load common
@test "4.2.0.0 -- Download modules" {
   lsb_release
   module avail
   osname=$(lsb_release -si)
   osmajorver=$(lsb_release -sr | cut -d. -f1)
   mkdir -p /trinity/clustervision/${osname}/${osmajorver}
   cd /root
   [[ -d /root/modules ]] || git clone http://github.com/clustervision/modules
}

@test "4.2.0.1 -- modules gcc" {
   [[ -d /trinity/clustervision/CentOS/7/modulefiles/gcc ]] && skip
   cd /root/modules
   ./install-gcc-5.3.0.sh > /dev/null
}

@test "4.2.0.2 -- modules freeipmi" {
   [[ -d /trinity/clustervision/CentOS/7/modulefiles/freeipmi ]] && skip
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
   module use /trinity/clustervision/CentOS/7/modulefiles
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
   module use /trinity/clustervision/CentOS/7/modulefiles
   cd /root/modules
   ./install-openmpi-gcc-1.10.0.sh > /dev/null
}

@test "4.2.0.8 -- modules netlib-hpl" {
   [[ -d /trinity/clustervision/CentOS/7/modulefiles/netlib-hpl ]] && skip
   module use /trinity/clustervision/CentOS/7/modulefiles
   cd /root/modules
   ./install-netlib-hpl-2.2.sh > /dev/null
}

