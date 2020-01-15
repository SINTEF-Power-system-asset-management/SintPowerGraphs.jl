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

function merge_line_segments(network::RadialPowerGraph)::RadialPowerGraph
    red_net = RadialPowerGraph()
    add_vertex!(red_net.G)
    red_net.ref_bus = 1
    # Copy the part of the mpc structure that are not dictionaries.
    # Note, the code does not copy the values only the keys.
    red_net.mpc = Dict(key=> typeof(value)==Dict{String, Any} ? Dict{String, Any}() : value for (key, value) in network.mpc)

    # Set other mpc struct things
    red_net.mpc["baseMVA"] = network.mpc["baseMVA"]
   
    from_bus = 0
    gen_count = 1
    load_count = 1

    n_vertices = 1
    n_edges = 0

    # Keep track of the mapping between new and old bus numbers
    bus_map = Dict(network.ref_bus => 1)

    π = π_segment(0, 0, 0)

    for edge in edges(network.radial)
        if from_bus == 0
            from_bus = src(edge)
        end
        bus = dst(edge)
        neighbor_count = length(neighbors(network.radial, bus))
        # Check if the we have reached a load, generator or end of radial
        if is_gen_bus(network, bus) || is_load_bus(network, bus) || neighbor_count != 1
            n_vertices += 1
            n_edges += 1
            # add the bus and the line
            add_vertex!(red_net.G)
            if from_bus == 57
                @show from_bus
                @show bus
                @show bus_map
                @show bus_map[from_bus]
            end
            add_edge!(red_net.G, bus_map[from_bus], n_vertices)
            
            red_net.mpc["bus"][repr(n_vertices)] = copy(get_bus_data(network, bus))
            red_net.mpc["bus"][repr(n_vertices)]["bus"] = repr(n_vertices)
            red_net.mpc["bus"][repr(n_vertices)]["index"] = repr(n_vertices)
                
            # This can be fixed more elegantly using metaprogramming
            if is_gen_bus(network, bus)
                red_net.mpc["gen"][repr(gen_count)] = get_prop(network.G, bus, :gen)
                red_net.mpc["gen"]["gen_bus"] = bus_map[from_bus]
                set_prop!(red_net.G, n_vertices, :gen, red_net.mpc["gen"])
                set_prop!(red_net.G, n_vertices, :gen_i, gen_count)
                gen_count += 1
            end
            if is_load_bus(network, bus)
                red_net.mpc["load"][repr(load_count)] = get_prop(network.G, bus, :load)
                red_net.mpc["load"]["load_bus"] = bus_map[from_bus]
                set_prop!(red_net.G, n_vertices, :load, red_net.mpc["load"])
                set_prop!(red_net.G, n_vertices, :load_i, load_count)
                load_count += 1
            end
            red_net.mpc["branch"][repr(n_edges)] = copy(get_branch_data(network, src(edge), bus))
            branch = red_net.mpc["branch"][repr(n_edges)]
            branch["f_bus"] = repr(bus_map[from_bus])
            branch["t_bus"] = repr(repr(n_vertices))

            π += get_π_equivalent(network, src(edge), bus)
            branch["br_r"] = real(π.Z)
            branch["br_x"] = imag(π.Z)
            branch["g_fr"] = real(π.Y₁)
            branch["b_fr"] = imag(π.Y₁)
            branch["g_fr"] = real(π.Y₁)
            branch["b_fr"] = real(π.Y₁)

            set_branch_data!(red_net, bus_map[from_bus], n_vertices, branch)
            set_bus_data!(red_net, n_vertices, red_net.mpc["bus"][repr(n_vertices)])
            
            bus_map[bus] = n_vertices

            for field in fieldnames(π_segment)
                setfield!(π, field, 0)
            end

            if neighbor_count == 0
                from_bus = 0
            else
                from_bus = bus
            end
        else
            π += get_π_equivalent(network, src(edge), bus)
        end
    end
    red_net.radial = DiGraph(red_net.G)
    return red_net
end
