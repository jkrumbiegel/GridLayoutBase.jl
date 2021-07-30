mutable struct DebugRect
    layoutobservables::GridLayoutBase.LayoutObservables{GridLayout}
    width::Observable{GridLayoutBase.SizeAttribute}
    height::Observable{GridLayoutBase.SizeAttribute}
    tellwidth::Observable{Bool}
    tellheight::Observable{Bool}
    halign::Observable{GridLayoutBase.AlignAttribute}
    valign::Observable{GridLayoutBase.AlignAttribute}
    leftprot::Observable{Float32}
    rightprot::Observable{Float32}
    bottomprot::Observable{Float32}
    topprot::Observable{Float32}
    alignmode::Observable{GridLayoutBase.AlignMode}
end

using GridLayoutBase: observablify, Observablify

function DebugRect(; bbox = nothing, width=nothing, height=nothing,
    tellwidth = true, tellheight = true, halign=:center,
    valign=:center, topprot=0.0, leftprot=0.0, rightprot=0.0, bottomprot=0.0,
    alignmode = Inside())

    width = observablify(width)
    height = observablify(height)
    tellwidth = observablify(tellwidth)
    tellheight = observablify(tellheight)
    halign = observablify(halign)
    valign = observablify(valign)
    topprot = Observablify{Float32}(topprot)
    leftprot = Observablify{Float32}(leftprot)
    rightprot = Observablify{Float32}(rightprot)
    bottomprot = Observablify{Float32}(bottomprot)
    alignmode = Observablify{GridLayoutBase.AlignMode}(alignmode)

    protrusions::Observable{GridLayoutBase.RectSides{Float32}} = map(leftprot, rightprot, bottomprot, topprot) do l, r, b, t
        GridLayoutBase.RectSides{Float32}(l, r, b, t)
    end

    layoutobservables = GridLayoutBase.LayoutObservables{GridLayout}(width,
        height, tellwidth, tellheight, halign, valign, alignmode;
        suggestedbbox = bbox, protrusions = protrusions)

    DebugRect(layoutobservables, height, width, tellwidth, tellheight,
        halign, valign, leftprot, rightprot, bottomprot, topprot, alignmode)
end

Base.show(io::IO, dr::DebugRect) = print(io, "DebugRect()")
