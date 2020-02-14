using PowerGraphs

fname = "lionshield.m"
fname = "test.m"
filepath = joinpath(@__DIR__, fname)
example = RadialPowerGraph(filepath)

red_example = merge_line_segments(example)

small = remove_zero_impedance_lines(red_example)
smallest = remove_low_impedance_lines(red_example, 1e-5)
