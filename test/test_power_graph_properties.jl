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

A_4_bus = [1 -1 0 0;
		   1 0 -1 0;
		   0 1 0 -1;
		   0 0 1 -1;
		   1 0 0 -1]
	
A_island_test = [0 -1 0 0 1 0;
				 1 0 -1 0 0 0;
				 0 0 -1 0 0 1;
				 0 0 0 1 -1 0;
				 0 -1 0 1 0 0;
				 1 0 0 0 0 -1]

A_island_bd = [1 -1 0 0 0 0;
			   1 0 -1 0 0 0;
			   0 1 -1 0 0 0;
			   0 0 0 1 -1 0;
			   0 0 0 1 0 -1;
			   0 0 0 0 1 -1]

test_3_bus = PowerGraph(joinpath(@__DIR__, "cases", "bus_3.toml"))
test_4_bus = PowerGraph(joinpath(@__DIR__, "cases", "bus_4.toml"))

four_area = PowerGraph(joinpath(@__DIR__, "cases", "4area_network.toml"))

test_island = PowerGraph(joinpath(@__DIR__, "cases", "island_test.toml"))

# The object test is from set_up_simple_test_system.jl
@testset "Get network properties from the graph" begin
    @test get_bus_data(test_net, "1")[:type] == 3 # Check if the bus is the swing bus
    @test get_branch_data(test_net, "2", "3")[1, :x] == 0.5 # Check if the branch reactance is correct
    @test is_load_bus(test_net, "7") # Check if the bus is a load bus
    @test is_gen_bus(test_net, "1") # Check if the bus is a load bus
    @test B == get_dc_admittance_matrix(test_3_bus)
    @test A == get_incidence_matrix(test_3_bus)
    @test A_4_bus == get_incidence_matrix(test_4_bus)
    @test n_edges(test_3_bus) == 3
    @test n_vertices(test_3_bus) == 3
	@test is_switch(test_net, "4", "7")
	@test ~is_switch(test_net, "4", "9")
	@test ~is_indicator(test_net, "4", "7")
	@test get_branch_data(test_net, :reldata, :fault_rate, "1", "2")[1] == 0.01
	@test size(get_incidence_matrix(four_area)) == (30,25)
	take_out_line!(test_net, "2")
	@test Array[[1, 2], [3, 4, 5, 6, 7]] == get_islanded_buses(test_net)

	take_out_line!(test_island, "4")
	@test A_island_test == get_incidence_matrix(test_island, true)
	A_bd, bus_mapping, branch_mapping = get_island_incidence_matrix(test_island)
	@test A_island_bd == A_bd

	@test get_reliability_data(test_4_bus, "1", "2").f_rate[1] == 1
	@test get_reliability_data(test_4_bus, "1", "3").f_rate[1] == 0


end
