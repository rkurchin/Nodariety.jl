using LightGraphs, MetaGraphs
using CSV, DataFrames
using LightGraphs, NetworkLayout

# helper function
function get_node_numbers(edge::DataFrameRow, nodes)
    local filtered_1, filtered_2
    filtered_1 = filter(r->(r.family_name==edge.family_name_1), nodes)
    filtered_2 = filter(r->(r.family_name==edge.family_name_2), nodes)
    # to handle missing given names, can't filter on both at once
    if size(filtered_1)[1]>1
        filtered_1 = filter(r->(r.given_name==edge.given_name_1), filtered_1)
    end
    if size(filtered_2)[1]>1
        filtered_2 = filter(r->(r.given_name==edge.given_name_2), filtered_2)
    end
    @assert size(filtered_1)[1]==1 && size(filtered_2)[1]==1 "Seems you might have a missing or duplicate node at $row"
    return filtered_1.nodenum[1], filtered_2.nodenum[1]
end

function build_graph()
    # read in data
    nodes = DataFrame(CSV.File("data/nodes.csv"))
    edges = DataFrame(CSV.File("data/edges.csv"))

    node_props = [Symbol(p) for p in names(nodes)]
    edge_props = [Symbol(p) for p in names(edges) if !any(contains.(p, ["family_name","given_name"]))]

    # add index column
    nodes.nodenum = 1:size(nodes)[1]    

    g = MetaDiGraph(SimpleDiGraph(size(nodes)[1]))

    # add node properties
    for row in eachrow(nodes)
        props = Dict(p=>getproperty(row,Symbol(p)) for p in node_props)
        set_props!(g, row.nodenum, props)
    end

    # add edges and properties
    for row in eachrow(edges)
        props = Dict(p=>getproperty(row,Symbol(p)) for p in edge_props)
        nodenums = get_node_numbers(row, nodes)
        add_edge!(g, nodenums..., props)
    end

    return g, nodes, edges
end

"""
open("data/elements.js","w") do io
    write_JSON(io, g)
end
"""