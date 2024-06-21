using SintPowerGraphs

Z₀ = π_segment(0, 0, 0)
Z₁ = π_segment(1, 1, 1)
@testset "Test circuit operations" begin
    Z = Z₀ + Z₀
    @test Z.Z == 0
    @test Z.Y₁ == 0
    @test Z.Y₂ == 0

    @test is_zero_impedance_line(Z)

    Z = Z₀ + Z₁
    @test Z.Z == 1
    @test Z.Y₁ == 1
    @test Z.Y₂ == 1
end
