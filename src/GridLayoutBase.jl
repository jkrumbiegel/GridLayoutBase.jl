module GridLayoutBase

using GeometryBasics
using Observables
using Match

const DEFAULT_COLGAP = Ref{Any}(20.0)
const DEFAULT_ROWGAP = Ref{Any}(20.0)
# These function refs can be mutated by other packages to override the default
# way of retrieving default column and row gap sizes
const DEFAULT_ROWGAP_GETTER = Ref{Function}(() -> DEFAULT_ROWGAP[])
const DEFAULT_COLGAP_GETTER = Ref{Function}(() -> DEFAULT_COLGAP[])

include("types.jl")
include("gridlayout.jl")
include("layout_engine.jl")
include("layoutobservables.jl")
include("gridapi.jl")
include("helpers.jl")
include("geometry_integration.jl")
include("gridlayoutspec.jl")

export GridLayout, GridPosition
export GridLayoutSpec
export BBox
export LayoutObservables
export Inside, Outside, Mixed, Protrusion
export Fixed, Auto, Relative, Aspect
export width, height, top, bottom, left, right
export with_updates_suspended
export appendcols!, appendrows!, prependcols!, prependrows!, deletecol!, deleterow!, trim!, insertrows!, insertcols!
export gridnest!
export AxisAspect, DataAspect
export colsize!, rowsize!, colgap!, rowgap!
export Left, Right, Top, Bottom, TopLeft, BottomLeft, TopRight, BottomRight
export grid!, hbox!, vbox!
export swap!
export protrusionsobservable, suggestedbboxobservable, reportedsizeobservable, autosizeobservable, computedbboxobservable, gridcontent
export ncols, nrows
export contents, content

if Base.VERSION >= v"1.4.2"
    include("precompile.jl")
    _precompile_()
end

end
