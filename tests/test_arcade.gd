extends GdUnitTestSuite
## The Arcade, GAME.md 8.1c: Pin Alley's playfield wears a pinball machine's inserts, laid out round
## the pieces on the floor rather than under or across any of them, and its coat is satin.

const MAP := &"vault_xl"
const ROOM: RoomLook = preload("res://data/rooms/pinball.tres")


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


## GAME.md 8.1c: the playfield's coat is satin, its sheen soft across it rather than a mirror's
## hot spot, the print reading through it everywhere.
func test_the_coat_is_satin() -> void:
	var style := ROOM.make_style(Surfaces.new(ROOM)) as PinballStyle
	var coat := style.floor_top()
	assert_float(coat.roughness).is_greater_equal(0.6)
	assert_float(coat.metallic_specular).is_less_equal(0.4)
	if coat.clearcoat_enabled:
		assert_float(coat.clearcoat).is_less_equal(0.15)
		assert_float(coat.clearcoat_roughness).is_greater_equal(0.6)


## GAME.md 8.1c: the playfield a player sees is printed under the House's layout, at its size and
## smoothed as it is drawn, four samples a pixel, so a floor worn this large shows no pixels along
## an insert's edge; and the light the coat gives back is that same picture, not a soft one of its
## own, which the floor wore as a blur over itself.
func test_the_playfield_is_printed_sharp_and_smooth() -> void:
	var host: Node = auto_free(Node.new())
	add_child(host)
	DrawnTexture.of(host, Control.new(), Vector2i(8, 8), LayoutPrint.SMOOTH)
	var drawn := host.get_child(0) as SubViewport
	assert_int(drawn.msaa_2d).is_equal(Viewport.MSAA_4X)
	assert_int(LayoutPrint.SMOOTH).is_equal(Viewport.MSAA_4X)
	var style := ROOM.make_style(Surfaces.new(ROOM)) as PinballStyle
	var coat := style.floor_top()
	var print := ImageTexture.create_from_image(Image.create(4, 4, true, Image.FORMAT_RGBA8))
	style.layout_printed(coat, print)
	assert_bool(coat.emission_enabled).is_true()
	assert_object(coat.emission_texture).is_same(print)
	assert_int(coat.emission_operator).is_equal(BaseMaterial3D.EMISSION_OP_MULTIPLY)


## GAME.md 8.1b: a floor's print is drawn as finely as Texture detail asks. Auto draws it finer
## for a taller screen, as finer as the screen is taller than the one it is laid out for, so it is
## no softer at 4K than there, up to 1.75 times a side and the pixels a print may take, and at its
## own size on a phone's renderer; Low at its own size always; High as finely as Auto ever draws
## it, whatever the screen and the renderer; and Ultra twice as finely as Auto would, never less
## than twice nor more than three times, nor wider than the card holds, and as High on a phone's
## renderer. Laid out the same, only its pixels finer.
func test_a_print_is_drawn_as_finely_as_texture_detail_asks() -> void:
	var grid := ArenaMaps.layout(MAP).parse()
	var laid_out := LayoutPrint.pixels(grid)
	var auto := Settings.TEXTURES_AUTO
	assert_float(LayoutPrint.MOST_SCALE).is_equal(1.75)
	assert_float(LayoutPrint.scale_for(auto, 1080, laid_out)).is_equal(1.0)
	assert_float(LayoutPrint.scale_for(auto, 1440, laid_out)).is_equal(1.0)
	assert_float(LayoutPrint.scale_for(auto, 2160, laid_out)).is_equal_approx(1.5, 0.001)
	assert_float(LayoutPrint.scale_for(auto, 2880, laid_out)).is_equal_approx(1.75, 0.001)
	assert_float(LayoutPrint.scale_for(auto, 4320, laid_out)).is_equal_approx(1.75, 0.001)
	assert_float(LayoutPrint.scale_for(auto, 2880, laid_out, false)).is_equal(1.0)
	for tallest: int in [800, 1440, 2880]:
		for full: bool in [true, false]:
			var low := LayoutPrint.scale_for(Settings.TEXTURES_LOW, tallest, laid_out, full)
			var high := LayoutPrint.scale_for(Settings.TEXTURES_HIGH, tallest, laid_out, full)
			assert_float(low).is_equal(1.0)
			assert_float(high).is_equal_approx(1.75, 0.001)
	var ultra := Settings.TEXTURES_ULTRA
	assert_float(LayoutPrint.scale_for(ultra, 1080, laid_out)).is_equal(2.0)
	assert_float(LayoutPrint.scale_for(ultra, 1440, laid_out)).is_equal(2.0)
	assert_float(LayoutPrint.scale_for(ultra, 2160, laid_out)).is_equal_approx(3.0, 0.001)
	assert_float(LayoutPrint.scale_for(ultra, 2880, laid_out)).is_equal_approx(3.0, 0.001)
	assert_float(LayoutPrint.scale_for(ultra, 2880, laid_out, false)).is_equal_approx(1.75, 0.001)
	var finest := Vector2(laid_out) * LayoutPrint.ULTRA_MOST
	assert_float(finest.x * finest.y).is_less_equal(float(LayoutPrint.ULTRA_PIXELS))
	var narrow := LayoutPrint.scale_for(ultra, 2880, laid_out, true, 4096)
	assert_float(narrow * laid_out.x).is_less_equal(4096.0)
	# The XL map drawn its finest fits in the pixels a print may take, and a print bigger than it
	# is drawn less finely to fit too.
	var drawn := Vector2(laid_out) * LayoutPrint.MOST_SCALE
	assert_float(drawn.x * drawn.y).is_less_equal(float(LayoutPrint.MOST_PIXELS))
	var bigger := Vector2i((Vector2(laid_out) * 1.2).round())
	var most := LayoutPrint.scale_for(Settings.TEXTURES_HIGH, 2880, bigger)
	drawn = Vector2(bigger) * most
	assert_float(most).is_less(LayoutPrint.MOST_SCALE)
	assert_float(drawn.x * drawn.y).is_less_equal(float(LayoutPrint.MOST_PIXELS) + 1.0)
	var host: Node = auto_free(Node.new())
	add_child(host)
	DrawnTexture.of(host, Control.new(), Vector2i(8, 6), LayoutPrint.SMOOTH, 2.0)
	var render := host.get_child(0) as SubViewport
	assert_vector(Vector2(render.size)).is_equal(Vector2(16, 12))
	assert_vector(Vector2(render.size_2d_override)).is_equal(Vector2(8, 6))
	assert_bool(render.size_2d_override_stretch).is_true()


## GAME.md 8.1b: changing Texture detail draws a print again at once at its new size, and leaves
## one already at it alone.
func test_a_print_is_drawn_again_when_texture_detail_changes() -> void:
	var was := Game.settings.texture_detail
	Game.settings.texture_detail = Settings.TEXTURES_LOW
	var host: Node = auto_free(Node.new())
	add_child(host)
	var made: Array[int] = [0]
	var make := func() -> Control:
		made[0] += 1
		return Control.new()
	var screen := ScreenPrint.lay(host, make, Vector2i(40, 20), func(_t: Texture2D) -> void: pass)
	assert_int(made[0]).is_equal(1)
	assert_float(screen.drawn_at()).is_equal(1.0)
	ScreenPrint.redraw(get_tree())
	assert_int(made[0]).is_equal(1)
	Game.settings.texture_detail = Settings.TEXTURES_HIGH
	ScreenPrint.redraw(get_tree())
	Game.settings.texture_detail = was
	assert_int(made[0]).is_equal(2)
	assert_float(screen.drawn_at()).is_equal_approx(1.75, 0.001)
	var render := host.get_child(host.get_child_count() - 1) as SubViewport
	assert_vector(Vector2(render.size)).is_equal(Vector2(70, 35))
	assert_int(render.msaa_2d).is_equal(LayoutPrint.SMOOTH_FINER)
