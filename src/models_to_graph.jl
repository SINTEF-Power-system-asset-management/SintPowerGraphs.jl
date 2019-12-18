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
    return G, ref_bus
end
