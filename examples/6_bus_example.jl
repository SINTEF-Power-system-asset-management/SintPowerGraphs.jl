using PowerGraphs

filepath = joinpath(@__DIR__, "cases", "bus_6.toml")
example = RadialPowerGraph(filepath)

red_example = merge_line_segments(example,
							  aggregators = Dict(:reldata => Dict(:fault_rate => 0.0,
																  :length => 0.0)))

final = remove_zero_impedance_lines(red_example)


