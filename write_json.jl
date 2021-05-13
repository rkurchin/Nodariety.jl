include("build_graph.jl")

function item_string(gprops, ind, pos=nothing)
    local str = "    {\n      \"data\":\n     {\n        \"id\": \"$(ind)\",\n        \"selected\": false,"
    props = gprops[ind]
    isnode = typeof(ind) <: Integer
    if isnode
        str = string(str, "\n        \"NodeType\": \"Cheese\",")
        str = string(str, "\n        \"name\": \"$(props[:given_name]) $(props[:family_name])\",")
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

function write_JSON(io::IO, g::MetaDiGraph=build_graph(); 
                    min_x = 1300, max_x = 6500, min_y = 2500, max_y = 5000)
    pos= NetworkLayout.Spring.layout(adjacency_matrix(g))
    # transform to something sensible as pixel units...
    x = [p[1] for p in pos]
    y = [p[2] for p in pos]
    # first shift (minimum is always negative...I think)
    x = x .- minimum(x)
    y = y .- minimum(y)
    # then scale to be 0 - 1
    x = x ./ maximum(x)
    y = y ./ maximum(y)
    # now shift and scale again
    x_scale = max_x - min_x
    y_scale = max_y - min_y
    x = min_x .+ x_scale .* x
    y = min_y .+ y_scale .* y
    pos = [[x[i], y[i]] for i in 1:length(x)]
    local bigstr = "const elements = {\n  \"nodes\": [\n"
    for nodenum in keys(g.vprops)
        #bigstr = string(bigstr, item_string(g.vprops, nodenum))
        bigstr = string(bigstr, item_string(g.vprops, nodenum, pos[nodenum]))
    end
    bigstr = string(bigstr, "\n  ],\n  \"edges\": [\n")
    for edge in keys(g.eprops)
        bigstr = string(bigstr, item_string(g.eprops, edge))
    end
    bigstr = string(bigstr, "\n  ],\n};")
    bigstr = string(bigstr, "\n
elements.nodes.forEach((n) => {
    
n.data.orgPos = {
  x: n.position.x,
  y: n.position.y
  };
});
    
export default elements;")
    print(io, bigstr)
end