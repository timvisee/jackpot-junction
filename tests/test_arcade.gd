extends GdUnitTestSuite
## The Arcade, GAME.md 8.1c: Pin Alley's playfield wears a pinball machine's inserts, laid out round
## the pieces on the floor rather than under or across any of them, and its coat is satin.

const MAP := &"vault_xl"


## The lane every turbo pad fires down wears a run of three chevrons pointing its way, each on
## open floor clear of every pad, and its guides; each Jackpot has its arrow, likewise clear.
func test_the_inserts_are_laid_out_round_the_pieces() -> void:
	var grid := ArenaMaps.layout(MAP).parse()
	var sections := grid.turbo_sections()
	var chevrons := PinballInserts.chevrons(grid)
	assert_int(chevrons.size()).is_equal(sections.size() * PinballInserts.CHEVRONS)
	for chevron: Array in chevrons:
		var box := PinballInserts.chevron_box(chevron[0], chevron[1], chevron[2])
		_assert_clear(grid, box, "a chevron at %s" % chevron[0])
	# Pointing the way their pad fires, and in the lane, so a kart reading them is not misled.
	for section: Rect2i in sections:
		var way := grid.turbo_direction(section.position)
		var points := 0
		for chevron: Array in chevrons:
			var at: Vector2 = chevron[0]
			var from := Vector2(section.get_center())
			var on_line := absf((at - from).dot(Vector2(-way.z, way.x))) < 0.01
			if on_line and (at - from).dot(Vector2(way.x, way.z)) > 0.0:
				if Vector2i(chevron[1]) == Vector2i(roundi(way.x), roundi(way.z)):
					points += 1
		assert_int(points).override_failure_message("lane of %s" % section).is_greater_equal(3)
	assert_int(PinballInserts.guides(grid).size()).is_equal(4)
	var arrows := PinballInserts.arrows(grid)
	assert_int(arrows.size()).is_equal(grid.jackpots.size())
	for arrow: Array in arrows:
		_assert_clear(grid, PinballInserts.arrow_box(arrow[0], arrow[1]), "an arrow")
		# Pointing at its Jackpot: the tip is nearer it than the tail.
		var nearest := INF
		for rect: Rect2i in grid.jackpots:
			nearest = minf(nearest, Vector2(rect.get_center()).distance_to(arrow[0]))
		var tail := INF
		for rect: Rect2i in grid.jackpots:
			tail = minf(tail, Vector2(rect.get_center()).distance_to(arrow[1]))
		assert_float(nearest).is_less(tail)


func _assert_clear(grid: ArenaGrid, box: Rect2, what: String) -> void:
	for y: int in range(floori(box.position.y), ceili(box.end.y)):
		for x: int in range(floori(box.position.x), ceili(box.end.x)):
			var glyph := grid.glyph(Vector2i(x, y))
			(
				assert_str(glyph)
				. override_failure_message("%s lies on a %s at %d,%d" % [what, glyph, x, y])
				. is_equal(ArenaGrid.FLOOR)
			)
	# And no pad's insert reaches into it.
	for y: int in grid.height:
		for x: int in grid.width:
			var glyph := grid.glyph(Vector2i(x, y))
			if not PinballInserts.KEEP.has(glyph):
				continue
			var middle := Vector2(x, y) + Vector2.ONE * 0.5
			var gap := middle.clamp(box.position, box.end).distance_to(middle)
			(
				assert_float(gap)
				. override_failure_message("%s runs into the %s at %d,%d" % [what, glyph, x, y])
				. is_greater_equal(PinballInserts.KEEP[glyph])
			)


## Half the coin pads' and the item pads' inserts are lit, as a machine mid-game, and a pad and its
## twin across the room alike, so the room stays even.
func test_half_the_inserts_are_lit_and_twins_alike() -> void:
	var grid := ArenaMaps.layout(MAP).parse()
	for cells: Array[Vector2i] in [grid.coin_pads, grid.power_pads]:
		var lit := 0
		for i: int in cells.size():
			var twin := Vector2i(grid.width - 1 - cells[i].x, grid.height - 1 - cells[i].y)
			var j := cells.find(twin)
			assert_int(j).is_greater_equal(0)
			assert_bool(PinballInserts._lit(i, cells.size())).is_equal(
				PinballInserts._lit(j, cells.size())
			)
			if PinballInserts._lit(i, cells.size()):
				lit += 1
		assert_int(lit).is_equal(cells.size() / 2)


## GAME.md 8.1c: the playfield's coat is satin, its sheen soft across it rather than a mirror's
## hot spot, the print reading through it everywhere.
func test_the_coat_is_satin() -> void:
	var room: RoomLook = load("res://data/rooms/pinball.tres")
	var style := room.make_style(Surfaces.new(room)) as PinballStyle
	var coat := style.floor_top()
	assert_float(coat.roughness).is_greater_equal(0.6)
	assert_float(coat.metallic_specular).is_less_equal(0.4)
	if coat.clearcoat_enabled:
		assert_float(coat.clearcoat).is_less_equal(0.15)
		assert_float(coat.clearcoat_roughness).is_greater_equal(0.6)
