const __bodyfunction__ = Dict{Method,Any}()

# Find keyword "body functions" (the function that contains the body
# as written by the developer, called after all missing keyword-arguments
# have been assigned values), in a manner that doesn't depend on
# gensymmed names.
# `mnokw` is the method that gets called when you invoke it without
# supplying any keywords.
function __lookup_kwbody__(mnokw::Method)
    function getsym(arg)
        isa(arg, Symbol) && return arg
        @assert isa(arg, GlobalRef)
        return arg.name
    end

    f = get(__bodyfunction__, mnokw, nothing)
    if f === nothing
        fmod = mnokw.module
        # The lowered code for `mnokw` should look like
        #   %1 = mkw(kwvalues..., #self#, args...)
        #        return %1
        # where `mkw` is the name of the "active" keyword body-function.
        ast = Base.uncompressed_ast(mnokw)
        if isa(ast, Core.CodeInfo) && length(ast.code) >= 2
            callexpr = ast.code[end-1]
            if isa(callexpr, Expr) && callexpr.head == :call
                fsym = callexpr.args[1]
                if isa(fsym, Symbol)
                    f = getfield(fmod, fsym)
                elseif isa(fsym, GlobalRef)
                    if fsym.mod === Core && fsym.name === :_apply
                        f = getfield(mnokw.module, getsym(callexpr.args[2]))
                    elseif fsym.mod === Core && fsym.name === :_apply_iterate
                        f = getfield(mnokw.module, getsym(callexpr.args[3]))
                    else
                        f = getfield(fsym.mod, fsym.name)
                    end
                else
                    f = missing
                end
            else
                f = missing
            end
        else
            f = missing
        end
        __bodyfunction__[mnokw] = f
    end
    return f
end

function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    Base.precompile(Tuple{typeof(compute_rowcols),GridLayout,HyperRectangle{2, Float32}})   # time: 0.18981326
    Base.precompile(Tuple{typeof(compute_col_row_sizes),Float32,Float32,GridLayout})   # time: 0.12354037
    let fbody = try __lookup_kwbody__(which(LayoutObservables, (Observable{Union{Nothing, Float32, Auto, Fixed, Relative}},Observable{Union{Nothing, Float32, Auto, Fixed, Relative}},Observable{Bool},Observable{Bool},Observable{HorizontalAlignment},Observable{VerticalAlignment},Observable{AlignMode},))) catch missing end
        if !ismissing(fbody)
            precompile(fbody, (Nothing,Nothing,Nothing,Nothing,Nothing,Nothing,Type{LayoutObservables},Observable{Union{Nothing, Float32, Auto, Fixed, Relative}},Observable{Union{Nothing, Float32, Auto, Fixed, Relative}},Observable{Bool},Observable{Bool},Observable{HorizontalAlignment},Observable{VerticalAlignment},Observable{AlignMode},))
        end
    end   # time: 0.085338145
    Base.precompile(Tuple{typeof(determinedirsize),GridLayout,GridDir})   # time: 0.072233215
    Base.precompile(Tuple{typeof(disconnect_layoutobservables!),GridContent{GridLayout}})   # time: 0.029253284
    Base.precompile(Tuple{typeof(align_to_bbox!),GridLayout,HyperRectangle{2, Float32}})   # time: 0.027329441
    Base.precompile(Tuple{typeof(update!),GridLayout})   # time: 0.016759742
    isdefined(GridLayoutBase, Symbol("#119#120")) && Base.precompile(Tuple{getfield(GridLayoutBase, Symbol("#119#120")),HyperRectangle{2, Float32},Tuple{Float32, Float32},Tuple{Nothing, Nothing}})   # time: 0.013669098
    Base.precompile(Tuple{typeof(add_content!),GridLayout,GridLayout,Int64,Int64,Side})   # time: 0.013486578
    Base.precompile(Tuple{typeof(reportedsizeobservable!),Observable{Tuple{Union{Nothing, Float32, Auto, Fixed, Relative}, Union{Nothing, Float32, Auto, Fixed, Relative}}},Observable{Tuple{Union{Nothing, Float32}, Union{Nothing, Float32}}},Observable{AlignMode},Observable{RectSides{Float32}},Observable{Tuple{Bool, Bool}}})   # time: 0.013447249
    Base.precompile(Tuple{typeof(_reportedsizeobservable),Tuple{Union{Nothing, Float32, Auto, Fixed, Relative}, Union{Nothing, Float32, Auto, Fixed, Relative}},Tuple{Union{Nothing, Float32}, Union{Nothing, Float32}},AlignMode,RectSides{Float32},Tuple{Bool, Bool}})   # time: 0.013254966
    Base.precompile(Tuple{typeof(determinedirsize),GridLayout,GridDir,Side})   # time: 0.013025343
    Base.precompile(Tuple{typeof(determinedirsize),Int64,GridLayout,GridDir})   # time: 0.012611937
    let fbody = try __lookup_kwbody__(which(GridLayout, (Int64,Int64,))) catch missing end
        if !ismissing(fbody)
            precompile(fbody, (Nothing,Nothing,Nothing,Nothing,Nothing,Inside,Tuple{Bool, Bool},Nothing,Auto,Auto,Bool,Bool,Symbol,Symbol,Float64,Float64,Base.Pairs{Symbol, Union{}, Tuple{}, NamedTuple{(), Tuple{}}},Type{GridLayout},Int64,Int64,))
        end
    end   # time: 0.01134311
    Base.precompile(Tuple{typeof(validategridlayout),GridLayout})   # time: 0.01045204
    Base.precompile(Tuple{typeof(protrusion),GridContent{GridLayout},Side})   # time: 0.006668691
    Base.precompile(Tuple{typeof(remove_from_gridlayout!),GridContent{GridLayout}})   # time: 0.006181527
    let fbody = try __lookup_kwbody__(which(adjust_rows_cols!, (GridLayout,Int64,Int64,))) catch missing end
        if !ismissing(fbody)
            precompile(fbody, (Bool,typeof(adjust_rows_cols!),GridLayout,Int64,Int64,))
        end
    end   # time: 0.004979384
    Base.precompile(Tuple{typeof(connect_layoutobservables!),GridContent{GridLayout}})   # time: 0.003868889
    Base.precompile(Tuple{Type{RowCols},Int64,Int64})   # time: 0.002162528
    Base.precompile(Tuple{typeof(_compute_maxgrid),GridLayout})   # time: 0.002111075
    Base.precompile(Tuple{Core.kwftype(typeof(Type)),NamedTuple{(:suggestedbbox,), Tuple{Nothing}},Type{LayoutObservables},Observable{Union{Nothing, Float32, Auto, Fixed, Relative}},Observable{Union{Nothing, Float32, Auto, Fixed, Relative}},Observable{Bool},Observable{Bool},Observable{HorizontalAlignment},Observable{VerticalAlignment},Observable{AlignMode}})   # time: 0.001960045
    isdefined(GridLayoutBase, Symbol("#63#81")) && Base.precompile(Tuple{getfield(GridLayoutBase, Symbol("#63#81")),Tuple{Int64, Auto}})   # time: 0.001867652
    Base.precompile(Tuple{Type{GridLayout}})   # time: 0.001182782
    isdefined(GridLayoutBase, Symbol("#64#82")) && Base.precompile(Tuple{getfield(GridLayoutBase, Symbol("#64#82")),Tuple{Int64, Auto}})   # time: 0.001104512
end
