using Graphs
using MetaGraphs
using JLD2
using FileIO
using JSON
using Plots
gr()

function main(;city="nihonbashi", dir="data", output_dir="output_figs")
    fn = "$(dir)/$(city)_graph.jld2"
    d = jldopen(fn)
    mg = d["graph"]

    println("n=$(nv(mg)), m=$(ne(mg))")
    locs = zeros(nv(mg), 2)
    for n in vertices(mg)
        lat_n, lon_n = get_prop(mg, n, :lat), get_prop(mg, n, :lon)
        locs[n, 1] = lon_n
        locs[n, 2] = lat_n
    end

    # (X, Y) sizes
    xmin = minimum(locs[:, 1])
    xmax = maximum(locs[:, 1])
    ymin = minimum(locs[:, 2])
    ymax = maximum(locs[:, 2])
    println("$xmin $xmax")
    println("$ymin $ymax")
    ratio = (ymax - ymin) / (xmax - xmin)
    fw = 500
    fh = fw * ratio
    f = plot(size=(fw, fh), dpi=150)
    for n in vertices(mg)
        for m in neighbors(mg, n)
            (n >= m) && continue
            pX = locs[[n, m], 1]
            pY = locs[[n, m], 2]
            plot!(f, pX, pY, lw=2, alpha=0.5, label=nothing, color=:gray)
        end
    end
    scatter!(f, locs[:, 1], locs[:, 2], marker=:circle, label=nothing, ms=3, alpha=0.3, color=:gray)
    savefig(f, "$(output_dir)/output_$(city).png")

end