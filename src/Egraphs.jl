module Egraphs

public
    Egraph,
    Enode,
    ConstTerm,
    VarTerm,
    FuncTerm

public
    add!,
    find!,
    merge!,
    rebuild!


include("./unionfind.jl")
using .UnionFinds: find!

include("./egraph.jl")
using .EgraphsCore: Egraph, Enode, ConstTerm, VarTerm, FuncTerm
using .EgraphsCore: add!, merge!, rebuild!

include("./match.jl")
include("./rewrite.jl")

include("./dsl.jl")

end # module Egraphs
