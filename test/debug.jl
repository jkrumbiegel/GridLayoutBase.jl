bbox = Observable(BBox(0, 1000, 0, 1000)) # just as observable for bbox conversion test
layout = GridLayout(bbox = bbox, alignmode = Outside(100, 200, 50, 150))
dr = layout[1, 1] = DebugRect()