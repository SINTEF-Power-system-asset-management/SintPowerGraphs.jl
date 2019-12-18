using PowerGraphs
using Test 
using LightGraphs

# Create the graph we should end up with
G = Graph(5)
add_edge!(G, 1, 2)
add_edge!(G, 2, 3)
add_edge!(G, 3, 4)
add_edge!(G, 3, 5)

test = RadialPowerGraph("cases/bus_5.m")

@test G == test.radial


