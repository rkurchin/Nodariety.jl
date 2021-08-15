using Colors
using LightGraphs
using DataFrames
using Serialization
using GLMakie, GraphMakie

default_palette_start_ind = 10

# helper function
function get_distinct_palettes(num::T) where T<:Integer
    dc = round(360/(num + 1))
    hues = [h for h in round(dc/2):dc:360 - round(dc/2)]
    return sequential_palette.(hues)
end

# figure out colors for subfields...
function get_field_subfield_color_pickers(prop::String, hg::HyphenGraph = hg; palette_start_ind = default_palette_start_ind)
    @assert prop in ["field", "subfield"]
    fields = unique(skipmissing(hg.edge_info.field))
    by_field = groupby(hg.edge_info, [:field])
    palettes = get_distinct_palettes(length(fields))
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
    if prop == "subfield"
        return subfield_colors
    elseif prop == "field"
        return field_colors
    end
end

# and for continents...
function get_country_color_picker(hg::HyphenGraph = hg; palette_start_ind = default_palette_start_ind)
    country_continent = deserialize(joinpath(@__DIR__, "..", "data", "country_continent.jls"))
    countries = keys(country_continent)
    continents = unique(values(country_continent))
    palettes = get_distinct_palettes(length(continents))
    continent_pals = Dict(c=>p for (c,p) in zip(continents,palettes))
    local country_colors = Dict{Union{String,Missing},RGB}()
    # this is not very efficient, maybe I'll fix it later
    for continent in continents
        countries = [c for (c, cont) in country_continent if cont==continent]
        palette = continent_pals[continent]
        local cc_here
        if length(countries) == 1
            cc_here = Dict(countries[1]=>palette[50])
        else
            inds = Integer.(round.(range(palette_start_ind, 100, length=length(countries))))
            cc_here = Dict(c=>palette[i] for (c, i) in zip(countries, inds))
        end
        country_colors = merge(country_colors, cc_here)
    end
    return country_colors
end

# aaand years...
# (min year is to set a floor to avoid Euclid et al. skewing the colorscale, possible a logarithmic scale would be a better solution though)
function get_year_color_picker(all_years::Vector{I}; min_year=1700) where I<:Integer
    #min_year = minimum(all_years)
    max_year = maximum(all_years)
    num_years = max_year - min_year + 1
    colors = to_colormap(:RdYlGn_4, num_years)
    year_color_picker = Dict{Union{String,Integer,Missing},RGB}(i+min_year-1=>colors[i] for i in 1:num_years)
    year_color_picker[missing] = colorant"grey"
    for year in all_years
        if year < min_year
            year_color_picker[year] = colors[1]
        end
    end
    return year_color_picker
end

# and one to put it all together
function get_graph_colors(node_color_prop, 
    edge_color_prop,
    hg::HyphenGraph = hg; 
    palette_start_ind = default_palette_start_ind,
    default_node_color = colorant"grey",
    default_edge_color = colorant"grey",
    male_color = colorant"lightblue",
    female_color = colorant"pink")

    local node_color_picker = nothing
    local edge_color_picker = nothing

    # first handle years since the colorscale depends if both nodes and edge color props care...the rest is simpler
    if any(occursin.("year", [node_color_prop, edge_color_prop])) # one is a year
        # inelegant copied code here, whatevs for now
        if all(occursin.("year", [node_color_prop, edge_color_prop]))
            node_years = [y for y in skipmissing(hg.node_info[:, Symbol(node_color_prop)])]
            edge_years = [y for y in skipmissing(hg.edge_info.year)]
            all_years = unique(vcat(edge_years, node_years))
            node_color_picker = edge_color_picker = get_year_color_picker(all_years)
        elseif occursin("year", node_color_prop)
            node_years = [y for y in skipmissing(hg.node_info[:, Symbol(node_color_prop)])]
            node_color_picker = get_year_color_picker(node_years)
        elseif occursin("year", edge_color_prop)
            edge_years = [y for y in skipmissing(hg.edge_info.year)]
            edge_color_picker = get_year_color_picker(edge_years)
        end
    end

    if occursin("field", edge_color_prop)
        edge_color_picker = get_field_subfield_color_pickers(edge_color_prop, hg, palette_start_ind = palette_start_ind)
    end

    if occursin("country", node_color_prop)
        node_color_picker = get_country_color_picker(hg, palette_start_ind = palette_start_ind)
    end

    if node_color_prop == "gender"
        node_color_picker = Dict("male"=>male_color, "female"=>female_color)
    end

    if !(edge_color_prop in ["field", "subfield", "year"])
        @warn "Currently, the only supported properties for edge_color_prop are field, subfield, and year. Coloring edges with default edge color: $default_edge_color."
    end

    if !(node_color_prop in ["birth_year", "death_year", "gender", "birth_country"])
        @warn "Currently, the only supported properties for node_color_prop are birth_year, death_year, gender, and birth_country. Coloring edges with default node color: $default_node_color."
    end

    local nc, ec
    if !isnothing(edge_color_picker)
        ec = [edge_color_picker[hg.graph.eprops[j][Symbol(edge_color_prop)]] for j in edges(hg)]
    else
        ec = default_edge_color
    end

    # TODO: replace this with a function that takes the dict and the default, similarly above
    if !isnothing(node_color_picker)
        #nc = [node_color_picker[hg.graph.vprops[j][Symbol(node_color_prop)]] for j in 1:nv(hg)]
        nc = map(1:nv(hg)) do j
            key = hg.graph.vprops[j][Symbol(node_color_prop)]
            if ismissing(key)
                return default_node_color
            else
                return node_color_picker[key]
            end
        end
    else
        nc = default_node_color
    end

    return nc, ec
end

# TODO: add some default canvas size stuff to make it readable if you zoom in at least...or maybe this is doable in Pluto
# TODO: legends/colorbars

function plot_graph(g::HyphenGraph = hg;
    node_label_prop = "family_name",
    node_color_prop = "",
    default_node_color = colorant"grey",
    edge_color_prop = "",
    default_edge_color = colorant"grey",
    palette_start_ind = 10,
    male_color = colorant"lightblue",
    female_color = colorant"pink"
    )

    local nl = nothing
    if !isnothing(node_label_prop)
        nl = [g.graph.vprops[i][Symbol(node_label_prop)] for i in 1:nv(g)]
    end

    nc, ec = get_graph_colors(node_color_prop, edge_color_prop, g, palette_start_ind=palette_start_ind, default_node_color=default_node_color, default_edge_color=default_edge_color, male_color=male_color, female_color=female_color)

    f, ax, p = graphplot(g.graph,
                         arrow_show = true,
                         nlabels = nl,
                         node_color = nc,
                         edge_color = ec,
                         node_size = 20,
                         edge_width = 5,
                         arrow_size = 15,
                         nlabels_distance = 18,
                         nlabels_textsize = 16,

    )
    hidedecorations!(ax); hidespines!(ax)
    deregister_interaction!(ax, :rectanglezoom)
    register_interaction!(ax, :ndrag, NodeDrag(p))
    register_interaction!(ax, :edrag, EdgeDrag(p))

    return f
end


"""
TODO: animation where nodes appear in birth year, 
edges appear in year associated with theory 
(and can color things however)
"""