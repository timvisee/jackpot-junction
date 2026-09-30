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
	# The shot that killed it landed, and is the shooter's hit.
	assert_float(stats.value(&"hits")).is_equal(1.0)
	var lost := match_node.slots[1].stats
	assert_float(lost.value(&"deaths")).is_equal(1.0)
	assert_float(lost.value(&"coins_lost")).is_equal(9.0)
	# What of it spilled onto the floor, the rest being banked.
	var rules := match_node.rules
	var spilled := Scoring.death_drop(9, rules.death_drop_fraction, rules.death_drop_max)
	assert_int(spilled).is_greater(0)
	assert_float(lost.value(&"coins_dropped")).is_equal(float(spilled))
	var data := match_node.build_snapshot()
	var copy := PlayerStats.new()
	copy.from_array(data["slots"][1]["stats"])
	assert_float(copy.value(&"coins_lost")).is_equal(9.0)
	assert_float(copy.value(&"deaths")).is_equal(1.0)


## GAME.md 3.8: accuracy is the share of a player's shots that landed on somebody, and only says
## anything past a handful of shots, so one lucky one is not an award.
func test_accuracy_is_worked_out_from_the_shots_and_is_an_award() -> void:
	var sharp := PlayerStats.new()
	sharp.add(&"bullets", 20.0)
	sharp.add(&"hits", 15.0)
	assert_float(sharp.value(&"accuracy")).is_equal(75.0)
	var lucky := PlayerStats.new()
	lucky.add(&"bullets", 1.0)
	lucky.add(&"hits", 1.0)
	assert_float(lucky.value(&"accuracy")).is_equal(0.0)
	var wild := PlayerStats.new()
	wild.add(&"bullets", 40.0)
	wild.add(&"hits", 4.0)
	var everyone: Array[PlayerStats] = [sharp, lucky, wild]
	var titles: Array = []
	for award: Array in PlayerStats.awards(sharp, everyone):
		titles.append(award[0])
		if award[0] == "Marksman":
			assert_str(award[1]).is_equal("75% of shots on target")
	assert_bool("Marksman" in titles).is_true()
	# The hits themselves are only counted for the accuracy's sake.
	for award: Array in PlayerStats.awards(wild, everyone):
		assert_str(award[1]).not_contains("hits")


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
	# And every one of them can be named on the results screen, or is behind one that can.
	for field: StringName in PlayerStats.FIELDS + PlayerStats.DERIVED:
		if field in PlayerStats.BEHIND_DERIVED:
			continue
		(
			assert_bool(PlayerStats.AWARDS.has(field))
			. override_failure_message("%s has no award" % field)
			. is_true()
		)


## GAME.md 3.8: a ram is counted for whoever landed it, once a ram, whatever it did, and the coins
## it knocks out of a kart that lives through it are coins that kart dropped.
func test_rams_are_counted_for_the_rammer_and_knock_coins_out() -> void:
	var match_node := _start_match([KartInput.new(), KartInput.new()])
	await _runner.simulate_frames(12, 17)
	var victim := match_node.kart_of(1)
	victim.lives = 2
	victim.pot.add_coins(20)
	KartCollisions.ram(victim, 0)
	assert_bool(victim.alive).is_true()
	assert_float(match_node.slots[0].stats.value(&"rams")).is_equal(1.0)
	var knocked := match_node.slots[1].stats.value(&"coins_dropped")
	assert_float(knocked).is_greater(0.0)
	assert_float(knocked).is_equal(20.0 - victim.pot.coins)
	# Still in touch, the tick after: the same ram, not another.
	KartCollisions.ram(victim, 0)
	assert_float(match_node.slots[0].stats.value(&"rams")).is_equal(1.0)
	assert_float(match_node.slots[1].stats.value(&"rams")).is_equal(0.0)


## GAME.md 3.8: reaching match point is counted, once for however long the pot hovers on the line
## and again only once it has been away from it a while, the same as it is called out, 3.4.
func test_match_points_are_counted_as_they_are_called() -> void:
	var match_node := _start_match([KartInput.new(), KartInput.new()])
	await _runner.simulate_frames(12, 17)
	var slot := match_node.slots[0]
	slot.banked = match_node.rules.target_score - 10
	slot.kart.pot.add_coins(40)
	assert_bool(match_node.would_win(slot)).is_true()
	await _runner.simulate_frames(20, 17)
	assert_float(slot.stats.value(&"match_points")).is_equal(1.0)
	# Off the line and straight back on is the same match point.
	slot.kart.pot.reset()
	await _runner.simulate_frames(2, 17)
	slot.kart.pot.add_coins(40)
	await _runner.simulate_frames(2, 17)
	assert_float(slot.stats.value(&"match_points")).is_equal(1.0)
	assert_float(match_node.slots[1].stats.value(&"match_points")).is_equal(0.0)


## GAME.md 3.8: two stats that tell one story earn a player one award between them, the coins in a
## pot at a death being most of the coins it drops there.
func test_one_award_for_one_story() -> void:
	var clumsy := PlayerStats.new()
	clumsy.add(&"coins_lost", 60.0)
	clumsy.add(&"coins_dropped", 40.0)
	clumsy.add(&"bullets", 5.0)
	clumsy.add(&"rams", 2.0)
	var careful := PlayerStats.new()
	careful.add(&"coins_lost", 2.0)
	careful.add(&"coins_dropped", 1.0)
	careful.add(&"bullets", 50.0)
	var everyone: Array[PlayerStats] = [clumsy, careful]
	var titles: Array = []
	for award: Array in PlayerStats.awards(clumsy, everyone):
		titles.append(award[0])
	assert_int(titles.size()).is_equal(3)
	assert_bool("Butterfingers" in titles and "Piggy Bank" in titles).is_false()
	assert_bool("Butterfingers" in titles or "Piggy Bank" in titles).is_true()
	assert_bool("Battering Ram" in titles).is_true()
