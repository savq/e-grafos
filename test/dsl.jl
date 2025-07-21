module TestDSL

using Test
using Egraphs: Egraph, Enode, add!, find!
using Egraphs.DSL: @add, @rule
using Egraphs.Rewriting: RewriteRule, rewrite!

@testset "DSL / variable symbols" begin
    eg = Egraph()
    a1 = add!(eg, Enode(:a))
    a2 = @add eg a

    @test find!(eg, a1) == find!(eg, a2)
end

@testset "DSL / function symbols" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    f1 = add!(eg, Enode(:f, [a]))
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
