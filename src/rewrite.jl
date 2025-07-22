module Rewriting

using ..EgraphsCore: Egraph, EclassId, ConstTerm, VarTerm, FuncTerm
using ..EgraphsCore: add!, merge!, find!, rebuild!
using ..Ematching: Pattern, ConstPattern, VarPattern, FuncPattern
using ..Ematching: search

struct RewriteRule
    lhs::Pattern
    rhs::Pattern
end


function instantiate(eg::Egraph, pat::ConstPattern, subst)
    add!(eg, ConstTerm(pat.val))
end

function instantiate(eg::Egraph, pat::VarPattern, subst)
    add!(eg, subst[pat])
end

function instantiate(eg::Egraph, pat::FuncPattern, subst)
    add!(eg, FuncTerm(pat.head, [instantiate(eg, sub_pat, subst) for sub_pat in pat.args]))
end

# Given a rewrite rule, find instances of LHS, instantiate and merge
function rewrite!(eg::Egraph, id::EclassId, rule::RewriteRule)
    matches = []
    # @info "begin read phase"
    for subst in search(eg, id, rule.lhs)
        push!(matches, (rule, subst))
    end

    # @info "begin write phase"
    did_merge = false
    for (rule, subst) in matches
        l = instantiate(eg, rule.lhs, subst)
        r = instantiate(eg, rule.rhs, subst)
        did_merge |= find!(eg, l) != find!(eg, r)
        merge!(eg, l, r)
    end

    did_rebuild = !isempty(eg.worklist)
    rebuild!(eg)

    saturated = !(did_merge || did_rebuild)
    return saturated
end


# El costo de constantes y variables es 1
function extract(eg::Egraph, node::VarTerm)
    return (1, node.head)
end

function extract(eg::Egraph, node::ConstTerm)
    if node.val isa Symbol
        return (1, QuoteNode(node.val))
    else
        return (1, node.val)
    end
end

# El costo de una función es 1 + el costo de sus argumentos
function extract(eg::Egraph, node::FuncTerm)
    cost = 1
    expr = []
    for (c, sub_expr) in extract.(eg, node.args)
        cost += c
        push!(expr, sub_expr)
    end
    return cost, Expr(:call, node.head, expr...)
end

# Return the e-node with the lowest cost in e-class
function extract(eg::Egraph, id::EclassId)
    nodes = eg.eclass_map[id].nodes
    local optimal_cost = Inf
    local optimal_expr
    for node in nodes
        (cost, expr) = extract(eg, node)
        if cost < optimal_cost
            optimal_cost, optimal_expr = cost, expr
        end
    end
    return optimal_cost, optimal_expr
end

function equality_saturation(eg::Egraph, id::EclassId, rewrites::Vector{RewriteRule}; timeout=100)
    saturated = false
    while !saturated && timeout > 0
        for rule in rewrites
            saturated = rewrite!(eg, id, rule)
        end
        timeout -= 1
    end

    cost, expr = extract(eg, id)
    return expr
end

end # module Rewriting
