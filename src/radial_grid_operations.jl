
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
    
    gen_count = 1
    load_count = 1

    n_vertices = 1
    n_edges = 0

    # Keep track of the mapping between new and old bus numbers
    bus_map = Dict(network.ref_bus => 1)

    π = π_segment(0, 0, 0)
    edge_list = edges(network.radial)
    vertices = dfs_iter(network.radial, network.ref_bus)
    orig_vertices = size(vertices, 1)
    from_bus = vertices[1]
    index = 1
    while index < orig_vertices
        f_bus = vertices[index]
        t_bus = vertices[index+1]
        
        # If the last bus we visited were an end bus we need to find an intersection
        if from_bus == 0
            find_intersection = true
            go_back = 1
            while find_intersection
                f_bus = vertices[index-go_back]
                if has_edge(network.radial, f_bus, t_bus)
                    from_bus = f_bus
                    find_intersection = false
                else
                    go_back += 1
                end
            end
        end

        neighbor_count = length(neighbors(network.radial, t_bus))
        # Check if the we have reached a load, generator, intersection or end of radial
        if is_gen_bus(network, t_bus) || is_load_bus(network, t_bus) || neighbor_count != 1
            n_vertices += 1
            n_edges += 1
            # add the bus and the line
            add_vertex!(red_net.G)
            add_edge!(red_net.G, bus_map[from_bus], n_vertices)
            
            red_net.mpc["bus"][repr(n_vertices)] = copy(get_bus_data(network, t_bus))
            red_net.mpc["bus"][repr(n_vertices)]["bus"] = repr(n_vertices)
            red_net.mpc["bus"][repr(n_vertices)]["index"] = repr(n_vertices)
                
            # This can be fixed more elegantly using metaprogramming
            if is_gen_bus(network, t_bus)
                red_net.mpc["gen"][repr(gen_count)] = get_prop(network.G, t_bus, :gen)
                red_net.mpc["gen"]["gen_bus"] = bus_map[from_bus]
                set_prop!(red_net.G, n_vertices, :gen, red_net.mpc["gen"])
                set_prop!(red_net.G, n_vertices, :gen_i, gen_count)
                gen_count += 1
            end
            if is_load_bus(network, t_bus)
                red_net.mpc["load"][repr(load_count)] = get_prop(network.G, t_bus, :load)
                red_net.mpc["load"]["load_bus"] = bus_map[from_bus]
                set_prop!(red_net.G, n_vertices, :load, red_net.mpc["load"])
                set_prop!(red_net.G, n_vertices, :load_i, load_count)
                load_count += 1
            end
            red_net.mpc["branch"][repr(n_edges)] = copy(get_branch_data(network, f_bus, t_bus))
            branch = red_net.mpc["branch"][repr(n_edges)]
            branch["f_bus"] = repr(bus_map[from_bus])
            branch["t_bus"] = repr(repr(n_vertices))

            π += get_π_equivalent(network, f_bus, t_bus)
            branch["br_r"] = real(π.Z)
            branch["br_x"] = imag(π.Z)
            branch["g_fr"] = real(π.Y₁)
            branch["b_fr"] = imag(π.Y₁)
            branch["g_fr"] = real(π.Y₁)
            branch["b_fr"] = real(π.Y₁)

            set_branch_data!(red_net, bus_map[from_bus], n_vertices, branch)
            set_bus_data!(red_net, n_vertices, red_net.mpc["bus"][repr(n_vertices)])
            
            bus_map[t_bus] = n_vertices

            for field in fieldnames(π_segment)
                setfield!(π, field, 0)
            end

            if neighbor_count == 0
                from_bus = 0
            else
                from_bus = t_bus
            end
        else
            @show f_bus
            @show t_bus
            π += get_π_equivalent(network, f_bus, t_bus)
            @show π 
        end
        index += 1
    end
    red_net.radial = DiGraph(red_net.G)
    return red_net
end
