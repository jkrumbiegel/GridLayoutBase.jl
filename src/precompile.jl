using InteractiveUtils

const Emptykwargs = Base.Iterators.Pairs{Union{}, Union{}, Tuple{}, NamedTuple{(), Tuple{}}}

macro warnpcfail(ex::Expr)
    modl = __module__
    file = __source__.file === nothing ? "?" : String(__source__.file)
    line = __source__.line
    quote
        $(esc(ex)) || @warn """precompile directive
     $($(Expr(:quote, ex)))
 failed. Please report an issue in $($modl) (after checking for duplicates) or remove this directive.""" _file=$file _line=$line
    end
end

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    @warnpcfail precompile(BBox, (Float32, Float32, Float64, Float64))

    @warnpcfail precompile(GridLayout, (Int, Int))
    @warnpcfail precompile(GridLayout, (GridLayoutSpec,))
    @warnpcfail precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox,), Tuple{Observable{Rect2i}}}, Type{GridLayout}))
    @warnpcfail precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox,), Tuple{Rect2f}}, Type{GridLayout}))
    # Also precompile `GridLayout(bbox = bbox, alignmode = al)` and the keyword body method
    fbody = isdefined(Base, :bodyfunction) ? Base.bodyfunction(which(GridLayout, (Int, Int))) : nothing
    for Al in (Inside, Outside, Mixed)
        @warnpcfail precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox, :alignmode), Tuple{Rect2f, Al}}, Type{GridLayout}))
        @warnpcfail precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox, :alignmode), Tuple{Observable{Rect2f}, Al}}, Type{GridLayout}))
        @warnpcfail precompile(Core.kwfunc(GridLayout), (NamedTuple{(:bbox, :alignmode), Tuple{NTuple{4,Int}, Al}}, Type{GridLayout}))
        # if fbody !== nothing
        #     @warnpcfail precompile(fbody, (Nothing, Nothing, Nothing, Nothing, Nothing, Al, Tuple{Bool, Bool}, Rect2f, Auto, Auto, Bool, Bool, Symbol, Symbol, Float64, Float64, Emptykwargs, Type{GridLayout}, Int, Int))
        # end
    end
    @warnpcfail precompile(Core.kwfunc(GridLayout), (NamedTuple{(:colsizes, :rowsizes), Tuple{Fixed, Relative}}, Type{GridLayout}, Int, Int))
    @warnpcfail precompile(Core.kwfunc(GridLayout), (NamedTuple{(:addedcolgaps,), Tuple{Vector{Fixed}}}, Type{GridLayout}, Int, Int))

    @warnpcfail precompile(Core.kwfunc(Mixed), (NamedTuple{(:left, :top), Tuple{Int, Int}}, Type{Mixed}))
    for T in (Int, Float32)
        @warnpcfail precompile(Outside, (T,))
        @warnpcfail precompile(Outside, (T,T,T,T))
    end
    @warnpcfail precompile(align_to_bbox!, (GridLayout, Rect2f))
    @warnpcfail precompile(update!, (GridLayout,))
    for I in subtypes(Indexables), J in subtypes(Indexables)
        @warnpcfail precompile(setindex!, (GridLayout, UnitRange{Int}, I, J))
        @warnpcfail precompile(setindex!, (GridLayout, Any, I, J))
    end
    @warnpcfail precompile(insertrows!, (GridLayout, Int, Int))
    @warnpcfail precompile(insertcols!, (GridLayout, Int, Int))
    @warnpcfail precompile(gridnest!, (GridLayout, UnitRange{Int}, UnitRange{Int}))
    @warnpcfail precompile(add_to_gridlayout!, (GridLayout, GridContent{GridLayout, GridLayout}))
    @warnpcfail precompile(connect_layoutobservables!, (GridContent{GridLayout, GridLayout},))
    @warnpcfail precompile(trim!, (GridLayout,))
    @warnpcfail precompile(sizeobservable!, (Observable{Any}, Observable{Any}))
    @warnpcfail precompile(_reportedsizeobservable, (Tuple{SizeAttribute,SizeAttribute}, Tuple{AutoSize,AutoSize}, AlignMode, RectSides{Float32}, Tuple{Bool,Bool}))
    for T in subtypes(Side)
        @warnpcfail precompile(bbox_for_solving_from_side, (RowCols{Vector{Float32}}, Rect2f, RowCols{Int}, T))
    end
    for S in (Left, Right, Top, Bottom)
        @warnpcfail precompile(protrusion, (GridContent{GridLayout,GridLayout}, S))
    end
    @warnpcfail precompile(suggestedbboxobservable, (GridLayout,))
    for VC in (Vector{Auto}, Vector{GapSize}, Vector{Fixed}, Vector{Relative}, Vector{ContentSize})
        @warnpcfail precompile(convert_contentsizes, (Int, VC))
        @warnpcfail precompile(==, (VC, VC))
    end
    @warnpcfail precompile(contents, (GridLayout,))
    @warnpcfail precompile(filterenum, (Function, Type, Vector{ContentSize}))
    @warnpcfail precompile(zcumsum, (Vector{Float64},))

    # These don't work completely but they have partial success
    @warnpcfail precompile(repr, (MIME{Symbol("text/plain")}, GridLayout))
end
