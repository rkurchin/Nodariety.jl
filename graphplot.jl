using Compose, GraphPlot
using Cairo, Fontconfig
include("functions.jl")

g = build_graph()

# some initial playing around
clusters = sort(connected_components(g), by=length, rev=true)
sg = g[clusters[1]]
nl = [sg.vprops[i][:family_name] for i in 1:nv(sg)]
gplot(sg, nodelabel=nl, arrowlengthfrac=0.05)

colors = [colorant"black" for i in  1:nv(sg)]
draw(PNG("test1.png", 40cm, 40cm), gplot(sg, nodelabel=nl, arrowlengthfrac=0.02, edgestrokec=colorant"black"))

#=
function gplot{V, T<:Real}(
    G::AbstractGraph{V},
    locs_x::Vector{T}, locs_y::Vector{T};
    nodelabel::Union(Nothing, Vector) = nothing,
    nodelabelc::ComposeColor = colorant"black",
    nodelabelsize::Union(Real, Vector) = 4,
    nodelabeldist::Real = 0,
    nodelabelangleoffset::Real = π/4.0,
    edgelabel::Union(Nothing, Vector) = nothing,
    edgelabelc::ComposeColor = colorant"black",
    edgelabelsize::Union(Real, Vector) = 4,
    edgestrokec::ComposeColor = colorant"lightgray",
    edgelinewidth::Union(Real, Vector) = 1,
    edgelabeldistx::Real = 0,
    edgelabeldisty::Real = 0,
    nodesize::Union(Real, Vector) = 1,
    nodefillc::ComposeColor = colorant"turquoise",
    nodestrokec::ComposeColor = nothing,
    nodestrokelw::Union(Real, Vector) = 0,
    arrowlengthfrac::Real = Graphs.is_directed(G) ? 0.1 : 0.0,
    arrowangleoffset = 20.0/180.0*π)
=#