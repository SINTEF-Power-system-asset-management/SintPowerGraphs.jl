# # Aggregate radial network and prepare for MATPOWER
# In this notebook code for aggregating a radial network and preparing it for power flows is presented.
#
# ## Dependencies
# This example has several dependencies not included in PowerGraphs. To run this example the dependencies should be installed separately. 
#
# To be able to run power flows pypsa or pandapower should be installed. They have to be installed on the same Python version as the one used by PyCall. To change the python version used by PyCall, please refer to the PyCall documentation
#
# ## Load packages
# First we need to load the package PowerGraphs for aggregating and saving the grid.

using PowerGraphs
using PyCall
using GraphPlot # For plotting
using Gadfly # For changing plot size
using Plots, GraphRecipes # For nicer plotting

# ## Load the network
# When we have loaded the PowerGraphs package we can read in the network.

fname = "east_side.toml"
filepath = joinpath(@__DIR__, joinpath("cases", fname))
example = RadialPowerGraph(filepath)

# ## Number of short lines
# We now have a very large network. However, many of the lines are very short and several don't have any impedance. In the next code cell one can see how many lines are shorter than 2 centimetres. 

df = example.mpc.reldata
# Divide by 1000 to go from km to m
df.length / 1000
df[df.length.<2/100, :][:, [:f_bus, :t_bus, :length]]

# ## Merge line segments
# Sometimes one line is represented as several line segements. This is the case for this test network. One easy method for making the network smaller is therefore to merge the segements. Before merging the lines we specify, which of the features of the lines should be aggregated. In the code below we specify that we want failure frequencies and line lengths to be aggregated, before we merge the line segments.

aggregators = Dict(
    :reldata => Dict(
        :failure_frequency_permanent => 0.0,
        :failure_frequency_temporary => 0.0,
        :length => 0.0,
    ),
)
red_example = merge_line_segments(example, aggregators = aggregators)

# Before merging we had 1133 buses in the case, now we have only 440 buses. We can also check how many lines shorter than 2cm we hace now:

df = red_example.mpc.reldata
# Divide by 1000 to go from km to m
df.length / 1000
df[df.length.<2/100, :][:, [:f_bus, :t_bus, :length]]

# There is now 202 lines shorter than 2cm. This is a big change compare to before when the number was 940. To be able to run power flows we will also remove lines with a low impedance. 
#
# ## Removing low impedance lines
# We wil now remove low impedance lines. At the moment this functionality does not keep information about switches, fault indicators or failure rates. It merely takes the everyting connected to one end of the low impedance line and connects it to the other end. Afterwards the line and the empty end are deleted.

small = remove_low_impedance_lines(red_example, 1e-5)

# ## Plot the network
# We will now plot the network, to check that it looks reasonable.
#
# There are two nice options for plotting. We can use GraphPlots as demonstrated below.

set_default_plot_size(25cm, 25cm)
gplot(small.G, nodelabel = 1:n_vertices(small), arrowlengthfrac = 0)

# Another nice option for plotting is to use Plots and GraphRecipes.

gr(alpha = 1, size = (700, 800), dpi = 150)
# Plotly is a nice backend that allows for interacting with the plot (zoomin, paning, ...). However, it is no
# supported by GitHub
# plotly(alpha=1, size=(700,800), dpi=150)
graphplot(
    small.G,
    method = :tree,
    nodeshape = :circle,
    names = 1:n_vertices(small),
    curves = false,
    fontsize = 5,
    self_edge_size = 0.5,
)

# ## Running power flow
# First we have to name the buses correctly

mpc = deepcopy(small.mpc)
mpc.bus.ID = 1:n_vertices(small)

# We can now run the power flow using pypsa

pypsa = pyimport("pypsa")
network = pypsa.Network()
ppc = to_ppc(mpc)
network.import_from_pypower_ppc(ppc)
network.pf()
print(network.lines_t["p0"])

# It should also be possible to run the power flow using pandapower, but we didn't manage to make it work using PyCall. To use pandapower the easiest is to pickle the variabl `ppc` and load it in Python.

# ## Write network to matpower
# We can now write the network to csv files for later processing in MATLAB

to_csv(mpc, joinpath(@__DIR__, "reduced_matpower"))
