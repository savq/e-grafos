const EclassId = UInt32


struct Enode
    head::Symbol
    args::Vector{UInt32}
end

function Base.:(==)(a::Enode, b::Enode)
    return (a.head == b.head) && (a.args == b.args)
end

function Base.hash(node::Enode, h::UInt)
    h = hash(node.head, h)
    for arg in node.args
        h = hash.(arg, h)
    end
    return h
end

function Base.show(io::IO, node::Enode)
    print(io, "⸨", node.head, isempty(node.args) ? "" : (" " * join(node.args, " ")), "⸩")
end


mutable struct Eclass
    nodes::Set{Enode}
    parents::Dict{Enode, EclassId}
end


function _create_id_generator()
    return Channel{EclassId}() do c
        x = zero(EclassId)
        while true
            put!(c, x += 1)
        end
    end
end


mutable struct Egraph
    union_find::UnionFind{EclassId}
    eclass_map::Dict{EclassId, Eclass}
    hashcons::Dict{Enode, EclassId}
    worklist::Vector{EclassId}
    id_generator::Channel

    Egraph() = new(UnionFind{EclassId}(), Dict(), Dict(), [], _create_id_generator())
end

function find!(eg::Egraph, id::EclassId)::EclassId
    return find!(eg.union_find, id)
end

function canonicalize(eg::Egraph, node::Enode)
    return Enode(node.head, map(arg -> find!(eg, arg), node.args))
end

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

        for arg in node.args
            eg.eclass_map[arg].parents[node] = new_id
        end

        ## Update hashcons
        eg.hashcons[node] = new_id

        return new_id
    end
end

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
            for arg in node.args
                eg.eclass_map[arg].parents[node] = new_id
            end
        end

        # Update parents
        for (p_node, p_class_id) in eg.eclass_map[old_id].parents
            eg.eclass_map[new_id].parents[p_node] = find!(eg, p_class_id)
        end

        ## Update hashcons
        for node in eg.eclass_map[new_id].nodes
            delete!(eg.hashcons, node)
            node = canonicalize(eg, node)
            eg.hashcons[node] = new_id
        end

        ## Remove old e-class and mark new e-class as stale
        delete!(eg.eclass_map, old_id)
        push!(eg.worklist, new_id)

        return new_id
    end
end

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

function rebuild!(eg::Egraph)
    while !isempty(eg.worklist)
        dedup_worklist = Set(find!(eg, id) for id in eg.worklist)
        eg.worklist = []
        for id in dedup_worklist
            repair!(eg, id)
        end
    end
end
