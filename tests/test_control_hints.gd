extends GdUnitTestSuite
## On-screen control hints, GAME.md 8.3: which button is shown, when it is worth showing, and
## whether it is drawn as a key or as a gamepad button. The hints are pictures rather than words,
## so what a test reads off one is the caption on each picture and the words in between.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const BOOST: PowerUp = preload("res://data/powerups/boost.tres")

var _runner: GdUnitSceneRunner
var _hints_were := true


func before_test() -> void:
	_hints_were = Game.settings.control_hints
	Game.settings.control_hints = true


func after_test() -> void:
	Game.settings.control_hints = _hints_were


## What a hint row says: every caption and every word in it, in the order they are drawn, so a
## test can ask what a row of pictures is a row of pictures of.
func _reads(node: Node) -> String:
	var parts: PackedStringArray = []
	var glyph := node as InputGlyph
	if glyph != null and not glyph.caption.is_empty():
		parts.append(glyph.caption)
	var label := node as Label
	if label != null:
		parts.append(label.text)
	for child: Node in node.get_children():
		var said := _reads(child)
		if not said.is_empty():
			parts.append(said)
	return " ".join(parts).strip_edges()


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(), KartInput.new()]
	match_node.start(inputs, 47)
	return match_node


func test_a_pinned_device_names_its_own_scheme_and_any_follows_the_last_touched() -> void:
	assert_bool(DeviceInput.uses_keyboard(DeviceInput.KEYBOARD)).is_true()
	assert_bool(DeviceInput.uses_keyboard(0)).is_false()
	var was := Game.last_input_keyboard
	Game.last_input_keyboard = true
	assert_bool(DeviceInput.uses_keyboard(DeviceInput.ANY)).is_true()
	Game.last_input_keyboard = false
	assert_bool(DeviceInput.uses_keyboard(DeviceInput.ANY)).is_false()
	# A real push on a stick counts as picking the pad up; a twitch does not.
	Game.last_input_keyboard = true
	var twitch := InputEventJoypadMotion.new()
	twitch.axis = JOY_AXIS_LEFT_X
	twitch.axis_value = 0.2
	Game._input(twitch)
	assert_bool(Game.last_input_keyboard).is_true()
	twitch.axis_value = 0.9
	Game._input(twitch)
	assert_bool(Game.last_input_keyboard).is_false()
	var key := InputEventKey.new()
	key.keycode = KEY_W
	Game._input(key)
	assert_bool(Game.last_input_keyboard).is_true()
	Game.last_input_keyboard = was


func test_each_hint_shows_only_while_it_is_worth_pressing() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var hud := match_node.hud
	var block: Dictionary = hud._blocks[0]
	var holder: Control = block["hints"]
	var kart := match_node.kart_of(0)
	# Parked, full tank, empty hands: only the nitro reminder is worth showing.
	kart.motor.velocity = Vector3.ZERO
	kart.nitro_charge = 1.0
	kart.held_item = null
	hud._update_hints(block, kart, DeviceInput.KEYBOARD)
	assert_bool(holder.visible).is_true()
	assert_str(_reads(holder)).contains("nitro")
	assert_str(_reads(holder)).not_contains("drift")
	assert_str(_reads(holder)).not_contains("item")
	# An empty tank takes its reminder away again.
	kart.nitro_charge = 0.0
	hud._update_hints(block, kart, DeviceInput.KEYBOARD)
	assert_bool(holder.visible).is_false()
	# Up to speed with an item in hand: both of those show instead.
	kart.motor.velocity = Vector3(kart.stats.top_speed, 0.0, 0.0)
	kart.held_item = BOOST
	kart.item_reveal_left = 0.0
	hud._update_hints(block, kart, DeviceInput.KEYBOARD)
	assert_str(_reads(holder)).contains("drift")
	assert_str(_reads(holder)).contains("item")
	# An item still rolling in the roulette cannot be played yet.
	kart.item_reveal_left = 0.4
	hud._update_hints(block, kart, DeviceInput.KEYBOARD)
	assert_str(_reads(holder)).not_contains("item")
	# The setting puts the whole row away.
	Game.settings.control_hints = false
	hud._update_hints(block, kart, DeviceInput.KEYBOARD)
	assert_bool(holder.visible).is_false()


func test_hints_are_named_for_the_scheme_in_use() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var hud := match_node.hud
	var block: Dictionary = hud._blocks[0]
	var holder: Control = block["hints"]
	var kart := match_node.kart_of(0)
	kart.nitro_charge = 1.0
	hud._update_hints(block, kart, DeviceInput.KEYBOARD)
	var keys := _reads(holder)
	hud._update_hints(block, kart, 0)
	assert_str(_reads(holder)).is_not_equal(keys)
	assert_str(keys).contains(InputActions.short_binding_text(InputActions.NITRO, true))
	assert_str(_reads(holder)).contains(InputActions.short_binding_text(InputActions.NITRO, false))
	# And the pad is drawn as a pad: the shoulder button is a pill, not a key cap.
	var pad_glyph: InputGlyph = null
	for child: Node in holder.get_child(0).get_children():
		if child is InputGlyph:
			pad_glyph = child
	assert_int(pad_glyph.kind).is_equal(InputGlyph.Kind.SHOULDER)


## GAME.md 8.3: a life is a heart, in the player's colour while it is theirs and grey once it
## is spent. A square said "one of something" and left you to work out what.
func test_lives_are_hearts_that_grey_out_as_they_are_lost() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var hud := match_node.hud
	var block: Dictionary = hud._blocks[0]
	var pips: Array = block["lives"]
	var kart := match_node.kart_of(0)
	assert_int(pips.size()).is_equal(match_node.rules.lives)
	for pip: Variant in pips:
		assert_object(pip).is_instanceof(Heart)
	hud._update_blocks()
	assert_object((pips[0] as Heart).color).is_equal(match_node.slots[0].color())
	# A life short: the last heart goes grey while the rest keep their colour.
	kart.lives = match_node.rules.lives - 1
	hud._update_blocks()
	assert_object((pips[0] as Heart).color).is_equal(match_node.slots[0].color())
	assert_object((pips[pips.size() - 1] as Heart).color).is_equal(MatchHud.LIFE_LOST)


## GAME.md 8.3a: the held item shows its own picture beside its name, and while the box is still
## opening the picture flicks through the others rather than showing question marks.
func test_the_held_item_shows_its_picture() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var hud := match_node.hud
	var block: Dictionary = hud._blocks[0]
	var kart := match_node.kart_of(0)
	var row: ItemRow = block["item"]
	var art: PowerUpArt.Picture = row.art
	var label: Label = row.label
	# Empty handed: no line at all.
	kart.held_item = null
	hud._update_blocks()
	assert_bool(art.get_parent().visible).is_false()
	# Holding one: its own picture and its own name.
	kart.held_item = BOOST
	kart.item_reveal_left = 0.0
	hud._update_blocks()
	assert_bool(art.get_parent().visible).is_true()
	assert_str(String(art.id)).is_equal("boost")
	assert_str(label.text).is_equal(kart.held_item.display_name)
	# Still turning: something else on the picture and no name yet.
	kart.item_reveal_left = 0.4
	hud._update_blocks()
	assert_str(label.text).is_empty()
	assert_bool(PowerUpArt.known().has(art.id)).is_true()


## GAME.md 3.6: a life going is a heart coming apart, in two pieces with a crack between them,
## rather than the words "-1 LIFE" over a kart somebody is trying to drive.
func test_a_broken_heart_is_two_pieces_with_a_gap_down_the_middle() -> void:
	var halves := Heart.broken_shapes()
	assert_int(halves.size()).is_equal(2)
	var left := 0.0
	var right := 1.0
	for piece: PackedVector2Array in halves:
		assert_int(piece.size()).is_greater(3)
		var middle := 0.0
		for point: Vector2 in piece:
			middle += point.x
		middle /= piece.size()
		if middle < 0.5:
			for point: Vector2 in piece:
				left = maxf(left, point.x)
		else:
			for point: Vector2 in piece:
				right = minf(right, point.x)
	# The two halves do not meet: there is a crack between them at the widest part.
	assert_float(left).is_less(0.52)
	assert_float(right).is_greater(0.46)
	# And together they are still most of a heart rather than slivers of one.
	var whole := 0
	for piece: PackedVector2Array in halves:
		whole += piece.size()
	assert_int(whole).is_greater(Heart.POINTS / 2)


## And it turns into something the room can see: a flat billboarded mesh that rises and takes
## itself off the screen when it is done.
func test_a_floating_icon_builds_a_mesh_and_clears_itself_up() -> void:
	var root: Node3D = auto_free(Node3D.new())
	var runner: GdUnitSceneRunner = scene_runner(root)
	var icon := FloatingIcon.spawn(root, Vector3.ZERO, Heart.broken_shapes(), Color.RED, 1.6, 0.2)
	assert_object(icon).is_not_null()
	var face: MeshInstance3D = icon.get_child(0)
	var points: PackedVector3Array = face.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	# Triangulated, so a whole number of triangles and more than one of them.
	assert_int(points.size() % 3).is_equal(0)
	assert_int(points.size()).is_greater(6)
	var high := icon.position.y
	await runner.simulate_frames(4, 17)
	assert_float(icon.position.y).is_greater(high)
	await runner.simulate_frames(30, 17)
	assert_bool(is_instance_valid(icon)).is_false()


## The shape is a heart rather than a box: it has the dip at the top and the point at the bottom
## that tell one from the other at the size a pip is drawn.
func test_the_heart_has_a_dip_at_the_top_and_a_point_at_the_bottom() -> void:
	var shape := Heart.unit_shape()
	assert_int(shape.size()).is_greater(20)
	var middle_top := 1.0
	var shoulder_top := 1.0
	var widest := 0.0
	for point: Vector2 in shape:
		if absf(point.x - 0.5) < 0.04:
			middle_top = minf(middle_top, point.y)
		if absf(point.x - 0.26) < 0.06:
			shoulder_top = minf(shoulder_top, point.y)
		widest = maxf(widest, absf(point.x - 0.5))
	# The shoulders stand above the dip between them.
	assert_float(shoulder_top).is_less(middle_top - 0.05)
	# And it comes to a point: the bottom is narrow where the top is wide.
	var bottom := 0.0
	for point: Vector2 in shape:
		if point.y > 0.9:
			bottom = maxf(bottom, absf(point.x - 0.5))
	assert_float(bottom).is_less(widest * 0.25)


func test_the_joker_menu_cap_shows_beside_a_hand_with_cards_in_it() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var hand: JokerHand = match_node.hud._hands[0]
	var kart := match_node.kart_of(0)
	assert_object(hand._cap).is_null()
	kart.jokers.add(load("res://data/jokers/big_tank.tres"))
	await _runner.simulate_frames(4, 17)
	assert_object(hand._cap).is_not_null()
	var cap: InputGlyph = hand._cap
	assert_str(cap.caption).is_equal(
		InputActions.short_binding_text(InputActions.JOKER_MENU, hand.keyboard)
	)
	# It sits to the left of the leftmost card.
	assert_float(cap.position.x).is_less(hand._cards[0].position.x)
	Game.settings.control_hints = false
	await _runner.simulate_frames(4, 17)
	assert_object(hand._cap).is_null()


## GAME.md 3.8: the hint shows the button that actually fires. Naming one in the text meant it
## went on saying RB long after firing had moved off the shoulder.
func test_the_gamepad_hint_shows_whatever_fire_is_bound_to() -> void:
	InputActions.register_defaults()
	var bound := InputActions.binding_text(InputActions.FIRE, false).get_slice(",", 0)
	var row: HBoxContainer = auto_free(ControlHint.hint_row(0))
	assert_str(_reads(row)).contains("%s fire" % bound)
	InputActions.rebind(InputActions.FIRE, {"button": JOY_BUTTON_RIGHT_SHOULDER})
	var moved: HBoxContainer = auto_free(ControlHint.hint_row(0))
	assert_str(_reads(moved)).contains("RB fire")
	InputActions.register_defaults()


## GAME.md 8.3: two ends of one stick are one stick. On a pad the steering is drawn as a single
## stick rather than as two halves of an axis; on a keyboard they really are two keys and both
## are drawn.
func test_a_stick_is_drawn_once_rather_than_as_two_axis_halves() -> void:
	InputActions.register_defaults()
	var ink := Color.WHITE
	var pad: Control = auto_free(
		InputHint.pair(InputActions.STEER_LEFT, InputActions.STEER_RIGHT, false, ink, 15)
	)
	assert_object(pad).is_instanceof(InputGlyph)
	assert_int((pad as InputGlyph).kind).is_equal(InputGlyph.Kind.STICK)
	# And it says which of the two sticks it is, written inside the gate it is drawn as.
	assert_str((pad as InputGlyph).caption).is_equal("L")
	assert_float(pad.custom_minimum_size.x).is_greater(pad.custom_minimum_size.y)
	var keys: Control = auto_free(
		InputHint.pair(InputActions.STEER_LEFT, InputActions.STEER_RIGHT, true, ink, 15)
	)
	assert_int(keys.get_child_count()).is_equal(2)
	assert_int((keys.get_child(0) as InputGlyph).kind).is_equal(InputGlyph.Kind.KEY)
	# Two actions that are not two ends of one stick fall back to drawing both.
	assert_str(InputActions.shared_stick(InputActions.FIRE, InputActions.NITRO)).is_empty()
	var apart: Control = auto_free(
		InputHint.pair(InputActions.FIRE, InputActions.NITRO, false, ink, 15)
	)
	assert_int(apart.get_child_count()).is_equal(2)


## And the joker screens use it, which is where a player reads it.
func test_the_joker_screens_draw_the_stick_once() -> void:
	var picker: JokerPicker = auto_free(JokerPicker.new())
	add_child(picker)
	picker.keyboard = false
	var row: HBoxContainer = auto_free(picker._hint_row(true))
	assert_int((row.get_child(0) as InputGlyph).kind).is_equal(InputGlyph.Kind.STICK)
	assert_str(_reads(row)).contains("choose")
	assert_str(_reads(row)).not_contains("Axis")


## GAME.md 8.3: what a power-up started is named under the item that started it, and counts down.
func test_a_running_power_up_says_what_it_is_and_how_long_is_left() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var hud := match_node.hud
	var row: ItemRow = hud._blocks[0]["item"]
	var kart := match_node.kart_of(0)
	# Nothing running: no line for it.
	hud._update_blocks()
	assert_bool(row.running.get_parent().visible).is_false()
	# One playing: its own name, in its own colour, with the time left beside it.
	kart.held_item = BOOST
	kart.item_reveal_left = 0.0
	kart.use_item()
	hud._update_blocks()
	assert_bool(row.running.get_parent().visible).is_true()
	assert_str(row.running.text).is_equal(BOOST.display_name)
	assert_float(row.clock.value).is_greater(50.0)
	# And it runs down rather than sitting where it started.
	var effect: KartEffect = kart.effects[0]
	effect.time_left = effect.duration * 0.25
	hud._update_blocks()
	assert_float(row.clock.value).is_less(30.0)
