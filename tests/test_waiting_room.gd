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
	assert_int(match_node.arena.targets.size()).is_equal(0)
	assert_object(match_node.arena.junction).is_not_null()
	# And it has the things to drive round that are the only reason to drive in here: three
	# standing props and one box, which comes back quickly because it is there to be driven round
	# rather than to be hidden behind.
	var props: Node3D = match_node.arena.get_node("WaitingProps")
	assert_int(props.get_child_count()).is_equal(3)
	assert_int(match_node.arena.crates.size()).is_equal(1)
	assert_float(match_node.arena.crates[0].respawn_delay).is_less(10.0)


## The box and the drum stand opposite one another on the same side of the room, which is what
## makes a figure eight round the pair of them possible: two marks a few lengths apart with a
## clear run between and clear floor to swing round the outside of each.
func test_the_box_and_the_drum_are_a_pair_to_weave_between() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var box := match_node.arena.crates[0].global_position
	var drum: Node3D = match_node.arena.get_node("WaitingProps/Drum")
	assert_float(absf(box.x - drum.global_position.x)).is_less(1.0)
	var apart := absf(box.z - drum.global_position.z)
	assert_float(apart).is_greater(4.0)
	assert_float(apart).is_less(9.0)
	# Both to one side of the pad, so the weave is not run through the middle of the room where
	# everybody else is trying to park.
	assert_float(absf(box.x)).is_greater(5.0)
	assert_float(signf(box.x)).is_equal(signf(drum.global_position.x))


## The sign that says how many are ready is a low stand on the floor at the back of the room,
## where a camera holding the whole room holds it too. A hoarding over a crowd stood outside the
## shot, and one behind the wall competed with the benches and chests along it.
func test_the_ready_sign_is_a_low_stand_inside_the_room() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var stand: ReadyStand = match_node.arena.get_node("ReadyStand")
	assert_float(stand.global_position.y + ReadyStand.LIFT + ReadyStand.FACE.y).is_less(2.0)
	# On the floor, against the back wall, and clear of the pad in the middle.
	var half := match_node.arena.world_size() * 0.5
	assert_float(absf(stand.global_position.z)).is_less(half.y)
	assert_float(half.y - absf(stand.global_position.z)).is_less(3.0)
	assert_float(stand.global_position.z).is_less(0.0)
	# Solid, like the drum and the wheels: a kart driving through the room's own sign is worse
	# than one bouncing off it.
	var solid: StaticBody3D = stand.get_node("Solid")
	assert_int(solid.collision_layer).is_equal(Layers.WORLD)


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


## Two people charging the pad are two arcs of the ring, each in their own colour, rather than one
## bar showing whichever of them is furthest along. A room of four otherwise cannot tell who the
## pad has taken and who it is still waiting on.
func test_each_player_charges_their_own_arc_of_the_ring() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ready_room: ReadyRoom = room.ready_room
	match_node.join_human(DeviceInput.KEYBOARD + 1)
	await _runner.simulate_frames(5, 17)
	assert_int(ready_room.player_count()).is_equal(2)
	# Only the second player drives on. Half the ring lights, in that player's colour, and the
	# other half stays dark.
	match_node.kart_of(1).global_position = match_node.arena.junction.global_position
	await _runner.simulate_frames(int(ReadyRoom.CHARGE_TIME * 80.0), 17)
	assert_float(ready_room.charge[0]).is_equal(0.0)
	assert_bool(ready_room.ready_slots.get(1, false)).is_true()
	var theirs := match_node.slots[1].color()
	var lit := 0
	for piece: MeshInstance3D in ready_room._segments:
		var ink := (piece.material_override as StandardMaterial3D).albedo_color
		if ink.is_equal_approx(theirs):
			lit += 1
		else:
			assert_bool(ink.is_equal_approx(ReadyRoom.WAITING_INK)).is_true()
	assert_int(lit).is_equal(ReadyRoom.SEGMENTS / 2)


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


## Dying in here costs nothing and takes no time. There is no run to build, so there is no hand
## of cards to pick from, and no reason to sit out a wait for a kart that was only messing about.
func test_dying_in_the_room_brings_you_straight_back_with_no_cards() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var slot: PlayerSlot = match_node.slots[0]
	match_node.kart_of(0).die(&"pit", -1)
	assert_object(slot.offer).override_failure_message("a joker was offered").is_null()
	assert_float(slot.respawn_left).is_equal(0.0)
	await _runner.simulate_frames(5, 17)
	assert_bool(match_node.kart_of(0).alive).is_true()


## The line saying how to take a seat draws both buttons, the key and the pad's, whichever this
## machine was last touched with: the player it is for has not touched anything yet.
func test_the_seat_hint_shows_the_key_and_the_pad_button() -> void:
	var was := Game.last_input_keyboard
	for keyboard: bool in [true, false]:
		Game.last_input_keyboard = keyboard
		var room := await _open()
		var hints: VBoxContainer = room.ready_room._hints
		var seat := hints.get_child(1) as HBoxContainer
		var captions: Array[String] = []
		for part: Node in seat.get_children():
			if part is InputGlyph:
				captions.append((part as InputGlyph).caption)
		assert_int(captions.size()).is_equal(2)
		assert_str(captions[0]).is_equal("J")
		assert_str(captions[1]).is_not_equal("J")
	Game.last_input_keyboard = was


## An empty room is not a ready room: a match with nobody in it has nothing to start.
func test_a_room_with_nobody_in_it_is_never_ready() -> void:
	var room := await _open()
	var ready_room: ReadyRoom = room.ready_room
	ready_room.match_node.slots.clear()
	assert_int(ready_room.player_count()).is_equal(0)
	assert_bool(ready_room.all_ready()).is_false()
