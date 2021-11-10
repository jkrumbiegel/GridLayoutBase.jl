"""
    side_indices(c::GridContent)::RowCols{Int}

Indices of the rows / cols for each side
"""
function side_indices(c::GridContent)
    return RowCols(
        c.span.cols.start,
        c.span.cols.stop,
        c.span.rows.start,
        c.span.rows.stop,
    )
end

# These functions tell whether an object in a grid touches the left, top, etc. border
# of the grid. This means that it is relevant for the grid's own protrusion on that side.
ismostin(gc::GridContent, grid, ::Left) = gc.span.cols.start == 1
ismostin(gc::GridContent, grid, ::Right) = gc.span.cols.stop == grid.ncols
ismostin(gc::GridContent, grid, ::Bottom) = gc.span.rows.stop == grid.nrows
ismostin(gc::GridContent, grid, ::Top) = gc.span.rows.start == 1


function protrusion(x::T, side::Side) where T
    protrusions = protrusionsobservable(x)
    if side isa Left
        protrusions[].left
    elseif side isa Right
        protrusions[].right
    elseif side isa Bottom
        protrusions[].bottom
    elseif side isa Top
        protrusions[].top
    else
        error("Can't get a protrusion value for side $(typeof(side)), only
        Left, Right, Bottom, or Top.")
    end
end

function protrusion(gc::GridContent, side::Side)
    prot = 
        if gc.side isa Inner
            protrusion(gc.content, side)
        # elseif gc.side isa Outer; BBox(l - pl, r + pr, b - pb, t + pt)
        elseif gc.side isa Union{Left, Right}
            if side isa typeof(gc.side)
                determinedirsize(gc.content, Col(), gc.side)
            else
                0.0
            end
        elseif gc.side isa Union{Top, Bottom}
            if side isa typeof(gc.side)
                determinedirsize(gc.content, Row(), gc.side)
            else
                0.0
            end
        elseif gc.side isa TopLeft
            if side isa Top
                determinedirsize(gc.content, Row(), gc.side)
            elseif side isa Left
                determinedirsize(gc.content, Col(), gc.side)
            else
                0.0
            end
        elseif gc.side isa TopRight
            if side isa Top
                determinedirsize(gc.content, Row(), gc.side)
            elseif side isa Right
                determinedirsize(gc.content, Col(), gc.side)
            else
                0.0
            end
        elseif gc.side isa BottomLeft
            if side isa Bottom
                determinedirsize(gc.content, Row(), gc.side)
            elseif side isa Left
                determinedirsize(gc.content, Col(), gc.side)
            else
                0.0
            end
        elseif gc.side isa BottomRight
            if side isa Bottom
                determinedirsize(gc.content, Row(), gc.side)
            elseif side isa Right
                determinedirsize(gc.content, Col(), gc.side)
            else
                0.0
            end
        else
            error("Invalid side $(gc.side)")
        end
    ifnothing(prot, 0.0)
end

getside(m::Mixed, ::Left) = m.sides.left
getside(m::Mixed, ::Right) = m.sides.right
getside(m::Mixed, ::Top) = m.sides.top
getside(m::Mixed, ::Bottom) = m.sides.bottom

function inside_protrusion(gl::GridLayout, side::Side)
    prot = 0.0
    for elem in gl.content
        if ismostin(elem, gl, side)
            # take the max protrusion of all elements that are sticking
            # out at this side
            prot = max(protrusion(elem, side), prot)
        end
    end
    return prot
end

function protrusion(gl::GridLayout, side::Side)
    # when we align with the outside there is by definition no protrusion
    if gl.alignmode[] isa Outside
        return 0.0
    elseif gl.alignmode[] isa Inside
        inside_protrusion(gl, side)
    elseif gl.alignmode[] isa Mixed
        si = getside(gl.alignmode[], side)
        if isnothing(si)
            inside_protrusion(gl, side)
        elseif si isa Protrusion
            si.p
        else
            # Outside alignment
            0.0
        end
    else
        error("Unknown AlignMode of type $(typeof(gl.alignmode[]))")
    end
end

function bbox_for_solving_from_side(maxgrid::RowCols, bbox_cell::Rect2f, idx_rect::RowCols, side::Side)
    pl = maxgrid.lefts[idx_rect.lefts]
    pr = maxgrid.rights[idx_rect.rights]
    pt = maxgrid.tops[idx_rect.tops]
    pb = maxgrid.bottoms[idx_rect.bottoms]

    l = left(bbox_cell)
    r = right(bbox_cell)
    b = bottom(bbox_cell)
    t = top(bbox_cell)

    if side isa Inner
        bbox_cell
    elseif side isa Outer
        BBox(l - pl, r + pr, b - pb, t + pt)
    elseif side isa Left
        BBox(l - pl, l, b, t)
    elseif side isa Top
        BBox(l, r, t, t + pt)
    elseif side isa Right
        BBox(r, r + pr, b, t)
    elseif side isa Bottom
        BBox(l, r, b - pb, b)
    elseif side isa TopLeft
        BBox(l - pl, l, t, t + pt)
    elseif side isa TopRight
        BBox(r, r + pr, t, t + pt)
    elseif side isa BottomRight
        BBox(r, r + pr, b - pb, b)
    elseif side isa BottomLeft
        BBox(l - pl, l, b - pb, b)
    else
        error("Invalid side $side")
    end
end

startside(c::Col) = Left()
stopside(c::Col) = Right()
startside(r::Row) = Top()
stopside(r::Row) = Bottom()


getspan(gc::GridContent, dir::Col) = gc.span.cols
getspan(gc::GridContent, dir::Row) = gc.span.rows



"""
Determine the size of a protrusion layout along a dimension. This size is dependent
on the `Side` at which the layout is placed in its parent grid. An `Inside` side
means that the protrusion layout reports its width but not its protrusions. `Left`
means that the layout reports only its full width but not its height, because
an element placed in the left protrusion loses its ability to influence height.
"""
function determinedirsize(content, gdir::GridDir, side::Side)
    reportedsize = reportedsizeobservable(content)
    if gdir isa Row
        if side isa Union{Inner, Top, Bottom, TopLeft, TopRight, BottomLeft, BottomRight}
            # TODO: is reportedsize the correct thing to return? or plus protrusions depending on the side
            ifnothing(reportedsize[][2], nothing)
        elseif side isa Union{Left, Right}
            nothing
        else
            error("$side not implemented")
        end
    else
        if side isa Union{Inner, Left, Right, TopLeft, TopRight, BottomLeft, BottomRight}
            ifnothing(reportedsize[][1], nothing)
        elseif side isa Union{Top, Bottom}
            nothing
        else
            error("$side not implemented")
        end
    end
end

function to_ranges(g::GridLayout, rows::Indexables, cols::Indexables)
    if rows isa Int
        rows = rows:rows
    elseif rows isa Colon
        rows = 1:g.nrows
    end
    if cols isa Int
        cols = cols:cols
    elseif cols isa Colon
        cols = 1:g.ncols
    end
    rows, cols
end

function adjust_rows_cols!(g::GridLayout, rows, cols; update = true)
    rows, cols = to_ranges(g, rows, cols)

    if rows.start < 1
        n = 1 - rows.start
        prependrows!(g, n, update = update)
        # adjust rows for the newly prepended ones
        rows = rows .+ n
    end
    if rows.stop > g.nrows
        n = rows.stop - g.nrows
        appendrows!(g, n, update = update)
    end
    if cols.start < 1
        n = 1 - cols.start
        prependcols!(g, n, update = update)
        # adjust cols for the newly prepended ones
        cols = cols .+ n
    end
    if cols.stop > g.ncols
        n = cols.stop - g.ncols
        appendcols!(g, n, update = update)
    end

    rows, cols
end
