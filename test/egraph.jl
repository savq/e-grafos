module TestEgraphs

using Test
using Egraphs: Egraph, Enode
using Egraphs: add!, find!, merge!, rebuild!

@testset "add! variables" begin
    eg = Egraph()
    id_a1 = add!(eg, Enode(:a, []))
    id_a2 = add!(eg, Enode(:a, []))
    @test id_a1 == id_a2
end

@testset "add! functions" begin
    eg = Egraph()
    id_a1 = add!(eg, Enode(:a, []))
    id_a2 = add!(eg, Enode(:a, []))
    id_f1 = add!(eg, Enode(:f, [id_a1]))
    id_f2 = add!(eg, Enode(:f, [id_a2]))
    @test id_f1 == id_f2
end

@testset "merge! variables" begin
    eg = Egraph()
    id_a = add!(eg, Enode(:a, []))
    id_b = add!(eg, Enode(:b, []))

    # Antes de `merge!`, las e-clases de `a, b` deben ser diferentes
    @test find!(eg, id_a) != find!(eg, id_b)

    # Después de `merge!`, las e-clases deben ser iguales
    merge!(eg, id_a, id_b)
    @test find!(eg, id_a) == find!(eg, id_b)
end

@testset "merge! functions" begin
    # { f(a, b), g(a, b), f == g }
    eg = Egraph()
    id_a = add!(eg, Enode(:a, []))
    id_b = add!(eg, Enode(:b, []))
    id_f = add!(eg, Enode(:f, [id_a, id_b]))
    id_g = add!(eg, Enode(:g, [id_a, id_b]))

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
    id_a = add!(eg, Enode(:a, []))
    id_b = add!(eg, Enode(:b, []))
    id_f1 = add!(eg, Enode(:f, [id_a]))
    id_f2 = add!(eg, Enode(:f, [id_b]))

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

end # TestEgraphs
