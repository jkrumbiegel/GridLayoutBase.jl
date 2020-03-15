mutable struct DebugRect
    layoutobservables::GridLayoutBase.LayoutObservables
    width::Observable
    height::Observable
    halign::Observable
    valign::Observable
    leftprot::Observable
    rightprot::Observable
    bottomprot::Observable
    topprot::Observable
end

# function default_attributes(T::Type{DebugRect})
#     Attributes(
#         height = nothing,
#         width = nothing,
#         halign = :center,
#         valign = :center,
#         topprot = 0,
#         leftprot = 0,
#         rightprot = 0,
#         bottomprot = 0
#     )
# end

observablify(x::Observable) = x
observablify(x, type=Any) = Observable{type}(x)

function DebugRect(; bbox = nothing, width=nothing, height=nothing, halign=:center,
    valign=:center, topprot=0.0, leftprot=0.0, rightprot=0.0, bottomprot=0.0)

    width = observablify(width)
    height = observablify(height)
    halign = observablify(halign)
    valign = observablify(valign)
    topprot = observablify(topprot, Float32)
    leftprot = observablify(leftprot, Float32)
    rightprot = observablify(rightprot, Float32)
    bottomprot = observablify(bottomprot, Float32)

    protrusions::Observable{GridLayoutBase.RectSides{Float32}} = map(leftprot, rightprot, bottomprot, topprot) do l, r, b, t
        GridLayoutBase.RectSides{Float32}(l, r, b, t)
    end

    layoutobservables = GridLayoutBase.LayoutObservables(DebugRect, width, height, halign, valign; suggestedbbox = bbox, protrusions = protrusions)

    # # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    DebugRect(layoutobservables, height, width, halign, valign, leftprot, rightprot, bottomprot, topprot)
end
