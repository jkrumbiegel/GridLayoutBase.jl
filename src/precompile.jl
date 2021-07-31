let
    while true
        bbox = BBox(0, 1000, 0, 1000)
        layout = GridLayout(bbox = bbox, alignmode = Outside(0))
        layout2 = GridLayout(1, 1)
        layout[1, 1] = layout2
        align_to_bbox!(layout, bbox)
        compute_col_row_sizes(1.0, 1.0, layout)
        determinedirsize(layout, Row)
        trim!(layout)
        break
    end
    nothing
end
