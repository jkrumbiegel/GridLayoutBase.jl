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

to_valid_pos(pos::Tuple{Any, Any}) = (pos[1], pos[2], Inner())
to_valid_pos(pos::Tuple{Any, Any, Any}) = pos

function GridLayoutSpec(content::Vector{<:Pair}; kwargs...)
    spec_content::Vector{Pair{Tuple{Indexables, Indexables, Side}, Any}} =
        map(content) do (pos, content)
            validpos = to_valid_pos(pos)
            return validpos => content
        end
    GridLayoutSpec(spec_content, Dict{Symbol, Any}(kwargs))
end
