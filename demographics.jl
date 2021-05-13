using DataFrames, CSV

nodes = DataFrame(CSV.File("data/nodes.csv"))
edges = DataFrame(CSV.File("data/edges.csv"))