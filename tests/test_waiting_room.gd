extends GdUnitTestSuite
## The room everybody waits in before a match, GAME.md 9.6. Nothing is scored in here: what the
## room is for is saying you are ready, which is said by driving onto the pad in the middle of it
## and staying there.

const FreePorts := preload("res://tests/free_ports.gd")
const WAITING_SCENE := preload("res://scenes/waiting/waiting_room.tscn")
const ARENA_RULES: MatchRules = preload("res://data/match/default.tres")
## A block of free ports of its own for every test, see tests/free_ports.gd.
var port := 0

var _runner: GdUnitSceneRunner
## The player's own settings, put aside while a test that saves them runs on a scratch copy.
var _settings_were: Settings


## The room reads the configuration it was opened with off [Game], which is a global: a test that
## left one behind would be handing its own settings to whatever opened a room next.
##
## A room on one machine puts its match settings up too, GAME.md 9.6, and closing them saves them,
## so every test runs on settings of its own, not the player's.
func before_test() -> void:
	port = FreePorts.take()
	Game.pending_config = MatchConfig.new()
	_settings_were = Game.settings
	Game.settings = Settings.new()
	Game.settings.path = "user://test_waiting_room.cfg"


func after_test() -> void:
	Game.pending_config = null
	get_tree().paused = false
	Net.close()
	if _settings_were != null:
		Settings.remove_files(Game.settings.path)
		Game.settings = _settings_were
		_settings_were = null


## Hosts a room, on settings of the test's own: closing the host's choices saves them, and a test
## that saved into the player's real settings would be deciding their next match for them.
func _host() -> Node3D:
	Game.settings.path = "user://test_waiting_host.cfg"
	Game.pending_config.online = "host"
	Game.pending_config.port = port
	return await _open()


## A room, with the way out of it unhooked. Readying up in here is the whole subject of this
## suite, and a room left to itself answers a full house by changing the scene to the arena --
## which in a test run means swapping the tree out from under the runner and leaving a match
## ticking away underneath every test that comes after. The handover has its own suite.
func _open() -> Node3D:
	var room: Node3D = auto_free(WAITING_SCENE.instantiate())
	_runner = scene_runner(room)
	# Past the loading screen the room is put up behind, GAME.md 8.6.
	await _runner.simulate_frames(45, 17)
	if room.ready_room.everybody_ready.is_connected(room._begin):
		room.ready_room.everybody_ready.disconnect(room._begin)
	# On one machine the match settings come up over the room as it opens, and it waits on them;
	# these tests are about everything after they are put away.
	if Game.pending_config.online == "" and room.host_settings != null:
		room.host_settings.close()
	return room


## Nitro comes back in seconds in here, the way it does in the Garage, GAME.md 9.6: a tank is
## something to play with while waiting, not something to save up for a match that has not begun.
func test_nitro_comes_back_quickly_in_the_room() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var kart := match_node.kart_of(0)
	kart.nitro_charge = 0.0
	await _runner.simulate_frames(90, 17)
	assert_float(kart.nitro_charge).is_greater(0.2)


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
	# And the bots coming in with them, see test_the_count_says_how_many_bots_come_in.
	assert_str(stand._words.text).is_equal("PLAYERS READY" + room.ready_room.bot_words())


## The props are solid. Clutter everywhere else in the game is scenery a kart drives through;
## these are the ones a kart is meant to drift round, which it cannot do through them. The wheels
## stand a cell further from the back wall than their share of the room alone puts them, clear of
## the room along the stalls there.
func test_the_things_in_the_room_are_solid() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var props: Node3D = match_node.arena.get_node("WaitingProps")
	var share := WaitingProps.PLACES[0].y * match_node.arena.world_size().y * 0.5
	var down := share + match_node.arena.grid.cell_size
	assert_float((props.get_node("Wheels") as Node3D).global_position.z).is_equal_approx(down, 0.01)
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


## GAME.md 9.6: the count says how many bots come in with the players, at the top of the screen
## and on the board, so nobody expecting a match of two finds four karts on the grid. As many as
## the host asked for that there are seats left for; nothing while the host has not said.
func test_the_count_says_how_many_bots_come_in() -> void:
	var room := await _open()
	var ready_room: ReadyRoom = room.ready_room
	await _runner.simulate_frames(2, 17)
	# Closing the choosing said the plan, and the bots with it.
	assert_int(ready_room.bots_asked).is_equal(room.config.bot_count)
	ready_room.bots_asked = 3
	await _runner.simulate_frames(2, 17)
	assert_int(ready_room.bots_joining()).is_equal(3)
	assert_str(ready_room._counter.text).is_equal("0 / 1 PLAYERS READY + 3 BOTS")
	assert_str(ready_room._board._words.text).is_equal("PLAYERS READY + 3 BOTS")
	# No more than there are seats for, and one is one bot.
	ready_room.bots_asked = 9
	assert_int(ready_room.bots_joining()).is_equal(ready_room.seats - 1)
	ready_room.bots_asked = 1
	await _runner.simulate_frames(2, 17)
	assert_str(ready_room._counter.text).ends_with("+ 1 BOT")
	# None, or none said, is the plain count.
	for none: int in [0, -1]:
		ready_room.bots_asked = none
		await _runner.simulate_frames(2, 17)
		assert_str(ready_room._counter.text).is_equal("0 / 1 PLAYERS READY")


## GAME.md 9.6: a lobby for two holds two. A third press of join at the host's own machine is
## turned away with a notice saying why, where it used to sit a third player down past the limit
## the door held for everybody knocking from elsewhere, and the line saying how to take a seat
## says there is none left. A device already playing is let through, for its pause button.
func test_a_full_lobby_turns_away_another_seat_and_says_so() -> void:
	var room := await _host()
	var match_node: Match = room.get_node("Match")
	var session: NetSession = room.session
	session.door.max_players = 2
	await _runner.simulate_frames(2, 17)
	var ready_room: ReadyRoom = room.ready_room
	assert_int(ready_room.seat_limit).is_equal(2)
	assert_bool(ready_room._seat_hint.visible).is_true()
	assert_bool(ready_room._full_hint.visible).is_false()
	assert_object(_join(match_node, 5)).is_not_null()
	assert_bool(SeatLimit.full(match_node, session)).is_true()
	assert_bool(SeatLimit.turns_away(room, match_node, session, 6)).is_true()
	var notice := room.get_node("Notice") as NoticePane
	assert_str(notice.said()).contains("Maximum number of players reached")
	assert_str(notice.said()).contains("room for 2 players")
	assert_bool(SeatLimit.turns_away(room, match_node, session, 5)).is_false()
	assert_int(SeatLimit.players(match_node)).is_equal(2)
	await _runner.simulate_frames(2, 17)
	assert_bool(ready_room._seat_hint.visible).is_false()
	assert_bool(ready_room._full_hint.visible).is_true()
	# It goes by itself.
	await _runner.simulate_frames(int(NoticePane.SHOWN_FOR * 60.0) + 10, 17)
	assert_str(notice.said()).is_empty()
	# Made bigger again, there is a seat, and the way to it.
	session.door.max_players = 3
	await _runner.simulate_frames(2, 17)
	assert_bool(SeatLimit.full(match_node, session)).is_false()
	assert_bool(ready_room._seat_hint.visible).is_true()


## Two people charging the pad are two arcs of the ring, each in their own color, rather than one
## bar showing whichever of them is furthest along. A room of four otherwise cannot tell who the
## pad has taken and who it is still waiting on.
func test_each_player_charges_their_own_arc_of_the_ring() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ready_room: ReadyRoom = room.ready_room
	_join(match_node, DeviceInput.KEYBOARD + 1)
	await _runner.simulate_frames(5, 17)
	assert_int(ready_room.player_count()).is_equal(2)
	# Only the second player drives on. Half the ring lights, in that player's color, and the
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
		var seat: HBoxContainer = room.ready_room._seat_hint
		var captions: Array[String] = []
		for part: Node in seat.get_children():
			if part is InputGlyph:
				captions.append((part as InputGlyph).caption)
		assert_int(captions.size()).is_equal(2)
		assert_str(captions[0]).is_equal("J")
		assert_str(captions[1]).is_not_equal("J")
	Game.last_input_keyboard = was


## Somebody who took a seat in the room goes through to the arena with everybody else, as who
## they were in the room: the same device, color, name and dress.
func test_a_seat_taken_in_the_room_goes_through_to_the_arena() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var second := _join(match_node, DeviceInput.KEYBOARD + 1)
	assert_object(second).is_not_null()
	var config: MatchConfig = room.arena_config()
	assert_int(config.human_devices.size()).is_equal(2)
	assert_int(config.human_devices[1]).is_equal(DeviceInput.KEYBOARD + 1)
	assert_int(config.human_colors[1]).is_equal(second.color_index)
	assert_str(config.human_names[1]).is_equal(second.player_name)
	assert_array(config.human_styles[1]).is_equal(second.style.to_array())
	assert_int(config.inputs().size()).is_equal(2 + config.bot_count)


## The host chooses the match first thing, with their kart waiting while they do, and the room
## says what was chosen once they are done. Under any other menu here too, the room's or anything
## else with the cursor on it, the karts sit still and go quiet, and drive again once it is put
## away, GAME.md 9.6.
func test_the_host_chooses_the_match_on_opening_the_room() -> void:
	var room := await _host()
	var match_node: Match = room.get_node("Match")
	var pane: HostSettings = room.host_settings
	assert_bool(pane.is_open()).is_true()
	assert_bool(match_node.kart_of(0).held).is_true()
	assert_bool(room.ready_room.held).is_true()
	assert_str(room.ready_room._plan.text).is_equal("The host is choosing the match")
	# Who may come in first, then the match: Next on the lobby's settings goes on to it.
	assert_bool(pane.on_lobby()).is_true()
	assert_bool(pane._pane.visible).is_false()
	assert_str(pane._lobby._back.text).is_equal("Next")
	pane._lobby._back.pressed.emit()
	assert_bool(pane.on_lobby()).is_false()
	assert_bool(pane._pane.visible).is_true()
	assert_bool(pane.is_open()).is_true()
	# The cursor at the top of the rows, not on Done, which Back is too, its bind drawn on it with
	# keys or a pad in hand.
	var held := get_viewport().gui_get_focus_owner()
	assert_object(held).is_not_null()
	assert_bool(pane._rows.is_ancestor_of(held)).is_true()
	pane._keyboard = true
	pane._pointer = false
	pane._show_bind()
	assert_object(pane._done.get_node_or_null("Bind")).is_not_null()
	pane.options.choose(false)
	pane.options.map_option.selected = 1
	pane.options.bots_option.selected = 1
	pane.options.minutes_option.selected = MatchOptions.match_lengths().find(480)
	pane.close()
	await _runner.simulate_frames(2, 17)
	assert_bool(match_node.kart_of(0).held).is_false()
	assert_bool(room.ready_room.held).is_false()
	var kart := match_node.kart_of(0)
	var menu: PauseMenu = room.get_node("PauseMenu")
	menu.set_paused(true)
	assert_bool(room._menu_up()).is_true()
	menu.set_paused(false)
	await _runner.simulate_frames(30, 17)
	assert_bool(room._menu_up()).is_false()
	var box: Button = auto_free(Button.new())
	add_child(box)
	box.grab_focus()
	await _runner.simulate_frames(2, 17)
	assert_bool(kart.held).is_true()
	assert_bool(kart.is_active()).is_false()
	# Quiet: the engine dies away as it does when the kart is down.
	await _runner.simulate_frames(30, 17)
	assert_float(kart.sound._alive_fade).is_less(0.1)
	box.release_focus()
	await _runner.simulate_frames(2, 17)
	assert_bool(kart.held).is_false()
	assert_bool(kart.is_active()).is_true()
	var config: MatchConfig = room.arena_config()
	assert_str(String(config.map)).is_equal(String(ArenaMaps.IDS[1]))
	assert_int(config.bot_count).is_equal(1)
	assert_float(config.duration).is_equal(480.0)
	assert_str(room.ready_room._plan.text).contains(ArenaMaps.NAMES[1])
	# The bots are the count's to say, not the plan's.
	assert_str(room.ready_room._plan.text).not_contains("bot")
	assert_int(room.ready_room.bots_asked).is_equal(1)
	assert_str(room.ready_room._counter.text).ends_with("+ 1 BOT")
	# Kept for next time, the way the lobby keeps what it was last set to.
	assert_int(Game.settings.bot_count).is_equal(1)
	assert_str(Game.settings.map).is_equal(String(ArenaMaps.IDS[1]))


## Back from a match with everybody still connected, the host's room takes over the connection
## that is already open rather than opening another, and puts the match settings up again: the
## next match is chosen here, the same as the first one was. Only the match's, though: who may come
## in was settled when the game was hosted.
func test_the_host_comes_back_to_the_room_on_the_same_connection() -> void:
	var open := Net.open(null)
	assert_int(open.host(port)).is_equal(OK)
	var room := await _host()
	assert_object(Net.session).is_same(open)
	assert_object(room.session).is_same(open)
	assert_object(open.match_node).is_same(room.get_node("Match"))
	var pane: HostSettings = room.host_settings
	assert_bool(pane.is_open()).is_true()
	assert_bool(pane.on_lobby()).is_false()
	assert_bool(pane._pane.visible).is_true()


## The host can choose a Grand Prix instead, GAME.md 9.7: how many maps rather than which, and
## the maps are dealt when the room goes, the first of them being the one the room goes to.
func test_the_host_can_choose_a_grand_prix() -> void:
	var room := await _host()
	var pane: HostSettings = room.host_settings
	pane.options.choose(true)
	pane.options.maps_option.selected = MatchOptions.MAPS.find(4)
	pane.close()
	await _runner.simulate_frames(2, 17)
	assert_str(room.ready_room._plan.text).contains("Grand Prix of 4 maps")
	var first: MatchConfig = room.first_map_config()
	assert_object(Game.grand_prix).is_not_null()
	assert_int(Game.grand_prix.playlist.size()).is_equal(4)
	assert_str(String(first.map)).is_equal(String(Game.grand_prix.playlist[0]))
	# The bots for the whole run are dealt now too, one for every seat nobody here is in.
	assert_int(Game.grand_prix.bots.size()).is_equal(first.network_seats + first.bot_count)
	# A room of more than four karts deals the XL maps alone, GAME.md 6.3, unless asked not to.
	room.session.door.max_players = 8
	room.config.bot_count = 7
	room.config.normal_maps = true
	room.config.xl_maps = false
	room.first_map_config()
	for id: StringName in Game.grand_prix.playlist:
		assert_bool(ArenaMaps.is_xl(id)).override_failure_message(String(id)).is_true()
	room.config.small_maps = true
	room.first_map_config()
	for id: StringName in Game.grand_prix.playlist:
		assert_bool(ArenaMaps.is_xl(id)).override_failure_message(String(id)).is_false()
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


## A room on one machine is asked as a host's is, GAME.md 9.6: Play goes straight into it with the
## match settings up, which say who can join while they are, and are in the pause menu after.
func test_a_room_on_one_machine_chooses_its_match_in_the_room() -> void:
	var room: Node3D = auto_free(WAITING_SCENE.instantiate())
	_runner = scene_runner(room)
	await _runner.simulate_frames(45, 17)
	var pane: HostSettings = room.host_settings
	assert_object(pane).is_not_null()
	assert_bool(pane.is_open()).is_true()
	assert_bool(pane.alone).is_true()
	# Nobody knocks on one machine: straight to the match.
	assert_bool(pane.on_lobby()).is_false()
	assert_bool(room.ready_room.held).is_true()
	pane.close()
	assert_bool(room.ready_room.held).is_false()
	var menu: PauseMenu = room.get_node("PauseMenu")
	var entry: Button = null
	for button: Node in menu.find_children("*", "Button", true, false):
		if (button as Button).text == "Match settings":
			entry = button
	assert_object(entry).is_not_null()


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
	_join(match_node, DeviceInput.KEYBOARD + 1)
	room.config.bot_count = 3
	var config: MatchConfig = room.arena_config()
	assert_int(config.bot_count).is_equal(2)
	assert_int(config.seats).is_equal(SeatLimit.SEATS)
	assert_int(config.inputs().size()).is_equal(config.seats)
	assert_int(config.rules(ARENA_RULES).max_players).is_equal(4)
	# Online, GAME.md 9.3, the arena has as many seats as the lobby lets play, and never fewer than
	# four. Two people can play each other with no bots at all.
	var session: NetSession = auto_free(NetSession.new())
	room.session = session
	session.door.max_players = 8
	room.config.bot_count = 7
	config = room.arena_config()
	assert_int(config.seats).is_equal(8)
	assert_int(config.bot_count).is_equal(6)
	assert_int(config.rules(ARENA_RULES).max_players).is_equal(8)
	session.door.max_players = 2
	room.config.bot_count = 7
	config = room.arena_config()
	assert_int(config.seats).is_equal(4)
	assert_int(config.bot_count).is_equal(2)
	room.config.bot_count = 0
	assert_int(room.arena_config().inputs().size()).is_equal(2)
	room.session = null


## A client keeps the color it had in the room: the arena keeps its seat in that color, in the
## order the host will seat the clients again.
func test_a_client_keeps_its_color_into_the_arena() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var visitor := match_node.join_network(NetInput.new())
	visitor.color_index = 3
	var session: NetSession = auto_free(NetSession.new())
	session._peer_slots.put(7, 0, visitor.index)
	room.session = session
	var config: MatchConfig = room.arena_config()
	room.session = null
	assert_int(config.network_seats).is_equal(1)
	assert_array(config.network_colors).contains_exactly([3])
	assert_int(config.colors()[config.human_devices.size()]).is_equal(3)


## And the room holds no more people than the arena can seat, so nobody who got in is left
## standing when the match begins: four on one machine, and online as many as the lobby lets in.
func test_the_room_holds_as_many_as_the_arena_seats() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	assert_int(SeatLimit.limit(match_node, null)).is_equal(room.arena_config().seats)
	var session: NetSession = auto_free(NetSession.new())
	room.session = session
	for most: int in range(SeatLimit.SEATS, NetDoor.MOST_PLAYERS + 1):
		session.door.max_players = most
		assert_int(SeatLimit.limit(match_node, session)).is_equal(room.arena_config().seats)
	room.session = null


## How many blocks of the ring are lit in [param slot]'s color.
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
	_join(match_node, DeviceInput.KEYBOARD + 1)
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
	assert_int(ball.collision_layer).is_equal(Layers.BALL)
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


## A shot kicks the ball on the way the shot was going, and is spent on it.
func test_a_shot_kicks_the_ball_on() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ball: RoomBall = room.ball
	var kart := match_node.kart_of(0)
	kart.global_position = ball.global_position + Vector3(0.0, 0.0, 6.0)
	var start := ball.global_position
	var shot := match_node.bullets.spawn(
		0,
		Vector3(start.x - 3.0, Bullet.HEIGHT, start.z),
		Vector3.RIGHT,
		kart.cannon.stats,
		Color.WHITE
	)
	shot.assist_enabled = false
	await _runner.simulate_frames(30, 17)
	assert_bool(is_instance_valid(shot) and not shot.is_dead()).is_false()
	assert_float(ball.linear_velocity.x).is_greater(2.0)
	assert_float(absf(ball.linear_velocity.z)).is_less(0.5)
	assert_float(ball.global_position.x - start.x).is_greater(0.5)


## A kart on nitro kicks the ball twice as hard as the same kart coming at it the same way off
## nitro, and the ball may go faster than its usual most for it.
func test_a_kick_on_nitro_is_twice_as_hard() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ball: RoomBall = room.ball
	var kart := match_node.kart_of(0)
	var at := ball.global_position
	kart.global_position = Vector3(at.x - 1.1, 0.0, at.z)
	kart.face(Vector3.RIGHT)
	kart.motor.velocity = Vector3(8.0, 0.0, 0.0)
	kart.nitro_active = false
	var plain: Array = ball._kick(at, Vector3.ZERO, kart)
	kart.nitro_active = true
	var hard: Array = ball._kick(at, Vector3.ZERO, kart)
	kart.nitro_active = false
	assert_bool(plain[2]).is_false()
	assert_bool(hard[2]).is_true()
	var soft_speed := (plain[1] as Vector3).length()
	assert_float(soft_speed).is_greater(1.0)
	assert_float((hard[1] as Vector3).length()).is_equal_approx(
		soft_speed * RoomBall.NITRO_KICK, 0.01
	)


## However hard it is sent, it stays on the floor and inside the room: no height to go up into,
## and walls that throw it back.
func test_the_ball_never_leaves_the_floor_or_the_room() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ball: RoomBall = room.ball
	var half := match_node.arena.world_size() * 0.5
	# Including as fast as a kick on nitro sends it.
	for heading: Vector3 in [Vector3(0, 0, -1), Vector3(1, 0, 0.6), Vector3(-1, 0.8, 1)]:
		ball._cap = RoomBall.MAX_SPEED * RoomBall.NITRO_KICK
		ball.linear_velocity = heading.normalized() * ball._cap
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


## The ball is heard being hit: a thump off a kart, a knock off a wall, and nothing at all while it
## only rolls.
func test_the_ball_is_heard_being_hit_and_not_rolling() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ball: RoomBall = room.ball
	var heard: Array[StringName] = []
	ball.struck.connect(func(kind: StringName, _strength: float) -> void: heard.append(kind))
	var kart := match_node.kart_of(0)
	var start := ball.global_position
	kart.global_position = Vector3(start.x - 4.0, 0.0, start.z)
	kart.face(Vector3.RIGHT)
	var driver := KartInput.new()
	driver.throttle = 1.0
	kart.input = driver
	await _runner.simulate_frames(90, 17)
	assert_array(heard).contains([&"kick"])
	# Away from every kart, and sent at the back wall: rolling there is quiet, the wall is not.
	kart.input = KartInput.new()
	kart.global_position = Vector3(start.x, 0.0, start.z + 8.0)
	heard.clear()
	ball.linear_velocity = Vector3.ZERO
	ball.global_position = Vector3(0.0, RoomBall.RADIUS, 0.0)
	await _runner.simulate_frames(5, 17)
	ball.linear_velocity = Vector3(0.0, 0.0, -8.0)
	# The test setting it going is a hit like any other; what comes after it is only rolling.
	await _runner.simulate_frames(3, 17)
	heard.clear()
	await _runner.simulate_frames(6, 17)
	assert_array(heard).is_empty()
	await _runner.simulate_frames(120, 17)
	assert_array(heard).contains([&"knock"])
	assert_bool(heard.has(&"kick")).is_false()


## A client hears the ball being hit from what it is told, since it is told nothing else.
func test_a_client_hears_the_ball_it_is_told_about() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var told := RoomBall.add_to(match_node, Vector3(-6.0, 0.0, 3.0), false)
	var heard: Array[StringName] = []
	told.struck.connect(func(kind: StringName, _strength: float) -> void: heard.append(kind))
	told.follow([-6.0, 3.0, 0.0, 0.0])
	await _runner.simulate_frames(10, 17)
	assert_array(heard).is_empty()
	told.follow([-6.0, 3.0, 9.0, 0.0])
	await _runner.simulate_frames(3, 17)
	assert_array(heard).is_equal([&"knock"])


## Down the side is who is in the room: a name each, in the order they arrived, with no place and
## no score, since nothing in here is being played for.
func test_the_side_list_is_who_is_in_the_room() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	# The first player came in on the keyboard, and somebody picks up the first pad.
	_join(match_node, DeviceInput.KEYBOARD + 1)
	await _runner.simulate_frames(3, 17)
	var list: Scoreboard = match_node.hud._scoreboard
	assert_bool(list.visible).is_true()
	assert_bool(list.roster).is_true()
	assert_int(list.get_child_count()).is_equal(2)
	for index: int in 2:
		var row: Dictionary = list._rows[index]
		assert_int((row["panel"] as Control).get_index()).is_equal(index)
		assert_str((row["name"] as Label).text).is_equal(match_node.slots[index].display_name())
		assert_bool((row["place"] as Label).visible).is_false()
		assert_bool((row["score"] as Label).visible).is_false()


## A player's block in the room says nothing about scoring, since nothing is scored in here: no
## banked chips, pot, mult, kills or deaths. The name, lives and nitro stay, since driving round
## in here is still driving.
func test_the_blocks_in_the_room_leave_the_scoring_out() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var block: Dictionary = match_node.hud._blocks[0]
	for scoring: String in ["banked", "pot", "stats"]:
		(
			assert_bool((block[scoring] as Control).visible)
			. override_failure_message(scoring)
			. is_false()
		)
	assert_bool((block["nitro"] as Control).visible).is_true()
	assert_bool((block["lives"][0] as Control).visible).is_true()


## A player here charging the pad hears it: a tick for every block of their arc as it lights,
## each one higher than the last. Somebody at another machine charging it is seen, not heard, or
## a room of four would be a clatter.
func test_charging_the_pad_is_heard_by_the_player_on_it() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ready_room: ReadyRoom = room.ready_room
	var visitor := match_node.join_network(NetInput.new())
	await _runner.simulate_frames(3, 17)
	var heard := {"steps": [], "seats": {}}
	ready_room.charged.connect(
		func(seat: int, step: int, _of: int) -> void:
			heard["steps"].append(step)
			heard["seats"][seat] = true
	)
	var pad := match_node.arena.junction.global_position
	match_node.kart_of(0).global_position = pad + Vector3(-1.0, 0.0, 0.0)
	visitor.kart.global_position = pad + Vector3(1.0, 0.0, 0.0)
	await _runner.simulate_frames(int(ReadyRoom.CHARGE_TIME * 70.0), 17)
	var steps: Array = heard["steps"]
	assert_int(steps.size()).is_greater(ReadyRoom.SEGMENTS / 2 - 3)
	for i: int in range(1, steps.size()):
		assert_int(steps[i]).is_greater(steps[i - 1])
	assert_bool((heard["seats"] as Dictionary).has(visitor.index)).is_false()


## GAME.md 9.6: readying up is heard at the machine that decides it, not only at the ones it tells.
## Whoever fills the room is heard as the ring going green, which is a run rather than the chime.
func test_readying_up_is_heard_and_filling_the_room_is_heard_louder() -> void:
	var room := await _open()
	var match_node: Match = room.get_node("Match")
	var ready_room: ReadyRoom = room.ready_room
	var visitor := match_node.join_network(NetInput.new())
	await _runner.simulate_frames(3, 17)
	var heard := {"readied": [], "filled": 0}
	ready_room.readied.connect(func(seat: int) -> void: heard["readied"].append(seat))
	ready_room.filled.connect(func() -> void: heard["filled"] += 1)
	var pad := match_node.arena.junction.global_position
	match_node.kart_of(0).global_position = pad + Vector3(-1.0, 0.0, 0.0)
	visitor.kart.global_position = pad + Vector3(4.0, 0.0, 4.0)
	await _runner.simulate_frames(int(ReadyRoom.CHARGE_TIME * 70.0), 17)
	assert_bool(ready_room.ready_slots.get(0, false)).is_true()
	assert_array(heard["readied"]).is_equal([0])
	assert_int(heard["filled"]).is_equal(0)
	visitor.kart.global_position = pad + Vector3(1.0, 0.0, 0.0)
	await _runner.simulate_frames(int(ReadyRoom.CHARGE_TIME * 70.0), 17)
	assert_bool(ready_room.all_green()).is_true()
	assert_array(heard["readied"]).is_equal([0])
	assert_int(heard["filled"]).is_equal(1)


## An empty room is not a ready room: a match with nobody in it has nothing to start.
func test_a_room_with_nobody_in_it_is_never_ready() -> void:
	var room := await _open()
	var ready_room: ReadyRoom = room.ready_room
	ready_room.match_node.slots.clear()
	assert_int(ready_room.player_count()).is_equal(0)
	assert_bool(ready_room.all_ready()).is_false()


## Somebody sits down on [param device], the player already here having last touched the keyboard:
## a real pad on the machine running the tests, touched while they run, is no part of what is
## tested, and the devices touched last decide who is holding which, see [DeviceInput].
func _join(match_node: Match, device: int) -> PlayerSlot:
	DeviceInput.recent = [DeviceInput.KEYBOARD]
	return match_node.join_human(device)
