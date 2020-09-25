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
    @assert precompile(trim!, (GridLayout,))
    @assert precompile(sizeobservable!, (Observable{Any}, Observable{Any}))
    for SizeAttrs in (Tuple{Auto,Auto}, Tuple{Nothing,Nothing}, Tuple{Fixed,Nothing}, Tuple{Int,Nothing}, Tuple{Nothing,Int}, Tuple{Int,Int})
        for AutoSize in (Tuple{Nothing,Nothing}, Tuple{Float32,Float32})
            @assert precompile(_reportedsizeobservable, (SizeAttrs, AutoSize, Inside, RectSides{Float32}, Tuple{Bool,Bool}))
        end
    end
end
