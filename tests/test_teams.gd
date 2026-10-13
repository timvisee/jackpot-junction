extends GdUnitTestSuite
## Team play, GAME.md 3.14: the option and its wire, who sits on which team, the team's color on a
## kart with its own shape on the roof, and a team carried over to a client.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const DEFAULT_RULES: MatchRules = preload("res://data/match/default.tres")

var _runner: GdUnitSceneRunner


func _rules(teams: int) -> MatchRules:
	var rules: MatchRules = DEFAULT_RULES.duplicate()
	rules.countdown = 0.1
	rules.duration = 60.0
	rules.teams = teams
	return rules


## A match of [param karts] split into [param teams], [param dealt] their teams; with
## [param people] they are players from another machine rather than bots.
func _start(teams: int, karts: int, dealt: Array[int] = [], people := false) -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = _rules(teams)
	match_node.rules.max_players = maxi(karts, 4)
	match_node.with_hud = false
	match_node.offer_size = 0
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = []
	for i: int in karts:
		inputs.append(NetInput.new() if people else KartInput.new())
	match_node.start(inputs, 17, [], [], [], dealt)
	return match_node


func _teams_of(match_node: Match) -> Array[int]:
	var result: Array[int] = []
	for slot: PlayerSlot in match_node.slots:
		result.append(slot.team)
	return result


## The rows' choices go over the wire to a client as rules and to a dedicated server as a plan,
## and a value no row offers is left out.
func test_the_teams_and_friendly_fire_survive_the_wire() -> void:
	var rules := _rules(3)
	rules.friendly_fire = true
	rules.team_size = 2
	var told: MatchRules = DEFAULT_RULES.duplicate()
	told.from_wire(rules.to_wire())
	assert_int(told.teams).is_equal(3)
	assert_bool(told.friendly_fire).is_true()
	assert_int(told.team_size).is_equal(2)
	var config := MatchConfig.new()
	config.teams = 4
	config.friendly_fire = true
	var planned := MatchConfig.new()
	MatchOptions.from_wire(planned, MatchOptions.to_wire(config))
	assert_int(planned.teams).is_equal(4)
	assert_bool(planned.friendly_fire).is_true()
	MatchOptions.from_wire(planned, {"teams": 5})
	assert_int(planned.teams).is_equal(4)
	assert_bool(config.rules(DEFAULT_RULES).friendly_fire).is_true()
	assert_int(config.rules(DEFAULT_RULES).teams).is_equal(4)


## Everybody who asked for a team has it, everybody else goes to the smallest as they come, the
## first of those tied in the suits' order, and the bots, last, fill whatever is short.
func test_teams_are_dealt_to_the_smallest() -> void:
	assert_array(Teams.deal([], 2, 4)).is_equal([0, 1, 0, 1])
	assert_array(Teams.deal([1, 1], 2, 4)).is_equal([1, 1, 0, 0])
	assert_array(Teams.deal([-1, 0, 0], 2, 5)).is_equal([1, 0, 0, 1, 0])
	assert_array(Teams.deal([3], 3, 3)).is_equal([0, 1, 2])
	assert_array(Teams.deal([2], 4, 4)).is_equal([2, 0, 1, 3])
	assert_array(Teams.deal([0, 1], 0, 3)).is_equal([-1, -1, -1])


## What the lobby sends: the humans' choices, the kept seats' teams, then the bots on whatever is
## short.
func test_a_config_deals_every_seat_a_team() -> void:
	var config := MatchConfig.new()
	config.teams = 2
	config.human_devices = [DeviceInput.KEYBOARD, 0]
	config.human_teams = [1, 1]
	config.network_seats = 1
	config.network_teams = [0]
	config.bot_count = 1
	assert_array(config.team_list()).is_equal([1, 1, 0, 0])
	config.teams = 0
	assert_array(config.team_list()).is_equal([-1, -1, -1, -1])


## A match in teams seats everybody on one, paints each kart in its team's color with its own
## color's shape on the roof, and plays to the target times the biggest team.
func test_a_match_in_teams_paints_its_karts_by_team() -> void:
	var match_node := _start(2, 4)
	assert_array(_teams_of(match_node)).is_equal([0, 1, 0, 1])
	for slot: PlayerSlot in match_node.slots:
		assert_int(slot.kart.team).is_equal(slot.team)
		assert_int(slot.kart.color_index).is_equal(Teams.color_index(slot.team))
		assert_int(slot.kart.marker_index).is_equal(slot.color_index)
		assert_object(slot.color()).is_equal(Teams.color(slot.team))
	# Teammates share a color and nothing else: four colors of their own, four shapes.
	assert_int(match_node.slots[0].kart.color_index).is_equal(match_node.slots[2].kart.color_index)
	assert_int(KartVisuals.shape_of(match_node.slots[0].kart)).is_not_equal(
		KartVisuals.shape_of(match_node.slots[2].kart)
	)
	assert_int(match_node.rules.team_size).is_equal(2)
	assert_int(match_node.rules.team_target()).is_equal(match_node.rules.target_score * 2)


## Without teams nothing changes: every kart in its own color, nobody on a side.
func test_a_match_without_teams_has_no_sides() -> void:
	var match_node := _start(0, 3)
	assert_array(_teams_of(match_node)).is_equal([-1, -1, -1])
	for slot: PlayerSlot in match_node.slots:
		assert_int(slot.kart.color_index).is_equal(slot.color_index)
	assert_int(match_node.rules.team_target()).is_equal(match_node.rules.target_score)


## The lobby's teams are the ones played, a rematch keeps them, and somebody joining fresh goes
## to the smallest.
func test_teams_hold_through_a_rematch_and_a_joiner_takes_the_smallest() -> void:
	var dealt: Array[int] = [1, 1, 0]
	var match_node := _start(2, 3, dealt, true)
	assert_array(_teams_of(match_node)).is_equal([1, 1, 0])
	match_node.rematch()
	assert_array(_teams_of(match_node)).is_equal([1, 1, 0])
	var joined := match_node.join_network(NetInput.new())
	assert_int(joined.team).is_equal(0)
	assert_int(joined.kart.color_index).is_equal(Teams.color_index(0))


## Somebody coming back from another room sits on the team they had there.
func test_a_player_from_another_machine_keeps_their_team() -> void:
	var match_node := _start(2, 2)
	var joined := match_node.join_network(NetInput.new(), {"team": 1})
	assert_int(joined.team).is_equal(1)
	assert_int(joined.kart.team).is_equal(1)
	assert_int(joined.kart.color_index).is_equal(Teams.color_index(1))


## A player who changes color in team play keeps their team's paint and wears the new color's
## shape on the roof.
func test_a_new_color_in_teams_changes_the_shape_only() -> void:
	var match_node := _start(2, 2)
	var slot := match_node.slots[0]
	var free := SeatIdentity.next_color(match_node, slot)
	SeatIdentity.paint(match_node, slot, free)
	assert_int(slot.color_index).is_equal(free)
	assert_int(slot.kart.color_index).is_equal(Teams.color_index(slot.team))
	assert_int(KartVisuals.shape_of(slot.kart)).is_equal(free)


## A client hears every seat's team, and paints and shapes its karts as the host does.
func test_a_client_sees_the_teams() -> void:
	var host := _start(2, 4)
	var data: Dictionary = bytes_to_var(var_to_bytes(host.build_snapshot()))
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = _rules(2)
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	client.apply_snapshot(data)
	for i: int in host.slots.size():
		var theirs := host.slots[i]
		var ours := client.slots[i]
		assert_int(ours.team).is_equal(theirs.team)
		assert_int(ours.kart.team).is_equal(theirs.kart.team)
		assert_int(ours.kart.color_index).is_equal(theirs.kart.color_index)
		assert_int(KartVisuals.shape_of(ours.kart)).is_equal(KartVisuals.shape_of(theirs.kart))


## The teams ranked by what their karts banked between them, then kills, then fewest deaths.
func test_teams_are_ranked_by_their_bank() -> void:
	var match_node := _start(2, 4)
	var slots := match_node.slots
	slots[0].banked = 500
	slots[2].banked = 400
	slots[1].banked = 1000
	assert_int(Teams.bank(slots, 0)).is_equal(900)
	assert_int(Teams.bank(slots, 1)).is_equal(1000)
	assert_array(Teams.standings(slots)).is_equal([1, 0])
	slots[3].banked = -100
	slots[0].kills = 2
	assert_array(Teams.standings(slots)).is_equal([0, 1])
	assert_int(Teams.members(slots, 1).size()).is_equal(2)
	assert_int(Teams.biggest(slots)).is_equal(2)
