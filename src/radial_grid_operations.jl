
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
    gen_count = 1
    load_count = 1

    n_vertices = 1
    n_edges = 0
    
    # Keep track of the mapping between new and old bus numbers
    bus_map = Dict(network.ref_bus => 1)
    vertices = dfs_iter(network.radial, network.ref_bus)
    from_bus = vertices[1]

    # Add the reference bus to network
    red_net.mpc["bus"][repr(n_vertices)] = copy(get_bus_data(network, network.ref_bus))
    red_net.mpc["bus"][repr(n_vertices)]["bus_i"] = n_vertices
    red_net.mpc["bus"][repr(n_vertices)]["index"] = n_vertices
    
    red_net.mpc["baseMVA"] = network.mpc["baseMVA"]
    red_net.mpc["gen"][repr(gen_count)] = get_prop(network.G, network.ref_bus, :gen)
    red_net.mpc["gen"][repr(gen_count)]["gen_bus"] = bus_map[from_bus]
    set_prop!(red_net.G, n_vertices, :gen, red_net.mpc["gen"])
    set_prop!(red_net.G, n_vertices, :gen_i, gen_count)

    π = π_segment(0, 0, 0)
    edge_list = edges(network.radial)
    orig_vertices = size(vertices, 1)
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
            red_net.mpc["bus"][repr(n_vertices)]["bus_i"] = n_vertices
            red_net.mpc["bus"][repr(n_vertices)]["index"] = n_vertices
                
            # This can probably be fixed more elegantly using metaprogramming
            if is_gen_bus(network, t_bus)
                red_net.mpc["gen"][repr(gen_count)] = get_prop(network.G, t_bus, :gen)
                red_net.mpc["gen"][repr(gen_count)]["gen_bus"] = bus_map[from_bus]
                set_prop!(red_net.G, n_vertices, :gen, red_net.mpc["gen"])
                set_prop!(red_net.G, n_vertices, :gen_i, gen_count)
                red_net.mpc["gen"][repr(gen_count)]["index"] = gen_count
                gen_count += 1
            end
            if is_load_bus(network, t_bus)
                red_net.mpc["load"][repr(load_count)] = get_prop(network.G, t_bus, :load)
                red_net.mpc["load"][repr(load_count)]["load_bus"] = bus_map[from_bus]
                set_prop!(red_net.G, n_vertices, :load, red_net.mpc["load"])
                set_prop!(red_net.G, n_vertices, :load_i, load_count)
                red_net.mpc["load"][repr(load_count)]["index"] = load_count
                load_count += 1
            end
            red_net.mpc["branch"][repr(n_edges)] = copy(get_branch_data(network, f_bus, t_bus))
            branch = red_net.mpc["branch"][repr(n_edges)]
            branch["f_bus"] = bus_map[from_bus]
            branch["t_bus"] = n_vertices
            branch["index"] = n_edges

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
            π += get_π_equivalent(network, f_bus, t_bus)
        end
        index += 1
    end
    red_net.radial = DiGraph(red_net.G)
    return red_net
end

function remove_zero_impedance_lines(network::PowerGraphBase)
    return remove_low_impedance_lines(network, 0.0)
end

function remove_low_impedance_lines(network_orig::PowerGraphBase, tol::Float64=0.0)
    network = deepcopy(network_orig)
    temp = MetaGraph(network.G)
    for edge in edges(temp)
        if series_impedance_norm(get_π_equivalent(network, edge))<=tol
            branch = get_branch_data(network, edge)
            f_bus = branch["f_bus"]
            t_bus = branch["t_bus"]
            delete!(network.mpc["branch"], repr(branch["index"]))
            if network.mpc["bus"][repr(t_bus)]["bus_type"] == 3
                network.mpc["bus"][repr(f_bus)]["bus_type"] = 3
            end
            delete!(network.mpc["bus"], repr(t_bus))
            # Connect the buses that were disconnected
            for neighbor in neighbors(temp, t_bus)
                if neighbor != f_bus
                    to_connect = get_branch_data(network, t_bus, neighbor)
                    if to_connect["f_bus"] == t_bus
                        to_connect["f_bus"] = f_bus
                    elseif to_connect["t_bus"] == t_bus
                        to_connect["t_bus"] = f_bus
                    else
                        ErrorException("Power system not connected")
                    end
                end
            end
            # Move loads or generators that may have been on the bus
            for gl_string in ["load", "gen"]
                for gl in values(network.mpc[gl_string])
                    bus = string(gl_string, "_bus")
                    if gl[bus] == t_bus
                        gl[bus] = f_bus
                    end
                end
            end
        end
    end
    # Make network consistent with graph
    key_list = sort([parse(Int, elm) for elm in keys(network.mpc["bus"])])
    fake = Dict{String, Any}()
    for (index, key) in enumerate(key_list)
        fake[repr(index)] = network.mpc["bus"][repr(key)]
        fake[repr(index)]["bus_i"] = index
        fake[repr(index)]["index"] = index
        for branch in values(network.mpc["branch"])
            if branch["f_bus"] ==  key
                branch["f_bus"] = index
            end
            if branch["t_bus"] == key
                branch["t_bus"] = index
            end
        end
        for gl_string in ["load", "gen"]
            for gl in values(network.mpc[gl_string])
                bus = string(gl_string, "_bus")
                if gl[bus] ==  key
                    gl[bus] = index
                end
            end
        end
    end
    # There definitively has to be a faster and better way to do this
    network.mpc["bus"] = fake
    
    # Sort the branches and make numbering consistent
    fake = Dict{String, Any}()
    key_list = sort([parse(Int, elm) for elm in keys(network.mpc["branch"])])
    for (index, key) in enumerate(key_list)
        fake[repr(index)] = network.mpc["branch"][repr(key)]
        fake[repr(index)]["index"] = index
    end
    network.mpc["branch"] = fake

    G, ref_bus = convert_case(network.mpc)
    return PowerGraph(G, network.mpc, ref_bus)
end
