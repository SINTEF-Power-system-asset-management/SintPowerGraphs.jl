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
							keep_transformers::Bool=true,
							aggregators::Dict{Symbol, Dict{Symbol, Float64}}=Dict{Symbol, Dict{Symbol, Float64}}())
	red_net = RadialPowerGraph()
    set_indexing_prop!(red_net.G, :name)
	
    # Set other mpc struct things

    # Keep track of the mapping between new and old bus numbers
	vertices = traverse(MetaGraph(network.G), network.G[network.ref_bus, :name], true)
    from_bus_int = vertices[1]
	#TODO: This hack should not be needed.
	network.radial = MetaDiGraph(dfs_tree(MetaGraph(network.G), network.G[network.ref_bus, :name]))

    # Add the reference bus to network
    temp = get_bus_data(network, network.ref_bus)
    push_bus!(red_net, temp)
	red_net.ref_bus = network.ref_bus

    red_net.mpc.baseMVA = network.mpc.baseMVA
   
    temp = get_gen_data(network, network.ref_bus)
    push_gen!(red_net, temp, network.ref_bus)

    π = π_segment(0, 0, 0)
    edge_list = edges(network.radial)
    orig_vertices = size(vertices, 1)
    index = 1

    while index < orig_vertices
        f_bus_int = vertices[index]
        t_bus_int = vertices[index+1]
        
        # If the last bus we visited was an end bus we need to find an intersection
        if from_bus_int == 0
            find_intersection = true
            go_back = 1
            while find_intersection
                f_bus_int = vertices[index-go_back]
                if has_edge(network.radial, f_bus_int, t_bus_int)
                    from_bus_int = f_bus_int
                    find_intersection = false
                else
                    go_back += 1
                end
            end
		end
		# Fix mapping
		from_bus = network.G[from_bus_int, :name]
		f_bus = network.G[f_bus_int, :name]
		t_bus = network.G[t_bus_int, :name]

        neighbor_count = length(neighbors(network.radial, t_bus_int))
        # Check if the we have reached a load, generator, intersection or end of radial
		
		# A bit sneaky, but I change t_bus and f_bus to the id
		if is_gen_bus(network, t_bus) || is_load_bus(network, t_bus) || neighbor_count != 1 || (keep_switches && is_switch(network, f_bus, t_bus)) || (keep_indicators && is_indicator(network, f_bus, t_bus)) || (keep_switches && is_neighbor_switch(network, f_bus, t_bus)) || (keep_indicators && is_neighbor_indicator(network, f_bus, t_bus)) || (keep_transformers && is_transformer(network, f_bus, t_bus))
            # add the bus and the line
			# get the bus we are adding
			new_bus = get_bus_data(network, t_bus)
            push_bus!(red_net, new_bus)
			
			if keep_loaddata && is_load_bus(network, t_bus)
				push_loaddata!(red_net, get_loaddata(network, t_bus), new_bus.ID)
			end
            
            # This can probably be fixed more elegantly using metaprogramming
            if is_gen_bus(network, t_bus)
				temp = deepcopy(get_gen_data(network, t_bus))
                push_gen!(red_net, temp, t_bus) 
            end
			if !isempty(aggregators)
				for (field, columns) in aggregators
					for (column, data) in columns
						if is_branch_type_in_graph(network, field, f_bus, t_bus)
							agg = aggregators[field][column]+get_branch_data(network, field, column, f_bus, t_bus)
						else
							agg = aggregators[field][column]
						end
							if isempty(getfield(red_net.mpc, field)) || !is_branch_type_in_graph(red_net, field, from_bus, t_bus)
								if is_branch_type_in_graph(network, field, f_bus, t_bus)
								temp = deepcopy(get_branch_data(network,
													   field,
													   f_bus,
													   t_bus))
								temp[column] = agg
									push_branch!(red_net,
												 field,
												 from_bus,
												 t_bus,
												 temp)
								end
							else
								set_branch_data!(red_net,
												field,
												column,
												from_bus,
												t_bus,
												agg)
						end
						aggregators[field][column] = 0.0

					end
				end
			end
			branch = deepcopy(get_branch_data(network, f_bus, t_bus))
            push_branch!(red_net, from_bus, t_bus, branch)
            
            π += get_π_equivalent(network, f_bus, t_bus)
            branch[1, :r] = real(π.Z)
            branch[1, :x] = imag(π.Z)
            branch[1, :b] = 2*real(π.Y₁)

            set_branch_data!(red_net, from_bus, t_bus, branch)

			# Fix from and to bus for switches or fault indicators
			if keep_switches && is_switch(network, f_bus, t_bus)
				push_switch!(red_net,
							 from_bus,
							 t_bus,
							deepcopy(get_switch_data(network,
											f_bus,
											t_bus)[1,:]))
			end
			if keep_indicators && is_indicator(network, f_bus, t_bus)
				push_indicator!(red_net,
								from_bus,
								t_bus,
								deepcopy(get_indicator_data(network,
												f_bus,
												t_bus)[1,:]))
			end
			if keep_transformers && is_transformer(network, f_bus, t_bus)
				push_transformer!(red_net,
								from_bus,
								t_bus,
								deepcopy(get_transformer_data(network,
												f_bus,
												t_bus)[1,:]))
			end

            for field in fieldnames(π_segment)
                setfield!(π, field, 0)
            end

            if neighbor_count == 0
                from_bus_int = 0
            else
                from_bus_int = t_bus_int
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
    red_net.radial = MetaDiGraph(red_net.G)
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
			# Ensure that swing bus is connected
			t_bus_type = network.bus[network.bus.ID .== t_bus, :type][1]
            if  t_bus_type == 3
                network.bus[f_bus, :type] = 3
            end
            # Connect the buses that were disconnected
            network.branch[network.branch.f_bus .== t_bus, :f_bus] .= f_bus
            network.branch[network.branch.t_bus .== t_bus, :t_bus] .= f_bus
           
            # Move what may have been on the bus
            network.gen[network.gen.ID .== t_bus, :ID] .= f_bus

            delete_bus!(network, t_bus)
        end
    end
    delete!(network.branch, delete_rows)

    G, ref_bus = read_case!(network)
    return PowerGraph(G, network, ref_bus)
end
