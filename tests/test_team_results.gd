extends GdUnitTestSuite
## The end of a map and of a run in team play, GAME.md 3.14: the payout slip's line a team with its
## players under it, a podium step a team, a Grand Prix paid by team, and its finale and board
## naming the team.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


## Hearts in seats 0 and 2, Spades in 1 and 3, Spades ahead.
func _start() -> Match:
	var rules: MatchRules = RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.teams = 2
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = []
	for i: int in 4:
		inputs.append(KartInput.new())
	match_node.start(inputs, 5)
	await _runner.simulate_frames(12, 17)
	var banked: Array[int] = [300, 900, 200, 100]
	for i: int in 4:
		match_node.slots[i].banked = banked[i]
	return match_node


## The standings in sides: a team together, where its best kart stands; a player each without.
func test_the_standings_go_in_sides() -> void:
	var match_node: Match = await _start()
	var sides := Teams.sides_of(match_node.standings())
	assert_int(sides.size()).is_equal(2)
	assert_int((sides[0] as Array).size()).is_equal(2)
	assert_int((sides[0][0] as PlayerSlot).index).is_equal(1)
	assert_int((sides[1][0] as PlayerSlot).index).is_equal(0)


## Steps as wide as their teams, spaced so none overlaps, the winner's in the middle.
func test_a_podiums_steps_fit_their_teams() -> void:
	assert_float(ResultsPodium.step_width(1, 1.9, 1.75)).is_equal(1.9)
	assert_float(ResultsPodium.step_width(3, 1.9, 1.75)).is_equal_approx(5.55, 0.001)
	var widths: Array[float] = [1.9, 1.9, 1.9]
	var across := ResultsPodium.spread(widths, 0.4)
	assert_float(across[0]).is_equal(0.0)
	assert_float(across[1]).is_equal_approx(-2.3, 0.001)
	assert_float(across[2]).is_equal_approx(2.3, 0.001)
	widths = [4.0, 2.0]
	across = ResultsPodium.spread(widths, 0.4)
	assert_float(across[1]).is_equal_approx(-3.4, 0.001)


## Every kart of the top teams stands on the podium, a team to a step.
func test_the_podium_stands_a_team_on_a_step() -> void:
	var match_node: Match = await _start()
	var podium: ResultsPodium = auto_free(ResultsPodium.create())
	add_child(podium)
	podium.show_top(match_node.standings())
	assert_int(podium._karts.size()).is_equal(4)
	assert_int(podium._standing[0].team).is_equal(1)
	assert_int(podium._standing[1].team).is_equal(1)
	assert_int(podium._standing[2].team).is_equal(0)


## The slip has a line a team, the winning team's stamped, and its players' lines under it, a block
## a team: dashes between its lines and no air, the team's close over its first player's, and for
## the reader's team one wash over all of it, square where one line runs on into the next.
func test_the_slip_has_a_block_a_team() -> void:
	var match_node: Match = await _start()
	# The reader plays for Hearts, in seat 0.
	match_node.slots[0].input = PlayerInput.new(DeviceInput.KEYBOARD)
	var page: SlipPage = auto_free(SlipPage.create(match_node))
	add_child(page)
	page.fill_map(match_node.standings())
	var blocks := page.rows.get_children()
	assert_int(blocks.size()).is_equal(2)
	var spades := blocks[0].get_children()
	var hearts := blocks[1].get_children()
	assert_int(spades.size()).is_equal(3)
	var named := (spades[0] as Node).find_child("Team", true, false)
	assert_str((named.get_node("Name") as Label).text).is_equal("Spades")
	assert_object((spades[0] as Node).find_child("Stamp", true, false)).is_not_null()
	assert_object((spades[1] as Node).find_child("Stamp", true, false)).is_null()
	assert_int((blocks[0] as VBoxContainer).get_theme_constant(&"separation")).is_equal(0)
	var team_line := _style(spades[0])
	var first_player := _style(spades[1])
	assert_float(team_line.dash.a).is_greater(0.0)
	assert_float(team_line.content_margin_bottom).is_equal(SlipPage.TEAM_BELOW)
	assert_float(first_player.content_margin_top).is_equal(SlipPage.TEAM_GAP)
	assert_float(team_line.wash.a).is_equal(0.0)
	# Hearts is the reader's: the whole block washed, the reader's own line, seat 0's, who banked
	# more than seat 2, the stronger.
	assert_object(_style(hearts[0]).wash).is_equal(SlipPage.TEAM_MINE)
	assert_object(_style(hearts[1]).wash).is_equal(SlipPage.ROW_MINE)
	assert_object(_style(hearts[2]).wash).is_equal(SlipPage.TEAM_MINE)
	assert_bool(_style(hearts[0]).joined_bottom).is_true()
	assert_bool(_style(hearts[1]).joined_top and _style(hearts[1]).joined_bottom).is_true()
	assert_bool(_style(hearts[2]).joined_bottom).is_false()
	# And the blocks run on into each other, the second team's wash meeting the dashes over it.
	assert_int(page.rows.get_theme_constant(&"separation")).is_equal(0)
	assert_bool(_style(spades[0]).joined_top).is_false()
	assert_bool(_style(spades[2]).joined_bottom).is_true()
	assert_bool(_style(hearts[0]).joined_top).is_true()


func _style(line: Node) -> DashStyle:
	return (line as PanelContainer).get_theme_stylebox(&"panel") as DashStyle


## A map of a run pays every kart of a team its team's place, and the run goes by team.
func test_a_run_is_paid_by_team() -> void:
	var match_node: Match = await _start()
	var run := GrandPrix.start(2, RandomNumberGenerator.new())
	run.score(match_node.standings())
	assert_int(run.total(1)).is_equal(GrandPrix.POINTS[0])
	assert_int(run.total(3)).is_equal(GrandPrix.POINTS[0])
	assert_int(run.total(0)).is_equal(GrandPrix.POINTS[1])
	assert_int(run.total(2)).is_equal(GrandPrix.POINTS[1])
	assert_int(run.wins(3)).is_equal(1)
	var page: SlipPage = auto_free(SlipPage.create(match_node))
	add_child(page)
	page.fill_run(run.standings(match_node.slots), run)
	assert_int(page.rows.get_child_count()).is_equal(2)


## The finale stands the winning team on the top step and its name on the board.
func test_the_finale_names_the_team() -> void:
	var match_node: Match = await _start()
	var finale := GrandPrixFinale.stage(match_node, match_node.standings(), func() -> void: pass)
	assert_int(finale._karts.size()).is_equal(4)
	assert_str(finale._champion.text).is_equal("Spades")
	assert_object(finale._tints[0]).is_equal(Teams.color(1))
	finale.queue_free()
