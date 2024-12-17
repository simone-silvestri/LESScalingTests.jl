#!/bin/bash

# Let's first specify the enviromental variables

# ====================================================== #
# ================ USER SPECIFIED INPUTS =============== #
# ====================================================== #

export PROFILE=1
export NTASKS=4

# Grid size
export NX=$((256 * RX))
export NY=$((256 * RY))
export NZ=256 

TOTCORES=$((RX * RY))
NODES=$(((TOTCORES - 1) / 4 + 1)) 

export NNODES=$NODES

export NTASKS=$((RX * RY / NNODES))

echo ""
echo "(RX, RY) = $RX, $RY"
echo "(NX, NY) = $NX, $NY"
echo "(NNODES, NTASKS) = $NNODES, $NTASKS"

OUTPUT="output_RX${RX}_RY${RY}"
ERROR="error_RX${RX}_RY${RY}"

sbatch -N ${NNODES} --gpus-per-node=${NTASKS} --ntasks-per-node=${NTASKS} -o ${OUTPUT} -e ${ERROR} perlmutter_job.sh
