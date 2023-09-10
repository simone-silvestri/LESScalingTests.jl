module LESscalingTests

export run_hit_simulation! 

using MPI
using JLD2
using Statistics: mean
using Printf
using Oceananigans
using Oceananigans.Utils: prettytime
using Oceananigans.Distributed
using Oceananigans.Grids: node
using Oceananigans.Advection: cell_advection_timescale
using Oceananigans.Units

@inline function bᵢ(x, y, z, p) 
    b = - 1 / (p.Ly)^2 * y^2 + 1
 
    return p.N² * z + p.Δb * b
end

function run_hit_simulation!(grid_size, ranks; 
                             topology  = (Periodic, Periodic, Bounded),
                             output_name = "test_fields",
                             timestepper = :QuasiAdamsBashforth2,
                             CFL = 0.5)
    
    N = grid_size .÷ ranks
    
    arch  = DistributedArch(GPU(); ranks, topology)
    grid  = RectilinearGrid(arch; size = N, x = (0, 4096),
			    		    y = (-2048, 2048),
					    z = (-512, 0), topology, halo = (4, 4, 4))

    # Buoyancy and boundary conditions
    @info "Enforcing boundary conditions..."
    
    N² = 4e-6
    Δb = 0.001
    Ly = 1024

    b_bcs = FieldBoundaryConditions(top = FluxBoundaryCondition(5e-9), 
                                    bottom = GradientBoundaryCondition(N²))

    @inline function b_restoring(i, j, k, grid, clock, fields, p)
        @inbounds begin
            x, y, z = node(i, j, k, grid, Center(), Center(), Center())
            return 1 / p.λ * (bᵢ(x, y, z, p) - fields.b[i, j, k])
        end
    end
                                    
    params = (; N², Δb, Ly, λ = 10days)

    model = NonhydrostaticModel(; grid, 
                                  advection = WENO(order = 7), 
                                  coriolis = FPlane(f = -1e-5),
				  tracers = :b, 
                                  buoyancy = BuoyancyTracer(),
                                  boundary_conditions = (; b = b_bcs),
                                  timestepper)
    
    @inline bᵣ(x, y, z) = bᵢ(x, y, z, params) + Δb * rand() / 1000
    @inline uᵣ(x, y, z) = (rand() - 0.5) * 0.001
    
    set!(model, u = uᵣ, v = uᵣ, b = bᵣ)
    
    wtime = Ref(time_ns())
    
    function progress(sim) 
        @info @sprintf("iteration: %d, Δt: %2e, wall time: %s (|u|, |v|, |w|): %.2e %.2e %.2e, b: %.2e \n", 
              sim.model.clock.iteration, sim.Δt, prettytime((time_ns() - wtime[])*1e-9),
              maximum(abs, sim.model.velocities.u), maximum(abs, sim.model.velocities.v), 
              maximum(abs, sim.model.velocities.w), maximum(abs, sim.model.tracers.b))
       wtime[] = time_ns()
    end

    simulation = Simulation(model; Δt=1.0, stop_time = 20days, stop_iteration = 100)
                        
    # Adaptive time-stepping
    wizard = TimeStepWizard(cfl=CFL, max_change=1.1, min_Δt=0.5, max_Δt=60.0)
    simulation.callbacks[:wizard] = Callback(wizard, IterationInterval(10))
    simulation.callbacks[:progress] = Callback(progress, IterationInterval(10))
   
    rank = MPI.Comm_rank(MPI.COMM_WORLD)

    if !isnothing(output_name)
        simulation.output_writers[:fields] = JLD2OutputWriter(model, merge(model.velocities, model.tracers),
                                                            filename = output_name * "_$(rank)",
                                                            schedule = TimeInterval(1hour),
                                                            overwrite_existing = true)
    end
    
    run!(simulation)
end

include("parse_results.jl")

end
