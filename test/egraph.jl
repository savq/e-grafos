module TestEgraphsCore

using Test
using Egraphs: Egraph, ConstTerm, VarTerm, FuncTerm
using Egraphs: add!, find!, merge!, rebuild!

@testset "add! variables" begin
    eg = Egraph()
    id_a1 = add!(eg, VarTerm(:a))
    id_a2 = add!(eg, VarTerm(:a))
    @test id_a1 == id_a2
end

@testset "add! functions" begin
    eg = Egraph()
    id_a1 = add!(eg, VarTerm(:a))
    id_a2 = add!(eg, VarTerm(:a))
    id_f1 = add!(eg, FuncTerm(:f, [id_a1]))
    id_f2 = add!(eg, FuncTerm(:f, [id_a2]))
    @test id_f1 == id_f2
end

@testset "add! constants" begin
    eg = Egraph()
    id_one1 = add!(eg, ConstTerm(1))
    id_one2 = add!(eg, ConstTerm(1))
    @test id_one1 == id_one2
end

@testset "merge! variables" begin
    eg = Egraph()
    id_a = add!(eg, VarTerm(:a))
    id_b = add!(eg, VarTerm(:b))

    # Antes de `merge!`, las e-clases de `a, b` deben ser diferentes
    @test find!(eg, id_a) != find!(eg, id_b)

    # Después de `merge!`, las e-clases deben ser iguales
    merge!(eg, id_a, id_b)
    @test find!(eg, id_a) == find!(eg, id_b)
end

@testset "merge! functions" begin
    # { f(a, b), g(a, b), f == g }
    eg = Egraph()
    id_a = add!(eg, VarTerm(:a))
    id_b = add!(eg, VarTerm(:b))
    id_f = add!(eg, FuncTerm(:f, [id_a, id_b]))
    id_g = add!(eg, FuncTerm(:g, [id_a, id_b]))

    # Antes de `merge!`, las e-clases de `f, g` deben ser diferentes
    @test find!(eg, id_f) != find!(eg, id_g)

    merge!(eg, id_f, id_g)
    rebuild!(eg)

    # Después de `merge!` las e-clases deben ser iguales
    @test find!(eg, id_f) == find!(eg, id_g)

    # Los nodos padre de `a` y de `b` también deben ser iguales
    @test reduce((==), values(eg.eclass_map[find!(eg, id_a)].parents))
    @test reduce((==), values(eg.eclass_map[find!(eg, id_b)].parents))
end

@testset "merge! function arguments" begin
    # { f(a), f(b), a == b }
    eg = Egraph()
    id_a = add!(eg, VarTerm(:a))
    id_b = add!(eg, VarTerm(:b))
    id_f1 = add!(eg, FuncTerm(:f, [id_a]))
    id_f2 = add!(eg, FuncTerm(:f, [id_b]))

    # Antes de `merge!`, las e-clases de `f1, f2` deben ser diferentes
    @test find!(eg, id_f1) != find!(eg, id_f2)

    merge!(eg, id_a, id_b)
    rebuild!(eg)

    # Después de `merge!`, las e-clases deben ser iguales
    @test find!(eg, id_f1) == find!(eg, id_f2)

    # La e-clase de `f` debe tener un único nodo
    @test length(eg.eclass_map[find!(eg, id_f1)].nodes) == 1

    # Los nodos padre de `a` y de `b` deben ser iguales
    @test eg.eclass_map[find!(eg, id_a)].parents == eg.eclass_map[find!(eg, id_b)].parents
end

@testset "merge! constants should be impossible" begin
    eg = Egraph()
    id_one = add!(eg, ConstTerm(1))
    id_two = add!(eg, ConstTerm(2))

    # TODO: This should fail
    merge!(eg, id_one, id_two)
    @test find!(eg, id_one) != find!(eg, id_two) broken=true
end

end # module TestEgraphsCore
