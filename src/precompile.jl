using InteractiveUtils

const Emptykwargs = Base.Iterators.Pairs{Union{}, Union{}, Tuple{}, NamedTuple{(), Tuple{}}}

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    precompile(BBox, (Float32, Float32, Float64, Float64))

    precompile(GridLayout, (Int, Int))
    precompile(GridLayout, (GridLayoutSpec,))
    precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox,), Tuple{Observable{IRect2D}}}, Type{GridLayout}))
    precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox,), Tuple{FRect2D}}, Type{GridLayout}))
    # Also precompile `GridLayout(bbox = bbox, alignmode = al)` and the keyword body method
    fbody = isdefined(Base, :bodyfunction) ? Base.bodyfunction(which(GridLayout, (Int, Int))) : nothing
    for Al in (Inside, Outside, Mixed)
        precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox, :alignmode), Tuple{FRect2D, Al}}, Type{GridLayout}))
        precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox, :alignmode), Tuple{Observable{FRect2D}, Al}}, Type{GridLayout}))
        precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox, :alignmode), Tuple{NTuple{4,Int}, Al}}, Type{GridLayout}))
        if fbody !== nothing
            precompile(fbody, (Nothing, Nothing, Nothing, Nothing, Al, Tuple{Bool, Bool}, FRect2D, Auto, Auto, Bool, Bool, Symbol, Symbol, Float64, Float64, Emptykwargs, Type{GridLayout}, Int, Int))
        end
    end
    precompile(Core.kwfunc(GridLayout), (NamedTuple{(:colsizes, :rowsizes), Tuple{Fixed, Relative}}, Type{GridLayout}, Int, Int))
    precompile(Core.kwfunc(GridLayout), (NamedTuple{(:addedcolgaps,), Tuple{Vector{Fixed}}}, Type{GridLayout}, Int, Int))

    precompile(Core.kwfunc(Mixed), (NamedTuple{(:left, :top), Tuple{Int, Int}}, Type{Mixed}))
    for T in (Int, Float32)
        precompile(Outside, (T,))
        precompile(Outside, (T,T,T,T))
    end
    precompile(align_to_bbox!, (GridLayout, FRect2D))
    precompile(update_gl!, (GridLayout,))
    for I in subtypes(Indexables), J in subtypes(Indexables)
        precompile(setindex!, (GridLayout, UnitRange{Int}, I, J))
        precompile(setindex!, (GridLayout, Any, I, J))
    end
    precompile(insertrows!, (GridLayout, Int, Int))
    precompile(insertcols!, (GridLayout, Int, Int))
    precompile(gridnest!, (GridLayout, UnitRange{Int}, UnitRange{Int}))
    precompile(add_to_gridlayout!, (GridLayout, GridContent{GridLayout, GridLayout}))
    precompile(connect_layoutobservables!, (GridContent{GridLayout, GridLayout},))
    precompile(trim!, (GridLayout,))
    precompile(sizeobservable!, (Observable{Any}, Observable{Any}))
    precompile(_reportedsizeobservable, (Tuple{SizeAttribute,SizeAttribute}, Tuple{AutoSize,AutoSize}, AlignMode, RectSides{Float32}, Tuple{Bool,Bool}))
    for T in subtypes(Side)
        precompile(bbox_for_solving_from_side, (RowCols{Vector{Float64}}, FRect2D, RowCols{Int}, T))
    end
    for S in (Left, Right, Top, Bottom)
        precompile(protrusion, (GridContent{GridLayout,GridLayout}, S))
    end
    precompile(suggestedbboxobservable, (GridLayout,))
    for VC in (Vector{Auto}, Vector{GapSize}, Vector{Fixed}, Vector{Relative}, Vector{ContentSize})
        precompile(convert_contentsizes, (Int, VC))
        precompile(==, (VC, VC))
    end
    precompile(contents, (GridLayout,))
    precompile(filterenum, (Function, Type, Vector{ContentSize}))
    precompile(zcumsum, (Vector{Float64},))

    # These don't work completely but they have partial success
    precompile(repr, (MIME{Symbol("text/plain")}, GridLayout))
end
