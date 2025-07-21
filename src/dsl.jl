module DSL

using ..EgraphsCore: Egraph, Enode, add!
using ..Ematching: Pattern
using ..Rewriting: RewriteRule

function Pattern(sym::Symbol)
    return Pattern(sym, [])
end

function Pattern(expr::Expr)
    if expr.head === :call
        return Pattern(expr.args[1], Pattern.(expr.args[2:end]))
    else
        ArgumentError("expr must be call, symbol or integer: ", expr)
    end
end

function rewrite_rule_from_expr(expr::Expr)
    if expr.head == :(-->)
        lhs, rhs = expr.args
        return RewriteRule(Pattern(lhs), Pattern(rhs))
    else
        ArgumentError("expr must be an Expr of the form `lhs --> rhs`")
    end
end

macro rule(expr::Expr)
    :(rewrite_rule_from_expr($(QuoteNode(expr))))
end

function enode_from_expr(eg::Egraph, sym::Symbol)
    return add!(eg, Enode(sym, []))
end

function enode_from_expr(eg::Egraph, expr)
    if expr.head === :call
        return add!(eg, Enode(expr.args[1], enode_from_expr.(eg, expr.args[2:end])))
    else
        ArgumentError("Expr must be call, symbol or integer: ", expr)
    end
end

macro add(eg::Symbol, expr)
    :(enode_from_expr($(esc(eg)), $(QuoteNode(expr))))
end

end # module DSL
