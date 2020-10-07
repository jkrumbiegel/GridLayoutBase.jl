using InteractiveUtils

const Emptykwargs = Base.Iterators.Pairs{Union{}, Union{}, Tuple{}, NamedTuple{(), Tuple{}}}

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    @assert precompile(BBox, (Float32, Float32, Float64, Float64))

    @assert precompile(GridLayout, (Int, Int))
    @assert precompile(GridLayout, (GridLayoutSpec,))
    @assert precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox,), Tuple{Observable{IRect2D}}}, Type{GridLayout}))
    @assert precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox,), Tuple{FRect2D}}, Type{GridLayout}))
    # Also precompile `GridLayout(bbox = bbox, alignmode = al)` and the keyword body method
    fbody = isdefined(Base, :bodyfunction) ? Base.bodyfunction(which(GridLayout, (Int, Int))) : nothing
    for Al in (Inside, Outside, Mixed)
        @assert precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox, :alignmode), Tuple{FRect2D, Al}}, Type{GridLayout}))
        @assert precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox, :alignmode), Tuple{Observable{FRect2D}, Al}}, Type{GridLayout}))
        @assert precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox, :alignmode), Tuple{NTuple{4,Int}, Al}}, Type{GridLayout}))
        if fbody !== nothing
            @assert precompile(fbody, (Nothing, Nothing, Nothing, Nothing, Al, Tuple{Bool, Bool}, FRect2D, Auto, Auto, Bool, Bool, Symbol, Symbol, Float64, Float64, Emptykwargs, Type{GridLayout}, Int, Int))
        end
    end
    @assert precompile(Core.kwfunc(GridLayout), (NamedTuple{(:colsizes, :rowsizes), Tuple{Fixed, Relative}}, Type{GridLayout}, Int, Int))
    @assert precompile(Core.kwfunc(GridLayout), (NamedTuple{(:addedcolgaps,), Tuple{Vector{Fixed}}}, Type{GridLayout}, Int, Int))

    @assert precompile(Core.kwfunc(Mixed), (NamedTuple{(:left, :top), Tuple{Int, Int}}, Type{Mixed}))
    for T in (Int, Float32)
        @assert precompile(Outside, (T,))
        @assert precompile(Outside, (T,T,T,T))
    end
    @assert precompile(align_to_bbox!, (GridLayout, FRect2D))
    @assert precompile(update_gl!, (GridLayout,))
    for I in subtypes(Indexables), J in subtypes(Indexables)
        @assert precompile(setindex!, (GridLayout, UnitRange{Int}, I, J))
        @assert precompile(setindex!, (GridLayout, Any, I, J))
    end
    @assert precompile(insertrows!, (GridLayout, Int, Int))
    @assert precompile(insertcols!, (GridLayout, Int, Int))
    @assert precompile(gridnest!, (GridLayout, UnitRange{Int}, UnitRange{Int}))
    @assert precompile(add_to_gridlayout!, (GridLayout, GridContent{GridLayout, GridLayout}))
    @assert precompile(connect_layoutobservables!, (GridContent{GridLayout, GridLayout},))
    @assert precompile(trim!, (GridLayout,))
    @assert precompile(sizeobservable!, (Observable{Any}, Observable{Any}))
    @assert precompile(_reportedsizeobservable, (Tuple{SizeAttribute,SizeAttribute}, Tuple{AutoSize,AutoSize}, AlignMode, RectSides{Float32}, Tuple{Bool,Bool}))
    for T in subtypes(Side)
        @assert precompile(bbox_for_solving_from_side, (RowCols{Vector{Float64}}, FRect2D, RowCols{Int}, T))
    end
    for S in (Left, Right, Top, Bottom)
        @assert precompile(protrusion, (GridContent{GridLayout,GridLayout}, S))
    end
    @assert precompile(suggestedbboxobservable, (GridLayout,))
    for VC in (Vector{Auto}, Vector{GapSize}, Vector{Fixed}, Vector{Relative}, Vector{ContentSize})
        @assert precompile(convert_contentsizes, (Int, VC))
        @assert precompile(==, (VC, VC))
    end
    @assert precompile(contents, (GridLayout,))
    @assert precompile(filterenum, (Function, Type, Vector{ContentSize}))
    @assert precompile(zcumsum, (Vector{Float64},))

    # These don't work completely but they have partial success
    @assert precompile(repr, (MIME{Symbol("text/plain")}, GridLayout))
end
