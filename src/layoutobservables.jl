function LayoutObservables(T::Type, width::Observable, height::Observable,
        tellwidth::Observable, tellheight::Observable, halign::Observable,
        valign::Observable, alignmode::Observable = Observable{AlignMode}(Inside());
        suggestedbbox = nothing,
        protrusions = nothing,
        reportedsize = nothing,
        autosize = nothing,
        computedbbox = nothing,
        gridcontent = nothing)

    sizeobservable = sizeobservable!(width, height)
    alignment = map(tuple, halign, valign)

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
    else
        maprectsides() do side
            if isnothing(getfield(al.padding, side))
                getfield(prot, side)
            else
                0f0
            end
        end
    end
end

create_suggested_bboxobservable(n::Nothing) = Observable(BBox(0, 100, 0, 100))
create_suggested_bboxobservable(tup::Tuple) = Observable(BBox(tup...))
create_suggested_bboxobservable(bbox::Rect{2}) = Observable(FRect2D(bbox))
create_suggested_bboxobservable(observable::Observable{FRect2D}) = observable
function create_suggested_bboxobservable(observable::Observable{<:Rect{2}})
    bbox = Observable(FRect2D(observable[]))
    on(observable) do o
        bbox[] = FRect2D(o)
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
    sizeattrs[] = sizeattrs[]

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
    else
        w = if isnothing(wsize)
            nothing
        else
            w = wsize
            if !isnothing(alignmode.padding.left)
                w += protrusions.left + alignmode.padding.left
            end
            if !isnothing(alignmode.padding.right)
                w += protrusions.right + alignmode.padding.right
            end
            w
        end
        h = if isnothing(hsize)
            nothing
        else
            h = hsize
            if !isnothing(alignmode.padding.bottom)
                h += protrusions.bottom + alignmode.padding.bottom
            end
            if !isnothing(alignmode.padding.top)
                h += protrusions.top + alignmode.padding.top
            end
            h
        end
        (w, h)
    end
end

function computed_size(sizeattr, autosize, tellsize)

    if !tellsize
        return nothing
    end

    ms = @match sizeattr begin
        sa::Nothing => nothing
        sa::Real => sa
        sa::Fixed => sa.x
        sa::Relative => nothing
        sa::Auto => autosize
        sa => error("""
            Invalid size attribute $sizeattr.
            Can only be Nothing, Fixed, Relative, Auto or Real""")
    end
end


function alignedbboxobservable!(
    suggestedbbox::Observable{FRect2D},
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

        cwidth, cheight = rsize
        w_target = if isnothing(cwidth)
            @match widthattr begin
                wa::Relative => wa.x * bw
                wa::Nothing => bw
                wa::Auto => if isnothing(autosizeobservable[][1])
                        # we have no autowidth available anyway
                        # take suggested width
                        bw
                    else
                        # use the width that was auto-computed
                        autosizeobservable[][1]
                    end
                wa::Fixed => wa.x
                wa::Real => wa
                wa => error("Unknown width attribute $wa")
            end
        else
            cwidth
        end

        h_target = if isnothing(cheight)
            @match heightattr begin
                ha::Relative => ha.x * bh
                ha::Nothing => bh
                ha::Auto => if isnothing(autosizeobservable[][2])
                        # we have no autoheight available anyway
                        # take suggested height
                        bh
                    else
                        # use the height that was auto-computed
                        autosizeobservable[][2]
                    end
                ha::Fixed => ha.x
                ha::Real => ha
                ha => error("Unknown height attribute $ha")
            end
        else
            cheight
        end

        inner_w, inner_h = if alignmode[] isa Inside
            (w_target, h_target)
        elseif alignmode[] isa Outside
            (w_target - protrusions[].left - protrusions[].right - alignmode[].padding.left - alignmode[].padding.right,
             h_target - protrusions[].top - protrusions[].bottom - alignmode[].padding.top - alignmode[].padding.bottom)
        else
            let
                w = w_target
                if !isnothing(alignmode[].padding.left)
                    w -= protrusions[].left + alignmode[].padding.left
                end
                if !isnothing(alignmode[].padding.right)
                    w -= protrusions[].right + alignmode[].padding.right
                end

                h = h_target
                if !isnothing(alignmode[].padding.bottom)
                    h -= protrusions[].bottom + alignmode[].padding.bottom
                end
                if !isnothing(alignmode[].padding.top)
                    h -= protrusions[].top + alignmode[].padding.top
                end

                w, h
            end
        end

        # how much space is left in the bounding box
        rw = bw - w_target
        rh = bh - h_target

        xshift = @match al[1] begin
            :left => 0.0f0
            :center => 0.5f0 * rw
            :right => rw
            x::Real => x * rw
            x => error("Invalid horizontal alignment $x (only Real or :left, :center, or :right allowed).")
        end

        yshift = @match al[2] begin
            :bottom => 0.0f0
            :center => 0.5f0 * rh
            :top => rh
            x::Real => x * rh
            x => error("Invalid vertical alignment $x (only Real or :bottom, :center, or :top allowed).")
        end

        if alignmode[] isa Inside
            # width and height are unaffected
        elseif alignmode[] isa Outside
            xshift = xshift + protrusions[].left + alignmode[].padding.left
            yshift = yshift + protrusions[].bottom + alignmode[].padding.bottom
        else
            if !isnothing(alignmode[].padding.left)
                xshift += protrusions[].left + alignmode[].padding.left
            end
            if !isnothing(alignmode[].padding.bottom)
                yshift += protrusions[].bottom + alignmode[].padding.bottom
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
