extends GdUnitTestSuite
## The moving-head lights around the arena, GAME.md 8.1: one head per excitement level, tipping
## down onto the floor as the levels climb and flashing on the beat read off the music's tempo.


func _lights() -> DiscoLights:
	var lights: DiscoLights = auto_free(DiscoLights.new())
	add_child(lights)
	lights.setup(Vector2(40.0, 22.5))
	return lights


## GAME.md 8.5: the accessibility setting puts every head out.
func test_the_setting_switches_every_head_off() -> void:
	var lights := _lights()
	lights.level = DiscoLights.COUNT
	_run(lights, 1.0)
	assert_int(lights.lit_count()).is_equal(DiscoLights.COUNT)
	var was := Game.settings.disco_lights
	Game.settings.disco_lights = false
	lights._process(0.016)
	assert_int(lights.lit_count()).is_equal(0)
	# The lamps are still part of the room; they have simply stopped lighting.
	assert_bool(lights.visible).is_true()
	assert_bool((lights._heads[0]["light"] as SpotLight3D).visible).is_true()
	assert_float((lights._heads[0]["light"] as SpotLight3D).light_energy).is_equal(0.0)
	Game.settings.disco_lights = was
	lights._process(0.016)
	assert_int(lights.lit_count()).is_equal(DiscoLights.COUNT)
	# A room that wants no rig takes the posts away with it.
	lights.enabled = false
	lights._process(0.016)
	assert_int(lights.lit_count()).is_equal(0)
	assert_bool(lights.visible).is_false()


## Runs the rig for [param seconds] of simulated time at the frame rate it would really see.
func _run(lights: DiscoLights, seconds: float) -> void:
	for i: int in int(seconds * 60.0):
		lights._process(1.0 / 60.0)


## One head per level, which is what makes the level readable from across the room.
func test_one_head_lights_up_per_excitement_level() -> void:
	var lights := _lights()
	for level: int in range(1, DiscoLights.COUNT + 1):
		lights.level = level
		_run(lights, 0.2)
		(
			assert_int(lights.lit_count())
			. override_failure_message("level %d lit the wrong number of heads" % level)
			. is_equal(level)
		)
	lights.level = 1
	_run(lights, 0.2)
	assert_int(lights.lit_count()).is_equal(1)


## A head that is not taking its turn goes dark where it stands: the lamp is part of the room,
## the beam is not.
func test_a_dark_head_keeps_its_lamp_and_loses_only_its_beam() -> void:
	var lights := _lights()
	lights.level = 1
	_run(lights, 2.0)
	assert_int(lights.lit_count()).is_equal(1)
	for i: int in DiscoLights.COUNT:
		var head: Dictionary = lights._heads[i]
		var light: SpotLight3D = head["light"]
		var beam: MeshInstance3D = head["beam"]
		var lens: StandardMaterial3D = head["lens"]
		(
			assert_bool(light.visible)
			. override_failure_message("head %d vanished instead of going dark" % i)
			. is_true()
		)
		assert_bool((head["post"] as MeshInstance3D).visible).is_true()
		if lights.is_lit(i):
			assert_float(light.light_energy).is_greater(0.0)
			assert_bool(beam.visible).is_true()
			assert_float(lens.emission_energy_multiplier).is_greater(0.0)
		else:
			assert_float(light.light_energy).is_equal(0.0)
			assert_bool(beam.visible).is_false()
			assert_float(lens.emission_energy_multiplier).is_equal(0.0)
			assert_object(lens.albedo_color).is_equal(DiscoLights.LENS_DARK)


## GAME.md 8.1: the rig stands around the table and looks up until the match gives it a reason
## to look down.
func test_the_heads_stand_at_the_edges_and_tip_down_as_the_heat_builds() -> void:
	var lights := _lights()
	for head: Dictionary in lights._heads:
		var light: SpotLight3D = head["light"]
		assert_float(light.position.y).is_equal_approx(DiscoLights.MOUNT_HEIGHT, 0.01)
		# Just outside the long edges of a 40 by 22.5 m table, never over it.
		assert_float(absf(light.position.z)).is_greater(11.2)
		assert_float(absf(light.position.x)).is_less(20.0)
		assert_object(head["post"]).is_not_null()
	# Levels 1 and 2 sweep the air above the room.
	lights.level = 1
	_run(lights, 2.0)
	var first: Dictionary = lights._heads[0]
	assert_float(lights._aim_point(first).y).is_greater(5.0)
	lights.level = 2
	_run(lights, 4.0)
	assert_float(lights._aim_point(first).y).is_greater(5.0)
	# Level 3 is on its way down, and from level 4 they rake the table itself.
	lights.level = 3
	_run(lights, 4.0)
	assert_float(lights._aim_point(first).y).is_between(1.0, 12.0)
	lights.level = 4
	_run(lights, 4.0)
	assert_float(lights._aim_point(first).y).is_equal_approx(0.0, 0.01)
	lights.level = DiscoLights.COUNT
	_run(lights, 8.0)
	assert_float(lights._aim_point(first).y).is_equal_approx(0.0, 0.01)


## The beams ease between levels rather than snapping: a step up sweeps them open.
func test_a_step_up_sweeps_the_beams_open_rather_than_snapping() -> void:
	var lights := _lights()
	lights.level = 1
	_run(lights, 2.0)
	lights.level = DiscoLights.COUNT
	_run(lights, 0.1)
	assert_float(lights._smooth).is_less(0.15)
	_run(lights, 4.0)
	assert_float(lights._smooth).is_equal_approx(1.0, 0.01)


## With heads to spare the lit run walks around the rig, and quicker when the match is hot.
func test_the_lit_heads_cycle_around_the_rig() -> void:
	var lights := _lights()
	lights.level = 1
	_run(lights, 1.0)
	var first := lights._offset
	_run(lights, DiscoLights.CYCLE_SLOW + 0.5)
	assert_int(lights._offset).is_not_equal(first)
	assert_int(lights.lit_count()).is_equal(1)
	# Two heads on, so exactly one head over from the offset is lit and the rest are dark.
	assert_bool(lights.is_lit(lights._offset)).is_true()
	assert_bool(lights.is_lit(posmod(lights._offset + 1, DiscoLights.COUNT))).is_false()
	# At the top level every head is lit, so there is nothing left to hand on.
	lights.level = DiscoLights.COUNT
	_run(lights, 5.0)
	var settled := lights._offset
	_run(lights, DiscoLights.CYCLE_SLOW + 1.0)
	assert_int(lights._offset).is_equal(settled)


func test_a_hot_match_sweeps_wider_brighter_and_faster() -> void:
	var lights := _lights()
	lights.level = 1
	_run(lights, 2.0)
	var calm_time := lights._time
	var head: SpotLight3D = lights._heads[0]["light"]
	var calm_energy := head.light_energy
	var calm_angle := head.spot_angle
	lights.level = DiscoLights.COUNT
	_run(lights, 5.0)
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


## GAME.md 8.1: a head does not keep one colour, and the light, the lens and the beam all wear
## whatever it has walked on to.
func test_a_head_walks_through_the_palette_and_dresses_itself_in_the_new_colour() -> void:
	var lights := _lights()
	lights.level = DiscoLights.COUNT
	_run(lights, 0.5)
	var head: Dictionary = lights._heads[0]
	var first: Color = head["color"]
	assert_object((head["light"] as SpotLight3D).light_color).is_equal(first)
	_run(lights, DiscoLights.COLOR_HOLD_SLOW + DiscoLights.COLOR_FADE + 1.0)
	var later: Color = head["color"]
	(
		assert_bool(later.is_equal_approx(first))
		. override_failure_message("the colour never moved")
		. is_false()
	)
	var light: SpotLight3D = head["light"]
	var lens: StandardMaterial3D = head["lens"]
	var tint: StandardMaterial3D = head["tint"]
	assert_object(light.light_color).is_equal(later)
	assert_object(lens.albedo_color).is_equal(later)
	assert_object(lens.emission).is_equal(later)
	assert_float(tint.albedo_color.r).is_equal_approx(later.r, 0.001)
	assert_float(tint.albedo_color.b).is_equal_approx(later.b, 0.001)
	# The rig does not change colour all at once: the heads are on staggered clocks.
	var lefts: Array[float] = []
	for other: Dictionary in lights._heads:
		lefts.append(other["color_left"])
	assert_float(lefts.max() - lefts.min()).is_greater(0.5)


## GAME.md 8.1: the cone opens and closes around the width its level asks for.
func test_a_cone_opens_and_closes_around_its_levels_width() -> void:
	var lights := _lights()
	lights.level = DiscoLights.COUNT
	_run(lights, 5.0)
	var head: SpotLight3D = lights._heads[0]["light"]
	var narrowest := head.spot_angle
	var widest := head.spot_angle
	for i: int in 900:
		lights._process(1.0 / 60.0)
		narrowest = minf(narrowest, head.spot_angle)
		widest = maxf(widest, head.spot_angle)
	# Around 24 degrees at the top level, opening and closing by about a third of that.
	assert_float(widest - narrowest).is_greater(6.0)
	assert_float(narrowest).is_greater(10.0)
	assert_float(widest).is_less(36.0)


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
