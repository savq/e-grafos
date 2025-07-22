module TestDSL

using Test
using Egraphs: Egraph, ConstTerm, VarTerm, FuncTerm
using Egraphs: add!, find!
using Egraphs.DSL: @add, @rule
using Egraphs.Rewriting: RewriteRule, rewrite!

@testset "DSL / constant symbols" begin
    eg = Egraph()
    e1 = add!(eg, ConstTerm(:e))
    e2 = @add eg :e

    @test find!(eg, e1) == find!(eg, e2)
end

@testset "DSL / variable symbols" begin
    eg = Egraph()
    a1 = add!(eg, VarTerm(:a))
    a2 = @add eg a

    @test find!(eg, a1) == find!(eg, a2)
end

@testset "DSL / function symbols" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    f1 = add!(eg, FuncTerm(:f, [a]))
    f2 = @add eg f(a)

    @test find!(eg, f1) == find!(eg, f2)
end

@testset "rewrite rules" begin
    eg = Egraph()
    a = @add eg a
    id2 = @add eg id(id(a))

    rr = @rule id(x) --> x
    rewrite!(eg, id2, rr)

    @test find!(eg, id2) == find!(eg, a)
end

end # module TestDSL
