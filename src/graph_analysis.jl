using LongestPaths

get_clusters(g::AbstractGraph = hg) = sort(connected_components(g.graph), by=length, rev=true)

# TODO: return all the indices, return top-N longest
function longest_path(graph::HyphenGraph = hg)
    local longest_length = 0
    local longest_start_inds = [1]
    for i=1:nv(graph)
        p = find_longest_path(graph, i, log_level=0)
        len = length(p.longest_path)-1
        if len > longest_length
            longest_length = len
            longest_start_inds = [i]
        elseif len == longest_length
            append!(longest_start_inds, i)
        end
    end
    return longest_length, longest_start_inds
end

# centrality_fcn can be any of the LightGraphs centrality measures: https://juliagraphs.org/LightGraphs.jl/stable/centrality/
# e.g. betweenness_centrality, closeness_centrality, degree_centrality, and many others...
function most_central(centrality_fcn::Function, g::HyphenGraph = hg)
    c = centrality_fcn(g.graph)
    return g.graph.vprops[argmax(c)]
end

const centrality_fcns = [betweenness_centrality, closeness_centrality, degree_centrality, eigenvector_centrality, katz_centrality, pagerank, stress_centrality, radiality_centrality]

# note that eigenvector_centrality gives different results upon repeated application...
function all_centrals(fcns::Vector{Function} = centrality_fcns, graph::HyphenGraph = hg)
    for f in fcns
        node = most_central(f, graph)
        println("$f: $(node[:given_name]) $(node[:family_name])")
    end
end
