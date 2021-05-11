using LightGraphs, MetaGraphs
using CSV, DataFrames
using GraphMakie

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

    return g
end

function item_string(gprops, ind, pos=nothing)
    local str = "    {\n      \"data\":\n     {\n        \"id\": \"$(ind)\",\n        \"selected\": false,"
    props = gprops[ind]
    isnode = typeof(ind) <: Integer
    if isnode
        str = string(str, "\n        \"NodeType\": \"Cheese\",")
    else
        str = string(str, "\n        \"interaction\": \"cc\",")
        str = string(str, "\n        \"source\": \"$(ind.src)\",")
        str = string(str, "\n        \"target\": \"$(ind.dst)\",")
    end
    for k in keys(props)
        prop = props[k]
        local propstr
        if !(typeof(prop)<:Number)
            propstr = "\"$prop\""
        else
            propstr = string(prop)
        end
        str = string(str, "\n        \"$(k)\": $propstr,")
    end
    str = string(str[1:end-1], "\n      },")
    if !isnothing(pos)
        str = string(str, "\n      \"position\": {\n        \"x\": $(pos[1]),\n        \"y\": $(pos[2])\n      },")
    end
    str = string(str, "\n      \"selected\": false\n    },\n")
    return str
end

function write_JSON(io::IO, g::MetaDiGraph=build_graph())
    gp = graphplot(g)
    pos = gp.plot.attributes.node_positions.val
    local bigstr = "const elements = {\n  \"nodes\": [\n"
    for nodenum in keys(g.vprops)
        bigstr = string(bigstr, item_string(g.vprops, nodenum, pos[nodenum]))
    end
    bigstr = string(bigstr, "\n  ],\n  \"edges\": [\n")
    for edge in keys(g.eprops)
        bigstr = string(bigstr, item_string(g.eprops, edge))
    end
    bigstr = string(bigstr, "\n  ],\n};")
    bigstr = string(bigstr, "\n
elements.nodes.forEach((n) => {
const data = n.data;
    
n.data.orgPos = {
  x: n.position.x,
  y: n.position.y
  };
});
    
export default elements;")
    print(io, bigstr)
end