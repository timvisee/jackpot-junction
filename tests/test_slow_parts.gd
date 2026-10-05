extends GdUnitTestSuite
## The parts of a snapshot that hardly ever change, GAME.md 10.3: a player's name, way of driving
## and statistics and a kart's dress and plate go at a slow beat of their own, in the few
## snapshots after one of them changes, all of them to somebody just arrived, and all of them
## while nothing is being played.


## The first snapshot carries everything, and after that each player's slow parts come round on a
## beat of their own, once every [constant SlowParts.EVERY], no two players on the same one.
func test_each_player_has_a_slow_beat_of_their_own() -> void:
	var slow := SlowParts.new()
	slow.next(true)
	for beat: int in 8:
		assert_bool(slow.due(beat)).is_true()
	var beats: Dictionary[int, int] = {}
	for snapshot: int in SlowParts.EVERY:
		slow.next(true)
		var due_now := 0
		for beat: int in 8:
			if slow.due(beat):
				beats[beat] = int(beats.get(beat, 0)) + 1
				due_now += 1
		assert_int(due_now).is_less_equal(1)
	for beat: int in 8:
		assert_int(beats.get(beat, 0)).is_equal(1)


## A change goes in the next few snapshots, enough that one lost packet changes nothing, and then
## waits for its beat again.
func test_a_change_is_sent_a_few_times_and_then_at_the_beat() -> void:
	var slow := SlowParts.new()
	slow.next(true)
	assert_bool(slow.wants("kart1.style", PackedInt32Array([0, 0, 0, 0]), 3)).is_true()
	var sent := 0
	for snapshot: int in SlowParts.EVERY:
		slow.next(true)
		if slow.wants("kart1.style", PackedInt32Array([0, 0, 0, 0]), 3):
			sent += 1
	# The rest of its repeats, and its beat.
	assert_int(sent).is_equal(SlowParts.REPEATS - 1 + 1)
	slow.next(true)
	var repeats := 0
	while slow.wants("kart1.style", PackedInt32Array([1, 0, 0, 0]), 3) and repeats < 20:
		repeats += 1
		slow.next(true)
	assert_int(repeats).is_equal(SlowParts.REPEATS)


## Somebody who has just arrived is sent all of it in the next snapshot, and so is everybody while
## the match is not being played, so the podium is drawn from everybody's last statistics.
func test_a_newcomer_and_a_podium_get_all_of_it() -> void:
	var slow := SlowParts.new()
	for snapshot: int in 3:
		slow.next(true)
	var off_beat := -1
	for beat: int in 8:
		if not slow.due(beat):
			off_beat = beat
	assert_int(off_beat).is_not_equal(-1)
	slow.start_again()
	slow.next(true)
	assert_bool(slow.due(off_beat)).is_true()
	slow.next(true)
	slow.next(false)
	for beat: int in 8:
		assert_bool(slow.due(beat)).is_true()


## A host's snapshot built over a wire leaves the slow parts out between beats, and one built on
## its own has all of it, for anything asking for a snapshot by itself.
func test_a_snapshot_leaves_the_slow_parts_out_between_beats() -> void:
	var match_node: Match = auto_free(load("res://scenes/match/match.tscn").instantiate())
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	match_node.rules = rules
	match_node.with_hud = false
	var runner := scene_runner(match_node)
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	match_node.start(inputs, 5)
	await runner.simulate_frames(20, 17)
	assert_bool(match_node.is_running()).is_true()
	var whole := match_node.build_snapshot()
	assert_bool((whole["slots"][0] as Dictionary).has("stats")).is_true()
	assert_bool((whole["karts"][0] as Dictionary).has("style")).is_true()
	var wire := PickupWire.new()
	var first := match_node.build_snapshot(wire)
	assert_bool((first["slots"][1] as Dictionary).has("name")).is_true()
	var without := 0
	for snapshot: int in SlowParts.EVERY:
		var next := match_node.build_snapshot(wire)
		if not (next["slots"][1] as Dictionary).has("stats"):
			without += 1
	assert_int(without).is_equal(SlowParts.EVERY - 1)
