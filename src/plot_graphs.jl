using Gadfly
using GraphPlot
function plot_to_web(network::PowerGraphBase)
    gplot(network.G, nodelabel=1:nv(network.G))
end

