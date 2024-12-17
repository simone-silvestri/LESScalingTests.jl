module LESscalingTests

export run_performance_simulation

using MPI
using JLD2
using Statistics: mean
using Printf
using Oceananigans
using Oceananigans.Utils: prettytime
using Oceananigans.DistributedComputations
using Oceananigans.Grids: node
using Oceananigans.Advection: cell_advection_timescale
using Oceananigans.Units

function run_performance_simulation(grid_size, ranks; 
                                    topology  = (Periodic, Periodic, Bounded),
                                    output_name = "test_fields",
                                    timestepper = :RungeKutta3,
                                    closure = nothing,
                                    CFL = 0.75)
    
    N = grid_size
    device_arch = GPU() 

    arch  = Distributed(device_arch; partition = Partition(ranks...))
    grid  = RectilinearGrid(arch; size = N, x = (0, 4096),
			    		    y = (-2048, 2048),
					        z = (-512, 0), topology, halo = (4, 4, 4))

    # Buoyancy and boundary conditions
    @info "Enforcing boundary conditions..."
    
    b_bcs = FieldBoundaryConditions(top = FluxBoundaryCondition(5e-9), 
                                    bottom = GradientBoundaryCondition(4e-6))

    model = NonhydrostaticModel(; grid, 
                                  advection = WENO(order = 7), 
                                  coriolis = FPlane(f = -1e-5),
				  tracers = :b, 
                                  closure,
                                  buoyancy = BuoyancyTracer(),
                                  boundary_conditions = (; b = b_bcs),
                                  timestepper)
    
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

    run!(simulation)
end

include("parse_results.jl")

end
