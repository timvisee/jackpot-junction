extends GdUnitTestSuite
## The stalls a kart is dressed at, GAME.md 4.4 and 9.6: a pad each for the paint, the hat, the
## flag and the trail, driven onto rather than picked from a menu and changed with the fire button,
## in the lobby and the garage, at this machine and across the wire.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")

var _runner: GdUnitSceneRunner
var _settings_were: Settings


## A player who presses fire, once, when the test says so.
class Pressing:
	extends PlayerInput

	var press := false

	func poll(_delta: float) -> void:
		fire = press
		fire_pressed = press
		press = false


func before_test() -> void:
	StyleStalls.learned.clear()
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


func test_the_fire_button_on_a_stall_puts_the_next_one_on_instead_of_a_shot() -> void:
	var player := Pressing.new(DeviceInput.KEYBOARD, 0)
	var match_node := _room([player])
	await _runner.simulate_frames(10, 17)
	var stalls := StyleStalls.add_to(match_node, Vector2i(8, 1))
	var slot := match_node.slots[0]
	var kart := slot.kart
	var shots := [0]
	var count := func(_slot: int) -> void: shots[0] += 1
	Events.bullet_fired.connect(count)
	_park(kart, stalls._areas[1])
	await _runner.simulate_frames(3, 17)
	# On it and waiting is nothing but the hint, which names the button.
	assert_int(slot.style.hat).is_equal(0)
	assert_object(kart.get_node_or_null("StallHint")).is_not_null()
	await _runner.simulate_frames(90, 17)
	assert_int(slot.style.hat).is_equal(0)
	player.press = true
	await _runner.simulate_frames(3, 17)
	assert_int(slot.style.hat).is_equal(1)
	assert_int(kart.style.hat).is_equal(1)
	assert_object(kart.get_node("Body").get_node_or_null("Hat")).is_not_null()
	assert_int(shots[0]).is_equal(0)
	# Kept in the seat's settings, for the next room and the next time.
	assert_int(PackedInt32Array(Game.settings.kart_styles[0])[1]).is_equal(1)
	# Once is enough to have learned it: the hint does not come back, on this pad or another.
	await _runner.simulate_frames(2, 17)
	assert_object(kart.get_node_or_null("StallHint")).is_null()
	player.press = true
	await _runner.simulate_frames(3, 17)
	assert_int(slot.style.hat).is_equal(2)
	kart.global_position = Vector3(0.0, 0.0, 5.0)
	await _runner.simulate_frames(3, 17)
	_park(kart, stalls._areas[3])
	await _runner.simulate_frames(3, 17)
	assert_int(slot.style.trail).is_equal(0)
	assert_object(kart.get_node_or_null("StallHint")).is_null()
	player.press = true
	await _runner.simulate_frames(3, 17)
	assert_int(slot.style.trail).is_equal(1)
	assert_int(slot.style.hat).is_equal(2)
	# Off the pads the button is the cannon's again.
	kart.global_position = Vector3(0.0, 0.0, 5.0)
	await _runner.simulate_frames(12, 17)
	player.press = true
	await _runner.simulate_frames(3, 17)
	assert_int(shots[0]).is_equal(1)
	Events.bullet_fired.disconnect(count)


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


## On a touch screen the fire button, and the hint that names it, show which of the four a stall
## changes rather than saying fire, GAME.md 4.4; off the stalls it fires, and says so.
func test_a_touch_screens_fire_button_shows_what_a_stall_changes() -> void:
	var was_touch := TouchInput.enabled
	TouchInput.enabled = true
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start([PlayerInput.new(DeviceInput.ANY, 0)] as Array[KartInput], 3)
	await _runner.simulate_frames(10, 17)
	var stalls := StyleStalls.add_to(match_node, Vector2i(8, 1))
	var kart := match_node.slots[0].kart
	var controls: TouchControls = match_node.hud.get_node("TouchControls")
	assert_int(controls.fire_dresses()).is_equal(-1)
	for part: int in StyleStalls.WORDS.size():
		_park(kart, stalls._areas[part])
		await _runner.simulate_frames(2, 17)
		assert_int(StyleStalls.part_under(match_node, kart)).is_equal(part)
		assert_int(controls.fire_dresses()).is_equal(part)
		var hint: Node = kart.get_node("StallHint")
		var badges := hint.find_children("*", "Control", true, false).filter(
			func(node: Node) -> bool: return node is DressArt.Badge
		)
		assert_int(badges.size()).is_equal(1)
		assert_int((badges[0] as DressArt.Badge).part).is_equal(part)
	kart.global_position = Vector3(0.0, 0.0, 5.0)
	await _runner.simulate_frames(2, 17)
	assert_int(controls.fire_dresses()).is_equal(-1)
	TouchInput.enabled = was_touch
	TouchInput.release()
