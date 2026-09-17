extends GdUnitTestSuite
## The virtual rev counter behind the engine sound, GAME.md 8.4, at a 60 Hz tick, and the two
## placement numbers that decide whether the levels around it mean anything at all.

const DT := 1.0 / 60.0
const SOUND: KartSoundStats = preload("res://data/kart/sound.tres")

var _stats: KartStats
var _sound: KartSoundStats
var _motor: KartMotor
var _rev: KartRev
var _input: KartInput


func before_test() -> void:
	_stats = load("res://data/kart/default.tres").duplicate()
	_sound = SOUND.duplicate()
	_motor = KartMotor.new(_stats)
	_rev = KartRev.new(_sound)
	_input = KartInput.new()


func _run(seconds: float) -> void:
	for i: int in int(round(seconds / DT)):
		_motor.step(_input, DT)
		_rev.step(_motor, _input, DT)


## Godot adds a player's volume_db to its distance attenuation and clamps the sum to max_db.
## These two are what make the dB in [KartSoundStats] the dB that come out: the ears have to be
## at the distance a voice is written for, so the attenuation there is nothing, and the ceiling
## has to sit above the loudest thing asked for, or every voice is flattened onto it and none of
## the levels do anything. Both were wrong once and nothing else noticed.
func test_a_kart_plays_at_the_distance_the_ears_are_at() -> void:
	var rig: CameraRig = auto_free(CameraRig.new())
	assert_float(SOUND.unit_size).is_equal_approx(rig.listener_height, 0.001)


func test_the_ceiling_sits_above_every_level_asked_for() -> void:
	# The engine flat out is the loudest a kart gets; the squeals and the chirp are below it.
	assert_float(SOUND.max_db).is_greater(SOUND.kart_db + SOUND.engine_db)
	for voice_db: float in [SOUND.drift_db, SOUND.slide_db, SOUND.lock_db, SOUND.chirp_db]:
		assert_float(SOUND.kart_db + voice_db).is_less(SOUND.kart_db + SOUND.engine_db)


func test_idles_when_nobody_is_driving() -> void:
	_run(1.0)
	assert_float(_rev.rev).is_equal_approx(_sound.idle_rev, 0.01)
	assert_float(_rev.pitch()).is_equal(_sound.pitch_min)


func test_throttle_revs_the_engine_before_the_kart_has_moved() -> void:
	_input.throttle = 1.0
	# A quarter of a second in, the kart has barely left the line but the engine is up.
	_run(0.25)
	assert_float(_motor.speed()).is_less(_stats.top_speed * 0.2)
	assert_float(_rev.rev).is_greater(_sound.idle_rev * 2.5)


func test_engine_keeps_revving_on_the_grid_with_the_kart_held_still() -> void:
	_input.throttle = 1.0
	for i: int in 60:
		# The motor is not stepped at all: this is a frozen kart during the countdown.
		_rev.step(_motor, _input, DT)
	assert_float(_rev.rev).is_equal_approx(_sound.launch_rev, 0.02)
	assert_float(_motor.speed()).is_equal(0.0)


func test_pulling_away_only_ever_climbs() -> void:
	# The flare used to overshoot what the road could hold and drop back before climbing again,
	# heard as a harsh wah. The clutch now hands over exactly where the road catches up, so the
	# needle rises the whole way from idle to the limiter.
	_input.throttle = 1.0
	var highest := _rev.rev
	var worst_drop := 0.0
	for i: int in int(round(3.0 / DT)):
		_motor.step(_input, DT)
		_rev.step(_motor, _input, DT)
		worst_drop = maxf(worst_drop, highest - _rev.rev)
		highest = maxf(highest, _rev.rev)
	assert_float(worst_drop).is_less(0.01)
	assert_float(_rev.rev).is_greater(0.9)


func test_the_clutch_bites_where_the_road_reaches_the_flare() -> void:
	var at_bite := _sound.idle_rev + (1.0 - _sound.idle_rev) * _rev.clutch_fraction()
	assert_float(at_bite).is_equal_approx(_sound.launch_rev, 0.001)


func test_flat_out_sits_near_the_limiter() -> void:
	_input.throttle = 1.0
	_run(4.0)
	assert_float(_motor.speed()).is_equal_approx(_stats.top_speed, 0.01)
	assert_float(_rev.rev).is_equal_approx(1.0, 0.02)


func test_nitro_carries_the_needle_past_the_limiter() -> void:
	_input.throttle = 1.0
	_run(4.0)
	var flat_out := _rev.rev
	_motor.nitro_bonus = _stats.nitro_speed_multiplier
	_run(2.0)
	assert_float(_rev.rev).is_greater(flat_out)
	assert_float(_rev.rev).is_less_equal(_sound.over_max)
	assert_float(_rev.pitch()).is_less_equal(_sound.pitch_max)


func test_lifting_off_drops_the_engine_level_without_dropping_the_revs() -> void:
	_input.throttle = 1.0
	_run(4.0)
	var loud := _rev.volume_db()
	_input.throttle = 0.0
	_run(0.5)
	assert_float(_rev.volume_db()).is_less(loud - 3.0)
	# The kart is still rolling, so the engine is still spinning with it.
	assert_float(_rev.rev).is_greater(0.5)


func test_a_drift_revs_higher_than_the_road_alone() -> void:
	_input.throttle = 1.0
	_run(4.0)
	var gripping := _rev.rev
	_input.steer = 1.0
	_input.handbrake = true
	_run(0.5)
	assert_bool(_motor.drifting).is_true()
	assert_float(_rev.rev).is_greater(gripping)


func test_spinning_out_on_oil_drops_the_engine_to_a_fast_idle() -> void:
	_input.throttle = 1.0
	_run(4.0)
	_motor.apply_spin_out(1.0)
	_run(0.5)
	assert_bool(_motor.spinning()).is_true()
	assert_float(_rev.rev).is_less(_sound.idle_rev * 2.5)


func test_reverse_has_a_short_gear_of_its_own() -> void:
	_input.brake = 1.0
	_run(2.0)
	assert_float(_motor.forward_speed).is_equal_approx(-_stats.reverse_top_speed, 0.01)
	# Backing up at full chat revs hard even though the road speed is half of top.
	assert_float(_rev.rev).is_greater(0.8)


func test_pitch_never_leaves_the_range_the_sample_stands_up_to() -> void:
	var seen_low := false
	var seen_high := false
	for step: Array in [[1.0, 0.0, 6.0], [0.0, 1.0, 4.0], [1.0, 0.0, 2.0], [0.0, 0.0, 6.0]]:
		_input.throttle = step[0]
		_input.brake = step[1]
		for i: int in int(round(float(step[2]) / DT)):
			_motor.step(_input, DT)
			_rev.step(_motor, _input, DT)
			assert_float(_rev.pitch()).is_between(_sound.pitch_min, _sound.pitch_max)
			seen_low = seen_low or _rev.pitch() < 1.0
			seen_high = seen_high or _rev.pitch() > 1.5
	assert_bool(seen_low).is_true()
	assert_bool(seen_high).is_true()
