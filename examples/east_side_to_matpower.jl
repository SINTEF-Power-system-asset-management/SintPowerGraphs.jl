using PowerGraphs
using DataFrames

fname = "east_side.toml"
filepath = joinpath(@__DIR__, joinpath("cases", fname))
example = RadialPowerGraph(filepath)

aggregators = Dict(:reldata => Dict(:failure_frequency_permanent => 0.0,
									:failure_frequency_temporary => 0.0,
									:length => 0.0))


red_example = merge_line_segments(example, aggregators=aggregators)
small = remove_low_impedance_lines(red_example, 1e-5)

## Prepare to write case to FaSad
mpc = deepcopy(small.mpc)
# mpc = deepcopy(red_example.mpc)
mpc.bus.ID = 1:nrow(mpc.bus)

to_csv(mpc, joinpath(@__DIR__, "reduced_matpower"))
