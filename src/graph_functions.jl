
"""
    Implements dfs_iter from the Python algorithms book.
"""
function dfs_iter(G::SimpleDiGraph, s::Int)::Array{Int, 1}
    S = Array{Int, 1}() # Visited vertices
    Q = Array{Int, 1}() # Queue of vertices to visit

    append!(Q, s)

    while size(Q, 1) > 0
        u = pop!(Q)
        if u in S # If we have already visted a vertice continue.
            continue
        end
        append!(S, u)
        append!(Q, neighbors(G, u))
    end
    return S
end

