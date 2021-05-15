using DataFrames
using StatsBase
using CairoMakie

function get_histogram_data(df, column_name)
    subset = dropmissing(df, column_name)
    gd = groupby(nodes, colunn_name)
    # ...
end

# subset = dropmissing(nodes, :birth_year)
# bins = vcat(1500:20:2000)
# hist(subset.birth_year, bins=bins)



# differences in birth year along edges?

# histograms of gender, birth year, race, country, etc...

# for the case of country...
function country_hist()
    data = skipmissing(nodes.birth_country)
    datamap = countmap(data)
    s = sort(unique(data), by=x->datamap[x], rev=true)
    #barplot((x -> datamap[x]).(s), xticks=(1:36, s), xrotation=90)
    f = Figure()
    a = Axis(f[1,1], xlabel="Country", ylabel="Count", xticks = (1:36, s), xticklabelrotation=π/3)
    barplot!(a, 1:36, (x -> datamap[x]).(s))
    display(f)
end