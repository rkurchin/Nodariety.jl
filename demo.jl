using Nodariety
using MetaGraphs
using Graphs

n = 77 # pick a number, this would be Dirac

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

# demographics (if time)
# ...

# graph viz
# pick some colorcodings to try etc.

# then show website