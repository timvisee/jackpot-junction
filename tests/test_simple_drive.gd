extends GdUnitTestSuite
## Simple driving, GAME.md 4.2: a push says which way on the screen to go, and the kart is driven
## there for the player.

const DT := 1.0 / 60.0
const KART_SCENE := preload("res://scenes/kart/kart.tscn")
const MATCH_SCENE := preload("res://scenes/match/match.tscn")
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
	DirAccess.remove_absolute(settings.path)


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
	DirAccess.remove_absolute(Game.settings.path)


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
	menu._switches.button(1).pressed.emit()
	assert_str(Game.settings.drive_mode(1)).is_equal(Settings.DRIVE_SIMPLE)
	assert_str(Game.settings.drive_mode(0)).is_equal(Settings.DRIVE_ADVANCED)
	assert_bool((inputs[1] as PlayerInput).simple()).is_true()
	menu._switches.button(1).pressed.emit()
	assert_str(Game.settings.drive_mode(1)).is_equal(Settings.DRIVE_ADVANCED)
	menu.set_paused(false)
	assert_object(menu._switches.button(0)).is_null()
	DirAccess.remove_absolute(Game.settings.path)
