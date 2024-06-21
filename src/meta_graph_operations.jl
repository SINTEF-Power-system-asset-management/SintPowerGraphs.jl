
""" 
    When making an undirected graph from a directed one using the MetaGraph
    function. Edges that are going from a vertex with a high index to a low
    index loses their properties. This function readds them.
"""
function undirected_copy(g::MetaDiGraph)
    g_c = MetaGraph(g)
    for e in edges(g_c)
        if e ∉ edges(g)
            for prop in props(g, e.dst, e.src)
                set_prop!(g_c, e, prop[1], prop[2])
            end
        end
    end
    return g_c
end
