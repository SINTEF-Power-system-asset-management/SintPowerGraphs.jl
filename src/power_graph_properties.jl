using LightGraphs.LinAlg
using LinearAlgebra
"""
    get_bus_data!(network::PowerGraphBase, bus_id::String)

    Return a DataFrameRow with the bus data.
"""
function get_bus_data!(network::PowerGraphBase, bus_id::String)::DataFrameRow
    return get_bus!(network.mpc, bus_id)
end

"""
    get_bus_data(network::PowerGraphBase, bus_id::Int)

    Return a copy of the DataFrameRow with the bus data.
"""
function get_bus_data(network::PowerGraphBase, bus_id::String)::DataFrameRow
    return get_bus(network.mpc, bus_id)
end

function get_gen_data!(network::PowerGraphBase, bus_id::String)::DataFrame
    return get_gen!(network.mpc, bus_id)
end

function get_gen_data(network::PowerGraphBase, bus_id::String)::DataFrame
    return get_gen(network.mpc, bus_id)
end

function get_loaddata(network::PowerGraphBase, bus_id::String)::DataFrame
    return get_loaddata(network.mpc, bus_id)
end

function push_bus!(network::PowerGraphBase, data::DataFrameRow)
    add_vertex!(network.G)
	set_prop!(network.G, nv(network.G) , :name, string(data.ID))
    push_bus!(network.mpc, data)
end

function push_gen!(network::PowerGraphBase, data::DataFrame)
    for gen in eachrow(data)
        push_gen!(network, gen)
    end
end

function push_gen!(network::PowerGraphBase, data::DataFrame, bus::String)
    for gen in eachrow(data)
        push_gen!(network, gen, bus)
    end
end

function push_gen!(network::PowerGraphBase, data::DataFrameRow)
    push_gen!(network.mpc, data)
end

function push_gen!(network::PowerGraphBase, data::DataFrameRow, bus::String)
    data[:ID] = bus
    push_gen!(network, data)
end

function push_loaddata!(network::PowerGraphBase, data::DataFrameRow)
    push_loaddata!(network.mpc, data)
end

function push_loaddata!(network::PowerGraphBase, data::DataFrameRow, bus::String)
    data[:bus] = bus
    push_loaddata!(network, data)
end

function push_loaddata!(network::PowerGraphBase, data::DataFrame, bus::String)
    for load in eachrow(data)
        push_loaddata!(network, load, bus)
    end
end

function push_branch!(network::PowerGraphBase, f_bus::String, t_bus::String, data::DataFrameRow)
	push_branch!(network.mpc, f_bus, t_bus, data)
    add_edge!(network.G,
			  network.G[string(f_bus), :name],
			  network.G[string(t_bus), :name])
end

function push_switch!(network::PowerGraphBase, f_bus::String, t_bus::String, data::DataFrameRow)
	push_switch!(network.mpc, f_bus, t_bus, data)
end

function push_indicator!(network::PowerGraphBase, f_bus::String, t_bus::String, data::DataFrameRow)
	push_indicator!(network.mpc, f_bus, t_bus, data)
end

function push_transformer!(network::PowerGraphBase, f_bus::String, t_bus::String, data::DataFrameRow)
	push_transformer!(network.mpc, f_bus, t_bus, data)
end

function push_branch!(network::PowerGraphBase, f_bus::String, t_bus::String, data::DataFrame)
    for branch in eachrow(data)
        push_branch!(network, f_bus, t_bus, branch)
    end
end

function push_branch!(network::PowerGraphBase, type::Symbol, f_bus::String, t_bus::String, data::DataFrameRow)
	push_branch!(network.mpc, type, f_bus, t_bus, data)
end

"""
    get_branch_data(network::PowerGraphBase, f_bus_id::Int, t_bus::Int)

    Return a dictionary containing the dictionary with the buse data.
"""
function get_branch_data(network::PowerGraphBase, f_bus::String, t_bus::String)::DataFrame
    if has_edge(network.G, f_bus, t_bus)
        return get_branch(network.mpc, f_bus, t_bus)
    else
        return get_branch(network.mpc, t_bus, f_bus)
    end
end

function get_branch_data(network::PowerGraphBase, type::Symbol, f_bus::String,
						 t_bus::String)::DataFrame
	get_branch_data(network.mpc, type, f_bus, t_bus)
end

function get_branch_data(network::PowerGraphBase, type::Symbol, column::Symbol, f_bus::String,
						 t_bus::String)
	get_branch_data(network.mpc, type, column, f_bus, t_bus)
end

function get_reliability_data(network::PowerGraphBase, f_bus::String, t_bus::String)::DataFrame
	temp = get_branch_data(network, :reldata, f_bus, t_bus)
	if nrow(temp) == 0
		@warn string("Branch ", f_bus, "-", t_bus, " does not have reliablity data")
		@warn "Returning zero filled reliablity data."
		row = []
		for name in names(temp)
			if name == "f_bus"
				push!(row, f_bus)
			elseif name == "t_bus"
				push!(row, t_bus)
			else
				if isa(network.mpc.reldata[1, name], Number)
					append!(row, 0)
				else
					append!(row, "")
				end
			end
		end
		push!(temp, row)
	end
	return temp
end

function is_branch_type_in_graph(network::PowerGraphBase, type::Symbol, f_bus::String,
								 t_bus::String)::Bool
	is_branch_type_in_case(network.mpc, type, f_bus, t_bus)
end

function set_branch_data!(network::PowerGraphBase, type::Symbol, column::Symbol, f_bus::String, t_bus::String, data)
	set_branch_data!(network.mpc, type, column, f_bus, t_bus, data)
end

function get_switch_data(network::PowerGraphBase, f_bus::String, t_bus::String)::DataFrame
	get_switch(network.mpc, f_bus, t_bus)
end

function get_indicator_data(network::PowerGraphBase, f_bus::String, t_bus::String)::DataFrame
	get_indicator(network.mpc, f_bus, t_bus)
end

function get_transformer_data(network::PowerGraphBase, f_bus::String, t_bus::String)::DataFrame
	get_transformer(network.mpc, f_bus, t_bus)
end

function set_branch_data!(network::PowerGraphBase, f_bus::String, t_bus::String, data::DataFrame)
    set_branch!(network.mpc, f_bus, t_bus, data)
end

function set_switch_data!(network::PowerGraphBase, f_bus::String, t_bus::String, data::DataFrame)
    set_switch!(network.mpc, f_bus, t_bus, data)
end

function set_indicator_data!(network::PowerGraphBase, f_bus::String, t_bus::String, data::DataFrame)
    set_indicator!(network.mpc, f_bus, t_bus, data)
end

"""
    is_load_bus(network::PowerGraphBase, bus_id::Int)

    Returns true if the bus bus_id is a load.
"""
function is_load_bus(network::PowerGraphBase, bus_id::String)::Bool
	return any(x-> x>0, network.mpc.bus[network.mpc.bus.ID.==bus_id, :Pd])
end

"""
    is_gen_bus(network::PowerGraphBase, bus_id::Int)

    Returns true if the bus bus_id is a load.
"""
function is_gen_bus(network::PowerGraphBase, bus_id::String)
    return is_gen_bus(network.mpc, bus_id)
end

function is_indicator(network::PowerGraphBase, f_bus::String, t_bus::String)
	is_indicator(network.mpc, f_bus, t_bus)
end

function is_switch(network::PowerGraphBase, f_bus, t_bus)
	is_switch(network.mpc, f_bus, t_bus)
end

function is_transformer(network::PowerGraphBase, f_bus, t_bus)
	is_transformer(network.mpc, f_bus, t_bus)
end

function is_neighbor_switch(network::PowerGraphBase, f_bus::String, t_bus::String)
	is_neighbor_switch(network.mpc, f_bus, t_bus)
end

function is_neighbor_indicator(network::PowerGraphBase, f_bus::String, t_bus::String)
	is_neighbor_indicator(network.mpc, f_bus, t_bus)
end

"""
    get_π_equivalent(network::PowerGraphBase, from_bus::Int, to_bus::Int)

    Returns the π-equivalent of a line segment.
"""
function get_π_equivalent(network::PowerGraphBase, from_bus::String, to_bus::String)::π_segment
    branch = get_branch_data(network, from_bus, to_bus)
    if nrow(branch)>1
        @warn string("The branch ", repr(from_bus), "-", repr(to_bus),
                     " is parallel")
    elseif nrow(branch) == 0
        return π_segment(0, 0, 0)
    end
    return get_π_equivalent(branch[1,:])
end

function get_π_equivalent(branch::DataFrameRow)::π_segment
    return π_segment(branch[:r]+branch[:x]im,
                     0+0.5*branch[:b]im,
                     0+0.5*branch[:b]im,)
end

"""
    get_dc_admittance_matrix(network::PowerGraphBase)::Array{Float64}
    Returns the admittance matrix for performing a dc power flow.
"""
function get_dc_admittance_matrix(network::PowerGraphBase)::Array{Float64, 2}
    A = incidence_matrix(network.G)
	return A*Diagonal(get_susceptance_vector(network))*A'
end

function get_dc_admittance_matrix(network::PowerGraphBase, consider_status::Bool)::Array{Float64, 2}
    A = get_incidence_matrix(network.mpc, consider_status)
	return A*Diagonal(get_susceptance_vector(network, consider_status))*A'
end

function get_incidence_matrix(network::PowerGraphBase)::Array{Int64, 2}
	return get_incidence_matrix(network.mpc)
end

function get_incidence_matrix(network::PowerGraphBase, consider_status::Bool)::Array{Int64, 2}
	return get_incidence_matrix(network.mpc, consider_status)
end

"""
    get_susceptance_vector(network::PowerGraphBase)::Array{Float64}
    Returns the susceptance vector for performing a dc power flow.
"""
function get_susceptance_vector(network::PowerGraphBase)::Array{Float64,1}
    return get_susceptance_vector(network.mpc)
end

function get_susceptance_vector(network::PowerGraphBase, consider_status::Bool)::Array{Float64,1}
    return get_susceptance_vector(network.mpc, consider_status)
end

function get_power_injection_vector(network::PowerGraphBase)::Array{Float64, 1}
    return get_power_injection_vector(network.mpc)
end

function get_power_injection_vector_pu(network::PowerGraphBase)::Array{Float64, 1}
    return get_power_injection_vector(network.mpc)/network.mpc.baseMVA
end

function n_edges(network::PowerGraphBase)::Int
    return ne(network.G)
end

function n_vertices(network::PowerGraphBase)::Int
    return nv(network.G)
end

function take_out_line!(network::PowerGraphBase, id::String)
	take_out_line!(network.mpc, id)
    branches = get_branch(network.mpc, id)
	for branch in eachrow(branches)
		rem_edge!(network.G, network.G[branch.f_bus, :name],
				  network.G[branch.t_bus, :name])
	end
end

function put_back_line!(network::PowerGraphBase, id::String)
    branch = get_branch(network.mpc, id)
	add_edge!(network.G, network.G[branch.f_bus, :name],
			  network.G[branch.t_bus, :name])
end

function get_line_lims_pu(network::PowerGraphBase)::Array{Float64}
    return get_line_lims_pu(network.mpc)
end

"""Return list of buses in islands"""
function get_islanded_buses(network::PowerGraphBase)::Array{Array{Int64,1},1}
	connected_components(network.G)
end

"""Return incidence_matrix for islands in system"""
function get_island_incidence_matrix(network::PowerGraphBase)::Tuple{Array{Int64, 2},
																	 Array{Array{Int64, 1}, 1},
																	 Array{Array{Int64, 1}, 1},
																	 Array{Array{Int64, 1}, 1}}
	get_island_incidence_matrix(get_incidence_matrix(network, true),
								get_islanded_buses(network))
end

function get_island_incidence_matrix(A::Array{Int64, 2},
									 islands::Array{Array{Int64, 1}, 1})::
	Tuple{Array{Int64, 2}, Array{Array{Int64, 1}, 1}, Array{Array{Int64, 1}, 1}, Array{Array{Int64, 1}, 1}}
	# At the moment I only consider two islands.
	swaps = 1
	bus_mapping = [Array{Int64, 1}(undef, 0) for a in 1:2]
	for bus in islands[1]
		if bus > size(islands[1], 1)
			swapcols!(A, bus, islands[2][swaps])
			append!(bus_mapping[1], bus)
			append!(bus_mapping[2], islands[2][swaps])
			swaps += 1
		end
	end
	
	# Figure out which branches are in the island
	branches = get_islanded_branches(A, islands)
	
	swaps = 1
	branch_mapping = [Array{Int64, 1}(undef, 0) for a in 1:2]
	for branch in branches[1]
		if branch > size(branches[1], 1)
			swaprows!(A, branch, branches[2][swaps])
			append!(branch_mapping[1], branch)
			append!(branch_mapping[2], branches[2][swaps])
			swaps += 1
		end
	end 
	return A, bus_mapping, branch_mapping, branches
end

"""Return branches in islands."""
function  get_islanded_branches(A::Array{Int64, 2},
								islands::Array{Array{Int64, 1}, 1})::Array{Array{Int64, 1}, 1}
	# Figure out which branches belong in the islands	
	branches = [Array{Int64, 1}(undef, 0) for a in 1:2]
	i = 1
	while i <= size(A, 1 )
		j = 1
		while j <= size(A, 2)
			if A[i,j] != 0
				if j <= size(islands[1], 1) # if j is larger than size of island 1, it belongs to island 2  
					append!(branches[1], i)
	            else
					append!(branches[2], i)
				end
			# If the entry was not 0 we have checked the branch
			# We only need to check one entry on each row. The
			# reason for this is that there are no connection
			# between islands
	        break 
			end   
			j += 1
		end
		i += 1
	end
	return branches
end

function  get_islanded_branches(network::PowerGraphBase)::Array{Array{Int64, 1}, 1}
	get_islanded_branches(get_incidence_matrix(network, true),
						  get_islanded_buses(network))
end

