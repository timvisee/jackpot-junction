extends GdUnitTestSuite
## The layered music: three tracks, one picked at random per match, each in three intensities.
## Calm by default, tense after a kill for a while, the full mix from Last Call to the results,
## and the same position kept across switches.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")


func before_test() -> void:
	Audio.set_track(0)
	Audio.set_excitement(1, 0.0)
	Audio.set_layer(Audio.LAYER_CALM)


func after_test() -> void:
	Audio.set_track(0)
	Audio.set_excitement(1, 0.0)
	Audio.set_layer(Audio.LAYER_CALM)


## Every track has all three intensities, they loop, and each is a whole number of bars long at
## the tempo it was measured at, which is what makes the loop seamless and the beat readable.
func test_every_track_loops_as_three_layers_of_a_whole_number_of_bars() -> void:
	assert_int(Audio.TRACKS.size()).is_equal(3)
	for i: int in Audio.TRACKS.size():
		Audio.set_track(i)
		var folder: String = Audio.MUSIC_DIR + String(Audio.TRACKS[i]["id"]) + "/"
		assert_bool(FileAccess.file_exists(folder + "LICENSE.txt")).is_true()
		var length := 0.0
		for layer: StringName in Audio.LAYER_FILES:
			var stream: AudioStream = Audio._music_stream(layer)
			assert_object(stream).override_failure_message("missing layer %s" % layer).is_not_null()
			assert_str(stream.resource_path).contains(folder)
			assert_bool((stream as AudioStreamOggVorbis).loop).is_true()
			if length == 0.0:
				length = stream.get_length()
			# The three are the same music, so they run for the same time to the sample.
			assert_float(stream.get_length()).is_equal_approx(length, 0.02)
		var beats := length * Audio.bpm() / 60.0
		(
			assert_float(beats)
			. override_failure_message("%s is %f beats long" % [Audio.TRACKS[i]["id"], beats])
			. is_equal_approx(roundf(beats), 0.02)
		)
		assert_int(roundi(beats) % Audio.BEATS_PER_BAR).is_equal(0)


## The tempo is the track's own: they were written at three different ones, so a single number
## would have everything that moves on the beat out of step for two of them.
func test_the_beat_is_read_at_the_tempo_of_whatever_is_playing() -> void:
	var tempos: Array[float] = []
	for i: int in Audio.TRACKS.size():
		Audio.set_track(i)
		assert_float(Audio.bpm()).is_equal(Audio.TRACKS[i]["bpm"])
		tempos.append(Audio.bpm())
	assert_bool(tempos[0] != tempos[1] and tempos[1] != tempos[2]).is_true()


## GAME.md 8.4: a record goes on as the room is built, so a run of matches is not one loop over
## and over.
func test_building_a_match_puts_a_record_on() -> void:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	var seen: Dictionary[int, bool] = {}
	for i: int in 30:
		var match_node: Match = auto_free(MATCH_SCENE.instantiate())
		match_node.rules = rules
		match_node.with_hud = false
		add_child(match_node)
		match_node.start([KartInput.new()] as Array[KartInput], i)
		seen[Audio.track] = true
		remove_child(match_node)
	# Thirty rooms built and more than one record played: it is a roll, not a fixed order.
	assert_int(seen.size()).is_greater(1)


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
	assert_str(Audio.music_debug()).contains("music tense L")


## GAME.md 8.4: the mix is chosen by the excitement level, calm up to 3, tense from 4 and the
## full track at 6. The levels hold themselves, so the layer follows them straight away.
func test_the_music_steps_up_with_the_excitement_level() -> void:
	for level: int in [1, 2, 3]:
		Audio.set_excitement(level, 0.0)
		assert_str(Audio.current_layer).is_equal("calm")
	for level: int in [4, 5]:
		Audio.set_excitement(level, 0.6)
		assert_str(Audio.current_layer).is_equal("tense")
	Audio.set_excitement(6, 1.0)
	assert_str(Audio.current_layer).is_equal("peak")
	Audio.set_excitement(5, 0.8)
	assert_str(Audio.current_layer).is_equal("tense")
	Audio.set_excitement(2, 0.2)
	assert_str(Audio.current_layer).is_equal("calm")


## GAME.md 8.4: Last Call does not switch the mix by itself any more. The excitement climb
## walks the room up to level 6 and the full track comes in with it, and the results take it
## back to calm.
func test_the_full_mix_comes_in_with_the_top_level_and_the_results_end_it() -> void:
	Audio._on_state_changed(Match.State.LAST_CALL)
	assert_str(Audio.current_layer).is_equal("calm")
	for level: int in [2, 3]:
		Audio.set_excitement(level, 0.2 * float(level))
		assert_str(Audio.current_layer).is_equal("calm")
	Audio.set_excitement(4, 0.6)
	assert_str(Audio.current_layer).is_equal("tense")
	Audio.set_excitement(6, 1.0)
	assert_str(Audio.current_layer).is_equal("peak")
	Audio._on_state_changed(Match.State.RESULTS)
	assert_str(Audio.current_layer).is_equal("calm")


func test_everyone_down_calms_the_music_at_once() -> void:
	Audio.set_excitement(4, 0.6)
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


## GAME.md 8.4: the music bus opens up as the levels climb and closes again as they drop back.
func test_the_music_bus_sweeps_open_with_the_excitement() -> void:
	assert_object(Audio._filter).is_not_null()
	assert_object(Audio._amplify).is_not_null()
	Audio._open = 0.0
	Audio._step_music_effects(0.0)
	# Level 1: muffled, and well under the room rather than leading it.
	assert_float(Audio._filter.cutoff_hz).is_equal_approx(Audio.FILTER_CLOSED_HZ, 1.0)
	assert_float(Audio._amplify.volume_db).is_equal_approx(Audio.COLD_GAIN_DB, 0.01)
	assert_float(Audio.COLD_GAIN_DB).is_less(Audio.HOT_GAIN_DB - 5.0)
	Audio.set_excitement(6, 1.0)
	for i: int in 40:
		Audio._step_music_effects(0.05)
	assert_float(Audio._open).is_equal_approx(1.0, 0.01)
	assert_float(Audio._filter.cutoff_hz).is_equal_approx(Audio.FILTER_OPEN_HZ, 20.0)
	assert_float(Audio._amplify.volume_db).is_equal_approx(Audio.HOT_GAIN_DB, 0.01)
	assert_str(Audio.music_debug()).contains("open 100%")
	Audio.set_excitement(1, 0.0)
	for i: int in 40:
		Audio._step_music_effects(0.05)
	assert_float(Audio._filter.cutoff_hz).is_equal_approx(Audio.FILTER_CLOSED_HZ, 1.0)
