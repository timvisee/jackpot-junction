extends GdUnitTestSuite
## Emotes, GAME.md 3.8: a flick of the right stick or a key, a bubble over the kart for a moment,
## decided where the karts are run and put up on every screen.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DT := 1.0 / 60.0

var _runner: GdUnitSceneRunner
var _touch_was := TouchInput.enabled


## A player whose emotes are whatever the test asks for.
class Emoting:
	extends PlayerInput

	var asked := -1

	func poll(_delta: float) -> void:
		emote = asked
		asked = -1


func after_test() -> void:
	var held: Array[StringName] = InputActions.EMOTES + InputActions.WHEEL_WAYS
	held.append_array([InputActions.AIM_RIGHT, InputActions.AIM_UP, InputActions.EMOTE_WHEEL])
	held.append(InputActions.THROTTLE)
	for action: StringName in held:
		Input.action_release(action)
	TouchInput.enabled = _touch_was
	TouchInput.release()


func test_a_key_or_a_flick_of_the_right_stick_asks_for_an_emote_once() -> void:
	var player := PlayerInput.new(DeviceInput.ANY, -1)
	Input.action_press(InputActions.EMOTE_3)
	player.poll(DT)
	assert_int(player.emote).is_equal(2)
	player.poll(DT)
	assert_int(player.emote).is_equal(-1)
	Input.action_release(InputActions.EMOTE_3)
	# Right is the second of them; held over it asks once, and up after the middle is the first.
	Input.action_press(InputActions.AIM_RIGHT)
	player.poll(DT)
	assert_int(player.emote).is_equal(1)
	player.poll(DT)
	assert_int(player.emote).is_equal(-1)
	Input.action_release(InputActions.AIM_RIGHT)
	player.poll(DT)
	Input.action_press(InputActions.AIM_UP)
	player.poll(DT)
	assert_int(player.emote).is_equal(0)


## V opens the wheel, and the four ways pick from it rather than drive, GAME.md 3.8.
func test_the_wheels_key_opens_it_and_a_way_picks_from_it() -> void:
	var player := PlayerInput.new(DeviceInput.ANY, -1)
	# Already on the gas when it opens: that is driving, not a pick.
	Input.action_press(InputActions.THROTTLE)
	player.poll(DT)
	Input.action_press(InputActions.EMOTE_WHEEL)
	player.poll(DT)
	Input.action_release(InputActions.EMOTE_WHEEL)
	assert_bool(player.wheel_by_keys).is_true()
	assert_int(player.emote).is_equal(-1)
	assert_float(player.throttle).is_equal(0.0)
	Input.action_press(InputActions.STEER_RIGHT)
	player.poll(DT)
	assert_int(player.emote).is_equal(1)
	assert_int(player.take_asked()).is_equal(1)
	assert_int(player.take_asked()).is_equal(-1)
	assert_bool(player.wheel_by_keys).is_false()
	Input.action_release(InputActions.STEER_RIGHT)
	# Open again and nothing picked, it shuts by itself.
	Input.action_press(InputActions.EMOTE_WHEEL)
	player.poll(DT)
	Input.action_release(InputActions.EMOTE_WHEEL)
	for i: int in int(PlayerInput.WHEEL_TIME / DT) + 2:
		player.poll(DT)
	assert_bool(player.wheel_by_keys).is_false()


## Pushed short of a flick, the right stick points at one on the wheel and asks for nothing.
func test_the_right_stick_points_at_one_before_it_flicks() -> void:
	var player := PlayerInput.new(DeviceInput.ANY, -1)
	Input.action_press(InputActions.AIM_UP, 0.5)
	player.poll(DT)
	assert_int(player.wheel_pointing).is_equal(0)
	assert_int(player.emote).is_equal(-1)
	Input.action_release(InputActions.AIM_UP)
	player.poll(DT)
	assert_int(player.wheel_pointing).is_equal(-1)


## A touch screen has a button for them beside the menu button, and a row of the four out of it.
func test_a_touch_screen_taps_an_emote_from_its_button() -> void:
	TouchInput.enabled = true
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var player := PlayerInput.new(DeviceInput.ANY, 0)
	match_node.start([player] as Array[KartInput], 3)
	await _runner.simulate_frames(3, 17)
	var emotes: TouchEmotes = match_node.hud.get_node("TouchEmotes")
	assert_bool(emotes.visible).is_true()
	emotes._input(_tap(emotes, emotes.button_center()))
	assert_bool(emotes.open).is_true()
	emotes._input(_tap(emotes, emotes.emote_center(3)))
	assert_bool(emotes.open).is_false()
	player.poll(DT)
	assert_int(player.emote).is_equal(3)
	# Out, and a tap somewhere else shuts it without asking for any.
	emotes._input(_tap(emotes, emotes.button_center()))
	emotes._input(_tap(emotes, Vector2(40.0, 400.0)))
	assert_bool(emotes.open).is_false()
	player.poll(DT)
	assert_int(player.emote).is_equal(-1)


## The wheel is round the kart of whoever has it open, with the keys for the ways on it.
func test_the_wheel_comes_up_round_the_kart() -> void:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var player := PlayerInput.new(DeviceInput.ANY, 0)
	match_node.start([player] as Array[KartInput], 3)
	await _runner.simulate_frames(3, 17)
	var wheel: EmoteWheel = match_node.hud.get_node("EmoteWheel")
	var root: Control = wheel._wheels[0]["root"]
	assert_bool(root.visible).is_false()
	player._wheel_left = PlayerInput.WHEEL_TIME
	await _runner.simulate_frames(2, 17)
	assert_bool(root.visible).is_true()
	assert_bool((wheel._wheels[0]["keys"] as Array)[0].visible).is_true()
	var camera := wheel.get_viewport().get_camera_3d()
	var kart := match_node.slots[0].kart
	var over := camera.unproject_position(kart.global_position + Vector3.UP * EmoteWheel.LIFT)
	assert_float(root.position.distance_to(over)).is_less(1.0)


func _tap(on: Control, at: Vector2) -> InputEventScreenTouch:
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = on.get_global_transform_with_canvas() * at
	return touch


func test_an_emote_pops_up_over_the_kart_and_goes() -> void:
	var player := Emoting.new()
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([player] as Array[KartInput], 3)
	await _runner.simulate_frames(10, 17)
	var heard := [0]
	var count := func(_slot: int, _emote: int) -> void: heard[0] += 1
	Events.emoted.connect(count)
	player.asked = 3
	await _runner.simulate_frames(3, 17)
	var kart := match_node.slots[0].kart
	assert_int(heard[0]).is_equal(1)
	assert_object(kart.get_node_or_null("Emote")).is_not_null()
	# Another straight away is too soon to be read, and is not put up.
	player.asked = 1
	await _runner.simulate_frames(3, 17)
	assert_int(heard[0]).is_equal(1)
	await _runner.simulate_frames(int(Emotes.SHOWN * 60.0) + 20, 17)
	assert_object(kart.get_node_or_null("Emote")).is_null()
	Events.emoted.disconnect(count)


func test_an_emote_goes_over_the_wire() -> void:
	var source := KartInput.new()
	source.emote = 2
	var remote := NetInput.new()
	remote.receive(NetInput.encode(source), 1)
	remote.receive(NetInput.encode(KartInput.new()), 2)
	remote.poll(DT)
	assert_int(remote.emote).is_equal(2)
	remote.poll(DT)
	assert_int(remote.emote).is_equal(-1)
	# A client from before emotes sends none.
	var old := NetInput.new()
	var packet := NetInput.encode(source)
	packet.resize(NetInput.FIELDS + 4)
	old.receive(packet, 1)
	old.receive(packet, 2)
	old.poll(DT)
	assert_int(old.emote).is_equal(-1)


func test_every_emote_has_a_picture() -> void:
	for i: int in EmoteArt.EMOTES.size():
		var drawn: EmoteArt.Picture = auto_free(EmoteArt.picture(i, Color.RED, 64.0))
		assert_int(drawn.emote).is_equal(i)
	assert_int(InputActions.EMOTES.size()).is_equal(EmoteArt.EMOTES.size())
