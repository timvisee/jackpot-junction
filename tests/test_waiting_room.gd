extends GdUnitTestSuite
## The room everybody waits in before a match, GAME.md 9.6. Nothing is scored in here: what the
## room is for is saying you are ready, which is said by driving onto the pad in the middle of it
## and staying there.

const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")

var _runner: GdUnitSceneRunner


## The room reads the configuration it was opened with off [Game], which is a global: a test that
## left one behind would be handing its own settings to whatever opened a room next.
func before_test() -> void:
	Game.pending_config = MatchConfig.new()


func after_test() -> void:
	Game.pending_config = null


## A room, with the way out of it unhooked. Readying up in here is the whole subject of this
## suite, and a room left to itself answers a full house by changing the scene to the arena --
## which in a test run means swapping the tree out from under the runner and leaving a match
## ticking away underneath every test that comes after. The handover has its own suite.
func _open() -> Node3D:
	var room: Node3D = auto_free(WAITING_SCENE.instantiate())
	_runner = scene_runner(room)
	await _runner.simulate_frames(20, 17)
	if room.ready_room.everybody_ready.is_connected(room._begin):
		room.ready_room.everybody_ready.disconnect(room._begin)
	return room


## Nothing in here is a match: no clock to run out, nothing to shoot at and nothing to collect.
func test_the_waiting_room_is_not_a_match() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	assert_bool(match_node.rules.timed).is_false()
	assert_int(match_node.arena.crates.size()).is_equal(0)
	assert_int(match_node.arena.targets.size()).is_equal(0)
	assert_object(match_node.arena.junction).is_not_null()
	# And it has the three things to drive round that are the only reason to drive in here.
	var props: Node3D = match_node.arena.get_node("WaitingProps")
	assert_int(props.get_child_count()).is_equal(3)


## The props are solid. Clutter everywhere else in the game is scenery a kart drives through;
## these are the ones a kart is meant to drift round, which it cannot do through them.
func test_the_things_in_the_room_are_solid() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var props: Node3D = match_node.arena.get_node("WaitingProps")
	for child: Node in props.get_children():
		var body := child as StaticBody3D
		assert_object(body).override_failure_message("%s is not solid" % child.name).is_not_null()
		assert_int(body.collision_layer).is_equal(Layers.WORLD)
		var shapes := 0
		for part: Node in body.get_children():
			if part is CollisionShape3D:
				shapes += 1
		assert_int(shapes).is_equal(1)


## Standing on the pad charges it and readies the player, and the room says so once everybody is.
func test_standing_on_the_pad_readies_a_player() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ready_room: ReadyRoom = room.ready_room
	assert_int(ready_room.player_count()).is_equal(1)
	assert_int(ready_room.ready_count()).is_equal(0)
	assert_bool(ready_room.all_ready()).is_false()
	var called := monitor_signals(ready_room, false)
	var kart := match_node.kart_of(0)
	kart.global_position = match_node.arena.junction.global_position
	# Part way through: the pad has taken some of it and the player is not ready yet.
	await _runner.simulate_frames(int(ReadyRoom.CHARGE_TIME * 30.0), 17)
	assert_float(ready_room.charge[0]).is_greater(0.2)
	await _runner.simulate_frames(int(ReadyRoom.CHARGE_TIME * 70.0), 17)
	assert_bool(ready_room.ready_slots.get(0, false)).is_true()
	assert_int(ready_room.ready_count()).is_equal(1)
	assert_bool(ready_room.all_ready()).is_true()
	await assert_signal(called).is_emitted("everybody_ready")
	# And a tick is floating over the kart that said so.
	assert_bool(ready_room._ticks.has(0)).is_true()


## Ready lasts as long as the standing does. Driving off the pad takes it back on the spot, along
## with the charge and the tick: a pad nobody is on does not speak for anybody.
func test_ready_is_taken_back_by_driving_off() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ready_room: ReadyRoom = room.ready_room
	var kart := match_node.kart_of(0)
	kart.global_position = match_node.arena.junction.global_position
	await _runner.simulate_frames(int(ReadyRoom.CHARGE_TIME * 80.0), 17)
	assert_bool(ready_room.all_ready()).is_true()
	kart.global_position = Vector3(10.0, 0.0, 6.0)
	await _runner.simulate_frames(10, 17)
	assert_bool(ready_room.all_ready()).is_false()
	assert_int(ready_room.ready_count()).is_equal(0)
	assert_float(ready_room.charge[0]).is_equal(0.0)
	assert_bool(ready_room._ticks.has(0)).is_false()


## An empty room is not a ready room: a match with nobody in it has nothing to start.
func test_a_room_with_nobody_in_it_is_never_ready() -> void:
	var room := await _open()
	var ready_room: ReadyRoom = room.ready_room
	ready_room.match_node.slots.clear()
	assert_int(ready_room.player_count()).is_equal(0)
	assert_bool(ready_room.all_ready()).is_false()
