using LightGraphs
using GraphDataFrameBridge
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

function RadialPowerGraph()
    G = MetaDiGraph()
    mpc = Case()
    ref_bus = ""
    radial = MetaDiGraph()
    RadialPowerGraph(G, mpc, ref_bus, radial)
end

function RadialPowerGraph(case_file::String)
	RadialPowerGraph(Case(case_file::String))
end

function RadialPowerGraph(mpc::Case)
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
	G = MetaDiGraph(mpc.branch, :f_bus, :t_bus)

    ref_bus = NaN
	for bus in eachrow(mpc.bus)
        if bus[:type] == 3
			ref_bus = string(bus.ID)
        end
    end
    
    set_indexing_prop!(G, :name)
	
	if size(mpc.switch, 1) >= 1 
		# Check if switches have propert closed.
		if "closed" ∉ names(mpc.switch)
			println("I don't know switch status.")
			println("All switches will be assumed closed.")
			mpc.switch[!, :closed] .= true
		end
		# Check if switches have column breaker
		if "breaker" ∉ names(mpc.switch)
			println("I don't know if switch or circuit breaker.")
			println("All switchgear will be assumed to be switches.")
			mpc.switch[!, :breaker] .= false
		end
	end
    
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
