using DataFrames
using StatsBase
using GLMakie

"""
    node_histogram(prop, g=hg)

Make a histogram of values of a node property of the HyphenGraph.

Options for `prop` currently include: `birth_country`, `birth_continent`, `race`, `gender`, `given_name`
"""
function node_histogram(prop, g::HyphenGraph = hg, fig_height = 600)
    data = skipmissing(g.node_info[:, prop])
    datamap = countmap(data)
    s = sort(unique(data), by = x -> datamap[x], rev = true)
    fig_width =
        maximum([Int(round(length(s) / 20 * fig_height)), Int(round(fig_height / 2))])
    f = Figure(resolution = (fig_width, fig_height))
    a = Axis(
        f[1, 1],
        xlabel = prop,
        ylabel = "count",
        xticks = (1:length(datamap), s),
        xticklabelrotation = π / 3,
    )
    barplot!(a, 1:length(datamap), (x -> datamap[x]).(s))
    display(f)
end
