module load cray-mpich

export JULIA_NUM_THREADS=${SLURM_CPUS_PER_TASK:=1}
export JULIA_CUDA_MEMORY_POOL=none
export JULIA_NVTX_CALLBACKS=gc

export SLURM_CPU_BIND="cores"
export CRAY_ACCEL_TARGET="nvidia80"

export JULIA="/global/homes/s/ssilvest/julia-1.10.4/bin/julia"
