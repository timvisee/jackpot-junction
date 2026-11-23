extends GdUnitTestSuite
## The blueprint of the pad in hand, GAME.md 8.3b: which drawing each family of pad gets and what
## its buttons are called, which button each binding is, what each sheet says at each button as the
## actions are bound, and the blueprint itself: its sheets, its keys and its way out.

var _holder: Control
var _fire_was: Array[InputEvent] = []


func before_test() -> void:
	PadFamily.reset()
	PadFamily.pretend = -1
	_holder = Control.new()
	_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_holder)
	_fire_was.assign(InputMap.action_get_events(InputActions.FIRE))


func after_test() -> void:
	InputMap.action_erase_events(InputActions.FIRE)
	for event: InputEvent in _fire_was:
		InputMap.action_add_event(InputActions.FIRE, event)
	PadFamily.pretend = -1
	PadFamily.reset()
	if is_instance_valid(_holder):
		remove_child(_holder)
		_holder.free()


func _button(index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	return event


func _axis(axis: JoyAxis) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = 1.0
	return event


func _pressed(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


## The words at each button of a page, joined as the leaflet prints them.
func _page(on_page: int, family: PadFamily.Family, simple := false) -> Dictionary:
	var said := PadLeaflet.labels(on_page, simple, PadDiagram.of(family))
	var words: Dictionary = {}
	for spot: StringName in said:
		var each: Array[String] = said[spot]["words"]
		words[spot] = PadLeaflet.joined(each)
	return words


func test_each_binding_is_a_button_on_the_drawing() -> void:
	assert_str(PadDiagram.spot_of(_button(JOY_BUTTON_A))).is_equal("south")
	assert_str(PadDiagram.spot_of(_button(JOY_BUTTON_Y))).is_equal("north")
	assert_str(PadDiagram.spot_of(_button(JOY_BUTTON_DPAD_LEFT))).is_equal("dpad")
	assert_str(PadDiagram.spot_of(_button(JOY_BUTTON_START))).is_equal("menu")
	assert_str(PadDiagram.spot_of(_axis(JOY_AXIS_TRIGGER_RIGHT))).is_equal("rt")
	assert_str(PadDiagram.spot_of(_axis(JOY_AXIS_RIGHT_Y))).is_equal("rs")
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	assert_str(PadDiagram.spot_of(key)).is_empty()
	assert_str(PadDiagram.spot_of(_button(JOY_BUTTON_PADDLE1))).is_empty()


func test_each_family_has_its_drawing_and_its_names() -> void:
	var family := PadFamily.Family
	assert_object(PadDiagram.of(family.PLAYSTATION).art).is_same(PadDiagram.PS5_ART)
	assert_object(PadDiagram.of(family.PLAYSTATION_4).art).is_same(PadDiagram.PS4_ART)
	assert_object(PadDiagram.of(family.XBOX).art).is_same(PadDiagram.XBOX_ART)
	# A Nintendo pad and a generic one have an Xbox pad's layout, and its drawing.
	assert_object(PadDiagram.of(family.NINTENDO).art).is_same(PadDiagram.XBOX_ART)
	assert_object(PadDiagram.of(family.GENERIC).art).is_same(PadDiagram.XBOX_ART)
	assert_str(PadDiagram.of(family.GENERIC).name_of(&"south")).is_equal("A")
	assert_str(PadDiagram.of(family.NINTENDO).name_of(&"south")).is_equal("B")
	assert_str(PadDiagram.of(family.NINTENDO).name_of(&"rt")).is_equal("ZR")
	assert_str(PadDiagram.of(family.PLAYSTATION).name_of(&"north")).is_equal("Triangle")
	assert_str(PadDiagram.of(family.PLAYSTATION_4).name_of(&"view")).is_equal("Share")
	assert_str(PadDiagram.of(family.PLAYSTATION).name_of(&"ls")).is_equal("Left stick")
	# Only a PlayStation pad has a touchpad to draw a line to.
	assert_bool(PadDiagram.of(family.PLAYSTATION).shows(&"touch")).is_true()
	assert_bool(PadDiagram.of(family.XBOX).shows(&"touch")).is_false()


func test_the_driving_page_says_what_each_button_does() -> void:
	var words := _page(0, PadFamily.Family.XBOX)
	assert_str(words[&"rt"]).is_equal("Gas")
	assert_str(words[&"lt"]).is_equal("Brake")
	assert_str(words[&"ls"]).is_equal("Steer")
	assert_str(words[&"south"]).is_equal("Fire")
	assert_str(words[&"west"]).is_equal("Use item")
	assert_str(words[&"north"]).is_equal("Joker hand")
	assert_str(words[&"lb"]).is_equal("Drift")
	assert_str(words[&"rb"]).is_equal("Nitro")
	assert_str(words[&"rs"]).is_equal("Aim")
	# Two things on one button, as one line.
	assert_str(words[&"menu"]).is_equal("Pause  ·  join")
	var said := PadLeaflet.labels(0, false, PadDiagram.of(PadFamily.Family.XBOX))
	assert_str(said[&"rt"]["note"]).is_equal("squeeze, don't stab")
	# Driving the simple way, the stick says the way to go.
	assert_str(_page(0, PadFamily.Family.XBOX, true)[&"ls"]).is_equal("Drive")


func test_the_other_pages() -> void:
	var jokers := _page(1, PadFamily.Family.PLAYSTATION)
	assert_str(jokers[&"south"]).is_equal("Drop  ·  take")
	assert_str(jokers[&"dpad"]).is_equal("Previous / next joker")
	assert_str(jokers[&"rs"]).is_equal("Details")
	var menus := _page(2, PadFamily.Family.PLAYSTATION)
	assert_str(menus[&"south"]).is_equal("Choose")
	assert_str(menus[&"east"]).is_equal("Back")
	assert_str(menus[&"lb"]).is_equal("Previous page")
	assert_str(menus[&"dpad"]).contains("Move")


## A binding changed moves its words to the button it is on now.
func test_a_rebinding_moves_the_words() -> void:
	InputMap.action_erase_events(InputActions.FIRE)
	InputMap.action_add_event(InputActions.FIRE, _button(JOY_BUTTON_RIGHT_SHOULDER))
	var words := _page(0, PadFamily.Family.XBOX)
	assert_bool(words.has(&"south")).is_false()
	assert_str(words[&"rb"]).is_equal("Nitro  ·  fire")


func test_the_leaflet_turns_its_pages_and_is_put_away() -> void:
	var from := Button.new()
	_holder.add_child(from)
	var leaflet := PadLeaflet.open(_holder, PadFamily.Family.PLAYSTATION, false, from)
	await get_tree().process_frame
	assert_int(leaflet.page).is_equal(0)
	assert_object(leaflet.diagram.art).is_same(PadDiagram.PS5_ART)
	leaflet._input(_pressed(InputActions.MENU_PAGE_NEXT))
	assert_int(leaflet.page).is_equal(1)
	leaflet._input(_pressed(InputActions.MENU_PAGE_PREV))
	leaflet._input(_pressed(InputActions.MENU_PAGE_PREV))
	assert_int(leaflet.page).is_equal(2)
	# A tab clicked turns to its page.
	(leaflet.get_node("Around/Pane/Sheet/Tab0") as Button).pressed.emit()
	assert_int(leaflet.page).is_equal(0)
	var away := [false]
	leaflet.put_away.connect(func() -> void: away[0] = true)
	leaflet._input(_pressed(&"ui_cancel"))
	assert_bool(away[0]).is_true()
	assert_bool(leaflet.is_queued_for_deletion()).is_true()
	assert_object(get_viewport().gui_get_focus_owner()).is_same(from)


## It lies over the screen as the catalog does, the screen round it, and fills a short one; the
## sheet as big as the pane, whatever its shape, the pad and its words fitting in it.
func test_it_lies_over_the_screen_and_fills_a_short_one() -> void:
	var leaflet := PadLeaflet.open(_holder, PadFamily.Family.XBOX)
	var around := leaflet.get_node("Around") as MarginContainer
	var pane := leaflet.get_node("Around/Pane") as Control
	var sheet := leaflet.get_node("Around/Pane/Sheet") as Control
	for room: Vector2 in [Vector2(1920.0, 1080.0), Vector2(1600.0, 1200.0)]:
		leaflet.size = room
		await get_tree().process_frame
		assert_int(around.get_theme_constant(&"margin_left")).is_greater(0)
		assert_bool(pane.size.x < room.x and pane.size.y < room.y).is_true()
		assert_vector(sheet.size * sheet.scale).is_equal_approx(pane.size, Vector2.ONE)
		assert_bool(sheet.size.x >= PadLeaflet.SIZE.x - 0.5).is_true()
		assert_bool(sheet.size.y >= PadLeaflet.SIZE.y - 0.5).is_true()
	leaflet.size = Vector2(1280.0, 800.0) / 1.5
	await get_tree().process_frame
	assert_int(around.get_theme_constant(&"margin_left")).is_equal(0)
	assert_vector(pane.size).is_equal_approx(leaflet.size, Vector2.ONE)
	leaflet.close()


## Its tabs say for a screen reader what each page shows, and the button that puts it up opens it
## for the pad touched last.
func test_its_button_opens_it_for_the_pad_in_hand() -> void:
	PadFamily.pretend = PadFamily.Family.NINTENDO
	var button := PadLeaflet.entry(_holder)
	_holder.add_child(button)
	assert_str(button.name).is_equal("PadLeafletButton")
	assert_str(button.text).is_equal(PadLeaflet.ENTRY)
	button.pressed.emit()
	var leaflet := _holder.get_node("PadLeaflet") as PadLeaflet
	assert_object(leaflet).is_not_null()
	assert_int(leaflet.family).is_equal(PadFamily.Family.NINTENDO)
	var tab := leaflet.get_node("Around/Pane/Sheet/Tab0") as Button
	# Its tabs light up along their own edges, so the gold frame the cursor slides in leaves them.
	assert_bool(FocusGlide._glides(tab)).is_false()
	assert_bool(FocusGlide._glides(leaflet.get_node("Around/Pane/Sheet/Back") as Button)).is_false()
	assert_str(tab.accessibility_name).contains(PadLeaflet.TITLE)
	assert_str(tab.accessibility_description).contains("Gas: ZR")
	leaflet.close()


## The booth's demo keeps its menus to what a passer-by needs, GAME.md 9.8: no leaflet in them.
func test_not_in_the_booths_demo() -> void:
	var was := Demo.on
	Demo.on = true
	var button := PadLeaflet.entry(_holder)
	var line := PadLeaflet.row(_holder)
	Demo.on = was
	assert_bool(button.visible).is_false()
	assert_bool(line.visible).is_false()
	button.free()
	line.free()
	var shown := PadLeaflet.row(_holder)
	assert_bool(shown.visible).is_true()
	shown.free()


## A Steam Deck is drawn from Valve's drawings where a Steam build has them, its top turned over
## above its front, and as an Xbox pad elsewhere, with its own names either way.
func test_the_steam_deck_is_drawn_from_valves_drawings_where_they_are() -> void:
	var deck := PadDiagram.of(PadFamily.Family.STEAM_DECK)
	assert_str(deck.name_of(&"rt")).is_equal("R2")
	assert_str(deck.name_of(&"south")).is_equal("A")
	if not ResourceLoader.exists(PadDiagram.DECK_FRONT):
		assert_object(deck.art).is_same(PadDiagram.XBOX_ART)
		assert_int(deck.layers.size()).is_equal(1)
		return
	# Each view in two, the middle left out, with a break line at each edge of it in both.
	assert_int(deck.layers.size()).is_equal(4)
	assert_int(deck.breaks.size()).is_equal(4)
	assert_bool(deck.layers[0]["flip"]).is_true()
	assert_bool(deck.layers[1]["flip"]).is_true()
	assert_float(deck.size.x).is_less(PadDiagram.DECK_WIDE * PadDiagram.DECK_UNIT)
	assert_float(deck.face_radius).is_equal_approx(
		PadDiagram.DECK_FACE_RADIUS * PadDiagram.DECK_UNIT, 0.01
	)
	# The front under the top, and every button within the drawing.
	assert_float(deck.layers[2]["at"].y).is_greater(deck.layers[0]["size"].y)
	var whole := Rect2(Vector2.ZERO, deck.size)
	for spot: StringName in deck.spots:
		assert_bool(whole.has_point(deck.spots[spot])).is_true()
