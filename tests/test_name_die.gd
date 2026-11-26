extends GdUnitTestSuite
## The name die, GAME.md 4.4a: the kart dialog's, the name dialog's and the one at the end of the
## match settings' cards, 9.6, see [NameDie].


## The die thrown is heard landing, GAME.md 4.4a: one die on a table, from tools/make_die_sound,
## in three takes that run on past where the die drawn last comes down; thrown, a take plays.
func test_the_die_is_heard_landing() -> void:
	var files: Array = Audio.LIBRARY[NameDie.SOUND]
	assert_int(files.size()).is_equal(3)
	var last := NameDie.HOPS[-1].y * NameDie.TUMBLE
	for file: String in files:
		var stream := load(Audio.SFX_DIR + file) as AudioStream
		assert_object(stream).override_failure_message(file).is_not_null()
		assert_float(stream.get_length()).is_greater(last)
	var die: NameDie = auto_free(NameDie.new())
	add_child(die)
	die.throw()
	var heard := false
	for player: AudioStreamPlayer in Audio._pool:
		var stream := player.stream
		if player.playing and stream != null and stream.resource_path.contains("die_throw"):
			heard = true
	assert_bool(heard).is_true()
