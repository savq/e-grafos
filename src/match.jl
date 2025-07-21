struct Pattern
    head::Symbol
    args::Vector{Pattern}
end

Pattern(head) = Pattern(head, [])

const Substitution = Dict{Symbol, Enode}


# Return a channel that yields valid substitutions
function search(eg::Egraph, id::EclassId, pat::Pattern)
    Channel() do c
        nodes = eg.eclass_map[id].nodes
        for node in nodes
            for subst in search(eg, node, pat)
                put!(c, subst)
            end
        end
    end
end

# Return a channel that yields valid substitutions
function search(eg::Egraph, node::Enode, pat::Pattern)
    Channel() do c
        for subst in match(eg, node, pat, Substitution())
            put!(c, subst)
        end

        # Look for match in child e-classes
        for child in node.args
            for subst in search(eg, child, pat)
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

# Un e-nodo coincide si su cabeza coincide y _todo_ de sus hijos coinciden
function match(eg::Egraph, node::Enode, pat::Pattern, subst::Substitution)
    Channel() do c
        len = length(pat.args)
        if len == 0
            var = pat.head
            if haskey(subst, var)
                if subst[var] == node
                    put!(c, subst)
                end
            else
                new_subst = copy(subst)
                new_subst[var] = node
                put!(c, new_subst)
            end
        elseif node.head == pat.head && len == length(node.args)
            for new_subst in match_list(eg, node.args, pat.args, subst)
                put!(c, new_subst)
            end
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
