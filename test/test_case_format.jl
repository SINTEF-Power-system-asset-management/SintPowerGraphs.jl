using PowerGraphs
using DataFrames

fname = joinpath(@__DIR__, joinpath("cases", "bus_3.toml"))
fname_w_gencost = joinpath(@__DIR__, joinpath("cases", "bus_3_w_gencost.toml"))

case = Case(fname)
case_w_gencost = Case(fname_w_gencost)

@test case.baseMVA == 100
@test case.gen[2, :mBase] == 100
@test get_power_injection_vector(case) == [0,100,-100]
@test get_line_lims_pu(case) == [0.8,1,1]
@test case.gencost == DataFrame()
@test get_n_buses(case) == 3

@test case_w_gencost.gencost[2, :cp1] == 1.2
