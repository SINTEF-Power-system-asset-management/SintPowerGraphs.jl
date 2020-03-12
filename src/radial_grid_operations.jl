
function directed_from_feeder(G::DiGraph, feeder_node::Int)
    # Make the graph undirected
    undirected = SimpleGraph(G)

    # Return a tree from the feeder node
    return dfs_tree(undirected, feeder_node)
end

"""
	merge_line_segments(network, keep)

		Merges consecutive line segments not separated by loads or generators.

		# Arguments
		- `network::RadialPowerGraph`: The network to merge line segments on
		- `keep_switches`::Bool=true: Keep switches.
		- `keep_indicators`::Bool=true: Keep indicators.
		- `keep_loaddata`::Bool=true: Keep loaddata.
		- `aggregators`::Dict{Symbol, Dict{Strig, Any}}=nothing: Sum up columns of the field Symbol given by String.
"""
function merge_line_segments(network::RadialPowerGraph;
							keep_switches::Bool=true,
							keep_indicators::Bool=true,
							keep_loaddata::Bool=true,
							aggregators::Dict{Symbol, Dict{Symbol, Float64}}=Dict{Symbol, Dict{Symbol, Float64}}())
	red_net = RadialPowerGraph()
    red_net.ref_bus = 1
	
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
    temp = get_bus_data(network, network.ref_bus)
    push_bus!(red_net, temp)

    red_net.mpc.baseMVA = network.mpc.baseMVA
   
    temp = get_gen_data(network, network.ref_bus)
    push_gen!(red_net, temp, n_vertices)

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
		if is_gen_bus(network, t_bus) || is_load_bus(network, t_bus) || neighbor_count != 1 || (keep_switches && is_switch(network, f_bus, t_bus)) || (keep_indicators && is_indicator(network, f_bus, t_bus)) || (keep_switches && is_neighbor_switch(network, f_bus, t_bus)) || (keep_indicators && is_neighbor_indicator(network, f_bus, t_bus))
            n_vertices += 1
            n_edges += 1
            # add the bus and the line
            push_bus!(red_net, get_bus_data(network, t_bus))
			
			if keep_loaddata && is_load_bus(network, t_bus)
				push_loaddata!(red_net, get_loaddata(network, t_bus), n_vertices)
			end
            
            # This can probably be fixed more elegantly using metaprogramming
            if is_gen_bus(network, t_bus)
                temp = get_gen_data(network, t_bus)
                push_gen!(red_net, temp, n_vertices) 
            end
			if !isempty(aggregators)
				for (field, columns) in aggregators
					for (column, data) in columns
						temp = get_branch_data(network,
											   field,
											   f_bus,
											   t_bus)
						temp[column] = aggregators[field][column]+get_branch_data(network, field, column, f_bus, t_bus)
						push_branch!(red_net,
									 field,
									 bus_map[from_bus],
									 n_vertices,
									 temp)
						aggregators[field][column] = 0.0
					end
				end
			end
            branch = get_branch_data(network, f_bus, t_bus)
            push_branch!(red_net, bus_map[from_bus], n_vertices, branch)
            
            π += get_π_equivalent(network, f_bus, t_bus)
            branch[1, :r] = real(π.Z)
            branch[1, :x] = imag(π.Z)
            branch[1, :b] = 2*real(π.Y₁)

            set_branch_data!(red_net, bus_map[from_bus], n_vertices, branch)

			# Fix from and to bus for switches or fault indicators
			if keep_switches && is_switch(network, f_bus, t_bus)
				push_switch!(red_net,
							 bus_map[from_bus],
							 n_vertices,
							get_switch_data(network,
											f_bus,
											t_bus)[1,:])
			end
			if keep_indicators && is_indicator(network, f_bus, t_bus)
				push_indicator!(red_net,
								bus_map[from_bus],
								n_vertices,
								get_indicator_data(network,
												f_bus,
												t_bus)[1,:])
			end

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
			if  !isempty(aggregators)
				for (field, columns) in aggregators
					for (column, data) in columns
						aggregators[field][column] += get_branch_data(network, field, column, f_bus, t_bus)
					end
				end
			end
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
    network = deepcopy(network_orig.mpc)
    delete_rows = []
    for branch in eachrow(network.branch)
        if series_impedance_norm(get_π_equivalent(branch))<=tol
            t_bus = branch.t_bus
            f_bus = branch.f_bus
            append!(delete_rows, getfield(branch, :row))
            if network.bus[t_bus, :type] == 3
                network.bus[f_bus, :type] = 3
            end
            # Connect the buses that were disconnected
            network.branch[network.branch.f_bus .== t_bus, :f_bus] .= f_bus
            network.branch[network.branch.t_bus .== t_bus, :t_bus] .= f_bus
           
            # Move what may have been on the bus
            network.gen[network.gen.bus .== t_bus, :bus] .= f_bus

            # Change bus numbers for generators
            network.gen[network.gen.bus .> t_bus, :bus] .-=1
            
            # Change bus numbers for branches
            network.branch[network.branch.f_bus .> t_bus, :f_bus] .-=1
            network.branch[network.branch.t_bus .> t_bus, :t_bus] .-=1
            
            delete_bus!(network, t_bus)
        end
    end
    deleterows!(network.branch, delete_rows)

    G, ref_bus = read_case(network)
    return PowerGraph(G, network, ref_bus)
end
