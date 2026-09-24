extends GdUnitTestSuite
## A seat somebody got up from in the waiting room online, GAME.md 9.6: emptied rather than handed
## to a bot, its kart out of the room until somebody new sits down in it.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/waiting_room.tres")
const RULES: MatchRules = preload("res://data/match/waiting_room.tres")

var _runner: GdUnitSceneRunner


func _room(rules: MatchRules = RULES) -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = rules
	match_node.arena_layout = LAYOUT
	match_node.with_hud = false
	_runner = scene_runner(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, 0), NetInput.new()]
	match_node.start(inputs, 3)
	return match_node


func test_an_emptied_seat_has_no_kart_in_the_room_until_somebody_sits_in_it() -> void:
	var match_node := _room()
	await _runner.simulate_frames(5, 17)
	var slot := match_node.slots[1]
	var kart := slot.kart
	var left := [-1]
	var heard := func(index: int) -> void: left[0] = index
	Events.player_left.connect(heard)
	VacantSeat.leave(match_node, slot)
	Events.player_left.disconnect(heard)
	assert_int(left[0]).is_equal(1)
	assert_bool(slot.is_human()).is_false()
	assert_object(kart.get_node_or_null("Brain")).is_null()
	assert_bool(kart.alive).is_false()
	assert_bool((kart.get_node("Body") as Node3D).visible).is_false()
	assert_int(kart.collision_layer).is_equal(0)
	assert_bool(match_node.camera_rig.targets.has(kart)).is_false()
	# Nothing counted it as a death, and it does not come back by itself.
	assert_int(slot.deaths).is_equal(0)
	await _runner.simulate_frames(30, 17)
	assert_bool(kart.alive).is_false()
	# Somebody new sits down in it, and it is back in the room for them.
	var taken := match_node.join_network(NetInput.new())
	assert_object(taken).is_same(slot)
	await _runner.simulate_frames(3, 17)
	assert_bool(slot.is_human()).is_true()
	assert_bool(kart.alive).is_true()
	assert_bool(match_node.camera_rig.targets.has(kart)).is_true()


## Its color is nobody's while it is empty; whoever sits down next is put in a free one.
func test_an_emptied_seats_color_is_free_to_take() -> void:
	var match_node := _room()
	await _runner.simulate_frames(5, 17)
	var mine := match_node.slots[0]
	var empty := match_node.slots[1]
	VacantSeat.leave(match_node, empty)
	SeatIdentity.paint(match_node, mine, empty.color_index)
	assert_int(mine.color_index).is_equal(1)
	match_node.join_network(NetInput.new())
	assert_int(empty.color_index).is_not_equal(1)


## The host empties the seat of somebody leaving the waiting room, and hands the seat of somebody
## leaving a match to a bot, which keeps their score going.
func test_the_host_empties_a_seat_in_the_room_and_hands_one_in_a_match_to_a_bot() -> void:
	for timed: bool in [false, true]:
		var rules: MatchRules = RULES.duplicate()
		rules.timed = timed
		var match_node := _room(rules)
		await _runner.simulate_frames(3, 17)
		var session: NetSession = auto_free(NetSession.new())
		add_child(session)
		session.is_host = true
		session.match_node = match_node
		session._peer_slots[7] = 1
		session._on_peer_disconnected(7)
		var input := match_node.slots[1].input
		assert_bool(input is VacantSeat).is_equal(not timed)
		assert_bool(input is BotInput).is_equal(timed)
