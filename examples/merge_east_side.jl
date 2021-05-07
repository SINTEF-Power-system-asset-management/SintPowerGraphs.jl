### A Pluto.jl notebook ###
# v0.12.20

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
	fname = "east_side.toml"
	filepath = joinpath(@__DIR__, joinpath("cases", fname))
	example = RadialPowerGraph(filepath)
	example.mpc
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
	red_example.mpc
end

# ╔═╡ c1a5ed9e-6a35-11eb-2455-03bc10cca19e
md"
Before merging we had 1133 buses in the case, now we have only 440 buses. We can also check how many lines shorter than 2cm we have now:"

# ╔═╡ daac54b0-6a35-11eb-34ec-7116d9268a29
begin
	df_short = red_example.mpc.reldata
	# Divide by 1000 to go from km to m
	df_short.length/1000
	df_short[df_short.length.<2/100,:][:,[:f_bus, :t_bus, :length]]
end

# ╔═╡ f1dc2700-6a35-11eb-0ae2-1dad05882229
md"
There is now 202 lines shorter than 2cm. This is a big change compare to before when the number was 940. To be able to run power flows we will also remove lines with a low impedance. "

# ╔═╡ 02d9ab90-6a36-11eb-154a-0d3a1e15d9bd
md"
## Removing low impedance lines
We wil now remove low impedance lines. At the moment this functionality does not keep information about switches, fault indicators or failure rates. It merely takes the everyting connected to one end of the low impedance line and connects it to the other end. Afterwards the line and the empty end are deleted."

# ╔═╡ 1ed1b450-6a36-11eb-1853-73ed3ad9c1b9
small = remove_low_impedance_lines(red_example, 1e-5)

# ╔═╡ 22c5d1e0-6a36-11eb-011c-038bd7c4fd5f
md"
## Plot the network
We will now plot the network, to check that it looks reasonable. There are two nice options for plotting. We can use GraphPlots as demonstrated below."

# ╔═╡ 5cced850-6a36-11eb-18ac-fbb43a74f1a3
begin
	set_default_plot_size(25cm, 25cm)
	gplot(small.G, nodelabel=1:n_vertices(small), arrowlengthfrac=0)
end

# ╔═╡ 68e70180-6a36-11eb-27d6-6bbbbd43d1af
md"
Another nice option for plotting is to use Plots and GraphRecipes."

# ╔═╡ 6efcc690-6a36-11eb-0ba8-e5b38f41b6ba
begin
	plotly(alpha=1, size=(700,800), dpi=150)
	graphplot(small.G, method=:tree, nodeshape=:circle, names=1:n_vertices(small), curves=false, fontsize=5, self_edge_size=0.5)
end

# ╔═╡ f665bbe0-6a37-11eb-2308-a3737ac2784b
md"
## Write to matpower
We can now write the network to csv files for later processing in MATLAB"

# ╔═╡ 66802f20-6a40-11eb-374f-53db9f556ab1
to_csv(small.mpc, joinpath(@__DIR__, "reduced_matpower"))

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
# ╟─c1a5ed9e-6a35-11eb-2455-03bc10cca19e
# ╠═daac54b0-6a35-11eb-34ec-7116d9268a29
# ╟─f1dc2700-6a35-11eb-0ae2-1dad05882229
# ╟─02d9ab90-6a36-11eb-154a-0d3a1e15d9bd
# ╠═1ed1b450-6a36-11eb-1853-73ed3ad9c1b9
# ╟─22c5d1e0-6a36-11eb-011c-038bd7c4fd5f
# ╠═5cced850-6a36-11eb-18ac-fbb43a74f1a3
# ╟─68e70180-6a36-11eb-27d6-6bbbbd43d1af
# ╠═6efcc690-6a36-11eb-0ba8-e5b38f41b6ba
# ╟─f665bbe0-6a37-11eb-2308-a3737ac2784b
# ╠═66802f20-6a40-11eb-374f-53db9f556ab1
