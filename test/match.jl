module TestEmatching

using Test
using Egraphs: Egraph, Enode, add!
using Egraphs.Ematching: Pattern, Substitution, match, search

@testset "match patterns / unconditional" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))

    p = Pattern(:x)
    subst = first(match(eg, a, p, Substitution()))

    @test subst == Substitution(:x => Enode(:a))
end

@testset "match patterns / single var, single pattern var" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    f = add!(eg, Enode(:f, [a, a]))

    p = Pattern(:f, [Pattern(:x), Pattern(:x)])
    subst = first(match(eg, f, p, Substitution()))

    @test subst == Substitution(:x => Enode(:a))
end

@testset "match patterns / single var, multiple pattern vars" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    f = add!(eg, Enode(:f, [a, a]))

    p = Pattern(:f, [Pattern(:x), Pattern(:y)])
    subst = first(match(eg, f, p, Substitution()))

    @test subst == Substitution(:x => Enode(:a), :y => Enode(:a))
end


@testset "match patterns / multiple var, multiple pattern vars" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    b = add!(eg, Enode(:b))
    f = add!(eg, Enode(:f, [a, b]))

    p = Pattern(:f, [Pattern(:x), Pattern(:y)])
    subst = first(match(eg, f, p, Substitution()))

    @test subst == Substitution(:x => Enode(:a), :y => Enode(:b))
end

@testset "match patterns / multiple nodes per e-class" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    b = add!(eg, Enode(:b))
    f = add!(eg, Enode(:f, [a]))
    merge!(eg, a, b)

    p = Pattern(:f, [Pattern(:x)])
    substs = collect(match(eg, f, p, Substitution()))

    @test length(substs) == 2
    @test Substitution(:x => Enode(:a)) in substs
    @test Substitution(:x => Enode(:b)) in substs
end

@testset "search patterns" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    b = add!(eg, Enode(:b))
    f = add!(eg, Enode(:f, [a, a]))
    g = add!(eg, Enode(:g, [f, b]))

    p = Pattern(:f, [Pattern(:x), Pattern(:x)])
    substs = collect(search(eg, g, p))

    @test length(substs) == 1
    @test Substitution(:x => Enode(:a)) in substs
end

@testset "search patterns / multiple var matches" begin
    eg = Egraph()
    a = add!(eg, Enode(:a))
    b = add!(eg, Enode(:b))
    f = add!(eg, Enode(:f, [a, b]))

    p = Pattern(:x)
    substs = collect(search(eg, f, p))

    @test length(substs) == 3
    @test Substitution(:x =>  Enode(:f, [a, b])) in substs
    @test Substitution(:x => Enode(:a)) in substs
    @test Substitution(:x => Enode(:b)) in substs
end

end # module TestEmatching
