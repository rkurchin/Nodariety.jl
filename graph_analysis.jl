using LongestPaths

function longest_path(g)
    local longest_length = 0
    local longest_start_inds = [1]
    for i=1:nv(g)
        p = find_longest_path(g, i);
        len = length(p.longest_path)-1
        if len > longest_length
            println(len)
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
function most_central(g, centrality_fcn)
    c = centrality_fcn(g)
    return g.vprops[argmax(c)]
end

const centrality_fcns = [betweenness_centrality, closeness_centrality, degree_centrality, eigenvector_centrality, katz_centrality, pagerank, stress_centrality, radiality_centrality]

# note that eigenvector_centrality gives different results upon repeated application...
function all_centrals(g, fcns = centrality_fcns)
    for f in fcns
        node = most_central(g, f)
        println("$f: $(node[:given_name]) $(node[:family_name])")
    end
end