halign2shift(align::Number)::Float32 = Float32(align)
function halign2shift(align::Symbol)::Float32
    align == :left && return 0.0f0
    align == :center && return 0.5f0
    align == :right && return 1.0f0
    error("Invalid horizontal alignment $align (only Real or :left, :center, or :right allowed).")
end

valign2shift(align::Number)::Float32 = Float32(align)
function valign2shift(align::Symbol)::Float32
    align == :bottom && return 0.0f0
    align == :center && return 0.5f0
    align == :top && return 1.0f0
    error("Invalid vertical alignment $align (only Real or :bottom, :center, or :top allowed).")
end

function align_shift_tuple(halign::Union{Number, Symbol}, valign::Union{Number, Symbol})
    return (halign2shift(halign), valign2shift(valign))
end

function LayoutObservables{T}(width::Observable, height::Observable,
        tellwidth::Observable, tellheight::Observable, halign::Observable,
        valign::Observable, alignmode::Observable = Observable{AlignMode}(Inside());
        suggestedbbox = nothing,
        protrusions = nothing,
        reportedsize = nothing,
        autosize = nothing,
        computedbbox = nothing,
        gridcontent = nothing) where T

    sizeobservable = sizeobservable!(width, height)
    alignment = map(align_shift_tuple, halign, valign)

    suggestedbbox_observable = create_suggested_bboxobservable(suggestedbbox)
    protrusions = create_protrusions(protrusions)

    tellsizeobservable = map(tuple, tellwidth, tellheight)

    protrusions_after_alignmode = Observable(RectSides{Float32}(0, 0, 0, 0))
    onany(protrusions, alignmode) do prot, al
        protrusions_after_alignmode[] = aligned_protrusion(prot, al)
    end

    autosizeobservable = Observable{NTuple{2, Optional{Float32}}}((nothing, nothing))
    reportedsize = reportedsizeobservable!(sizeobservable, autosizeobservable, alignmode, protrusions, tellsizeobservable)
    finalbbox = alignedbboxobservable!(suggestedbbox_observable, reportedsize, alignment, sizeobservable, autosizeobservable,
        alignmode, protrusions)

    LayoutObservables{T, GridLayout}(suggestedbbox_observable, protrusions_after_alignmode, reportedsize, autosizeobservable, finalbbox, nothing)
end

maprectsides(f) = RectSides(map(f, (:left, :right, :bottom, :top))...)

function aligned_protrusion(prot, @nospecialize(al::AlignMode))
    if al isa Inside
        prot
    elseif al isa Outside
        RectSides{Float32}(0, 0, 0, 0)
    elseif al isa Mixed
        maprectsides() do side
            # normal inside mode
            if isnothing(getfield(al.sides, side))
                getfield(prot, side)
            # protrusion override
            elseif getfield(al.sides, side) isa Protrusion
                getfield(al.sides, side).p
            # outside mode
            else
                0f0
            end
        end
    end
end

create_suggested_bboxobservable(n::Nothing) = Observable(BBox(0, 100, 0, 100))
create_suggested_bboxobservable(tup::Tuple) = Observable(BBox(tup...))
create_suggested_bboxobservable(bbox::Rect{2}) = Observable(Rect2f(bbox))
create_suggested_bboxobservable(observable::Observable{Rect2f}) = observable
function create_suggested_bboxobservable(observable::Observable{<:Rect{2}})
    bbox = Observable(Rect2f(observable[]))
    on(observable) do o
        bbox[] = Rect2f(o)
    end
    bbox
end

create_protrusions(p::Nothing) = Observable(RectSides{Float32}(0, 0, 0, 0))
create_protrusions(p::Observable{RectSides{Float32}}) = p
create_protrusions(p::RectSides{Float32}) = Observable(p)


function sizeobservable!(@nospecialize(widthattr::Observable), @nospecialize(heightattr::Observable))
    sizeattrs = Observable{Tuple{Any, Any}}((widthattr[], heightattr[]))
    onany(widthattr, heightattr) do w, h
        sizeattrs[] = (w, h)
    end
    sizeattrs
end

function reportedsizeobservable!(sizeattrs, autosizeobservable::Observable{NTuple{2, Optional{Float32}}},
        alignmode, protrusions, tellsizeobservable)

    # set up rsizeobservable with correct type manually
    rsizeobservable = Observable{NTuple{2, Optional{Float32}}}((nothing, nothing))

    onany(sizeattrs, autosizeobservable, alignmode, protrusions, tellsizeobservable) do sizeattrs::Tuple{SizeAttribute,SizeAttribute},
            autosize, alignmode::AlignMode, protrusions, tellsizeobservable
        rsizeobservable[] = _reportedsizeobservable(sizeattrs, autosize, alignmode, protrusions, tellsizeobservable)
    end

    # trigger first value
    notify(sizeattrs)

    rsizeobservable
end

function _reportedsizeobservable(@nospecialize(sizeattrs::Tuple{SizeAttribute,SizeAttribute}), @nospecialize(autosize::Tuple{AutoSize,AutoSize}), @nospecialize(alignmode::AlignMode), protrusions, tellsizeobservable::Tuple{Bool,Bool})
    wattr, hattr = sizeattrs
    wauto, hauto = autosize
    tellw, tellh = tellsizeobservable

    wsize = computed_size(wattr, wauto, tellw)
    hsize = computed_size(hattr, hauto, tellh)

    return if alignmode isa Inside
        (wsize, hsize)
    elseif alignmode isa Outside
        (isnothing(wsize) ? nothing : wsize + protrusions.left + protrusions.right + alignmode.padding.left + alignmode.padding.right,
         isnothing(hsize) ? nothing : hsize + protrusions.top + protrusions.bottom + alignmode.padding.top + alignmode.padding.bottom)
    elseif alignmode isa Mixed
        w = if isnothing(wsize)
            nothing
        else
            w = wsize
            if alignmode.sides.left isa Float32
                w += protrusions.left + alignmode.sides.left
            elseif alignmode.sides.left isa Protrusion
                w += alignmode.sides.left.p
            end
            if alignmode.sides.right isa Float32
                w += protrusions.right + alignmode.sides.right
            elseif alignmode.sides.right isa Protrusion
                w += alignmode.sides.right.p
            end
            w
        end
        h = if isnothing(hsize)
            nothing
        else
            h = hsize
            if alignmode.sides.bottom isa Float32
                h += protrusions.bottom + alignmode.sides.bottom
            elseif alignmode.sides.bottom isa Protrusion
                h += alignmode.sides.bottom.p
            end
            if alignmode.sides.top isa Float32
                h += protrusions.top + alignmode.sides.top
            elseif alignmode.sides.top isa Protrusion
                h += alignmode.sides.top.p
            end
            h
        end
        (w, h)
    else
        error("Unknown alignmode $alignmode")
    end
end

function computed_size(sizeattr, autosize, tellsize)

    if !tellsize
        return nothing
    end

    if sizeattr === nothing
        nothing
    elseif sizeattr isa Real
        Float32(sizeattr)
    elseif sizeattr isa Fixed
        sizeattr.x
    elseif sizeattr isa Relative
        nothing
    elseif sizeattr isa Auto
        autosize
    else
        error("""
            Invalid size attribute $sizeattr.
            Can only be Nothing, Fixed, Relative, Auto or Real""")
    end
end


function alignedbboxobservable!(
    suggestedbbox::Observable{Rect2f},
    reportedsize::Observable{NTuple{2, Optional{Float32}}},
    alignment::Observable,
    sizeattrs::Observable,
    autosizeobservable::Observable{NTuple{2, Optional{Float32}}},
    alignmode, protrusions)

    finalbbox = Observable(BBox(0, 100, 0, 100))

    onany(suggestedbbox, alignment, reportedsize) do sbbox, al, rsize

        bw = width(sbbox)
        bh = height(sbbox)

        # we only passively retrieve sizeattrs here because if they change
        # they also trigger reportedsize, which triggers this observable, too
        # we only need to know here if there are relative sizes given, because
        # those can only be computed knowing the suggestedbbox
        widthattr, heightattr = sizeattrs[]
        prot = protrusions[]
        T = eltype(prot)

        cwidth, cheight = rsize
        w_target = T(if isnothing(cwidth)
            if widthattr isa Relative
                widthattr.x * bw
            elseif widthattr isa Nothing
                bw
            elseif widthattr isa Auto
                if isnothing(autosizeobservable[][1])
                    # we have no autowidth available anyway
                    # take suggested width
                    bw
                else
                    # use the width that was auto-computed
                    autosizeobservable[][1]
                end
            elseif widthattr isa Fixed
                widthattr.x
            elseif widthattr isa Real
                Float32(widthattr)
            else
                error("Unknown width attribute $widthattr")
            end
        else
            cwidth
        end)::T

        h_target = T(if isnothing(cheight)
            if heightattr isa Relative
                heightattr.x * bh
            elseif heightattr isa Nothing
                bh
            elseif heightattr isa Auto
                if isnothing(autosizeobservable[][2])
                    # we have no autoheight available anyway
                    # take suggested height
                    bh
                else
                    # use the height that was auto-computed
                    autosizeobservable[][2]
                end
            elseif heightattr isa Fixed
                heightattr.x
            elseif heightattr isa Real
                Float32(heightattr)
            else
                error("Unknown height attribute $heightattr")
            end
        else
            cheight
        end)::T

        am = alignmode[]
        inner_w, inner_h = if am isa Inside
            (w_target, h_target)
        elseif am isa Outside
            (w_target - prot.left - prot.right - am.padding.left - am.padding.right,
             h_target - prot.top - prot.bottom - am.padding.top - am.padding.bottom)
        else
            am = am::Mixed
            let
                w = w_target
                # subtract if outside padding is used via a Float32 value
                # Protrusion and `nothing` are protrusion modes
                if am.sides.left isa Float32
                    w -= prot.left + am.sides.left
                end
                if am.sides.right isa Float32
                    w -= prot.right + am.sides.right
                end

                h = h_target
                if am.sides.bottom isa Float32
                    h -= prot.bottom + am.sides.bottom
                end
                if am.sides.top isa Float32
                    h -= prot.top + am.sides.top
                end

                w, h
            end
        end

        # how much space is left in the bounding box
        rw = bw - w_target
        rh = bh - h_target

        xshift, yshift = al .* (rw, rh)

        if am isa Inside
            # width and height are unaffected
        elseif am isa Outside
            xshift = xshift + prot.left + am.padding.left
            yshift = yshift + prot.bottom + am.padding.bottom
        else
            am = am::Mixed
            if am.sides.left isa Float32
                xshift += prot.left + am.sides.left
            end
            if am.sides.bottom isa Float32
                yshift += prot.bottom + am.sides.bottom
            end
        end

        # align the final bounding box in the layout bounding box
        l = left(sbbox) + xshift
        b = bottom(sbbox) + yshift
        r = l + inner_w
        t = b + inner_h
        newbbox = BBox(l, r, b, t)
        # if finalbbox[] != newbbox
        #     finalbbox[] = newbbox
        # end
        finalbbox[] = newbbox
    end

    finalbbox
end

"""
    layoutobservables(x::T) where T

Access `x`'s field `:layoutobservables` containing a `LayoutObservables` instance. This should
be overloaded for any type that is layoutable but stores its `LayoutObservables` in
a differently named field.
"""
function layoutobservables(x::T) where T
    if hasfield(T, :layoutobservables) && fieldtype(T, :layoutobservables) <: LayoutObservables
        x.layoutobservables
    else
        error("It's not defined how to get LayoutObservables for type $T, overload this method for layoutable types.")
    end
end

# These are the default API functions to retrieve the layout parts from an object
protrusionsobservable(x) = layoutobservables(x).protrusions
suggestedbboxobservable(x) = layoutobservables(x).suggestedbbox
reportedsizeobservable(x) = layoutobservables(x).reportedsize
autosizeobservable(x) = layoutobservables(x).autosize
computedbboxobservable(x) = layoutobservables(x).computedbbox
gridcontent(x) = layoutobservables(x).gridcontent
