using GridLayoutBase
using Test
using Observables

include("debugrect.jl")

# have BBoxes show as such because the default is very verbose
Base.show(io::IO, bb::BBox) = print(io, "BBox(l: $(left(bb)), r: $(right(bb)), b: $(bottom(bb)), t: $(top(bb)))")


@testset "GridLayout Zero Outside AlignMode" begin
    bbox = BBox(0, 1000, 0, 1000)
    layout = GridLayout(bbox = bbox, alignmode = Outside(0))
    dr = layout[1, 1] = DebugRect()

    @test computedbboxobservable(dr)[] == bbox

    dr.topprot[] = 100
    @test computedbboxobservable(dr)[] == BBox(0, 1000, 0, 900)
    dr.bottomprot[] = 100
    @test computedbboxobservable(dr)[] == BBox(0, 1000, 100, 900)
    dr.leftprot[] = 100
    @test computedbboxobservable(dr)[] == BBox(100, 1000, 100, 900)
    dr.rightprot[] = 100
    @test computedbboxobservable(dr)[] == BBox(100, 900, 100, 900)

    dr2 = layout[1, 2] = DebugRect()
    @test layout.nrows == 1 && layout.ncols == 2
    colgap!(layout, 1, Fixed(0))

    @test computedbboxobservable(dr)[].widths == computedbboxobservable(dr2)[].widths == Float32[400.0, 800.0]
end

@testset "GridLayout Outside AlignMode" begin
    bbox = BBox(0, 1000, 0, 1000)
    layout = GridLayout(bbox = bbox, alignmode = Outside(100, 200, 50, 150))
    dr = layout[1, 1] = DebugRect()

    @test computedbboxobservable(dr)[] == BBox(100, 800, 50, 850)

    dr.topprot[] = 100
    @test computedbboxobservable(dr)[] == BBox(100, 800, 50, 750)
    dr.bottomprot[] = 100
    @test computedbboxobservable(dr)[] == BBox(100, 800, 150, 750)
    dr.leftprot[] = 100
    @test computedbboxobservable(dr)[] == BBox(200, 800, 150, 750)
    dr.rightprot[] = 100
    @test computedbboxobservable(dr)[] == BBox(200, 700, 150, 750)
end

@testset "GridLayout Inside AlignMode" begin
    bbox = BBox(0, 1000, 0, 1000)
    layout = GridLayout(bbox = bbox, alignmode = Inside())
    dr = layout[1, 1] = DebugRect()

    @test computedbboxobservable(dr)[] == BBox(0, 1000, 0, 1000)

    dr.topprot[] = 100
    @test computedbboxobservable(dr)[] == BBox(0, 1000, 0, 1000)
    dr.bottomprot[] = 100
    @test computedbboxobservable(dr)[] == BBox(0, 1000, 0, 1000)
    dr.leftprot[] = 100
    @test computedbboxobservable(dr)[] == BBox(0, 1000, 0, 1000)
    dr.rightprot[] = 100
    @test computedbboxobservable(dr)[] == BBox(0, 1000, 0, 1000)
end

@testset "GridLayout Mixed AlignMode" begin
    bbox = BBox(0, 1000, 0, 1000)
    layout = GridLayout(bbox = bbox, alignmode = Mixed(left = 0, top = 100))
    dr = layout[1, 1] = DebugRect()

    @test GridLayoutBase.protrusion(layout, Left()) == 0
    @test GridLayoutBase.protrusion(layout, Right()) == 0
    @test GridLayoutBase.protrusion(layout, Bottom()) == 0
    @test GridLayoutBase.protrusion(layout, Top()) == 0

    @test computedbboxobservable(dr)[] == BBox(0, 1000, 0, 900)

    dr.topprot[] = 100
    @test GridLayoutBase.protrusion(layout, Top()) == 0
    @test computedbboxobservable(dr)[] == BBox(0, 1000, 0, 800)

    dr.bottomprot[] = 100
    @test GridLayoutBase.protrusion(layout, Bottom()) == 100
    @test computedbboxobservable(dr)[] == BBox(0, 1000, 0, 800)

    dr.leftprot[] = 100
    @test GridLayoutBase.protrusion(layout, Left()) == 0
    @test computedbboxobservable(dr)[] == BBox(100, 1000, 0, 800)

    dr.rightprot[] = 100
    @test GridLayoutBase.protrusion(layout, Right()) == 100
    @test computedbboxobservable(dr)[] == BBox(100, 1000, 0, 800)
end


@testset "resizing through indexing out of range and trim!" begin

    bbox = BBox(0, 1000, 0, 1000)
    layout = GridLayout(bbox = bbox, alignmode = Outside(0))

    dr = layout[1, 1] = DebugRect()
    @test size(layout) == (1, 1)

    layout[1, 2] = dr
    @test size(layout) == (1, 2)

    layout[3, 2] = dr
    @test size(layout) == (3, 2)

    layout[4, 4] = dr
    @test size(layout) == (4, 4)

    layout[0, 1] = dr
    @test size(layout) == (5, 4)

    layout[1, 0] = dr
    @test size(layout) == (5, 5)

    layout[-1, -1] = dr
    @test size(layout) == (7, 7)

    layout[3, 3] = dr
    trim!(layout)
    @test size(layout) == (1, 1)

    layout[2:3, 4:5] = dr
    @test size(layout) == (3, 5)

    trim!(layout)
    @test size(layout) == (2, 2)
end


@testset "setting col and row sizes and gaps" begin
    bbox = BBox(0, 1000, 0, 1000)
    layout = GridLayout(3, 3, bbox = bbox, alignmode = Outside(0))

    colsize!(layout, 1, Fixed(10))
    @test layout.colsizes[1] == Fixed(10)

    colsize!(layout, 2, 20)
    @test layout.colsizes[2] == Fixed(20)

    rowsize!(layout, 1, Relative(0.2))
    @test layout.rowsizes[1] == Relative(0.2)

    rowsize!(layout, 2, 15.3)
    @test layout.rowsizes[2] == Fixed(15.3)

    @test_throws ErrorException colsize!(layout, 4, Auto())
    @test_throws ErrorException rowsize!(layout, 0, Auto())


    colgap!(layout, 1, Fixed(10))
    @test layout.addedcolgaps[1] == Fixed(10)
    rowgap!(layout, 2, Relative(0.3))
    @test layout.addedrowgaps[2] == Relative(0.3)

    colgap!(layout, 10)
    @test all(layout.addedcolgaps .== Ref(Fixed(10)))
    rowgap!(layout, 20)
    @test all(layout.addedrowgaps .== Ref(Fixed(20)))

    colgap!(layout, Fixed(30))
    @test all(layout.addedcolgaps .== Ref(Fixed(30)))
    rowgap!(layout, Fixed(40))
    @test all(layout.addedrowgaps .== Ref(Fixed(40)))
end

@testset "some constructors" begin
    @test Outside() == Outside(0f0)
    @test Auto(2).ratio == 2.0
end

@testset "gridlayout constructor colsizes" begin
    gl = GridLayout(2, 2; colsizes = Fixed(10), rowsizes = Relative(0.5))

    @test gl.colsizes == GridLayoutBase.ContentSize[Fixed(10), Fixed(10)]
    @test gl.rowsizes == GridLayoutBase.ContentSize[Relative(0.5), Relative(0.5)]

    gl2 = GridLayout(2, 2;
        colsizes = [Fixed(10), Relative(0.3)],
        rowsizes = [Auto(false), Auto(true)])
    @test gl2.colsizes == GridLayoutBase.ContentSize[Fixed(10), Relative(0.3)]
    @test gl2.rowsizes == GridLayoutBase.ContentSize[Auto(false), Auto(true)]

    @test_throws ErrorException GridLayout(; colsizes = "abc")
    @test_throws ErrorException GridLayout(; rowsizes = missing)

    gl3 = GridLayout(3, 3; addedcolgaps = Fixed(20), addedrowgaps = Fixed(0))
    @test gl3.addedcolgaps == GridLayoutBase.GapSize[Fixed(20), Fixed(20)]
    @test gl3.addedrowgaps == GridLayoutBase.GapSize[Fixed(0), Fixed(0)]

    @test_throws ErrorException GridLayout(3, 1; addedcolgaps = "abc")
    @test_throws ErrorException GridLayout(1, 3; addedrowgaps = "abc")

    @test_throws ErrorException GridLayout(3, 1; addedcolgaps = [Fixed(20)])
    @test_throws ErrorException GridLayout(3, 1; addedrowgaps = [Fixed(30)])

    @test_throws ErrorException GridLayout(3, 1; rowsizes = [Fixed(20)])
    @test_throws ErrorException GridLayout(3, 2; colsizes = [Relative(0.4)])

    @test_throws ErrorException GridLayout(0, 1)
    @test_throws ErrorException GridLayout(1, 0)
end


@testset "printing gridlayouts" begin
    gl = GridLayout(3, 3)
    gl[1, 1] = DebugRect()
    gl[2:3, 4:5] = DebugRect()

    text_long = repr(MIME"text/plain"(), gl)
    @test text_long == """
    GridLayout[3, 5] with 2 children
     ┣━ [1:1 | 1:1] DebugRect
     ┗━ [2:3 | 4:5] DebugRect
    """
    text_short = repr(gl)
    @test text_short == "GridLayout[3, 5] (2 children)"
end
