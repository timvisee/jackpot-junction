extends GdUnitTestSuite
## The sound component reaches the kart it is attached to: a local player's kart gets one, a bot's
## does not, and the engine follows the driving, GAME.md 8.4.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")
const SOUND: KartSoundStats = preload("res://data/kart/sound.tres")

var _runner: GdUnitSceneRunner


func _start_match(inputs: Array[KartInput]) -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, 31)
	return match_node


func test_every_kart_has_a_voice_and_only_the_driven_one_has_all_of_it() -> void:
	var match_node := _start_match([PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()])
	await _runner.simulate_frames(12, 17)
	var mine := match_node.kart_of(0).sound
	var theirs := match_node.kart_of(1).sound
	assert_object(mine).is_not_null()
	assert_object(theirs).is_not_null()
	assert_bool(mine.lean).is_false()
	assert_bool(theirs.lean).is_true()
	# The lean one is an engine and one squeal; the full one has the other two and the chirp.
	assert_object(mine.get_node_or_null("Lock")).is_not_null()
	assert_object(mine.get_node_or_null("Chirp")).is_not_null()
	assert_object(theirs.get_node_or_null("Lock")).is_null()
	assert_object(theirs.get_node_or_null("Chirp")).is_null()


func test_karts_nobody_here_drives_are_quieter_and_not_all_the_same_engine() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD)]
	for i: int in 3:
		inputs.append(BotInput.new())
	var match_node := _start_match(inputs)
	await _runner.simulate_frames(12, 17)
	# The player nodes only take a level headless, so this reads what would be written to them.
	assert_float(match_node.kart_of(0).sound._trim).is_equal(0.0)
	assert_float(match_node.kart_of(0).sound._detune).is_equal(1.0)
	# A kart alongside is meant to be as present as your own, so the trim is not what keeps it
	# in its place; the distance is. What has to hold is that a kart at the range another one is
	# usually at cannot drown out the engine you are driving.
	var carried := 20.0 * log(SOUND.unit_size / 10.0) / log(10.0)
	assert_float(SOUND.bot_db + carried).is_less(-6.0)
	var detunes: Array[float] = []
	for i: int in 3:
		var bot := match_node.kart_of(i + 1)
		detunes.append(bot.sound._detune)
		assert_float(bot.sound._trim).is_equal(SOUND.bot_db)
	# Three engines rather than three copies of one, none of them far off their own pitch.
	assert_float(absf(detunes[0] - detunes[1])).is_greater(0.01)
	assert_float(absf(detunes[1] - detunes[2])).is_greater(0.01)
	assert_float(absf(detunes[0] - detunes[2])).is_greater(0.01)
	for detune: float in detunes:
		assert_float(absf(detune - 1.0)).is_less(0.2)


func test_a_kart_driven_from_somewhere_else_still_revs_with_its_speed() -> void:
	# A puppet's controls never come over the wire, so the engine has to be read off where the
	# kart ended up, or every other player in an online match idles around the room.
	var match_node := _start_match([PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()])
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(1)
	kart.make_puppet()
	kart.enable_sound(true, true)
	await _runner.simulate_frames(2, 17)
	var sound := kart.sound
	var idling := sound.rev.rev
	# Pulling away: the snapshots say it is moving, and nothing says why.
	for i: int in 40:
		kart.motor.velocity = Vector3(mini(i, 30) * 0.35, 0.0, 0.0)
		kart.motor.forward_speed = kart.motor.velocity.length()
		sound.step(1.0 / 60.0)
	assert_float(sound.rev.rev).is_greater(idling + 0.3)
	assert_float(sound.rev.load).is_greater(0.5)
	# Stopped again, and it settles.
	for i: int in 120:
		kart.motor.velocity = Vector3.ZERO
		kart.motor.forward_speed = 0.0
		sound.step(1.0 / 60.0)
	assert_float(sound.rev.rev).is_less(idling + 0.1)
	assert_float(sound.rev.load).is_less(0.2)


func test_earning_a_drift_boost_pings_for_you_and_not_for_the_bots() -> void:
	var match_node := _start_match([PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()])
	await _runner.simulate_frames(20, 17)
	var pings: Array[int] = [0]
	Events.drift_boosted.connect(func(_slot: int) -> void: pings[0] += 1)
	var mine := match_node.kart_of(0)
	var theirs := match_node.kart_of(1)
	assert_bool(mine.driven_here).is_true()
	assert_bool(theirs.driven_here).is_false()
	# Both karts end a drift that earned its boost on the same tick.
	for kart: Kart in [mine, theirs]:
		kart._was_drifting = true
		kart._was_charged = true
		kart.motor.drifting = false
		kart._step_drift_sparks()
	assert_int(pings[0]).is_equal(1)


func test_a_human_leaving_hands_the_kart_the_lean_voice() -> void:
	var match_node := _start_match([PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()])
	await _runner.simulate_frames(12, 17)
	assert_bool(match_node.kart_of(0).sound.lean).is_false()
	match_node.leave_human(match_node.slots[0])
	await _runner.simulate_frames(4, 17)
	assert_bool(match_node.kart_of(0).sound.lean).is_true()


func test_the_ears_follow_the_player_rather_than_the_camera() -> void:
	var match_node := _start_match([PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()])
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	kart.global_position = Vector3(12.0, 0.0, -6.0)
	await _runner.simulate_frames(4, 17)
	var ears := match_node.camera_rig.listener.global_position
	assert_float(ears.x).is_equal_approx(kart.global_position.x, 0.5)
	assert_float(ears.z).is_equal_approx(kart.global_position.z, 0.5)
	# Far from the camera, which frames the whole room from well outside it.
	assert_float(ears.distance_to(match_node.camera_rig.camera.global_position)).is_greater(10.0)


func test_the_engine_revs_with_the_throttle_and_settles_when_it_is_let_go() -> void:
	# A bare input so the test holds the pedals itself, with the voices attached by hand: a
	# PlayerInput would overwrite them from the input map on every poll.
	var input := KartInput.new()
	var match_node := _start_match([input, BotInput.new()])
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	kart.enable_sound(true)
	await _runner.simulate_frames(2, 17)
	var sound := kart.sound
	var idling := sound.rev.rev
	input.throttle = 1.0
	await _runner.simulate_frames(40, 17)
	var pulling := sound.rev.rev
	var loud := sound.rev.volume_db()
	assert_float(pulling).is_greater(idling + 0.3)
	assert_float(sound.rev.load).is_greater(0.8)
	input.throttle = 0.0
	input.brake = 1.0
	await _runner.simulate_frames(20, 17)
	# Off the pedal the engine backs right off, even though the kart is still carrying speed.
	assert_float(sound.rev.load).is_less(0.2)
	assert_float(sound.rev.volume_db()).is_less(loud - 3.0)


func test_driving_into_a_wall_crashes_once_rather_than_every_tick() -> void:
	var input := KartInput.new()
	var match_node := _start_match([input, BotInput.new()])
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	# An array, because a lambda captures a plain local by value and would count into its own copy.
	var crashes: Array[int] = [0]
	Events.kart_crashed.connect(func(_slot: int, _force: float) -> void: crashes[0] += 1)
	var wall := match_node.arena.bounds()
	kart.global_position = Vector3(wall.position.x + wall.size.x - 9.0, 0.0, 0.0)
	kart.face(Vector3.RIGHT)
	input.throttle = 1.0
	# Long enough to get up to speed and bury the nose in it.
	await _runner.simulate_frames(120, 17)
	var on_impact: int = crashes[0]
	assert_int(on_impact).is_greater(0)
	# Still pinned against it at full throttle: it must not keep crashing.
	await _runner.simulate_frames(60, 17)
	assert_int(crashes[0]).is_equal(on_impact)


func test_a_light_clip_of_a_wall_reports_less_force_than_a_square_hit() -> void:
	var input := KartInput.new()
	var match_node := _start_match([input, BotInput.new()])
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	var stats := kart.stats
	var lightest := KartCollisions.CRASH_SPEED
	assert_float(KartCollisions.force(stats, lightest)).is_equal_approx(0.0, 0.001)
	assert_float(KartCollisions.force(stats, stats.top_speed)).is_equal_approx(1.0, 0.001)
	assert_float(KartCollisions.force(stats, stats.top_speed * 2.0)).is_equal(1.0)
	# A clip at walking pace has to be far quieter than a shunt, not a step below it.
	assert_float(KartCollisions.force(stats, 3.5)).is_less(0.2)


func test_bouncing_down_a_wall_is_not_a_string_of_bangs() -> void:
	var input := KartInput.new()
	var match_node := _start_match([input, BotInput.new()])
	await _runner.simulate_frames(20, 17)
	var kart := match_node.kart_of(0)
	var crashes: Array[int] = [0]
	Events.kart_crashed.connect(func(_slot: int, _force: float) -> void: crashes[0] += 1)
	var wall := match_node.arena.bounds()
	kart.global_position = Vector3(wall.position.x + wall.size.x - 9.0, 0.0, 0.0)
	kart.face(Vector3.RIGHT)
	input.throttle = 1.0
	input.steer = 0.35
	# Two seconds of running along the wall, breaking contact and touching it again.
	await _runner.simulate_frames(120, 17)
	assert_int(crashes[0]).is_less_equal(int(ceil(2.0 / KartCollisions.CRASH_INTERVAL)) + 1)


func test_a_dead_kart_goes_quiet_and_comes_back_on_respawn() -> void:
	var match_node := _start_match([PlayerInput.new(DeviceInput.KEYBOARD), BotInput.new()])
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	assert_float(kart.sound._alive_fade).is_equal_approx(1.0, 0.01)
	kart.die(&"test", -1)
	await _runner.simulate_frames(40, 17)
	assert_float(kart.sound._alive_fade).is_equal(0.0)
	kart.respawn(Vector3.ZERO, Vector3.FORWARD, 0.0)
	await _runner.simulate_frames(40, 17)
	assert_float(kart.sound._alive_fade).is_equal_approx(1.0, 0.01)
