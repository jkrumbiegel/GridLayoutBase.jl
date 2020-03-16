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

@testset "assigning content to protrusions" begin

    bbox = BBox(0, 1000, 0, 1000)
    layout = GridLayout(bbox = bbox, alignmode = Outside(0))
    subgl = layout[1, 1] = GridLayout()

    subgl[1, 1, Left()] = DebugRect(width = Fixed(100))
    @test GridLayoutBase.protrusion(subgl, Left()) == 100

    subgl[1, 1, Top()] = DebugRect(height = 50)
    @test GridLayoutBase.protrusion(subgl, Top()) == 50

    subgl[1, 1, Right()] = DebugRect(width = 120)
    @test GridLayoutBase.protrusion(subgl, Right()) == 120

    subgl[1, 1, Bottom()] = DebugRect(height = 40)
    @test GridLayoutBase.protrusion(subgl, Bottom()) == 40

    subgl[1, 1, TopLeft()] = DebugRect(width = 200, height = 200)
    @test GridLayoutBase.protrusion(subgl, Left()) == 200
    @test GridLayoutBase.protrusion(subgl, Top()) == 200

    subgl[1, 1, TopRight()] = DebugRect(width = 210, height = 210)
    @test GridLayoutBase.protrusion(subgl, Right()) == 210
    @test GridLayoutBase.protrusion(subgl, Top()) == 210

    subgl[1, 1, BottomRight()] = DebugRect(width = 220, height = 220)
    @test GridLayoutBase.protrusion(subgl, Right()) == 220
    @test GridLayoutBase.protrusion(subgl, Bottom()) == 220

    subgl[1, 1, BottomLeft()] = DebugRect(width = 230, height = 230)
    @test GridLayoutBase.protrusion(subgl, Left()) == 230
    @test GridLayoutBase.protrusion(subgl, Bottom()) == 230

    # dr = subgl[1, 1, GridLayoutBase.Outer()] = DebugRect()
    # @test computedbboxobservable(dr)[].widths == (1000, 1000)
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


@testset "manually deleting rows / cols" begin
    layout = GridLayout(4, 4)

    deletecol!(layout, 2)
    @test size(layout) == (4, 3)

    deleterow!(layout, 3)
    @test size(layout) == (3, 3)

    deleterow!(layout, 1)
    @test size(layout) == (2, 3)

    deletecol!(layout, 1)
    @test size(layout) == (2, 2)

    deleterow!(layout, 2)
    @test size(layout) == (1, 2)

    deletecol!(layout, 2)
    @test size(layout) == (1, 1)

    @test_throws ErrorException deletecol!(layout, 2)
    @test_throws ErrorException deleterow!(layout, 2)
    @test_throws ErrorException deletecol!(layout, 1)
    @test_throws ErrorException deleterow!(layout, 1)

    dr = layout[1, 2] = DebugRect()
    @test length(layout.content) == 1
    deletecol!(layout, 2)
    @test isempty(layout.content)

    dr = layout[2, 1] = DebugRect()
    @test length(layout.content) == 1
    deleterow!(layout, 2)
    @test isempty(layout.content)
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

    @test_throws ErrorException colgap!(layout, 10, Fixed(10))
    @test_throws ErrorException rowgap!(layout, 10, Fixed(10))
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

    subgl = gl[1, 2] = GridLayout()
    subgl[1:5, 3] = DebugRect()

    text_longer = repr(MIME"text/plain"(), gl)
    # this is actually a bit buggy with the newline space space newline at the end
    @test text_longer == "GridLayout[3, 5] with 3 children\n ┣━ [1:1 | 1:1] DebugRect\n ┣━ [2:3 | 4:5] DebugRect\n ┗━ [1:1 | 2:2] GridLayout[5, 3] with 1 children\n   ┗━ [1:5 | 3:3] DebugRect\n  \n"


    gl3 = GridLayout()
    gl4 = gl3[1, 1] = GridLayout()
    gl4[1, 1] = DebugRect()
    gl3[2, 2] = DebugRect()
    text_long_downconnection = repr(MIME"text/plain"(), gl3)

    # this is also a bit buggy for the same reason as above
    @test text_long_downconnection == "GridLayout[2, 2] with 2 children\n ┣━ [1:1 | 1:1] GridLayout[1, 1] with 1 children\n ┃ ┗━ [1:1 | 1:1] DebugRect\n ┃\n ┗━ [2:2 | 2:2] DebugRect\n"
end

@testset "vector and array assigning" begin
    gl = GridLayout()
    gl[1, 1:3] = [DebugRect() for i in 1:3]
    @test size(gl) == (1, 3)

    gl2 = GridLayout()
    gl2[2:3, 2] = [DebugRect() for i in 1:2]
    @test size(gl2) == (3, 2)

    gl3 = GridLayout()
    gl3[1:3, 1:4] = [DebugRect() for i in 1:12]
    @test size(gl3) == (3, 4)

    gl4 = GridLayout()
    gl4[1:3, 1:4] = [DebugRect() for i in 1:3, j in 1:4]
    @test size(gl4) == (3, 4)

    @test_throws ErrorException gl[1, 1:3] = [DebugRect() for i in 1:2]
    @test_throws ErrorException gl[1:3, 2] = [DebugRect() for i in 1:2]
    @test_throws ErrorException gl[1:3, 1:3] = [DebugRect() for i in 1:10]
    @test_throws ErrorException gl[1:3, 1:3] = [DebugRect() for i in 1:3, j in 1:4]

    gl5 = GridLayout()
    gl5[] = [DebugRect() for i in 1:2, j in 1:3]
    @test size(gl5) == (2, 3)

    gl6 = GridLayout()
    gl6[:v] = [DebugRect() for i in 1:3]
    @test size(gl6) == (3, 1)

    gl7 = GridLayout()
    gl7[:h] = [DebugRect() for i in 1:3]
    @test size(gl7) == (1, 3)

    @test_throws ErrorException gl7[:abc] = [DebugRect() for i in 1:3]
    @test_throws ErrorException gl7[] = [DebugRect() for i in 1:3]
end

@testset "grid api" begin

    gl1 = grid!([1:2, 1:2] => DebugRect(), [3, :] => DebugRect())
    @test size(gl1) == (3, 2)
    @test gl1.content[1].span == GridLayoutBase.Span(1:2, 1:2)
    @test gl1.content[2].span == GridLayoutBase.Span(3:3, 1:2)

    gl2 = grid!([DebugRect() for i in 1:3, j in 1:2])
    @test size(gl2) == (3, 2)
    for i in 1:3, j in 1:2
        n = (i - 1) * 2 + j
        @test gl2.content[n].span == GridLayoutBase.Span(i:i, j:j)
    end

    gl3 = vbox!(DebugRect(), DebugRect())
    @test size(gl3) == (2, 1)
    for i in 1:2
        @test gl3.content[i].span == GridLayoutBase.Span(i:i, 1:1)
    end

    gl4 = hbox!(DebugRect(), DebugRect())
    @test size(gl4) == (1, 2)
    for i in 1:2
        @test gl4.content[i].span == GridLayoutBase.Span(1:1, i:i)
    end
end

@testset "gridnest" begin
    layout = GridLayout()
    dr = layout[1:2, 3:4] = DebugRect()
    subgl = gridnest!(layout, 1:2, 3:4)

    @test size(subgl) == (2, 2)
    @test subgl.content[1].span == GridLayoutBase.Span(1:2, 1:2)
end

@testset "invalid removal" begin
    layout = GridLayout()
    dr = layout[1, 1] = DebugRect()
    # remove the item outside of the normal path
    deleteat!(layout.content, 1)
    # place the item somewhere else, this should error now
    @test_throws ErrorException layout[1, 2] = dr
end

@testset "equal protrusion gaps" begin
    bbox = BBox(0, 1000, 0, 1000)
    layout = GridLayout(bbox = bbox, alignmode = Outside(0))
    subgl = layout[1, 1] = GridLayout(3, 3, equalprotrusiongaps = (true, true),
        addedcolgaps = Fixed(0), addedrowgaps = Fixed(0))
    subgl[1, 1, BottomRight()] = DebugRect(width = 100, height = 100)

    dr1 = subgl[1, 1] = DebugRect()
    dr2 = subgl[2, 2] = DebugRect()
    dr3 = subgl[3, 3] = DebugRect()

    @test width(computedbboxobservable(dr1)[]) ≈ (1000 - 2 * 100) / 3.0f0
    @test width(computedbboxobservable(dr2)[]) ≈ (1000 - 2 * 100) / 3.0f0
    @test width(computedbboxobservable(dr3)[]) ≈ (1000 - 2 * 100) / 3.0f0
    @test height(computedbboxobservable(dr1)[]) ≈ (1000 - 2 * 100) / 3.0f0
    @test height(computedbboxobservable(dr2)[]) ≈ (1000 - 2 * 100) / 3.0f0
    @test height(computedbboxobservable(dr3)[]) ≈ (1000 - 2 * 100) / 3.0f0
end

@testset "getindex gridposition" begin
    layout = GridLayout()
    dr = layout[2, 2] = DebugRect()

    @test layout[2, 2] == GridPosition(layout, 2, 2)
    @test layout[end, end] == GridPosition(layout, 2, 2)
    @test_throws ErrorException layout[2, 2, end]

    gp = GridPosition(layout, 1, 1)
    gp[] = dr
    @test gridcontent(dr).span == GridLayoutBase.Span(1:1, 1:1)
end
