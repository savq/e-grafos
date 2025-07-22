pattern_from_expr(n::Int) = ConstPattern(n)
pattern_from_expr(qn::QuoteNode) = ConstPattern(qn.value)
pattern_from_expr(sym::Symbol) = VarPattern(sym)

function pattern_from_expr(expr::Expr)
    if expr.head === :call
        return FuncPattern(expr.args[1], pattern_from_expr.(expr.args[2:end]))
    else
        ArgumentError("expr must be call, symbol or integer: ", expr)
    end
end

function rewrite_rule_from_expr(expr::Expr)
    if expr.head == :(-->)
        lhs, rhs = expr.args
        return RewriteRule(pattern_from_expr(lhs), pattern_from_expr(rhs))
    else
        ArgumentError("expr must be an Expr of the form `lhs --> rhs`")
    end
end

macro rule(expr::Expr)
    :(rewrite_rule_from_expr($(QuoteNode(expr))))
end

enode_from_expr(eg::Egraph, n::Int) = add!(eg, ConstTerm(n))
enode_from_expr(eg::Egraph, qn::QuoteNode) = add!(eg, ConstTerm(qn.value))
enode_from_expr(eg::Egraph, sym::Symbol) = add!(eg, VarTerm(sym))

function enode_from_expr(eg::Egraph, expr::Expr)
    if expr.head === :call
        return add!(eg, FuncTerm(expr.args[1], enode_from_expr.(eg, expr.args[2:end])))
    else
        ArgumentError("Expr must be call, symbol or integer: ", expr)
    end
end

macro add(eg::Symbol, expr)
    :(enode_from_expr($(esc(eg)), $(QuoteNode(expr))))
end
