extends GdUnitTestSuite
## Match statistics and the results awards, GAME.md 3.8: the match counts what every kart does,
## the awards pick the stats a player stands out in, and stats reach puppets in snapshots.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var _runner: GdUnitSceneRunner


func _start_match(inputs: Array[KartInput]) -> Match:
	var rules: MatchRules = load("res://data/match/default.tres").duplicate()
	rules.countdown = 0.1
	rules.lives = 1
	rules.spawn_protection = 0.0
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	match_node.start(inputs, 17)
	return match_node


func test_awards_go_to_the_stats_a_player_leads_and_skip_zeroes() -> void:
	var a := PlayerStats.new()
	var b := PlayerStats.new()
	a.add(&"bullets", 50.0)
	a.add(&"drifted", 10.0)
	a.add(&"coins", 4.0)
	b.add(&"bullets", 5.0)
	b.add(&"drifted", 200.0)
	b.add(&"grazes", 3.0)
	var everyone: Array[PlayerStats] = [a, b]
	var mine := PlayerStats.awards(a, everyone)
	assert_int(mine.size()).is_equal(3)
	assert_str(mine[0][0]).is_equal("Trigger Happy")
	assert_str(mine[0][1]).is_equal("50 shots fired")
	var theirs := PlayerStats.awards(b, everyone)
	assert_str(theirs[0][0]).is_equal("Sideways Specialist")
	assert_str(theirs[0][1]).is_equal("200 m drifted")
	var titles: Array = []
	for award: Array in theirs:
		titles.append(award[0])
	assert_bool("Close Shave" in titles).is_true()
	assert_bool("Vacuum Cleaner" in titles).is_false()
	var nobody := PlayerStats.awards(PlayerStats.new(), everyone)
	assert_int(nobody.size()).is_equal(0)


func test_the_match_counts_shots_distance_coins_and_deaths() -> void:
	var input := KartInput.new()
	var match_node := _start_match([input, KartInput.new()])
	await _runner.simulate_frames(12, 17)
	var kart := match_node.kart_of(0)
	var victim := match_node.kart_of(1)
	kart.global_position = Vector3(-6.0, 0.0, -9.375)
	kart.face(Vector3(1.0, 0.0, 0.0))
	victim.global_position = Vector3(0.0, 0.0, -9.375)
	victim.pot.add_coins(9)
	input.throttle = 1.0
	await _runner.simulate_frames(40, 17)
	input.throttle = 0.0
	var stats := match_node.slots[0].stats
	assert_float(stats.value(&"driven")).is_greater(1.0)
	kart.collect_coins(3, null)
	assert_float(stats.value(&"coins")).is_equal(3.0)
	kart.global_position = Vector3(-6.0, 0.0, -9.375)
	kart.face(Vector3(1.0, 0.0, 0.0))
	kart.cannon.stats.aim_assist = false
	input.fire = true
	await _runner.simulate_frames(3, 17)
	input.fire = false
	assert_float(stats.value(&"bullets")).is_greater_equal(1.0)
	await _runner.simulate_frames(30, 17)
	assert_bool(victim.alive).is_false()
	var lost := match_node.slots[1].stats
	assert_float(lost.value(&"deaths")).is_equal(1.0)
	assert_float(lost.value(&"coins_lost")).is_equal(9.0)
	var data := match_node.build_snapshot()
	var copy := PlayerStats.new()
	copy.from_array(data["slots"][1]["stats"])
	assert_float(copy.value(&"coins_lost")).is_equal(9.0)
	assert_float(copy.value(&"deaths")).is_equal(1.0)


## GAME.md 3.8: the awards follow the game. The Jackpot, the drift boost, the Royal Flush pads
## and the oil are all things a player does a lot of, and each is now counted.
func test_the_newer_mechanics_are_counted_too() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	await _runner.simulate_frames(12, 17)
	var stats := match_node.slots[0].stats
	assert_float(stats.value(&"jackpot_chips")).is_equal(0.0)
	Events.jackpot_collected.emit(0, 9)
	Events.drift_boosted.emit(0)
	Events.drift_boosted.emit(0)
	Events.oil_hit.emit(0)
	await _runner.simulate_frames(2, 17)
	assert_float(stats.value(&"jackpot_chips")).is_equal(9.0)
	assert_float(stats.value(&"drift_boosts")).is_equal(2.0)
	assert_float(stats.value(&"oil_spins")).is_equal(1.0)
	# Taking a flush pad counts whether or not it ever becomes a flush.
	var kart := match_node.kart_of(0)
	kart.global_position = match_node.arena.flush_pads[0].global_position
	await _runner.simulate_frames(6, 17)
	assert_float(stats.value(&"pads_taken")).is_greater_equal(1.0)
	# And every one of them can be named on the results screen.
	for field: StringName in PlayerStats.FIELDS:
		(
			assert_bool(PlayerStats.AWARDS.has(field))
			. override_failure_message("%s has no award" % field)
			. is_true()
		)
