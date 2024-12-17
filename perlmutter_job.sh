#!/bin/bash
#SBATCH -C gpu
#SBATCH -q regular
#SBATCH --time=00:20:00
#SBATCH --account=m4672
#SBATCH -c 1
#SBATCH --gpus-per-task=1
#SBATCH --gpu-bind=none

source setup_perlmutter.sh

cat > launch.sh << EoF_s
#! /bin/sh
export CUDA_VISIBLE_DEVICES=0,1,2,3
exec \$*
EoF_s
chmod +x launch.sh

srun nsys profile --trace=cuda,mpi,nvtx --mpi-impl=mpich --gpu-metrics-device=all --output=./new_reports2/report_RX${RX}_RY${RY} ./launch.sh $JULIA --check-bounds=no --project scaling_experiments.jl
