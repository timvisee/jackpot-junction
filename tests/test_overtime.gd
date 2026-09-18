extends GdUnitTestSuite
## Overtime, GAME.md 3.13: the clock running out sends the match to sudden death rather than
## ending it. Nobody comes back, the Junction still pays, and the last kart standing takes
## everything it is carrying.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


func _start_match(overtime: bool, players: int = 3) -> Match:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.lives = 1
	rules.respawn_delay = 0.2
	rules.overtime = overtime
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = []
	for i: int in players:
		inputs.append(KartInput.new())
	match_node.start(inputs, 17)
	return match_node


## The clock hitting zero with a field still out there goes to sudden death instead of the
## whistle, and the clock says so rather than counting anything.
func test_the_clock_running_out_goes_to_sudden_death() -> void:
	var match_node := _start_match(true)
	await _runner.simulate_frames(12, 17)
	match_node.time_left = 0.02
	await _runner.simulate_frames(6, 17)
	assert_int(match_node.state).is_equal(Match.State.OVERTIME)
	# And nothing about it winds down: the room still reads as the finale.
	assert_bool(match_node.in_the_finale()).is_true()
	assert_bool(match_node.is_running()).is_true()


## Nobody comes back out of it, and nobody is offered a joker for a respawn that is not coming.
func test_nobody_respawns_in_overtime() -> void:
	var match_node := _start_match(true)
	await _runner.simulate_frames(12, 17)
	match_node.time_left = 0.02
	await _runner.simulate_frames(6, 17)
	assert_int(match_node.state).is_equal(Match.State.OVERTIME)
	var slot := match_node.slots[2]
	slot.kart.die(&"test", 0)
	await _runner.simulate_frames(int(match_node.rules.respawn_delay * 60.0) + 40, 17)
	assert_bool(slot.kart.alive).is_false()
	assert_object(slot.offer).is_null()
	assert_int(match_node.state).is_equal(Match.State.OVERTIME)


## The last one left takes everything it is still carrying, and that ends it.
func test_the_last_kart_standing_banks_the_lot() -> void:
	var match_node := _start_match(true)
	await _runner.simulate_frames(12, 17)
	match_node.time_left = 0.02
	await _runner.simulate_frames(6, 17)
	var winner := match_node.slots[0]
	var banked_before := winner.banked
	winner.kart.collect_coins(40, null)
	winner.kart.gain_mult(2.0, &"test")
	# Nobody is credited with the deaths, so what lands in the winner's column is the pot and
	# nothing else.
	match_node.slots[1].kart.die(&"test", -1)
	await _runner.simulate_frames(2, 17)
	var carrying := Scoring.pot_value(winner.kart.pot.coins, winner.kart.pot.mult)
	assert_int(carrying).is_greater(0)
	match_node.slots[2].kart.die(&"test", -1)
	await _runner.simulate_frames(6, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	assert_int(winner.banked).is_equal(banked_before + carrying)
	assert_int(winner.kart.pot.coins).is_equal(0)


## Banking during it works the way it always did, so a player can secure what they have rather
## than betting it on staying alive.
func test_the_junction_still_pays_in_overtime() -> void:
	var match_node := _start_match(true)
	await _runner.simulate_frames(12, 17)
	match_node.time_left = 0.02
	await _runner.simulate_frames(6, 17)
	assert_int(match_node.state).is_equal(Match.State.OVERTIME)
	var slot := match_node.slots[0]
	var before := slot.banked
	slot.kart.collect_coins(30, null)
	slot.kart.global_position = match_node.arena.junction_position
	await _runner.simulate_frames(90, 17)
	assert_int(slot.banked).is_greater(before)


## Everyone going down at once is nobody's win: the whistle simply goes.
func test_an_empty_field_ends_it_without_paying_anyone() -> void:
	var match_node := _start_match(true, 2)
	await _runner.simulate_frames(12, 17)
	match_node.time_left = 0.02
	await _runner.simulate_frames(6, 17)
	assert_int(match_node.state).is_equal(Match.State.OVERTIME)
	for slot: PlayerSlot in match_node.slots:
		slot.kart.collect_coins(20, null)
		slot.kart.die(&"test", -1)
	await _runner.simulate_frames(6, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)


## A field already down to one when the clock runs out has nothing to play out: the whistle goes
## on the hour, as it did before there was an overtime.
func test_a_field_of_one_never_enters_overtime() -> void:
	var match_node := _start_match(true)
	await _runner.simulate_frames(12, 17)
	match_node.slots[1].kart.die(&"test", 0)
	match_node.slots[2].kart.die(&"test", 0)
	match_node.time_left = 0.02
	await _runner.simulate_frames(6, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)


## GAME.md 3.8: a player who would rather the whistle went on the hour can say so, and then it
## does, whoever is still driving.
func test_the_lobby_switch_turns_overtime_off() -> void:
	var match_node := _start_match(false)
	await _runner.simulate_frames(12, 17)
	match_node.time_left = 0.02
	await _runner.simulate_frames(6, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)


## The switch reaches the rules the way every other lobby option does.
func test_the_setting_reaches_the_rules() -> void:
	var config := MatchConfig.new()
	config.overtime = false
	var rules: MatchRules = DEFAULT_RULES
	assert_bool(rules.overtime).is_true()
	assert_bool(config.rules(rules).overtime).is_false()
	config.overtime = true
	assert_bool(config.rules(rules).overtime).is_true()
	var settings := Settings.new()
	settings.overtime = false
	assert_bool(MatchConfig.from_settings(settings).overtime).is_false()


## GAME.md 3.13: a kill in sudden death that puts the killer past the player they took out is
## called out and counted. In overtime a pot is a pot nobody is coming back for, so a kill
## changes the order far more often than it does with a clock still running.
func test_a_kill_that_takes_a_place_in_overtime_is_called_and_counted() -> void:
	var match_node := _start_match(true)
	await _runner.simulate_frames(12, 17)
	match_node.time_left = 0.02
	await _runner.simulate_frames(6, 17)
	assert_int(match_node.state).is_equal(Match.State.OVERTIME)
	var killer := match_node.slots[0]
	var victim := match_node.slots[1]
	# The victim is ahead, but only on what it is carrying, and that is what the kill takes.
	killer.banked = 200
	victim.banked = 40
	victim.kart.pot.add_coins(200)
	assert_bool(PlayerSlot.by_score(victim, killer)).is_true()
	var calls: Array = []
	var heard := func(slot: int, text: String) -> void: calls.append([slot, text])
	Events.announced.connect(heard)
	victim.kart.die(&"bullet", killer.index)
	Events.announced.disconnect(heard)
	assert_bool(PlayerSlot.by_score(killer, victim)).is_true()
	assert_array(calls).contains([[killer.index, "TAKING THE LEAD"]])
	assert_float(killer.stats.value(&"overtakes")).is_equal(1.0)


## The same kill with the clock still running is worth nothing extra: places change hands all
## match long when everybody is coming back.
func test_taking_a_place_outside_overtime_is_not_called() -> void:
	var match_node := _start_match(false)
	await _runner.simulate_frames(12, 17)
	var killer := match_node.slots[0]
	var victim := match_node.slots[1]
	killer.banked = 200
	victim.banked = 40
	victim.kart.pot.add_coins(200)
	var calls: Array = []
	var heard := func(slot: int, text: String) -> void: calls.append([slot, text])
	Events.announced.connect(heard)
	victim.kart.die(&"bullet", killer.index)
	Events.announced.disconnect(heard)
	assert_array(calls).is_empty()
	assert_float(killer.stats.value(&"overtakes")).is_equal(0.0)
