module LESscalingTests

export homogeneous_isotropic_turbulence

using MPI
using Statistics: mean
using Printf
using Oceananigans
using Oceananigans.Utils: prettytime
using Oceananigans.Distributed

function run_hit_simulation!(grid_size, ranks; 
                             topology  = (Periodic, Periodic, Periodic),
                             output_name = nothing,
                             timestepper = :QuasiAdamsBashforth2,
                             CFL = 0.35)
    
    N = grid_size .÷ ranks
    
    arch  = DistributedArch(CPU(); ranks, topology)
    grid  = RectilinearGrid(arch; size = N, extent = (2π, 2π, 2π), topology, halo = (7, 7, 7))

    model = NonhydrostaticModel(; grid, 
                                  advection = WENO(order = 7), 
                                  tracers = :b, 
                                  timestepper)
    
    set!(model, u = (x, y, z) -> rand(), v = (x, y, z) -> rand())
    
    Δt = cell_advection_timescale(grid, model.velocities) * CFL

    simulation = Simulation(model; Δt, stop_iteration = 1000)
    
    wtime = Ref(time_ns())
    
    function progress(sim) 
       @info @sprintf("iteration: %d, wall time: %s \n", sim.model.clock.iteration, prettytime((time_ns() - wtime[])*1e-9))
       wtime[] = time_ns()
    end
    
    simulation.callbacks[:progress] = Callback(progress, IterationInterval(10))
    
    if !isnothig(output_name)
        simulation.output_writers[:fields] = JLD2OutputWriter(model, merge(model.velocities, (; ζ)),
                                                            filename = output_name * "_$(rank)",
                                                            schedule = TimeInterval(0.1))
    end
    
    run!(simulation)
end


end
