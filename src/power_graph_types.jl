using LightGraphs
using MetaGraphs

abstract type PowerGraph end

mutable struct RadialPowerGraph <: PowerGraph
    G::MetaDiGraph # graph containing the power network 
    mpc::Dict{String, Any}
    ref_bus::Int # The id of the reference bus
    radial::DiGraph # The graph directed from the transmission node
end

function RadialPowerGraph()
    G = MetaDiGraph()
    mpc = Dict{String, Any}()
    ref_bus = 0
    radial = DiGraph()
    RadialPowerGraph(G, mpc, ref_bus, radial)
end
