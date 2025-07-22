module TestRewriting

using Test
using Egraphs: Egraph, ConstTerm, VarTerm, FuncTerm, ConstPattern, VarPattern, FuncPattern, Substitution, RewriteRule
using Egraphs: add!, merge!, find!, search, rewrite!, eqsaturate!

@testset "rewrite / identity" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    id = add!(eg, FuncTerm(:id, [a]))
    id2 = add!(eg, FuncTerm(:id, [id]))

    rr = RewriteRule(
        FuncPattern(:id, [VarPattern(:x)]),
        VarPattern(:x)
    )

    rewrite!(eg, id2, rr)
    @test find!(eg, id2) == find!(eg, id) == find!(eg, a)
end

@testset "rewrite / symmetry" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    b = add!(eg, VarTerm(:b))
    d = add!(eg, FuncTerm(:d, [a, b]))

    rr = RewriteRule(
        FuncPattern(:d, [VarPattern(:x), VarPattern(:y)]),
        FuncPattern(:d, [VarPattern(:y), VarPattern(:x)]),
    )

    rewrite!(eg, d, rr)
    @test find!(eg, d) == find!(eg, add!(eg, FuncTerm(:d, [b, a])))
end

@testset "rewrite / zero" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    z = add!(eg, ConstTerm(0))
    sum = add!(eg, FuncTerm(:+, [a, z]))

    rr = RewriteRule(
        FuncPattern(:+, [VarPattern(:x), ConstPattern(0)]),
        VarPattern(:x),
    )

    rewrite!(eg, sum, rr)
    @test find!(eg, sum) == find!(eg, a)
end

@testset "rewrite / check saturation" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    id = add!(eg, FuncTerm(:id, [a]))

    rr = RewriteRule(
        FuncPattern(:id, [VarPattern(:x)]),
        VarPattern(:x)
    )

    saturated = rewrite!(eg, id, rr)
    @test !saturated

    saturated = rewrite!(eg, id, rr)
    @test saturated
end

@testset "equality saturation" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    id = add!(eg, FuncTerm(:id, [a]))
    id2 = add!(eg, FuncTerm(:id, [id]))

    rr = RewriteRule(
        FuncPattern(:id, [VarPattern(:x)]),
        VarPattern(:x)
    )

    result = eqsaturate!(eg, id2, [rr])
    @test result == :a
end

@testset "equality saturation / constants" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    zt = add!(eg, ConstTerm(0))
    sum = add!(eg, FuncTerm(:+, [a, zt]))
    sum2 = add!(eg, FuncTerm(:+, [sum, zt]))

    rr = RewriteRule(
        FuncPattern(:+, [VarPattern(:x), ConstPattern(0)]),
        VarPattern(:x)
    )

    result = eqsaturate!(eg, sum2, [rr])
    @test result == :a
end

end # module TestRewriting
