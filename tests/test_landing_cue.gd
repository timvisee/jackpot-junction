extends GdUnitTestSuite
## Where Next new lands, drawn the eye to, GAME.md 8.8, see [LandingCue].


## What lands comes up past its size with a little give and settles back to it.
func test_it_comes_up_and_settles_back() -> void:
	assert_float(LandingCue.pop_at(0.0, LandingCue.POP)).is_equal_approx(1.0, 0.001)
	var top := LandingCue.pop_at(LandingCue.GROWS * 0.999, LandingCue.POP)
	assert_float(top).is_greater(LandingCue.POP - 0.01)
	var halfway := LandingCue.GROWS + LandingCue.SETTLES * 0.5
	assert_float(LandingCue.pop_at(halfway, LandingCue.POP)).is_between(1.0, LandingCue.POP)
	var settled := LandingCue.GROWS + LandingCue.SETTLES
	assert_float(LandingCue.pop_at(settled, LandingCue.POP)).is_equal_approx(1.0, 0.001)


## It comes up over what is round it and goes once its rings are gone, the thing as it was; and the
## next landing ends the last at once.
func test_one_at_a_time_and_left_as_it_was() -> void:
	var first: Control = auto_free(Control.new())
	var second: Control = auto_free(Control.new())
	for each: Control in [first, second]:
		each.size = Vector2(100.0, 140.0)
		add_child(each)
	var cue := LandingCue.on(first)
	assert_int(first.z_index).is_equal(1)
	assert_vector(first.pivot_offset).is_equal(Vector2(50.0, 70.0))
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(first.scale.x).is_greater(1.0)
	LandingCue.on(second, LandingCue.GENTLE)
	assert_bool(cue.is_queued_for_deletion()).is_true()
	assert_vector(first.scale).is_equal(Vector2.ONE)
	assert_int(first.z_index).is_equal(0)
	assert_vector(first.pivot_offset).is_equal(Vector2.ZERO)
	var ends := Time.get_ticks_msec() + int(LandingCue.LASTS * 1000.0) + 1500
	while second.get_node_or_null("Landing") != null and Time.get_ticks_msec() < ends:
		await get_tree().process_frame
	assert_object(second.get_node_or_null("Landing")).is_null()
	assert_vector(second.scale).is_equal(Vector2.ONE)
	assert_int(second.z_index).is_equal(0)
