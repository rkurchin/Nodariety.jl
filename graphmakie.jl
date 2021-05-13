using GraphMakie, CairoMakie
include("build_graph.jl")

g = build_graph()
clusters = sort(connected_components(g), by=length, rev=true)
sg = g
#sg = g[clusters[5]]


nl = [sg.vprops[i][:family_name] for i in 1:nv(sg)]
#el = 

gp = graphplot(sg, nlabels=nl, node_size=8)
#gp = graphplot(g)