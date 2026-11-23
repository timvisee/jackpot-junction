extends GdUnitTestSuite
## A pad that goes while it is played on, GAME.md 4.2: the room's menu comes up for the player
## holding it, who keeps their seat while it is up, the next pad that comes theirs; played on
## without it, a bot takes the kart until the pad comes again and takes it back. A pad nobody holds
## goes unremarked. On pads no machine has, so a pad plugged in here plays no part.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
## Pads nobody has plugged in: the second player's, another, and the one that comes in its place.
const PAD := 21
const OTHER := 22
const NEW_PAD := 23

var _match: Match
var _menu: PauseMenu


## A room with [param inputs] at this machine and its menu, put away.
func _room(inputs: Array[KartInput]) -> void:
	_match = auto_free(MATCH_SCENE.instantiate())
	_match.with_hud = true
	_match.offer_size = 0
	var runner := scene_runner(_match)
	_match.start(inputs, 5)
	await runner.simulate_frames(3, 17)
	_menu = PauseMenu.add_to(_match)
	await await_idle_frame()


func after_test() -> void:
	if is_instance_valid(_menu):
		_menu.set_paused(false)
	get_tree().paused = false
	DeviceInput.recent.clear()
	Settings.remove_files(Game.settings.path)


func test_a_pad_that_goes_brings_the_menu_up_and_keeps_the_seat() -> void:
	await _room([PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(PAD, 1)])
	assert_bool(_menu.is_open()).is_false()
	Input.joy_connection_changed.emit(PAD, false)
	await await_idle_frame()
	assert_bool(_menu.is_open()).is_true()
	assert_bool(_match.slots[1].is_human()).is_true()
	assert_int(_match.slots[1].device()).is_equal(PAD)


func test_the_next_pad_that_comes_is_theirs() -> void:
	await _room([PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(PAD, 1)])
	Input.joy_connection_changed.emit(PAD, false)
	Input.joy_connection_changed.emit(NEW_PAD, true)
	assert_int(_match.slots[1].device()).is_equal(NEW_PAD)
	# The keyboard's player keeps theirs.
	assert_int(_match.slots[0].device()).is_equal(DeviceInput.KEYBOARD)


func test_a_player_on_every_device_is_paused_for_the_pad_they_drove_with() -> void:
	var alone := PlayerInput.new(DeviceInput.ANY, 0)
	alone.last_device = PAD
	await _room([alone])
	Input.joy_connection_changed.emit(PAD, false)
	await await_idle_frame()
	assert_bool(_menu.is_open()).is_true()


func test_a_pad_nobody_holds_goes_unremarked() -> void:
	await _room([PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(PAD, 1)])
	Input.joy_connection_changed.emit(OTHER, false)
	await await_idle_frame()
	assert_bool(_menu.is_open()).is_false()


func test_played_on_without_the_pad_a_bot_takes_the_kart() -> void:
	await _room([PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(PAD, 1)])
	Input.joy_connection_changed.emit(PAD, false)
	await await_idle_frame()
	_menu.set_paused(false)
	assert_bool(_match.slots[1].is_human()).is_false()
	assert_bool(_match.slots[0].is_human()).is_true()


func test_the_pad_coming_again_takes_the_same_kart_back() -> void:
	await _room([PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(PAD, 1)])
	var named := _match.slots[1].player_name
	var kart := _match.slots[1].kart
	Input.joy_connection_changed.emit(PAD, false)
	await await_idle_frame()
	_menu.set_paused(false)
	# Another pad is somebody else's, to join with as anybody does.
	Input.joy_connection_changed.emit(OTHER, true)
	assert_bool(_match.slots[1].is_human()).is_false()
	Input.joy_connection_changed.emit(PAD, true)
	assert_bool(_match.slots[1].is_human()).is_true()
	assert_int(_match.slots[1].device()).is_equal(PAD)
	assert_object(_match.slots[1].kart).is_same(kart)
	assert_str(_match.slots[1].player_name).is_equal(named)


func test_a_player_on_every_device_plays_on_without_a_bot() -> void:
	var alone := PlayerInput.new(DeviceInput.ANY, 0)
	alone.last_device = PAD
	await _room([alone])
	Input.joy_connection_changed.emit(PAD, false)
	await await_idle_frame()
	_menu.set_paused(false)
	assert_bool(_match.slots[0].is_human()).is_true()


func test_a_room_with_no_menu_hands_the_kart_to_a_bot_at_once() -> void:
	_match = auto_free(MATCH_SCENE.instantiate())
	_match.offer_size = 0
	var runner := scene_runner(_match)
	var inputs: Array[KartInput] = [
		PlayerInput.new(DeviceInput.KEYBOARD, 0), PlayerInput.new(PAD, 1)
	]
	_match.start(inputs, 5)
	await runner.simulate_frames(3, 17)
	Input.joy_connection_changed.emit(PAD, false)
	assert_bool(_match.slots[1].is_human()).is_false()
