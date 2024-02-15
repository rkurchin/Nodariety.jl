using Graphs, MetaGraphs
using DataFrames
using Serialization

# helper function
function get_node_numbers(edge::DataFrameRow, node_info::DataFrame)
    local src_info, dst_info
    src_info = filter(r -> (r.family_name == edge.family_name_1), node_info)
    dst_info = filter(r -> (r.family_name == edge.family_name_2), node_info)
    # to handle missing given names, can't filter on both at once
    if size(src_info)[1] > 1
        src_info = filter(r -> (r.given_name == edge.given_name_1), src_info)
    end
    if size(dst_info)[1] > 1
        dst_info = filter(r -> (r.given_name == edge.given_name_2), dst_info)
    end
    @assert size(src_info)[1] == 1 && size(dst_info)[1] == 1 "Seems you might have a missing or duplicate node at $edge"
    return src_info.nodenum[1], dst_info.nodenum[1]
end

"""
    HyphenGraph(node_info_path, edge_info_path)

Construct a HyphenGraph object given paths to two CSV's containing the requisite information about the nodes and edges. These default to the built-in datasets. The resulting HyphenGraph object stores the graph itself as a `MetaDiGraph` (with features from the CSV's attached to nodes and edges), as well as the contents of the CSV's as DataFrames in the `node_info` and `edge_info` fields.
"""
struct HyphenGraph{T} <: AbstractGraph{T}
    graph::MetaDiGraph
    node_info::DataFrame
    edge_info::DataFrame
end

function HyphenGraph(
    node_info_path::String = joinpath(@__DIR__, "..", "data", "nodes.csv"),
    edge_info_path::String = joinpath(@__DIR__, "..", "data", "edges.csv"),
    T = Integer,
)

    # read in node info and add index and continent column
    node_info = DataFrame(CSV.File(node_info_path))
    country_continent =
        deserialize(joinpath(@__DIR__, "..", "data", "country_continent.jls"))
    country_continent = merge(country_continent, Dict(missing => missing))
    node_info = select(
        node_info,
        names(node_info)...,
        :birth_country => ByRow(x -> country_continent[x]) => :birth_continent,
    )
    node_props = [Symbol(p) for p in names(node_info)]
    node_info.nodenum = 1:size(node_info)[1]

    # read in edge info and add src/dst columns
    edge_info = DataFrame(CSV.File(edge_info_path))
    edge_props = [
        Symbol(p) for
        p in names(edge_info) if !any(contains.(p, ["family_name", "given_name"]))
    ]
    src_dest_tuples = map(r -> Nodariety.get_node_numbers(r, node_info), eachrow(edge_info))
    edge_info.src = [sdt[1] for sdt in src_dest_tuples]
    edge_info.dst = [sdt[2] for sdt in src_dest_tuples]

    graph = MetaDiGraph(SimpleDiGraph(size(node_info)[1]))

    # add node properties
    for row in eachrow(node_info)
        props = Dict(p => getproperty(row, p) for p in node_props)
        set_props!(graph, row.nodenum, props)
    end

    # add edges and properties
    for row in eachrow(edge_info)
        props = Dict(p => getproperty(row, p) for p in edge_props)
        nodenums = row.src, row.dst
        add_edge!(graph, nodenums..., props)
    end

    HyphenGraph{T}(graph, node_info, edge_info)
end

# pretty printing
function Base.show(io::IO, g::HyphenGraph)
    st = "HyphenGraph with $(nv(g)) people, $(ne(g)) hyphens"
    print(io, st)
end

# implement Graphs API...
Base.zero(HyphenGraph) =
    HyphenGraph(MetaDiGraph(zero(SimpleDiGraph)), DataFrame(), DataFrame())
Graphs.edges(g::HyphenGraph) = Graphs.edges(g.graph)
Graphs.edgetype(g::HyphenGraph) = Graphs.edgetype(g.graph)
Graphs.has_edge(g::HyphenGraph, i, j) = Graphs.has_edge(g.graph, i, j)
Graphs.has_vertex(g::HyphenGraph, v::Integer) = Graphs.has_vertex(g.graph, v)
Graphs.inneighbors(g::HyphenGraph, node) = Graphs.inneighbors(g.graph, node)
Graphs.ne(g::HyphenGraph) = Graphs.ne(g.graph)
Graphs.nv(g::HyphenGraph) = Graphs.nv(g.graph)
Graphs.outneighbors(g::HyphenGraph, node) = Graphs.outneighbors(g.graph, node)
Graphs.vertices(g::HyphenGraph) = Graphs.vertices(g.graph)
Graphs.is_directed(g::HyphenGraph) = true
Graphs.is_directed(::Type{HyphenGraph}) = true

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

# NB that this implementation messes up the indices currently
# which is why in graph_analysis.jl, I have to call induced_subraph on graph.graph
# instead of just graph
function Graphs.induced_subgraph(
    g::HyphenGraph{T},
    vlist::AbstractVector{U},
) where {U<:Integer,T<:Integer}
    # this is the easy part...
    new_graph = g.graph[vlist]

    # then we have to cut up the dataframes...
    # nodes are pretty easy...
    new_node_info = hg.node_info[vlist, :]
    new_node_info.nodenum = 1:length(vlist)

    # now edges...a bit trickier
    # this is not quite right but it's something like this...
    index_map = Dict(vlist[i] => i for i = 1:length(vlist))
    new_edges = [(e.src, e.dst) for e in edges(new_graph)]

    new_edge_info = filter(e -> edge_has_nodes(e, new_edges, index_map), hg.edge_info)
    @assert size(new_edge_info, 1) == ne(new_graph) "Edge counts don't match up!"

    new_edge_info.src = map(i -> index_map[i], new_edge_info.src)
    new_edge_info.dst = map(i -> index_map[i], new_edge_info.dst)

    vmap = map(i -> index_map[i], vlist)

    return HyphenGraph{T}(new_graph, new_node_info, new_edge_info), vmap
end
