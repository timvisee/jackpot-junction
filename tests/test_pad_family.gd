extends GdUnitTestSuite
## A pad's buttons drawn as its family prints them, GAME.md 8.3: which family a pad is, by its
## maker's id or its name; what each family calls the buttons; and the hints that follow the pad
## touched last, or the pad of the player they are for.

## Pads that are not plugged in, with the family each is taken to be.
const PS5_PAD := 41
const SWITCH_PAD := 42

var _keyboard_was := true


func before_test() -> void:
	PadFamily.reset()
	PadFamily.pretend = -1
	_keyboard_was = Game.last_input_keyboard


func after_test() -> void:
	PadFamily.reset()
	PadFamily.pretend = -1
	Game.last_input_keyboard = _keyboard_was
	DeviceInput.recent.clear()


## A pad as the engine tells of it: its maker's and its product's USB ids, as it gives them.
func _info(maker: int, product: int, named := "") -> Dictionary:
	return {"vendor_id": str(maker), "product_id": str(product), "raw_name": named}


## The two pads above as if plugged in, without asking the engine about them.
func _plug_in() -> void:
	PadFamily._known[PS5_PAD] = PadFamily.Family.PLAYSTATION
	PadFamily._known[SWITCH_PAD] = PadFamily.Family.NINTENDO


func _button(index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	return event


func _trigger(axis: JoyAxis) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = 1.0
	return event


func test_a_pads_family_comes_from_its_maker_and_then_its_name() -> void:
	var family := PadFamily.Family
	assert_int(PadFamily.of_pad(_info(PadFamily.SONY, 0x0CE6), "")).is_equal(family.PLAYSTATION)
	assert_int(PadFamily.of_pad(_info(PadFamily.SONY, 0x09CC), "")).is_equal(family.PLAYSTATION_4)
	assert_int(PadFamily.of_pad(_info(PadFamily.NINTENDO, 0x2009), "")).is_equal(family.NINTENDO)
	assert_int(PadFamily.of_pad(_info(PadFamily.MICROSOFT, 0x0B13), "")).is_equal(family.XBOX)
	# A pad of another maker by its name, as a phone tells of one, and anything else as generic.
	assert_int(PadFamily.of_pad({}, "DualSense Wireless Controller")).is_equal(family.PLAYSTATION)
	assert_int(PadFamily.of_pad({}, "Pro Controller")).is_equal(family.NINTENDO)
	assert_int(PadFamily.of_pad({}, "Xbox 360 Controller")).is_equal(family.XBOX)
	assert_int(PadFamily.of_pad(_info(0x28DE, 0x11FF), "Steam Virtual Gamepad")).is_equal(
		family.GENERIC
	)
	assert_int(PadFamily.of_pad(_info(0x1C11, 0xB04D), "Ergodox")).is_equal(family.GENERIC)
	assert_int(PadFamily.of_pad({}, "")).is_equal(family.GENERIC)


func test_each_family_names_the_buttons_it_prints() -> void:
	var family := PadFamily.Family
	var named := func(event: InputEvent, drawn: int) -> String:
		return InputActions.event_text(event, drawn)
	var bottom := _button(JOY_BUTTON_A)
	assert_str(named.call(bottom, family.GENERIC)).is_equal("A")
	assert_str(named.call(bottom, family.XBOX)).is_equal("A")
	assert_str(named.call(bottom, family.PLAYSTATION)).is_equal("Cross")
	assert_str(named.call(bottom, family.NINTENDO)).is_equal("B")
	var right := _button(JOY_BUTTON_B)
	assert_str(named.call(right, family.NINTENDO)).is_equal("A")
	assert_str(named.call(_button(JOY_BUTTON_LEFT_SHOULDER), family.PLAYSTATION)).is_equal("L1")
	assert_str(named.call(_button(JOY_BUTTON_LEFT_SHOULDER), family.NINTENDO)).is_equal("L")
	assert_str(named.call(_trigger(JOY_AXIS_TRIGGER_RIGHT), family.XBOX)).is_equal("RT")
	assert_str(named.call(_trigger(JOY_AXIS_TRIGGER_RIGHT), family.PLAYSTATION)).is_equal("R2")
	assert_str(named.call(_trigger(JOY_AXIS_TRIGGER_RIGHT), family.NINTENDO)).is_equal("ZR")
	var back := _button(JOY_BUTTON_BACK)
	assert_str(named.call(back, family.XBOX)).is_equal("View")
	assert_str(named.call(back, family.PLAYSTATION)).is_equal("Create")
	assert_str(named.call(back, family.PLAYSTATION_4)).is_equal("Share")
	assert_str(named.call(back, family.NINTENDO)).is_equal("−")
	assert_str(named.call(_button(JOY_BUTTON_START), family.PLAYSTATION)).is_equal("Options")
	assert_str(named.call(_button(JOY_BUTTON_START), family.NINTENDO)).is_equal("+")
	assert_str(named.call(_button(JOY_BUTTON_LEFT_STICK), family.PLAYSTATION)).is_equal("L3")
	# A binding said in words, as a screen reader is told it.
	(
		assert_str(InputActions.short_binding_text(InputActions.FIRE, false, family.PLAYSTATION))
		. is_equal("Cross")
	)


func test_the_pad_touched_last_is_the_one_drawn() -> void:
	_plug_in()
	assert_int(PadFamily.shown()).is_equal(PadFamily.Family.GENERIC)
	var epoch := PadFamily.epoch
	DeviceInput.touched(PS5_PAD)
	assert_int(PadFamily.shown()).is_equal(PadFamily.Family.PLAYSTATION)
	assert_int(PadFamily.epoch).is_greater(epoch)
	# The keyboard picked up in between leaves the pad that was last touched drawn.
	DeviceInput.touched(DeviceInput.KEYBOARD)
	assert_int(PadFamily.shown()).is_equal(PadFamily.Family.PLAYSTATION)
	DeviceInput.touched(SWITCH_PAD)
	assert_int(PadFamily.shown()).is_equal(PadFamily.Family.NINTENDO)
	assert_str(InputActions.short_binding_text(InputActions.FIRE, false)).is_equal("B")
	DeviceInput.recent.clear()


func test_a_glyph_follows_the_pad_picked_up_unless_it_is_pinned() -> void:
	_plug_in()
	var ink := Color.WHITE
	var follows: InputGlyph = auto_free(InputGlyph.of_event(_button(JOY_BUTTON_A), ink, 15))
	var pinned: InputGlyph = auto_free(InputGlyph.of_event(_button(JOY_BUTTON_A), ink, 15))
	add_child(follows)
	add_child(pinned)
	pinned.pin(SWITCH_PAD)
	assert_str(follows.caption).is_equal("A")
	assert_str(pinned.caption).is_equal("B")
	assert_int(follows.face).is_equal(JOY_BUTTON_A)
	DeviceInput.touched(PS5_PAD)
	await get_tree().process_frame
	assert_int(follows.family).is_equal(PadFamily.Family.PLAYSTATION)
	assert_str(follows.caption).is_equal("Cross")
	assert_int(pinned.family).is_equal(PadFamily.Family.NINTENDO)
	assert_str(pinned.caption).is_equal("B")
	# A round button however it is drawn, so a line does not jump as the pad changes.
	assert_vector(follows.custom_minimum_size).is_equal(pinned.custom_minimum_size)
	DeviceInput.recent.clear()


## A player's own hints are drawn for the pad they hold, whatever pad was touched last.
func test_a_players_hint_is_drawn_for_their_own_pad() -> void:
	_plug_in()
	DeviceInput.touched(PS5_PAD)
	var row: HBoxContainer = auto_free(ControlHint.hint_row(SWITCH_PAD))
	var faces: Array[String] = []
	for glyph: Node in row.find_children("*", "InputGlyph", true, false):
		if (glyph as InputGlyph).kind == InputGlyph.Kind.FACE:
			faces.append((glyph as InputGlyph).caption)
	assert_array(faces).contains_exactly(["B"])
	# A player who reads every device, holding a pad just now.
	Game.last_input_keyboard = false
	var anybody: HBoxContainer = auto_free(ControlHint.hint_row(DeviceInput.ANY))
	var shapes: Array[String] = []
	for glyph: Node in anybody.find_children("*", "InputGlyph", true, false):
		if (glyph as InputGlyph).kind == InputGlyph.Kind.FACE:
			shapes.append((glyph as InputGlyph).caption)
	assert_array(shapes).contains_exactly(["Cross"])
	DeviceInput.recent.clear()


## A kart's driver's pad, asked of the kart by name: a player's own, or any for anyone else.
func test_the_pad_of_a_karts_driver() -> void:
	var player := PlayerInput.new()
	player.device = SWITCH_PAD
	var kart := Node.new()
	assert_int(InputGlyph.device_of(null)).is_equal(DeviceInput.ANY)
	assert_int(InputGlyph.device_of(kart)).is_equal(DeviceInput.ANY)
	kart.free()
	var driven: Kart = auto_free(preload("res://scenes/kart/kart.tscn").instantiate())
	driven.input = player
	assert_int(InputGlyph.device_of(driven)).is_equal(SWITCH_PAD)


func test_a_debug_build_draws_every_pad_as_the_family_asked_for() -> void:
	PadFamily.pretend = PadFamily.Family.NINTENDO
	assert_int(PadFamily.shown()).is_equal(PadFamily.Family.NINTENDO)
	assert_int(PadFamily.of_device(3)).is_equal(PadFamily.Family.NINTENDO)
	assert_str(InputActions.short_binding_text(InputActions.NITRO, false)).is_equal("R")


## Valve's own: the Steam Deck's controls with its own names, and the Steam Controller lettered as
## an Xbox pad is.
func test_valves_pads() -> void:
	var family := PadFamily.Family
	var deck := _info(PadFamily.VALVE, PadFamily.STEAM_DECK_PAD)
	assert_int(PadFamily.of_pad(deck, "")).is_equal(family.STEAM_DECK)
	assert_int(PadFamily.of_pad(_info(PadFamily.VALVE, 0x1142), "")).is_equal(family.XBOX)
	var shoulder := InputActions.event_text(_button(JOY_BUTTON_LEFT_SHOULDER), family.STEAM_DECK)
	assert_str(shoulder).is_equal("L1")
	var trigger := InputActions.event_text(_trigger(JOY_AXIS_TRIGGER_RIGHT), family.STEAM_DECK)
	assert_str(trigger).is_equal("R2")
	assert_str(InputActions.event_text(_button(JOY_BUTTON_A), family.STEAM_DECK)).is_equal("A")
	assert_bool(PadFamily.lettered(family.STEAM_DECK)).is_false()
	# The Steam Controller of 2026, wired, over Bluetooth, through its puck or a Steam Machine's
	# receiver: named as the Deck's controls are.
	for product: int in PadFamily.STEAM_CONTROLLERS_2026:
		var pad := _info(PadFamily.VALVE, product, "Steam Controller")
		assert_int(PadFamily.of_pad(pad, "")).is_equal(family.STEAM_CONTROLLER)
	var bumper := InputActions.event_text(
		_button(JOY_BUTTON_RIGHT_SHOULDER), family.STEAM_CONTROLLER
	)
	assert_str(bumper).is_equal("R1")
	assert_str(InputActions.event_text(_button(JOY_BUTTON_Y), family.STEAM_CONTROLLER)).is_equal(
		"Y"
	)


## In a Steam build, a pad Steam Input stands in for is the pad Steam says is behind it, asked by
## the index the engine gives it; one Steam knows nothing of is told apart as before.
func test_steam_says_which_pad_is_behind_its_own() -> void:
	var fake := FakeSteam.new()
	var store := SteamStore.new(fake)
	fake.pad_handles[0] = 4100
	fake.pad_types[4100] = 13
	store.watch_pads()
	assert_bool(fake.calls.has("inputInit")).is_true()
	assert_int(store.pad_family(0)).is_equal(PadFamily.Family.PLAYSTATION)
	# An index that is the pad's handle itself.
	fake.pad_types[7] = 14
	assert_int(store.pad_family(7)).is_equal(PadFamily.Family.STEAM_DECK)
	# The Steam Controller of 2026, which reaches the engine through Steam Input alone.
	fake.pad_types[8] = 17
	assert_int(store.pad_family(8)).is_equal(PadFamily.Family.STEAM_CONTROLLER)
	assert_int(store.pad_family(9)).is_equal(-1)
	PadFamily.behind_steam = store.pad_family
	var virtual := _info(PadFamily.VALVE, 0x11FF, "Steam Virtual Gamepad")
	virtual["steam_input_index"] = "0"
	assert_int(PadFamily.of_pad(virtual, "")).is_equal(PadFamily.Family.PLAYSTATION)
	virtual["steam_input_index"] = "9"
	assert_int(PadFamily.of_pad(virtual, "")).is_equal(PadFamily.Family.GENERIC)
	PadFamily.behind_steam = Callable()
