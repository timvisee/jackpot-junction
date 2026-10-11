extends GdUnitTestSuite
## Simple driving, GAME.md 4.2: a push says which way on the screen to go, and the kart is driven
## there for the player.

const DT := 1.0 / 60.0
const KART_SCENE := preload("res://scenes/kart/kart.tscn")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")
## The camera of 8.2, looking up the floor toward -Z: up the screen is -Z and right is +X.
const AXES: Array[Vector3] = [Vector3.FORWARD, Vector3.RIGHT]
const UP := Vector2(0.0, -1.0)
const LEFT := Vector2(-1.0, 0.0)

var _stats: KartStats
var _motor: KartMotor
var _input: KartInput
var _drive: SimpleDrive
## The player's own settings, put aside so nothing chosen here is ever theirs.
var _settings_were: Settings


func before_test() -> void:
	_stats = load("res://data/kart/default.tres").duplicate()
	_motor = KartMotor.new(_stats)
	_input = KartInput.new()
	_drive = SimpleDrive.new()
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_simple_drive.cfg"


func after_test() -> void:
	Game.settings = _settings_were
	for action: StringName in [InputActions.STEER_RIGHT, InputActions.DRIVE_UP]:
		Input.action_release(action)


## Faces the kart [param degrees] clockwise from up the screen, at [param speed] along its nose.
func _face(degrees: float, speed := 0.0) -> void:
	_motor.heading = -deg_to_rad(degrees)
	_motor.velocity = _motor.forward_vector() * speed
	_motor.forward_speed = speed


## Which way the nose points, in degrees clockwise from up the screen.
func _facing() -> float:
	var forward := _motor.forward_vector()
	return rad_to_deg(atan2(forward.x, -forward.z))


func _run(push: Vector2, seconds: float, axes: Array[Vector3] = AXES) -> void:
	for i: int in int(round(seconds / DT)):
		_drive.drive(_input, push, axes, _motor, DT)
		_motor.step(_input, DT)


func test_a_push_turns_the_kart_that_way_and_drives_it() -> void:
	_face(90.0)
	_run(UP, 1.5)
	assert_float(_facing()).is_between(-3.0, 3.0)
	assert_float(_motor.forward_speed).is_greater(_stats.top_speed * 0.6)


func test_a_kart_facing_away_turns_before_it_goes() -> void:
	_face(90.0)
	_run(LEFT, 0.1)
	assert_float(_input.throttle).is_equal(0.0)
	assert_float(_input.steer).is_equal(-1.0)


func test_letting_go_brakes_to_a_stop_and_no_further() -> void:
	_face(0.0, _stats.top_speed)
	_run(UP, 0.1)
	_run(Vector2.ZERO, 2.0)
	assert_float(_motor.speed()).is_less(SimpleDrive.STOPPED)
	assert_float(_motor.forward_speed).is_greater_equal(-0.05)
	assert_float(_input.brake).is_equal(0.0)


func test_a_flick_turns_the_kart_after_it_is_let_go() -> void:
	_face(90.0)
	_run(LEFT, 0.05)
	_run(Vector2.ZERO, 1.8)
	assert_float(_facing()).is_equal_approx(-90.0, SimpleDrive.ARRIVED_DEG + 0.5)
	assert_float(_motor.speed()).is_less(1.0)


func test_a_diagonal_let_go_of_one_key_before_the_other_is_the_diagonal() -> void:
	_face(0.0)
	_run(Vector2(1.0, 1.0).normalized(), 0.5)
	_run(Vector2(1.0, 0.0), 0.03)
	_run(Vector2.ZERO, DT)
	var diagonal := Vector3(1.0, 0.0, 1.0).normalized()
	assert_float(_drive.wanted.angle_to(diagonal)).is_less(0.01)


func test_a_new_way_held_a_moment_takes_over() -> void:
	_face(0.0)
	_run(Vector2(1.0, 1.0).normalized(), 0.5)
	_run(Vector2(1.0, 0.0), 0.2)
	_run(Vector2.ZERO, DT)
	assert_float(_drive.wanted.angle_to(Vector3.RIGHT)).is_less(0.01)


func test_the_way_is_the_screens_and_not_the_karts() -> void:
	# A camera looking along +X: up the screen is +X, and right is +Z.
	var along_x: Array[Vector3] = [Vector3.RIGHT, Vector3.BACK]
	_face(0.0)
	_run(UP, 1.5, along_x)
	assert_float(_motor.forward_vector().angle_to(Vector3.RIGHT)).is_less(deg_to_rad(3.0))


func test_the_screen_axes_come_off_the_camera() -> void:
	var camera := Camera3D.new()
	add_child(camera)
	camera.look_at_from_position(Vector3(0.0, 10.0, 7.0), Vector3.ZERO, Vector3.UP)
	var axes := SimpleDrive.screen_axes(camera)
	assert_float(axes[0].angle_to(Vector3.FORWARD)).is_less(0.001)
	assert_float(axes[1].angle_to(Vector3.RIGHT)).is_less(0.001)
	camera.free()


func test_a_way_a_little_off_is_come_round_to_without_sawing() -> void:
	_face(0.0, _stats.top_speed)
	var off := deg_to_rad(10.0)
	var push := Vector2(sin(off), -cos(off))
	for i: int in 90:
		_drive.drive(_input, push, AXES, _motor, DT)
		_motor.step(_input, DT)
		assert_float(_input.steer).is_greater_equal(0.0)
	assert_float(_facing()).is_equal_approx(10.0, 1.0)


func test_the_nitro_drives_on_when_let_go() -> void:
	_face(0.0, _stats.top_speed)
	_input.nitro = true
	_run(Vector2.ZERO, DT)
	assert_float(_input.brake).is_equal(0.0)


func test_once_there_a_knock_is_not_turned_back_against() -> void:
	_face(90.0)
	_run(LEFT, 0.05)
	_run(Vector2.ZERO, 2.0)
	assert_bool(_drive.wanted.is_zero_approx()).is_true()
	_face(120.0)
	_run(Vector2.ZERO, 0.5)
	assert_float(_facing()).is_equal_approx(120.0, 0.5)


func test_a_seat_drives_the_way_its_setting_says() -> void:
	var player := PlayerInput.new(DeviceInput.ANY, 1)
	assert_bool(player.simple()).is_false()
	Game.settings.drive_modes[1] = Settings.DRIVE_SIMPLE
	assert_bool(player.simple()).is_true()
	# Controls with no seat are a tool's, and work the wheel whatever anybody chose.
	Game.settings.drive_modes[0] = Settings.DRIVE_SIMPLE
	assert_bool(PlayerInput.new().simple()).is_false()


func test_simple_driving_leaves_the_pedals_to_the_push() -> void:
	Game.settings.drive_modes[0] = Settings.DRIVE_SIMPLE
	var player := PlayerInput.new(DeviceInput.ANY, 0)
	Input.action_press(InputActions.DRIVE_UP)
	player.poll(DT)
	# Up is a way to go rather than the gas pedal, but no kart yet only revs the engine.
	assert_float(player.throttle).is_equal(1.0)
	assert_float(player.steer).is_equal(0.0)
	Input.action_release(InputActions.DRIVE_UP)
	Input.action_press(InputActions.STEER_RIGHT)
	player.poll(DT)
	# The joker cursor goes by the push, not by what the wheel does with it.
	assert_float(player.cursor).is_equal(1.0)


func test_a_pads_triggers_still_work_the_pedals_over_the_push() -> void:
	Game.settings.drive_modes[0] = Settings.DRIVE_SIMPLE
	var player := PadPlayer.new()
	Input.action_press(InputActions.DRIVE_UP)
	player.poll(DT)
	assert_float(player.throttle).is_equal(1.0)
	player.pedals = Vector2(0.0, 1.0)
	player.poll(DT)
	assert_float(player.throttle).is_equal(0.0)
	assert_float(player.brake).is_equal(1.0)
	Input.action_release(InputActions.DRIVE_UP)
	player.pedals = Vector2(0.5, 0.0)
	player.poll(DT)
	assert_float(player.throttle).is_equal(0.5)
	player.pedals = Vector2.ZERO
	player.poll(DT)
	assert_float(player.throttle).is_equal(0.0)


## With Auto throttle off, GAME.md 4.2, the push only steers, and only while it is held: let go, the
## kart is not turned on toward the way last pushed, and the pedals are left to the player.
func test_without_auto_throttle_the_push_only_steers_while_held() -> void:
	_face(0.0)
	_input.throttle = 0.3
	_input.brake = 0.0
	_drive.drive(_input, LEFT, AXES, _motor, DT, false)
	assert_float(absf(_input.steer)).is_greater(0.5)
	assert_float(_input.throttle).is_equal(0.3)
	_drive.drive(_input, Vector2.ZERO, AXES, _motor, DT, false)
	assert_float(_input.steer).is_equal(0.0)
	assert_bool(_drive.wanted.is_zero_approx()).is_true()
	assert_float(_input.brake).is_equal(0.0)
	# With it on, a flick is turned on toward after it is let go of.
	_drive.drive(_input, LEFT, AXES, _motor, DT)
	_drive.drive(_input, Vector2.ZERO, AXES, _motor, DT)
	assert_float(absf(_input.steer)).is_greater(0.5)


## The pedals are the player's own with Auto throttle off, which it is to start with, on a pad or a
## touch screen, never on the keyboard, whose keys are all the way to go; on a pad then the triggers
## are the gas and the brake whatever the stick says.
func test_the_pedals_are_a_pads_own_but_never_the_keyboards() -> void:
	Game.settings.drive_modes[0] = Settings.DRIVE_SIMPLE
	assert_bool(Game.settings.auto_throttle(0)).is_false()
	assert_bool(PlayerInput.new(0, 0).works_the_pedals()).is_true()
	assert_bool(PlayerInput.new(DeviceInput.KEYBOARD, 0).works_the_pedals()).is_false()
	Game.settings.set_auto_throttle(0, true)
	assert_bool(PlayerInput.new(0, 0).works_the_pedals()).is_false()
	Game.settings.set_auto_throttle(0, false)
	var player := PadPlayer.new()
	player.last_device = 0
	assert_bool(player.works_the_pedals()).is_true()
	Input.action_press(InputActions.DRIVE_UP)
	player.poll(DT)
	# Pushed up the screen, but no trigger pressed: no gas.
	assert_float(player.throttle).is_equal(0.0)
	player.pedals = Vector2(0.7, 0.0)
	player.poll(DT)
	assert_float(player.throttle).is_equal_approx(0.7, 0.001)
	Input.action_release(InputActions.DRIVE_UP)
	# Kept with the rest of the seat's driving.
	Game.settings.set_auto_throttle(1, true)
	var kept := Game.settings.profile
	kept.path = "user://test_simple_drive_profile.cfg"
	kept.save_to_disk()
	var read := Profile.new()
	read.path = kept.path
	read.load_from_disk()
	assert_bool(read.auto_throttle[1]).is_true()
	assert_bool(read.auto_throttle[0]).is_false()
	DirAccess.remove_absolute(kept.path)


func test_the_keyboards_brake_is_the_way_down_in_simple_driving() -> void:
	Game.settings.drive_modes[0] = Settings.DRIVE_SIMPLE
	var player := PlayerInput.new(DeviceInput.ANY, 0)
	Input.action_press(InputActions.BRAKE)
	Input.action_press(InputActions.DRIVE_DOWN)
	player.poll(DT)
	# S is down the screen here, and the kart goes that way rather than braking: a key is never a
	# pad's pedal.
	assert_float(player.throttle).is_equal(1.0)
	assert_float(player.brake).is_equal(0.0)
	assert_float(DeviceInput.pad_strength(InputActions.BRAKE, DeviceInput.ANY)).is_equal(0.0)
	assert_float(DeviceInput.pad_strength(InputActions.BRAKE, DeviceInput.KEYBOARD)).is_equal(0.0)
	Input.action_release(InputActions.BRAKE)
	Input.action_release(InputActions.DRIVE_DOWN)


func test_the_kart_is_known_to_the_controls_it_is_handed() -> void:
	var kart: Kart = KART_SCENE.instantiate()
	var player := PlayerInput.new(DeviceInput.ANY, 0)
	kart.input = player
	assert_object(player.kart).is_same(kart)
	kart.free()


func test_the_first_answer_is_every_seats_that_has_none() -> void:
	var settings := Game.settings
	assert_bool(settings.has_chosen_driving()).is_false()
	settings.drive_modes[2] = Settings.DRIVE_ADVANCED
	settings.choose_driving(Settings.DRIVE_SIMPLE)
	assert_bool(settings.has_chosen_driving()).is_true()
	assert_str(settings.drive_mode(0)).is_equal(Settings.DRIVE_SIMPLE)
	assert_str(settings.drive_mode(2)).is_equal(Settings.DRIVE_ADVANCED)
	assert_str(settings.drive_mode(3)).is_equal(Settings.DRIVE_SIMPLE)


func test_the_ways_to_drive_are_saved() -> void:
	var settings := Game.settings
	settings.drive_modes[1] = Settings.DRIVE_SIMPLE
	assert_int(settings.save_to_disk()).is_equal(OK)
	var loaded := Settings.new()
	loaded.path = settings.path
	loaded.load_from_disk()
	assert_str(loaded.drive_mode(1)).is_equal(Settings.DRIVE_SIMPLE)
	assert_bool(loaded.has_chosen_driving()).is_false()
	Settings.remove_files(settings.path)


func test_the_push_that_walks_the_cursor_goes_over_the_wire() -> void:
	var source := KartInput.new()
	source.steer = -0.4
	source.cursor = 1.0
	var remote := NetInput.new()
	remote.receive(NetInput.encode(source), 1)
	remote.receive(NetInput.encode(source), 2)
	remote.poll(DT)
	assert_float(remote.cursor).is_equal(1.0)
	# A client from before it sends the wheel alone, and for it the wheel was the push.
	var old := NetInput.new()
	var packet := NetInput.encode(source)
	packet.resize(NetInput.FIELDS + 3)
	old.receive(packet, 1)
	old.receive(packet, 2)
	old.poll(DT)
	assert_float(old.cursor).is_equal(-0.4)


func test_the_first_play_asks_how_to_drive_and_goes_on_once_answered() -> void:
	var holder: Control = auto_free(Control.new())
	add_child(holder)
	var went := [0]
	var choice := DriveChoice.first(holder, func() -> void: went[0] += 1)
	assert_object(choice).is_not_null()
	assert_int(went[0]).is_equal(0)
	# The cursor starts on a card and stays on the two.
	await await_idle_frame()
	assert_object(get_viewport().gui_get_focus_owner()).is_same(choice.card(Settings.DRIVE_SIMPLE))
	choice.card(Settings.DRIVE_ADVANCED).pressed.emit()
	assert_int(went[0]).is_equal(1)
	assert_str(Game.settings.drive_mode(0)).is_equal(Settings.DRIVE_ADVANCED)
	assert_str(Game.settings.drive_mode(3)).is_equal(Settings.DRIVE_ADVANCED)
	# Answered once, it is never asked again.
	assert_object(DriveChoice.first(holder, func() -> void: went[0] += 1)).is_null()
	assert_int(went[0]).is_equal(2)
	Settings.remove_files(Game.settings.path)


func test_the_settings_ask_the_question_again_for_the_first_player() -> void:
	Game.settings.drive_modes = [
		Settings.DRIVE_SIMPLE, Settings.DRIVE_ADVANCED, Settings.DRIVE_SIMPLE, ""
	]
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	var again: Button = null
	for button: Node in screen.find_children("*", "Button", true, false):
		if (button as Button).text == "Help me choose":
			again = button
	again.pressed.emit()
	var choice: DriveChoice = screen.get_node("DriveChoice")
	await await_idle_frame()
	# The cursor starts on what the first player drives now.
	assert_object(get_viewport().gui_get_focus_owner()).is_same(choice.card(Settings.DRIVE_SIMPLE))
	choice.card(Settings.DRIVE_ADVANCED).pressed.emit()
	await await_idle_frame()
	# The first player's alone, whatever the others said, and the row shows it.
	assert_array(Game.settings.drive_modes).is_equal(
		[Settings.DRIVE_ADVANCED, Settings.DRIVE_ADVANCED, Settings.DRIVE_SIMPLE, ""]
	)
	var picker: DrivePicker = again.get_parent()
	assert_str(picker.mode).is_equal(Settings.DRIVE_ADVANCED)
	assert_object(get_viewport().gui_get_focus_owner()).is_same(again)
	Settings.remove_files(Game.settings.path)


func test_the_player_at_a_touch_screen_can_switch_its_controls_there_too() -> void:
	var was_touch := TouchInput.enabled
	TouchInput.enabled = true
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.with_hud = true
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, 0), KartInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(3, 17)
	var menu := PauseMenu.add_to(match_node)
	menu.set_paused(true)
	await await_idle_frame()
	var buttons: Array[Control] = menu._switches._up[0]["buttons"]
	assert_int(buttons.size()).is_equal(2)
	(buttons[1] as Button).pressed.emit()
	assert_str(Game.settings.touch_layout).is_equal(Settings.TOUCH_BUTTONS)
	assert_str(Game.settings.drive_mode(0)).is_equal(Settings.DRIVE_ADVANCED)
	# The two are one column to a pad: down from the one is the other.
	assert_object(buttons[0].find_valid_focus_neighbor(SIDE_BOTTOM)).is_same(buttons[1])
	menu.set_paused(false)
	get_tree().paused = false
	TouchInput.enabled = was_touch
	TouchInput.release()
	Settings.remove_files(Game.settings.path)


func test_the_settings_pick_the_touch_controls_by_their_pictures() -> void:
	var was_touch := TouchInput.enabled
	TouchInput.enabled = true
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	var pickers := screen.find_children("*", "DrivePicker", true, false)
	var touch: DrivePicker = null
	for each: Node in pickers:
		if (each as DrivePicker).button(Settings.TOUCH_SLIDER) != null:
			touch = each
	assert_object(touch).is_not_null()
	assert_str(touch.mode).is_equal(Settings.TOUCH_SLIDER)
	touch.button(Settings.TOUCH_BUTTONS).pressed.emit()
	assert_str(Game.settings.touch_layout).is_equal(Settings.TOUCH_BUTTONS)
	TouchInput.enabled = was_touch


## Each seat's name on the Seats tab has a small switch after it for how that seat drives, and
## the first seat's is the same setting as the Driving row of the Controls tab.
func test_each_seat_on_the_players_tab_has_a_driving_switch() -> void:
	var screen: SettingsScreen = auto_free(SETTINGS_SCENE.instantiate())
	add_child(screen)
	var second: Button = screen.find_child("Driving1", true, false)
	assert_object(second).is_not_null()
	second.pressed.emit()
	assert_str(Game.settings.drive_mode(1)).is_equal(Settings.DRIVE_SIMPLE)
	assert_str(second.tooltip_text).is_equal("Simple driving")
	second.pressed.emit()
	assert_str(Game.settings.drive_mode(1)).is_equal(Settings.DRIVE_ADVANCED)
	var first: Button = screen.find_child("Driving0", true, false)
	first.pressed.emit()
	assert_str(screen._first_driving.mode).is_equal(Settings.DRIVE_SIMPLE)
	screen._first_driving.button(Settings.DRIVE_ADVANCED).pressed.emit()
	assert_str(first.tooltip_text).is_equal("Advanced driving")


func test_back_puts_the_question_away_unanswered() -> void:
	var holder: Control = auto_free(Control.new())
	add_child(holder)
	var went := [0]
	var choice := DriveChoice.first(holder, func() -> void: went[0] += 1)
	var back := InputEventAction.new()
	back.action = &"ui_cancel"
	back.pressed = true
	choice._unhandled_input(back)
	await await_idle_frame()
	assert_bool(is_instance_valid(choice)).is_false()
	assert_int(went[0]).is_equal(0)
	assert_bool(Game.settings.has_chosen_driving()).is_false()


func test_the_pause_menu_has_a_switch_over_each_players_corner() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.with_hud = true
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(0, 1), KartInput.new()
	]
	match_node.start(inputs, 5)
	await runner.simulate_frames(3, 17)
	var menu := PauseMenu.add_to(match_node)
	menu.set_paused(true)
	await await_idle_frame()
	for seat: int in 2:
		var corner: Control = match_node.hud.get_node("Block%d" % seat)
		var switch := menu._switches.button(seat)
		assert_object(switch).is_not_null()
		assert_bool(switch.get_global_rect().intersects(corner.get_global_rect())).is_true()
	# Under each, what that player is playing on and the keys or the stick they drive with.
	var cards: Array[String] = []
	for each: Dictionary in menu._switches._up:
		var words: Label = (each["card"] as Control).get_child(0).get_child(0)
		cards.append(words.text)
	assert_array(cards).contains_exactly(["Keyboard", "Gamepad 1"])
	menu._switches.button(1).pressed.emit()
	assert_str(Game.settings.drive_mode(1)).is_equal(Settings.DRIVE_SIMPLE)
	assert_str(Game.settings.drive_mode(0)).is_equal(Settings.DRIVE_ADVANCED)
	assert_bool((inputs[1] as PlayerInput).simple()).is_true()
	menu._switches.button(1).pressed.emit()
	assert_str(Game.settings.drive_mode(1)).is_equal(Settings.DRIVE_ADVANCED)
	# A pad's cursor goes out to them from the menu, to the side each is on, and back.
	var resume := menu._resume
	assert_object(resume.find_valid_focus_neighbor(SIDE_LEFT)).is_same(menu._switches.button(0))
	assert_object(resume.find_valid_focus_neighbor(SIDE_RIGHT)).is_same(menu._switches.button(1))
	# Up and down stay in the menu: only sideways goes out to them.
	assert_object(resume.find_valid_focus_neighbor(SIDE_TOP)).is_same(resume)
	var last: Button = menu._buttons()[-1]
	assert_object(last.find_valid_focus_neighbor(SIDE_BOTTOM)).is_same(last)
	var left := menu._switches.button(0)
	assert_object(left.find_valid_focus_neighbor(SIDE_RIGHT)).is_same(resume)
	assert_object(left.find_valid_focus_neighbor(SIDE_LEFT)).is_same(left)
	menu.set_paused(false)
	assert_object(menu._switches.button(0)).is_null()
	assert_bool(resume.focus_neighbor_left.is_empty()).is_true()
	get_tree().paused = false
	Settings.remove_files(Game.settings.path)


## The card saying what a player drives with is toward the middle of the screen: under the switch
## of a player in a top corner, over the switch of the third, in a bottom one.
func test_a_bottom_corner_has_its_card_over_the_switch() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.with_hud = true
	match_node.offer_size = 0
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(0, 1), PlayerInput.new(1, 2)
	]
	match_node.start(inputs, 5)
	await runner.simulate_frames(3, 17)
	var menu := PauseMenu.add_to(match_node)
	menu.set_paused(true)
	await await_idle_frame()
	var up: Array[Dictionary] = menu._switches._up
	assert_int(up.size()).is_equal(3)
	for each: Dictionary in up:
		var card: Control = each["card"]
		var pane: Control = each["pane"]
		var corner: Control = each["corner"]
		var bottom := corner.get_global_rect().get_center().y > menu._switches.size.y * 0.5
		assert_bool(card.get_index() < pane.get_index()).is_equal(bottom)
	var third: Dictionary = up[2]
	var third_corner: Control = third["corner"]
	(
		assert_bool(third_corner.get_global_rect().get_center().y > menu._switches.size.y * 0.5)
		. is_true()
	)
	menu.set_paused(false)
	get_tree().paused = false
	Settings.remove_files(Game.settings.path)


## A player on a pad whose triggers are wherever the test puts them.
class PadPlayer:
	extends PlayerInput

	var pedals := Vector2.ZERO

	func _init() -> void:
		super(DeviceInput.ANY, 0)

	func _pad_pedals() -> Vector2:
		return pedals
