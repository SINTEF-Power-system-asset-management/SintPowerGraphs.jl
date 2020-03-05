using PowerGraphs

fname = "east_side.toml"
filepath = joinpath(@__DIR__, joinpath("cases", fname))
example = RadialPowerGraph(filepath)

red_example = merge_line_segments(example)

small = remove_zero_impedance_lines(red_example)
smallest = remove_low_impedance_lines(red_example, 1e-5)

update_ID!(small.mpc)
to_csv(small.mpc, joinpath(@__DIR__, "small"))
