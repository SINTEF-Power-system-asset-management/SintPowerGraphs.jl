function convert_case(mpc::Dict)
    G = MetaDiGraph(mpc["bus"].count)

    for branch in values(mpc["branch"])
        edge = Edge(branch["f_bus"], branch["t_bus"])
        add_edge!(G, edge)
        set_prop!(G, edge, :data, branch)
    end
    ref_bus = NaN
    for bus in values(mpc["bus"])
        set_prop!(G, bus["bus_i"], :data, bus)
        if bus["bus_type"] == 3
            ref_bus = bus["bus_i"]
        end
    end
    # If there is a load on the bus, save the location of the load in the load vector
    for (index, load) in mpc["load"]
        set_prop!(G, load["load_bus"], :load_i, index)
        set_prop!(G, load["load_bus"], :load, load)
    end
    # If there is a generator on the bus, save the location of the generator 
    # in the generator vector
    for (index, gen) in mpc["gen"]
        set_prop!(G, gen["gen_bus"], :gen_i, index)
        set_prop!(G, gen["gen_bus"], :gen, gen)
    end
    return G, ref_bus
end
