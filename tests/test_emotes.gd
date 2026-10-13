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
	(
		held
		. append_array(
			[
				InputActions.AIM_RIGHT,
				InputActions.AIM_UP,
				InputActions.AIM_LEFT,
				InputActions.EMOTE_WHEEL,
			]
		)
	)
	held.append(InputActions.THROTTLE)
	for action: StringName in held:
		Input.action_release(action)
	TouchInput.enabled = _touch_was
	TouchInput.release()


func test_a_key_or_the_right_stick_held_on_one_asks_for_an_emote_once() -> void:
	var player := PlayerInput.new(DeviceInput.ANY, -1)
	Input.action_press(InputActions.EMOTE_3)
	player.poll(DT)
	assert_int(player.emote).is_equal(2)
	player.poll(DT)
	assert_int(player.emote).is_equal(-1)
	Input.action_release(InputActions.EMOTE_3)
	# Right is the second of them: held there the ring fills, and once it is full it is armed,
	# and let go it is asked for, once.
	Input.action_press(InputActions.AIM_RIGHT)
	_hold(player, PlayerInput.ARM_TIME * 0.5)
	assert_int(player.wheel_pointing).is_equal(1)
	assert_float(player.wheel_charge).is_between(0.3, 0.7)
	assert_bool(player.wheel_armed).is_false()
	_hold(player, PlayerInput.ARM_TIME * 0.5 + DT * 2.0)
	assert_bool(player.wheel_armed).is_true()
	assert_int(player.emote).is_equal(-1)
	Input.action_release(InputActions.AIM_RIGHT)
	player.poll(DT)
	assert_int(player.emote).is_equal(1)
	player.poll(DT)
	assert_int(player.emote).is_equal(-1)
	# A flick to the edge and straight back is too quick to have meant one.
	Input.action_press(InputActions.AIM_UP)
	player.poll(DT)
	player.poll(DT)
	Input.action_release(InputActions.AIM_UP)
	player.poll(DT)
	assert_int(player.emote).is_equal(-1)


## Let go, a stick snaps back past the middle to the other side for a moment: the one it was armed
## on is asked for, not the one on the far side it passed over.
func test_a_stick_let_go_asks_for_the_armed_one_past_its_snap_back() -> void:
	var player := PlayerInput.new(DeviceInput.ANY, -1)
	Input.action_press(InputActions.AIM_RIGHT)
	_hold(player, PlayerInput.ARM_TIME + DT * 2.0)
	assert_bool(player.wheel_armed).is_true()
	Input.action_release(InputActions.AIM_RIGHT)
	Input.action_press(InputActions.AIM_LEFT, 0.7)
	player.poll(DT)
	player.poll(DT)
	assert_int(player.emote).is_equal(-1)
	assert_int(player.wheel_pointing).is_equal(1)
	Input.action_release(InputActions.AIM_LEFT)
	player.poll(DT)
	assert_int(player.emote).is_equal(1)


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
	assert_bool(player.wheel_by_keys).is_false()
	Input.action_release(InputActions.STEER_RIGHT)
	# Open again and nothing picked, it shuts by itself.
	Input.action_press(InputActions.EMOTE_WHEEL)
	player.poll(DT)
	Input.action_release(InputActions.EMOTE_WHEEL)
	for i: int in int(PlayerInput.WHEEL_TIME / DT) + 2:
		player.poll(DT)
	assert_bool(player.wheel_by_keys).is_false()


## Pushed short of the edge, the right stick brings the wheel up and points at one on it, for as
## long as it is held, but never arms it, and let go from there asks for nothing. Armed at the
## edge and then moved off it slowly, onto another or toward the middle, is changing one's mind:
## nothing is asked for.
func test_the_right_stick_holds_the_wheel_up_and_moving_off_asks_nothing() -> void:
	var player := PlayerInput.new(DeviceInput.ANY, -1)
	Input.action_press(InputActions.AIM_UP, 0.5)
	_hold(player, PlayerInput.ARM_TIME * 2.0)
	assert_int(player.wheel_pointing).is_equal(0)
	assert_float(player.wheel_charge).is_zero()
	assert_bool(player.wheel_armed).is_false()
	Input.action_release(InputActions.AIM_UP)
	player.poll(DT)
	assert_int(player.emote).is_equal(-1)
	assert_int(player.wheel_pointing).is_equal(-1)
	# Armed on up, then round to the left and held there: up is let go of, nothing asked for.
	Input.action_press(InputActions.AIM_UP, 0.9)
	_hold(player, PlayerInput.ARM_TIME + DT * 2.0)
	assert_bool(player.wheel_armed).is_true()
	Input.action_release(InputActions.AIM_UP)
	Input.action_press(InputActions.AIM_LEFT, 0.6)
	_hold(player, PlayerInput.LET_GO_TIME * 2.0)
	assert_int(player.wheel_pointing).is_equal(3)
	assert_bool(player.wheel_armed).is_false()
	Input.action_release(InputActions.AIM_LEFT)
	player.poll(DT)
	assert_int(player.emote).is_equal(-1)
	# Armed again, and eased back toward the middle slowly: nothing either.
	Input.action_press(InputActions.AIM_UP, 0.9)
	_hold(player, PlayerInput.ARM_TIME + DT * 2.0)
	Input.action_release(InputActions.AIM_UP)
	Input.action_press(InputActions.AIM_UP, 0.5)
	_hold(player, PlayerInput.LET_GO_TIME * 2.0)
	Input.action_release(InputActions.AIM_UP)
	player.poll(DT)
	assert_int(player.emote).is_equal(-1)


## Polls [param player] for [param seconds] as the stick stands.
func _hold(player: PlayerInput, seconds: float) -> void:
	for i: int in ceili(seconds / DT):
		player.poll(DT)


## A touch screen has a button for them beside the menu button, and a row of the four out of it.
func test_a_touch_screen_taps_an_emote_from_its_button() -> void:
	TouchInput.enabled = true
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var player := PlayerInput.new(DeviceInput.ANY, 0)
	match_node.start([player, KartInput.new()] as Array[KartInput], 3)
	await _runner.simulate_frames(3, 17)
	var emotes: TouchEmotes = match_node.hud.get_node("TouchEmotes")
	# Against bots alone there is nobody to put one up for; with a friend on the wire there is.
	assert_bool(emotes.visible).is_false()
	match_node.slots[1].input = NetInput.new()
	await _runner.simulate_frames(2, 17)
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
	# Its own key, or a finger on the touch screen's button, asks for one without it.
	player._wheel_left = 0.0
	await _runner.simulate_frames(2, 17)
	Input.action_press(InputActions.EMOTE_2)
	await _runner.simulate_frames(2, 17)
	assert_object(kart.get_node_or_null("Emote")).is_not_null()
	assert_bool(root.visible).is_false()


## Somebody watching has no kart: their emote floats up from the bottom of the screen in gray,
## with their name under it, and goes.
func test_a_watchers_emote_floats_up_the_screen() -> void:
	var holder: CanvasLayer = auto_free(CanvasLayer.new())
	add_child(holder)
	var emotes := WatcherEmotes.add_to(holder, null)
	await await_idle_frame()
	Events.watcher_emoted.emit("Ann", 2)
	var bubble: Control = emotes.get_node("WatcherEmote")
	var label: Label = bubble.get_child(1)
	assert_str(label.text).is_equal("Ann")
	var picture: EmoteArt.Picture = bubble.get_child(0)
	assert_int(picture.emote).is_equal(2)
	assert_that(picture.ink).is_equal(WatcherEmotes.INK)
	var start := bubble.position.y
	assert_float(start).is_greater(emotes.size.y * 0.5)
	await get_tree().create_timer(0.5).timeout
	assert_float(bubble.position.y).is_less(start)
	await get_tree().create_timer(WatcherEmotes.SHOWN).timeout
	assert_bool(is_instance_valid(bubble)).is_false()


## A player waiting to come back emotes too, and with no kart to put it over, it floats up from the
## bottom the way a watcher's does, in the player's own color and under their name.
func test_a_dead_players_emote_floats_up_in_their_color() -> void:
	var player := Emoting.new()
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.with_hud = false
	match_node.offer_size = 0
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	match_node.rules = rules
	_runner = scene_runner(match_node)
	match_node.start([player] as Array[KartInput], 3)
	var holder: CanvasLayer = auto_free(CanvasLayer.new())
	add_child(holder)
	var emotes := WatcherEmotes.add_to(holder, match_node)
	await _runner.simulate_frames(20, 17)
	var kart := match_node.slots[0].kart
	kart.die(&"pit", -1)
	player.asked = 1
	await _runner.simulate_frames(3, 17)
	assert_object(kart.get_node_or_null("Emote")).is_null()
	var bubble: Control = emotes.get_node_or_null("WatcherEmote")
	assert_object(bubble).override_failure_message("nothing floated up").is_not_null()
	var picture: EmoteArt.Picture = bubble.get_child(0)
	assert_int(picture.emote).is_equal(1)
	assert_that(picture.ink).is_equal(match_node.slots[0].color())
	assert_str((bubble.get_child(1) as Label).text).is_equal(match_node.slots[0].display_name())


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


## The photo finish is a moment to say something too, GAME.md 3.8: past the whistle a player's
## emote is still read and put up over their kart, and over their kart on the podium.
func test_an_emote_after_the_whistle_reaches_the_photo_finish() -> void:
	var player := Emoting.new()
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([player] as Array[KartInput], 3)
	await _runner.simulate_frames(10, 17)
	match_node._finish()
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	var podium := ResultsPodium.create()
	match_node.add_child(podium)
	var standings: Array[PlayerSlot] = []
	standings.assign(match_node.slots)
	podium.show_top(standings)
	player.asked = 2
	await _runner.simulate_frames(3, 17)
	assert_object(match_node.slots[0].kart.get_node_or_null("Emote")).is_not_null()
	var on_podium: Node3D = podium._karts[standings.find(match_node.slots[0])]
	assert_object(on_podium.get_node_or_null("Emote")).is_not_null()


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
