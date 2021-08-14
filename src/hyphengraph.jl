using LightGraphs, MetaGraphs
using DataFrames

# helper function
function get_node_numbers(edge::DataFrameRow, node_info::DataFrame)
    local src_info, dst_info
    src_info = filter(r->(r.family_name==edge.family_name_1), node_info)
    dst_info = filter(r->(r.family_name==edge.family_name_2), node_info)
    # to handle missing given names, can't filter on both at once
    if size(src_info)[1]>1
        src_info = filter(r->(r.given_name==edge.given_name_1), src_info)
    end
    if size(dst_info)[1]>1
        dst_info = filter(r->(r.given_name==edge.given_name_2), dst_info)
    end
    @assert size(src_info)[1]==1 && size(dst_info)[1]==1 "Seems you might have a missing or duplicate node at $edge"
    return src_info.nodenum[1], dst_info.nodenum[1]
end

struct HyphenGraph{T} <: AbstractGraph{T}
    graph::MetaDiGraph
    node_info::DataFrame
    edge_info::DataFrame
end

# function HyphenGraph(node_info_path::String = joinpath(pathof(Nodariety), "data", "nodes.csv"), 
#     edge_info_path::String = joinpath(pathof(Nodariety), "data", "elements.csv"))
function HyphenGraph(node_info_path::String = joinpath(@__DIR__, "..", "data", "nodes.csv"), 
    edge_info_path::String = joinpath(@__DIR__, "..", "data", "edges.csv"),
    T = Integer)

    # read in node info and add index column
    node_info = DataFrame(CSV.File(node_info_path))
    node_props = [Symbol(p) for p in names(node_info)]
    node_info.nodenum = 1:size(node_info)[1] 

    # read in edge info and add src/dst columns
    edge_info = DataFrame(CSV.File(edge_info_path))
    edge_props = [Symbol(p) for p in names(edge_info) if !any(contains.(p, ["family_name","given_name"]))]
    src_dest_tuples = map(r->Nodariety.get_node_numbers(r, node_info), eachrow(edge_info))
    edge_info.src = [sdt[1] for sdt in src_dest_tuples] 
    edge_info.dst = [sdt[2] for sdt in src_dest_tuples] 
 
    graph = MetaDiGraph(SimpleDiGraph(size(node_info)[1]))

    # add node properties
    for row in eachrow(node_info)
        props = Dict(p=>getproperty(row ,p) for p in node_props)
        set_props!(graph, row.nodenum, props)
    end

    # add edges and properties
    for row in eachrow(edge_info)
        props = Dict(p=>getproperty(row, p) for p in edge_props)
        nodenums = row.src, row.dst
        add_edge!(graph, nodenums..., props)
    end

    HyphenGraph{T}(graph, node_info, edge_info)
end

# pretty printing
function Base.show(io::IO, g::HyphenGraph)
    st = "HyphenGraph with $(nv(g)) people, $(ne(g)) hyphens"
    # if length(g.featurization)!=0
    #     st = string(st, ", feature vector length $(size(g.features)[1])")
    # end
    print(io, st)
end

# implement LightGraphs API...
const lg = LightGraphs
# Base.reverse
Base.zero(HyphenGraph) = HyphenGraph(MetaDiGraph(zero(SimpleDiGraph)), DataFrame(), DataFrame())
lg.edges(g::HyphenGraph) = lg.edges(g.graph)
lg.edgetype(g::HyphenGraph) = lg.edgetype(g.graph)
lg.has_edge(g::HyphenGraph, i, j) = lg.has_edge(g.graph, i, j)
lg.has_vertex(g::HyphenGraph, v::Integer) = lg.has_vertex(g.graph, v)
lg.inneighbors(g::HyphenGraph, node) = lg.inneighbors(g.graph, node)
lg.ne(g::HyphenGraph) = lg.ne(g.graph)
lg.nv(g::HyphenGraph) = lg.nv(g.graph)
lg.outneighbors(g::HyphenGraph, node) = lg.outneighbors(g.graph, node)
lg.vertices(g::HyphenGraph) = lg.vertices(g.graph)
lg.eltype(g::HyphenGraph) = lg.eltype(g.graph)
lg.weights(g::HyphenGraph) = lg.weights(g.graph)
# I'm  not sure which one of these I need, but even with all of them calling some of the centrality stuff directly on the HyphenGraph doesn't seem to work :/
lg.is_directed(g::HyphenGraph) = true
lg.is_directed(::Type{HyphenGraph}) = true
#lg.is_directed(HyphenGraph) = true

# helper fcn
function edge_has_nodes(edge, new_edges, index_map)
    if edge[:src] in keys(index_map) && edge[:dst] in keys(index_map)
        if (index_map[edge[:src]], index_map[edge[:dst]]) in new_edges
            return true
        else
            return false
        end
    else
        return false
    end
end

function lg.induced_subgraph(g::HyphenGraph{T}, vlist::AbstractVector{U}) where {U<:Integer, T<:Integer}
    # this is the easy part...
    new_graph = g.graph[vlist]

    # then we have to cut up the dataframes...
    # nodes are pretty easy...
    new_node_info = hg.node_info[vlist, :]
    new_node_info.nodenum = 1:length(vlist)

    # now edges...a bit trickier
    # this is not quite right but it's something like this...
    index_map = Dict(vlist[i]=>i for i in 1:length(vlist))
    new_edges = [(e.src, e.dst) for e in edges(new_graph)]

    new_edge_info = filter(e -> edge_has_nodes(e, new_edges, index_map), hg.edge_info)
    @assert size(new_edge_info,1) == ne(new_graph) "Edge counts don't match up!"

    new_edge_info.src = map(i->index_map[i], new_edge_info.src)
    new_edge_info.dst = map(i->index_map[i], new_edge_info.dst)

    vmap = map(i->index_map[i], vlist)

    return HyphenGraph{T}(new_graph, new_node_info, new_edge_info), vmap

end

