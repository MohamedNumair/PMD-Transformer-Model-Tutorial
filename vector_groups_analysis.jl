using PowerModelsDistribution
using Ipopt
using Makie
using CairoMakie


FILE_PATH = "trans_2w_dy_en_VecG_tests.dss"
eng = parse_file(FILE_PATH, transformations=[transform_loops!, remove_all_bounds!]);





math= transform_data_model(eng, kron_reduce=false, phase_project=false);



add_start_vrvi!(math)
pf = solve_mc_opf(math, IVRENPowerModel, Ipopt.Optimizer)

v_1 = pf["solution"]["bus"]["1"]["vr"] + 1im*pf["solution"]["bus"]["1"]["vi"]
#display(abs.(v_1));
angles_primary = rad2deg.(angle.(v_1))

v_2 = pf["solution"]["bus"]["2"]["vr"] + 1im*pf["solution"]["bus"]["2"]["vi"];
#display(abs.(v_2))
angles_secondary = rad2deg.(angle.(v_2))
fig = Figure()
phasor_axis = PolarAxis(fig[1, 1], title = "Voltage Phasors", rlimits = (0, 1.1), 
    direction = -1, theta_0 = -pi/2)

# Helper to format data for polar arrows: base point (0,0) -> tip (angle, radius)
# Standard arrows! in PolarAxis usually expects (radius, angle) or projected coordinates depending on backend,
# but passing specific u,v components can be tricky.
# A robust way in Makie PolarAxis is simple lines or arrows where inputs are angle (radians) and radius.

# Primary side vectors (v_1)
# angles are already calculated in degrees via rad2deg above, but Makie PolarAxis expects radians for theta.

colors_primary = Dict(1=> :salmon1, 2=> :springgreen2, 3=>:lightskyblue, 4=>:black, 5=>:black)
colors_secondary = Dict(1=> :red, 2=> :green, 3=>:blue, 4=>:black, 5=>:black)

for (i, v) in enumerate(v_1[1:3])
    arrows2d!(phasor_axis, [0.0], [0.0], [angle(v)], [abs(v)], color = colors_primary[i], label = i==1 ? "Primary" : nothing)
end

# Secondary side vectors (v_2)
for (i, v) in enumerate(v_2[1:3])
    arrows2d!(phasor_axis, [0.0], [0.0], [angle(v)], [abs(v)], color = colors_secondary[i], label = i==1 ? "Secondary" : nothing)
end

display(fig)


printstyled("Primary Side a (Degrees): ", angles_primary[1], " | Secondary Side a (Degrees): ", angles_secondary[1], "\n")
printstyled("Primary Side b (Degrees): ", angles_primary[2], " | Secondary Side b (Degrees): ", angles_secondary[2], "\n")
printstyled("Primary Side c (Degrees): ", angles_primary[3], " | Secondary Side c (Degrees): ", angles_secondary[3], "\n")

using OpenDSSDirect
DSS = OpenDSSDirect


dss("""
    clear
""")

pwd()
dss("""
compile $FILE_PATH
""")
pwd()

Solution.Solve()

if Solution.Converged()
    println("Solution converged successfully.")
else
    error("Solution failed to converge.")
end

println("dss primary angles")

Circuit.SetActiveBus("X1")
v_mag_ang = Bus.VMagAngle()
v_dss_primary = [] 
for i in 1:Int(length(v_mag_ang) / 2)
    mag = v_mag_ang[2i-1]
    ang = v_mag_ang[2i]
    display(ang)
    push!(v_dss_primary, mag*cis(ang))
end


println("dss secondary angles")
Circuit.SetActiveBus("X2")
v_mag_ang = Bus.VMagAngle()
v_dss_secondary = [] 
for i in 1:Int(length(v_mag_ang) / 2)
    mag = v_mag_ang[2i-1]
    ang = v_mag_ang[2i]
    display(ang)
    push!(v_dss_secondary, mag*cis(ang))
end




display(" f_conn tr 1 : $(math["transformer"]["1"]["f_connections"])")
display(" f_conn tr 2 : $(math["transformer"]["2"]["f_connections"])")
# math["transformer"]["1"]["t_connections"]

# math["transformer"]["2"]["t_connections"]
# @show math["transformer"]["2"]["f_connections"]

