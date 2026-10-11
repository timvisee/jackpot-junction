extends GdUnitTestSuite
## The stage the payout slip's photo finish is taken against, GAME.md 3.8. See [PhotoBackdrop].


## On a screen of a UI scale over one, as a phone's, the curtains are drawn at the screen's own
## pixels into a sheet as big as the picture is there and shown back at the picture's size, every
## point of them scaled rather than the node they are drawn on, which the sheet did not draw at.
func test_the_curtains_are_drawn_at_the_screens_pixels() -> void:
	var backdrop: PhotoBackdrop = auto_free(PhotoBackdrop.new())
	backdrop.size = Vector2(700.0, 200.0)
	add_child(backdrop)
	await get_tree().process_frame
	# The sheet as big as the picture at whatever pixels it is drawn at, and shown back at its size.
	var scale := backdrop._sheet_scale
	assert_vector(Vector2(backdrop._sheet.size)).is_equal((backdrop.size * scale).ceil())
	assert_vector(backdrop._shown.scale * Vector2(backdrop._sheet.size)).is_equal_approx(
		backdrop.size, Vector2.ONE
	)
	assert_vector(backdrop._curtains.scale).is_equal(Vector2.ONE)
	# At a UI scale of 1.5 the curtains reach the sheet's far corner, not two thirds of the way.
	backdrop._sheet_scale = 1.5
	var reach := Vector2.ZERO
	for point: Vector2 in backdrop.curtain_cloth().points:
		reach = reach.max(point)
	assert_vector(reach).is_equal_approx(Vector2(1050.0, 300.0), Vector2.ONE * 2.0)
