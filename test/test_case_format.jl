using PowerGraphs

fname = joinpath(@__DIR__, joinpath("cases", "bus_3.toml"))

case = Case(fname)

@test case.baseMVA == 100
@test case.gen[2, :mBase] == 100
@show get_power_injection_vector(case)
@test get_power_injection_vector(case) == [0,100,-100]

