using GraphMakie, CairoMakie
include("build_graph.jl")

g = build_graph()

plot_graph(g)