using LightGraphs.LinAlg
using LinearAlgebra
using SparseArrays
""" 
    get_bus_data!(network::PowerGraphBase, bus_id::Int)

    Return a DataFrameRow with the bus data.
"""
function get_bus_data!(network::PowerGraphBase, bus_id::Int)::DataFrameRow
    return get_bus!(network.mpc, bus_id)
end

""" 
    get_bus_data(network::PowerGraphBase, bus_id::Int)

    Return a copy of the DataFrameRow with the bus data.
"""
function get_bus_data(network::PowerGraphBase, bus_id::Int)::DataFrameRow
    return get_bus(network.mpc, bus_id)
end

function get_gen_data!(network::PowerGraphBase, bus_id::Int)::DataFrame
    return get_gen!(network.mpc, bus_id)
end

function get_gen_data(network::PowerGraphBase, bus_id::Int)::DataFrame
    return get_gen(network.mpc, bus_id)
end

function push_bus!(network::PowerGraphBase, data::DataFrameRow)
    add_vertex!(network.G)
    push_bus!(network.mpc, data)
end

function push_gen!(network::PowerGraphBase, data::DataFrame)
    for gen in eachrow(data)
        push_gen!(network, gen)
    end
end

function push_gen!(network::PowerGraphBase, data::DataFrame, bus::Int)
    for gen in eachrow(data)
        push_gen!(network, gen, bus)
    end
end

function push_gen!(network::PowerGraphBase, data::DataFrameRow)
    push_gen!(network.mpc, data)
end

function push_gen!(network::PowerGraphBase, data::DataFrameRow, bus::Int)
    data[:bus] = bus
    push_gen!(network, data)
end

function push_branch!(network::PowerGraphBase, f_bus::Int, t_bus::Int, data::DataFrameRow)
    data[:f_bus] = f_bus
    data[:t_bus] = t_bus
    add_edge!(network.G, f_bus, t_bus)
    push_branch!(network.mpc, data) 
end

function push_branch!(network::PowerGraphBase, f_bus::Int, t_bus::Int, data::DataFrame)
    for branch in eachrow(data)
        push_branch!(network, f_bus, t_bus, branch)
    end
end

""" 
    get_branch_data(network::PowerGraphBase, f_bus_id::Int, t_bus::Int)

    Return a dictionary containing the dictionary with the buse data.
"""
function get_branch_data(network::PowerGraphBase, f_bus::Int, t_bus::Int)::DataFrame
    if has_edge(network.G, f_bus, t_bus)
        return get_branch(network.mpc, f_bus, t_bus)
    else
        return get_branch(network.mpc, t_bus, f_bus)
    end
end

function set_branch_data!(network::PowerGraphBase, f_bus::Int, t_bus::Int, data::DataFrame)
    set_branch!(network.mpc, f_bus, t_bus, data)
end

"""
    is_load_bus(network::PowerGraphBase, bus_id::Int)

    Returns true if the bus bus_id is a load.
"""
function is_load_bus(network::PowerGraphBase, bus_id::Int)
    return network.mpc.bus[bus_id,:Pd]>0
end

"""
    is_gen_bus(network::PowerGraphBase, bus_id::Int)

    Returns true if the bus bus_id is a load.
"""
function is_gen_bus(network::PowerGraphBase, bus_id::Int)
    return is_gen_bus(network.mpc, bus_id)
end

"""
    get_π_equivalent(network::PowerGraphBase, from_bus::Int, to_bus::Int)
    
    Returns the π-equivalent of a line segment.
"""
function get_π_equivalent(network::PowerGraphBase, from_bus::Int, to_bus::Int)::π_segment
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
function get_dc_admittance_matrix(network::PowerGraphBase)::SparseMatrixCSC{Float64, Int64}
    A = incidence_matrix(network.G)
    return A*spdiagm(0 => get_susceptance_vector(network))*A'
end

"""
    get_susceptance_vector(network::PowerGraphBase)::Array{Float64}
    Returns the susceptance vector for performing a dc power flow.
"""
function get_susceptance_vector(network::PowerGraphBase)::Array{Float64,1}
    return map(x-> 1/x, network.mpc.branch[:,:x])
end

