#!/bin/bash

module load netlib-hpl/2.2
sbatch --account=clustervision ${HPL_DIR}/submit.single.netlib.gcc.openblas.openmpi.job
