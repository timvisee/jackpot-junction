extends GdUnitTestSuite
## The sparks off the rear wheels, GAME.md 4.3: they say whether the drift has earned its exit
## boost yet, and they flash when it is taken.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match() -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 13)
	return match_node


func test_the_sparks_turn_gold_once_the_boost_is_earned_and_flash_when_it_is_taken() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(30, 17)
	var kart := match_node.kart_of(0)
	var sparks: DriftSparks = kart.get_node("DriftSparks")
	var left: GPUParticles3D = sparks._fountains[0]
	var colour := func() -> Color: return (left.process_material as ParticleProcessMaterial).color
	assert_bool(left.emitting).is_false()
	# Up to speed, then a flick of the handbrake to break the rear loose.
	kart.motor.forward_speed = kart.stats.top_speed
	kart.motor.velocity = kart.motor.forward_vector() * kart.stats.top_speed
	kart.input.throttle = 1.0
	kart.input.steer = 1.0
	kart.input.handbrake = true
	await _runner.simulate_frames(12, 17)
	kart.input.handbrake = false
	assert_bool(kart.motor.drifting).is_true()
	assert_bool(left.emitting).is_true()
	# Still earning it: white and thin.
	assert_object(colour.call()).is_equal(DriftSparks.CHARGING)
	assert_float(left.amount_ratio).is_equal_approx(DriftSparks.RATE_CHARGING, 0.01)
	# Held past the minimum, the boost is in the bank and the sparks say so.
	await _runner.simulate_frames(60, 17)
	assert_float(kart.motor.drift_time).is_greater(kart.stats.drift_min_duration)
	assert_object(colour.call()).is_equal(DriftSparks.READY)
	assert_float(left.amount_ratio).is_equal_approx(DriftSparks.RATE_READY, 0.01)
	# Gathered up: the boost is taken and the flash goes off with it. Caught on the frame it
	# happens, since the flash is shorter than half a second and this is what it is for.
	kart.input.steer = -1.0
	var lit := 0.0
	for i: int in 30:
		await _runner.simulate_frames(1, 17)
		lit = maxf(lit, sparks._flash)
		if kart.motor.boosting():
			break
	assert_bool(kart.motor.boosting()).is_true()
	assert_float(lit).is_greater(0.0)
	sparks._process(0.0)
	assert_float(sparks._glow.light_energy).is_greater(0.0)
	# And it fades rather than hanging there.
	sparks._process(DriftSparks.FLASH_TIME + 0.1)
	assert_float(sparks._flash).is_equal(0.0)


## A kart being watched across the network sparks too: the drift and how long it has run both
## come over in the snapshot, so a watcher sees the boost earned and taken the same as the driver.
func test_a_watched_kart_sparks_from_the_snapshot() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(1)
	var sparks: DriftSparks = kart.get_node("DriftSparks")
	var left: GPUParticles3D = sparks._fountains[0]
	kart.make_puppet()
	var state := {
		"x": kart.global_position.x,
		"z": kart.global_position.z,
		"h": 0.0,
		"vx": 6.0,
		"vz": 0.0,
		"alive": true,
		"drift": true,
		"drift_time": 1.2,
		"prot": false,
		"shield": false,
		"ring": -1.0,
		"aim": false,
		"nitro": false,
		"lives": 2,
		"decoy": false,
	}
	kart.apply_puppet_state(state, 1.0 / 60.0)
	await _runner.simulate_frames(4, 17)
	assert_bool(left.emitting).is_true()
	assert_object((left.process_material as ParticleProcessMaterial).color).is_equal(
		DriftSparks.READY
	)


## A kart doing nothing throws no sparks and no light, so the effect never says anything untrue.
func test_a_kart_that_is_not_drifting_is_quiet() -> void:
	var match_node := _start_match()
	await _runner.simulate_frames(30, 17)
	var kart := match_node.kart_of(0)
	var sparks: DriftSparks = kart.get_node("DriftSparks")
	kart.input.throttle = 1.0
	await _runner.simulate_frames(30, 17)
	assert_bool(kart.motor.drifting).is_false()
	for fountain: GPUParticles3D in sparks._fountains:
		assert_bool(fountain.emitting).is_false()
	assert_float(sparks._glow.light_energy).is_equal(0.0)
