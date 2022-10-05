using PowerGraphs
using Graphs
using MetaGraphs
using Test

# Set up the simple test system used in the following tests
include("set_up_test_systems.jl")

include("test_radial_power_graph.jl")
include("test_power_graph_properties.jl")

include("test_circuit_operations.jl")
@testset "Test the case format" begin
   include("test_case_format.jl")
end

import Aqua
Aqua.test_all(PowerGraphs; ambiguities = (recursive=false),
             project_extras=false, deps_compat=false)
