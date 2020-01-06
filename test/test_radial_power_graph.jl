using PowerGraphs
using Test 

@testset "Check construction of radial graph" begin
    @test test_graph == test.radial
end

# Create the reduced graph
test_red_graph = DiGraph(5)
add_edge!(test_red_graph, 1, 2)
add_edge!(test_red_graph, 2, 3)
add_edge!(test_red_graph, 3, 4)
add_edge!(test_red_graph, 3, 5)

@testset "Check line merging" begin
    red_net = merge_line_segments(test)
    @test test_red_graph == red_net.radial
    @test test_red_graph != test.radial
    @test red_net.mpc["bus"]["5"]["va"] == test.mpc["bus"]["6"]["va"]
    @test is_load_bus(red_net, 5)
    @test get_π_equivalent(red_net, 3, 5) == (get_π_equivalent(test, 3, 5)+get_π_equivalent(test,5,6))

end

