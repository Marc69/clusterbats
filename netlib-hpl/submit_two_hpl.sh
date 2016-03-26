#!/bin/bash

module load netlib-hpl/2.2
sbatch --account=clustervision --nodes=2 \
       ${HPL_DIR}/submit.multiple.netlib.gcc.openblas.openmpi.job
