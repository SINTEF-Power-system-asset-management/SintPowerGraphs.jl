import PowerModels

function RadialPowerGraph(case_file::String)
    mpc = PowerModels.parse_file(case_file::String)
    G, ref_bus = convert_case(mpc)
    radial = directed_from_feeder(G, ref_bus)
    RadialPowerGraph(G, mpc, ref_bus, radial)
end

function PowerGraph(case_file::String)
    mpc = PowerModels.parse_file(case_file::String)
    G, ref_bus = convert_case(mpc)
    PowerGraph(G, mpc, ref_bus)
end

