module Nodariety

using CSV, DataFrames
using LightGraphs

include("build_hyphengraph.jl")
nodes = DataFrame(CSV.File("data/nodes.csv"))
edges = DataFrame(CSV.File("data/edges.csv"))
hg = build_hyphengraph()
export hg, nodes, edges

include("demographics.jl")
# export ...

include("graph_analysis.jl")
export get_clusters
export centrality_fcns, all_centrals
export longest_path, most_central


include("graphplot.jl")
# export ...

include("write_json.jl")
export write_JSON

end
