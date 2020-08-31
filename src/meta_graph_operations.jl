function graphMap(mpc, G) #network::RadialPowerGraph)
    mg = MetaGraph(G)
    for bus in eachrow(mpc.bus)
        set_prop!(mg, DataFrames.row(bus), :name, string(bus.ID))
    end
    set_indexing_prop!(mg, :name)
    for branch in eachrow(mpc.branch)
        if is_switch(mpc, branch.f_bus, branch.t_bus)
            switch = get_switch(mpc, branch.f_bus, branch.t_bus)
            set_prop!(mg, mg[string(branch.f_bus),:name], mg[string(branch.t_bus),:name], :c_switch, switch.closed[1])
        end
    end
    return mg
end