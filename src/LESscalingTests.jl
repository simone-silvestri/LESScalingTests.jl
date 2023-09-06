module LESscalingTests

export run_hit_simulation! 

using MPI
using Statistics: mean
using Printf
using Oceananigans
using Oceananigans.Utils: prettytime
using Oceananigans.Distributed
using Oceananigans.Grids: node
using Oceananigans.Advection: cell_advection_timescale
using Oceananigans.Units

@inline transform(y, p) = y / p.Ly * 2π - π/2

@inline function bᵢ(x, y, z, p) 
    γ = transform(y, p)
    b = ifelse(γ < 0, 0, ifelse(γ > π, 1, 1 - (π - γ - sin(π - γ) * cos(π - γ)) / π))
    return p.N² * z + p.Δb * b
end

function run_hit_simulation!(grid_size, ranks; 
                             topology  = (Periodic, Bounded, Bounded),
                             output_name = "test_fields",
                             timestepper = :QuasiAdamsBashforth2,
                             CFL = 0.35)
    
    N = grid_size .÷ ranks
    
    arch  = DistributedArch(GPU(); ranks, topology)
    grid  = RectilinearGrid(arch; size = N, extent = (4.096kilometers, 4.096kilometers, 512meters), topology, halo = (4, 4, 4))

    # Buoyancy and boundary conditions
    @info "Enforcing boundary conditions..."
    
    N² = 4e-6
    Δb = 0.001
    Ly = 2.048kilometers 

    b_bcs = FieldBoundaryConditions(top = FluxBoundaryCondition(5e-9),
                                    bottom = GradientBoundaryCondition(N²))

    @inline function b_restoring(i, j, k, grid, clock, fields, p)
        @inbounds begin
            x, y, z = node(i, j, k, grid, Center(), Center(), Center())
            return 1 / p.λ * (bᵢ(x, y, z, p) - fields.b[i, j, k])
        end
    end
                                    
    params = (; N², Δb, Ly, λ = 10days)
    b_frc = Forcing(b_restoring, discrete_form=true, parameters=params)

    model = NonhydrostaticModel(; grid, 
                                  advection = WENO(order = 7), 
                                  coriolis = FPlane(f = -1e-5),
                                  tracers = :b, 
                                  buoyancy = BuoyancyTracer(),
                                  boundary_conditions = (; b = b_bcs),
                                  forcing = (; b = b_frc),
                                  timestepper)
    
    @inline bᵣ(x, y, z) = bᵢ(x, y, z, params) + Δb * rand() / 100
    @inline uᵣ(x, y, z) = (rand() - 0.5) * 0.001
    
    set!(model, u = uᵣ, v = uᵣ, b = bᵣ)
    
    wtime = Ref(time_ns())
    
    function progress(sim) 
        @info @sprintf("iteration: %d, wall time: %s (|u|, |v|, |w|): %.2e %.2e %.2e, b: %.2e \n", 
              sim.model.clock.iteration, prettytime((time_ns() - wtime[])*1e-9),
              maximum(abs, sim.model.velocities.u), maximum(abs, sim.model.velocities.v), 
              maximum(abs, sim.model.velocities.w), maximum(abs, sim.model.tracers.b))
       wtime[] = time_ns()
    end

    simulation = Simulation(model; Δt=1.0, stop_time = 20days)
                        
    # Adaptive time-stepping
    wizard = TimeStepWizard(cfl=CFL, max_change=1.1, min_Δt=0.01, max_Δt=30.0)
    simulation.callbacks[:wizard] = Callback(wizard, IterationInterval(10))
    simulation.callbacks[:progress] = Callback(progress, IterationInterval(10))
    
    if !isnothing(output_name)
        simulation.output_writers[:fields] = JLD2OutputWriter(model, merge(model.velocities, model.tracers.b),
                                                            filename = output_name * "_$(rank)",
                                                            schedule = TimeInterval(1hour),
                                                            overwrite_existing = true)
    end
    
    run!(simulation)
end


end
