extends GdUnitTestSuite
## The moving-head lights over the arena, GAME.md 8.1: how many are lit follows the excitement
## meter, and they flash on the beat read off the music's tempo.


func _lights() -> DiscoLights:
	var lights: DiscoLights = auto_free(DiscoLights.new())
	add_child(lights)
	lights.setup(Vector2(40.0, 22.5))
	return lights


## GAME.md 8.5: the accessibility setting puts every head out.
func test_the_setting_switches_every_head_off() -> void:
	var lights := _lights()
	lights.level = 1.0
	_run(lights, 25.0)
	assert_int(lights.lit_count()).is_equal(DiscoLights.COUNT)
	var was := Game.settings.disco_lights
	Game.settings.disco_lights = false
	lights._process(0.016)
	assert_int(lights.lit_count()).is_equal(0)
	Game.settings.disco_lights = was
	lights._process(0.016)
	assert_int(lights.lit_count()).is_equal(DiscoLights.COUNT)


## Runs the rig for [param seconds] of simulated time at the frame rate it would really see.
func _run(lights: DiscoLights, seconds: float) -> void:
	for i: int in int(seconds * 60.0):
		lights._process(1.0 / 60.0)


func test_more_heads_switch_on_as_the_meter_climbs() -> void:
	var lights := _lights()
	lights.level = 0.0
	_run(lights, 1.0)
	assert_int(lights.lit_count()).is_equal(1)
	lights.level = 0.5
	_run(lights, 10.0)
	assert_int(lights.lit_count()).is_between(3, 4)
	lights.level = 1.0
	_run(lights, 20.0)
	assert_int(lights.lit_count()).is_equal(DiscoLights.COUNT)
	lights.level = 0.0
	_run(lights, 40.0)
	assert_int(lights.lit_count()).is_equal(1)


## The point of the slow follower, the dead band and the hold: a moment of excitement must not
## flick a head on and straight back off.
func test_a_brief_spike_does_not_flicker_a_head() -> void:
	var lights := _lights()
	lights.level = 0.0
	_run(lights, 2.0)
	assert_int(lights.lit_count()).is_equal(1)
	# Half a second of chaos, then quiet again.
	lights.level = 1.0
	_run(lights, 0.5)
	lights.level = 0.0
	_run(lights, 0.5)
	assert_int(lights.lit_count()).is_equal(1)
	# A spell of real heat does bring one on, and it then stays on for a while.
	lights.level = 0.6
	_run(lights, 3.0)
	assert_int(lights.lit_count()).is_greater(1)
	var lit := lights.lit_count()
	lights.level = 0.0
	_run(lights, 1.0)
	assert_int(lights.lit_count()).is_equal(lit)


## With heads to spare the lit run walks around the rig, and quicker when the match is hot.
func test_the_lit_heads_cycle_around_the_rig() -> void:
	var lights := _lights()
	lights.level = 0.0
	_run(lights, 1.0)
	var first := lights._offset
	_run(lights, DiscoLights.CYCLE_SLOW + 0.5)
	assert_int(lights._offset).is_not_equal(first)
	assert_int(lights.lit_count()).is_equal(1)
	# Two heads on, so exactly one head over from the offset is lit and the rest are dark.
	assert_bool(lights.is_lit(lights._offset)).is_true()
	assert_bool(lights.is_lit(posmod(lights._offset + 1, DiscoLights.COUNT))).is_false()
	# At full heat every head is lit, so there is nothing left to hand on.
	lights.level = 1.0
	_run(lights, 25.0)
	var settled := lights._offset
	_run(lights, DiscoLights.CYCLE_SLOW + 1.0)
	assert_int(lights._offset).is_equal(settled)


func test_a_hot_match_sweeps_wider_brighter_and_faster() -> void:
	var lights := _lights()
	lights.level = 0.0
	_run(lights, 2.0)
	var calm_time := lights._time
	var head: SpotLight3D = lights._heads[0]["light"]
	var calm_energy := head.light_energy
	var calm_angle := head.spot_angle
	lights.level = 1.0
	_run(lights, 20.0)
	var hot_time := lights._time
	_run(lights, 2.0)
	assert_float(lights._time - hot_time).is_greater(calm_time * 0.9)
	assert_float(head.light_energy).is_greater(calm_energy * 1.5)
	assert_float(head.spot_angle).is_greater(calm_angle)
	# Bright, but well short of washing the table out: six of these are on at once.
	var peak := 0.0
	for i: int in 240:
		lights._process(1.0 / 60.0)
		peak = maxf(peak, head.light_energy)
	assert_float(peak).is_less(5.0)
	assert_float((lights._heads[0]["tint"] as StandardMaterial3D).albedo_color.a).is_less(0.2)


func test_the_beat_comes_off_the_tempo_and_wraps_through_the_bar() -> void:
	var beat := Audio.music_beat()
	assert_float(beat).is_between(0.0, 1.0)
	assert_int(Audio.music_beat_index()).is_between(0, Audio.BEATS_PER_BAR - 1)
	# A beat is half a second at 120 BPM, so the phase moves on as the clock runs.
	var moved := false
	for i: int in 12:
		await await_millis(60)
		moved = moved or absf(Audio.music_beat() - beat) > 0.05
	assert_bool(moved).override_failure_message("the beat never advanced").is_true()
