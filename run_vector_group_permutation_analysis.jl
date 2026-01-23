using PowerModelsDistribution
using OpenDSSDirect
using Printf

# --- 1. Define Permutations ---
# We want to explore all physical connections of phases A,B,C to terminals 1,2,3.
# Represented as permutations of indices [1, 2, 3].
perms = [
    [1, 2, 3],
    [1, 3, 2],
    [2, 1, 3],
    [2, 3, 1],
    [3, 1, 2],
    [3, 2, 1]
]

# Helper to convert permutation to node string
function perm_to_str(p)
    return join(p, ".")
end

# Identify permutation type (Identity, Cyclic+120, Cyclic-120, Odd/Swap)
function identify_perm_type(p)
    if p == [1, 2, 3]; return "Identity (abc)"
    elseif p == [2, 3, 1]; return "Cyclic -120 (bca)"
    elseif p == [3, 1, 2]; return "Cyclic +120 (cab)"
    else; return "Swap/Negative Seq"
    end
end

println("--- Transformer Vector Group Permutation Analysis ---")
println("Analyzing configuration with variable Conns [Delta/Wye] and Lead/Lag")

# --- 2. Iterate through permutations ---

results = []
lead_lag_opts = ["Lead", "Lag"]
conn_opts = [("Delta", "Wye"), ("Wye", "Wye"), ("Wye", "Delta"), ("Delta", "Delta")]

# Assuming Primary is X1, Secondary is X2
# Base DSS string template
# We use the OpenDSSDirect 'dss' function to re-compile the circuit with changed connections

for lead_lag in lead_lag_opts
    for (conn_pri, conn_sec) in conn_opts
        for p_pri in perms
            for p_sec in perms
                
                # Formulate Bus Strings based on Connection Type
                # Wye uses 4 nodes (with neutral), Delta uses 3 nodes
                
                bus1_base = "X1." * perm_to_str(p_pri)
                bus1_str = (conn_pri == "Wye") ? bus1_base * ".4" : bus1_base
                
                bus2_base = "X2." * perm_to_str(p_sec)
                bus2_str = (conn_sec == "Wye") ? bus2_base * ".4" : bus2_base
                
                # Run DSS Simulation
                dss("Clear")
                dss("New Circuit.Test phases=3 basekv=11 baseMVA=0.2 bus1=B1 MVASC1=1e8 MVASC3=1e8")
                # Define Linecode (simplified from original for speed/conciseness if needed, or re-use)
                dss("New Linecode.Zabcn units=km nphases=4 rmatrix=(0.227217624 0.059217624 0.059217624 0.059217624 |0.059217624 0.227217624 0.059217624 0.059217624 |0.059217624 0.059217624 0.227217624 0.059217624 |0.059217624 0.059217624 0.059217624 0.227217624) xmatrix=(0.879326005 0.541069709 0.475545802 0.449141163 |0.541069709 0.879326005 0.516533439 0.475545802 |0.475545802 0.516533439 0.879326005 0.541069709 |0.449141163 0.475545802 0.541069709 0.879326005) cmatrix=(0 | 0 0 | 0 0 0 | 0 0 0 0) Rg=0 Xg=0")
                
                # Source Line (Line1 connects B1.1.2.3.0 to X1.1.2.3.4)
                dss("New Line.Line1 bus1=B1.1.2.3.0 bus2=X1.1.2.3.4 linecode=Zabcn length=30 units=km")
                
                # --- THE TRANSFORMER ---
                # Using the permutations and connections
                dss("New Transformer.Transformer1 windings=2 phases=3 Buses=[$bus1_str $bus2_str] Conns=[$conn_pri $conn_sec] kVs=[11 0.4] kVAs=[500 500] %Rs=[1 2] xhl=5 %noloadloss=5 %imag=11 leadlag=$lead_lag taps=[1.0 0.95]")
                
                # Grounding & Load (To ensure calculation convergence)
                # Note: Grounding at X2.4 is valid even if X2 is Delta (just grounds the unused node 4 at that bus)
                dss("New Reactor.Grounding phases=1 bus1=X2.4 bus2=X2.0 R=0 X=1E-6")
                dss("New Line.Line2 bus1=X2.1.2.3.4 bus2=B2.1.2.3.4 linecode=Zabcn length=0.5 units=km")
                dss("New Load.Load1 phases=1 bus1=B2.1.4 kv=0.23 model=1 conn=wye kVA=10 pf=0.9 vminpu=0.1 vmaxpu=2")
                
                dss("Set voltagebases=[11 0.4]")
                dss("Calcvoltagebases")
                dss("Solve")
                
                if Solution.Converged()
                    # Calculate Voltages to determine Clock Number
                    
                    # Get Primary Voltage Phasor (Phase A/1)
                    Circuit.SetActiveBus("X1")
                    v_pri_complex = Bus.Voltages() 
                    va_pri = v_pri_complex[1] + 1im*v_pri_complex[2]
                    ang_pri = angle(va_pri) * 180/pi
                    
                    # Get Secondary Voltage Phasor (Phase a/1)
                    Circuit.SetActiveBus("X2")
                    v_sec_complex = Bus.Voltages()
                    va_sec = v_sec_complex[1] + 1im*v_sec_complex[2]
                    ang_sec = angle(va_sec) * 180/pi
                    
                    # Calculate Shift
                    # Clock number = (Pri - Sec) / 30
                    diff = ang_pri - ang_sec
                    
                    # Normalize to 0-360
                    while diff < 0; diff += 360; end
                    while diff >= 360; diff -= 360; end
                    
                    clock_float = diff / 30.0
                    clock_int = round(Int, clock_float)
                    
                    push!(results, (lead_lag, conn_pri, conn_sec, p_pri, p_sec, clock_int, diff))
                else
                    push!(results, (lead_lag, conn_pri, conn_sec, p_pri, p_sec, "Failed", "Failed"))
                end
            end
        end
    end
end

# --- 3. Display Results ---

println("\nMapping Permutations to Vector Groups (Clock Numbers)")
println("LL   | Conns     | Pri      | Sec      | Shift deg     | Clock | Note")
println("-----|-----------|----------|----------|---------------|-------|---------------")

for (ll, c1, c2, p_pri, p_sec, clock, diff) in results
    p1_s = perm_to_str(p_pri)
    p2_s = perm_to_str(p_sec)
    conn_s = c1[1:1] * c2[1:1] # Dy, Yy, Yd, Dd
    
    # Filter for standard Cyclic permutations to show standard groups first
    is_std_pri = p_pri in [[1,2,3], [2,3,1], [3,1,2]]
    is_std_sec = p_sec in [[1,2,3], [2,3,1], [3,1,2]]
    
    note = ""
    if !is_std_pri || !is_std_sec
        note = "(Swap)"
    end
    
    # Make the table pretty
    @printf("%-4s | %-9s | %-8s | %-8s | %5.1f deg     | %2d    | %s\n", ll, "$c1-$c2", p1_s, p2_s, diff, clock, note)
end
