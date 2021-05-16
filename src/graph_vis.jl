using Compose, Colors
using Cairo, Fontconfig
using LightGraphs, GraphPlot
using DataFrames

# figure out colors for subfields...
function get_field_subfield_color_pickers(hg::HyphenGraph = hg, palette_start_ind = 10)
    fields = unique(skipmissing(hg.edge_info.field))
    by_field = groupby(hg.edge_info, [:field])
    dc = round(360/(length(fields) + 1))
    hues = [h for h in round(dc/2):dc:360 - round(dc/2)]
    palettes = sequential_palette.(hues)
    field_pals = Dict(f=>p for (f,p) in zip(fields,palettes))
    field_colors = Dict{Union{String,Missing},RGB}(f=>p[50] for (f,p) in zip(fields,palettes))
    local subfield_colors = Dict{Union{String,Missing},RGB}()
    for (field, palette) in zip(fields, palettes)
        data = by_field[by_field.keymap[(field,)]]
        subfields = unique(skipmissing(data.subfield))
        local sc_here
        if length(subfields) == 1
            sc_here = Dict(subfields[1]=>palette[50])
        else
            inds = Integer.(round.(range(palette_start_ind, 100, length=length(subfields))))
            sc_here = Dict(sf=>palette[i] for (sf, i) in zip(subfields, inds))
        end
        subfield_colors = merge(subfield_colors, sc_here)
    end
    field_colors[missing] = colorant"grey"
    subfield_colors[missing] = colorant"grey"
    return field_colors, subfield_colors
end

# and for continents...
function get_country_color_picker(hg::HyphenGraph = hg)
    # ...
end

# aaand years...
# function get_year_color_picker(hg::HyphenGraph = hg, node_color_prop::String, edge_color_prop::String)
#     # ...
# end

# and one to put it all together, maybe?
# function get_graph_colors(hg::HyphenGraph = hg, node_color_prop::String, edge_color_prop::String)
#     # ...
#     return node_colors, edge_colors
# end

# TODO: add some default canvas size stuff to make it readable if you zoom in at least
# draw(PNG("test1.png", 40cm, 40cm), gplot(...))
function plot_graph(hg::HyphenGraph = hg;
    node_label_prop = "family_name",
    edge_label_prop = nothing,
    node_color_prop = nothing,
    default_node_color = colorant"grey",
    edge_color_prop = nothing,
    default_edge_color = colorant"grey",
    palette_start_ind = 10,
    )

    nl = [hg.graph.vprops[i][Symbol(node_label_prop)] for i in 1:nv(hg)]
    local ec, nc
    # TODO: clean this up
    if !isnothing(edge_color_prop)
        local edge_color_picker = Dict{Union{Integer,String,Missing},RGB}()
        local field_colors, subfield_colors = get_field_subfield_color_pickers(hg, palette_start_ind)
        if edge_color_prop == "field"
            edge_color_picker = field_colors
        elseif edge_color_prop == "subfield"
            edge_color_picker = subfield_colors
        elseif edge_color_prop == "year"
            local all_years
            local edge_years = [y for y in skipmissing(hg.edge_info.year)]
            if node_color_prop in ["birth_year", "death_year"]
                node_years = [y for y in skipmissing(hg.node_info[:, Symbol(node_collr_prop)])]
                all_years = unique(vcat(edge_years, node_years))
            else
                all_years = edge_years
            end
            min_year = minimum(all_years)
            max_year = maximum(all_years)
            num_years = max_year - min_year + 1
            colors = RGB.(colormatch.(range(425, 670, length=num_years)))
            edge_color_picker = Dict{Union{String,Integer,Missing},RGB}(i+min_year-1=>colors[i] for i in 1:num_years)
            edge_color_picker[missing] = colorant"grey"
        else
            @warn "Currently, the only supported properties for edge_color_prop are field, subfield, and year. Coloring edges with default edge color: $default_edge_color."
            ec = default_edge_color
        end
        if !isempty(edge_color_picker)
            ec = [edge_color_picker[hg.graph.eprops[j][Symbol(edge_color_prop)]] for j in edges(hg)]
        end
    else
        ec = default_edge_color
    end

    if !isnothing(node_color_prop)
        local node_color_picker = Dict{Union{Integer,Missing},RGB}()
        if node_color_prop in ["birth_year", "death_year"]
            node_color_picker = edge_color_picker
        elseif node_color_prop == "gender"

        elseif node_color_prop == "birth_country"
            
        else
            @warn "Currently, the only supported properties for node_color_prop are birth_year, death_year, gender, and birth_country. Coloring edges with default node color: $default_node_color."
            nc = default_node_color
        end
        if !isempty(node_color_picker)
            nc = [node_color_picker[hg.graph.vprops[j][Symbol(node_color_prop)]] for j in 1:nv(hg)]
        end
    else
        nc = default_node_color
    end

    gplot(hg.graph, nodelabel=nl, nodefillc=nc, edgestrokec=ec, arrowlengthfrac=0.05)
end



#=
function gplot{V, T<:Real}(
    G::AbstractGraph{V},
    locs_x::Vector{T}, locs_y::Vector{T};
    nodelabel::Union(Nothing, Vector) = nothing,
    nodelabelc::ComposeColor = colorant"black",
    nodelabelsize::Union(Real, Vector) = 4,
    nodelabeldist::Real = 0,
    nodelabelangleoffset::Real = π/4.0,
    edgelabel::Union(Nothing, Vector) = nothing,
    edgelabelc::ComposeColor = colorant"black",
    edgelabelsize::Union(Real, Vector) = 4,
    edgestrokec::ComposeColor = colorant"lightgray",
    edgelinewidth::Union(Real, Vector) = 1,
    edgelabeldistx::Real = 0,
    edgelabeldisty::Real = 0,
    nodesize::Union(Real, Vector) = 1,
    nodefillc::ComposeColor = colorant"turquoise",
    nodestrokec::ComposeColor = nothing,
    nodestrokelw::Union(Real, Vector) = 0,
    arrowlengthfrac::Real = Graphs.is_directed(G) ? 0.1 : 0.0,
    arrowangleoffset = 20.0/180.0*π)
=#

"""
TODO: animation where nodes appear in birth year, 
edges appear in year associated with theory 
(and can color things however)
"""