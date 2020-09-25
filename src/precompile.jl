using InteractiveUtils

const Emptykwargs = Base.Iterators.Pairs{Union{}, Union{}, Tuple{}, NamedTuple{(), Tuple{}}}

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    @assert precompile(GridLayout, (Int, Int))
    @assert precompile(GridLayout, (GridLayoutSpec,))
    # Also precompile `GridLayout(bbox = bbox, alignmode = al)` and the keyword body method
    fbody = isdefined(Base, :bodyfunction) ? Base.bodyfunction(which(GridLayout, (Int, Int))) : nothing
    for Al in (Inside, Outside, Mixed)
        @assert precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox, :alignmode), Tuple{FRect2D, Al}}, Type{GridLayout}))
        if fbody !== nothing
            @assert precompile(fbody, (Nothing, Nothing, Nothing, Nothing, Al, Tuple{Bool, Bool}, FRect2D, Auto, Auto, Bool, Bool, Symbol, Symbol, Float64, Float64, Emptykwargs, Type{GridLayout}, Int, Int))
        end
    end
    @assert precompile(Core.kwfunc(GridLayout), (NamedTuple{(:colsizes, :rowsizes), Tuple{Fixed, Relative}}, Type{GridLayout}, Int, Int))
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
    end
    @assert precompile(filterenum, (Function, Type, Vector{ContentSize}))
    @assert precompile(zcumsum, (Vector{Float64},))
end
