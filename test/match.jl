module TestMatch

using Test
using Egraphs: Egraph, Enode
using Egraphs: add!, Pattern, Substitution, match, search

@testset "match patterns / unconditional" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    p = Pattern(:x)
    subst = Substitution()
    matched = match(eg, a, p, subst)
    @info "test: valid Substitution" subst
    @test subst == Dict(:x => Enode(:a))
    @test matched
end

@testset "match patterns / single var, single pattern var" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    f = add!(eg, Enode(:f, [a, a]))

    p = Pattern(:f, [Pattern(:x), Pattern(:x)])
    subst = Substitution()
    matched = match(eg, f, p, subst)
    @info "test: valid Substitution" subst
    @test matched
end

@testset "match patterns / single var, multiple pattern vars" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    f = add!(eg, Enode(:f, [a, a]))

    p = Pattern(:f, [Pattern(:x), Pattern(:y)])
    subst = Substitution()
    matched = match(eg, f, p, subst)
    @info "test: valid Substitution" subst
    @test matched
end

@testset "match patterns / multiple var, multiple pattern vars" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    b = add!(eg, Enode(:b))
    f = add!(eg, Enode(:f, [a, b]))

    p = Pattern(:f, [Pattern(:x), Pattern(:y)])
    subst = Substitution()
    matched = match(eg, f, p, subst)
    @info "test: valid Substitution" subst
    @test matched
end

@testset "search patterns" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    b = add!(eg, Enode(:b))
    f = add!(eg, Enode(:f, [a, a]))
    g = add!(eg, Enode(:g, [f, b]))

    p = Pattern(:f, [Pattern(:x), Pattern(:x)])
    matched = false
    for subst in search(eg, g, p)
        matched = true
        @info "test: valid Substitution" subst
    end
    @test matched
end

@testset "search patterns / multiple matches" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    b = add!(eg, Enode(:b))
    f = add!(eg, Enode(:f, [a, b]))

    p = Pattern(:x)
    matched = false
    for subst in search(eg, f, p)
        matched = true
        @info "test: valid Substitution" subst
    end
    @test matched
end

end
