using LongestPaths

get_clusters(g::AbstractGraph = hg) =
    sort(connected_components(g.graph), by = length, rev = true)

"""
    trim_graph(g=hg, threshold=4)

Given a graph as input, find connected clusters and return a new graph that only retains clusters at least the size of `threshold`.
"""
function trim_graph(g::AbstractGraph = hg, threshold::Int = 4)
    clusters = get_clusters(g)
    indices = vcat([c for c in cs if length(c) >= threshold]...)
    return g[indices]
end

"""
    longest_path(graph=hg)

Find the longest path in the graph and return the set of indices visited.
"""
function longest_path(graph::HyphenGraph = hg)
    local longest_length = 0
    local longest_start_inds = [1]
    for i = 1:nv(graph)
        p = find_longest_path(graph.graph, i, log_level = 0)
        len = length(p.longest_path) - 1
        if len > longest_length
            longest_length = len
            longest_start_inds = [i]
        elseif len == longest_length
            append!(longest_start_inds, i)
        end
    end
    paths = [
        find_longest_path(graph.graph, i, log_level = 0).longest_path for i in longest_start_inds
    ]
    return paths
end

"""
    most_central(centrality_fcn, g=hg)

Return the most central node in `g` according to the provided centrality measure. `centrality_fcn` can be any of the Graphs centrality measures: https://juliagraphs.org/Graphs.jl/stable/algorithms/centrality/ e.g. `betweenness_centrality`, `closeness_centrality`, `degree_centrality`, and many others...

See also: [`all_centrals`](@ref)
"""
function most_central(centrality_fcn::Function, g::HyphenGraph = hg)
    c = centrality_fcn(g.graph)
    return g.graph.vprops[argmax(c)]
end

const centrality_fcns = [
    betweenness_centrality,
    closeness_centrality,
    degree_centrality,
    eigenvector_centrality,
    katz_centrality,
    pagerank,
    stress_centrality,
    radiality_centrality,
]

"""
    all_centrals(fcns=centrality_fcns, graph=hg)

Iterate through every centrality measure provided (defaults to the Graphs.jl list) and find the most central node of it in `graph`. Print results.

See also: [`most_central`](@ref)

Note that eigenvector_centrality gives different results upon repeated application...
"""
function all_centrals(fcns::Vector{Function} = centrality_fcns, graph::HyphenGraph = hg)
    for f in fcns
        node = most_central(f, graph)
        println("$f: $(node[:given_name]) $(node[:family_name])")
    end
end
