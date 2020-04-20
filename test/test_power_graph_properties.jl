# Set up admittance matrix for dc power flow
b_12 = 1
b_13 = 2
b_23 = 4/3

# Create susceptance matrix
B = [b_12+b_13 -b_12 -b_13;
     -b_12 b_12+b_23 -b_23;
     -b_13 -b_23 b_13+b_23]

A = [1 -1 0;
     1 0 -1;
     0 1 -1]

test_3_bus = PowerGraph(joinpath(@__DIR__, "cases", "bus_3.toml"))

# The object test is from set_up_simple_test_system.jl
@testset "Get network properties from the graph" begin
    @test get_bus_data(test, 1)[:type] == 3 # Check if the bus is the swing bus
    @test get_branch_data(test, 2, 3)[1, :x] == 0.5 # Check if the branch reactance is correct
    @test is_load_bus(test, 7) # Check if the bus is a load bus
    @test is_gen_bus(test, 1) # Check if the bus is a load bus
    @test B == Array(get_dc_admittance_matrix(test_3_bus)) 
    @test A == Array(get_incidence_matrix(test_3_bus))
    @test n_edges(test_3_bus) == 3
    @test n_vertices(test_3_bus) == 3
	@test is_switch(test, 4, 7)
	@test ~is_switch(test, 4, 9)
	@test ~is_indicator(test, 4, 7)
	@test get_branch_data(test, :reldata, :fault_rate, 1, 2) == 0.01
end
