using DataFrames
using CSV
import TOML

mutable struct Case
    baseMVA::Float64
    bus::DataFrame
    branch::DataFrame
    gen::DataFrame
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
