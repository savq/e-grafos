module Egraphs

# TODO: Fix recursive e-graphs.

public
    Egraph,
    EclassId,
    Enode,
    ConstTerm,
    VarTerm,
    FuncTerm,
    ConstPattern,
    VarPattern,
    FuncPattern

public
    add!,
    find!,
    merge!,
    rebuild!,
    search,
    match,
    extract,
    rewrite!,
    eqsaturate!,
    @add,
    @rule


include("./unionfind.jl")
include("./egraph.jl")
include("./match.jl")
include("./rewrite.jl")
include("./dsl.jl")

end # module Egraphs
