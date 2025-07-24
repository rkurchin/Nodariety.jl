using Nodariety
using MetaGraphs
using Graphs

# pick a number, a few possibilities below...
n = 77 # this would be Dirac
# n = 36 # Cauchy
# n = 45 # Cayley
# n = 338 # Riemann

props(hg.graph, n) # get info about this node

# find the hyphens from here...
inn = inneighbors(hg, n)
outn = outneighbors(hg, n)

# find info about an edge
props(hg.graph, inn[1], n)

# what about my original question?
paths = longest_path()

subgraph = hg[paths[2]]

subgraph.node_info.family_name

# centrality?
all_centrals()

# cycles?
cycs = simplecycles(hg.graph)
get_prop.(Ref(hg.graph), cycs, Ref(:family_name))

# demographics (if time)
node_histogram("birth_country")

# graph viz, etc.
clus = get_clusters()
g2 = induced_subgraph(hg, clus[1])[1]
plot_graph(g2, node_color_prop="birth_year", edge_color_prop="year")

# then show website: https://rkurchin.github.io/nodarietyvis/