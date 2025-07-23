module TestExamples

using Test
using Egraphs: Egraph, RewriteRule, VarTerm
using Egraphs: find!, rewrite!, eqsaturate!, extract
using Egraphs: @add, @rule

@testset "Group theory" begin
    theory = [
        # associativity
        @rule((x * y) * z --> x * (y * z)),
        @rule(x * (y * z) --> (x * y) * z),

        # identity
        @rule(x * :e --> x),
        @rule(:e * x --> x),

        # inverses
        @rule(x * inv(x) --> :e),
        @rule(inv(x) * x --> :e),
        @rule(inv(inv(x)) --> x),

        # commutativity
        @rule(x * y --> y * x),
    ]

    eg = Egraph()
    term = @add(eg, (a * b) * inv(a))

    eqsaturate!(eg, term, theory)
    # @test extract(eg, term)[2] == :b

    rewrite!(eg, term, theory[3])
    @test find!(eg, term) == find!(eg, @add eg b)
end

@testset "Symbolic differentiation" begin
    theory = [
        @rule(Dx(:x) --> 1)
        @rule(Dx(y) --> 0)

        @rule(Dx(u + v) --> Dx(v + u))
        @rule(Dx(u * v) --> u*Dx(v) + v*Dx(u))

        @rule(u + v --> v + u)
        @rule(u * 1 --> u)
        @rule(u + u --> 2 * u)
    ]

    eg = Egraph()
    term = @add(eg, Dx(:x * :x))

    eqsaturate!(eg, term, theory)
    # @test extract(eg, term)[2] == :(2 * :x)

    @test find!(eg, term) == find!(eg, @add eg (2 * :x))
end

end # module TestExamples
