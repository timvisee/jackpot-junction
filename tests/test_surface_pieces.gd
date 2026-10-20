extends GdUnitTestSuite
## The surface printed over a cut shape, GAME.md 8.1a: the shape is cut into a piece for every
## tile of the surface it crosses, and every piece is a polygon the renderer can fill. A sliver of
## nothing where an edge runs along a tile's, which it cannot, used to be handed to it all the same.


## A notched ticket of every size between small and wide, at every screen scale and every place in
## the tile, cut into pieces none of which fails to triangulate.
func test_every_piece_of_a_cut_shape_can_be_filled() -> void:
	var bad := 0
	var tried := 0
	for scale: float in [0.75, 1.0, 1.25, 1.5, 2.0]:
		var tile := float(Surface.TILE) / scale
		for phase: int in range(0, 997, 37):
			var shift := (
				Vector2(fposmod(phase * 0.618034, 1.0), fposmod(phase * 0.414214, 1.0)) * tile
			)
			for width: float in range(40, 1300, 23):
				for height: float in [44.0, 70.0, 96.5, 128.0, 200.0]:
					var size := Vector2(width, height)
					var edge := TicketStyle.outline(size, 10.0)
					for piece: Dictionary in Surface.pieces(edge, size, tile, shift):
						tried += 1
						if Geometry2D.triangulate_polygon(piece[&"points"]).is_empty():
							bad += 1
	assert_int(tried).is_greater(1000)
	(
		assert_int(bad)
		. override_failure_message("%d of %d pieces cannot be filled" % [bad, tried])
		. is_equal(0)
	)


## A shape drawn again at another size has its surface cut again for that size. Kept from the size
## it was first drawn at, the driving test's clipboard, laid out tall for a frame and then shorter,
## went on printing its felt and its paper's fibers below the board, over the room.
func test_a_shape_drawn_shorter_keeps_its_surface_inside_it() -> void:
	var item := RenderingServer.canvas_item_create()
	var kept := {}
	for height: float in [600.0, 229.0]:
		var size := Vector2(300.0, height)
		Surface.draw(item, kept, TicketStyle.outline(size, 10.0), size, Surface.Kind.FELT, 0.22)
	var lowest := 0.0
	for layers: Array in (kept[&"surface_by_phase"] as Dictionary).values():
		for made: Array in layers:
			for piece: Dictionary in made:
				for point: Vector2 in piece[&"points"]:
					lowest = maxf(lowest, point.y)
	RenderingServer.free_rid(item)
	assert_float(lowest).is_greater(200.0).is_less_equal(229.0)
