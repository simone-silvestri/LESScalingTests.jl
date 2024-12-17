
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

function perlmutter_scaling_tests()
    files = readdir("./")
    files = filter(x -> length(x) > 8, files)
    files = filter(x -> x[1:8] == "error_RX", files)
    files = filter.(x -> '0'<=x<='9', files)

    ranks = [(16, 1),
	     (16, 16),
	     (16,2),
	     (16,8),
	     (1,1),
	     (1,2),
	     (1,4),
	     (1,8),
	     (2,1),
	     (2,16),
	     (2,4),
	     (32,16),
	     (32,32),
	     (4,1),
	     (4,2),
	     (64,1),
	     (64,32),
	     (64,64),
	     (8,1),
	     (8,2),
	     (8,8)]

    sizes = Tuple(r .* (512, 512) for r in ranks)
    times = zeros(length(ranks))

    for i in eachindex(ranks)
        times[i] = average_execution_time(ranks[i]; folder = "./")
    end

    rx = Float64[ranks[i][1] for i in eachindex(ranks)]
    ry = Float64[ranks[i][2] for i in eachindex(ranks)]

    return rx, ry, times
end
