extends GdUnitTestSuite
## The kart dialog shuffle's roll heard, GAME.md 4.4a, see [PartHook]: its push button pushed, a
## tick for each face of its die going by and a clack where it lands.


## Three takes from tools/make_die_sound, each running on past where the reel has settled; rolled,
## one plays, and rolled again as it spins, the first is cut short, so one is heard at a time.
func test_the_shuffle_is_heard_rolling() -> void:
	var files: Array = Audio.LIBRARY[PartHook.SOUND]
	assert_int(files.size()).is_equal(3)
	for file: String in files:
		var stream := load(Audio.SFX_DIR + file) as AudioStream
		assert_object(stream).override_failure_message(file).is_not_null()
		assert_float(stream.get_length()).is_greater(PartHook.ROLL)
	var hook: PartHook = auto_free(PartHook.make(BoardArt.SHUFFLE))
	add_child(hook)
	hook.roll()
	assert_int(_rolling()).is_equal(1)
	hook.roll()
	assert_int(_rolling()).is_equal(1)
	Audio.cut_sfx(PartHook.SOUND)
	assert_int(_rolling()).is_equal(0)


## How many of the shuffle's rolls are playing.
func _rolling() -> int:
	var count := 0
	for player: AudioStreamPlayer in Audio._pool:
		var stream := player.stream
		if player.playing and stream != null and stream.resource_path.contains("shuffle_roll"):
			count += 1
	return count
