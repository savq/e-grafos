module TestHashCons

using Test
using Egraphs: HashCons, get!


@testset "Test HashCons" begin
    h = HashCons(Dict{UInt, Any}())

    e1 = :[+, x, y]
    e2 = :[+, x, y]

    hashed_e1 = get!(h, e1)
    hashed_e2 = get!(h, e2)

    @test e1 !== e2
    @test hashed_e1 === hashed_e2
end

end # TestHashCons
