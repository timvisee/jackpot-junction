extends GdUnitTestSuite
## The stalls a kart is dressed at, GAME.md 4.4 and 9.6: a pad each for the paint, the hat, the
## flag and the trail, driven onto rather than picked from a menu, in the lobby and the garage,
## at this machine and across the wire.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")

var _runner: GdUnitSceneRunner
var _settings_were: Settings


func before_test() -> void:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_style_stalls.cfg"


func after_test() -> void:
	DirAccess.remove_absolute(Game.settings.path)
	Game.settings = _settings_were


func _room(inputs: Array[KartInput]) -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.with_hud = false
	_runner = scene_runner(match_node)
	match_node.start(inputs, 3)
	return match_node


func _park(kart: Kart, on: Rect2) -> void:
	var middle := on.get_center()
	kart.global_position = Vector3(middle.x, 0.0, middle.y)
	kart.motor.velocity = Vector3.ZERO


func test_a_stall_puts_the_next_one_on_and_goes_on_while_the_kart_stays() -> void:
	var player := PlayerInput.new(DeviceInput.KEYBOARD, 0)
	var match_node := _room([player])
	await _runner.simulate_frames(10, 17)
	var stalls := StyleStalls.add_to(match_node, Vector2i(8, 1))
	var slot := match_node.slots[0]
	var kart := slot.kart
	_park(kart, stalls._areas[1])
	await _runner.simulate_frames(3, 17)
	assert_int(slot.style.hat).is_equal(1)
	assert_int(kart.style.hat).is_equal(1)
	assert_object(kart.get_node("Body").get_node_or_null("Hat")).is_not_null()
	# Kept in the seat's settings, for the next room and the next time.
	assert_int(PackedInt32Array(Game.settings.kart_styles[0])[1]).is_equal(1)
	# Held there, the next one comes round, and the one after.
	await _runner.simulate_frames(int(StyleStalls.STEP_TIME * 60.0) + 6, 17)
	assert_int(slot.style.hat).is_equal(2)
	# Off and on again is one more, whatever the wait.
	kart.global_position = Vector3(0.0, 0.0, 5.0)
	await _runner.simulate_frames(3, 17)
	_park(kart, stalls._areas[3])
	await _runner.simulate_frames(3, 17)
	assert_int(slot.style.trail).is_equal(1)
	assert_int(slot.style.hat).is_equal(2)


func test_a_dressed_kart_changes_on_a_clients_screen_too() -> void:
	var host := _room([KartInput.new()])
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = RULES.duplicate()
	client.arena_layout = LAYOUT
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	await _runner.simulate_frames(5, 17)
	client.apply_snapshot(host.build_snapshot())
	var puppet: Kart = client.puppet_karts.values()[0]
	assert_int(puppet.style.flag).is_equal(0)
	StyleStalls.dress(host.slots[0], PackedInt32Array([2, 3, 1, 2]))
	client.apply_snapshot(host.build_snapshot())
	assert_array(Array(puppet.style.to_array())).is_equal([2, 3, 1, 2])
	var body := puppet.get_node("Body")
	assert_object(body.get_node_or_null("Hat")).is_not_null()
	assert_object(body.get_node_or_null("Flag")).is_not_null()


func test_dressing_again_moves_the_marker_over_the_new_hat() -> void:
	var match_node := _room([KartInput.new()])
	await _runner.simulate_frames(3, 17)
	var kart := match_node.slots[0].kart
	var marker: Node3D = kart.get_node("Body/RoofMarker")
	var bare := marker.position.y
	StyleStalls.dress(match_node.slots[0], PackedInt32Array([1, 4, 0, 0]))
	assert_float(marker.position.y).is_equal_approx(bare + KartDress.HAT_LIFT[4], 0.001)
	StyleStalls.dress(match_node.slots[0], PackedInt32Array([1, 0, 0, 0]))
	assert_float(marker.position.y).is_equal_approx(bare, 0.001)
	assert_object(kart.get_node("Body").get_node_or_null("Hat")).is_null()
	assert_object(kart._tint.albedo_texture).is_not_null()
