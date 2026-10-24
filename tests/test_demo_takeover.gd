extends GdUnitTestSuite
## Somebody sitting down at the demo for a booth, GAME.md 9.8: no press does, but Escape or a pad's
## Menu opens the pause menu, whose Join current match takes the first of the demo's seats nobody
## holds for the device that opened it, there and then, said so where nobody can miss it, and past
## them a bot's kart, asking how they want to drive in the menu's place. A minute of nothing from
## that device and the bot drives on. The demo's menu has nothing of a lobby's on it, and a switch
## to drive the other way for a seat somebody holds.

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


func _escape() -> InputEventKey:
	return _key(KEY_ESCAPE)


func _start_button(device: int) -> InputEventJoypadButton:
	var event := _button(device)
	event.button_index = JOY_BUTTON_START
	return event


## The demo's pause menu over [param room], as the match scene puts it up, Join current match
## working for [param host].
func _menu(room: Node3D, host: DemoHost) -> PauseMenu:
	var match_node: Match = room.get_node("Match")
	var menu := PauseMenu.add_to(room)
	menu.for_the_demo(
		func() -> void: pass, host.join.bind(menu, match_node), host.can_join.bind(match_node)
	)
	return menu


func _join_button(menu: PauseMenu) -> Button:
	return menu.find_child("JoinMatch", true, false) as Button


## [param event] heard twice in [param room]: whether each was taken.
func _twice(host: DemoHost, event: InputEvent, room: Node) -> Array[bool]:
	var taken: Array[bool] = [host.heard(event, room), host.heard(event, room)]
	return taken


## Escape or a pad's Menu opens the menu as in any room, the device that did so kept for its Join
## current match: Join seats that device at the first free seat there and then, the kart as it was,
## its bot letting go, the hint over it and the call saying so, and asks how they want to drive in
## the menu's place, the room still stopped; answered, the menu goes and the room runs on.
func test_join_from_the_menu_takes_the_first_free_seat() -> void:
	var room := _room(true)
	var match_node: Match = room.get_node("Match")
	await _runner.simulate_frames(20, 17)
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	var menu := _menu(room, host)
	var kart := match_node.kart_of(0)
	match_node.slots[0].banked = 120
	assert_bool(host.can_join(match_node)).is_false()
	assert_bool(host.heard(_start_button(PAD), room)).is_false()
	assert_int(host.menu_device).is_equal(PAD)
	assert_bool(host.can_join(match_node)).is_true()
	menu.set_paused(true)
	assert_bool(_join_button(menu).visible).is_true()
	_join_button(menu).pressed.emit()
	var seat := match_node.slots[0].input as DemoInput
	assert_bool(seat.held()).is_true()
	assert_int(seat.device).is_equal(PAD)
	assert_object(match_node.kart_of(0)).is_same(kart)
	assert_int(match_node.slots[0].banked).is_equal(120)
	assert_object(kart.get_node_or_null("ControlHint")).is_not_null()
	var call: CallBanner = match_node.hud.get_node("Call")
	assert_str(call.said()).contains(DemoSeats.TAKEN)
	# Asked how to drive in the menu's place, the room still stopped.
	var choice := menu.holder().get_node_or_null("DriveChoice") as DriveChoice
	assert_object(choice).is_not_null()
	assert_int(choice.seat).is_equal(0)
	assert_bool(menu._main.visible).is_false()
	assert_bool(get_tree().paused).is_true()
	choice.choose(Settings.DRIVE_ADVANCED)
	await _runner.simulate_frames(2, 17)
	assert_str(Game.settings.drive_mode(0)).is_equal(Settings.DRIVE_ADVANCED)
	assert_bool(menu.is_open()).is_false()
	# Opened again by the same pad, there is no Join for somebody already sitting down.
	host.heard(_start_button(PAD), room)
	menu.set_paused(true)
	assert_bool(_join_button(menu).visible).is_false()
	menu.set_paused(false)


## The question put away unanswered still leaves them sitting, driving the way a seat comes, and
## the menu goes with it; the menu put away first takes the question along.
func test_the_question_put_away_puts_the_menu_away() -> void:
	var room := _room(true)
	var match_node: Match = room.get_node("Match")
	await _runner.simulate_frames(10, 17)
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	var menu := _menu(room, host)
	host.heard(_escape(), room)
	assert_int(host.menu_device).is_equal(DeviceInput.KEYBOARD)
	menu.set_paused(true)
	_join_button(menu).pressed.emit()
	assert_int((match_node.slots[0].input as DemoInput).device).is_equal(DeviceInput.KEYBOARD)
	var choice := menu.holder().get_node("DriveChoice") as DriveChoice
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	choice._unhandled_input(back)
	await _runner.simulate_frames(2, 17)
	assert_bool(menu.is_open()).is_false()
	assert_bool(menu._main.visible).is_true()
	host.menu_device = PAD
	menu.set_paused(true)
	_join_button(menu).pressed.emit()
	assert_int((match_node.slots[1].input as DemoInput).device).is_equal(PAD)
	menu.set_paused(false)
	await _runner.simulate_frames(2, 17)
	assert_object(menu.holder().get_node_or_null("DriveChoice")).is_null()


## Once every seat of the demo's is held, Join takes a bot's kart over as joining a map does; with
## none left there is no Join.
func test_past_the_demos_seats_a_bots_kart_is_taken() -> void:
	var room := _room()
	var match_node: Match = room.get_node("Match")
	await _runner.simulate_frames(10, 17)
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	DemoSeats.sit(PAD, match_node)
	DemoSeats.sit(DeviceInput.KEYBOARD, match_node)
	assert_int((match_node.slots[1].input as DemoInput).device).is_equal(DeviceInput.KEYBOARD)
	assert_bool(DemoSeats.any_free()).is_false()
	host.menu_device = OTHER_PAD
	assert_bool(host.can_join(match_node)).is_true()
	assert_bool(DemoSeats.sit(OTHER_PAD, match_node)).is_true()
	assert_array(DemoSeats.joined).contains_exactly([OTHER_PAD])
	var taken := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.plays_on(OTHER_PAD):
			taken += 1
			assert_bool(slot.input is DemoInput).is_false()
	assert_int(taken).is_equal(1)
	assert_int(match_node.slots.size()).is_equal(4)
	assert_bool(host.can_join(match_node)).is_false()


## A minute of nothing from its device and the seat is its bot's again, said so, and drives the
## simple way again for whoever sits down next; a bot's kart taken over goes back to a bot the same
## way. A press or a push heard from the device in the meantime starts the minute over; the mouse
## does not.
func test_a_quiet_seat_goes_back_to_its_bot() -> void:
	var room := _room(true)
	var match_node: Match = room.get_node("Match")
	await _runner.simulate_frames(10, 17)
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	DemoSeats.sit(PAD, match_node)
	DemoSeats.sit(DeviceInput.KEYBOARD, match_node)
	DemoSeats.sit(OTHER_PAD, match_node)
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


## No press sits anybody down any more: not two of a playing key or a pad's button, nor a stick
## pushed from rest, nor the mouse, nor the pause key itself, which is the menu's; and the menu's
## device is not taken from a press while the menu is up.
func test_no_press_sits_anybody_down() -> void:
	var room := _room()
	await _runner.simulate_frames(5, 17)
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	for event: InputEvent in [click, _key(KEY_A), _button(PAD), _escape(), _start_button(PAD)]:
		assert_array(_twice(host, event, room)).contains_exactly([false, false])
	for push: int in 2:
		host.heard(_stick(OTHER_PAD, 0.05), room)
		assert_bool(host.heard(_stick(OTHER_PAD, -0.9), room)).is_false()
	assert_bool(DemoSeats.held.is_empty()).is_true()
	get_tree().paused = true
	host.heard(_start_button(OTHER_PAD), room)
	assert_int(host.menu_device).is_equal(PAD)
	get_tree().paused = false


## The line says Escape while the keys were last touched, a pad's Menu once a pad is; with nothing
## touched yet, a pad if one is plugged in.
func test_the_line_shows_the_key_or_the_button_in_hand() -> void:
	var room := _room()
	await _runner.simulate_frames(5, 17)
	var host: DemoHost = auto_free(load(Game.DEMO_HOST).new())
	assert_bool(host.shows_keyboard()).is_equal(Input.get_connected_joypads().is_empty())
	host.heard(_button(PAD), room)
	assert_bool(host.shows_keyboard()).is_false()
	host.heard(_key(KEY_A), room)
	assert_bool(host.shows_keyboard()).is_true()


## The pause key on the title deals the next run at once, and the menu of its map opens once the
## map is up, for whoever pressed to join from.
func test_the_pause_key_on_the_title_deals_the_run_and_opens_its_menu() -> void:
	var title: Control = auto_free(Control.new())
	title.scene_file_path = Game.TITLE_SCENE
	var host: CountingHost = auto_free(CountingHost.new())
	assert_bool(host.heard(_button(PAD), title)).is_false()
	assert_int(host.dealt).is_equal(0)
	assert_bool(host.heard(_start_button(PAD), title)).is_true()
	assert_int(host.dealt).is_equal(1)
	assert_int(host.menu_device).is_equal(PAD)
	assert_bool(DemoSeats.held.is_empty()).is_true()
	var room := _room(true)
	var match_node: Match = room.get_node("Match")
	var menu := _menu(room, host)
	await _runner.simulate_frames(20, 17)
	host._open_the_menu_wanted(match_node)
	assert_bool(menu.is_open()).is_true()
	assert_bool(_join_button(menu).visible).is_true()
	menu.set_paused(false)


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


## In the pause menu a seat somebody holds has its switch, to drive the other way, and, in the demo,
## one to leave by, GAME.md 9.8; a seat its bot drives has none.
func test_a_held_seat_has_its_switch_in_the_menu() -> void:
	var room := _room(true)
	var match_node: Match = room.get_node("Match")
	await _runner.simulate_frames(5, 17)
	DemoSeats.sit(PAD, match_node)
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
		assert_bool(each.has("leave")).is_true()
	switches.button(0).pressed.emit()
	assert_str(Game.settings.drive_mode(0)).is_equal(Settings.DRIVE_ADVANCED)


## The demo's pause menu: Resume, Join current match and Play the full game, a dotted rule, then
## Settings and Quit, with no Clubhouse and no way to a lobby; Play the full game in foil, a glint
## running across it.
func test_the_demos_pause_menu() -> void:
	var room := _room(true)
	var menu := PauseMenu.add_to(room)
	var asked := [0]
	menu.for_the_demo(func() -> void: asked[0] += 1, Callable(), func() -> bool: return true)
	menu.set_paused(true)
	var shown: Array[String] = []
	var full: Button = null
	for button: Button in menu._buttons():
		if button.visible:
			shown.append(button.text)
		if button.text == "Play the full game":
			full = button
	assert_array(shown).contains_exactly(
		["Resume", "Join current match", "Play the full game", "Settings", "Quit"]
	)
	var after := full.get_parent().get_child(full.get_index() + 1)
	assert_bool(after is Button).is_false()
	# Both ringed buttons catch the eye with a glint, GAME.md 9.8.
	assert_object(menu._join.get_node_or_null("Glint")).is_not_null()
	assert_object(full.get_node_or_null("Glint")).is_not_null()
	full.pressed.emit()
	assert_int(asked[0]).is_equal(1)


## A host whose runs leave the room as a scene change does, taking the title out of the tree there
## and then.
class LeavingHost:
	extends DemoHost
	var dealt := 0

	func deal() -> void:
		dealt += 1
		for title: Node in get_tree().get_nodes_in_group(&"demo_test_title"):
			title.get_parent().remove_child(title)


## The pause key on the title that deals the next run takes the title, and the hand in it, out of
## the tree as the run is dealt; the press is still taken, and nothing is left to hear it.
func test_a_press_that_leaves_the_title_is_still_taken() -> void:
	var title: Control = auto_free(Control.new())
	title.scene_file_path = Game.TITLE_SCENE
	title.add_to_group(&"demo_test_title")
	add_child(title)
	var host: LeavingHost = auto_free(LeavingHost.new())
	add_child(host)
	host.process_mode = Node.PROCESS_MODE_DISABLED
	DemoHand.add_to(title, host)
	var viewport := get_viewport()
	viewport.push_input(_escape())
	assert_int(host.dealt).is_equal(1)
	assert_bool(title.is_inside_tree()).is_false()
	assert_bool(viewport.is_input_handled()).is_true()
