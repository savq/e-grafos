module TestUnionFind

using Test
using Egraphs: UnionFind, make_set!, find!, union!

@testset "Test UnionFind" begin
    u = UnionFind{Char}(Dict(), Dict())
    # Adding elements
    for char in "abcdexy"
        make_set!(u, char)
    end

    union!(u, 'x', 'a')
    union!(u, 'y', 'b')
    union!(u, 'a', 'b')
    union!(u, 'c', 'd')

    @test 'x' == find!(u, 'a')
    @test 'x' == find!(u, 'b')
    @test 'e' == find!(u, 'e')
    @test find!(u, 'x') == find!(u, 'y')
end

end # TestUnionFind
