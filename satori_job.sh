#!/bin/bash
#SBATCH --cpus-per-task=16
#SBATCH --mem=500GB
#SBATCH --time 24:00:00

## modules setup
source setup_satori.sh

cat > launch.sh << EoF_s
#! /bin/sh
export CUDA_VISIBLE_DEVICES=0,1,2,3
exec \$*
EoF_s
chmod +x launch.sh

if test $PROFILE == 1; then
   NSYS="nsys profile --trace=nvtx,cuda,mpi --output=report_RX${RX}_RY${RY}_NX${NX}_NY${NY}"
fi

$NSYS srun --mpi=pmi2 ./launch.sh $JULIA --check-bounds=no --project scaling_experiments.jl 
