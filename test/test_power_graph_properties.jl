# Set up admittance matrix for dc power flow
b_12 = 1
b_13 = 2
b_23 = 4 / 3

# Create susceptance matrix
B = [
    b_12+b_13 -b_12 -b_13
    -b_12 b_12+b_23 -b_23
    -b_13 -b_23 b_13+b_23
]

test_3_bus = PowerGraph(joinpath(@__DIR__, "cases", "bus_3.toml"))
test_4_bus = PowerGraph(joinpath(@__DIR__, "cases", "bus_4.toml"))

four_area = PowerGraph(joinpath(@__DIR__, "cases", "4area_network.toml"))

test_island = PowerGraph(joinpath(@__DIR__, "cases", "island_test.toml"))

# The object test is from set_up_simple_test_system.jl
@testset "Get network properties from the graph" begin
    @test get_prop(test_3_bus.G, 1, 2, :rateA) == 80
    @test get_bus_data(test, "1")[:type] == 3 # Check if the bus is the swing bus
    @test get_branch_data(test, "2", "3")[1, :x] == 0.5 # Check if the branch reactance is correct
    @test is_load_bus(test, "7") # Check if the bus is a load bus
    @test is_gen_bus(test, "1") # Check if the bus is a load bus
    @test n_edges(test_3_bus) == 3
    @test n_vertices(test_3_bus) == 3
    @test is_switch(test, "4", "7")
    @test ~is_switch(test, "4", "9")
    @test ~is_indicator(test, "4", "7")
    @test get_branch_data(test, :reldata, :fault_rate, "1", "2")[1] == 0.01
    take_out_line!(test, "2")
    @test Array[[1, 2], [3, 4, 5, 6, 7]] == get_islanded_buses(test)

    @test get_reliability_data(test_4_bus, "1", "2").f_rate[1] == 1
    @test get_reliability_data(test_4_bus, "1", "3").f_rate[1] == 0

    @test get_gen_indices(test_4_bus) == [true, true, false, false]
    @test get_load_indices(test_4_bus) == [false, false, true, true]

    @test get_prop(test_3_bus.G, 3, :load)
    @test !get_prop(test_3_bus.G, 3, :nfc)
    @test get_prop(test_3_bus.G, 1, :external)

end
