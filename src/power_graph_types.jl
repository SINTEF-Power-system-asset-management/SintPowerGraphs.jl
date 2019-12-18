using LightGraphs
using MetaGraphs

abstract type PowerGraph end

mutable struct RadialPowerGraph <: PowerGraph
    G::MetaDiGraph # graph containing the power network 
    mpc::Dict
    ref_bus::Int # The id of the reference bus
    radial # The graph directed from the transmission node
end


