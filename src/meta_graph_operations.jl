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
function subgraph(g::MetaDiGraph, start::Int = 0)::MetaDiGraph
    # start = start == 0 ? root(g) : start

    # removing open switch edges before traversing with BFS
	g_copy = MetaGraph(g)
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
        src, tar = sort([get(reindex, e.src, nothing), get(reindex, e.dst, nothing)])
        if !(nothing in [src, tar])
            #if get_prop(g, e, :switch) != 0 
            add_edge!(newgraph, src, tar)
			# Sometimes the lines are in the opposite direction in the original graph
			if has_edge(g, e.src, e.dst)
				set_prop!(newgraph, src, tar, :switch, get_prop(g_copy, e.src, e.dst, :switch))
			else
				# When f_bus and t_bus have been inversed the property disappears from the 
				# graph when going from MetaDiGraph to MetaGraph
				set_prop!(newgraph, src, tar, :switch, get_prop(g, e.dst, e.src, :switch))
			end
           # end
        end
    end
    return newgraph
end
