
# Create the graph we should end up with
test_graph = DiGraph(6)
add_edge!(test_graph, 1, 2)
add_edge!(test_graph, 2, 3)
add_edge!(test_graph, 3, 4)
add_edge!(test_graph, 3, 5)
add_edge!(test_graph, 5, 6)

# Read in the system we are testing on
test = RadialPowerGraph(joinpath(@__DIR__, "cases", "bus_6.toml"))

