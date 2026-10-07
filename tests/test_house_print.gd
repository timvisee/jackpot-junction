extends GdUnitTestSuite
## The house print, GAME.md 8.1a: the ticket every pane and button is cut from, the perforation
## under a pane's header, the signs on questions, and the one theme every control wears.


## A ticket's corners are notched inward the way a ticket is punched: the corner itself is outside
## it, the middle inside, and a bite comes out of either side where it is perforated.
func test_a_ticket_is_notched_and_bitten() -> void:
	var size := Vector2(300.0, 200.0)
	var edge := TicketStyle.outline(size, 12.0, PackedFloat32Array([80.0]), 10.0)
	assert_bool(Geometry2D.is_point_in_polygon(Vector2(150.0, 100.0), edge)).is_true()
	for corner: Vector2 in [Vector2(1.0, 1.0), Vector2(299.0, 1.0), Vector2(1.0, 199.0)]:
		assert_bool(Geometry2D.is_point_in_polygon(corner, edge)).is_false()
	# Beside the perforation the edge is bitten into, and above it the edge is whole.
	assert_bool(Geometry2D.is_point_in_polygon(Vector2(4.0, 80.0), edge)).is_false()
	assert_bool(Geometry2D.is_point_in_polygon(Vector2(296.0, 80.0), edge)).is_false()
	assert_bool(Geometry2D.is_point_in_polygon(Vector2(4.0, 50.0), edge)).is_true()
	# A pane under tabs keeps its top corners square for them.
	var under_tabs := TicketStyle.outline(size, 12.0, PackedFloat32Array(), 10.0, false)
	assert_bool(Geometry2D.is_point_in_polygon(Vector2(1.0, 1.0), under_tabs)).is_true()


## A bite that would run into a notch is left out rather than cut across it, which would leave the
## outline crossing itself.
func test_a_bite_never_runs_into_a_notch() -> void:
	var edge := TicketStyle.outline(Vector2(300.0, 60.0), 12.0, PackedFloat32Array([8.0]), 10.0)
	assert_bool(Geometry2D.is_point_in_polygon(Vector2(4.0, 30.0), edge)).is_true()


## The perforation under a pane's header tells the pane where it is, so the pane tears there, and
## stands as tall as it takes for the gap over and under it to be the pane's own gap beside its
## words, GAME.md 8.1a, whatever its column puts between its children.
func test_a_perforation_tears_the_pane_with_the_same_gap_all_round() -> void:
	for between: int in [0, 12, 16]:
		var pane := MenuTheme.pane()
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", between)
		pane.add_child(column)
		var title := MenuTheme.title("Heading", Type.TITLE)
		column.add_child(title)
		var tear := MenuTheme.perforation()
		column.add_child(tear)
		var below := MenuTheme.button("Below")
		column.add_child(below)
		add_child(pane)
		await await_idle_frame()
		await await_idle_frame()
		var style := pane.get_theme_stylebox(&"panel") as TicketStyle
		assert_int(style.perforations.size()).is_equal(1)
		var line := style.perforations[0]
		var expected := style.content_margin_top + title.size.y + between + tear.size.y * 0.5
		assert_float(line).is_equal_approx(roundf(expected), 1.0)
		var gap := style.content_margin_left - style.frame_inset
		assert_float(gap).is_equal(MenuTheme.PANE_GAP)
		# Under the tear: from the hairline round the body to the button, the gap beside the words.
		var body_top := line + style.bite + TicketStyle.FRAME_GAP
		assert_float(below.position.y + style.content_margin_top - body_top).is_equal_approx(
			gap, 1.0
		)
		# Over it: from the title's box to the hairline round the header, the same again.
		var header_foot := line - style.bite - TicketStyle.FRAME_GAP
		var title_foot := style.content_margin_top + title.size.y
		assert_float(header_foot - title_foot).is_equal_approx(gap, 1.0)
		assert_float(style.content_margin_top - style.frame_inset).is_equal(gap)
		pane.free()


## A title's capitals stand in the middle of its box, so a header centered on the box is centered
## on the capitals: Barlow keeps more of a line over its capitals than under its baseline.
func test_a_title_is_centered_on_its_capitals() -> void:
	var size := Type.TITLE
	var title := MenuTheme.title("Heading", size)
	var even := title.get_theme_stylebox(&"normal")
	var font := Type.display_font()
	var over := even.content_margin_top + font.get_ascent(size) - size * Type.CAP_HEIGHT
	var under := even.content_margin_bottom + font.get_descent(size)
	assert_float(over).is_equal_approx(under, 0.5)
	title.free()


## The keys of a binding stand at their own size in the middle of their socket rather than
## stretched to fill it, GAME.md 8.1a.
func test_a_bindings_keys_keep_their_own_size_in_the_socket() -> void:
	var row := SettingsScreen._bound_glyphs(InputActions.FIRE, true)
	assert_int(row.get_child_count()).is_greater(0)
	for glyph: Node in row.get_children():
		assert_int((glyph as Control).size_flags_vertical).is_equal(Control.SIZE_SHRINK_CENTER)
		assert_float((glyph as Control).get_combined_minimum_size().y).is_less(
			SettingsScreen.BINDING_CELL.y - HouseTheme.SOCKET_ROOM * 2.0 + 1.0
		)
	row.free()


## A question that loses something wears the warning diamond; one that is only a question wears
## the round blue sign.
func test_a_question_wears_its_sign() -> void:
	var pane := ConfirmPane.new()
	add_child(pane)
	pane.ask("Leave?", "Your pot stays.", "Leave")
	assert_int(pane._sign.kind).is_equal(RoadSign.Kind.WARNING)
	pane.ask("Missing license", "Earn one.", "Earn it", "Drive", RoadSign.Kind.QUESTION)
	assert_int(pane._sign.kind).is_equal(RoadSign.Kind.QUESTION)
	pane.queue_free()


## The house's look reaches a button however deep it is, under a canvas layer too, which a theme on
## the root window does not: the pause menu and every pane over a room live in one.
func test_every_control_wears_the_house_look() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var button := Button.new()
	layer.add_child(button)
	assert_object(button.get_theme_stylebox(&"normal")).is_instanceof(TicketStyle)
	var onward := MenuTheme.primary(Button.new())
	layer.add_child(onward)
	var foil := onward.get_theme_stylebox(&"normal") as TicketStyle
	assert_object(foil.fill).is_equal(HouseTheme.FOIL_HIGH)
	assert_object(onward.get_theme_color(&"font_color")).is_equal(HouseTheme.ON_FOIL)
	layer.queue_free()


## A strip comes off the edge it is cut for and leans at its other end, wide where it hangs from:
## at the top for a corner at the top of the screen, at the bottom for one standing on it.
func test_a_strip_leans_at_its_inner_end() -> void:
	var size := Vector2(200.0, 100.0)
	var left := StripStyle.cut(false, 20.0, 10.0, 30.0, 4.0)
	var shape := left.outline(size)
	for point: Vector2 in [Vector2(0.0, 0.0), Vector2(200.0, 0.0), Vector2(180.0, 100.0)]:
		assert_bool(shape.has(point)).is_true()
	var right := StripStyle.cut(true, 20.0, 10.0, 30.0, 4.0)
	right.wide_at_bottom = true
	shape = right.outline(size)
	for point: Vector2 in [Vector2(200.0, 0.0), Vector2(20.0, 0.0), Vector2(0.0, 100.0)]:
		assert_bool(shape.has(point)).is_true()
	# The content keeps clear of the lean and the stripe on the end that has them.
	assert_float(right.content_margin_left).is_greater(right.content_margin_right)


## The clock is a board of lit digits for a time and words for anything else, GAME.md 8.1a, every
## segment that is off still faintly there.
func test_the_clock_board_reads_a_time_in_digits() -> void:
	assert_bool(ClockBoard._is_time("4:56")).is_true()
	assert_bool(ClockBoard._is_time("OVERTIME")).is_false()
	assert_str(ClockBoard._unlit("4:56")).is_equal("8:88")
	assert_float(ClockBoard.digits_width("10:00")).is_greater(ClockBoard.digits_width("4:56"))
	var board := ClockBoard.new()
	board.text = "0:30"
	board.hot = true
	assert_bool(board.hot).is_true()
	board.free()


## A corner block is a strip bled off its own corner and striped in its player's color, holding
## the width it is given however the numbers in it grow.
func test_a_corner_block_is_a_strip_in_its_players_color() -> void:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	var match_node: Match = auto_free(load("res://scenes/match/match.tscn").instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(20, 17)
	var block: Dictionary = match_node.hud._blocks[0]
	var card: Control = block["box"]
	var strip := card.get_theme_stylebox(&"panel") as StripStyle
	assert_object(strip).is_not_null()
	assert_bool(strip.off_right).is_false()
	assert_object(strip.stripe).is_equal(match_node.slots[0].color())
	assert_float(card.get_global_rect().position.x).is_equal(0.0)
	assert_float(card.size.x).is_equal_approx(MatchHud.BLOCK_WIDTH, 0.5)
	# As big a pot as a match makes: thousands of coins at a mult in its twenties.
	match_node.kart_of(0).pot.coins = 2603
	match_node.kart_of(0).pot.mult = 24.5
	await runner.simulate_frames(4, 17)
	assert_float(card.size.x).is_equal_approx(MatchHud.BLOCK_WIDTH, 0.5)
	assert_object(block["nitro"]).is_instanceof(NitroCells)
	assert_object(block["speed_dial"]).is_instanceof(SpeedDial)


## A slip is torn along its top and its foot rather than notched, its teeth reaching the edge
## between the corners and its corners cut off.
func test_a_slip_is_torn_along_its_top_and_foot() -> void:
	var size := Vector2(300.0, 200.0)
	var edge := TicketStyle.outline(size, 0.0, PackedFloat32Array(), 10.0, true, true)
	var tips := 0
	for point: Vector2 in edge:
		if is_zero_approx(point.y) or is_equal_approx(point.y, size.y):
			tips += 1
	assert_int(tips).is_greater(20)
	assert_bool(Geometry2D.is_point_in_polygon(Vector2(1.0, 1.0), edge)).is_false()
	assert_bool(Geometry2D.is_point_in_polygon(Vector2(150.0, 100.0), edge)).is_true()


## The announcer's call stands on a plate; match point is run out on hazard tape behind it.
func test_a_call_stands_on_a_plate_and_match_point_on_tape() -> void:
	var banner := CallBanner.new()
	add_child(banner)
	banner.show_call("Ann", "DOUBLE KILL", Color.RED)
	assert_bool(banner.visible).is_true()
	assert_int(banner.dress).is_equal(CallBanner.Dress.CARDS)
	assert_str(banner.said()).is_equal("Ann  DOUBLE KILL")
	banner.show_call("Ann", MatchHud.WIN_CALL, Color.RED)
	assert_int(banner.dress).is_equal(CallBanner.Dress.TAPE)
	assert_bool(banner._behind.visible).is_true()
	banner.show_call("Ann", "ON FIRE", Color.RED)
	assert_bool(banner._flames[0].visible).is_true()
	banner.show_call("Ann", "TRADE KILL", Color.RED)
	assert_bool(banner._sign.visible).is_true()
	banner.show_call("Ann", "SOMETHING ELSE", Color.RED)
	assert_int(banner.dress).is_equal(CallBanner.Dress.PLATE)
	banner.put_away()
	assert_bool(banner.visible).is_false()
	banner.free()


## The title's sunburst and seal turn about the mark over the name, GAME.md 8.1a.
func test_the_title_turns_about_its_mark() -> void:
	var screen := Control.new()
	screen.size = Vector2(1600.0, 900.0)
	add_child(screen)
	var back := TitleBackground.add_to(screen)
	back.size = screen.size
	var mark := Control.new()
	mark.position = Vector2(700.0, 120.0)
	mark.size = Vector2(132.0, 132.0)
	screen.add_child(mark)
	back.anchor = mark
	await await_idle_frame()
	await await_idle_frame()
	assert_object(back.focus()).is_equal(Vector2(766.0, 186.0))
	assert_bool(back._seal.visible).is_true()
	mark.visible = false
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(back._seal.visible).is_false()
	screen.free()


## A hint hung over a kart stands on the house's tag, a small ticket, GAME.md 8.1a.
func test_a_hint_over_a_kart_stands_on_a_ticket() -> void:
	var card := InputHint.card(Label.new())
	assert_object(card.get_theme_stylebox(&"panel")).is_instanceof(TicketStyle)
	card.free()


## A switch that is on is not lit for it: the lit look is the cursor's alone.
func test_a_switch_that_is_on_is_not_lit() -> void:
	var on := MenuTheme.toggle(true)
	add_child(on)
	assert_object(on.get_theme_stylebox(&"pressed")).is_not_instanceof(TicketStyle)
	assert_object(on.get_theme_stylebox(&"focus")).is_instanceof(TicketStyle)
	on.queue_free()


## A texture is laid in tiles cut to the shape, so together they cover the ticket and nothing
## past it, and its tile repeats at the size it is made, GAME.md 8.1a.
func test_a_texture_covers_its_shape_in_tiles() -> void:
	var size := Vector2(530.0, 310.0)
	var edge := TicketStyle.outline(size, 12.0, PackedFloat32Array([90.0]), 10.0, true, false)
	var pieces := Surface.pieces(edge, size, 100.0)
	var covered := 0.0
	for piece: Dictionary in pieces:
		covered += _area(piece[&"points"])
		for uv: Vector2 in piece[&"uvs"]:
			(
				assert_bool(uv.x >= -0.001 and uv.x <= 1.001 and uv.y >= -0.001 and uv.y <= 1.001)
				. is_true()
			)
	assert_float(covered).is_equal_approx(_area(edge), 1.0)
	var tile := Surface.tile_of(Surface.Kind.PAPER)
	assert_int(tile.get_width()).is_equal(Surface.TILE)
	assert_int(Surface.named("scratched")).is_equal(Surface.Kind.SCRATCHED)


static func _area(points: PackedVector2Array) -> float:
	var twice := 0.0
	for i: int in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		twice += a.x * b.y - b.x * a.y
	return absf(twice) * 0.5


## The cursor's glide is on by default and kept switched off for anybody who turns it off in
## Accessibility, GAME.md 8.5.
func test_the_cursor_glide_can_be_switched_off_and_stays_off() -> void:
	var settings := Settings.new()
	assert_bool(settings.cursor_glide).is_true()
	settings.path = "user://test_cursor_glide.cfg"
	settings.cursor_glide = false
	assert_int(settings.save_to_disk()).is_equal(OK)
	var read := Settings.new()
	read.path = settings.path
	read.load_from_disk()
	assert_bool(read.cursor_glide).is_false()
	Settings.remove_files(settings.path)


## GAME.md 8.1a: the gold frame slides from one button to the next as the cursor goes, and not to
## or from one that cannot be pressed.
func test_the_cursor_glides_only_between_buttons_that_can_be_pressed() -> void:
	var glide: FocusGlide = auto_free(FocusGlide.new())
	add_child(glide)
	var row: HBoxContainer = auto_free(HBoxContainer.new())
	add_child(row)
	var buttons: Array[Button] = []
	for i: int in 3:
		var button := MenuTheme.button("Button %d" % i)
		row.add_child(button)
		buttons.append(button)
	buttons[2].disabled = true
	await await_idle_frame()
	buttons[0].grab_focus()
	buttons[1].grab_focus()
	assert_object(glide._target).is_same(buttons[1])
	assert_float(glide._t).is_less(1.0)
	glide._t = 1.0
	buttons[2].grab_focus()
	assert_float(glide._t).is_equal(1.0)
	buttons[2].disabled = false
	buttons[2].release_focus()
	buttons[1].grab_focus()
	buttons[2].disabled = true
	glide._t = 1.0
	buttons[2].grab_focus()
	buttons[2].disabled = false
	assert_float(glide._t).is_equal(1.0)


## The part of a pane that scrolls is as tall as what it holds while there is room for it, and no
## taller than the screen leaves once the rest of the pane has its room, GAME.md 8.5.
func test_a_pane_too_tall_for_the_screen_scrolls_its_body() -> void:
	var pane := PanelContainer.new()
	var column := VBoxContainer.new()
	pane.add_child(column)
	var head := Control.new()
	head.custom_minimum_size = Vector2(200.0, 100.0)
	column.add_child(head)
	var body := Control.new()
	body.custom_minimum_size = Vector2(200.0, 300.0)
	var scroll := FitScroll.around(body, pane)
	column.add_child(scroll)
	add_child(pane)
	await await_idle_frame()
	scroll.fit()
	assert_float(scroll.custom_minimum_size.y).is_equal(300.0)
	body.custom_minimum_size.y = 5000.0
	scroll.fit()
	var screen := scroll.get_viewport_rect().size.y
	assert_float(scroll.custom_minimum_size.y).is_less(screen)
	assert_float(pane.get_combined_minimum_size().y).is_less_equal(screen)
	pane.free()


## The finishes as chosen, GAME.md 8.1a, each control taking the tile from a place of its own so
## two buttons are not one texture twice, and the felt laid at two scales so no clump of it repeats
## across the screen as a grid.
func test_each_control_takes_the_texture_from_its_own_place() -> void:
	assert_int(int(Surface.finish("foil")[0])).is_equal(Surface.Kind.BRUSHED)
	assert_int(int(Surface.finish("hud")[0])).is_equal(Surface.Kind.SCRATCHED)
	assert_int(int(Surface.finish("backdrop")[0])).is_equal(Surface.Kind.FELT)
	var size := Vector2(300.0, 60.0)
	var edge := TicketStyle.outline(size, 9.0)
	var one: Array = Surface._laid(edge, size, Surface.Kind.SCRATCHED, 1.0, 3)
	var other: Array = Surface._laid(edge, size, Surface.Kind.SCRATCHED, 1.0, 5)
	assert_int(one.size()).is_equal(1)
	var first: Dictionary = one[0][0]
	var second: Dictionary = other[0][0]
	assert_bool(first[&"uvs"] == second[&"uvs"]).is_false()
	assert_int(Surface._laid(edge, size, Surface.Kind.FELT, 1.0, 3).size()).is_equal(2)
