function LayoutObservables(T::Type, width::Observable, height::Observable, halign::Observable, valign::Observable;
        suggestedbbox = nothing,
        protrusions = nothing,
        computedsize = nothing,
        autosize = nothing,
        computedbbox = nothing,
        gridcontent = nothing)

    sizeobservable = sizeobservable!(width, height)
    alignment = map(tuple, halign, valign)

    suggestedbbox_observable = create_suggested_bboxobservable(suggestedbbox)
    protrusions = create_protrusions(protrusions)
    autosizeobservable = Observable{NTuple{2, Optional{Float32}}}((nothing, nothing))
    computedsize = computedsizeobservable!(sizeobservable, autosizeobservable)
    finalbbox = alignedbboxobservable!(suggestedbbox_observable, computedsize, alignment, sizeobservable, autosizeobservable)

    LayoutObservables{T, GridLayout}(suggestedbbox_observable, protrusions, computedsize, autosizeobservable, finalbbox, nothing)
end


create_suggested_bboxobservable(n::Nothing) = Observable(BBox(0, 100, 0, 100))
create_suggested_bboxobservable(tup::Tuple) = Observable(BBox(tup...))
create_suggested_bboxobservable(bbox::Rect{2}) = Observable(FRect2D(bbox))
create_suggested_bboxobservable(observable::Observable{FRect2D}) = observable

create_protrusions(p::Nothing) = Observable(RectSides{Float32}(0, 0, 0, 0))
create_protrusions(p::Observable{RectSides{Float32}}) = p
create_protrusions(p::RectSides{Float32}) = Observable(p)


function sizeobservable!(widthattr::Observable, heightattr::Observable)
    sizeattrs = Observable{Tuple{Any, Any}}((widthattr[], heightattr[]))
    onany(widthattr, heightattr) do w, h
        sizeattrs[] = (w, h)
    end
    sizeattrs
end

function computedsizeobservable!(sizeattrs, autosizeobservable::Observable{NTuple{2, Optional{Float32}}})

    # set up csizeobservable with correct type manually
    csizeobservable = Observable{NTuple{2, Optional{Float32}}}((nothing, nothing))

    onany(sizeattrs, autosizeobservable) do sizeattrs, autosize

        wattr, hattr = sizeattrs
        wauto, hauto = autosize

        wsize = computed_size(wattr, wauto)
        hsize = computed_size(hattr, hauto)

        csizeobservable[] = (wsize, hsize)
    end

    # trigger first value
    sizeattrs[] = sizeattrs[]

    csizeobservable
end

function computed_size(sizeattr, autosize)
    ms = @match sizeattr begin
        sa::Nothing => nothing
        sa::Real => sa
        sa::Fixed => sa.x
        sa::Relative => nothing
        sa::Auto => if sa.trydetermine
                # if trydetermine we report the autosize to the layout
                autosize
            else
                # but not if it's false, this allows for single span content
                # not to shrink its column or row, like a small legend next to an
                # axis or a super title over a single axis
                nothing
            end
        sa => error("""
            Invalid size attribute $sizeattr.
            Can only be Nothing, Fixed, Relative, Auto or Real""")
    end
end


function alignedbboxobservable!(
    suggestedbbox::Observable{FRect2D},
    computedsize::Observable{NTuple{2, Optional{Float32}}},
    alignment::Observable,
    sizeattrs::Observable,
    autosizeobservable::Observable{NTuple{2, Optional{Float32}}})

    finalbbox = Observable(BBox(0, 100, 0, 100))

    onany(suggestedbbox, alignment, computedsize) do sbbox, al, csize

        bw = width(sbbox)
        bh = height(sbbox)

        # we only passively retrieve sizeattrs here because if they change
        # they also trigger computedsize, which triggers this observable, too
        # we only need to know here if there are relative sizes given, because
        # those can only be computed knowing the suggestedbbox
        widthattr, heightattr = sizeattrs[]

        cwidth, cheight = csize

        w = if isnothing(cwidth)
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
                wa => error("At this point, if computed width is not known,
                widthattr should be a Relative or Nothing, not $wa.")
            end
        else
            cwidth
        end

        h = if isnothing(cheight)
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
                ha => error("At this point, if computed height is not known,
                heightattr should be a Relative or Nothing, not $ha.")
            end
        else
            cheight
        end

        # how much space is left in the bounding box
        rw = bw - w
        rh = bh - h

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

        # align the final bounding box in the layout bounding box
        l = left(sbbox) + xshift
        b = bottom(sbbox) + yshift
        r = l + w
        t = b + h

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
protrusionobservable(x) = layoutobservables(x).protrusions
suggestedbboxobservable(x) = layoutobservables(x).suggestedbbox
computedsizeobservable(x) = layoutobservables(x).computedsize
autosizeobservable(x) = layoutobservables(x).autosize
computedbboxobservable(x) = layoutobservables(x).computedbbox
gridcontent(x) = layoutobservables(x).gridcontent
