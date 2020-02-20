using DataFrames
using CSV
import TOML

mutable struct Case
    baseMVA::Float64
    bus::DataFrame
    branch::DataFrame
    gen::DataFrame
end

function Case()::Case
    baseMVA = 100
    bus = DataFrame()
    branch = DataFrame()
    gen = DataFrame()
    Case(baseMVA, bus, branch, gen)
end
    

function Case(fname::String)::Case
    conf = TOML.parsefile(fname)
    dir = splitdir(fname)[1]
    files = conf["files"]
    bus = CSV.File(joinpath(dir, files["bus"])) |> DataFrame
    branch = CSV.File(joinpath(dir, files["branch"])) |> DataFrame
    gen = CSV.File(joinpath(dir, files["gen"])) |> DataFrame
    baseMVA = conf["configuration"]["baseMVA"]
    return Case(baseMVA, bus, branch, gen)
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
    return case.bus[:, :Pd]
end
