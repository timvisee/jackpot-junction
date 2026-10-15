extends GdUnitTestSuite
## Somebody sitting down at the demo for a booth, GAME.md 9.8: two presses of a key the game plays
## with or of a pad take the first of the demo's seats nobody holds, there and then, said so where
## nobody can miss it, and past them a bot's kart; the mouse never does. A minute of nothing from
## that device and the bot drives on. Escape is left to the pause menu, whose demo has nothing of a
## lobby's on it, and a switch to drive the other way for a seat somebody holds.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES := preload("res://data/match/default.tres")
const PAD := 0
const OTHER_PAD := 1


## A host whose runs are counted rather than dealt, which would leave the test's scene.
class CountingHost:
	extends DemoHost
	var dealt := 0

	func deal() -> void:
		dealt += 1


var _runner: GdUnitSceneRunner
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = ""
	Demo.on = true
	Demo.set_up(Game.settings, false)
	DemoSeats.clear()
	ControlHint.shown_to.clear()


func after_test() -> void:
	Demo.on = false
	DemoSeats.clear()
	DemoRun.current = null
	ControlHint.shown_to.clear()
	get_tree().paused = false
	Game.settings = _settings_were


## A room with a map in it, two of the demo's seats and two bots, as the match scene has it.
func _room(with_hud := false) -> Node3D:
	var room: Node3D = auto_free(Node3D.new())
	var match_node: Match = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	match_node.rules = DEFAULT_RULES.duplicate()
	match_node.rules.countdown = 0.1
	match_node.with_hud = with_hud
	room.add_child(match_node)
	_runner = scene_runner(room)
	var inputs: Array[KartInput] = [
		DemoInput.new(0), DemoInput.new(1), BotInput.new(), BotInput.new()
	]
	match_node.start(inputs, 31)
	return room


func _button(device: int, pressed := true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = JOY_BUTTON_A
	event.pressed = pressed
	return event


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	return event


## A stick of [param device] at [param value].
func _stick(device: int, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = device
	event.axis = JOY_AXIS_LEFT_Y
	event.axis_value = value
	return event


## [param event] heard twice in [param room], as somebody sitting down presses: whether each was
## taken.
func _twice(host: DemoHost, event: InputEvent, room: Node) -> Array[bool]:
	var taken: Array[bool] = [host.heard(event, room), host.heard(event, room)]
	return taken


## Two presses on a pad nobody sits at take the first seat there and then: the kart as it was, its
## bot letting go, the hint over it saying how to drive, and the call saying so. The first press is
## taken too, and goes no further.
func test_two_presses_take_the_first_free_seat() -> void:
	var room := _room(true)
	var match_node: Match = room.get_node("Match")
	await _runner.simulate_frames(20, 17)
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	var kart := match_node.kart_of(0)
	var banked := 120
	match_node.slots[0].banked = banked
	var seat := match_node.slots[0].input as DemoInput
	assert_bool(host.heard(_button(PAD), room)).is_true()
	assert_bool(seat.held()).is_false()
	assert_bool(host.heard(_button(PAD), room)).is_true()
	assert_bool(seat.held()).is_true()
	assert_int(seat.device).is_equal(PAD)
	assert_bool(DemoInput.bot_drives(seat)).is_false()
	assert_object(match_node.kart_of(0)).is_same(kart)
	assert_int(match_node.slots[0].banked).is_equal(banked)
	assert_bool(match_node.hud._blocks.has(0)).is_true()
	assert_object(kart.get_node_or_null("ControlHint")).is_not_null()
	var call: CallBanner = match_node.hud.get_node("Call")
	assert_bool(call.visible).is_true()
	assert_str(call.said()).contains(DemoSeats.TAKEN)
	assert_str(call.said()).contains(match_node.slots[0].display_name())
	# The same pad again is somebody playing, not somebody else sitting down.
	assert_bool(host.heard(_button(PAD), room)).is_false()
	assert_bool((match_node.slots[1].input as DemoInput).held()).is_false()


## The keyboard sits down at the next seat, and once every seat of the demo's is held another
## device takes a bot's kart over as joining a map does.
func test_past_the_demos_seats_a_bots_kart_is_taken() -> void:
	var room := _room()
	var match_node: Match = room.get_node("Match")
	await _runner.simulate_frames(10, 17)
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	_twice(host, _button(PAD), room)
	assert_array(_twice(host, _key(KEY_A), room)).contains_exactly([true, true])
	assert_int((match_node.slots[1].input as DemoInput).device).is_equal(DeviceInput.KEYBOARD)
	assert_bool(DemoSeats.any_free()).is_false()
	_twice(host, _button(OTHER_PAD), room)
	assert_array(DemoSeats.joined).contains_exactly([OTHER_PAD])
	var taken := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.plays_on(OTHER_PAD):
			taken += 1
			assert_bool(slot.input is DemoInput).is_false()
	assert_int(taken).is_equal(1)
	assert_int(match_node.slots.size()).is_equal(4)


## A minute of nothing from its device and the seat is its bot's again, said so, and drives the
## simple way again for whoever sits down next; a bot's kart taken over goes back to a bot the same
## way. A press or a push heard from the device in the meantime starts the minute over; the mouse
## does not.
func test_a_quiet_seat_goes_back_to_its_bot() -> void:
	var room := _room(true)
	var match_node: Match = room.get_node("Match")
	await _runner.simulate_frames(10, 17)
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	_twice(host, _button(PAD), room)
	_twice(host, _key(KEY_A), room)
	_twice(host, _button(OTHER_PAD), room)
	Game.settings.set_drive_mode(1, Settings.DRIVE_ADVANCED)
	DemoSeats.step(match_node, DemoSeats.IDLE - 1.0)
	host.heard(_stick(PAD, 0.0), room)
	assert_bool(host.heard(_stick(PAD, 0.8), room)).is_false()
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(5.0, 0.0)
	host.heard(mouse, room)
	DemoSeats.step(match_node, 2.0)
	assert_bool((match_node.slots[0].input as DemoInput).held()).is_true()
	assert_bool((match_node.slots[1].input as DemoInput).held()).is_false()
	assert_str(Game.settings.drive_mode(1)).is_equal(Settings.DRIVE_SIMPLE)
	var call: CallBanner = match_node.hud.get_node("Call")
	assert_str(call.said()).contains(DemoSeats.GIVEN_BACK)
	assert_array(DemoSeats.joined).is_empty()
	for slot: PlayerSlot in match_node.slots:
		assert_bool(slot.plays_on(OTHER_PAD)).is_false()
	var bots := match_node.slots.filter(func(s: PlayerSlot) -> bool: return s.input is BotInput)
	assert_int(bots.size()).is_equal(2)
	DemoSeats.step(match_node, DemoSeats.IDLE)
	assert_bool(DemoInput.bot_drives(match_node.slots[0].input)).is_true()
	assert_bool(DemoSeats.held.is_empty()).is_true()


## What sits nobody down: the mouse moved or clicked, a key the game has no use for, Escape, a key
## let go, a stick's drift, an axis that only ever reports itself held, a single press, and anything
## while the pause menu is open.
func test_what_does_not_sit_anybody_down() -> void:
	var room := _room()
	await _runner.simulate_frames(5, 17)
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	assert_array(_twice(host, click, room)).contains_exactly([false, false])
	var moved := InputEventMouseMotion.new()
	moved.relative = Vector2(20.0, 0.0)
	assert_bool(host.heard(moved, room)).is_false()
	assert_array(_twice(host, _key(KEY_ALT), room)).contains_exactly([false, false])
	assert_array(_twice(host, _key(KEY_ESCAPE), room)).contains_exactly([false, false])
	var let_go := _key(KEY_A)
	let_go.pressed = false
	assert_array(_twice(host, let_go, room)).contains_exactly([false, false])
	assert_bool(host.heard(_stick(PAD, 0.1), room)).is_false()
	var held := InputEventJoypadMotion.new()
	held.device = OTHER_PAD
	held.axis = JOY_AXIS_TRIGGER_LEFT
	held.axis_value = -1.0
	assert_array(_twice(host, held, room)).contains_exactly([false, false])
	assert_bool(host.heard(_button(PAD), room)).is_true()
	assert_bool(DemoSeats.held.is_empty()).is_true()
	get_tree().paused = true
	assert_array(_twice(host, _button(OTHER_PAD), room)).contains_exactly([false, false])
	get_tree().paused = false
	assert_bool(DemoSeats.held.is_empty()).is_true()


## A stick pushed out from rest twice sits somebody down, as two presses do.
func test_a_stick_pushed_from_rest_sits_somebody_down() -> void:
	var room := _room()
	await _runner.simulate_frames(5, 17)
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	for push: int in 2:
		assert_bool(host.heard(_stick(PAD, 0.05), room)).is_false()
		assert_bool(host.heard(_stick(PAD, -0.9), room)).is_true()
	assert_int(DemoSeats.held[0]).is_equal(PAD)


## Two presses on the title deal the next run at once, with whoever pressed in its first seat.
func test_presses_on_the_title_deal_the_run_with_them_in_it() -> void:
	var title: Control = auto_free(Control.new())
	title.scene_file_path = Game.TITLE_SCENE
	var host: CountingHost = auto_free(CountingHost.new())
	assert_array(_twice(host, _button(PAD), title)).contains_exactly([true, true])
	assert_int(host.dealt).is_equal(1)
	assert_int(DemoSeats.held[0]).is_equal(PAD)
	var config := DemoRun.deal(RandomNumberGenerator.new())
	var inputs := DemoRun.inputs(config)
	assert_bool((inputs[0] as DemoInput).held()).is_true()
	assert_int((inputs[0] as DemoInput).device).is_equal(PAD)
	assert_bool((inputs[1] as DemoInput).held()).is_false()


## Whoever took a bot's kart over at the map before takes one over at the next.
func test_a_bots_kart_taken_is_taken_again_at_the_next_map() -> void:
	DemoSeats.held = {0: PAD, 1: DeviceInput.KEYBOARD}
	DemoSeats.joined = [OTHER_PAD]
	DemoSeats.quiet = {PAD: 0.0, DeviceInput.KEYBOARD: 0.0, OTHER_PAD: 0.0}
	var room := _room()
	var match_node: Match = room.get_node("Match")
	DemoSeats.seat_again(match_node)
	var seated := match_node.slots.filter(func(s: PlayerSlot) -> bool: return s.plays_on(OTHER_PAD))
	assert_int(seated.size()).is_equal(1)
	DemoSeats.seat_again(match_node)
	seated = match_node.slots.filter(func(s: PlayerSlot) -> bool: return s.plays_on(OTHER_PAD))
	assert_int(seated.size()).is_equal(1)


## A seat its bot drives knocks no pad, whatever is plugged in, and nor does a player reading every
## device while they drive on the keyboard.
func test_no_pad_is_knocked_that_nobody_drives_with() -> void:
	var room := _room()
	var match_node: Match = room.get_node("Match")
	assert_int(match_node.slots[0].knocked_pad()).is_equal(-1)
	var alone := PlayerInput.new(DeviceInput.ANY, 0)
	alone.last_device = DeviceInput.KEYBOARD
	match_node.slots[1].input = alone
	assert_int(match_node.slots[1].knocked_pad()).is_equal(-1)


## In the pause menu a seat somebody holds has its switch, to drive the other way, and nothing to
## leave by; a seat its bot drives has none.
func test_a_held_seat_has_its_switch_in_the_menu() -> void:
	var room := _room(true)
	var match_node: Match = room.get_node("Match")
	await _runner.simulate_frames(5, 17)
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	_twice(host, _button(PAD), room)
	# The corner made again for them goes by its own name, which the switch finds it by.
	var corner: Control = match_node.hud._blocks[0]["box"]
	assert_object(match_node.hud.get_node_or_null("Block0")).is_same(corner)
	var here := DriveSwitches._players_here(match_node)
	assert_int(here.size()).is_equal(1)
	assert_object(here[0]).is_same(match_node.slots[0])
	var switches := DriveSwitches.new()
	room.add_child(switches)
	switches.put_up()
	assert_object(switches.button(0)).is_not_null()
	assert_object(switches.button(1)).is_null()
	for each: Dictionary in switches._up:
		assert_bool(each.has("leave")).is_false()
	switches.button(0).pressed.emit()
	assert_str(Game.settings.drive_mode(0)).is_equal(Settings.DRIVE_ADVANCED)


## The demo's pause menu: Resume, Settings, Play the full game and Quit, with no Clubhouse and no
## way to a lobby; Play the full game in foil, a glint running across it.
func test_the_demos_pause_menu() -> void:
	var room := _room(true)
	var menu := PauseMenu.add_to(room)
	var asked := [0]
	menu.for_the_demo(func() -> void: asked[0] += 1)
	var shown: Array[String] = []
	var full: Button = null
	for button: Button in menu._buttons():
		if button.visible:
			shown.append(button.text)
		if button.text == "Play the full game":
			full = button
	assert_array(shown).contains_exactly(["Resume", "Settings", "Play the full game", "Quit"])
	assert_str(String(full.theme_type_variation)).is_equal(String(HouseTheme.PRIMARY))
	assert_object(full.get_node_or_null("Glint")).is_not_null()
	full.pressed.emit()
	assert_int(asked[0]).is_equal(1)
