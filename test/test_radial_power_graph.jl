using PowerGraphs
using Test 

@testset "Check construction of radial graph" begin
    @test test_graph == test.radial
end

# Create the reduced graph
test_red_graph = DiGraph(6)
add_edge!(test_red_graph, 1, 2)
add_edge!(test_red_graph, 2, 3)
add_edge!(test_red_graph, 3, 4)
add_edge!(test_red_graph, 3, 5)
add_edge!(test_red_graph, 5, 6)
    
red_net = merge_line_segments(test)

@testset "Check line merging" begin
    @test test_red_graph == red_net.radial
    @test test_red_graph != test.radial
    @test red_net.mpc.bus[red_net.mpc.bus.ID .==6,:] == test.mpc.bus[test.mpc.bus.ID .==6,:]
    @test is_load_bus(red_net, 6)
    # The next test is sketchy since the bus does not end up where I expect it to be
    @test get_π_equivalent(red_net, 3, 4) == (get_π_equivalent(test, 3, 5)+get_π_equivalent(test,5,6))
	@test is_switch(red_net, 5, 6)
end

test_no_zero = DiGraph(4)
add_edge!(test_no_zero, 1, 2)
add_edge!(test_no_zero, 2, 3)
add_edge!(test_no_zero, 2, 4)

@testset "Check removing of zero impedance lines" begin
    no_zero = remove_zero_impedance_lines(red_net)
    @test nv(no_zero.G) == 4
    from_feeder = directed_from_feeder(no_zero.G, 1)
    @test test_no_zero == from_feeder
end
