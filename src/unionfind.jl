struct UnionFind{T}
    parents::Dict{T, T}
    ranks::Dict{T, Int} # The number of direct children of a node
end

UnionFind{T}() where {T} = UnionFind{T}(Dict(), Dict())

function make_set!(u::UnionFind{T}, a::T) where {T}
    if haskey(u.parents, a)
        return a
    else
        u.parents[a] = a
        u.ranks[a] = 0
        return a
    end
end

function find!(u::UnionFind{T}, a::T) where {T}
    if haskey(u.parents, a)
        if u.parents[a] != a
            # Reduce rank of old parent
            u.ranks[u.parents[a]] -= 1
            # Update parent
            u.parents[a] = find!(u, u.parents[a])
            # Increase rank of new parent
            u.ranks[u.parents[a]] += 1
        end
        return u.parents[a]
    else
        throw(KeyError(a))
    end
end

function Base.union!(u::UnionFind{T}, a::T, b::T) where {T}
    root_a = find!(u, a)
    root_b = find!(u, b)

    if root_a != root_b
        if u.ranks[root_a] < u.ranks[root_b]
            u.parents[root_a] = root_b
            u.ranks[root_b] += 1
            return root_b
        else
            u.parents[root_b] = root_a
            u.ranks[root_a] += 1
            return root_a
        end
    else
        return root_a
    end
end
