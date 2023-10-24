using SintPowerCase
using Graphs
using MetaGraphs
using GraphDataFrameBridge
using TOML

abstract type PowerGraphBase end

mutable struct RadialPowerGraph <: PowerGraphBase
    G::MetaDiGraph # graph containing the power network
    mpc::Case
    ref_bus::String # The id of the reference bus
    reserves::Vector{String} # List of ids for reserve connections
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
    reserves = []
    radial = MetaDiGraph()
    RadialPowerGraph(G, mpc, ref_bus, reserves, radial)
end

function RadialPowerGraph(mpc::Case)
    G, ref_bus = read_case!(mpc)
	radial = subgraph(G, G[ref_bus, :name])
    RadialPowerGraph(G, mpc, ref_bus, [], radial)
end

function RadialPowerGraph(case_file::String)
	RadialPowerGraph(Case(case_file::String))
end

function PowerGraph(mpc::Case)
    G, ref_bus = read_case!(mpc)
    PowerGraph(G, mpc, ref_bus)
end

function PowerGraph(case_file::String)
    PowerGraph(Case(case_file::String))
end

function read_case!(mpc::Case)
	G = MetaDiGraph(mpc.branch, :f_bus, :t_bus,
                   edge_attributes=:rateA)

    ref_bus = ""
	for bus in eachrow(mpc.bus)
        if bus[:type] == 3
			ref_bus = bus.ID
        end
    end
    
    set_indexing_prop!(G, :name)
	
	if size(mpc.switch, 1) >= 1 
		# Check if switches have propert closed.
		if :closed ∉ propertynames(mpc.switch)
			println("I don't know switch status.")
			println("All switches will be assumed closed.")
			mpc.switch[!, :closed] .= true
		end
		# Check if switches have column breaker
		if :breaker ∉ propertynames(mpc.switch)
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
            switches = get_switch(mpc, branch.f_bus, branch.t_bus)
            set_prop!(G,
                      G[string(branch.f_bus), :name], G[string(branch.t_bus), :name],
                      :switch_buses, switches.f_bus)
            if any(switches.breaker)
                # If there is a breaker on the branch we will treat it as a breaker
                set_prop!(G, G[string(branch.f_bus), :name], G[string(branch.t_bus), :name], :switch, 2)
            else
                # it is a switch (it can be open or closed)
                # If one switch is open the branch is considered and open switch
                set_prop!(G, G[string(branch.f_bus), :name], G[string(branch.t_bus), :name], :switch,
                          all(switches.closed) ? 1 : 0)
            end
        else
            # it is a normal branch
            set_prop!(G, G[string(branch.f_bus), :name], G[string(branch.t_bus), :name], :switch, -1)
            set_prop!(G,
                      G[string(branch.f_bus), :name], G[string(branch.t_bus), :name],
                      :switch_buses, [])
        end
    end
    # Add loads to edges
    for v in vertices(G)
        set_prop!(G, v, :load,
                  sum(
                      mpc.loaddata[mpc.loaddata.bus.==get_prop(G, v, :name), :P]))
    end
        
    return G, ref_bus
end
