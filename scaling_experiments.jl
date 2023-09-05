using MPI
MPI.Init()

using Oceananigans
using LESscalingTests

rx = parse(Int, get(ENV, "RX", "1"))
ry = parse(Int, get(ENV, "RY", "1"))

ranks = (rx, ry, 1)

Nx = parse(Int, get(ENV, "NX", "256"))
Ny = parse(Int, get(ENV, "NY", "256"))
Nz = parse(Int, get(ENV, "NZ", "256"))

grid_size = (Nx, Ny, Nz)

run_hit_simulation!(grid_size, ranks)

