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
ismostin(gc::GridContent, grid, side::Side) = side == Left ? (gc.span.cols.start == 1) :
                                              side == Right ? (gc.span.cols.stop == grid.ncols) :
                                              side == Bottom ? (gc.span.rows.stop == grid.nrows) :
                                              side == Top ? (gc.span.rows.start == 1) : throw_side(side)


function protrusion(x::T, side::Side) where T
    protrusions = protrusionsobservable(x)
    return side == Left ? protrusions[].left :
           side == Right ? protrusions[].right :
           side == Bottom ? protrusions[].bottom :
           side == Top ? protrusions[].top :
           error("Can't get a protrusion value for side $side, only Left, Right, Bottom, or Top.")
end

function protrusion(gc::GridContent, side::Side)
    gcside = gc.side
    prot = gcside == Inner ? protrusion(gc.content, side) :
           # gcside == Outer ? BBox(l - pl, r + pr, b - pb, t + pt) :
           gcside ∈ (Left, Right) ? (side == gcside ? determinedirsize(gc.content, Col, gcside) : 0.0) :
           gcside ∈ (Top, Bottom) ? (side == gcside ? determinedirsize(gc.content, Row, gcside) : 0.0) :
           gcside == TopLeft ? (side ∈ (Top, Left) ? determinedirsize(gc.content, GridDir(side), gcside) : 0.0) :
           gcside == TopRight ? (side ∈ (Top, Right) ? determinedirsize(gc.content, GridDir(side), gcside) : 0.0) :
           gcside == BottomLeft ? (side ∈ (Bottom, Left) ? determinedirsize(gc.content, GridDir(side), gcside) : 0.0) :
           gcside == BottomRight ? (side ∈ (Bottom, Right) ? determinedirsize(gc.content, GridDir(side), gcside) : 0.0) :
           throw_side(gcside)
    ifnothing(prot, 0.0)
end

function getside(m::Mixed, side::Side)
    msides = m.sides
    return side == Left ? msides.left :
           side == Right ? msides.right :
           side == Top ? msides.top :
           side == Bottom ? msides.bottom : throw_side(side)
end

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

    return side == Inner ? bbox_cell :
           side == Outer ? BBox(l - pl, r + pr, b - pb, t + pt) :
           side == Left ? BBox(l - pl, l, b, t) :
           side == Top ? BBox(l, r, t, t + pt) :
           side == Right ? BBox(r, r + pr, b, t) :
           side == Bottom ? BBox(l, r, b - pb, b) :
           side == TopLeft ? BBox(l - pl, l, t, t + pt) :
           side == TopRight ? BBox(r, r + pr, t, t + pt) :
           side == BottomRight ? BBox(r, r + pr, b - pb, b) :
           side == BottomLeft ? BBox(l - pl, l, b - pb, b) : throw_side(side)
end

startside(rc::GridDir) = rc == Row ? Top : Left
stopside(rc::GridDir) = rc == Row ? Bottom : Right


getspan(gc::GridContent, dir::GridDir) = dir == Col ? gc.span.cols : gc.span.rows



"""
Determine the size of a protrusion layout along a dimension. This size is dependent
on the `Side` at which the layout is placed in its parent grid. An `Inside` side
means that the protrusion layout reports its width but not its protrusions. `Left`
means that the layout reports only its full width but not its height, because
an element placed in the left protrusion loses its ability to influence height.
"""
determinedirsize(content, gdir::GridDir, side::Side) = _determinedirsize(reportedsizeobservable(content), gdir, side)
@noinline function _determinedirsize(reportedsize, gdir::GridDir, side::Side)
    if gdir == Row
        # TODO: is reportedsize the correct thing to return? or plus protrusions depending on the side
        side ∈ (Inner, Top, Bottom, TopLeft, TopRight, BottomLeft, BottomRight) ? reportedsize[][2] :
        side ∈ (Left, Right) ? nothing : throw_side(side)
    else
        side ∈ (Inner, Left, Right, TopLeft, TopRight, BottomLeft, BottomRight) ? reportedsize[][1] :
        side ∈ (Top, Bottom) ? nothing : throw_side(side)
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

function adjust_rows_cols!(g::GridLayout, rows::Indexables, cols::Indexables; update = true)
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
