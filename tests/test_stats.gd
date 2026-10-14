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


## GAME.md 3.8: an award is earned by doing enough of a thing, its least, and for a contest by doing
## the most of it; a dull figure, a mult that never left x1, earns nothing, and neither does a
## player who did nothing.
func test_an_award_needs_its_least_and_a_lead() -> void:
	var a := PlayerStats.new()
	var b := PlayerStats.new()
	var idle := PlayerStats.new()
	a.add(&"bullets", 90.0)
	a.add(&"drifted", 10.0)
	a.peak(&"max_mult", 1.0)
	b.add(&"bullets", 5.0)
	b.add(&"drifted", 200.0)
	b.add(&"grazes", 6.0)
	b.peak(&"max_mult", 1.0)
	var dealt := PlayerStats.deal([a, b, idle] as Array[PlayerStats], 300.0)
	assert_array(_titles(dealt[0])).is_equal(["Trigger Happy"])
	assert_str(dealt[0][0][1]).is_equal("90 shots fired")
	assert_array(_titles(dealt[1])).contains_exactly_in_any_order(
		["Sideways Specialist", "Close Shave"]
	)
	assert_array(dealt[2]).is_empty()
	# Under its least, nothing: forty shots is not Trigger Happy on a five-minute map.
	a.values[&"bullets"] = 40.0
	assert_array(PlayerStats.deal([a, b] as Array[PlayerStats], 300.0)[0]).is_empty()
	# A total's least goes with the map's length; a peak's and a feat's do not.
	assert_float(PlayerStats.least_of(&"bullets", 0.5)).is_equal(40.0)
	assert_float(PlayerStats.least_of(&"max_mult", 0.5)).is_equal(6.0)
	assert_float(PlayerStats.least_of(&"flushes", 2.0)).is_equal(2.0)
	assert_array(_titles(PlayerStats.deal([a, b] as Array[PlayerStats], 150.0)[0])).is_equal(
		["Trigger Happy"]
	)


## GAME.md 3.8: the awards are dealt in finishing order, the winner first, each title once on the
## slip, so a feat two players earned is the higher placed one's; up to three each; and a ribbing
## never goes to the winner, though it goes to whoever else leads it.
func test_the_winner_deals_first_and_a_title_is_once_on_a_slip() -> void:
	var winner := PlayerStats.new()
	var second := PlayerStats.new()
	for each: PlayerStats in [winner, second]:
		each.add(&"flushes", 2.0)
	winner.add(&"deaths", 20.0)
	second.add(&"crates", 30.0)
	var dealt := PlayerStats.deal([winner, second] as Array[PlayerStats], 300.0)
	assert_array(_titles(dealt[0])).is_equal(["Royal Flush"])
	assert_array(_titles(dealt[1])).is_equal(["Demolition Crew"])
	# The second in the lead of the deaths: theirs to be ribbed for.
	winner.values[&"deaths"] = 3.0
	second.add(&"deaths", 12.0)
	dealt = PlayerStats.deal([winner, second] as Array[PlayerStats], 300.0)
	assert_bool("Crash Test Dummy" in _titles(dealt[1])).is_true()
	# Up to three a player, the most interesting first: a headline before a skill before a busy.
	var busy := PlayerStats.new()
	busy.add(&"flushes", 3.0)
	busy.add(&"grazes", 9.0)
	busy.add(&"crates", 40.0)
	busy.add(&"turbo_pads", 30.0)
	dealt = PlayerStats.deal([busy] as Array[PlayerStats], 300.0)
	assert_array(_titles(dealt[0])).is_equal(["Royal Flush", "Close Shave", "Demolition Crew"])


## GAME.md 3.8: everybody drives, so a Road Warrior has to have driven a fifth further than anybody.
func test_a_road_warrior_drove_a_fifth_further() -> void:
	var far := PlayerStats.new()
	var near := PlayerStats.new()
	far.add(&"driven", 1500.0)
	near.add(&"driven", 1300.0)
	var everyone: Array[PlayerStats] = [far, near]
	assert_array(_titles(PlayerStats.deal(everyone, 300.0)[0])).is_empty()
	far.values[&"driven"] = 1600.0
	assert_array(_titles(PlayerStats.deal(everyone, 300.0)[0])).is_equal(["Road Warrior"])


## GAME.md 3.8: one of a thing is said as one, "1 graze", not "1 grazes".
func test_one_is_said_as_one() -> void:
	assert_str(PlayerStats.said(&"grazes", 1.0)[1]).is_equal("1 graze")
	assert_str(PlayerStats.said(&"grazes", 4.0)[1]).is_equal("4 grazes")
	assert_str(PlayerStats.said(&"flushes", 2.0)[1]).is_equal("2 flushes")
	assert_str(PlayerStats.said(&"bounties", 1.0)[1]).is_equal("1 bounty collected")


## GAME.md 3.8 has every award in a table to look it up by, its least among it: the table and the
## awards are held to each other, so neither changes without the other.
func test_the_design_lists_every_award_with_its_least() -> void:
	var design := FileAccess.get_file_as_string("res://docs/GAME.md")
	var from := design.find("| Award | Tier | Kind |")
	assert_int(from).is_greater(0)
	var table := design.substr(from, design.find("\n\n", from) - from)
	var rows := {}
	for line: String in table.split("\n").slice(2):
		var cells := line.split("|")
		rows[cells[1].strip_edges()] = cells[5].strip_edges()
	assert_int(rows.size()).is_equal(PlayerStats.AWARDS.size())
	for field: StringName in PlayerStats.AWARDS:
		var award: Array = PlayerStats.AWARDS[field]
		var title: String = award[PlayerStats.TITLE]
		assert_bool(rows.has(title)).override_failure_message("%s is not listed" % title).is_true()
		var least := "%s" % str(award[PlayerStats.LEAST]).trim_suffix(".0")
		(
			assert_str(rows.get(title, ""))
			. override_failure_message("%s's least is not %s" % [title, least])
			. contains(least)
		)


func _titles(awards: Array) -> Array:
	var titles: Array = []
	for award: Array in awards:
		titles.append(award[0])
	return titles


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
	var dealt := PlayerStats.deal(everyone, 300.0)
	var marksman := dealt[0].filter(func(award: Array) -> bool: return award[0] == "Marksman")
	assert_int(marksman.size()).is_equal(1)
	assert_str(marksman[0][1]).is_equal("75% of shots on target")
	# The hits themselves are only counted for the accuracy's sake.
	for award: Array in dealt[2]:
		assert_str(award[1]).not_contains("hits")
	# A share of a few shots is luck: under fifteen, no Marksman.
	sharp.values[&"bullets"] = 12.0
	sharp.values[&"hits"] = 11.0
	assert_bool("Marksman" in _titles(PlayerStats.deal(everyone, 300.0)[0])).is_false()


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
		if field in PlayerStats.BEHIND_DERIVED or field in PlayerStats.RECORD_ONLY:
			continue
		(
			assert_bool(PlayerStats.AWARDS.has(field))
			. override_failure_message("%s has no award" % field)
			. is_true()
		)


## GAME.md 8.5: the records the Statistics page keeps beside the awards' counts. The longest drift
## and the biggest pot are peaks; a kill streak is kills in one life, a death starting it again; and
## two bullets meeting is one shot down for each of their karts, none for a kart's own two.
func test_the_records_are_counted() -> void:
	var inputs: Array[KartInput] = [KartInput.new(), KartInput.new(), KartInput.new()]
	var match_node := _start_match(inputs)
	await _runner.simulate_frames(12, 17)
	var stats := match_node.slots[0].stats
	var kart := match_node.kart_of(0)
	kart.motor.drifting = true
	kart.motor.drift_time = 3.2
	kart.pot.add_coins(50)
	kart.pot.add_mult(1.0)
	MatchStats.step(match_node, 0.0)
	kart.motor.drift_time = 1.0
	kart.pot.reset()
	MatchStats.step(match_node, 0.0)
	assert_float(stats.value(&"longest_drift")).is_equal_approx(3.2, 0.001)
	assert_float(stats.value(&"biggest_pot")).is_equal(100.0)
	match_node.kart_of(1).die(&"bullet", 0)
	match_node.kart_of(2).die(&"bullet", 0)
	assert_float(stats.value(&"best_streak")).is_equal(2.0)
	kart.die(&"bullet", 1)
	assert_int(match_node.slots[0].streak).is_equal(0)
	assert_float(stats.value(&"best_streak")).is_equal(2.0)
	Events.bullets_met.emit(0, 1)
	Events.bullets_met.emit(2, 2)
	assert_float(stats.value(&"parries")).is_equal(1.0)
	assert_float(match_node.slots[1].stats.value(&"parries")).is_equal(1.0)
	assert_float(match_node.slots[2].stats.value(&"parries")).is_equal(0.0)
	# A profile keeps the best of each peak rather than adding them up.
	var profile := Profile.new()
	LifetimeStats.add_play(profile, match_node.slots[0], 60.0)
	LifetimeStats.add_play(profile, match_node.slots[0], 60.0)
	assert_float(LifetimeStats.value_of(profile, &"longest_drift")).is_equal_approx(3.2, 0.001)
	assert_float(LifetimeStats.value_of(profile, &"parries")).is_equal(2.0)
	assert_str(LifetimeStats.shown(profile, &"longest_drift")).is_equal("3.2 s")


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
	var careful := PlayerStats.new()
	careful.add(&"coins_lost", 2.0)
	careful.add(&"coins_dropped", 1.0)
	careful.add(&"bullets", 90.0)
	var clumsy := PlayerStats.new()
	clumsy.add(&"coins_lost", 600.0)
	clumsy.add(&"coins_dropped", 400.0)
	clumsy.add(&"bullets", 5.0)
	clumsy.add(&"rams", 4.0)
	var everyone: Array[PlayerStats] = [careful, clumsy]
	var titles := _titles(PlayerStats.deal(everyone, 300.0)[1])
	assert_int(titles.size()).is_equal(2)
	assert_bool("Butterfingers" in titles and "Piggy Bank" in titles).is_false()
	assert_bool("Butterfingers" in titles or "Piggy Bank" in titles).is_true()
	assert_bool("Battering Ram" in titles).is_true()
