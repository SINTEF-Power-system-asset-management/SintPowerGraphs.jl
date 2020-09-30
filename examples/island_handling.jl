# # Example demonstrating how to get incidence matrix for a system split into two islands 

using PowerGraphs
using GraphPlot
using LinearAlgebra

# We start by loading in the case.

fname = joinpath(@__DIR__, "cases", "island_test.toml")
case_data = Case(fname)
graph = PowerGraph(case_data)

# After we have loaded the case we can plot it using GraphPlot

gplot(graph.G, edgelabel=1:n_edges(graph), nodelabel=1:n_vertices(graph))

# From the plot of the graph, we can see that the system can be easily split into two islands.

take_out_line!(graph, 4)


# After we take out the line it's nice to plot the system again

layout=(args...)->spring_layout(args...; C=10)
gplot(graph.G, edgelabel=[1,2,3,5,6,7], layout = layout, nodelabel=1:n_vertices(graph))

# We can now see that the system is split into two islands. The incidence matrix for this system is given below.

A = get_incidence_matrix(graph, true)

# A problem with this matrix is that when we try to do a dc power flow the determinant we must calculate will be zero. For the purpose of demonstrating this we assume bus 1 to be the reference bus.

B = get_dc_admittance_matrix(graph, true)
det(B[2:6, 2:6])

# To solve this problem it is useful to order the rows and columns of the incidence such that it becomes block diagonal with one block per island.

A, bus_mapping, branch_mapping = get_island_incidence_matrix(graph)

A

bus_mapping

branch_mapping

# Now we can easily invert the matrix contained in the block diagonal containing the reference bus.

b = get_susceptance_vector(graph, true)
# We have to remember to swap the position of the suceptances
b[branch_mapping[1][1]], b[branch_mapping[2][1]] = b[branch_mapping[2][1]], b[branch_mapping[1][1]]
D = Diagonal(b)
B = A[1:3,1:3]'*D[1:3,1:3]*A[1:3,1:3]

det(B[2:3, 2:3])
