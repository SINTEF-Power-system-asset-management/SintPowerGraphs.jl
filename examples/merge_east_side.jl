### A Pluto.jl notebook ###
# v0.12.4

using Markdown
using InteractiveUtils

# ╔═╡ c209f8b2-6a0b-11eb-1fa1-e92435e9f9e4
using Markdown

# ╔═╡ d14e8d32-6a0c-11eb-3893-a737e6e8c37e
begin
	using PowerGraphs
	using GraphPlot # For plotting
	using Gadfly # For changing plot size
	using Plots, GraphRecipes # For nicer plotting
	using MetaGraphs
	using LightGraphs
end

# ╔═╡ 96711fc0-6a0c-11eb-2d54-8b7a82bbe8d4
md"
# Notebook for reading in network and aggregating the data
First we start by importing the relevant packages.
"


# ╔═╡ 55e50190-6a0e-11eb-21cd-7f1287a4188e
md"
## Load the network"

# ╔═╡ b5d5c9c0-6a10-11eb-28fa-2747e5ca8119
begin
	fname = "lionshield.toml"
	filepath = joinpath(@__DIR__, joinpath("cases", fname))
	example = RadialPowerGraph(filepath)
end

# ╔═╡ cf309260-6a10-11eb-12ae-61bbfb78b061
md"
## Number of short lines
We now have a very large network. However, many of the lines are very short and several don't have any impedance. In the next code cell one can see how many lines are shorter than 2 centimetres."

# ╔═╡ f3d389fe-6a10-11eb-05ad-2fbf6db78c4b
begin
	df = example.mpc.reldata
	# Divide by 1000 to go from km to m
	df.length/1000
	df[df.length.<2/100,:][:,[:f_bus, :t_bus, :length]]
end

# ╔═╡ 0a9ad680-6a11-11eb-2a5b-710a1f821f00
md"
## Merge line segments
Sometimes one line is represented as several line segements. This is the case for this test network. One easy method for making the network smaller is therefore to merge the segements. Before merging the lines we specify, which of the features of the lines should be aggregated. In the code below we specify that we want failure frequencies and line lengths to be aggregated, before we merge the line segments."

# ╔═╡ 18c0d110-6a11-11eb-1e96-e34c52473e47
begin
	aggregators = Dict(:reldata => Dict(:failure_frequency_permanent => 0.0,
										:failure_frequency_temporary => 0.0,
										:length => 0.0))
	red_example = merge_line_segments(example, aggregators=aggregators)

	red_example.ref_bus
end

# ╔═╡ Cell order:
# ╠═c209f8b2-6a0b-11eb-1fa1-e92435e9f9e4
# ╟─96711fc0-6a0c-11eb-2d54-8b7a82bbe8d4
# ╠═d14e8d32-6a0c-11eb-3893-a737e6e8c37e
# ╟─55e50190-6a0e-11eb-21cd-7f1287a4188e
# ╠═b5d5c9c0-6a10-11eb-28fa-2747e5ca8119
# ╟─cf309260-6a10-11eb-12ae-61bbfb78b061
# ╠═f3d389fe-6a10-11eb-05ad-2fbf6db78c4b
# ╟─0a9ad680-6a11-11eb-2a5b-710a1f821f00
# ╠═18c0d110-6a11-11eb-1e96-e34c52473e47
