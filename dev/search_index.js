var documenterSearchIndex = {"docs":
[{"location":"#SintPowerGraphs.jl","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.jl","text":"","category":"section"},{"location":"","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.jl","text":"Julia package for treating a power system as a graph.","category":"page"},{"location":"","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.jl","text":"The library is in very early development and probably only usable and useful for me. I expect the type hierarchy to undergo large changes as I learn Julia.","category":"page"},{"location":"#Method-documentation","page":"SintPowerGraphs.jl","title":"Method documentation","text":"","category":"section"},{"location":"","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.jl","text":"Modules = [SintPowerGraphs]","category":"page"},{"location":"","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.jl","text":"Modules = [SintPowerGraphs]","category":"page"},{"location":"#SintPowerCase.get_branch_data-Tuple{SintPowerGraphs.PowerGraphBase, String, String}","page":"SintPowerGraphs.jl","title":"SintPowerCase.get_branch_data","text":"get_branch_data(network::PowerGraphBase, f_bus_id::Int, t_bus::Int)\n\nReturn a dictionary containing the dictionary with the buse data.\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerCase.get_gen_indices-Tuple{PowerGraph}","page":"SintPowerGraphs.jl","title":"SintPowerCase.get_gen_indices","text":"Return indices of the buses with generators.\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerCase.get_load_indices-Tuple{PowerGraph}","page":"SintPowerGraphs.jl","title":"SintPowerCase.get_load_indices","text":"Return indices of the buses with generators.\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerCase.is_gen_bus-Tuple{SintPowerGraphs.PowerGraphBase, String}","page":"SintPowerGraphs.jl","title":"SintPowerCase.is_gen_bus","text":"is_gen_bus(network::PowerGraphBase, bus_id::Int)\n\nReturns true if the bus bus_id is a load.\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerCase.is_load_bus-Tuple{SintPowerGraphs.PowerGraphBase, String}","page":"SintPowerGraphs.jl","title":"SintPowerCase.is_load_bus","text":"is_load_bus(network::PowerGraphBase, bus_id::Int)\n\nReturns true if the bus bus_id is a load.\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerGraphs.get_bus_data!-Tuple{SintPowerGraphs.PowerGraphBase, String}","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.get_bus_data!","text":"get_bus_data!(network::PowerGraphBase, bus_id::String)\n\nReturn a DataFrameRow with the bus data.\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerGraphs.get_bus_data-Tuple{SintPowerGraphs.PowerGraphBase, String}","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.get_bus_data","text":"get_bus_data(network::PowerGraphBase, bus_id::Int)\n\nReturn a copy of the DataFrameRow with the bus data.\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerGraphs.get_id_idx-Tuple{PowerGraph, Symbol, String}","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.get_id_idx","text":"Returns the index of the  element elm with index ID\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerGraphs.get_island_incidence_matrix-Tuple{SintPowerGraphs.PowerGraphBase}","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.get_island_incidence_matrix","text":"Return incidence_matrix for islands in system\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerGraphs.get_islanded_branches-Tuple{Matrix{Int64}, Vector{Vector{Int64}}}","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.get_islanded_branches","text":"Return branches in islands.\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerGraphs.get_islanded_buses-Tuple{SintPowerGraphs.PowerGraphBase}","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.get_islanded_buses","text":"Return list of buses in islands\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerGraphs.get_susceptance_vector-Tuple{SintPowerGraphs.PowerGraphBase}","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.get_susceptance_vector","text":"get_susceptance_vector(network::PowerGraphBase)::Array{Float64}\nReturns the susceptance vector for performing a dc power flow.\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerGraphs.get_π_equivalent-Tuple{SintPowerGraphs.PowerGraphBase, String, String}","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.get_π_equivalent","text":"get_π_equivalent(network::PowerGraphBase, from_bus::Int, to_bus::Int)\n\nReturns the π-equivalent of a line segment.\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerGraphs.merge_line_segments-Tuple{RadialPowerGraph}","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.merge_line_segments","text":"merge_line_segments(network, keep)\n\n\tMerges consecutive line segments not separated by loads or generators.\n\n\t# Arguments\n\t- `network::RadialPowerGraph`: The network to merge line segments on\n\t- `keep_switches`::Bool=true: Keep switches.\n\t- `keep_indicators`::Bool=true: Keep indicators.\n\t- `keep_loaddata`::Bool=true: Keep loaddata.\n\t- `aggregators`::Dict{Symbol, Dict{Strig, Any}}=nothing: Sum up columns of the field Symbol given by String.\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerGraphs.remove_lines_by_value","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.remove_lines_by_value","text":"Remove lines from a case. Whether or not a line should be removed is determined by the function func, and the tolerance tol.\n\n\n\n\n\n","category":"function"},{"location":"#SintPowerGraphs.subgraph","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.subgraph","text":"Make a subgraph out of all descendents with a given node as root\n\n\n\n\n\n","category":"function"},{"location":"#SintPowerGraphs.swapcols!-Tuple{AbstractMatrix, Integer, Integer}","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.swapcols!","text":"Method to efficiently swap columns taken from the internet\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerGraphs.swaprows!-Tuple{AbstractMatrix, Integer, Integer}","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.swaprows!","text":"Method to efficiently swap rows based on swapcols!\n\n\n\n\n\n","category":"method"},{"location":"#SintPowerGraphs.traverse","page":"SintPowerGraphs.jl","title":"SintPowerGraphs.traverse","text":"Start at a node and traverse DFS/BFS, recording order nodes were seen Node that the order branches are traversed is not determined (the natural ordering from :args in the edges is not used...yet)\n\n\n\n\n\n","category":"function"}]
}
