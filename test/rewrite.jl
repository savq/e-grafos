module TestRewriting

using Test
using Egraphs: Egraph, Enode, add!, merge!, find!
using Egraphs.Ematching: Pattern, Substitution, search
using Egraphs.Rewriting: RewriteRule, rewrite!, equality_saturation

@testset "rewrite / identity" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    id = add!(eg, Enode(:id, [a]))
    id2 = add!(eg, Enode(:id, [id]))

    rr = RewriteRule(
        Pattern(:id, [Pattern(:x)]),
        Pattern(:x)
    )

    rewrite!(eg, id2, rr)
    @test find!(eg, id2) == find!(eg, id) == find!(eg, a)
end

@testset "rewrite / symmetry" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    b = add!(eg, Enode(:b))
    d = add!(eg, Enode(:d, [a, b]))

    rr = RewriteRule(
        Pattern(:d, [Pattern(:x), Pattern(:y)]),
        Pattern(:d, [Pattern(:y), Pattern(:x)]),
    )

    rewrite!(eg, d, rr)
    @test find!(eg, d) == find!(eg, add!(eg, Enode(:d, [b, a])))
end

@testset "rewrite / check saturation" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    id = add!(eg, Enode(:id, [a]))

    rr = RewriteRule(
        Pattern(:id, [Pattern(:x)]),
        Pattern(:x)
    )

    saturated = rewrite!(eg, id, rr)
    @test !saturated

    saturated = rewrite!(eg, id, rr)
    @test saturated
end

@testset "equality saturation" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    id = add!(eg, Enode(:id, [a]))
    id2 = add!(eg, Enode(:id, [id]))

    rr = RewriteRule(
        Pattern(:id, [Pattern(:x)]),
        Pattern(:x)
    )

    result = equality_saturation(eg, id2, [rr])
    @test result == :a
end

end # module TestRewriting
