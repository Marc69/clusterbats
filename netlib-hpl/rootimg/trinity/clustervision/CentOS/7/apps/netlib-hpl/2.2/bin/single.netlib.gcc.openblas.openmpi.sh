#!/bin/bash

########################################
# HPL VERSION
########################################
export VERSION_HPL="2.2-netlib.gcc.openblas.openmpi"

########################################
# EARLY EXIT IF NO HOST DEFINED
########################################
if [[ -n $1 ]];then
  LOAD=$1
else
  echo "usage: $0 <memory load> <block size>"
  echo "  examples: for a quick run (150 sec), do $0 30"
  echo "            for a normal run, do $0 90"
  exit 1
fi
if [[ -n $2 ]];then
  BSIZ=$2
else
  BSIZ=192
fi 

########################################
# DEFINE CPU
########################################
CMODEL=$(grep "model name" /proc/cpuinfo|uniq|cut -d: -f2|xargs)
NCORES=$(grep processor /proc/cpuinfo|wc -l)
CFREQ=$(grep "cpu MHz" /proc/cpuinfo|cut -d: -f2|cut -d\. -f1|sort -ru|head -1|xargs)

# HASWELL
if [[ -n $(echo $CMODEL|grep 'E5-[0-9]\{4\}[ ]*v3') ]];then
  export HPLTR=74
  export CFLPS=16

# SANDY/IVY BRIDGE
elif [[ -n $(echo $CMODEL|grep 'E5-[0-9]\{4\}') ]];then
  export HPLTR=90
  export CFLPS=8

else
  export HPLTR=80
  export CFLPS=4

fi
export HPLPF=$(($NCORES*$CFREQ*$CFLPS/1000))

########################################
# GET HOSTNAME
########################################
CHOST=$(hostname)
CDATE=$(date +"%y%m%d-%H%M%S")

########################################
# DEFINE ABSOLUTE PATH
########################################
export PREFIX_SRC=$(dirname $(readlink -f $0))
export PREFIX_HPL="$(pwd)/${CHOST}-${CDATE}"
mkdir -p ${PREFIX_HPL}

########################################
# DEFINE YOUR ENVIRONMENT HERE
########################################
source ${PREFIX_SRC}/load_modules

########################################
# GET MEMORY CONFIGURATION
########################################
MEMORY=$(grep MemTotal /proc/meminfo|awk '{print $2}')
N_SIZE=$(($MEMORY*1024/8))
N_SIZE=$(echo "sqrt($N_SIZE*$LOAD/100)"|bc)
N_SIZE=$((($N_SIZE/192)*192))

########################################
# GET GRID CONFIGURATION
########################################
Pmax=$(echo "sqrt($NCORES)"|bc)
for ((Pi=1;Pi<=$Pmax;Pi++))
do
  is_ok=$(($NCORES%$Pi))
  if [[ $is_ok -eq 0 ]] ; then 
    DIM_P=$Pi 
    DIM_Q=$(($NCORES/$Pi))
  fi
done 

########################################
# DEFINE HPL BINARY
########################################
MPI_BIN=$(which mpirun 2> /dev/null)
MPI_OPT="-x PATH -x LD_LIBRARY_PATH"
MPI_PAR="-bind-to core -mca btl ^tcp,openib -n ${NCORES} -npernode ${NCORES}"

########################################
# MAKE DIRECTORY
########################################
cp ${PREFIX_SRC}/dataHPL.model          ${PREFIX_HPL}/HPL.dat
ln -s ${PREFIX_SRC}/xhpl-${VERSION_HPL} ${PREFIX_HPL}/xhpl
sed -i "s|@OUTPUT@|HPL.out|"            ${PREFIX_HPL}/HPL.dat
sed -i "s|@DIMNB@|$BSIZ|"               ${PREFIX_HPL}/HPL.dat
sed -i "s|@SIZE@|$N_SIZE|"              ${PREFIX_HPL}/HPL.dat
sed -i "s|@DIMP@|$DIM_P|"               ${PREFIX_HPL}/HPL.dat
sed -i "s|@DIMQ@|$DIM_Q|"               ${PREFIX_HPL}/HPL.dat

########################################
# LAUNCH HPL HERE
########################################
cd ${PREFIX_HPL} 
BIN_CMD="${MPI_BIN} ${MPI_OPT} ${MPI_PAR} ${PREFIX_HPL}/xhpl"
echo "====================================================================
HPL TEST
====================================================================
hostname: ${CHOST}
#cores  : ${NCORES}
n/nb/p/q: ${N_SIZE}/${BSIZ}/${DIM_P}/${DIM_Q}
command : ${BIN_CMD}
===================================================================="
if [[ -n ${BIN_CMD} ]];then
  ${BIN_CMD}
  if [[ -n $CFLPS && -n $HPLPF && -n $HPLTR ]];then
    echo "cflops     : $CFLPS GFlops"
    echo "target_perf: $HPLPF GFlops"
    echo "target_effi: $HPLTR %"
  fi
  echo "walltime     : $(grep WR ${PREFIX_HPL}/HPL.out |awk {'print $6'}) sec"
  echo "performance  : $(grep WR ${PREFIX_HPL}/HPL.out |awk {'print $7'}| awk '{ print sprintf("%.2f", $1); }') GFlops"
  echo "===================================================================="
else
  echo "HPL TEST: EXITING WITH ERRORS"
  echo "===================================================================="
fi

