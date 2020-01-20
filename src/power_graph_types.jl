using LightGraphs
using MetaGraphs

abstract type PowerGraphBase end

mutable struct RadialPowerGraph <: PowerGraphBase
    G::MetaDiGraph # graph containing the power network 
    mpc::Dict{String, Any}
    ref_bus::Int # The id of the reference bus
    radial::DiGraph # The graph directed from the transmission node
end

mutable struct PowerGraph <: PowerGraphBase
    G::MetaDiGraph
    mpc::Dict{String, Any}
    ref_bus::Int
end

function RadialPowerGraph()
    G = MetaDiGraph()
    mpc = Dict{String, Any}()
    ref_bus = 0
    radial = DiGraph()
    RadialPowerGraph(G, mpc, ref_bus, radial)
end


