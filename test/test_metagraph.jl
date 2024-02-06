G = undirected_copy(test.G)

@test props(G, 2, 3) == props(test.G, 3, 2) 
