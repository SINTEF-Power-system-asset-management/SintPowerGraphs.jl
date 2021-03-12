using CSV

function graphMap(mpc, G, ref_bus, filtered_branches=DataFrame(element=[], f_bus=[], t_bus=[], tag=[])) #network::RadialPowerGraph)
    mg = MetaGraph(G)
    islanded_nodes = apply_assumptions_to_make_network_converge(G)
    islanded_nodes_names = mpc.bus[islanded_nodes,:ID]
    for bus in eachrow(mpc.bus)
        name = string(bus.ID)
        set_prop!(mg, DataFrames.row(bus), :name, name)
    end
    set_indexing_prop!(mg, :name)
    for node in islanded_nodes
        bus = mpc.bus[node,:ID]
        node_number = mg[string(bus), :name]
        rem_vertex!(mg,node_number)
    end
    
    for branch in eachrow(mpc.branch)
        # I set the following rule for the property stored on each edge:
        # :switch = [-1 => no switch;
        #            0  => open; # information stored on column switch.closed[1]
        #            1  => closed; # information stored on column switch.closed[1]
        #            2  => breaker; # information stored on column switch.breaker[1]
        #            ]
        if (branch.f_bus in islanded_nodes_names) || (branch.t_bus in islanded_nodes_names)
            # branches should be automatically deleted when the two terminals belonging to the island are eliminated
            continue
        elseif !isempty(filtered_branches[.&(filtered_branches[!,:f_bus].==branch.f_bus,filtered_branches[!,:t_bus].==branch.t_bus),:])
            # Lines on filter are removed, switches are opened
            tag = filtered_branches[.&(filtered_branches[!,:f_bus].==branch.f_bus,filtered_branches[!,:t_bus].==branch.t_bus),:].tag[1]
            if tag == "L"
                rem_edge!(mg,mg[string(branch.f_bus), :name],mg[string(branch.t_bus), :name])
            elseif tag == "S"
                switch = get_switch(mpc, branch.f_bus, branch.t_bus)
                set_prop!(mg, mg[string(branch.f_bus),:name], mg[string(branch.t_bus),:name], :switch, 0)
            end
        else
            if is_switch(mpc, branch.f_bus, branch.t_bus)
                switch = get_switch(mpc, branch.f_bus, branch.t_bus)
                if (switch.breaker[1] == "True" || switch.breaker[1] == 1)
                    # it is a breaker
                    set_prop!(mg, mg[string(branch.f_bus),:name], mg[string(branch.t_bus),:name], :switch, 2)
                else
                    # it is a switch (it can be open or closed)
                    set_prop!(mg, mg[string(branch.f_bus),:name], mg[string(branch.t_bus),:name], :switch, if (switch.closed[1]=="True" || switch.closed[1]==1) 1 else 0 end)
                end
            else
                # it is a normal branch
                set_prop!(mg, mg[string(branch.f_bus),:name], mg[string(branch.t_bus),:name], :switch, -1)
            end
        end
    end
    meta_radial = subgraph(mg, ref_bus)
    # for f in eachrow(mpc.transformer)
    #     push!(meta_radial, string(f.t_bus) => subgraph(mg, mg[string(f.t_bus), :name]))
    # end
    return mg, meta_radial
end


# These two functions below are taken from a github repo

"""Start at a node and traverse DFS/BFS, recording order nodes were seen
Node that the order branches are traversed is not determined (the natural
ordering from :args in the edges is not used...yet)
"""
function traverse(g::MetaGraph, start::Int = 0, dfs::Bool = true)::Vector{Int}
    # start = start == 0 ? root(g) : start
    
    seen = Vector{Int}()
    visit = Vector{Int}([start])
    @assert start in vertices(g) "can't access $start in $(props(g, 1))"
    while !isempty(visit)
        next = pop!(visit)
        if !(next in seen)
            for n in neighbors(g, next)
                if !(n in seen)
                    if dfs append!(visit, n) else insert!(visit, 1, n) end
                end
            end
            push!(seen, next)
        end
    end
    return seen
end

"""Make a subgraph out of all descendents with a given node as root"""
function subgraph(g::MetaGraph, start::Int = 0)::MetaDiGraph
    # start = start == 0 ? root(g) : start

    # removing open switch edges before traversing with BFS
    g_copy = copy(g)
    open_switches_iter = filter_edges(g, (g,x)->(get_prop(g, x, :switch) == 0))
    for e in open_switches_iter
        rem_edge!(g_copy, e)
    end

    inds = traverse(g_copy, start, false)
    newgraph = MetaDiGraph()
    set_indexing_prop!(newgraph, :name)
    set_prop!(newgraph, :root, 1)
    reindex = Dict{Int,Int}()

    for (newi, i) in enumerate(inds)  # in BFS order
        add_vertex!(newgraph)
        set_prop!(newgraph, newi, :name, get_prop(g_copy, i, :name))
        reindex[i] = newi
    end

    for e in edges(g_copy)
        # I sort src and tar for keeping the order of discovery in BFS
        # -1 is used as result for bus not found
        src, tar = sort([get(reindex, e.src, -1), get(reindex, e.dst, -1)])
        if !(-1 in [src, tar])
            #if get_prop(g, e, :switch) != 0 
            add_edge!(newgraph, src, tar)
            set_prop!(newgraph, src, tar, :switch, get_prop(g_copy, e.src, e.dst, :switch))
           # end
        end
    end
    return newgraph
end

function apply_assumptions_to_make_network_converge(G)
    islands = Dict()
    for island in connected_components(G)
        push!(islands, length(island)=> island)
    end
    keymax = maximum(keys(islands))
    islanded_nodes = []
    for (key, nodes) in islands
        if key != keymax
            append!(islanded_nodes, nodes)
        end
    end
    return islanded_nodes
end