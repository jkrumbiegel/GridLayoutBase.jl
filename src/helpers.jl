Base.eltype(::Type{RectSides{T}}) where T = T

"""
Shorthand for `isnothing(optional) ? fallback : optional`
"""
@inline ifnothing(optional, fallback) = isnothing(optional) ? fallback : optional

function Base.foreach(f::Function, contenttype::Type, layout::GridLayout; recursive = true)
    for c in layout.content
        if recursive && c.content isa GridLayout
            foreach(f, contenttype, c.content)
        elseif c.content isa contenttype
            f(c.content)
        end
    end
end

"""
Swaps or rotates the layout positions of the given elements to their neighbor's.
"""
function swap!(layout_elements...)
    gridcontents = gridcontent.(collect(layout_elements))

    # copy relevant fields before gridcontents are mutated
    parents = map(gc -> gc.parent, gridcontents)
    spans = map(gc -> gc.span, gridcontents)
    sides = map(gc -> gc.side, gridcontents)

    for (gc, parent, span, side) in zip(circshift(gridcontents, 1), parents, spans, sides)
        parent[span.rows, span.cols, side] = gc.content
    end
end

function zcumsum(v::AbstractVector{T}) where T
    vpad = [[zero(T)]; v]  # inference-friendly
    cumsum!(vpad, vpad)
end
