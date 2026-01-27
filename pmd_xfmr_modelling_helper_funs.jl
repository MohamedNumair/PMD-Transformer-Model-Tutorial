
# HELPER FUNCTIONS #
# I recommend skipping reading the definitions of these helper functions for now to maintain the flow of the narrative. You can revisit the implementation details once you have a firm grasp of the core concepts.function show_transformer_math_components(math; suppress_print::Bool=false)

PowerModelsDistribution.silence!()

"""
    show_transformer_math_components(math::Dict; suppress_print::Bool=false) -> Dict{String, Any}

Extracts and optionally displays the components (buses, branches, transformers) in a mathematical grid model that correspond to original transformers from the engineering model.

This function iterates through the `map` of the given `math` model dictionary to find elements transformed via the key `"_map_math2eng_transformer!"`. For each identified transformer, it aggregates the resulting mathematical components.

# Arguments
- `math::Dict`: The mathematical model dictionary (typically resulting from a PowerModels/PowerModelsDistribution transformation).
- `suppress_print::Bool`: If `true`, suppresses the output of component details to the console. Default is `false`.
- `show_bus_details::Bool`: If `true`, displays detailed information for bus components. Default is `false`.

# Returns
- `Dict{String, Any}`: A nested dictionary where the top-level keys are the original transformer names. Each value is a dictionary containing:
    - `"buses"`: A dictionary of associated bus components.
    - `"branches"`: A dictionary of associated branch components.
    - `"transformers"`: A dictionary of associated transformer components (if any remain as explicit transformers in the math model).
"""

function show_transformer_math_components(math; suppress_print::Bool=false, suppress_bus_details::Bool=false)
    results = Dict{String,Any}()
    transformer_index_byname = findall(x -> haskey(x, "unmap_function") && x["unmap_function"] == "_map_math2eng_transformer!", math["map"])
    for idx in transformer_index_byname
        trafo_name = math["map"][idx]["from"]

        if !suppress_print
            display("in the MATHEMATICAL model transformer " * trafo_name * " was converted to: ")
        end

        results[trafo_name] = Dict{String,Any}("buses" => Dict{String,Any}(), "branches" => Dict{String,Any}(), "transformers" => Dict{String,Any}())

        for element in math["map"][idx]["to"]
            element_type = split(element, ".")[1]
            element_idx = split(element, ".")[2]

            if !suppress_print

                if element_type != "bus" # || suppress_bus_details
                    display("================================" * element_type * " " * element_idx * "================================")
                    # display("Element Index: " * element_idx)    
                    display(math[element_type][element_idx])
                end


            end

            if element_type == "bus"
                results[trafo_name]["buses"][element_idx] = math[element_type][element_idx]
            elseif element_type == "branch"
                results[trafo_name]["branches"][element_idx] = math[element_type][element_idx]
            elseif element_type == "transformer"
                results[trafo_name]["transformers"][element_idx] = math[element_type][element_idx]
            end
        end
    end
    return results
end


# Helper Function to Run Simulation and Plot
"""
    analyze_vector_group(prim_conn, sec_conn, prim_perm, sec_perm, lead_lag, taps)

Analyzes and visualizes the vector group configuration of a transformer by simulating a power flow
using a base OpenDSS file and plotting the resulting voltage phasors.

# Arguments
- `prim_conn`: String representing the primary connection type (e.g., "Delta", "Wye").
- `sec_conn`: String representing the secondary connection type (e.g., "Delta", "Wye").
- `prim_perm`: Vector or Tuple of integers defining the node permutation for the primary side (e.g., `[1, 2, 3]`).
- `sec_perm`: Vector or Tuple of integers defining the node permutation for the secondary side.
- `lead_lag`: String or value defining the transformer's lead/lag setting/convention.
- `taps`: Vector of floats defining the per-unit tap settings for primary and secondary windings (e.g., `[1.0, 1.0]`).

# Details
The function performs the following steps:
1.  Reads a template DSS file (`trans_3ph_2w_dy_en.dss`).
2.  Modifies connection properties, bus definitions, and permutations based on input arguments.
3.  Writes a temporary DSS file (`temp_vec_group_sim.dss`).
4.  Solves the multi-conductor Optimal Power Flow (MC-OPF) using `PowerModelsDistribution` and `Ipopt`.
5.  Extracts voltage phasors for both sides of the transformer.
6.  Generates a polar plot using Makie to visualize the phase displacement.
7.  Computes and displays the angular shift (Phase A) and the approximate vector group "Clock Number".

# Returns
- A Makie `Figure` object containing the polar plot and vector group analysis text.
"""
function analyze_vector_group(prim_conn, sec_conn, prim_perm, sec_perm, lead_lag, taps)
    base_dss = read("trans_3ph_2w_dy_en.dss", String)

    # 1. Construct Buses Strings based on Permutations
    # Primary (HV)
    b1_nodes = join(prim_perm, ".")
    bus1_str = "b1.$b1_nodes" # e.g., b1.1.2.3

    # Secondary (LV)
    b2_nodes = join(sec_perm, ".")
    # Note: If Wye, we typically need the neutral node (4) for the 3-phase bank in PMD/DSS if we want to ground it.
    # The original file has grounding on b2.4.
    if sec_conn == "Wye"
        bus2_str = "b2.$b2_nodes.4"
    else
        bus2_str = "b2.$b2_nodes"
    end

    # 2. Modify DSS Parameters
    conns_str = "Conns=[$prim_conn $sec_conn]"
    buses_str = "Buses=[$bus1_str $bus2_str]"
    leadlag_str = "leadlag=$lead_lag"
    taps_str = "taps=[$(taps[1]) $(taps[2])]"

    # Create valid DSS content by replacing lines
    # We use regex to be robust against spacing
    new_dss = replace(base_dss, r"New Transformer\.TX1.*" => "New Transformer.TX1 phases=3 $buses_str")
    new_dss = replace(new_dss, r"~ Conns=.*" => "~ $conns_str")
    new_dss = replace(new_dss, r"~ leadlag=.*" => "~ $leadlag_str")
    new_dss = replace(new_dss, r"~ taps=.*" => "~ $taps_str")
     if sec_conn == "Wye"
     new_dss = replace(new_dss, r"New Reactor\.Grounding.*" => "New Reactor.Grounding phases=1 bus1=b2.4 bus2=b2.0 R=0 X=1E-6 // Grounding reactor for wye neutral")
    else
     new_dss = replace(new_dss, r"New Reactor\.Grounding.*" => "// NO GROUNDING FOR DELTA SECONDARY // New Reactor.Grounding phases=1 bus1=b2.4 bus2=b2.0 R=0 X=1E-6 // Grounding reactor for wye neutral")
    end

    temp_path = "temp_vec_group_sim.dss"
    write(temp_path, new_dss)

    # 3. Solve Power Flow
    # We use remove_all_bounds! to ensure valid solution even with shifts
    eng = parse_file(temp_path, transformations=[transform_loops!, remove_all_bounds!])
    # Keep explicit neutral (kron_reduce=false) to see true phasors
    math = transform_data_model(eng, kron_reduce=false, phase_project=false)

        
    for (b, bus) in math["bus"]
        if 5 in bus["terminals"] 
            display("Bus $b is grounded on neutral.")
            bus["grounded"][4] = true
        end
    end

    add_start_vrvi!(math)
    ipopt_solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)
    pf = solve_mc_opf(math, IVRENPowerModel, ipopt_solver)
    max_viol = 0.0
    if haskey(pf["solution"], "dss_violations")
        max_viol = maximum(values(pf["solution"]["dss_violations"]))
    end

    # 4. Extract Results
    v_1 = pf["solution"]["bus"]["1"]["vr"] + 1im * pf["solution"]["bus"]["1"]["vi"]
    v_2 = pf["solution"]["bus"]["2"]["vr"] + 1im * pf["solution"]["bus"]["2"]["vi"]

    # 5. Plotting
    fig = Figure(size=(800, 400))
    ax = PolarAxis(fig[1, 1], title="Interactive Vector Group Phasors", rlimits=(0, 1.1), direction=-1, theta_0=-pi / 2)

    colors_pri = [:red, :green, :blue]
    colors_sec = [:salmon1, :springgreen2, :lightskyblue]
    labels_pri = ["A (HV)", "B (HV)", "C (HV)"]
    labels_sec = ["a (LV)", "b (LV)", "c (LV)"]

    # Plot HV
    for i in 1:3
        # arrows! inputs: origin_x, origin_y, u, v (Cartesian) OR use lines for polar
        # Makie PolarAxis is tricky with arrows, we use arrows2d! (projected) or direct plot
        # Simplest: Just plot lines from center
        theta = angle(v_1[i])
        r = abs(v_1[i])
        lines!(ax, [0, theta], [0, r], color=colors_pri[i], linewidth=2, label=i == 1 ? "HV (Primary)" : nothing)
        scatter!(ax, [theta], [r], color=colors_pri[i], markersize=10)
    end

    # Plot LV
    for i in 1:3
        theta = angle(v_2[i])
        r = abs(v_2[i])
        lines!(ax, [0, theta], [0, r], color=colors_sec[i], linewidth=2, linestyle=:dash, label=i == 1 ? "LV (Secondary)" : nothing)
        scatter!(ax, [theta], [r], color=colors_sec[i], markersize=10)
    end


    elements = []
    labels = []

    for i in 1:3
        push!(elements, LineElement(color=colors_pri[i], linewidth=2))
        push!(labels, labels_pri[i])
    end

    for i in 1:3
        push!(elements, LineElement(color=colors_sec[i], linewidth=2, linestyle=:dash))
        push!(labels, labels_sec[i])
    end


    Legend(fig[1, 2],
        elements,
        labels,
        patchsize=(35, 35), rowgap=10)


    # Calculate Shift (Phase A)
    ang_pri_a = rad2deg(angle(v_1[1]))
    ang_sec_a = rad2deg(angle(v_2[1]))


    shift = ang_sec_a - ang_pri_a
    # Normalize shift to -180 to 180
    if shift > 180
        shift -= 360
    end
    if shift < -180
        shift += 360
    end


    conn_letter = Dict("Delta" => "D", "Wye" => "Y")
    # Print Info
    # Use a hidden text block or display
    text = "Shift (LV - HV): $(round(shift, digits=0))°\n  Clock Notation: $(uppercase(conn_letter[prim_conn]))$(lowercase(conn_letter[sec_conn])) $(Int(round(shift != 0 ? (shift < 0 ? (360+shift)/30 : shift/30) : 0))) "

    # We display the text below the plot
    Label(fig[2, 1:2], text, fontsize=20, halign=:center, tellwidth=false)

    display(fig)
    return fig
end