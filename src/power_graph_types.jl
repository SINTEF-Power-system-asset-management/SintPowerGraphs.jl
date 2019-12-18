using LightGraphs
using MetaGraphs

mutable struct RadialPowerGraph
    G::MetaDiGraph # graph containing the power network 
    mpc::Dict
    ref_bus::Int # The id of the reference bus
    radial # The graph directed from the transmission node
end


