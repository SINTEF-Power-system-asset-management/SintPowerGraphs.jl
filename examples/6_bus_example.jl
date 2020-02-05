using PowerGraphs

filepath = joinpath(@__DIR__, "bus_6.m")
example = RadialPowerGraph(filepath)

red_example = merge_line_segments(example)

final = remove_zero_impedance_lines(red_example)


