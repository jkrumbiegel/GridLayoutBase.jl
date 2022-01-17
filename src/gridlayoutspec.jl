function GridLayout(spec::GridLayoutSpec)
    gl = GridLayout(; spec.kwargs...)

    for ((rows, cols, side), content) in spec.content
        if content isa GridLayoutSpec
            content = GridLayout(content)
        end
        gl[rows, cols, side] = content
    end

    gl
end

const PosTuple = Tuple{Indexables, Indexables, Side}
to_valid_pos(pos::Tuple{Indexables, Indexables}) = (pos[1], pos[2], Inner)
to_valid_pos(pos::Tuple{Indexables, Indexables, Side}) = pos

function GridLayoutSpec(content::Vector{<:Pair}; kwargs...)
    spec_content = Pair{PosTuple, Any}[Pair{PosTuple, Any}(to_valid_pos(pos), c) for (pos, c) in content]
    GridLayoutSpec(spec_content, Dict{Symbol, Any}(kwargs))
end
