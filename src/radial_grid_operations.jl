import PowerModels

function RadialPowerGraph(case_file::String)
    mpc = PowerModels.parse_file(case_file::String)
    G, ref_bus = convert_case(mpc)
    radial = directed_from_feeder(G, ref_bus)
    RadialPowerGraph(G, mpc, ref_bus, radial)
end

function directed_from_feeder(G::MetaDiGraph, feeder_node::Int)
    # Make the graph undirected
    undirected = MetaGraph(G)

    # Return a tree from the feeder node
    return dfs_tree(undirected, feeder_node)
end

#function merge_line_segments(G::RadialPowerGraph)

