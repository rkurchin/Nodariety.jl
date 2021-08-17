module Nodariety

using CSV, DataFrames
using LightGraphs

include("hyphengraph.jl")
hg = HyphenGraph()
export HyphenGraph, hg
export is_directed

include("demographics.jl")
export node_histogram

include("graph_analysis.jl")
export longest_path, get_clusters
export centrality_fcns
export most_central, all_centrals

# TODO: save country_continent to json instead of jls
include("graph_vis.jl")
export plot_graph

include("write_json.jl")
export write_JSON

end
