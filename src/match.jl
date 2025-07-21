struct Pattern
    head::Symbol
    args::Vector{Pattern}
end

Pattern(head) = Pattern(head, [])

function search(eg::Egraph, id::EclassId, pat::Pattern)
    found = false
    nodes = eg.eclass_map[id].nodes
    for node in nodes
        found |= search(eg, node, pat)
    end
    return found
end

function search(eg::Egraph, node::Enode, pat::Pattern)
    found = false
    if node.head == pat.head
        # Try match
        found = match(eg, node, pat)
    end

    # Look for match in child e-classes
    for child in node.args
        found |= search(eg, child, pat)
    end
    return found
end

function match(eg::Egraph, id::EclassId, pat::Pattern)
    matched = false
    nodes = eg.eclass_map[id].nodes
    for node in nodes
        matched |= match(eg, node, pat)
    end
    return matched
end

function match(eg::Egraph, node::Enode, pat::Pattern)
    len = length(pat.args)
    if len == 0
        # Pattern variable
        @info "Found match" pat.head => node
        return true
    elseif node.head == pat.head && len == length(node.args)
        # Pattern expr
        for (child, sub_pat) in zip(node.args, pat.args)
            if match(eg, child, sub_pat)
                continue
            else
                return false
            end
        end
        @info "Found match" pat.head => node
        return true
    else
        return false
    end
end
