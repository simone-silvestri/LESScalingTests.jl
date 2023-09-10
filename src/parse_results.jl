
function average_execution_time(ranks, size; folder = "results/")
    Rx, Ry = ranks
    Nx, Ny = size
    file = open(folder * "error_RX$(Rx)_RY$(Ry)_NX$(Nx)_NY$(Ny)")

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
    ranks = ((1, 1), (2, 1), (2, 2), 
             (4, 1), (1, 4), (2, 4), 
             (4, 2), (8, 1), (1, 8),
             (16, 8), (16, 16), (64, 1))
    
    sizes = Tuple(r .* (512, 512) for r in ranks)
    times = zeros(length(ranks))

    for i in eachindex(ranks)
        times[i] = average_execution_time(ranks[i], sizes[i])
    end

    rx = Float64[ranks[i][1] for i in eachindex(ranks)]
    ry = Float64[ranks[i][2] for i in eachindex(ranks)]

    return rx, ry, times
end