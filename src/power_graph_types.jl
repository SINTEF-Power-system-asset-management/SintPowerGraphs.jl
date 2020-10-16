using LightGraphs
using MetaGraphs
using TOML

abstract type PowerGraphBase end

mutable struct RadialPowerGraph <: PowerGraphBase
    G::MetaDiGraph # graph containing the power network
    mpc::Case
    ref_bus::String # The id of the reference bus
    radial::MetaDiGraph # The graph directed from the transmission node
end

mutable struct PowerGraph <: PowerGraphBase
    G::MetaDiGraph
    mpc::Case
    ref_bus::String
end

function MetaPowerGraph(case_file::String)
    conf = TOML.parsefile(case_file)
    format = get(conf, "format", 0)
    if format == 0
        mpc = Case(case_file::String) # relrad format
    else
        mpc_temp = Fasad_Case(case_file::String) # fasad format
        mpc = process_Fasad_Case(mpc_temp, conf["transmission_grid"])
    end
    G, ref_bus = read_case!(mpc)
    meta, meta_radial = graphMap(mpc, G, ref_bus)
    MetaPowerGraph(G, mpc, ref_bus, meta, meta_radial)
end

function RadialPowerGraph()
    G = MetaDiGraph()
    mpc = Case()
    ref_bus = ""
    radial = MetaDiGraph()
    RadialPowerGraph(G, mpc, ref_bus, radial)
end

function RadialPowerGraph(case_file::String)
    mpc = Case(case_file::String)
    G, ref_bus = read_case!(mpc)
	radial = subgraph(G, G[ref_bus, :name])
    RadialPowerGraph(G, mpc, ref_bus, radial)
end

function PowerGraph(mpc::Case)
    G, ref_bus = read_case!(mpc)
    PowerGraph(G, mpc, ref_bus)
end

function PowerGraph(case_file::String)
    PowerGraph(Case(case_file::String))
end

function read_case!(mpc::Case)
    G = MetaDiGraph(nrow(mpc.bus))

    ref_bus = NaN
	for bus in eachrow(mpc.bus)
        if bus[:type] == 3
			ref_bus = string(DataFrames.row(bus))
        end
        set_prop!(G, DataFrames.row(bus), :name, bus.ID)
    end
    
    set_indexing_prop!(G, :name)
	
	if size(mpc.switch, 1) >= 1 
		# Check if switches have propert closed.
		if :closed ∉ names(mpc.switch)
			println("I don't know switch status.")
			println("All switches will be assumed closed.")
			mpc.switch[!, :closed] .= true
		end
		# Check if switches have column breaker
		if :breaker ∉ names(mpc.switch)
			println("I don't know if switch or circuit breaker.")
			println("All switchgear will be assumed to be switches.")
			mpc.switch[!, :breaker] .= false
		end
	end
    
	for branch in eachrow(mpc.branch)
		# First add the edge to the graph
		add_edge!(G, G[string(branch.f_bus), :name], G[string(branch.t_bus), :name])

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
                set_prop!(G, G[string(branch.f_bus), :name], G[string(branch.t_bus), :name], :switch, 2)
            else
                # it is a switch (it can be open or closed)
                set_prop!(G, G[string(branch.f_bus), :name], G[string(branch.t_bus), :name], :switch, switch.closed[1])
            end
        else
            # it is a normal branch
            set_prop!(G, G[string(branch.f_bus), :name], G[string(branch.t_bus), :name], :switch, -1)
        end
    end
    return G, ref_bus
end
