using Preferences
const iscray = parse(Bool, load_preference(Base.UUID("3da0fdf6-3ccc-4f1b-acd9-58baa6c99267"), "iscray", "false"))
@debug "Preloading GTL library" iscray
if iscray
    import Libdl
    Libdl.dlopen_e("libmpi_gtl_cuda", Libdl.RTLD_LAZY | Libdl.RTLD_GLOBAL)
end

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

run_performance_simulation(grid_size, ranks)

