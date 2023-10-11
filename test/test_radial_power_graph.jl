using SintPowerGraphs
using Test 

@testset "Check construction of radial graph" begin
	for edge in edges(test.radial)
		@test has_edge(test_graph, parse(Int64, test.radial[edge.src, :name]), parse(Int64, test.radial[edge.dst, :name]))
	end
end

# Create the reduced graph
test_red_graph = MetaDiGraph(6)
add_edge!(test_red_graph, 1, 2)
add_edge!(test_red_graph, 2, 3)
add_edge!(test_red_graph, 3, 4)
add_edge!(test_red_graph, 3, 5)
add_edge!(test_red_graph, 5, 6)
    
red_net = merge_line_segments(test,
							  aggregators = Dict(:reldata => Dict(:fault_rate => 0.0,
																  :length => 0.0)))
@testset "Check line merging" begin
	@test DiGraph(test_red_graph) == DiGraph(red_net.radial)
	@test test_red_graph != test.radial
	@test red_net.mpc.bus[red_net.mpc.bus.ID .=="6",:] == test.mpc.bus[test.mpc.bus.ID .=="6",:]
	@test is_load_bus(red_net, "6")
	@test is_gen_bus(red_net, "2")
	@test get_π_equivalent(red_net, "3", "6") == (get_π_equivalent(test, "3", "5")+get_π_equivalent(test, "5", "6"))
	@test is_switch(red_net, "4", "7")
	@test 0.01 + 0.01 == get_branch_data(red_net, :reldata, :fault_rate, "3", "4")[1]
	@test get_branch_data(test, :reldata, :length, "3", "5") + get_branch_data(test, :reldata, :length, "5", "6") == get_branch_data(red_net, :reldata, :length, "3", "6")
	@test is_transformer(red_net, "1", "2")
end

test_no_zero = DiGraph(4)
add_edge!(test_no_zero, 1, 2)
add_edge!(test_no_zero, 2, 3)
add_edge!(test_no_zero, 2, 4)
@testset "Check removing of zero impedance lines" begin
	no_zero = remove_zero_impedance_lines(red_net)
	@test nv(no_zero.G) == 4
	@test test_no_zero == DiGraph(no_zero.G)
end
