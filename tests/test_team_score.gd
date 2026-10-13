extends GdUnitTestSuite
## Scoring together in team play, GAME.md 3.14: a team's bank against a team's target, the winner
## and its tie-break, sudden death to the last team, the bounty, Toll Booth and Vulture, flush pads
## held by a team and a Jackpot teammates do not contest.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")
const AWAY: Array[Vector3] = [
	Vector3(-10.0, 0.0, 8.0),
	Vector3(10.0, 0.0, 8.0),
	Vector3(-4.0, 0.0, 8.0),
	Vector3(4.0, 0.0, 8.0)
]

var _runner: GdUnitSceneRunner


## Four karts, Hearts in seats 0 and 2 and Spades in 1 and 3, playing to 100 a kart, 200 a team.
func _start(overtime := true, lives := 2) -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.teams = 2
	rules.target_score = 100
	rules.overtime = overtime
	rules.lives = lives
	rules.respawn_delay = 0.2
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = []
	for i: int in 4:
		inputs.append(KartInput.new())
	match_node.start(inputs, 11)
	await _runner.simulate_frames(12, 17)
	for i: int in 4:
		_park(match_node.kart_of(i), AWAY[i])
	return match_node


func _park(kart: Kart, at: Vector3) -> void:
	kart.global_position = at
	kart.face(Vector3(1.0, 0.0, 0.0))
	kart.motor.velocity = Vector3.ZERO


func _active_zone(match_node: Match) -> JackpotZone:
	for zone: JackpotZone in match_node.arena.jackpot_zones:
		if zone.active:
			return zone
	return null


## A team plays to the target times its size, and it is the team's bank that gets there.
func test_a_team_wins_on_its_bank() -> void:
	var match_node: Match = await _start()
	assert_int(match_node.rules.team_target()).is_equal(200)
	match_node.slots[0].banked = 150
	match_node.check_target()
	assert_int(match_node.state).is_not_equal(Match.State.RESULTS)
	match_node.slots[2].banked = 60
	match_node.check_target()
	assert_int(match_node.state).is_equal(Match.State.RESULTS)


## A pot that would take its team over the line is match point, though it would not take its
## kart there alone.
func test_a_pot_wins_with_its_teammates_bank() -> void:
	var match_node: Match = await _start()
	var slot := match_node.slots[0]
	slot.kart.pot.add_coins(60)
	assert_bool(match_node.would_win(slot)).is_false()
	match_node.slots[2].banked = 150
	assert_bool(match_node.would_win(slot)).is_true()
	assert_bool(match_node.would_win(match_node.slots[1])).is_false()


## The standings go team by team, each team's karts by what they banked; level teams go to the
## one with more kills between its karts.
func test_the_standings_go_by_team() -> void:
	var match_node: Match = await _start()
	var slots := match_node.slots
	slots[0].banked = 10
	slots[2].banked = 80
	slots[1].banked = 60
	slots[3].banked = 20
	var ranked := match_node.standings()
	assert_array([ranked[0].index, ranked[1].index, ranked[2].index, ranked[3].index]).is_equal(
		[2, 0, 1, 3]
	)
	slots[3].banked = 30
	slots[1].kills = 1
	ranked = match_node.standings()
	assert_int(ranked[0].index).is_equal(1)


## Sudden death plays on while two teams are out there, and ends when one is left, every kart of
## it banking the whole of its pot.
func test_sudden_death_is_played_to_the_last_team() -> void:
	var match_node: Match = await _start(true, 1)
	match_node.kart_of(0).pot.add_coins(10)
	match_node.kart_of(2).pot.add_coins(5)
	match_node.time_left = 0.02
	await _runner.simulate_frames(6, 17)
	assert_int(match_node.state).is_equal(Match.State.OVERTIME)
	match_node.kart_of(1).die(&"test", -1)
	await _runner.simulate_frames(4, 17)
	assert_int(match_node.state).is_equal(Match.State.OVERTIME)
	var carried: Array[int] = [match_node.kart_of(0).pot.value(), match_node.kart_of(2).pot.value()]
	match_node.kart_of(3).die(&"test", -1)
	await _runner.simulate_frames(4, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	assert_int(match_node.slots[0].banked).is_greater_equal(carried[0])
	assert_int(match_node.slots[2].banked).is_greater_equal(carried[1])
	assert_int(carried[1]).is_greater_equal(5)


## A field down to one team when the clock runs out has nothing to play out.
func test_one_team_left_at_the_clock_ends_it() -> void:
	var match_node: Match = await _start(true, 1)
	match_node.kart_of(1).die(&"test", -1)
	match_node.kart_of(3).die(&"test", -1)
	match_node.kart_of(2).pot.add_coins(7)
	match_node.time_left = 0.02
	await _runner.simulate_frames(6, 17)
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	assert_int(match_node.slots[2].banked).is_equal(7)


## The price goes on the leading team's top earner once the team is clear, not on a kart that is
## only clear of the rest by itself.
func test_the_bounty_goes_on_the_leading_teams_top_earner() -> void:
	var match_node: Match = await _start()
	var slots := match_node.slots
	slots[1].banked = 300
	slots[0].banked = 100
	slots[2].banked = 150
	assert_object(Bounty._leader(match_node)).is_null()
	slots[2].banked = 400
	assert_object(Bounty._leader(match_node)).is_same(slots[2])


## Toll Booth takes a share of the other team's cash-outs, and nothing of a teammate's.
func test_toll_booth_takes_from_the_other_team_only() -> void:
	var match_node: Match = await _start()
	var holder := match_node.slots[0]
	holder.kart.jokers.add(load("res://data/jokers/toll_booth.tres"))
	match_node._on_bank_completed(match_node.kart_of(2), 10, 1.0, 100)
	assert_int(holder.banked).is_equal(0)
	match_node._on_bank_completed(match_node.kart_of(1), 10, 1.0, 100)
	assert_int(holder.banked).is_greater(0)


## Vulture pays for the other team's dropped chips, not a teammate's.
func test_vulture_pays_for_the_other_teams_drops() -> void:
	var match_node: Match = await _start()
	var kart := match_node.kart_of(0)
	kart.jokers.add(load("res://data/jokers/vulture.tres"))
	var ours: Chip = auto_free(Chip.new())
	ours.dropped = true
	ours.dropped_team = 0
	var theirs: Chip = auto_free(Chip.new())
	theirs.dropped = true
	theirs.dropped_team = 1
	assert_int(kart.jokers.jokers[0].modify_coin_value(kart, ours, 1)).is_equal(1)
	assert_int(kart.jokers.jokers[0].modify_coin_value(kart, theirs, 1)).is_equal(3)


## A chip a kart drops says which team it was on.
func test_a_dropped_chip_says_its_team() -> void:
	var match_node: Match = await _start()
	var chips := match_node.arena.spawn_chips(Vector3.ZERO, 2, 15.0, 0.0, true, 1)
	for chip: Chip in chips:
		assert_int(chip.dropped_team).is_equal(1)


## A pad is its team's: a teammate driving over it holds it rather than taking it, and the team
## holding all four, whoever of it holds each, has a flush, each pad paying its holder after.
func test_a_team_holds_the_flush_pads_together() -> void:
	var match_node: Match = await _start()
	var pads := match_node.arena.flush_pads
	var hearts := match_node.slots[0]
	var mate := match_node.slots[2]
	pads[0].claim(0, hearts.color(), 0)
	_park(mate.kart, pads[0].global_position)
	await _runner.simulate_frames(3, 17)
	assert_int(pads[0].owner_slot).is_equal(2)
	assert_int(pads[0].owner_team).is_equal(0)
	assert_bool(pads[0].can_be_taken_by(hearts.kart)).is_false()
	assert_bool(pads[0].can_be_taken_by(match_node.kart_of(1))).is_true()
	_park(mate.kart, AWAY[2])
	pads[1].claim(0, hearts.color(), 0)
	pads[2].claim(2, mate.color(), 0)
	pads[3].claim(0, hearts.color(), 0)
	FlushBoard.claimed(pads[3], hearts.kart, match_node)
	assert_bool(pads[0].is_disabled()).is_true()
	assert_int(match_node.flush_lock_slot).is_equal(0)
	assert_array([pads[0].lock_holder, pads[1].lock_holder, pads[2].lock_holder]).is_equal(
		[2, 0, 2]
	)
	hearts.kart.pot.reset()
	mate.kart.pot.reset()
	match_node.rules.flush_pad_income = 4.0
	await _runner.simulate_frames(60, 17)
	assert_int(hearts.kart.pot.coins).is_greater(0)
	assert_int(mate.kart.pot.coins).is_greater(0)


## Teammates do not contest the Jackpot: the first of them on collects. The other team does.
func test_teammates_do_not_contest_the_jackpot() -> void:
	var match_node: Match = await _start()
	match_node.rules.jackpot_accrual = 0.0
	var zone := _active_zone(match_node)
	zone.chips = 30.0
	var first := match_node.kart_of(0)
	var mate := match_node.kart_of(2)
	_park(first, zone.global_position + Vector3(0.0, 0.0, -0.75))
	await _runner.simulate_frames(2, 17)
	_park(mate, zone.global_position + Vector3(0.0, 0.0, 0.75))
	await _runner.simulate_frames(200, 17)
	assert_int(first.pot.coins).is_equal(30)
	assert_int(mate.pot.coins).is_equal(0)
	zone = _active_zone(match_node)
	zone.chips = 30.0
	_park(first, zone.global_position + Vector3(0.0, 0.0, -0.75))
	_park(match_node.kart_of(1), zone.global_position + Vector3(0.0, 0.0, 0.75))
	_park(mate, AWAY[2])
	var before := first.pot.coins
	await _runner.simulate_frames(60, 17)
	assert_int(first.pot.coins).is_equal(before)
