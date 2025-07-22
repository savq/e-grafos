module TestEmatching

using Test
using Egraphs: Egraph, ConstTerm, VarTerm, FuncTerm, ConstPattern, VarPattern, FuncPattern, Substitution
using Egraphs: add!, match, search

@testset "matching / unconditional" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))

    pat = VarPattern(:x)
    subst = first(match(eg, a, pat, Substitution()))

    @test subst == Substitution(VarPattern(:x) => VarTerm(:a))
end

@testset "matching / single var, single pattern var" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    f = add!(eg, FuncTerm(:f, [a, a]))

    x = VarPattern(:x)
    pat = FuncPattern(:f, [x, x])
    subst = first(match(eg, f, pat, Substitution()))

    @test subst == Substitution(x => VarTerm(:a))
end

@testset "matching / single var, multiple pattern vars" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    f = add!(eg, FuncTerm(:f, [a, a]))

    x = VarPattern(:x)
    y = VarPattern(:y)
    p = FuncPattern(:f, [x, y])
    subst = first(match(eg, f, p, Substitution()))

    @test subst == Substitution(x => VarTerm(:a), y => VarTerm(:a))
end


@testset "matching / multiple var, multiple pattern vars" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    b = add!(eg, VarTerm(:b))
    f = add!(eg, FuncTerm(:f, [a, b]))


    x = VarPattern(:x)
    y = VarPattern(:y)
    p = FuncPattern(:f, [x, y])
    subst = first(match(eg, f, p, Substitution()))

    @test subst == Substitution(x => VarTerm(:a), y => VarTerm(:b))
end

@testset "matching / multiple nodes per e-class" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    b = add!(eg, VarTerm(:b))
    f = add!(eg, FuncTerm(:f, [a]))
    merge!(eg, a, b)

    x = VarPattern(:x)
    pat = FuncPattern(:f, [x])
    substs = collect(match(eg, f, pat, Substitution()))

    @test length(substs) == 2
    @test Substitution(x => VarTerm(:a)) in substs
    @test Substitution(x => VarTerm(:b)) in substs
end

@testset "search" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    b = add!(eg, VarTerm(:b))
    f = add!(eg, FuncTerm(:f, [a, a]))
    g = add!(eg, FuncTerm(:g, [f, b]))

    x = VarPattern(:x)
    p = FuncPattern(:f, [x, x])
    substs = collect(search(eg, g, p))

    @test length(substs) == 1
    @test Substitution(x => VarTerm(:a)) in substs
end

@testset "search / multiple var matches" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    b = add!(eg, VarTerm(:b))
    f = add!(eg, FuncTerm(:f, [a, b]))

    x = VarPattern(:x)
    substs = collect(search(eg, f, x))

    @test length(substs) == 3
    @test Substitution(VarPattern(:x) => FuncTerm(:f, [a, b])) in substs
    @test Substitution(VarPattern(:x) => VarTerm(:a)) in substs
    @test Substitution(VarPattern(:x) => VarTerm(:b)) in substs
end

@testset "search / multiple var matches" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    b = add!(eg, VarTerm(:b))
    f = add!(eg, FuncTerm(:f, [a, b]))

    x = VarPattern(:x)
    substs = collect(search(eg, f, x))

    @test length(substs) == 3
    @test Substitution(VarPattern(:x) => FuncTerm(:f, [a, b])) in substs
    @test Substitution(VarPattern(:x) => VarTerm(:a)) in substs
    @test Substitution(VarPattern(:x) => VarTerm(:b)) in substs
end

@testset "matching / constant term - variable pattern" begin
    eg = Egraph()
    a = add!(eg, ConstTerm(:a))

    x = VarPattern(:x)
    substs = collect(match(eg, a, x, Substitution()))

    @test Substitution(VarPattern(:x) => ConstTerm(:a)) in substs
end

@testset "matching / constant term - constant pattern" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    zt = add!(eg, ConstTerm(0))
    sum = add!(eg, FuncTerm(:+, [a, zt]))

    x = VarPattern(:x)
    zp = ConstPattern(0)
    pat = FuncPattern(:+, [x, zp])
    substs = collect(match(eg, sum, pat, Substitution()))

    @test Substitution(VarPattern(:x) => VarTerm(:a)) in substs
end

@testset "matching / constant term - constant pattern" begin
    eg = Egraph()
    a = add!(eg, VarTerm(:a))
    zt = add!(eg, ConstTerm(0))
    sum = add!(eg, FuncTerm(:+, [a, zt]))

    x = VarPattern(:x)
    y = VarPattern(:y)
    pat = FuncPattern(:+, [x, y])
    substs = collect(match(eg, sum, pat, Substitution()))

    @test Substitution(VarPattern(:x) => VarTerm(:a), VarPattern(:y) => ConstTerm(0)) in substs
end

end # module TestEmatching
