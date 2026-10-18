extends GdUnitTestSuite
## Steam's keyboard on the screen, GAME.md 10.8: a box starting to be typed into, in a Steam build
## on Steam's own hardware or in Big Picture, asks Steam for its floating keyboard beside the box's
## place in the window, of the kind the box wants, once the box stays put and is drawn whole; a
## pad's A on a box starts it and brings the keyboard, back too after Steam's close put it away; the
## keyboard is handed from one box straight to the next and goes with the box; Enter on it submits
## the box. Nothing is asked without Steam, off Steam's hardware outside Big Picture, or with a
## keyboard in hand. Steam here is always [FakeSteam].

const SHOW := "showFloatingGamepadTextInput"
const HIDE := "dismissFloatingGamepadTextInput"
## GodotSteam's `SteamHardwareType` for a Steam Deck, a Steam Machine and a Steam Frame.
const DECK := 1
const MACHINE := 2
const FRAME := 3

var _fake: FakeSteam
var _keyboard: SteamKeyboard
var _holder: Control
var _was_keyboard: bool
var _was_pointer: bool
var _was_recent: Array[int]


func before_test() -> void:
	_was_keyboard = Game.last_input_keyboard
	_was_pointer = Game.last_input_pointer
	_was_recent = DeviceInput.recent.duplicate()
	_fake = FakeSteam.new()
	_fake.hardware = DECK
	Store.steam = SteamStore.new(_fake)
	Store.steam.start(3141590)
	_holder = Control.new()
	_holder.size = Vector2(1920.0, 1080.0)
	add_child(_holder)
	_keyboard = SteamKeyboard.new()
	add_child(_keyboard)


func after_test() -> void:
	for each: Node in [_keyboard, _holder]:
		if is_instance_valid(each):
			remove_child(each)
			each.free()
	Store.steam = null
	Game.last_input_keyboard = _was_keyboard
	Game.last_input_pointer = _was_pointer
	DeviceInput.recent = _was_recent


## A box in the holder at [param at].
func _box(at := Vector2(100.0, 100.0)) -> LineEdit:
	var box := LineEdit.new()
	box.position = at
	box.size = Vector2(300.0, 48.0)
	_holder.add_child(box)
	return box


## A button in the holder, for the cursor to be somewhere other than a box.
func _button() -> Button:
	var button := Button.new()
	button.position = Vector2(100.0, 600.0)
	_holder.add_child(button)
	return button


## Every time Steam was asked for its keyboard.
func _asked() -> Array:
	return _fake.calls.filter(func(call: String) -> bool: return call.begins_with(SHOW))


## Frames enough for a box that stays put to be told to Steam, and for whatever was put off to the
## end of a frame.
func _settle() -> void:
	for _frame: int in SteamKeyboard.STILL + 2:
		await await_idle_frame()


static func _pad(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event


static func _key(code: Key, typed := "") -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.unicode = typed.unicode_at(0) if not typed.is_empty() else 0
	event.pressed = true
	return event


func test_a_box_typed_into_asks_for_steams_keyboard_beside_it() -> void:
	# A box on a layer of its own, moved and scaled, as a dialog's are.
	var layer := CanvasLayer.new()
	layer.scale = Vector2(1.5, 1.5)
	layer.offset = Vector2(100.0, 50.0)
	_holder.add_child(layer)
	var box := LineEdit.new()
	box.position = Vector2(200.0, 300.0)
	box.size = Vector2(240.0, 48.0)
	layer.add_child(box)
	box.grab_focus()
	assert_bool(box.is_editing()).is_true()
	await _settle()
	# Where it is drawn, in the window's pixels, the stretch to the window's size and all.
	var drawn := get_tree().root.get_final_transform() * Rect2(400.0, 500.0, 360.0, 72.0)
	var rect := Rect2i(Vector2i(drawn.position.round()), Vector2i(drawn.size.round()))
	assert_that(SteamKeyboard.window_rect(box)).is_equal(rect)
	var where := [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
	assert_array(_asked()).is_equal(
		["%s %d %d %d %d %d" % ([SHOW, SteamKeyboard.SINGLE_LINE] + where)]
	)
	assert_bool(_keyboard.shown).is_true()
	assert_object(_keyboard.field).is_same(box)


func test_steam_is_told_where_the_box_comes_to_rest() -> void:
	# A box on a pane being dealt in: faded, then rising into place, by whole pixels of the window,
	# which is a small one where nothing is drawn.
	var box := _box(Vector2(100.0, 700.0))
	_holder.modulate.a = 0.0
	box.grab_focus()
	await _settle()
	assert_array(_asked()).is_empty()
	_holder.modulate.a = 1.0
	var pixel := 1.0 / get_tree().root.get_final_transform().get_scale().y
	for _frame: int in 6:
		box.position.y -= pixel * 2.0
		await await_idle_frame()
	assert_array(_asked()).is_empty()
	await _settle()
	var rect := SteamKeyboard.window_rect(box)
	var where := [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
	assert_array(_asked()).is_equal(
		["%s %d %d %d %d %d" % ([SHOW, SteamKeyboard.SINGLE_LINE] + where)]
	)
	# One that never settles is told where it is all the same, in a while.
	var other := _box(Vector2(100.0, 500.0))
	other.modulate.a = 0.5
	other.grab_focus()
	await _settle()
	assert_int(_asked().size()).is_equal(1)
	await await_millis(int(SteamKeyboard.LONGEST * 1000.0) + 200)
	assert_int(_asked().size()).is_equal(2)
	assert_object(_keyboard.field).is_same(other)


func test_a_box_gets_the_kind_of_keyboard_a_phone_would_give_it() -> void:
	var port: LineEdit = auto_free(MenuTheme.port_field("", ""))
	assert_int(SteamKeyboard.kind_of(port)).is_equal(SteamKeyboard.NUMERIC)
	var mail: LineEdit = auto_free(LineEdit.new())
	mail.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS
	assert_int(SteamKeyboard.kind_of(mail)).is_equal(SteamKeyboard.EMAIL)
	var host: LineEdit = auto_free(MenuTheme.host_field("", 64))
	assert_int(SteamKeyboard.kind_of(host)).is_equal(SteamKeyboard.SINGLE_LINE)
	var password: LineEdit = auto_free(MenuTheme.field("", "Password", 32))
	password.secret = true
	assert_int(SteamKeyboard.kind_of(password)).is_equal(SteamKeyboard.SINGLE_LINE)
	# Asked for so: the port's box gets Steam's keypad.
	_holder.add_child(port)
	port.grab_focus()
	await _settle()
	assert_str(_asked()[0]).starts_with("%s %d " % [SHOW, SteamKeyboard.NUMERIC])


func test_every_box_is_heard_once_however_often_it_comes_and_goes() -> void:
	# A box in the tree before the keyboard was made is heard too.
	remove_child(_keyboard)
	_keyboard.free()
	var box := _box()
	_keyboard = SteamKeyboard.new()
	add_child(_keyboard)
	# Out of the tree and back, it asks once each time it is typed into, not twice.
	_holder.remove_child(box)
	_holder.add_child(box)
	box.grab_focus()
	await _settle()
	assert_int(_asked().size()).is_equal(1)


func test_a_pads_a_on_a_box_starts_it_and_brings_the_keyboard_back() -> void:
	var box := _box()
	# The cursor walked onto the box with a pad, which does not start it being typed into.
	_fake.hardware = SteamStore.NOT_STEAM_HARDWARE
	box.grab_focus()
	box.unedit()
	_fake.hardware = DECK
	await _settle()
	assert_array(_asked()).is_empty()
	get_viewport().push_input(_pad(JOY_BUTTON_A))
	assert_bool(get_viewport().is_input_handled()).is_true()
	assert_bool(box.is_editing()).is_true()
	await _settle()
	assert_int(_asked().size()).is_equal(1)
	# With the keyboard up for it, A asks nothing more.
	get_viewport().push_input(_pad(JOY_BUTTON_A))
	await _settle()
	assert_int(_asked().size()).is_equal(1)
	# Put away by Steam's close, the box keeps the cursor as the player left it, and A brings the
	# keyboard back.
	_fake.close_keyboard()
	assert_bool(_keyboard.shown).is_false()
	await _settle()
	assert_bool(box.has_focus()).is_true()
	assert_bool(box.is_editing()).is_true()
	assert_array(_fake.calls).not_contains([HIDE])
	get_viewport().push_input(_pad(JOY_BUTTON_A))
	await _settle()
	assert_int(_asked().size()).is_equal(2)
	assert_bool(_keyboard.shown).is_true()


func test_enter_on_steams_keyboard_submits_the_box() -> void:
	var box := _box()
	var submitted: Array[String] = []
	box.text_submitted.connect(func(typed: String) -> void: submitted.append(typed))
	box.grab_focus()
	await _settle()
	assert_bool(_keyboard.shown).is_true()
	# Steam's keyboard types as keys do.
	get_viewport().push_input(_key(KEY_B, "b"))
	get_viewport().push_input(_key(KEY_O, "o"))
	get_viewport().push_input(_key(KEY_ENTER))
	assert_array(submitted).is_equal(["bo"])
	assert_bool(box.has_focus()).is_true()
	# Its keys say nothing of a keyboard in hand.
	assert_bool(_keyboard.keys_in_hand).is_false()
	# Enter puts it away: Steam's keyboard for a line goes by itself, and the box is done with.
	_fake.close_keyboard()
	await _settle()
	assert_object(_keyboard.field).is_null()
	assert_array(_fake.calls).not_contains([HIDE])


func test_the_keyboard_goes_with_the_box() -> void:
	var first := _box(Vector2(100.0, 100.0))
	var second := _box(Vector2(100.0, 200.0))
	var button := _button()
	first.grab_focus()
	await _settle()
	# Straight from one box to the next, the keyboard is handed over, never put away in between.
	second.grab_focus()
	await _settle()
	assert_int(_asked().size()).is_equal(2)
	assert_array(_fake.calls).not_contains([HIDE])
	assert_object(_keyboard.field).is_same(second)
	# The cursor on something else, it is put away.
	button.grab_focus()
	await _settle()
	assert_int(_fake.calls.count(HIDE)).is_equal(1)
	assert_bool(_keyboard.shown).is_false()
	assert_object(_keyboard.field).is_null()
	# And so it is with the box gone, whether it had the keyboard yet or not.
	second.grab_focus()
	await _settle()
	second.queue_free()
	await _settle()
	assert_int(_fake.calls.count(HIDE)).is_equal(2)
	assert_object(_keyboard.field).is_null()
	first.grab_focus()
	first.queue_free()
	await _settle()
	assert_int(_asked().size()).is_equal(3)
	assert_int(_fake.calls.count(HIDE)).is_equal(2)
	assert_bool(_keyboard.shown).is_false()


func test_only_on_steams_hardware_or_in_big_picture() -> void:
	var box := _box()
	var button := _button()
	_fake.hardware = SteamStore.NOT_STEAM_HARDWARE
	box.grab_focus()
	await _settle()
	assert_array(_asked()).is_empty()
	# A pad's A is left to do what it did.
	box.unedit()
	get_viewport().push_input(_pad(JOY_BUTTON_A))
	assert_bool(box.is_editing()).is_false()
	await _settle()
	assert_array(_asked()).is_empty()
	# With Steam in Big Picture it comes, and on every one of Steam's own machines.
	_fake.big_picture = true
	button.grab_focus()
	box.grab_focus()
	await _settle()
	assert_int(_asked().size()).is_equal(1)
	_fake.big_picture = false
	for hardware: int in [DECK, MACHINE, FRAME]:
		_fake.hardware = hardware
		button.grab_focus()
		box.grab_focus()
		await _settle()
	assert_int(_asked().size()).is_equal(4)
	# Never for a box that cannot be typed into.
	box.editable = false
	assert_bool(_keyboard.wanted(box)).is_false()


func test_a_keyboard_in_hand_keeps_steams_keyboard_down() -> void:
	var box := _box()
	var button := _button()
	button.grab_focus()
	get_viewport().push_input(_key(KEY_SHIFT))
	assert_bool(_keyboard.keys_in_hand).is_true()
	box.grab_focus()
	await _settle()
	assert_array(_asked()).is_empty()
	# A pad picked up, and it comes again; a key pressed while it waits, and it does not.
	button.grab_focus()
	get_viewport().push_input(_pad(JOY_BUTTON_X))
	assert_bool(_keyboard.keys_in_hand).is_false()
	box.grab_focus()
	get_viewport().push_input(_key(KEY_SHIFT))
	await _settle()
	assert_array(_asked()).is_empty()
	button.grab_focus()
	get_viewport().push_input(_pad(JOY_BUTTON_X))
	box.grab_focus()
	await _settle()
	assert_int(_asked().size()).is_equal(1)
	# What says what: a key, unless Steam's keyboard is up to have typed it; a pad's button, a real
	# push of its stick, a finger on the screen; and the mouse nothing.
	assert_bool(SteamKeyboard.in_hand_after(_key(KEY_A), false, false)).is_true()
	assert_bool(SteamKeyboard.in_hand_after(_key(KEY_A), false, true)).is_false()
	assert_bool(SteamKeyboard.in_hand_after(_pad(JOY_BUTTON_A), true, false)).is_false()
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	assert_bool(SteamKeyboard.in_hand_after(touch, true, false)).is_false()
	var stick := InputEventJoypadMotion.new()
	stick.axis_value = 0.2
	assert_bool(SteamKeyboard.in_hand_after(stick, true, false)).is_true()
	stick.axis_value = -0.9
	assert_bool(SteamKeyboard.in_hand_after(stick, true, false)).is_false()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	assert_bool(SteamKeyboard.in_hand_after(click, true, false)).is_true()
	assert_bool(SteamKeyboard.in_hand_after(click, false, false)).is_false()


func test_without_steam_nothing_is_asked() -> void:
	Store.steam = null
	var box := _box()
	box.grab_focus()
	box.unedit()
	get_viewport().push_input(_pad(JOY_BUTTON_A))
	assert_bool(box.is_editing()).is_false()
	await _settle()
	assert_array(_asked()).is_empty()
	# And a game without Steam never makes the keyboard at all.
	for child: Node in Game.get_children():
		var script := child.get_script() as Script
		var path := script.resource_path if script != null else ""
		assert_str(path).is_not_equal(Game.STEAM_KEYBOARD)
