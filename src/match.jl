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
        subst = Substitution()
        if match(eg, node, pat, subst)
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

function match(eg::Egraph, id::EclassId, pat::Pattern, subst)
    matched = false
    nodes = eg.eclass_map[id].nodes
    for node in nodes
        matched |= match(eg, node, pat, subst)
    end
    return matched
end

function match(eg::Egraph, node::Enode, pat::Pattern, subst)
    len = length(pat.args)
    if len == 0
        # @info "Pattern variable"
        var = pat.head
        if haskey(subst, var)
            # variable is already in Substitution, check if compatible
            if subst[var] == node
                # @info "Found match" var => node
                return true
            else
                # @info "incompatible match" var => node
                return false
            end
        else
            subst[var] = node
            # @info "Found match" var => node
            return true
        end
    elseif node.head == pat.head && len == length(node.args)
        # @info "Pattern expression"
        for (child, sub_pat) in zip(node.args, pat.args)
            if match(eg, child, sub_pat, subst)
                continue
            else
                return false
            end
        end
        # @info "Found match" pat.head => node
        return true
    else
        return false
    end
end
