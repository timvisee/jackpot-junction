extends GdUnitTestSuite
## The room everybody waits in before a match, GAME.md 9.6. Nothing is scored in here: what the
## room is for is saying you are ready, which is said by driving onto the pad in the middle of it
## and staying there.

const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")
## A port of this suite's own for the host's room, clear of the ones the other network suites use.
const HOST_PORT := 7795

var _runner: GdUnitSceneRunner
## The player's own settings, put aside while a test that saves them runs on a scratch copy.
var _settings_were: Settings


## The room reads the configuration it was opened with off [Game], which is a global: a test that
## left one behind would be handing its own settings to whatever opened a room next.
func before_test() -> void:
	Game.pending_config = MatchConfig.new()


func after_test() -> void:
	Game.pending_config = null
	get_tree().paused = false
	Net.close()
	if _settings_were != null:
		Game.settings = _settings_were
		_settings_were = null


## Hosts a room, on settings of the test's own: closing the host's choices saves them, and a test
## that saved into the player's real settings would be deciding their next match for them.
func _host() -> Node3D:
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_waiting_host.cfg"
	Game.pending_config.online = "host"
	Game.pending_config.port = HOST_PORT
	return await _open()


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


## The sign that says how many are ready stands on top of the back wall, over the middle of it:
## inside the shot of a camera holding the whole room, and off the floor the karts drive on. It
## says the count on a line of its own, over what it is counting.
func test_the_ready_sign_stands_on_the_back_wall() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var stand: ReadyStand = match_node.arena.get_node("ReadyStand")
	var layout := match_node.arena.layout
	var half := match_node.arena.world_size() * 0.5
	assert_float(stand.global_position.y).is_equal_approx(layout.wall_height, 0.001)
	assert_float(stand.global_position.x).is_equal_approx(0.0, 0.001)
	assert_float(stand.global_position.z).is_less(-(half.y - layout.cell_size))
	assert_float(stand.global_position.z).is_greater(-half.y)
	assert_float(ReadyStand.height()).is_less(2.0)
	# Leaning back, toward the camera over the room, rather than down at the floor.
	assert_float(stand.face.global_basis.z.y).is_greater(0.3)
	assert_str(stand._count.text).is_equal("0 / 1")
	assert_str(stand._words.text).is_equal("PLAYERS READY")


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


## Parks the one player on the pad and runs frames until the room is full, a frame at a time so
## the test knows the moment it filled rather than landing somewhere in the second after it.
func _fill(room: Node3D) -> ReadyRoom:
	var match_node: Match = room.get_node("Match")
	var ready_room: ReadyRoom = room.ready_room
	match_node.kart_of(0).global_position = match_node.arena.junction.global_position
	for i: int in 400:
		if ready_room.all_ready():
			break
		await _runner.simulate_frames(1, 17)
	assert_bool(ready_room.all_ready()).is_true()
	return ready_room


## A full house turns the whole ring green and holds it, and the room goes a second later, not
## the moment the last player readies: the room says it is going before it goes.
func test_a_full_room_turns_green_and_goes_a_second_later() -> void:
	var room := await _open()
	var went := {"count": 0}
	room.ready_room.everybody_ready.connect(func() -> void: went["count"] += 1)
	var ready_room: ReadyRoom = await _fill(room)
	for wait: int in [2, 30]:
		await _runner.simulate_frames(wait, 17)
		assert_bool(ready_room.all_green()).is_true()
		for piece: MeshInstance3D in ready_room._segments:
			var glow := (piece.material_override as StandardMaterial3D).emission
			assert_bool(glow.is_equal_approx(ReadyRoom.READY_INK)).is_true()
		assert_int(went["count"]).is_equal(0)
	await _runner.simulate_frames(40, 17)
	assert_int(went["count"]).is_equal(1)
	# And only once, however long the room stands full afterwards.
	await _runner.simulate_frames(30, 17)
	assert_int(went["count"]).is_equal(1)


## Rolling off the pad in the second before the room goes calls it off. Ready lasts as long as the
## standing does, in the last second as much as in any other.
func test_driving_off_in_the_last_second_calls_it_off() -> void:
	var room := await _open()
	var went := {"count": 0}
	room.ready_room.everybody_ready.connect(func() -> void: went["count"] += 1)
	var ready_room: ReadyRoom = await _fill(room)
	await _runner.simulate_frames(20, 17)
	room.get_node("Match").kart_of(0).global_position = Vector3(10.0, 0.0, 6.0)
	await _runner.simulate_frames(90, 17)
	assert_int(went["count"]).is_equal(0)
	assert_bool(ready_room.all_ready()).is_false()
	assert_bool(ready_room.all_green()).is_false()


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
		var seat: HBoxContainer = null
		for line: Node in hints.get_children():
			if line is HBoxContainer:
				seat = line
		var captions: Array[String] = []
		for part: Node in seat.get_children():
			if part is InputGlyph:
				captions.append((part as InputGlyph).caption)
		assert_int(captions.size()).is_equal(2)
		assert_str(captions[0]).is_equal("J")
		assert_str(captions[1]).is_not_equal("J")
	Game.last_input_keyboard = was


## Somebody who took a seat in the room goes through to the arena with everybody else, as who
## they were in the room: the same device, colour, name and dress.
func test_a_seat_taken_in_the_room_goes_through_to_the_arena() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var second := match_node.join_human(DeviceInput.KEYBOARD + 1)
	assert_object(second).is_not_null()
	var config: MatchConfig = room.arena_config()
	assert_int(config.human_devices.size()).is_equal(2)
	assert_int(config.human_devices[1]).is_equal(DeviceInput.KEYBOARD + 1)
	assert_int(config.human_colors[1]).is_equal(second.color_index)
	assert_str(config.human_names[1]).is_equal(second.player_name)
	assert_array(config.human_styles[1]).is_equal(second.style.to_array())
	assert_int(config.inputs().size()).is_equal(2 + config.bot_count)


## The host chooses the match first thing, with their kart waiting while they do, and the room
## says what was chosen once they are done.
func test_the_host_chooses_the_match_on_opening_the_room() -> void:
	var room := await _host()
	var match_node: Match = room.get_node("Match")
	var pane: HostSettings = room.host_settings
	assert_bool(pane.is_open()).is_true()
	assert_bool(match_node.kart_of(0).frozen).is_true()
	assert_bool(room.ready_room.held).is_true()
	assert_str(room.ready_room._plan.text).is_equal("The host is choosing the match")
	pane.options.mode_option.selected = 1
	pane.options.map_option.selected = 1
	pane.options.bots_option.selected = 1
	pane.options.minutes_option.selected = MatchOptions.match_lengths().find(8)
	pane.close()
	await _runner.simulate_frames(2, 17)
	assert_bool(match_node.kart_of(0).frozen).is_false()
	assert_bool(room.ready_room.held).is_false()
	var config: MatchConfig = room.arena_config()
	assert_str(String(config.map)).is_equal(String(ArenaMaps.IDS[1]))
	assert_int(config.bot_count).is_equal(1)
	assert_float(config.duration).is_equal(480.0)
	assert_str(room.ready_room._plan.text).contains(ArenaMaps.NAMES[1])
	assert_str(room.ready_room._plan.text).contains("1 bot")
	# Kept for next time, the way the lobby keeps what it was last set to.
	assert_int(Game.settings.bot_count).is_equal(1)
	assert_str(Game.settings.map).is_equal(String(ArenaMaps.IDS[1]))


## Back from a match with everybody still connected, the host's room takes over the connection
## that is already open rather than opening another, and puts the match settings up again: the
## next match is chosen here, the same as the first one was.
func test_the_host_comes_back_to_the_room_on_the_same_connection() -> void:
	var open := Net.open(null)
	assert_int(open.host(HOST_PORT)).is_equal(OK)
	var room := await _host()
	assert_object(Net.session).is_same(open)
	assert_object(room.session).is_same(open)
	assert_object(open.match_node).is_same(room.get_node("Match"))
	assert_bool(room.host_settings.is_open()).is_true()


## The host can choose a Grand Prix instead, GAME.md 9.7: how many maps rather than which, and
## the maps are dealt when the room goes, the first of them being the one the room goes to.
func test_the_host_can_choose_a_grand_prix() -> void:
	var room := await _host()
	var pane: HostSettings = room.host_settings
	pane.options.mode_option.selected = 0
	pane.options.maps_option.selected = MatchOptions.MAPS.find(4)
	pane.close()
	await _runner.simulate_frames(2, 17)
	assert_str(room.ready_room._plan.text).contains("Match of 4 maps")
	var first: MatchConfig = room.first_map_config()
	assert_object(Game.grand_prix).is_not_null()
	assert_int(Game.grand_prix.playlist.size()).is_equal(4)
	assert_str(String(first.map)).is_equal(String(Game.grand_prix.playlist[0]))
	# The bots for the whole run are dealt now too, one for every seat nobody here is in.
	assert_int(Game.grand_prix.bots.size()).is_equal(first.network_seats + first.bot_count)
	Game.grand_prix = null


## A single map deals no Grand Prix, and clears one left over from before.
func test_a_single_map_is_not_a_grand_prix() -> void:
	var room := await _open()
	Game.grand_prix = GrandPrix.start(3, RandomNumberGenerator.new())
	room.config.rounds = 0
	room.first_map_config()
	assert_object(Game.grand_prix).is_null()


## And the host can open it again from the pause menu, which only the host's has.
func test_the_host_opens_the_choosing_again_from_the_pause_menu() -> void:
	var room := await _host()
	room.host_settings.close()
	var menu: PauseMenu = room.get_node("PauseMenu")
	var entry: Button = null
	for button: Node in menu.find_children("*", "Button", true, false):
		if (button as Button).text == "Match settings":
			entry = button
	assert_object(entry).override_failure_message("no Match settings in the menu").is_not_null()
	entry.pressed.emit()
	assert_bool(room.host_settings.is_open()).is_true()
	assert_bool(room.ready_room.held).is_true()


## Nobody but a host is asked. A room that is not hosting has nothing to choose and no entry for it.
func test_only_the_host_is_asked() -> void:
	var room := await _open()
	assert_object(room.host_settings).is_null()
	var menu: PauseMenu = room.get_node("PauseMenu")
	for button: Node in menu.find_children("*", "Button", true, false):
		assert_str((button as Button).text).is_not_equal("Match settings")


## A full room does not go while the host is choosing, and goes once they are done.
func test_a_full_room_waits_for_the_host_to_finish_choosing() -> void:
	var room := await _host()
	var went := {"count": 0}
	room.ready_room.everybody_ready.connect(func() -> void: went["count"] += 1)
	var ready_room: ReadyRoom = await _fill(room)
	await _runner.simulate_frames(90, 17)
	assert_int(went["count"]).is_equal(0)
	assert_bool(ready_room.all_green()).is_false()
	room.host_settings.close()
	await _runner.simulate_frames(90, 17)
	assert_int(went["count"]).is_equal(1)


## The bots the host asks for are on top of everybody here, as many as the arena has seats left.
func test_the_bots_fill_the_seats_nobody_is_in() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	room.config.bot_count = 3
	assert_int(room.arena_config().bot_count).is_equal(3)
	match_node.join_human(DeviceInput.KEYBOARD + 1)
	room.config.bot_count = 3
	var config: MatchConfig = room.arena_config()
	assert_int(config.bot_count).is_equal(2)
	assert_int(config.inputs().size()).is_equal(room.ARENA_RULES.max_players)


## A client keeps the colour it had in the room: the arena keeps its seat in that colour, in the
## order the host will seat the clients again.
func test_a_client_keeps_its_colour_into_the_arena() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var visitor := match_node.join_network(NetInput.new())
	visitor.color_index = 3
	var session: NetSession = auto_free(NetSession.new())
	session._peer_slots[7] = visitor.index
	room.session = session
	var config: MatchConfig = room.arena_config()
	room.session = null
	assert_int(config.network_seats).is_equal(1)
	assert_array(config.network_colors).contains_exactly([3])
	assert_int(config.colors()[config.human_devices.size()]).is_equal(3)


## And the room holds no more people than the arena can seat, so nobody who got in is left
## standing when the match begins.
func test_the_room_holds_as_many_as_the_arena_seats() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	assert_int(match_node.rules.max_players).is_equal(room.ARENA_RULES.max_players)


## How many blocks of the ring are lit in [param slot]'s colour.
func _lit_for(ready_room: ReadyRoom, slot: PlayerSlot) -> int:
	var lit := 0
	for piece: MeshInstance3D in ready_room._segments:
		var ink := (piece.material_override as StandardMaterial3D).albedo_color
		if ink.is_equal_approx(slot.color()):
			lit += 1
	return lit


## A client fills its ring off the karts it can see, so the arcs move on every screen and not only
## on the host's. Who is ready is still the host's word: the arc stops one block short of full,
## and no tick goes up, until the host says so.
func test_a_client_fills_the_ring_and_waits_for_the_host_to_call_it() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ready_room: ReadyRoom = room.ready_room
	ready_room.deciding = false
	# Somebody else in the room who stays off the pad, so it never fills and the arcs are read
	# as arcs rather than as the whole ring going green.
	match_node.join_human(DeviceInput.KEYBOARD + 1)
	await _runner.simulate_frames(2, 17)
	var arc := ReadyRoom.SEGMENTS / 2
	var slot: PlayerSlot = match_node.slots[0]
	match_node.kart_of(0).global_position = match_node.arena.junction.global_position
	await _runner.simulate_frames(int(ReadyRoom.CHARGE_TIME * 30.0), 17)
	var part_way := _lit_for(ready_room, slot)
	assert_int(part_way).is_greater(0)
	assert_int(part_way).is_less(arc)
	# Long past the charge time, and still not called: one short, no tick, nobody ready.
	await _runner.simulate_frames(int(ReadyRoom.CHARGE_TIME * 80.0), 17)
	assert_int(_lit_for(ready_room, slot)).is_equal(arc - 1)
	assert_int(ready_room.ready_count()).is_equal(0)
	assert_bool(ready_room._ticks.has(0)).is_false()
	# The host calls it: the arc is whole and the tick goes up.
	Events.player_ready.emit(0, true)
	await _runner.simulate_frames(2, 17)
	assert_int(_lit_for(ready_room, slot)).is_equal(arc)
	assert_bool(ready_room._ticks.has(0)).is_true()
	assert_bool(ready_room.all_green()).is_false()


## Presses and lets go of Start on [param pad], the way a hand on a real pad does.
func _press_start(pad: int) -> void:
	for down: bool in [true, false]:
		var event := InputEventJoypadButton.new()
		event.device = pad
		event.button_index = JOY_BUTTON_START
		event.pressed = down
		Input.parse_input_event(event)
		await _runner.simulate_frames(2, 17)


## A pad nobody is driving takes a seat with Start, as the line under the count says, and the
## pause menu does not open on the same press. The pad somebody is driving pauses with it.
func test_start_on_a_new_pad_takes_a_seat_and_on_a_seated_one_pauses() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var menu: PauseMenu = room.get_node("PauseMenu")
	await _press_start(1)
	assert_int(match_node.slots.size()).is_equal(2)
	assert_bool(match_node.slots[1].plays_on(1)).is_true()
	assert_bool(menu._panel.visible).is_false()
	await _press_start(1)
	assert_int(match_node.slots.size()).is_equal(2)
	assert_bool(menu._panel.visible).is_true()
	menu.set_paused(false)


## Somebody who came in on any device and has been driving with a pad is playing on that pad:
## their Start pauses, rather than seating a second player on it beside them.
func test_the_any_device_player_pauses_with_the_pad_they_drive() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var menu: PauseMenu = room.get_node("PauseMenu")
	(match_node.slots[0].input as PlayerInput).last_device = 0
	await _press_start(0)
	assert_int(match_node.slots.size()).is_equal(1)
	assert_bool(menu._panel.visible).is_true()
	menu.set_paused(false)


## There is a football on the floor, in front of the pad, touching nothing but walls and props: no
## kart runs into it as into a wall, and it never stands anybody on the pad.
func test_the_room_has_a_ball_on_the_floor() -> void:
	var room := await _open()
	var ball: RoomBall = room.ball
	assert_object(ball).is_not_null()
	assert_float(ball.global_position.y).is_equal_approx(RoomBall.RADIUS, 0.01)
	(
		assert_float(
			ball.global_position.distance_to(room.BALL_SPOT + Vector3.UP * RoomBall.RADIUS)
		)
		. is_less(0.1)
	)
	assert_int(ball.collision_layer).is_equal(0)
	assert_int(ball.collision_mask).is_equal(Layers.WORLD)


## A kart driven into the ball kicks it on ahead of it, and goes on itself: the kart is the heavy
## thing, and the ball is what gets out of the way.
func test_a_kart_driving_into_the_ball_kicks_it() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ball: RoomBall = room.ball
	var kart := match_node.kart_of(0)
	var start := ball.global_position
	kart.global_position = Vector3(start.x - 4.0, 0.0, start.z)
	kart.face(Vector3.RIGHT)
	var driver := KartInput.new()
	driver.throttle = 1.0
	kart.input = driver
	await _runner.simulate_frames(60, 17)
	assert_float(ball.global_position.x - start.x).is_greater(1.0)
	assert_float(ball.linear_velocity.x).is_greater(0.5)
	assert_float(kart.global_position.x).is_greater(start.x - 4.0 + 2.0)
	assert_float(ball.global_position.y).is_equal_approx(RoomBall.RADIUS, 0.01)


## However hard it is sent, it stays on the floor and inside the room: no height to go up into,
## and walls that throw it back.
func test_the_ball_never_leaves_the_floor_or_the_room() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ball: RoomBall = room.ball
	var half := match_node.arena.world_size() * 0.5
	for heading: Vector3 in [Vector3(0, 0, -1), Vector3(1, 0, 0.6), Vector3(-1, 0.8, 1)]:
		ball.linear_velocity = heading.normalized() * RoomBall.MAX_SPEED
		for i: int in 180:
			await _runner.simulate_frames(1, 17)
			var at := ball.global_position
			assert_float(at.y).is_equal_approx(RoomBall.RADIUS, 0.01)
			assert_float(absf(at.x)).is_less(half.x)
			assert_float(absf(at.z)).is_less(half.y)


## A client does not kick the ball, it is told where it is, and draws it there.
func test_a_client_draws_the_ball_where_it_was_told() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var told := RoomBall.add_to(match_node, Vector3(-6.0, 0.0, 3.0), false)
	await _runner.simulate_frames(2, 17)
	assert_bool(told.freeze).is_true()
	told.follow([4.0, -2.0, 0.0, 0.0])
	await _runner.simulate_frames(30, 17)
	assert_float(told.global_position.distance_to(Vector3(4.0, RoomBall.RADIUS, -2.0))).is_less(0.1)


## An empty room is not a ready room: a match with nobody in it has nothing to start.
func test_a_room_with_nobody_in_it_is_never_ready() -> void:
	var room := await _open()
	var ready_room: ReadyRoom = room.ready_room
	ready_room.match_node.slots.clear()
	assert_int(ready_room.player_count()).is_equal(0)
	assert_bool(ready_room.all_ready()).is_false()
