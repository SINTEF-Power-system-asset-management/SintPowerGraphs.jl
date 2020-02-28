using PowerGraphs

fname = joinpath(@__DIR__, joinpath("cases", "bus_3.toml"))

case = Case(fname)

@test case.baseMVA == 100
@test case.gen[2, :mBase] == 100
@test get_power_injection_vector(case) == [0,100,-100]
@test get_line_lims_pu(case) == [0.8,1,1]
@test case.gencost[2, :cp1] == 1.2

