#!/bin/bash

# Let's first specify the enviromental variables

# ====================================================== #
# ================ USER SPECIFIED INPUTS =============== #
# ====================================================== #

# Grid size
export NX=2048 
export NY=2048
export NZ=256 

export RX=8
export RY=1

export NNODES=2

sbatch -N ${NNODES} satori_job.sh
