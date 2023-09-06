module LESscalingTests

export run_hit_simulation! 

using MPI
using Statistics: mean
using Printf
using Oceananigans
using Oceananigans.Utils: prettytime
using Oceananigans.Distributed
using Oceananigans.Advection: cell_advection_timescale

function run_hit_simulation!(grid_size, ranks; 
                             topology  = (Periodic, Periodic, Periodic),
                             output_name = nothing,
                             timestepper = :QuasiAdamsBashforth2,
                             CFL = 0.35)
    
    N = grid_size .÷ ranks
    
    arch  = DistributedArch(GPU(); ranks, topology)
    grid  = RectilinearGrid(arch; size = N, extent = (2π, 2π, 2π), topology, halo = (7, 7, 7))

    model = NonhydrostaticModel(; grid, 
                                  advection = WENO(order = 7), 
                                  tracers = :b, 
                                  timestepper)
    
    simulation = Simulation(model; Δt = 1e-3, stop_iteration = 1000)
    
    wtime = Ref(time_ns())
    
    function progress(sim) 
       @info @sprintf("iteration: %d, wall time: %s \n", sim.model.clock.iteration, prettytime((time_ns() - wtime[])*1e-9))
       wtime[] = time_ns()
    end
    
    simulation.callbacks[:progress] = Callback(progress, IterationInterval(10))
    
    if !isnothing(output_name)
        simulation.output_writers[:fields] = JLD2OutputWriter(model, merge(model.velocities, (; ζ)),
                                                            filename = output_name * "_$(rank)",
                                                            schedule = TimeInterval(0.1))
    end
    
    run!(simulation)
end


end
