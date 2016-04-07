#!/bin/bash

# Netlib HPL version
HPLVER="2.1"

# Stack version
STACK="netlib.gcc.openblas.openmpi"

# Web sources
WLINK="http://www.netlib.org/benchmark/hpl/hpl-${HPLVER}.tar.gz"

# Download sources
if [[ ! -f hpl-${HPLVER}.tar.gz ]] ; then
  wget ${WLINK} 
fi

# Load modules
source load_modules

# Uncompress soures
PREFIX=$(pwd)
if [[ -d hpl-${HPLVER} ]] ; then
  rm -rf hpl-${HPLVER}
fi
tar zxf hpl-${HPLVER}.tar.gz

# Copy makefile
\cp Make.${STACK} hpl-${HPLVER}/ 

# Compile 
cd hpl-${HPLVER}/
sed -i "s|@TOPDIR@|$PREFIX/hpl-${HPLVER}|" Make.${STACK}
if [[ "$HPLVER" == "2.1" ]];then
  patch -p1 -d src < ../hpl_2.1_progess.patch
fi 
make arch=${STACK} || exit 1

# Backup binary
cp bin/${STACK}/xhpl ${PREFIX}/xhpl-${HPLVER}-${STACK}
cd ${PREFIX} ; rm -rf hpl-${HPLVER}/
