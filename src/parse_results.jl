
function average_execution_time(ranks; folder = "./")
    Rx, Ry = ranks
    file = open(folder * "error_RX$(Rx)_RY$(Ry)")

    lines = readlines(file)
    line_start = 1

    while !occursin("iteration: 20", lines[line_start])
        line_start += 1
    end

    wall_time = 0.0
    tot_samples = 0
    for i in line_start:length(lines)
        if occursin("wall time:", lines[i])
            line = lines[i]
            split_line = split(line, " ")
            tidx = findfirst(isequal("time:"), split_line)
            wall_time += parse(Float64, split_line[tidx + 1])
            tot_samples += 1
        end
    end

    return wall_time / tot_samples
end

function perlmutter_scaling_tests(dir)
  files = readdir(dir)
  files = filter(x -> length(x) > 8, files)
  files = filter(x -> x[1:8] == "error_RX", files)
  files = filter.(x -> '0'<=x<='9', files)

  ranks = [(1 , 1 ), 
           (2 , 1 ), 
           (1 , 2 ), 
           (2 , 2 ), 
           (4 , 1 ), 
           (1 , 4 ), 
           (4 , 4 ), 
           (8 , 1 ), 
           (1 , 8 ), 
           (8 , 8 ), 
           (16, 1 ), 
           (1 , 16), 
           (16, 16), 
           (4 , 2 ),   
           (2 , 4 ),
           (8 , 2 ),
           (2 , 4 ),
           (16, 2 ),
           (2 , 16),
	   (32, 32)]
           # (64, 64)]
         
  sizes = Tuple(r .* (512, 512) for r in ranks)
  times = zeros(length(ranks))

  for i in eachindex(ranks)
      times[i] = average_execution_time(ranks[i]; folder = "./")
  end

  return ranks, times
end

function visualize_results(dir="./data")
   ranks, times = perlmutter_scaling_tests(dir)  
   color = Float64.([1 in rank ? 0 : 1 for rank in ranks])
   gpus  = Float64.([prod(rank) for rank in ranks])

   perm = sortperm(gpus)
   color = color[perm]
   times = times[perm]
   gpus  = gpus[perm]

   # color = color[2:end]
   # times = times[2:end]
   # gpus = gpus[2:end]

   gputicks = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024]
   gpulabel = [L"1", L"2", L"4", L"8", L"16", L"32", L"64", L"128", L"256", L"512", L"1024"]
  
   fig = Figure(size = (1000, 300))
   ax  = Axis(fig[1, 1], xlabel = L"\text{GPUs (Tesla A100)}", ylabel = L"\text{wall time per timestep (s)}", xscale = log2,
	      xticks = (gputicks, gpulabel),
	      yticks = ([4, 8, 12, 16, 20, 24], [L"4", L"8", L"12", L"16", L"20", L"24"]))
   scatter!(ax, gpus, times; color, markersize=15)
   lines!(ax, gpus, times, linewidth=0.5, linestyle=:dash)

   ax  = Axis(fig[1, 2], xlabel = L"\text{GPUs (Tesla A100)}", ylabel = L"\text{Scaling efficiency [-]}", xscale = log2,
	      xticks = (gputicks, gpulabel),
	      yticks = ([0, 0.2, 0.4, 0.6, 0.8, 1], [L"0", L"0.2", L"0.4", L"0.6", L"0.8", L"1.0"]))
   scatter!(ax, gpus, times[1] ./ times; color, markersize=15)
   lines!(ax, gpus, times[1] ./ times, linewidth=0.5, linestyle=:dash)
   ylims!(ax, 0, 1)

   return fig
end
