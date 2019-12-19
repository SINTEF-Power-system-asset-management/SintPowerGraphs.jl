using PowerGraphs
using Test 

@testset "Check construction of radial graph" begin
    @test test_graph == test.radial
end
