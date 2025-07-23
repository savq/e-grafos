### A Pluto.jl notebook ###
# v0.20.13

using Markdown
using InteractiveUtils

# ╔═╡ 304076bc-67a3-11f0-12df-e72a6c18dd45
begin
	using PlutoUI: TableOfContents, LocalResource
	using Test: @testset, @test, @test_throws
end

# ╔═╡ ebbb2300-6777-4edf-8918-a2b2e77f6f6f
md"""
# E-grafos

Sergio Alejandro Vargas Q.\
savargasqu@unal.edu.co

Álgebra Abstracta y Computacional 2025-I\
Universidad Nacional de Colombia

[Enlace al repositorio](https://github.com/savq/e-grafos)
"""

# ╔═╡ f304d80f-c63e-453c-a915-805333d58da4
TableOfContents()

# ╔═╡ 25600dbc-30a0-495a-adbe-669e2e7bb436
md"""
# Introducción

Un ejemplo de compiladores...

![](./imgs/01.png)
"""

# ╔═╡ 1726db1b-e0c4-4f74-8f42-d50011a3c247
md"""
##

Queremos simplificar la expresión:
```
(a * 2) / 2
```
"""

# ╔═╡ b6612ee0-532c-4ac0-bad7-840570189903
LocalResource("./imgs/01.png")

# ╔═╡ 8bb21019-7241-4a29-8861-dbfd9a5f6f95
md"""
##

Posibles reglas
```
x / x -> 1
x * 2 -> x << 1
```
"""

# ╔═╡ 83a5e1f3-d6d8-4665-b4f2-cc4ec51616ca
LocalResource("./imgs/02.png")

# ╔═╡ 06515986-fa2b-4d9c-b98f-c9d58c760a7e
md"""
##

Podemos reutilizar nodos para reducir el consumo de memoria.
"""

# ╔═╡ b4e40994-20b2-4ef8-95fc-083a6c9c617b
LocalResource("./imgs/03.png")

# ╔═╡ 4950ddae-64f7-4764-b80a-b8dc25961da6
md"""
##

Podemos representar equivalencias entre términos.
"""

# ╔═╡ 3ffb7739-170b-4d03-974a-8e74dc8d9cd8
LocalResource("./imgs/04.png")

# ╔═╡ 80ba3652-b501-48c3-b539-114732db0b46
md"##"

# ╔═╡ cb28740e-45fe-4182-bb64-ca93ac7ad54c
LocalResource("./imgs/05.png")

# ╔═╡ 7c4b2067-2c1f-4512-856c-8bc9e0b52c85
md"##"

# ╔═╡ 4c0691d2-b82b-49f7-804e-62f88036202c
LocalResource("./imgs/06.png")

# ╔═╡ c116c966-d8bc-4a7b-a60b-d8bddad09795
md"""
# Definición de e-grafo

Un e-grafo (abreviación de e-graph, o equality graph) es una estructura de datos usada para representar y manipular eficientemente igualdades entre expresiones.

Estructuralmente, un e-grafo es una tupla $E = (U, M, H)$ compuesta por

- Una estructura _Union-Find_ $U$

- Un mapa de e-clases $M$

- Una estructura hashcons $H$
"""

# ╔═╡ cf421cd4-ab38-41dd-8ddd-f7dd3872f77f
abstract type Enode end

# ╔═╡ ebe5c986-b544-4968-9d2d-2cff78be4fbd
const EclassId = UInt32;

# ╔═╡ 36e63309-0bd9-4f02-9507-8fd30d7d56e1
mutable struct Eclass
    nodes::Set{Enode}
    parents::Dict{Enode, EclassId}
end

# ╔═╡ 55f890d3-7cfd-409c-9ac6-d4a081353f42
function create_id_generator()
    return Channel{EclassId}() do c
        x = zero(EclassId)
        while true
            put!(c, x += 1)
        end
    end
end

# ╔═╡ 71a6c37c-3c9a-4090-93b0-2c7ffc4a1fae
md"""
# Representación de un lenguaje formal

Los términos de un lenguaje formal están compuestos por:
- Constantes
- Variables
- Funciones
"""

# ╔═╡ 5d7bd249-c9c8-4c5e-bfae-3bb0041f9c75
begin

struct ConstTerm <: Enode
    val::Union{Symbol, Int}
end

struct VarTerm <: Enode
    head::Symbol
end

struct FuncTerm <: Enode
    head::Symbol
    args::Vector{EclassId}
end

function Base.:(==)(a::FuncTerm, b::FuncTerm)
    return (a.head == b.head) && (a.args == b.args)
end

function Base.hash(node::FuncTerm, h::UInt)
    h = hash(node.head, h)
    for arg in node.args
        h = hash.(arg, h)
    end
    return h
end

Base.show(io::IO, node::ConstTerm) = print(io, "⸨", node.val, "⸩")
Base.show(io::IO, node::VarTerm) = print(io, "⸨", node.head, "⸩")
Base.show(io::IO, node::FuncTerm) = print(io, "⸨", node.head, (" " * join(node.args, " ")), "⸩")

end

# ╔═╡ 34b24ef0-069b-41c5-a53f-20e97f4e598f
md"""
# Union-Find

- Estructura de conjuntos disyuntos.

- Dos operaciones.

  - `find`: Retorna el representante de un conjunto.

  - `union`: Reemplaza dos conjuntos de la partición por su unión.

- Implementación: dictionary → trees → sets
"""

# ╔═╡ 001ea2dc-7057-4c15-b515-57f822ad74c2
begin
struct UnionFind{T}
    parents::Dict{T, T}
    ranks::Dict{T, Int}; # número de "hijos" directos de un elemento
end

UnionFind{T}() where {T} = UnionFind{T}(Dict(), Dict()) # constructor vacío
end

# ╔═╡ a6f71498-4f81-48d4-8e29-13e6e0bc311f
mutable struct Egraph
    union_find::UnionFind{EclassId}
    eclass_map::Dict{EclassId, Eclass}
    hashcons::Dict{Enode, EclassId}
    
	worklist::Vector{EclassId}
    id_generator::Channel
	
    Egraph() = new(UnionFind{EclassId}(), Dict(), Dict(), [], create_id_generator())
end

# ╔═╡ 32148449-bd30-45a9-a6e7-b0899ad26c71
Base.Broadcast.broadcastable(eg::Egraph) = Ref(eg)

# ╔═╡ a2d86fcd-2e43-4cfe-8b07-2f35cef19ab0
function make_set!(u::UnionFind{T}, a::T) where {T}
    if haskey(u.parents, a)
        return a
    else
        u.parents[a] = a
        u.ranks[a] = 0
        return a
    end
end

# ╔═╡ 4f129d1a-ef54-4401-bbfd-154232bd160a
function find!(u::UnionFind{T}, a::T) where {T}
    if haskey(u.parents, a)
        if u.parents[a] != a
            # Reduce rank of old parent
            u.ranks[u.parents[a]] -= 1
            # Update parent
            u.parents[a] = find!(u, u.parents[a])
            # Increase rank of new parent
            u.ranks[u.parents[a]] += 1
        end
        return u.parents[a]
    else
        throw(KeyError(a))
    end
end

# ╔═╡ da2fc5f0-61fa-4781-8d82-cb768c7d9069
md"""
# Operaciones básicas
"""

# ╔═╡ d7bfe56e-f7f6-47b2-812e-1b177326a29a
md"el mismo find del union-find:"

# ╔═╡ 68cccd6d-241b-4e9e-97a0-6078ebb50ee0
function find!(eg::Egraph, id::EclassId)::EclassId
    return find!(eg.union_find, id)
end

# ╔═╡ 0c44ce4e-b7f2-4475-9e84-0feabe435dd0
function Base.union!(u::UnionFind{T}, a::T, b::T) where {T}
    root_a = find!(u, a)
    root_b = find!(u, b)

    if root_a != root_b
        if u.ranks[root_a] < u.ranks[root_b]
            u.parents[root_a] = root_b
            u.ranks[root_b] += 1
            return root_b
        else
            u.parents[root_b] = root_a
            u.ranks[root_a] += 1
            return root_a
        end
    else
        return root_a
    end
end

# ╔═╡ ef7f67b5-3ac9-4ae0-9244-153295cd2115
md"Los e-nodos deben tener una representación única (canónica):"

# ╔═╡ ed61d76a-b1d6-4da3-943d-e89b5aae794c
begin
canonicalize(eg::Egraph, node::ConstTerm) = node
canonicalize(eg::Egraph, node::VarTerm) = node
canonicalize(eg::Egraph, node::FuncTerm) =
	FuncTerm(node.head, map(arg -> find!(eg, arg), node.args))
end

# ╔═╡ 6e7fe152-b33c-4bfb-a40c-8aacff6dcda5
function add!(eg::Egraph, node::Enode)::EclassId
    node = canonicalize(eg, node)
    if haskey(eg.hashcons, node)
        return eg.hashcons[node]
    else
        ## Create new ID
        new_id = take!(eg.id_generator)

        ## Update union_find
        make_set!(eg.union_find, new_id)

        ## Update eclass_map
        eg.eclass_map[new_id] = Eclass(Set([node]), Dict())

        if node isa FuncTerm
            for arg in node.args
                eg.eclass_map[arg].parents[node] = new_id
            end
        end

        ## Update hashcons
        eg.hashcons[node] = new_id

        return new_id
    end
end

# ╔═╡ 873bf7ab-b89b-4612-bfc3-239104e4c39f
function Base.merge!(eg::Egraph, id1::EclassId, id2::EclassId)::EclassId
    root1 = find!(eg, id1)
    root2 = find!(eg, id2)

    if root1 == root2
        return root1
    else
        ## Update union_find
        new_id = union!(eg.union_find, root1, root2)

        if new_id == root1
            old_id = root2
        else
            old_id = root1
        end

        ## Update eclass_map
        for node in eg.eclass_map[old_id].nodes
            # Move node to new e-class
            node = canonicalize(eg, node)
            push!(eg.eclass_map[new_id].nodes, node)

            # Update children
            if node isa FuncTerm
                for arg in node.args
                    eg.eclass_map[arg].parents[node] = new_id
                end
            end
        end

        # Update parents
        for (p_node, p_class_id) in eg.eclass_map[old_id].parents
            eg.eclass_map[new_id].parents[p_node] = find!(eg, p_class_id)

            delete!(eg.eclass_map[p_class_id].nodes, p_node)
            push!(eg.eclass_map[p_class_id].nodes, canonicalize(eg, p_node))
        end

        ## Remove old e-class and mark new e-class as stale
        delete!(eg.eclass_map, old_id)
        push!(eg.worklist, new_id)

        return new_id
    end
end

# ╔═╡ c01b62be-01ef-4272-aa7d-1ce0219f63ab
function repair!(eg::Egraph, id::EclassId)
    eclass = eg.eclass_map[id]

    # TODO: Se puede optimizar este filtro?
    filter!(node -> node == canonicalize(eg, node), eclass.nodes)

    new_parents = Dict()
    for (p_node, p_class_id) in eclass.parents
        # Update hashcons
        delete!(eg.hashcons, p_node)
        p_node = canonicalize(eg, p_node)
        eg.hashcons[p_node] = find!(eg, p_class_id)

        # Dedup parents
        p_node = canonicalize(eg, p_node)
        if haskey(new_parents, p_node)
            merge!(eg, p_class_id, new_parents[p_node])
        end
        new_parents[p_node] = find!(eg, p_class_id)
    end

    # TODO: Cómo hacer esto sin mutación?
    eg.eclass_map[id].parents = new_parents
    return
end

# ╔═╡ 738dee24-8832-487c-9829-0cad5d07e07f
function rebuild!(eg::Egraph)
    while !isempty(eg.worklist)
        dedup_worklist = Set(find!(eg, id) for id in eg.worklist)
        eg.worklist = []
        for id in dedup_worklist
            repair!(eg, id)
        end
    end
end

# ╔═╡ 67ebe67d-7bc9-4cce-9ff2-a201244a339e
md"""
# E-matching (coincidencia de patrones)

- Buscar patrones
- Retornar posibles sustituciones
"""

# ╔═╡ 56eaa177-4bc5-4059-8a77-7dfb2ad5fe0e
begin

abstract type Pattern end

struct ConstPattern <: Pattern
    val::Union{Symbol, Int}
end

struct VarPattern <: Pattern
    head::Symbol
end

struct FuncPattern <: Pattern
    head::Symbol
    args::Vector{Pattern}
end

Base.show(io::IO, node::ConstPattern) = print(io, "⟦:", node.val, "⟧")
Base.show(io::IO, node::VarPattern) = print(io, "⟦", node.head, "⟧")
Base.show(io::IO, node::FuncPattern) =
	print(io, "⟦", node.head, (" " * join(node.args, " ")), "⟧")

end

# ╔═╡ cb88e815-35df-4609-9765-c86d7958f1ab
const Substitution = Dict{VarPattern, Enode};

# ╔═╡ 4a329c78-f2c3-478d-905b-361a0eed7e41
md"""
## Busqueda

Usamos canales (como generadores en Python) para retornar todas las posibles sustituciones.
"""

# ╔═╡ d36c5db4-7075-4877-9a3b-a91fd2439a05
md"""
## Matching

- Un e-nodo coincide si _todos_ sus argumentos coinciden.
- Una e-clase coincide si _alguno_ de sus e-nodos coinciden.
"""

# ╔═╡ 4919f618-3aba-4578-8c5c-0ec704da52ba
begin

# Una e-clase coincide si alguno de sus nodos coincide
function match(eg::Egraph, id::EclassId, pat::Pattern, subst::Substitution)
    Channel() do c
        nodes = eg.eclass_map[id].nodes
        for node in nodes
            for subst in match(eg, node, pat, subst)
                put!(c, subst)
            end
        end
    end
end

# Por defecto, no hay match.
function match(eg::Egraph, id::Enode, pat::Pattern, subst::Substitution)
    return Channel(identity)
end

# Los patrones variables hacen match incondicionalmente.
function match(eg::Egraph, node::Enode, var_pat::VarPattern, subst::Substitution)
    Channel() do c
        if haskey(subst, var_pat)
            if subst[var_pat] == node
                put!(c, subst)
            end
        else
            new_subst = copy(subst)
            new_subst[var_pat] = node
            put!(c, new_subst)
        end
    end
end

# Las funciones hacen match si sus cabezas coinciden y _todos_ sus argumentos coinciden.
function match(eg::Egraph, node::FuncTerm, pat::FuncPattern, subst::Substitution)
    Channel() do c
        if node.head == pat.head && length(pat.args) == length(node.args)
            for new_subst in match_list(eg, node.args, pat.args, subst)
                put!(c, new_subst)
            end
        end
    end
end

# Las constantes hacen match si sus valores son iguales.
function match(eg::Egraph, node::ConstTerm, pat::ConstPattern, subst::Substitution)
    Channel() do c
        if node.val == pat.val
            put!(c, subst)
        end
    end
end

function match_list(eg::Egraph, ids::Vector{EclassId}, patterns::Vector{Pattern}, subst::Substitution)
    Channel() do c
        if length(patterns) == 0
            put!(c, subst)
        else
            for subst1 in match(eg, ids[1], patterns[1], subst)
                for subst2 in match_list(eg, ids[2:end], patterns[2:end], subst1)
                    put!(c, subst2)
                end
            end
        end
    end
end;

end

# ╔═╡ d02aca4e-1e23-43a4-8aa1-d34a30aceef2
begin

function search(eg::Egraph, id::EclassId, pat::Pattern, visited=[])
    Channel() do c
        if id in visited
            return
        else
            push!(visited, id)
            nodes = eg.eclass_map[id].nodes
            for node in nodes
                for subst in search(eg, node, pat, visited)
                    put!(c, subst)
                end
            end
        end
    end
end

function search(eg::Egraph, node::Enode, pat::Pattern, _visited=[])
    Channel() do c
        for subst in match(eg, node, pat, Substitution())
            put!(c, subst)
        end
    end
end

function search(eg::Egraph, node::FuncTerm, pat::Pattern, visited=[])
    Channel() do c
        for subst in match(eg, node, pat, Substitution())
            put!(c, subst)
        end

        # Look for match in child e-classes
        for child in node.args
            for subst in search(eg, child, pat, visited)
                put!(c, subst)
            end
        end
    end
end;

end

# ╔═╡ ca29a288-eaab-4509-b921-1ad5734b9b62
md"""
# Reescritura
"""

# ╔═╡ ef215ff3-ce3b-49d5-93d1-d286e21d2b75
struct RewriteRule
    lhs::Pattern
    rhs::Pattern
end

# ╔═╡ 8407540b-b34d-4dac-b803-ec45b55ee5da
begin

function instantiate(eg::Egraph, pat::ConstPattern, subst)
    add!(eg, ConstTerm(pat.val))
end

function instantiate(eg::Egraph, pat::VarPattern, subst)
    add!(eg, subst[pat])
end

function instantiate(eg::Egraph, pat::FuncPattern, subst)
	add!(
		eg,
		FuncTerm(
			pat.head, [instantiate(eg, sub_pat, subst) for sub_pat in pat.args]
		)
	)
end

end

# ╔═╡ bf233520-085f-4476-9b83-8c6ea8871348
function rewrite!(eg::Egraph, id::EclassId, rule::RewriteRule)
    matches = []
    # @info "begin read phase"
    for subst in search(eg, id, rule.lhs)
        push!(matches, (rule, subst))
    end

    # @info "begin write phase"
    did_merge = false
    for (rule, subst) in matches
        l = instantiate(eg, rule.lhs, subst)
        r = instantiate(eg, rule.rhs, subst)
        if find!(eg, l) != find!(eg, r)
            # @info "Substitution" rule subst l r
            did_merge |= true
            merge!(eg, l, r)
        end
    end

    did_rebuild = !isempty(eg.worklist)
    rebuild!(eg)

    saturated = !(did_merge || did_rebuild)
    return saturated
end

# ╔═╡ d6259506-54e7-4489-a95e-eaed406b8f7a
md"""
## Extracción

- Buscamos una expresión "óptima".
- Función de costo: tamaño de la expresión.
"""

# ╔═╡ c3bf915d-2a55-4e75-b402-ea9ad2e5f76d
begin

# El costo de constantes y variables es 1
function extract(eg::Egraph, node::VarTerm)
    return (1, node.head)
end

function extract(eg::Egraph, node::ConstTerm)
    if node.val isa Symbol
        return (1, QuoteNode(node.val))
    else
        return (1, node.val)
    end
end

# El costo de una función es 1 + el costo de sus argumentos
function extract(eg::Egraph, node::FuncTerm)
    cost = 1
    expr = []
    for (c, sub_expr) in extract.(eg, node.args)
        cost += c
        push!(expr, sub_expr)
    end
    return cost, Expr(:call, node.head, expr...)
end

# Return the e-node with the lowest cost in e-class
# TODO: Avoid infinite loops
function extract(eg::Egraph, id::EclassId)
    nodes = eg.eclass_map[id].nodes
    local optimal_cost = Inf
    local optimal_expr
    for (cost, expr) in extract.(eg, nodes)
        if cost < optimal_cost
            optimal_cost, optimal_expr = cost, expr
        end
    end
    return optimal_cost, optimal_expr
end

end

# ╔═╡ 6824acfa-c235-43db-9507-0320e9ceb172
md"""
# Algoritmo de saturación

Aplicar reescrituras hasta que el e-grafo alcance un punto fijo (no se puede añadir más nodos).
"""

# ╔═╡ 02c02ef0-a54f-40ab-b41c-1d019b9fdff0
function eqsaturate!(
	eg::Egraph, id::EclassId, rewrites::Vector{RewriteRule};
	timeout=100
)
    saturated = false
    while !saturated && timeout > 0
        for rule in rewrites
            saturated = rewrite!(eg, id, rule)
        end
        timeout -= 1
        # @info "timeout" timeout
    end
end

# ╔═╡ 4f0449d7-e2c4-4e7e-a9b5-4d80a74c8326
md"""
# DSL para términos y patrones

(es más claro ver los ejemplos)
"""

# ╔═╡ 81826354-a78f-441a-a079-b408e0108165
begin

pattern_from_expr(n::Int) = ConstPattern(n)
pattern_from_expr(qn::QuoteNode) = ConstPattern(qn.value)
pattern_from_expr(sym::Symbol) = VarPattern(sym)

function pattern_from_expr(expr::Expr)
    if expr.head === :call
        return FuncPattern(expr.args[1], pattern_from_expr.(expr.args[2:end]))
    else
        ArgumentError("expr must be call, symbol or integer: ", expr)
    end
end

function rewrite_rule_from_expr(expr::Expr)
    if expr.head == :(-->)
        lhs, rhs = expr.args
        return RewriteRule(pattern_from_expr(lhs), pattern_from_expr(rhs))
    else
        ArgumentError("expr must be an Expr of the form `lhs --> rhs`")
    end
end

macro rule(expr::Expr)
    :(rewrite_rule_from_expr($(QuoteNode(expr))))
end

enode_from_expr(eg::Egraph, n::Int) = add!(eg, ConstTerm(n))
enode_from_expr(eg::Egraph, qn::QuoteNode) = add!(eg, ConstTerm(qn.value))
enode_from_expr(eg::Egraph, sym::Symbol) = add!(eg, VarTerm(sym))

function enode_from_expr(eg::Egraph, expr::Expr)
    if expr.head === :call
        return add!(eg, FuncTerm(expr.args[1], enode_from_expr.(eg, expr.args[2:end])))
    else
        ArgumentError("Expr must be call, symbol or integer: ", expr)
    end
end

macro add(eg::Symbol, expr)
    :(enode_from_expr($(esc(eg)), $(QuoteNode(expr))))
end

end

# ╔═╡ e3083285-e696-4de9-9e8a-90886c53c94e
md"""
# Ejemplos
"""

# ╔═╡ 96d706b9-ac4b-49f4-979d-aa586820aa2f
@testset "Diferenciación simbólica" begin
    theory = [
        @rule Dx(:x) --> 1
        @rule Dx(y) --> 0

        @rule Dx(u + v) --> Dx(v + u)
        @rule Dx(u * v) --> u*Dx(v) + v*Dx(u)

        @rule u + v --> v + u
        @rule u * 1 --> u
        @rule u + u --> 2 * u
    ]

    eg = Egraph()
    term = @add(eg, Dx(:x * :x))

    eqsaturate!(eg, term, theory)
    # @test extract(eg, term)[2] == :(2 * :x)

    @test find!(eg, term) == find!(eg, @add eg (2 * :x))
end

# ╔═╡ 323fc6a4-2423-42f5-b4d5-d0976b59a9b9
@testset "Teoría de grupos" begin
    theory = [
        # associativity
        @rule (x * y) * z --> x * (y * z)
        @rule x * (y * z) --> (x * y) * z

        # identity
        @rule x * :e --> x
        @rule :e * x --> x

        # inverses
        @rule x * inv(x) --> :e
        @rule inv(x) * x --> :e
        @rule inv(inv(x)) --> x

        # commutativity
        @rule x * y --> y * x
    ]

    eg = Egraph()
    term = @add(eg, (a * b) * inv(a))

    eqsaturate!(eg, term, theory)
    # @test extract(eg, term)[2] == :b

    rewrite!(eg, term, theory[3])
    @test find!(eg, term) == find!(eg, @add eg b)
end

# ╔═╡ 2350aa2c-954a-4262-9f04-7b019dcdd1b7
md"""
# Estado del arte

- E-analisis: Reescritura usando computación arbitraria


- Proyectos usando e-grafos

  - [Cranelift: compiler backend](https://cranelift.dev/)

  - [Metatheory.jl: symbolic computation](https://github.com/JuliaSymbolics/Metatheory.jl)

  - [Herbie: Accurate Floating Point Expressions.](https://herbie.uwplse.org/pldi15-paper.pdf)

  - Otros proyectos: [awesome-egraphs](https://github.com/philzook58/awesome-egraphs)

"""

# ╔═╡ 85b01956-273f-4922-bf89-d9e350ece009
md"""
# Referencias

1. Franz Baader and Tobias Nipkow. 1999. Term rewriting and all that (1st paperback edition ed.). Cambridge University Press, Cambridge New York Melbourne Madrid Cape Town.


2. Alessandro Cheli. 2021. Automated Code Optimization with E-Graphs. <https://doi.org/10.48550/arXiv.2112.14714>


3. David Detlefs, Greg Nelson, and James B. Saxe. 2005. Simplify: a theorem prover for program checking. J. ACM 52, 3 (May 2005), 365–473. <https://doi.org/10.1145/1066100.1066102>


4. Jean-Christophe Filliatre and Sylvain Conchon. 2006. Type-Safe Modular Hash-Consing. (2006).


5. Pavel Panchekha, Alex Sachez-Stern, James R Wilcox, and Zachary Tatlock. Automatically Improving Accuracy for Floating Point Expressions. 


6. Robert Endre Tarjan. 1975. Efficiency of a Good But Not Linear Set Union Algorithm. J. ACM 22, 2 (April 1975), 215–225. <https://doi.org/10.1145/321879.321884>


7. Ross Tate, Michael Stepp, Zachary Tatlock, and Sorin Lerner. 2011. Equality Saturation: A New Approach to Optimization. Logical Methods in Computer Science Volume 7, Issue 1, (March 2011), 1016. <https://doi.org/10.2168/LMCS-7(1:10)2011>


8. Max Willsey. 2021. Practical and Flexible Equality Saturation. (2021).


9. Max Willsey, Chandrakana Nandi, Yisu Remy Wang, Oliver Flatt, Zachary Tatlock, and Pavel Panchekha. 2021. egg: Fast and Extensible Equality Saturation. Proc. ACM Program. Lang. 5, POPL (January 2021), 1–29. <https://doi.org/10.1145/3434304>


10. Yihong Zhang, Yisu Remy Wang, Oliver Flatt, David Cao, Philip Zucker, Eli Rosenthal, Zachary Tatlock, and Max Willsey. 2023. Better Together: Unifying Datalog and Equality Saturation. <https://doi.org/10.48550/arXiv.2304.04332>
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[compat]
PlutoUI = "~0.7.68"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.6"
manifest_format = "2.0"
project_hash = "4e47d654be604c5bf42c58956c88e5b6ec1fd02c"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

    [deps.ColorTypes.weakdeps]
    StyledStrings = "f489334b-da3d-4c2e-b8f0-e476e12c162b"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "7d2f8f21da5db6a806faf7b9b292296da42b2810"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.3"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "ec9e63bd098c50e4ad28e7cb95ca7a4860603298"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.68"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.Tricks]]
git-tree-sha1 = "6cae795a5a9313bbb4f60683f7263318fc7d1505"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.10"

[[deps.URIs]]
git-tree-sha1 = "bef26fb046d031353ef97a82e3fdb6afe7f21b1a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╟─ebbb2300-6777-4edf-8918-a2b2e77f6f6f
# ╠═304076bc-67a3-11f0-12df-e72a6c18dd45
# ╠═f304d80f-c63e-453c-a915-805333d58da4
# ╟─25600dbc-30a0-495a-adbe-669e2e7bb436
# ╟─1726db1b-e0c4-4f74-8f42-d50011a3c247
# ╟─b6612ee0-532c-4ac0-bad7-840570189903
# ╟─8bb21019-7241-4a29-8861-dbfd9a5f6f95
# ╟─83a5e1f3-d6d8-4665-b4f2-cc4ec51616ca
# ╟─06515986-fa2b-4d9c-b98f-c9d58c760a7e
# ╟─b4e40994-20b2-4ef8-95fc-083a6c9c617b
# ╟─4950ddae-64f7-4764-b80a-b8dc25961da6
# ╟─3ffb7739-170b-4d03-974a-8e74dc8d9cd8
# ╟─80ba3652-b501-48c3-b539-114732db0b46
# ╟─cb28740e-45fe-4182-bb64-ca93ac7ad54c
# ╟─7c4b2067-2c1f-4512-856c-8bc9e0b52c85
# ╟─4c0691d2-b82b-49f7-804e-62f88036202c
# ╟─c116c966-d8bc-4a7b-a60b-d8bddad09795
# ╠═cf421cd4-ab38-41dd-8ddd-f7dd3872f77f
# ╠═ebe5c986-b544-4968-9d2d-2cff78be4fbd
# ╠═36e63309-0bd9-4f02-9507-8fd30d7d56e1
# ╠═a6f71498-4f81-48d4-8e29-13e6e0bc311f
# ╟─55f890d3-7cfd-409c-9ac6-d4a081353f42
# ╠═32148449-bd30-45a9-a6e7-b0899ad26c71
# ╟─71a6c37c-3c9a-4090-93b0-2c7ffc4a1fae
# ╠═5d7bd249-c9c8-4c5e-bfae-3bb0041f9c75
# ╟─34b24ef0-069b-41c5-a53f-20e97f4e598f
# ╠═001ea2dc-7057-4c15-b515-57f822ad74c2
# ╠═a2d86fcd-2e43-4cfe-8b07-2f35cef19ab0
# ╠═4f129d1a-ef54-4401-bbfd-154232bd160a
# ╠═0c44ce4e-b7f2-4475-9e84-0feabe435dd0
# ╠═da2fc5f0-61fa-4781-8d82-cb768c7d9069
# ╟─d7bfe56e-f7f6-47b2-812e-1b177326a29a
# ╠═68cccd6d-241b-4e9e-97a0-6078ebb50ee0
# ╟─ef7f67b5-3ac9-4ae0-9244-153295cd2115
# ╠═ed61d76a-b1d6-4da3-943d-e89b5aae794c
# ╠═6e7fe152-b33c-4bfb-a40c-8aacff6dcda5
# ╠═873bf7ab-b89b-4612-bfc3-239104e4c39f
# ╠═c01b62be-01ef-4272-aa7d-1ce0219f63ab
# ╠═738dee24-8832-487c-9829-0cad5d07e07f
# ╠═67ebe67d-7bc9-4cce-9ff2-a201244a339e
# ╠═56eaa177-4bc5-4059-8a77-7dfb2ad5fe0e
# ╠═cb88e815-35df-4609-9765-c86d7958f1ab
# ╟─4a329c78-f2c3-478d-905b-361a0eed7e41
# ╠═d02aca4e-1e23-43a4-8aa1-d34a30aceef2
# ╟─d36c5db4-7075-4877-9a3b-a91fd2439a05
# ╠═4919f618-3aba-4578-8c5c-0ec704da52ba
# ╠═ca29a288-eaab-4509-b921-1ad5734b9b62
# ╠═ef215ff3-ce3b-49d5-93d1-d286e21d2b75
# ╠═8407540b-b34d-4dac-b803-ec45b55ee5da
# ╠═bf233520-085f-4476-9b83-8c6ea8871348
# ╟─d6259506-54e7-4489-a95e-eaed406b8f7a
# ╠═c3bf915d-2a55-4e75-b402-ea9ad2e5f76d
# ╠═6824acfa-c235-43db-9507-0320e9ceb172
# ╠═02c02ef0-a54f-40ab-b41c-1d019b9fdff0
# ╟─4f0449d7-e2c4-4e7e-a9b5-4d80a74c8326
# ╠═81826354-a78f-441a-a079-b408e0108165
# ╟─e3083285-e696-4de9-9e8a-90886c53c94e
# ╠═96d706b9-ac4b-49f4-979d-aa586820aa2f
# ╠═323fc6a4-2423-42f5-b4d5-d0976b59a9b9
# ╠═2350aa2c-954a-4262-9f04-7b019dcdd1b7
# ╟─85b01956-273f-4922-bf89-d9e350ece009
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
