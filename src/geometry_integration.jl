left(rect::HyperRectangle{2}) = minimum(rect)[1]
right(rect::HyperRectangle{2}) = maximum(rect)[1]
bottom(rect::HyperRectangle{2}) = minimum(rect)[2]
top(rect::HyperRectangle{2}) = maximum(rect)[2]

width(rect::HyperRectangle{2}) = right(rect) - left(rect)
height(rect::HyperRectangle{2}) = top(rect) - bottom(rect)


function BBox(left::Number, right::Number, bottom::Number, top::Number)
    mini = (left, bottom)
    maxi = (right, top)
    return FRect2D(mini, maxi .- mini)
end


function RowCols(ncols::Int, nrows::Int)
    return RowCols(
        zeros(ncols),
        zeros(ncols),
        zeros(nrows),
        zeros(nrows)
    )
end

Base.getindex(rowcols::RowCols, ::Left) = rowcols.lefts
Base.getindex(rowcols::RowCols, ::Right) = rowcols.rights
Base.getindex(rowcols::RowCols, ::Top) = rowcols.tops
Base.getindex(rowcols::RowCols, ::Bottom) = rowcols.bottoms

"""
    eachside(f)
Calls f over all sides (Left, Right, Top, Bottom), and creates a BBox from the result of f(side)
"""
function eachside(f)
    return BBox(map(f, (Left(), Right(), Bottom(), Top()))...)
end

"""
mapsides(
       f, first::Union{HyperRectangle{2}, RowCols}, rest::Union{HyperRectangle{2}, RowCols}...
   )::FRect2D
Maps f over all sides of the rectangle like arguments.
e.g.
```
mapsides(BBox(left, right, bottom, top)) do side::Side, side_val::Number
    return ...
end::FRect2D
```
"""
function mapsides(
        f, first::Union{HyperRectangle{2}, RowCols}, rest::Union{HyperRectangle{2}, RowCols}...
    )
    return eachside() do side
        f(side, getindex.((first, rest...), (side,))...)
    end
end
