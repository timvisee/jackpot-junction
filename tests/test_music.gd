extends GdUnitTestSuite
## The layered music: calm by default, tense after a kill for a while, the full mix from Last
## Call to the results, and the same position kept across switches.


func before_test() -> void:
	Audio.tense_seconds = 0.2
	Audio.set_layer(Audio.LAYER_CALM)
	Audio._last_call = false
	Audio._tense_left = 0.0


func after_test() -> void:
	Audio.tense_seconds = 12.0
	Audio._last_call = false
	Audio.set_layer(Audio.LAYER_CALM)


func test_all_three_layers_exist_and_share_a_length() -> void:
	var lengths: Array[float] = []
	for layer: StringName in Audio.LAYER_FILES:
		var stream: AudioStream = Audio._music_stream(layer)
		assert_object(stream).override_failure_message("missing layer %s" % layer).is_not_null()
		lengths.append(stream.get_length())
	assert_float(lengths[0]).is_equal_approx(lengths[1], 0.05)
	assert_float(lengths[0]).is_equal_approx(lengths[2], 0.05)


func test_a_kill_makes_the_music_tense_then_it_calms_down() -> void:
	Audio.mark_excitement()
	assert_str(Audio.current_layer).is_equal("tense")
	await await_millis(450)
	assert_str(Audio.current_layer).is_equal("calm")


func test_last_call_brings_the_full_mix_until_the_results() -> void:
	Audio._on_state_changed(Match.State.LAST_CALL)
	assert_str(Audio.current_layer).is_equal("peak")
	Audio.mark_excitement()
	assert_str(Audio.current_layer).is_equal("peak")
	Audio.mark_all_players_down()
	assert_str(Audio.current_layer).is_equal("peak")
	Audio._on_state_changed(Match.State.RESULTS)
	assert_str(Audio.current_layer).is_equal("calm")


func test_everyone_down_calms_the_music_at_once() -> void:
	Audio.mark_excitement()
	Audio.mark_all_players_down()
	assert_str(Audio.current_layer).is_equal("calm")
