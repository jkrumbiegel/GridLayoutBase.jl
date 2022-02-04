let
    while true
        ccall(:jl_generating_output, Cint, ()) == 1 || break
        gl = GridLayout()
        gl2 = GridLayout()
        gl[1, 1] = gl2
        GridLayoutBase.determinedirsize(gl, GridLayoutBase.Row())
        GridLayoutBase.compute_rowcols(gl, GridLayoutBase.suggestedbboxobservable(gl)[])
        GridLayoutBase.update!(gl)
        GridLayoutBase.align_to_bbox!(gl2, GridLayoutBase.suggestedbboxobservable(gl2)[])
        break
    end
    nothing
end