extends GdUnitTestSuite
## What team play shows, GAME.md 3.14: the standings in a block for each team, a corner with the
## team's bank and the player's share, a tank a team, the board naming the team, one match point a
## team, the flush tally counting a team's pads together, and a suit on every kart's pennant.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


## A player here in seat 0 on Hearts with a bot teammate in seat 2, and Spades in seats 1 and 3,
## playing to 1000 a kart.
func _start(hud := true) -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.teams = 2
	rules.target_score = 1000
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = hud
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [
		PlayerInput.new(0), KartInput.new(), KartInput.new(), KartInput.new()
	]
	match_node.start(inputs, 31)
	await _runner.simulate_frames(12, 17)
	return match_node


func _bank(match_node: Match, amounts: Array[int]) -> void:
	for i: int in amounts.size():
		match_node.slots[i].banked = amounts[i]


## A head row a team, the leading team's first, each team's karts under its head by what they
## banked and without a place of their own.
func test_the_standings_stand_in_a_block_a_team() -> void:
	var match_node: Match = await _start()
	_bank(match_node, [100, 900, 300, 50])
	await _runner.simulate_frames(2, 17)
	var board := match_node.hud._scoreboard
	var spades: Dictionary = board._heads[1]
	var hearts: Dictionary = board._heads[0]
	assert_str((spades["name"] as Label).text).is_equal("Spades")
	assert_str((spades["score"] as Label).text).is_equal("950")
	assert_str((hearts["score"] as Label).text).is_equal("400")
	var order: Array[Control] = []
	for child: Node in board.get_children():
		if (child as Control).visible:
			order.append(child as Control)
	var wanted: Array[Control] = [
		spades["panel"],
		board._rows[1]["panel"],
		board._rows[3]["panel"],
		hearts["panel"],
		board._rows[2]["panel"],
		board._rows[0]["panel"],
	]
	assert_array(order).is_equal(wanted)
	assert_str((board._rows[1]["place"] as Label).text).is_empty()
	assert_str((board._rows[1]["score"] as Label).text).is_equal("900")


## A player's corner shows the team's bank, and their own share of it beside their lives.
func test_a_corner_shows_the_teams_bank_and_the_share() -> void:
	var match_node: Match = await _start()
	_bank(match_node, [120, 0, 380, 0])
	await _runner.simulate_frames(2, 17)
	var block: Dictionary = match_node.hud._blocks[0]
	assert_str((block["banked"] as Label).text).is_equal("500")
	var share: Label = block["share"]
	assert_bool(share.visible).is_true()
	assert_str(share.text).is_equal("yours 120")


## A tank a team, in its color, full at the team's target.
func test_a_tank_a_team() -> void:
	var match_node: Match = await _start(false)
	_bank(match_node, [500, 0, 500, 1000])
	await _runner.simulate_frames(240, 17)
	var tanks := match_node.score_tanks
	assert_int(tanks._columns.size()).is_equal(2)
	assert_float(tanks._levels[0]).is_equal_approx(0.5, 0.02)
	assert_float(tanks._levels[1]).is_equal_approx(0.5, 0.02)


## The board over the crowd names the team that won.
func test_the_board_names_the_winning_team() -> void:
	var match_node: Match = await _start(false)
	_bank(match_node, [0, 2000, 0, 0])
	match_node.check_target()
	assert_int(match_node.state).is_equal(Match.State.RESULTS)
	assert_str(match_node.led_clock._winner()).is_equal("Spades")


## Two teammates reaching match point together are one call, the team's.
func test_match_point_is_called_once_a_team() -> void:
	var match_node: Match = await _start(false)
	_bank(match_node, [1900, 0, 0, 0])
	match_node.kart_of(0).pot.add_coins(200)
	match_node.kart_of(2).pot.add_coins(200)
	var calls := MatchPoint.new()
	assert_array(calls.step(match_node, 0.1)).has_size(1)
	assert_array(calls.step(match_node, 0.1)).is_empty()


## A team's pads count together in the tally, and a teammate's pad is this screen's business.
func test_the_flush_tally_counts_a_teams_pads_together() -> void:
	var match_node: Match = await _start()
	var tally: FlushTally = match_node.hud.get_node("FlushTally")
	var pads := match_node.arena.flush_pads
	var hearts := Teams.color(0)
	pads[0].claim(2, hearts, 0)
	pads[1].claim(0, hearts, 0)
	pads[2].claim(2, hearts, 0)
	tally._process(0.0)
	assert_bool(tally.visible).is_true()
	assert_array(tally.holders).is_equal([0, 0, 0])
	assert_int(tally.threat).is_equal(-1)
	pads[0].claim(1, Teams.color(1), 1)
	pads[1].claim(3, Teams.color(1), 1)
	pads[2].claim(1, Teams.color(1), 1)
	tally._process(0.0)
	assert_int(tally.threat).is_equal(1)


## Every kart on a team flies its suit; a kart moved to another team flies the new one, and a kart
## of a match without teams flies none.
func test_a_kart_flies_its_teams_pennant() -> void:
	var match_node: Match = await _start(false)
	var kart := match_node.kart_of(0)
	assert_object(kart.get_node_or_null("Body/TeamPennant")).is_not_null()
	SeatIdentity.join_team(match_node.slots[0], 1)
	await _runner.simulate_frames(1, 17)
	assert_int(kart.color_index).is_equal(Teams.color_index(1))
	var pennants := 0
	for child: Node in kart.get_node("Body").get_children():
		if child.name == TeamPennant.NAME:
			pennants += 1
	assert_int(pennants).is_equal(1)
	SeatIdentity.join_team(match_node.slots[0], -1)
	await _runner.simulate_frames(1, 17)
	assert_object(kart.get_node_or_null("Body/TeamPennant")).is_null()
