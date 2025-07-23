abstract type Pattern end

struct ConstPattern <: Pattern
    val::Union{Symbol, Int}
end

struct VarPattern <: Pattern
    head::Symbol
end

struct FuncPattern <: Pattern
    head::Symbol
    args::Vector{Pattern}
end

Base.show(io::IO, node::ConstPattern) = print(io, "⟦:", node.val, "⟧")
Base.show(io::IO, node::VarPattern) = print(io, "⟦", node.head, "⟧")
Base.show(io::IO, node::FuncPattern) = print(io, "⟦", node.head, (" " * join(node.args, " ")), "⟧")

const Substitution = Dict{VarPattern, Enode}


# Return a channel that yields valid substitutions
function search(eg::Egraph, id::EclassId, pat::Pattern, visited=[])
    Channel() do c
        if id in visited
            return
        else
            push!(visited, id)
            nodes = eg.eclass_map[id].nodes
            for node in nodes
                for subst in search(eg, node, pat, visited)
                    put!(c, subst)
                end
            end
        end
    end
end

function search(eg::Egraph, node::Enode, pat::Pattern, _visited=[])
    Channel() do c
        for subst in match(eg, node, pat, Substitution())
            put!(c, subst)
        end
    end
end

function search(eg::Egraph, node::FuncTerm, pat::Pattern, visited=[])
    Channel() do c
        for subst in match(eg, node, pat, Substitution())
            put!(c, subst)
        end

        # Look for match in child e-classes
        for child in node.args
            for subst in search(eg, child, pat, visited)
                put!(c, subst)
            end
        end
    end
end

# Una e-clase coincide si alguno de sus nodos coincide
function match(eg::Egraph, id::EclassId, pat::Pattern, subst::Substitution)
    Channel() do c
        nodes = eg.eclass_map[id].nodes
        for node in nodes
            for subst in match(eg, node, pat, subst)
                put!(c, subst)
            end
        end
    end
end

# Por defecto, no hay match.
function match(eg::Egraph, id::Enode, pat::Pattern, subst::Substitution)
    return Channel(identity)
end

# Los patrones variables hacen match incondicionalmente.
function match(eg::Egraph, node::Enode, var_pat::VarPattern, subst::Substitution)
    Channel() do c
        if haskey(subst, var_pat)
            if subst[var_pat] == node
                put!(c, subst)
            end
        else
            new_subst = copy(subst)
            new_subst[var_pat] = node
            put!(c, new_subst)
        end
    end
end

# Las funciones hacen match si sus cabezas coinciden y _todos_ sus argumentos coinciden.
function match(eg::Egraph, node::FuncTerm, pat::FuncPattern, subst::Substitution)
    Channel() do c
        if node.head == pat.head && length(pat.args) == length(node.args)
            for new_subst in match_list(eg, node.args, pat.args, subst)
                put!(c, new_subst)
            end
        end
    end
end

# Las constantes hacen match si sus valores son iguales.
function match(eg::Egraph, node::ConstTerm, pat::ConstPattern, subst::Substitution)
    Channel() do c
        if node.val == pat.val
            put!(c, subst)
        end
    end
end

function match_list(eg::Egraph, ids::Vector{EclassId}, patterns::Vector{Pattern}, subst::Substitution)
    Channel() do c
        if length(patterns) == 0
            put!(c, subst)
        else
            for subst1 in match(eg, ids[1], patterns[1], subst)
                for subst2 in match_list(eg, ids[2:end], patterns[2:end], subst1)
                    put!(c, subst2)
                end
            end
        end
    end
end
