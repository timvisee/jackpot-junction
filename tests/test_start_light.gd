extends GdUnitTestSuite
## The start gantry from GAME.md 8.3: the countdown is a rack of lamps, not a number.


func test_the_lamps_fill_up_across_the_countdown_and_turn_green_on_the_drop() -> void:
	var light: StartLight = auto_free(StartLight.new())
	# One lamp the moment the field is held, so the rack says something from the first frame.
	light.set_countdown(3.0, 3.0)
	assert_int(light.lit).is_equal(1)
	assert_bool(light.go).is_false()
	# Filling up, and never past the rack.
	light.set_countdown(1.5, 3.0)
	assert_int(light.lit).is_equal(3)
	light.set_countdown(0.0, 3.0)
	assert_int(light.lit).is_equal(StartLight.LAMPS)
	assert_bool(light.go).is_false()
	# The drop: the whole row goes green at once.
	light.set_go()
	assert_int(light.lit).is_equal(StartLight.LAMPS)
	assert_bool(light.go).is_true()


## A countdown of no length at all still reads, rather than dividing by it.
func test_an_instant_countdown_lights_the_whole_rack() -> void:
	var light: StartLight = auto_free(StartLight.new())
	light.set_countdown(0.0, 0.0)
	assert_int(light.lit).is_equal(StartLight.LAMPS)
