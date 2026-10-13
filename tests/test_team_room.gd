extends GdUnitTestSuite
## Choosing a side in the waiting room, GAME.md 3.14 and 9.6: driving onto another team's mat and
## stopping there, or the switch's team button, here and asked of the host; a seat sitting down on
## the smallest team, in its corner; the teams kept as the host changes how many there are; and the
## ticket saying how they stand.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")

var _runner: GdUnitSceneRunner
var _corners: TeamCorners
var _joined: Array = []


## A room in [param teams] teams with [param people] players from other machines in it, on the
## teams [param dealt] says.
func _room(teams: int, people: int, dealt: Array[int] = []) -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = RULES.duplicate()
	match_node.rules.teams = teams
	match_node.rules.max_players = 8
	match_node.arena_layout = LAYOUT
	match_node.with_hud = false
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = []
	for i: int in people:
		inputs.append(NetInput.new())
	match_node.start(inputs, 3, [], [], [], dealt)
	_corners = TeamCorners.add_to(match_node)
	await _runner.simulate_frames(6, 17)
	return match_node


func _park(kart: Kart, at: Vector3) -> void:
	kart.global_position = at
	kart.motor.velocity = Vector3.ZERO
	kart.velocity = Vector3.ZERO


func _note_joined(slot: int, team: int) -> void:
	_joined.append([slot, team])


## Standing still on another team's mat for two thirds of a second moves a player to it, with the
## cash-out ring filling round them meanwhile.
func test_standing_on_another_teams_mat_moves_a_player() -> void:
	var match_node: Match = await _room(2, 2, [0, 1])
	var slot := match_node.slots[0]
	_park(slot.kart, _corners.corner(1))
	await _runner.simulate_frames(20, 17)
	assert_int(slot.team).is_equal(0)
	assert_float(slot.kart.channel_progress).is_greater(0.0)
	await _runner.simulate_frames(40, 17)
	assert_int(slot.team).is_equal(1)
	assert_int(slot.kart.color_index).is_equal(Teams.color_index(1))
	assert_float(slot.kart.channel_progress).is_equal(-1.0)


## Driving off before it is full moves nobody, and a player's own team's mat does nothing.
func test_passing_over_a_mat_moves_nobody() -> void:
	var match_node: Match = await _room(2, 2, [0, 1])
	var slot := match_node.slots[0]
	_park(slot.kart, _corners.corner(1))
	await _runner.simulate_frames(20, 17)
	_park(slot.kart, Vector3.ZERO)
	await _runner.simulate_frames(40, 17)
	assert_int(slot.team).is_equal(0)
	assert_float(slot.kart.channel_progress).is_equal(-1.0)
	_park(slot.kart, _corners.corner(0))
	await _runner.simulate_frames(60, 17)
	assert_int(slot.team).is_equal(0)
	assert_float(slot.kart.channel_progress).is_equal(-1.0)


## The switch's team button goes round the teams, and says so for the puff on every screen; a
## client's ask comes over the color's message.
func test_the_switch_goes_round_the_teams() -> void:
	var match_node: Match = await _room(3, 1)
	var slot := match_node.slots[0]
	assert_int(slot.team).is_equal(0)
	_joined.clear()
	Events.team_joined.connect(_note_joined)
	SeatIdentity.next_team(match_node, slot)
	assert_int(slot.team).is_equal(1)
	SeatIdentity.next_team(match_node, slot)
	SeatIdentity.next_team(match_node, slot)
	assert_int(slot.team).is_equal(0)
	SeatIdentity.claim(match_node, slot, SeatIdentity.TEAM_CLAIM + 2)
	Events.team_joined.disconnect(_note_joined)
	assert_int(slot.team).is_equal(2)
	assert_array(_joined).has_size(4)
	assert_array(_joined[3]).is_equal([0, 2])
	SeatIdentity.claim(match_node, slot, SeatIdentity.TEAM_CLAIM + 5)
	assert_int(slot.team).is_equal(2)


## Somebody sitting down goes to the smallest team and comes in at its corner, beside the mat.
func test_a_seat_sitting_down_comes_in_at_its_corner() -> void:
	var match_node: Match = await _room(2, 2, [0, 0])
	var joined := match_node.join_network(NetInput.new())
	assert_int(joined.team).is_equal(1)
	var corner := _corners.corner(1)
	assert_float(absf(joined.kart.global_position.x - corner.x)).is_less(0.01)
	assert_int(_corners.mat_under(joined.kart.global_position)).is_equal(-1)
	assert_float(joined.kart.global_position.distance_to(corner)).is_less(TeamCorners.MAT * 2.0)


## An emptied seat is on no team, and whoever sits down in it goes to the smallest.
func test_an_emptied_seat_counts_for_no_team() -> void:
	var match_node: Match = await _room(2, 3, [0, 1, 1])
	VacantSeat.leave(match_node, match_node.slots[2])
	assert_int(match_node.slots[2].team).is_equal(-1)
	assert_array(Teams.sizes(match_node.slots, 2)).is_equal([1, 1])
	match_node.slots[0].team = 1
	var joined := match_node.join_network(NetInput.new())
	assert_int(joined.index).is_equal(2)
	assert_int(joined.team).is_equal(0)


## The host turning the teams down keeps everybody it can on their team and seats the rest on the
## smallest; turning them off leaves everybody on none, in their own colors again.
func test_fewer_teams_keep_who_they_can() -> void:
	var match_node: Match = await _room(4, 4, [0, 1, 2, 3])
	match_node.rules.teams = 2
	TeamCorners.reseat(match_node)
	var teams: Array[int] = []
	for slot: PlayerSlot in match_node.slots:
		teams.append(slot.team)
	assert_array(teams).is_equal([0, 1, 0, 1])
	match_node.rules.teams = 0
	TeamCorners.reseat(match_node)
	for slot: PlayerSlot in match_node.slots:
		assert_int(slot.team).is_equal(-1)
		assert_int(slot.kart.color_index).is_equal(slot.color_index)


## The ticket says how the teams stand and the team's target.
func test_the_ticket_says_how_the_teams_stand() -> void:
	var config := MatchConfig.new()
	config.target_score = 3000
	config.teams = 2
	var sizes: Array[int] = [2, 1]
	var said := MatchOptions.describe(config, sizes)
	assert_str(said).contains("first to 6000")
	assert_str(said).contains("2 v 1")
	assert_str(MatchOptions.describe(config)).contains("2 teams")


## A client hears how many teams the room has, and draws a mat for each.
func test_a_client_hears_how_many_teams() -> void:
	var host: Match = await _room(3, 2)
	var client: Match = auto_free(MATCH_SCENE.instantiate())
	client.rules = RULES.duplicate()
	client.arena_layout = LAYOUT
	client.with_hud = false
	add_child(client)
	client.start_puppet()
	var corners := TeamCorners.add_to(client)
	client.apply_snapshot(bytes_to_var(var_to_bytes(host.build_snapshot())))
	assert_int(client.rules.teams).is_equal(3)
	corners._process(0.0)
	assert_int(corners.get_child_count()).is_equal(3)
