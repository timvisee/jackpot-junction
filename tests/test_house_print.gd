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


## A switch that is on is not lit for it: the lit look is the cursor's alone.
func test_a_switch_that_is_on_is_not_lit() -> void:
	var on := MenuTheme.toggle(true)
	add_child(on)
	assert_object(on.get_theme_stylebox(&"pressed")).is_not_instanceof(TicketStyle)
	assert_object(on.get_theme_stylebox(&"focus")).is_instanceof(TicketStyle)
	on.queue_free()
