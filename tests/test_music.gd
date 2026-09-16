extends GdUnitTestSuite
## The layered music: calm by default, tense after a kill for a while, the full mix from Last
## Call to the results, and the same position kept across switches.


func before_test() -> void:
	Audio._last_call = false
	Audio.set_intensity(0.0)
	Audio.set_layer(Audio.LAYER_CALM)


func after_test() -> void:
	Audio._last_call = false
	Audio.set_intensity(0.0)
	Audio.set_layer(Audio.LAYER_CALM)


func test_all_three_layers_exist_loop_and_share_the_88_second_length() -> void:
	for layer: StringName in Audio.LAYER_FILES:
		var stream: AudioStream = Audio._music_stream(layer)
		assert_object(stream).override_failure_message("missing layer %s" % layer).is_not_null()
		assert_float(stream.get_length()).is_equal_approx(88.0, 0.02)
		assert_bool((stream as AudioStreamOggVorbis).loop).is_true()


func test_a_crossfade_keeps_the_summed_level_constant() -> void:
	Audio.set_layer(Audio.LAYER_TENSE)
	var players: Array[AudioStreamPlayer] = Audio._music_players
	var total := players[0].volume_linear + players[1].volume_linear
	assert_float(total).is_equal_approx(1.0, 0.05)
	await await_millis(400)
	var active := players[Audio._active_player]
	var other := players[1 - Audio._active_player]
	if other.playing:
		assert_float(active.volume_linear).is_between(0.2, 0.8)
		assert_float(active.volume_linear + other.volume_linear).is_equal_approx(1.0, 0.05)
	else:
		assert_float(active.volume_linear).is_equal_approx(1.0, 0.001)
	assert_str(Audio.music_debug()).contains("music tense")


## The layer follows the excitement meter, with a gap between the two marks so a value sitting on
## the line does not flap between layers.
func test_the_music_steps_up_with_the_intensity_and_holds_until_it_drops_well_back() -> void:
	Audio.set_intensity(0.45)
	assert_str(Audio.current_layer).is_equal("calm")
	Audio.set_intensity(0.55)
	assert_str(Audio.current_layer).is_equal("tense")
	Audio.set_intensity(0.4)
	assert_str(Audio.current_layer).is_equal("tense")
	Audio.set_intensity(0.25)
	assert_str(Audio.current_layer).is_equal("calm")


func test_last_call_brings_the_full_mix_until_the_results() -> void:
	Audio._on_state_changed(Match.State.LAST_CALL)
	assert_str(Audio.current_layer).is_equal("peak")
	Audio.set_intensity(1.0)
	assert_str(Audio.current_layer).is_equal("peak")
	Audio.set_intensity(0.0)
	assert_str(Audio.current_layer).is_equal("peak")
	Audio.mark_all_players_down()
	assert_str(Audio.current_layer).is_equal("peak")
	Audio._on_state_changed(Match.State.RESULTS)
	assert_str(Audio.current_layer).is_equal("calm")


func test_everyone_down_calms_the_music_at_once() -> void:
	Audio.set_intensity(0.9)
	assert_str(Audio.current_layer).is_equal("tense")
	Audio.mark_all_players_down()
	assert_str(Audio.current_layer).is_equal("calm")


func test_the_mute_toggle_flips_the_music_bus_and_the_setting() -> void:
	var muted_before := Game.settings.music_muted
	Audio.toggle_music_mute()
	assert_bool(Game.settings.music_muted).is_not_equal(muted_before)
	assert_bool(Audio.is_music_muted()).is_equal(Game.settings.music_muted)
	Audio.toggle_music_mute()
	assert_bool(Game.settings.music_muted).is_equal(muted_before)
	assert_bool(Audio.is_music_muted()).is_equal(muted_before)
