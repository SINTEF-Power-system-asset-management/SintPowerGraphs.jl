function graphMap(mpc, G, ref_bus) #network::RadialPowerGraph)
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
    @assert start in vertices(g_copy) "can't access $start in $(props(g, 1))"
    while !isempty(visit)
        next = pop!(visit)
        if !(next in seen)
            for n in neighbors(g_copy, next)
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
    open_switches_iter = filter_edges(network.meta, (g,x)->(get_prop(g, x, :switch) == 0))
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
        src, tar = sort([get(reindex, e.src, nothing), get(reindex, e.dst, nothing)])
        if !(nothing in [src, tar])
            #if get_prop(g, e, :switch) != 0 
            add_edge!(newgraph, src, tar)
            set_prop!(newgraph, src, tar, :switch, get_prop(g_copy, e.src, e.dst, :switch))
           # end
        end
    end
    return newgraph
end