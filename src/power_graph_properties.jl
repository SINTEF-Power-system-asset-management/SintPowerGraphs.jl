using LightGraphs.LinAlg
using LinearAlgebra
using SparseArrays
""" 
    get_bus_data(network::PowerGraphBase, bus_id::Int)

    Return a dictionary containing the dictionary with the buse data.
"""
function get_bus_data(network::PowerGraphBase, bus_id::Int)::Dict
    return get_prop(network.G, bus_id, :data)
end

""" 
set_bus_data!(network::PowerGraphBase, bus_id::Int, data::Dict{String, Any})

    Set the data to be stored on the bus
"""
function set_bus_data!(network::PowerGraphBase, bus_id::Int, data::Dict{String, Any})
    set_prop!(network.G, bus_id, :data, data)
end

""" 
set_branch_data!(network::PowerGraphBase, bus_id::Int, data::Dict{String, Any})

    Sets the data to be stored on the branch
"""
function set_branch_data!(network::PowerGraphBase, f_bus::Int, t_bus::Int, data::Dict{String, Any})
    return set_prop!(network.G, f_bus, t_bus, :data, data)
end

""" 
    get_branch_data(network::PowerGraphBase, f_bus_id::Int, t_bus::Int)

    Return a dictionary containing the dictionary with the buse data.
"""
function get_branch_data(network::PowerGraphBase, f_bus::Int, t_bus::Int)::Dict
    if has_edge(network.G, f_bus, t_bus)
        return get_prop(network.G, f_bus, t_bus, :data)
    else
        return get_prop(network.G, t_bus, f_bus, :data)
    end
end

function get_branch_data(network::PowerGraphBase,
                         edge::LightGraphs.SimpleGraphs.SimpleEdge{Int64})::Dict
    return get_prop(network.G, edge, :data)
end

"""
    is_load_bus(network::PowerGraphBase, bus_id::Int)

    Returns true if the bus bus_id is a load.
"""
function is_load_bus(network::PowerGraphBase, bus_id::Int)
    return haskey(props(network.G, bus_id), :load_i)
end

"""
    is_gen_bus(network::PowerGraphBase, bus_id::Int)

    Returns true if the bus bus_id is a load.
"""
function is_gen_bus(network::PowerGraphBase, bus_id::Int)
    return haskey(props(network.G, bus_id), :gen_i)
end

"""
    get_π_equivalent(network::PowerGraphBase, from_bus::Int, to_bus::Int)
    
    Returns the π-equivalent of a line segment.
"""
function get_π_equivalent(network::PowerGraphBase, from_bus::Int, to_bus::Int)::π_segment
    branch = get_branch_data(network, from_bus, to_bus)
    
    return π_segment(branch["br_r"]+branch["br_x"]im,
                     branch["g_fr"]+branch["b_fr"]im,
                     branch["g_to"]+branch["b_to"]im,)
end

"""
    get_dc_admittance_matrix(network::PowerGraphBase)::Array{Float64}
    Returns the admittance matrix for performing a dc power flow.
"""
function get_dc_admittance_matrix(network::PowerGraphBase)::SparseMatrixCSC{Float64, Int64}
    A = incidence_matrix(network.G)
    return A*spdiagm(0 => get_susceptance_vector(network))*A'
end

"""
    get_susceptance_vector(network::PowerGraphBase)::Array{Float64}
    Returns the susceptance vector for performing a dc power flow.
"""
function get_susceptance_vector(network::PowerGraphBase)::Array{Float64,1}
    B = Vector{Float64}(undef, ne(network.G))
    for (index, edge) in enumerate(edges(network.G))
        branch = get_branch_data(network, edge)
        B[index] = 1/branch["br_x"]
    end
    return B
end

