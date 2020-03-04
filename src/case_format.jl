using DataFrames
using CSV
import Pkg.TOML

mutable struct Case
    baseMVA::Float64
    bus::DataFrame
    branch::DataFrame
    gen::DataFrame
    gencost::DataFrame
end

function Case()::Case
    baseMVA = 100
    bus = DataFrame()
    branch = DataFrame()
    gen = DataFrame()
    gencost = DataFrame()
    Case(baseMVA, bus, branch, gen, gencost)
end
    

function Case(fname::String)::Case
    conf = TOML.parsefile(fname)
    dir = splitdir(fname)[1]
    files = conf["files"]
    
    # Mandatory files/content in Case
    bus = CSV.File(joinpath(dir, files["bus"])) |> DataFrame
    branch = CSV.File(joinpath(dir, files["branch"])) |> DataFrame
    gen = CSV.File(joinpath(dir, files["gen"])) |> DataFrame
    
    # Optional files/content in Case
    if haskey(files, "gencost")
        gencost = CSV.File(joinpath(dir, files["gencost"])) |> DataFrame
    else
        gencost = DataFrame()
    end

    baseMVA = conf["configuration"]["baseMVA"]
    return Case(baseMVA, bus, branch, gen, gencost)
end

function push_bus!(mpc::Case, bus::DataFrameRow)
    push!(mpc.bus, bus)
end

function push_branch!(mpc::Case, branch::DataFrameRow)
    push!(mpc.branch, branch)
end
    
function push_gen!(mpc::Case, gen::DataFrameRow)
    push!(mpc.gen, gen)
end

function get_bus(mpc::Case, ID::Int)::DataFrameRow
    return mpc.bus[ID, :]
end

function get_bus!(mpc::Case, ID::Int)::DataFrameRow
    return mpc.bus[ID, !]
end

function get_gen(mpc::Case, bus_id::Int)::DataFrame
    return mpc.gen[mpc.gen.bus.==bus_id,:]
end

function get_gen!(mpc::Case, bus_id::Int)::DataFrame
    return mpc.gen[mpc.gen.bus.==bus_id, !]
end

function get_branch(mpc::Case, f_bus::Int, t_bus::Int)::DataFrame
    return mpc.branch[(mpc.branch.f_bus .== f_bus) .&
                      (mpc.branch.t_bus .== t_bus),:]
end

function get_branch(mpc::Case, id::Int)::DataFrameRow
    return mpc.branch[id,:]
end

function set_branch!(mpc::Case, f_bus::Int, t_bus::Int, data::DataFrame)
    mpc.branch[(mpc.branch.f_bus .== f_bus) .&
              (mpc.branch.t_bus .== t_bus), :] = data
end

function is_gen_bus(mpc::Case, bus_id::Int)::Bool
    return bus_id in mpc.gen.bus
end

function delete_branch!(mpc::Case, f_bus::Int, t_bus::Int)
    deleterows!(mpc.branch, (mpc.branch.f_bus .== f_bus) .&
               mpc.branch.t_bus .== t_bus)
end

function delete_bus!(mpc::Case, bus::Int)
    deleterows!(mpc.bus, bus)
end

"""
    get_susceptance_vector(network::PowerGraphBase)::Array{Float64}
    Returns the susceptance vector for performing a dc power flow.
"""
function get_susceptance_vector(case::Case)::Array{Float64, 1}
    return map(x-> 1/x, case.branch[:,:x])
end

function get_power_injection_vector(case::Case)::Array{Float64, 1}
    Pd = -case.bus[:, :Pd]
    Pg = zeros(length(Pd), 1) 
    for gen in eachrow(case.gen) 
        Pg[gen.bus] = gen.Pg
    end
    return Pg[:] + Pd
end

function get_line_lims_pu(case::Case)::Array{Float64}
    return case.branch.rateA/case.baseMVA
end
