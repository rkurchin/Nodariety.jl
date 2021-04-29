using LightGraphs, MetaGraphs
using CSV, DataFrames

# read in info
nodes = DataFrame(CSV.File("data/nodes.csv"))
edges = DataFrame(CSV.File("data/edges.csv"))

node_props = [Symbol(p) for p in names(nodes) if !any(contains.(p, ["family_name","given_name"]))]
edge_props = [Symbol(p) for p in names(edges) if !any(contains.(p, ["family_name","given_name"]))]

# add index column
nodes.nodenum = 1:size(nodes)[1]

# helper function
function get_node_numbers(row::DataFrameRow)
    filtered_1 = filter(r->(r.family_name==row.family_name_1 && r.given_name==row.given_name_1), nodes)
    filtered_2 = filter(r->(r.family_name==row.family_name_2 && r.given_name==row.given_name_2), nodes)
    @assert size(filtered_1)[1]==1 && size(filtered_2)[1]==1 "Seems you might have a missing or duplicate node at $row"
    return filtered_1.nodenum[1], filtered_2.nodenum[1]
end

# build graph
g = MetaDiGraph(SimpleDiGraph(size(nodes)[1]))

# add node properties
for row in eachrow(nodes)
    props = Dict(p=>getproperty(row,Symbol(p)) for p in node_props)
    set_props!(g, row.nodenum, props)
end

# add edges and properties
for row in eachrow(edges)
    props = Dict(p=>getproperty(row,Symbol(p)) for p in edge_props)
    nodenums = get_node_numbers(row)
    add_edge!(g, nodenums..., props)
end
