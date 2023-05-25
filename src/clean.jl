using Graphs
using MetaGraphs
using JLD2
using FileIO
using JSON

function dG(lat1, lon1, lat2, lon2; R=6371000)
    Pi, Ri = deg2rad(lat1), deg2rad(lon1)
    Pj, Rj = deg2rad(lat2), deg2rad(lon2)
    v1 = sin((Pj - Pi) / 2)
    v2 = sin((Rj - Ri) / 2)
    vv = v1 ^ 2 + cos(Pi) * cos(Pj) * v2 ^ 2
    d = 2 * R * asin(sqrt(vv))
    return d
end

function clean(;th = 25, city="nihonbashi", dir="data")
    fn = "$(dir)/$(city)_graph.jld2"
    d = jldopen(fn)
    mg = d["graph"]

    counter = 0
    while true
        println("n=$(nv(mg)), m=$(ne(mg))")
        locs = zeros(nv(mg), 2)
        for n in vertices(mg)
            lat_n, lon_n = get_prop(mg, n, :lat), get_prop(mg, n, :lon)
            locs[n, 1] = lat_n
            locs[n, 2] = lon_n
        end


        flag = false
        target = (-1, -1)
        for n in vertices(mg)
            pn = locs[n, :]
            for m in neighbors(mg, n)
                pm = locs[m, :]
                # println("$n $m")
                dnm = dG(pn[1], pn[2], pm[1], pm[2])
                if dnm < th
                    target = (n, m)
                    flag = true
                    break
                end
            end
            
            (flag) && break
        end

        # no two `too near' points
        if !flag
            break
        end

        # update
        # println("$target")
        new_node_loc_lat = (locs[target[1], 1] + locs[target[2], 1]) / 2
        new_node_loc_lon = (locs[target[1], 2] + locs[target[2], 2]) / 2

        # neighbors
        ng_n = neighbors(mg, target[1])
        ng_m = neighbors(mg, target[2])
        new_n = nv(mg) + 1
        
        new_mg = copy(mg)
        add_vertex!(new_mg)
        set_prop!(new_mg, new_n, :lat, new_node_loc_lat)
        set_prop!(new_mg, new_n, :lon, new_node_loc_lon)

        # println("$(target[1]) $ng_n")
        for m in ng_n
            (m == target[2]) && continue
            dnm = dG(new_node_loc_lat, new_node_loc_lon, locs[m, 1], locs[m, 2])
            add_edge!(new_mg, new_n, m)
            set_prop!(new_mg, new_n, m, :dist, dnm)
        end

        # println("$(target[2]) $ng_m")
        for m in ng_m
            (m == target[1]) && continue
            dnm = dG(new_node_loc_lat, new_node_loc_lon, locs[m, 1], locs[m, 2])
            add_edge!(new_mg, new_n, m)
            set_prop!(new_mg, new_n, m, :dist, dnm)
        end

        rem_vertex!(new_mg, target[1])
        rem_vertex!(new_mg, target[2])

        if nv(mg) == nv(new_mg)
            break
        end

        # next loop
        mg = new_mg
        counter += 1
    end


    # output
    println("n=$(nv(mg)), m=$(ne(mg))")

    data = Dict("markers" => [])
    for n in vertices(mg)
        lat_n, lon_n = get_prop(mg, n, :lat), get_prop(mg, n, :lon)
        push!(data["markers"], [lat_n, lon_n])
    end

    # output to JLD2
    jldopen("$(dir)/clean/$(city)_graph.jld2", "w") do dict
        dict["graph"] = mg
    end

end