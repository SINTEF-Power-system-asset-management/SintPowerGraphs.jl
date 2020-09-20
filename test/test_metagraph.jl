using PowerGraphs

fname = joinpath(@__DIR__, joinpath("fasad_tsh", "TSH-grid-no-indicators.toml"))

network = MetaPowerGraph(fname)

println("ciao")