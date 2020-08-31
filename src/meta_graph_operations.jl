function graphMap(mpc, G) #network::RadialPowerGraph)
    mg = MetaGraph(G)
    for bus in eachrow(mpc.bus)
        set_prop!(mg, DataFrames.row(bus), :name, string(bus.ID))
    end
    set_indexing_prop!(mg, :name)
    for branch in eachrow(mpc.branch)
        # I set the following rule for the property stored on each edge:
        # :switch = [-1 => no switch;
        #            0  => open; # information stored on column switch.closed[1]
        #            1  => closed; # information stored on column switch.closed[1]
        #            2  => breaker; # information stored on column switch.breaker[1]
        #            ]
        if is_switch(mpc, branch.f_bus, branch.t_bus)
            switch = get_switch(mpc, branch.f_bus, branch.t_bus)
            if switch.breaker[1] == 1
                # it is a breaker
                set_prop!(mg, mg[string(branch.f_bus),:name], mg[string(branch.t_bus),:name], :switch, 2)
            else
                # it is a switch (it can be open or closed)
                set_prop!(mg, mg[string(branch.f_bus),:name], mg[string(branch.t_bus),:name], :switch, switch.closed[1])
            end
        else
            # it is a normal branch
            set_prop!(mg, mg[string(branch.f_bus),:name], mg[string(branch.t_bus),:name], :switch, -1)
        end
    end
    return mg
end