function process_fasad_case(fname::String)
	return process_fasad_case(Fasad_Case(fname))
end

function process_fasad_case(mpc_temp::Fasad_Case)
    mpc = Case()
    f_process_lines(mpc, mpc_temp)
    f_process_switch(mpc, mpc_temp)
    f_process_transformers(mpc, mpc_temp)
    f_process_nodes(mpc, mpc_temp, mpc_temp.trans_node)
	
	# In case the slack bus is not defined in the bus data sheet
    nodes_entry = [mpc_temp.trans_node, 3, 0, 0, 0, 0, 0, 1, 0, 22, 0, 1.2, 0.9]
	if mpc_temp.trans_node ∉ mpc.bus.ID
		push!(mpc.bus, nodes_entry)
	end

    return mpc
end

function f_process_lines(mpc, mpc_temp)
    branches_columns = ["f_bus", "t_bus", "r", "x", "b", "rateA", "rateB", "rateC", "ratio", "shift", "br_status"] 
    reldata_columns = ["ID", "f_bus", "t_bus", "repairTime", "temporaryFaultFrequency", "permanentFaultFrequency", "sectioningTime", "temporaryFaultTime", "capacity"]
    mpc.branch = DataFrame([Symbol(col) => Any[] for col in branches_columns])
    mpc.reldata = DataFrame([Symbol(col) => Any[] for col in reldata_columns])
    for row in collect(eachrow(mpc_temp.lines))
		lines_entry = [row["from"], row["to"], 0, 0, 0, row["apparent_power_limit"], 0, 0, 0, 0, 1]
        reldata_entry = [size(mpc.branch)[1]+1, row["from"], row["to"], row["repair_time"]/60, row["failure_frequency_temporary"], row["failure_frequency_permanent"],0, 0.02, row["apparent_power_limit"]]
        push!(mpc.branch, lines_entry)
        push!(mpc.reldata, reldata_entry)
    end
end

function f_process_switch(mpc, mpc_temp)
    switches_columns = ["f_bus", "t_bus", "breaker", "closed"] 
    mpc.switch = DataFrame([Symbol(col) => Any[] for col in switches_columns])
    for row in collect(eachrow(mpc_temp.switchgear))
        switches_entry = [row["from"], row["to"], if row["switchgear_type"]=="breaker" "True" else "False" end, row["closed"]]
        lines_entry = [row["from"], row["to"], 0, 0, 0, 0, 0, 0, 0, 0, 1]
        reldata_entry = [size(mpc.branch)[1]+1, row["from"], row["to"], 0, 0, 0,row["switching_time"]/60, 0, 0]
        push!(mpc.switch, switches_entry)
        push!(mpc.branch, lines_entry)
        push!(mpc.reldata, reldata_entry)
    end
end

function f_process_transformers(mpc, mpc_temp)
    trafos_columns = ["ID", "f_bus", "t_bus", "rateA"] 
    mpc.transformer = DataFrame([Symbol(col) => Any[] for col in trafos_columns])
    for row in collect(eachrow(mpc_temp.transformers))
        if row["transformer_type"]=="secondary"
            trafos_entry = [row["name"], row["from"], row["to"], row["apparent_power_limit"]]
            push!(mpc.transformer, trafos_entry)
        else
            # I see that fasad does not explicitly declare the secondary bus of transformer as node, I add it manually
            push!(mpc_temp.nodes, [row["to"]])
        end
        lines_entry = [row["from"], row["to"], 0, 0, 0, 0, 0, 0, 0, 0, 1]
        reldata_entry = [size(mpc.branch)[1]+1, row["from"], row["to"], 0, 0, 0, 0, 0.02, row["apparent_power_limit"]]
        push!(mpc.branch, lines_entry)
        push!(mpc.reldata, reldata_entry)
    end
end

function f_process_nodes(mpc, mpc_temp, slack_bus)
    loads_columns = ["bus", "demand", "ref_demand"] 
    nodes_columns = ["ID", "type", "Pd", "Qd", "Gs", "Bs", "area_num", "Vm", "Va", "baseKV", "zone", "max_Vm", "min_Vm"]
    gen_columns = ["bus", "Pg", "Qg", "Qmax", "Qmin", "Vg", "mBase", "status", "Pmax", "Pmin"]
    mpc.loaddata = DataFrame([Symbol(col) => Any[] for col in loads_columns])
    mpc.bus = DataFrame([Symbol(col) => Any[] for col in nodes_columns])
    mpc.gen = DataFrame([Symbol(col) => Any[] for col in gen_columns])
    for row in collect(eachrow(mpc_temp.nodes))
        name = row["name"]
        nodes_entry = [name, 1, 0, 0, 0, 0, 0, 1, 0, 22, 0, 1.2, 0.9]
        if name in mpc_temp.delivery_points[!, "name"]
            df = mpc_temp.delivery_points[mpc_temp.delivery_points[!, "name"] .== name,["demand", "reference_demand"]]
            nodes_entry[3] = df[!, "demand"][1]
            load_entry = [name, df[!, "demand"][1], df[!, "reference_demand"][1]]
            push!(mpc.loaddata, load_entry)
        end
        if name==slack_bus 
            nodes_entry[2] = 3
            gen_entry = [name, 0, 0, 0, 0, 1, 0, 1, 0, 0]
            push!(mpc.gen, gen_entry)
        end
        push!(mpc.bus, nodes_entry)
    end
end
