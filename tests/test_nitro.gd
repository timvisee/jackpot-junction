extends GdUnitTestSuite
## Nitro from GAME.md 4.1: a limited tank that burns for speed and ramming kills and refills slowly.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


func _start_match(inputs: Array[KartInput]) -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, 31)
	return match_node


func test_nitro_burns_for_speed_then_empties_and_refills_after_a_pause() -> void:
	var input := KartInput.new()
	var match_node := _start_match([input, KartInput.new()])
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	kart.global_position = Vector3(-14.0, 0.0, 0.0)
	kart.face(Vector3(1.0, 0.0, 0.0))
	input.throttle = 1.0
	input.nitro = true
	await _runner.simulate_frames(30, 17)
	assert_bool(kart.nitro_active).is_true()
	assert_bool(kart._flame.active).is_true()
	# The flame drags a heavy plume behind it, well past the exhaust's own faint trail.
	assert_bool(kart._flame._smoke.emitting).is_true()
	assert_int(kart._flame._smoke.amount).is_greater(kart._smoke.amount)
	assert_float(kart.motor.max_speed()).is_equal_approx(
		kart.stats.top_speed * kart.stats.nitro_speed_multiplier, 0.01
	)
	assert_float(kart.nitro_charge).is_less(1.0)
	await _runner.simulate_frames(110, 17)
	assert_bool(kart.nitro_active).is_false()
	assert_bool(kart._flame.active).is_false()
	assert_bool(kart._flame._smoke.emitting).is_false()
	assert_float(kart.nitro_charge).is_equal(0.0)
	assert_float(kart.motor.max_speed()).is_equal_approx(kart.stats.top_speed, 0.01)
	input.nitro = false
	input.throttle = 0.0
	await _runner.simulate_frames(90, 17)
	assert_float(kart.nitro_charge).is_between(0.005, 0.03)
	input.nitro = true
	await _runner.simulate_frames(6, 17)
	assert_bool(kart.nitro_active).is_false()


func test_ramming_with_nitro_kills_the_other_kart() -> void:
	var input := KartInput.new()
	var match_node := _start_match([input, KartInput.new()])
	await _runner.simulate_frames(12, 17)
	var rammer := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	rammer.global_position = Vector3(-6.0, 0.0, 1.0)
	rammer.face(Vector3(1.0, 0.0, 0.0))
	victim.global_position = Vector3(-1.0, 0.0, 1.0)
	victim.face(Vector3(1.0, 0.0, 0.0))
	input.throttle = 1.0
	input.nitro = true
	await _runner.simulate_frames(60, 17)
	assert_bool(victim.alive).is_false()
	assert_int(match_node.slots[0].kills).is_equal(1)
	assert_float(rammer.nitro_charge).is_greater(0.55)


func test_a_kill_refills_half_a_tank_and_respawning_keeps_the_charge() -> void:
	var match_node := _start_match([KartInput.new(), KartInput.new()])
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	kart.nitro_charge = 0.2
	var gained := monitor_signals(Events, false)
	kart.refill_nitro(kart.stats.nitro_kill_refill)
	assert_float(kart.nitro_charge).is_equal_approx(0.7, 0.001)
	await assert_signal(gained).is_emitted("nitro_gained", [0])
	kart.refill_nitro(1.0)
	assert_float(kart.nitro_charge).is_equal(1.0)
	kart.nitro_charge = 0.3
	kart.respawn(Vector3.ZERO, Vector3.FORWARD, 0.0)
	assert_float(kart.nitro_charge).is_equal_approx(0.3, 0.001)
