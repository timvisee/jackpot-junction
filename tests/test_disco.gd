extends GdUnitTestSuite
## The moving-head lights over the arena, GAME.md 8.1: how many are lit follows the excitement
## meter, and they flash on the beat read off the music's tempo.


func _lights() -> DiscoLights:
	var lights: DiscoLights = auto_free(DiscoLights.new())
	add_child(lights)
	lights.setup(Vector2(40.0, 22.5))
	return lights


func test_more_heads_switch_on_as_the_meter_climbs() -> void:
	var lights := _lights()
	lights.level = 0.0
	lights._process(0.016)
	assert_int(lights.lit_count()).is_equal(1)
	lights.level = 0.5
	lights._process(0.016)
	assert_int(lights.lit_count()).is_between(3, 4)
	lights.level = 1.0
	lights._process(0.016)
	assert_int(lights.lit_count()).is_equal(DiscoLights.COUNT)


func test_a_hot_match_sweeps_wider_brighter_and_faster() -> void:
	var lights := _lights()
	lights.level = 0.0
	for i: int in 10:
		lights._process(0.05)
	var calm_time := lights._time
	var head: SpotLight3D = lights._heads[0]["light"]
	var calm_energy := head.light_energy
	var calm_angle := head.spot_angle
	lights.level = 1.0
	for i: int in 10:
		lights._process(0.05)
	assert_float(lights._time - calm_time).is_greater(calm_time)
	assert_float(head.light_energy).is_greater(calm_energy * 2.0)
	assert_float(head.spot_angle).is_greater(calm_angle)


func test_the_beat_comes_off_the_tempo_and_wraps_through_the_bar() -> void:
	var beat := Audio.music_beat()
	assert_float(beat).is_between(0.0, 1.0)
	assert_int(Audio.music_beat_index()).is_between(0, Audio.BEATS_PER_BAR - 1)
	# A beat is half a second at 120 BPM, so the phase has moved on after a short wait.
	await await_millis(120)
	assert_float(absf(Audio.music_beat() - beat)).is_greater(0.05)
