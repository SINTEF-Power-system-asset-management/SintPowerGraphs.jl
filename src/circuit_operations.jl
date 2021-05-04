import Base.+
import Base.==

mutable struct π_segment
    Z::Number
    Y₁::Number
    Y₂::Number
end

function π_segment(branch::Dict{String, Any})
    Z = branch["br_r"] + branch["br_x"]im
    Y₁ = branch["g_fr"] + branch["b_fr"]im
    Y₂ = branch["g_to"] + branch["b_to"]im
    π_segment(Z, Y₁, Y₂)
end

function (+)(π₁::π_segment, π₂::π_segment)
    # Add the adjacent line susceptances
    Y₁₂ = π₁.Y₂ + π₂.Y₁

    # Do the Y-Δ transformation
    Z = π₁.Z + π₂.Z + π₁.Z*π₂.Z*Y₁₂
    # In case Z is zero just treat both impedances as short circuits
    if Z == 0
        Y₁ = Y₁₂
        Y₂ = Y₁₂
    else
        Y₁ = π₂.Z*Y₁₂/Z
        Y₂ = π₁.Z*Y₁₂/Z
    end

    π_segment(Z, π₁.Y₁+Y₁, π₂.Y₂+Y₂)
end

function (==)(π₁::π_segment, π₂::π_segment)::Bool
    return π₁.Z == π₂.Z && π₁.Y₁ == π₂.Y₁ && π₁.Y₂ == π₂.Y₂ 
end

function is_zero_impedance_line(π::π_segment)::Bool
    return 0.0 == π.Z
end

function series_impedance_norm(π::π_segment)::Float64
    return abs(π.Z)
end

function series_impedance_norm(branch::DataFrameRow)::Float64
	return series_impedance_norm(get_π_equivalent(branch))
end
