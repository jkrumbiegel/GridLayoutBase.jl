left(rect::Rect{2}) = minimum(rect)[1]
right(rect::Rect{2}) = maximum(rect)[1]
bottom(rect::Rect{2}) = minimum(rect)[2]
top(rect::Rect{2}) = maximum(rect)[2]

width(rect::Rect{2}) = right(rect) - left(rect)
height(rect::Rect{2}) = top(rect) - bottom(rect)


function BBox(left::Number, right::Number, bottom::Number, top::Number)
    mini = (left, bottom)
    maxi = (right, top)
    return Rect2f(mini, maxi .- mini)
end


function RowCols(ncols::Int, nrows::Int)
    return RowCols(
        zeros(Float32, ncols),
        zeros(Float32, ncols),
        zeros(Float32, nrows),
        zeros(Float32, nrows)
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
    return BBox(f(Left()), f(Right()), f(Bottom()), f(Top()))
end

"""
mapsides(
       f, first::Union{Rect{2}, RowCols}, rest::Union{Rect{2}, RowCols}...
   )::Rect2f
Maps f over all sides of the rectangle like arguments.
e.g.
```
mapsides(BBox(left, right, bottom, top)) do side::Side, side_val::Number
    return ...
end::Rect2f
```
"""
function mapsides(
        f, first::Union{Rect{2}, RowCols}, rest::Union{Rect{2}, RowCols}...
    )
    return eachside() do side
        f(side, getindex.((first, rest...), (side,))...)
    end
end
