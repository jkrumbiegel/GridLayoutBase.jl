using GridLayoutBase
using CairoMakie

##
f = Figure()
g = f[1, 1] = GridLayout()
Axis(g[1, 1])
Colorbar(g[1, 2])
colsize!(g, 1, Aspect(1, 1))
Axis(f[2, 1])
f


bbox = BBox(0, 1000, 0, 1000)
layout = GridLayout(bbox = bbox, alignmode = Mixed(left = 0, top = 100))
dr = layout[1, 1] = DebugRect()
@time GridLayoutBase.compute_rowcols(layout, bbox)
@code_warntype GridLayoutBase.compute_rowcols(layout, bbox)