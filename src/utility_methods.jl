"""Method to efficiently swap columns taken from the internet"""
function swapcols!(X::AbstractMatrix, i::Integer, j::Integer)
	@inbounds for k = 1:size(X,1)
		X[k,i], X[k,j] = X[k,j], X[k,i]
	end
end

"""Method to efficiently swap rows based on swapcols!"""
function swaprows!(X::AbstractMatrix, i::Integer, j::Integer)
	@inbounds for k = 1:size(X,2)
		X[i,k], X[j,k] = X[j,k], X[i,k]
	end
end


