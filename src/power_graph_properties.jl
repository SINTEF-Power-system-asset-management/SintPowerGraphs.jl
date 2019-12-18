""" 
    get_bus_data(network::PowerGraph, bus_id::Int)

    Return a dictionary containing the dictionary with the buse data.
"""
function get_bus_data(network::PowerGraph, bus_id::Int)::Dict
    return get_prop(network.G, bus_id, :data)
end

""" 
    get_branch_data(network::PowerGraph, bus_id::Int)

    Return a dictionary containing the dictionary with the buse data.
"""
function get_branch_data(network::PowerGraph, f_bus::Int, t_bus::Int)::Dict
    return get_prop(network.G, f_bus, t_bus, :data)
end
