using PowerGraphs
using DataFrames

fname = "east_side.toml"
filepath = joinpath(@__DIR__, joinpath("cases", fname))
example = RadialPowerGraph(filepath)

aggregators = Dict(
    :reldata => Dict(
        :failure_frequency_permanent => 0.0,
        :failure_frequency_temporary => 0.0,
        :length => 0.0,
    ),
)


red_example = merge_line_segments(example, aggregators = aggregators)

## Prepare to write case to FaSad
mpc = deepcopy(red_example.mpc)

# Merge reliability data and line data
mpc.branch =
    coalesce.(join(mpc.branch, mpc.reldata, on = [:f_bus, :t_bus], kind = :left), 0.0)

# Find transmission node
trans_node = findall(mpc.bus.type .== 3)

# Delete indicators, switches and transformers from the branch matrix
for b_type in [:switch, :indicator, :transformer]
    for branch in eachrow(getfield(mpc, b_type))
        deleterows!(
            mpc.branch,
            findall(
                (mpc.branch.f_bus .== branch.f_bus) .& (mpc.branch.t_bus .== branch.t_bus),
            ),
        )
    end
end

# Rename stuff to be consistent with FaSad
rename_branch = Dict(:f_bus => :from, :t_bus => :to, :rateA => :apparent_power_limit)
rename!(mpc.branch, rename_branch)
rename!(mpc.indicator, Dict(:f_bus => :from, :t_bus => :to))
rename!(mpc.switch, Dict(:f_bus => :from, :t_bus => :to))
rename!(mpc.transformer, Dict(:f_bus => :from, :t_bus => :to))
rename!(mpc.loaddata, Dict(:bus => :name))

# Add component names
mpc.branch.name = [string("L", x) for x = 1:nrow(mpc.branch)]
mpc.bus.name = 1:nrow(mpc.bus)

# Delete uneccessary stuff
deleterows!(mpc.bus, mpc.loaddata.name)
deletecols!(mpc.bus, findall(:name .!= DataFrames.names(mpc.bus)))
branch_h = [
    :from,
    :to,
    :apparent_power_limit,
    :name,
    :repair_time,
    :failure_frequency_temporary,
    :failure_frequency_permanent,
    :length,
]
deletecols!(mpc.branch, setdiff(DataFrames.names(mpc.branch), branch_h))

# Fix names
mpc.bus[!, :name] = string.("N", mpc.bus.name)
mpc.branch[!, :from] = string.("N", mpc.branch.from)
mpc.branch[!, :to] = string.("N", mpc.branch.to)
mpc.indicator[!, :to] = string.("N", mpc.indicator.to)
mpc.indicator[!, :from] = string.("N", mpc.indicator.from)
mpc.switch[!, :from] = string.("N", mpc.switch.from)
mpc.switch[!, :to] = string.("N", mpc.switch.to)
mpc.transformer[!, :from] = string.("N", mpc.transformer.from)
mpc.transformer[!, :to] = string.("N", mpc.transformer.to)
mpc.loaddata[!, :name] = string.("N", mpc.loaddata.name)

to_csv(mpc, joinpath(@__DIR__, "reduced"))

small = remove_zero_impedance_lines(red_example)
smallest = remove_low_impedance_lines(red_example, 1e-5)

update_ID!(small.mpc)
to_csv(small.mpc, joinpath(@__DIR__, "small"))
