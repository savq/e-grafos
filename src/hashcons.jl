# Esta definición no se está usando.
# hashcons es suficientemente simple para usarse directamente.

struct HashCons{K, V}
    table::Dict{K, V}
end

function Base.get!(h::HashCons{K, V}, val::V) where {K, V}
    key = hash(val)
    Base.get!(h.table, key, val)
end
