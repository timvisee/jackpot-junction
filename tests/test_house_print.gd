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


## The perforation under a pane's header tells the pane where it is, so the pane tears there.
func test_a_perforation_tells_its_pane_where_to_tear() -> void:
	var pane := MenuTheme.pane()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	pane.add_child(column)
	var title := MenuTheme.title("Heading", Type.TITLE)
	column.add_child(title)
	column.add_child(MenuTheme.perforation())
	column.add_child(MenuTheme.button("Below"))
	add_child(pane)
	await await_idle_frame()
	await await_idle_frame()
	var style := pane.get_theme_stylebox(&"panel") as TicketStyle
	assert_int(style.perforations.size()).is_equal(1)
	var expected := style.content_margin_top + title.size.y + Perforation.HEIGHT * 0.5
	assert_float(style.perforations[0]).is_equal_approx(roundf(expected), 1.0)
	pane.queue_free()


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


## A switch that is on is not lit for it: the lit look is the cursor's alone.
func test_a_switch_that_is_on_is_not_lit() -> void:
	var on := MenuTheme.toggle(true)
	add_child(on)
	assert_object(on.get_theme_stylebox(&"pressed")).is_not_instanceof(TicketStyle)
	assert_object(on.get_theme_stylebox(&"focus")).is_instanceof(TicketStyle)
	on.queue_free()
