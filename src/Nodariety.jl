module Nodariety

using LightGraphs

include("build_graph.jl")
export g, nodes, edges
g, nodes, edges = build_graph()

include("demographics.jl")
# export ...

include("graph_analysis.jl")
export centrality_fcns
export longest_path, most_central


include("graphplot.jl")
# export ...

include("write_json.jl")
export write_JSON

end
