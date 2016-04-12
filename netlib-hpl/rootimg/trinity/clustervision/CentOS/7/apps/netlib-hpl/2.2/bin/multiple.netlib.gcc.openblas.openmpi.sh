#!/bin/bash

########################################
# HPL VERSION
########################################
export VERSION_HPL="netlib.gcc.openblas.openmpi"

########################################
# EARLY EXIT IF NO HOST DEFINED
########################################
if [[ -n $1 && -n $2 ]];then
  NNODES=$1
  LOAD=$2
else
  echo "usage: $0 <number of nodes> <memory load> <block size>"
  echo "  examples: for a quick run (150 sec), do $0 30"
  echo "            for a normal run, do $0 2 90"
  exit 1
fi
if [[ -n $3 ]];then
  BSIZ=$3
else
  BSIZ=192
fi 

########################################
# DEFINE CPU
########################################
CMODEL=$(grep "model name" /proc/cpuinfo|uniq|cut -d: -f2|xargs)
NCORES=$(grep processor /proc/cpuinfo|wc -l)
NPROCS=$(($NNODES*$NCORES))
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
export HPLPF=$(($NPROCS*$CFREQ*$CFLPS/1000))

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
N_SIZE=$(($NNODES*$MEMORY*1024/8))
N_SIZE=$(echo "sqrt($N_SIZE*$LOAD/100)"|bc)
N_SIZE=$((($N_SIZE/192)*192))

########################################
# GET GRID CONFIGURATION
########################################
Pmax=$(echo "sqrt($NPROCS)"|bc)
for ((Pi=1;Pi<=$Pmax;Pi++))
do
  is_ok=$(($NPROCS%$Pi))
  if [[ $is_ok -eq 0 ]] ; then 
    DIM_P=$Pi 
    DIM_Q=$(($NPROCS/$Pi))
  fi
done 

########################################
# DEFINE HPL BINARY
########################################
MPI_BIN=$(which mpirun 2> /dev/null)
MPI_OPT="-x PATH -x LD_LIBRARY_PATH" #--mca btl ^tcp,openib
MPI_PAR="--bind-to core -np ${NPROCS} -npernode ${NCORES}"
if [[ $NNODES -gt 1 ]];then
 if [[ -z $NODELIST ]];then NODELIST=$(scontrol show hostnames|xargs|tr ' ' ','); fi
 if [[ -n $NODELIST ]];then MPI_PAR="$MPI_PAR --mca btl ^tcp,openib -host $NODELIST"; fi
fi

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
hostname     : ${CHOST}
#nodes       : ${NNODES}
#cores       : ${NCORES}
#procs       : ${NPROCS}
n/nb/p/q     : ${N_SIZE}/${BSIZ}/${DIM_P}/${DIM_Q}
direcotry    : ${PREFIX_HPL}
command      : ${BIN_CMD}
===================================================================="
if [[ -n ${BIN_CMD} ]];then
  ${BIN_CMD}
  if [[ -n $CFLPS && -n $HPLPF && -n $HPLTR ]];then
    #echo "cflops     : $CFLPS Flops"
    echo "RPEAK (AVX)  : $HPLPF GFlops"
    echo "objectif     : $HPLTR %"
  fi
  if [[ -n $(grep WR ${PREFIX_HPL}/HPL.out) ]];then
    hpltime=$(grep WR ${PREFIX_HPL}/HPL.out |awk {'print $6'})
    hplperf=$(grep WR ${PREFIX_HPL}/HPL.out |awk {'print $7'}| awk '{ print sprintf("%.2f", $1); }')
    hpleffi=$(echo "scale=2;100*$hplperf/$HPLPF"|bc)
    echo "walltime     : ${hpltime} sec"
    echo "performance  : ${hplperf} GFlops"
    echo "efficiency   : ${hpleffi} %"
  fi
  echo "===================================================================="
else
  echo "HPL TEST: EXITING WITH ERRORS"
  echo "===================================================================="
fi

