#!/usr/bin/env bash

##################################################
# SOFTWARE CARD
##################################################
appname="openmpi"
appversion="1.10.2"
tarball="${appname}-${appversion}.tar.gz"
extract="${appname}-${appversion}"
link="http://www.open-mpi.org/software/ompi/v1.10/downloads/${tarball}"
extra="64"
##################################################
config_gcc="gcc/4.9.3"
#config_intel="intel/compiler/64/15.0.2.164"
##################################################
shared_prefix="/cluster"

# Adding packages
# ---------------
yum -y -q install infinipath-psm-devel libsysfs-devel libibverbs-devel

# Functions
# ---------
function stop_run {
  if [[ $1 != 0 ]] ; then
    echo "####################"
    echo "Error on step: $2"
    echo "####################"
    exit 1
  fi
}

# Find top directory of the build
# -------------------------------
prefix_sources=$(pwd)

# Run script for every compiler
# -----------------------------
for cmpl in gcc
do

  # Specific parameters
  # -------------------
  prefix_install=${shared_prefix}/apps/${appname}/${cmpl}/${appversion}
  module_install=${shared_prefix}/modulefiles/${appname}/${cmpl}/${appversion}


  # Clean modules
  # -------------
  module purge
  eval config_mod=\$config_${cmpl}
  check_mod=$(echo ${config_mod} | sed 's| |:|g')
  module load ${config_mod}
  if [[ ${LOADEDMODULES} != "${check_mod}" ]] ; then
    echo "Check and fix script to load the right ${cmpl} modules"
    exit 1
  fi

  # Get
  # ---
  cd ${prefix_sources}
  if [ ! -e ${tarball} ] ; then
    echo "Downloading ${appname} ${appversion}"
    wget ${link} || exit 1
  fi
  if [ -e ${tarball} ] ; then
    echo "Extracting ${appname} ${appversion}"
    rm -rf ${prefix_sources}/${extract}
    tar zxf ${tarball}  || exit 1
  else
    exit 1
  fi
  
  # Install 
  # -------
  echo "Configuring ${appname} ${appversion}"
  build_dir=${prefix_sources}/${extract}
  log_dir=${prefix_install}/logs
  mkdir -p ${build_dir}
  mkdir -p ${log_dir}

  if [[ ${cmpl} == gcc ]] ; then
    cmpl_cc=$(which gcc)
    cmpl_cx=$(which g++)
    cmpl_cp="${cmpl_cx} -E"
    flags="-O3"
  fi
  if [[ ${cmpl} == intel ]] ; then
    cmpl_cc=$(which icc)
    cmpl_cx=$(which icpc)
    cmpl_cp="${cmpl_cx} -E"
    flags="-O3"
  fi

  cd ${build_dir} && ${build_dir}/configure                      \
                     --prefix=${prefix_install}                  \
                     --enable-orterun-prefix-by-default          \
                     --enable-mpirun-prefix-by-default           \
                     --enable-mpi-thread-multiple                \
                     --with-hwloc=internal                       \
                     --enable-shared                             \
                     --enable-static                             \
                     --with-openib                               \
                     --with-psm                                  \
                     --with-slurm                                \
                     CC="${cmpl_cc}"                             \
                     CPP="${cmpl_cp}"                            \
                     CFLAGS="${flags}"                           \
                     2>&1 | tee ${log_dir}/${appname}-config.log \
                     && stop_run ${PIPESTATUS[0]} "configure ${appname}/${cmpl}/${appversion}"

  cd ${build_dir} && make -j 8                  \
     2>&1 | tee ${log_dir}/${appname}-build.log \
     && stop_run ${PIPESTATUS[0]} "build ${appname}/${cmpl}/${appversion}"

  cd ${build_dir} && make install                 \
     2>&1 | tee ${log_dir}/${appname}-install.log \
     && stop_run ${PIPESTATUS[0]} "install ${appname}/${cmpl}/${appversion}"

  # Write modulefile
  # ----------------
  mkdir -p $(echo ${module_install}|rev| cut -d/ -f 2-|rev)
  echo "#%Module
#
# @name:    _APP_NAME_
# @version: _APP_VERSION_
#

# Customize the output of \`module help\` command
# ---------------------------------------------
proc ModulesHelp { } {
   puts stderr \"\\tAdds GNU Cross Compilers to your environment variables\"
   puts stderr \"\\t\\t\\\$PATH, \\\$MANPATH\"
}

# Customize the output of \`module whatis\` command
# -----------------------------------------------
module-whatis   \"loads the [module-info name] environment\"

# Define internal modulefile variables (Tcl script use only)
# ----------------------------------------------------------
set   name      _APP_NAME_
set   cmpl      _CMPL_NAME_
set   version   _APP_VERSION_
set   prefix    ${shared_prefix}/apps/\${name}/\${cmpl}/\${version}

# Check if the path exists before modifying environment
# -----------------------------------------------------
if {![file exists \$prefix]} {
   puts stderr \"\\t[module-info name] Load Error: \$prefix does not exist\"
   break
   exit 1
}

# Update common variables in the environment
# ------------------------------------------
prepend-path   PATH              \$prefix/bin
prepend-path   LD_LIBRARY_PATH   \$prefix/lib
prepend-path   LIBRARY_PATH      \$prefix/lib
prepend-path   INCLUDE           \$prefix/include
prepend-path   C_INCLUDE_PATH    \$prefix/include

prepend-path   PKG_CONFIG_PATH   \$prefix/lib/pkgconfig

prepend-path   MANPATH           \$prefix/share/man
prepend-path   INFOPATH          \$prefix/share/info

" > ${module_install}
 
  # Custom modulefile
  # -----------------
  sed -i "s|_APP_NAME_|${appname}|" ${module_install}
  sed -i "s|_CMPL_NAME_|${cmpl}|" ${module_install}
  sed -i "s|_APP_VERSION_|${appversion}|" ${module_install}
  
  # Copy script
  # -----------
  #cp ${prefix_sources}/$0 ${shared_prefix}/modulefiles/${appname}/${cmpl}/$0

  # Clean all install
  # -----------------
  cd ${prefix_sources}
  rm -rf ${prefix_sources}/${extract}

done

