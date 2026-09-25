extends Node
## Development harness: plays a whole Grand Prix of GAME.md 9.7 through the real scenes, the way a
## player would, and says at every step whether what should have happened did. Started by
## tools/multiplayer_check.gd, which tools/multiplayer_check runs as a host and a client, two
## processes on one machine, and as two players on one screen, so "does it work in multiplayer"
## is a yes or a no rather than an impression.
##
## Each run is a role: host, client or local. The host and the client find each other on a port
## on this machine; nothing else is shared between them, so what each one checks is what that
## machine really saw. Every step prints a line starting MPCHECK, and a step that does not happen
## in time fails the run with the reason.

const WAITING_SCENE := "res://scenes/waiting/waiting_room.tscn"
const MATCH_SCENE := "res://scenes/match/match_scene.tscn"
const ONLINE_SCENE := "res://scenes/ui/online.tscn"
## How many maps the checked Grand Prix runs, and how many bots it asks for.
const MAPS := 2
const BOTS := 1
## How far a client walks its kart toward the pad in a frame, and where on the pad each seat
## parks, see [method _park].
const STEP := 0.05
## How long the host reads a podium before pressing on, the way a person does. It is also what
## gives the client time to have its own podium up before the host has moved everybody on.
const READING := 2.0
const SPOTS: Array[Vector3] = [
	Vector3(-1.1, 0.0, 0.0), Vector3(1.1, 0.0, 0.0), Vector3(0.0, 0.0, -1.1), Vector3(0.0, 0.0, 1.1)
]

var _role := ""
var _port := 7851
var _failed := false
## The color this client had on the first map, to find it in again on the second.
var _color := -1
## Whether the role got to its last step.
var _finished := false
## On the host: how many clients to wait for, and how many players sit at the host's own
## machine, the host and whoever takes the second seat there.
var _clients := 1
var _locals := 1
## The color this client had in the waiting room, to find it in again in the arena.
var _room_color := -1
## The name it took in the room, for map 1 to be checked against.
var _room_name := ""
## What of their jokers everybody keeps between maps, one of GrandPrix.Keep, and on the host
## the jokers it handed every seat on the first map, to find the right ones again on the second.
var _keep := 2
var _given: Dictionary = {}
## The lobby's password, GAME.md 9.6: on the host the one its door wants, and on a client the one
## it types when asked. A client with one knocks without it first, the way a player who has not
## been told does, and goes in through the question.
var _password := ""
## Whether a client gives a wrong password first, and is sent back to Play LAN for it, before it
## joins from there with the right one.
var _wrong_first := false
## Whether a client gives no name at all, and plays under the funny one the host hands it, which
## it keeps from room to room, GAME.md 3.8.
var _nameless := false


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):
			_role = arg.get_slice("=", 1)
		elif arg.begins_with("--port="):
			_port = int(arg.get_slice("=", 1))
		elif arg.begins_with("--clients="):
			_clients = int(arg.get_slice("=", 1))
		elif arg.begins_with("--locals="):
			_locals = int(arg.get_slice("=", 1))
		elif arg.begins_with("--jokers="):
			_keep = ["none", "choose", "random", "all"].find(arg.get_slice("=", 1))
		elif arg.begins_with("--password="):
			_password = arg.get_slice("=", 1)
		elif arg == "--wrong-first":
			_wrong_first = true
		elif arg == "--nameless":
			_nameless = true
	_run.call_deferred()


func _run() -> void:
	multiplayer.peer_connected.connect(func(peer: int) -> void: _say("peer %d connected" % peer))
	multiplayer.peer_disconnected.connect(
		func(peer: int) -> void: _say("peer %d disconnected" % peer)
	)
	multiplayer.server_disconnected.connect(func() -> void: _say("the server hung up"))
	# Settings of its own, so a check never decides anybody's next match.
	Game.settings = Settings.new()
	Game.settings.path = "user://multiplayer_check_%s.cfg" % _role
	match _role:
		"host":
			await _host()
		"client":
			await _client()
		"local":
			await _local()
		"watcher":
			await _watcher()
		_:
			_fail("no --role=host, client, watcher or local")
	# A step that gave up without saying why is a failure too: a script error inside one is how
	# that happens, and it should not read as a pass.
	if not _failed and not _finished:
		_fail("stopped before the end")
	if not _failed:
		_say("PASSED")
	get_tree().quit(1 if _failed else 0)


## The host of an online Grand Prix: opens the room, chooses a match of two maps, waits for the
## client, readies up, plays both maps, and takes everybody back to the room.
func _host() -> void:
	var first := await _host_opens_the_room()
	if first == null:
		return
	var last := await _host_plays(first)
	if last == null:
		return
	await _host_goes_back(last)


## Up to the first map: the room, the choice of a match, the client, and readying up.
func _host_opens_the_room() -> Node:
	var config := MatchConfig.from_settings(Game.settings)
	config.online = "host"
	config.port = _port
	config.human_names = ["Host"] as Array[String]
	config.password = _password
	# Somebody watching is let in without it, so the one watching this game needs none.
	Game.settings.lobby_watch_free = true
	Game.go_to_waiting(config)
	var room := await _room()
	if room == null:
		return null
	var pane: HostSettings = room.host_settings
	if not _check(pane != null and pane.is_open(), "the match settings are up in the room"):
		return null
	pane.options.choose(true)
	pane.options.maps_option.selected = MatchOptions.MAPS.find(MAPS)
	pane.options.bots_option.selected = MatchOptions.BOTS.find(BOTS)
	pane.options.minutes_option.selected = MatchOptions.match_lengths().find(60)
	pane.options.jokers_option.selected = _keep
	pane.close()
	_check(room.ready_room._plan.text.contains("Grand Prix of %d maps" % MAPS), "the room says so")
	var match_node: Match = room.match_node
	if not await _until(
		func() -> bool: return _remote(match_node) == _clients,
		30.0,
		"%d client(s) sat down" % _clients
	):
		return null
	# The clients drive through the football on their way to the pad. The host kicks it, so it is
	# on the host that it has to move.
	var ball: RoomBall = room.ball
	await _until(
		func() -> bool: return ball.global_position.distance_to(ball.home) > 1.0,
		30.0,
		"a client kicked the football"
	)
	# A second player at the host's own machine takes a seat on a pad, the way the room tells
	# them to, once the others are in.
	if _locals > 1:
		_check(match_node.join_human(0) != null, "a second player here took a seat")
	# Not ready while only the host's end is on the pad: the room waits for everybody.
	_park_mine(match_node)
	await _frames(150)
	if not _check(_scene() == room, "the room waits while the clients are not on the pad"):
		return null
	var ready_room: ReadyRoom = room.ready_room
	if not await _until(
		func() -> bool: return _park_mine(match_node) and _scene() != room, 30.0, "the room went"
	):
		if is_instance_valid(ready_room):
			_say(_readout(match_node, ready_room))
		return null
	return await _map(1)


## What the host's room sees of who is where, for a room that has not gone when it should have.
func _readout(match_node: Match, ready_room: ReadyRoom) -> String:
	var pad := match_node.arena.junction.global_position
	var parts: PackedStringArray = [
		(
			"ready %d/%d held=%s"
			% [ready_room.ready_count(), ready_room.player_count(), ready_room.held]
		)
	]
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		(
			parts
			. append(
				(
					"seat %d %s at %.1f m charge %.2f alive %s"
					% [
						slot.index,
						slot.input.get_class() if slot.input != null else "none",
						kart.global_position.distance_to(pad) if kart != null else -1.0,
						ready_room.charge.get(slot.index, 0.0),
						kart.alive if kart != null else false,
					]
				)
			)
		)
	var on := ready_room._karts_on_the_pad()
	parts.append("on the pad %s" % str(on.keys()))
	return " | ".join(parts)


## Both maps, checking the second has the same people, bot and colors as the first. Returns the
## run's podium.
func _host_plays(first: Node) -> ResultsScreen:
	var one: Match = first.match_node
	var first_arena := one.rules.map
	var bot := _bot_seat(one)
	var bot_trait := String(one.slots[bot].bot_trait.id) if bot >= 0 else ""
	var guests := _colors(one)
	var seats := _locals + _clients + BOTS
	_check(one.slots.size() == seats, "map 1 seats everybody and a bot, %d in all" % seats)
	_check(guests.size() == _clients, "every client has a seat on map 1")
	if _locals > 1:
		_check(one.slots[1].is_local_human(), "the second player here plays map 1")
	var podium := await _end(first)
	if podium == null:
		return null
	_check(not podium._next.visible and not podium._rematch.visible, "map 1's podium goes on")
	_check(Game.grand_prix.scored_round == 0, "map 1 is scored")
	_say("SCORES 1 %s" % _scores(one))
	if not await _on_to_the_standings(podium, 1):
		return null
	await _seconds(READING)
	podium._next.pressed.emit()
	var second := await _map(2)
	if second == null:
		return null
	var two: Match = second.match_node
	# Everybody choosing which joker to keep does it on this map's grid, and the lamps wait for
	# them: the host for the player here, each client for its own, the host deciding for all.
	await _keep_on(second, 0)
	if _keep == GrandPrix.Keep.CHOOSE:
		await _until(
			func() -> bool: return two.state != Match.State.LOBBY,
			30.0,
			"the lamps went once everybody had chosen"
		)
	_check(two.slots.size() == seats, "map 2 seats the same people")
	_check(
		bot >= 0 and String(two.slots[bot].bot_trait.id) == bot_trait,
		"map 2 has the same bot in the same seat"
	)
	_check(_colors(two) == guests, "every client is in the same seat and color on map 2")
	if _locals > 1:
		_check(two.slots[1].is_local_human(), "the second player here plays map 2")
	_check(two.rules.map != first_arena, "map 2 is a different arena")
	_check_kept(two)
	var last := await _end(second)
	if last == null:
		return null
	if not await _to_the_run(last):
		return null
	_check(last._lobby.visible and not last._next.visible, "it offers Back to lobby")
	_say("SCORES 2 %s" % _scores(two))
	return last


## Back to the room with everybody, the settings up again for the next one.
func _host_goes_back(last: ResultsScreen) -> void:
	await _seconds(READING)
	last._lobby.pressed.emit()
	var again := await _room()
	if again == null:
		return
	_check(again.host_settings != null and again.host_settings.is_open(), "settings are up again")
	var match_node: Match = again.match_node
	await _until(
		func() -> bool: return _remote(match_node) == _clients, 30.0, "every client is back"
	)
	if _locals > 1:
		_check(match_node.slots[1].is_local_human(), "and the second player here too")
	# Give the client its moment to see the room before this end hangs up.
	await _until(func() -> bool: return multiplayer_peers() == 0, 20.0, "the client finished")
	_finished = true


## The client of the same Grand Prix: joins, readies up, follows the host through both maps and
## back to the room, checking at each step what it was told.
func _client() -> void:
	var first := await _client_joins()
	if first == null:
		return
	var second := await _client_after_map_1(first)
	if second == null:
		return
	await _client_after_map_2(second)


## Into the room, seated, parked on the pad, and following the host to the first map.
func _client_joins() -> Node:
	var config := MatchConfig.new()
	config.online = "join"
	config.address = "127.0.0.1"
	config.port = _port
	config.human_names = ["" if _nameless else "Client"] as Array[String]
	# The host may still be opening its room.
	await _frames(60)
	Game.go_to_waiting(config)
	if not await _through_the_door():
		return null
	var room := await _room()
	if room == null:
		return null
	var session: NetSession = room.session
	var match_node: Match = room.match_node
	# Seated once the seat is known and the snapshot has built it: the seat's number and the
	# seats themselves arrive separately.
	if not await _until(
		func() -> bool:
			return session.local_slot >= 0 and match_node.slots.size() > session.local_slot,
		30.0,
		"seated in the room"
	):
		return null
	_room_color = match_node.slots[session.local_slot].color_index
	# The first client drives through the football on the way to the pad, from a little short of
	# it to a little past it, and the ball this machine draws has to have gone somewhere too. Only
	# the first: two karts making for the same ball meet each other, and the host takes the wheel
	# off both for a moment, which is the game working and not what is being checked here.
	var ball: RoomBall = room.ball
	var seat := session.local_slot
	var first := true
	for slot: PlayerSlot in match_node.slots:
		if slot.index > 0 and slot.index < seat and slot.is_human():
			first = false
	# A new name, and for the first client the next color nobody is in, asked of the host from here
	# and brought back in the snapshot, GAME.md 4.4. Only the first, though the snapshot saying who
	# else is a person can be late enough for two to think they are it: two asking for the same free
	# color at once is one of them told no, which is the host working, so it is asked again until
	# the host has moved it on to one.
	_room_name = "Renamed %d" % seat
	if not _nameless:
		SeatIdentity.rename(match_node.slots[seat], _room_name)
	if first:
		var from := match_node.slots[seat].color_index
		var again := [0]
		if not await _until(
			func() -> bool:
				var mine := match_node.slots[seat]
				if mine.color_index != from and mine.kart != null:
					return mine.kart.color_index == mine.color_index
				var now := Time.get_ticks_msec()
				if now >= again[0]:
					again[0] = now + 500
					SeatIdentity.recolor(match_node, mine)
				return false,
			10.0,
			"the host put it in the next free color"
		):
			return null
	await _seconds(1.0)
	_room_color = match_node.slots[seat].color_index
	if _nameless:
		_room_name = match_node.slots[seat].player_name
		_check(_room_name in PlayerNames.NAMES, "the host handed it a name: %s" % _room_name)
	else:
		_check(match_node.slots[seat].player_name == _room_name, "the host gave it its new name")
	if first:
		await _until(
			func() -> bool: return _walk(match_node, seat, ball.home - Vector3(1.8, 0.0, 0.0)),
			30.0,
			"up to the ball"
		)
		await _until(
			func() -> bool: return _walk(match_node, seat, ball.home + Vector3(1.5, 0.0, 0.0)),
			30.0,
			"through the ball"
		)
		await _until(
			func() -> bool: return ball.global_position.distance_to(ball.home) > 0.5,
			10.0,
			"the football it kicked moved on its screen too"
		)
		_check(absf(ball.global_position.y - RoomBall.RADIUS) < 0.01, "and stayed on the floor")
	if not await _until(
		func() -> bool: return _park(match_node, session.local_slot) and _scene() != room,
		60.0,
		"followed the host to map 1"
	):
		return null
	return await _map(1)


## Map 1's podium as a client sees it, then on to map 2.
func _client_after_map_1(first: Node) -> Node:
	var one: Match = first.match_node
	_color = one.slots[one.local_slot].color_index
	_check(_color == _room_color, "the same color on map 1 as in the room")
	_check(one.slots[one.local_slot].player_name == _room_name, "and the same name")
	var podium := await _podium(first, 60.0)
	if podium == null:
		return null
	_check(not podium._next.visible, "a client has no Next map of its own")
	_check(podium._host_decides.text == "The host starts the next map.", "and is told who does")
	_check(podium._caption.text.contains("map 1 of %d" % MAPS), "its podium says map 1 of 2")
	if not await _until(
		func() -> bool: return Game.grand_prix != null and Game.grand_prix.scored_round == 0,
		10.0,
		"told how the run stands after map 1"
	):
		return null
	_check(_scene_has_points(podium), "its podium shows what each place paid")
	_say("SCORES 1 %s" % _scores(one))
	# The run's standings are everybody's to look at, and the host still decides when to go on.
	if not await _until(
		func() -> bool: return podium._standings.visible, 10.0, "it offers the run's"
	):
		return null
	podium._standings.pressed.emit()
	_check(podium._title.text == ResultsScreen.GRAND_PRIX_TITLE, "then the run's standings")
	_check(not podium._next.visible and podium._host_decides.visible, "still the host's to go on")
	# What it held at the whistle, as the host told it, to be offered again on the next map.
	_given[one.local_slot] = one.slots[one.local_slot].kart.jokers.ids()
	var second := await _map(2)
	if second != null:
		await _keep_on(second, second.match_node.local_slot)
	return second


## Map 2 in the same color, the run's podium, and back to the room.
func _client_after_map_2(second: Node) -> void:
	var two: Match = second.match_node
	_check(two.slots[two.local_slot].color_index == _color, "the same color on map 2")
	_check(two.slots[two.local_slot].player_name == _room_name, "and the same name on map 2")
	var last := await _podium(second, 60.0)
	if last == null:
		return
	await _until(
		func() -> bool: return Game.grand_prix != null and Game.grand_prix.scored_round == 1,
		10.0,
		"told how the run ended"
	)
	await _frames(5)
	if not await _to_the_run(last):
		return
	_check(last._host_decides.text.contains("back to the lobby"), "told the host takes it back")
	_say("SCORES 2 %s" % _scores(two))
	var again := await _room()
	if again == null:
		return
	var session: NetSession = again.session
	if not await _until(
		func() -> bool: return session.local_slot >= 0, 30.0, "seated in the room again"
	):
		return
	# Stays a moment, the way a player would, so the host sees it back in the room before it goes.
	await _seconds(READING * 2.0)
	_finished = true


## Somebody who came to watch, GAME.md 10.3: into the room with no seat, the host's maps as it
## plays them with the karts in view, and back into the room with everybody when the run is over.
func _watcher() -> void:
	var config := MatchConfig.new()
	config.online = "join"
	config.watching = true
	config.address = "127.0.0.1"
	config.port = _port
	await _frames(60)
	Game.go_to_waiting(config)
	var room := await _room()
	if room == null:
		return
	var session: NetSession = room.session
	if not await _until(
		func() -> bool: return room.match_node.puppet_karts.size() > 0, 30.0, "watching the room"
	):
		return
	_check(session.local_slot == -1, "in the room with no seat")
	await _frames(5)
	_check(not room.ready_room._seat_hint.visible, "not told how to take a seat")
	# An emote with no kart to put it over, GAME.md 3.8: asked of the host, and back from it, up the
	# bottom of this screen as of every other.
	var heard: Array[String] = []
	var hear := func(watcher: String, _emote: int) -> void: heard.append(watcher)
	Events.watcher_emoted.connect(hear)
	Input.action_press(InputActions.EMOTE_1)
	await _frames(3)
	Input.action_release(InputActions.EMOTE_1)
	await _until(
		func() -> bool: return not heard.is_empty(), 10.0, "its emote came back from the host"
	)
	var bubble: Node = room.match_node.hud.find_child("WatcherEmote", true, false)
	_check(bubble != null, "and floats up this screen")
	Events.watcher_emoted.disconnect(hear)
	for round: int in [1, 2]:
		if not await _until(
			func() -> bool:
				var scene := _scene()
				if scene == null or scene.scene_file_path != MATCH_SCENE:
					return false
				var match_node: Match = scene.match_node
				if match_node == null or match_node.rules.round != round:
					return false
				return match_node.puppet_karts.size() >= 2,
			120.0,
			"watching map %d" % round
		):
			return
		_check(session.local_slot == -1, "map %d watched with no kart" % round)
		# Nobody watching presses anything: the podium goes on to the run's standings itself.
		# After the first map this host goes on sooner than a watcher's podium does, which is the
		# host's to do, so it is asked after the last, which the host stays on for the finale.
		if round < MAPS:
			continue
		if not await _until(
			func() -> bool:
				var scene := _scene()
				if scene == null or scene.scene_file_path != MATCH_SCENE:
					return false
				# After the last map that is the finale first, and the standings over it once the
				# camera is there, which this host does not stay for.
				var hud: MatchHud = scene.match_node.hud
				return (
					hud != null and (hud._results._showing_run or scene.match_node.finale != null)
				),
			120.0,
			"the run's standings came up after map %d with no press" % round
		):
			return
	var back := await _until(
		func() -> bool: return _scene() != null and _scene().scene_file_path == WAITING_SCENE,
		180.0,
		"followed the host back to the room"
	)
	if back:
		_finished = true


## Two players on one machine: Play, the waiting room, both maps, and back to the lobby with the
## same two players in it and the match settings up again.
func _local() -> void:
	var first := await _local_readies_up()
	if first == null:
		return
	var last := await _local_plays(first)
	if last == null:
		return
	last._lobby.pressed.emit()
	var again := await _room()
	if again == null:
		return
	_check(again.match_node.slots.size() == 2, "back in the lobby with both players")
	_check(again.host_settings != null and again.host_settings.is_open(), "settings are up again")
	_finished = true


## Both players into the room, and the room waiting until both are on the pad.
func _local_readies_up() -> Node:
	var config := MatchConfig.from_settings(Game.settings)
	config.online = ""
	config.human_devices = [DeviceInput.KEYBOARD, 0] as Array[int]
	config.human_colors = [0, 2] as Array[int]
	config.human_names = ["Left", "Right"] as Array[String]
	config.rounds = MAPS
	config.bot_count = BOTS
	config.duration = 60.0
	config.keep_jokers = _keep
	Game.go_to_waiting(config)
	var room := await _room()
	if room == null:
		return null
	# The match is chosen over the room, on one machine as online, GAME.md 9.6.
	var pane: HostSettings = room.host_settings
	if not _check(pane != null and pane.is_open(), "the match settings are up in the room"):
		return null
	pane.options.choose(true)
	pane.options.maps_option.selected = MatchOptions.MAPS.find(MAPS)
	pane.options.bots_option.selected = MatchOptions.BOTS.find(BOTS)
	pane.options.minutes_option.selected = MatchOptions.match_lengths().find(60)
	pane.options.jokers_option.selected = _keep
	pane.close()
	var match_node: Match = room.match_node
	_check(match_node.slots.size() == 2, "both players are seated in the room")
	# One on the pad is not everybody.
	_park(match_node, 0)
	await _frames(150)
	if not _check(_scene() == room, "the room waits for the second player"):
		return null
	if not await _until(
		func() -> bool: return _park(match_node, 0) and _park(match_node, 1) and _scene() != room,
		30.0,
		"the room went with both on the pad"
	):
		return null
	return await _map(1)


## Both maps, the second with the same players and bot as the first. Returns the run's podium.
func _local_plays(first: Node) -> ResultsScreen:
	var one: Match = first.match_node
	_check(one.slots.size() == 2 + BOTS, "map 1 has both players and the bot")
	_check(one.slots[0].is_local_human() and one.slots[1].is_local_human(), "both play here")
	_check(
		one.slots[1].color_index == 2 and one.slots[1].player_name == "Right", "as they were set up"
	)
	var bot := _bot_seat(one)
	var bot_trait := String(one.slots[bot].bot_trait.id) if bot >= 0 else ""
	var podium := await _end(first)
	if podium == null:
		return null
	if not await _on_to_the_standings(podium, 1):
		return null
	podium._next.pressed.emit()
	var second := await _map(2)
	if second == null:
		return null
	var two: Match = second.match_node
	_check(two.slots.size() == 2 + BOTS, "map 2 has the same players and bot")
	_check(two.slots[1].is_local_human() and two.slots[1].color_index == 2, "the second carried on")
	_check(bot >= 0 and String(two.slots[bot].bot_trait.id) == bot_trait, "the same bot on map 2")
	_check_kept(two)
	var last := await _end(second)
	if last == null:
		return null
	if not await _to_the_run(last):
		return null
	_say("SCORES 2 %s" % _scores(two))
	return last


## Waits for the waiting room to be up, and returns it.
func _room() -> Node:
	var up := await _until(
		func() -> bool:
			var scene := _scene()
			return (
				scene != null
				and scene.scene_file_path == WAITING_SCENE
				and scene.ready_room != null
			),
		30.0,
		"the waiting room is up"
	)
	return _scene() if up else null


## Waits for map [param round] of the run to be up and this machine seated in it, and returns
## its scene.
func _map(round: int) -> Node:
	var up := await _until(
		func() -> bool:
			var scene := _scene()
			if scene == null or scene.scene_file_path != MATCH_SCENE or scene.match_node == null:
				return false
			var match_node: Match = scene.match_node
			# The arena goes up a phase at a time behind a loading screen, GAME.md 8.6, and a map
			# is only up once there are seats in it.
			if match_node.arena == null or match_node.rules.round != round:
				return false
			if match_node.slots.is_empty() or match_node.hud == null:
				return false
			if match_node.puppet:
				return (
					match_node.local_slot >= 0 and match_node.slots.size() > match_node.local_slot
				)
			# The host's map is up when every client is seated in it.
			return _role != "host" or _remote(match_node) == _clients,
		60.0,
		"map %d is up and everybody is seated" % round
	)
	if not up:
		return null
	var scene := _scene()
	_check(scene.match_node.rules.rounds == MAPS, "map %d knows it is one of %d" % [round, MAPS])
	return scene


## Blows the whistle on a map this machine runs, after a moment of it being played, and waits
## for its podium.
func _end(scene: Node) -> ResultsScreen:
	await _seconds(READING)
	if scene.match_node.rules.round == 1:
		_give_jokers(scene.match_node)
	# Different fortunes on every map, so the run's standings are not simply the seats in order
	# and the two ends have something to disagree about if they are going to.
	var match_node: Match = scene.match_node
	var count := match_node.slots.size()
	for slot: PlayerSlot in match_node.slots:
		var turn := (slot.index + match_node.rules.round) % count
		slot.banked = 100 * (turn + 1)
	match_node._finish()
	return await _podium(scene, 15.0)


## Two jokers for every seat before the first whistle, different for every seat, for the rule
## about keeping them to have something to keep.
func _give_jokers(match_node: Match) -> void:
	var catalog := match_node.joker_catalog.jokers
	for slot: PlayerSlot in match_node.slots:
		var given: Array[StringName] = []
		for i: int in 2:
			var joker: Joker = catalog[(slot.index * 2 + i) % catalog.size()]
			slot.kart.jokers.add(joker)
			given.append(joker.id)
		_given[slot.index] = given


## When everybody chooses a joker to keep, GAME.md 9.7: waits for the pick to be up for
## [param seat] as the map starts, with the two jokers it held on the last one, and takes the
## second by pressing the key for it, the way the player in it would.
func _keep_on(scene: Node, seat: int) -> void:
	var match_node: Match = scene.match_node
	# The rule as the host set it: a client is told it with the rest of the rules.
	if match_node.rules.keep_jokers != GrandPrix.Keep.CHOOSE:
		return
	var slot := match_node.slots[seat]
	if not await _until(
		func() -> bool: return JokerKeep.choosing(slot) and slot.offer.is_settled(),
		20.0,
		"seat %d is asked which joker to keep" % seat
	):
		return
	var offered: Array[StringName] = []
	for joker: Joker in slot.offer.choices:
		offered.append(joker.id)
	_check(offered == _given.get(seat, []), "it is offered the two it held: %s" % [offered])
	var press: InputEventKey = null
	for event: InputEvent in InputMap.action_get_events(InputActions.JOKER_SELECTS[1]):
		if event is InputEventKey:
			press = (event as InputEventKey).duplicate()
	if not _check(press != null, "there is a key for the second card"):
		return
	press.pressed = true
	Input.parse_input_event(press)
	await _frames(6)
	var release: InputEventKey = press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	_say("KEPT %s" % offered[1])


## Every seat on the second map holds what the rule says it takes from the first: nothing, the
## second joker for the people who chose it, one of its two for a bot or at random, or both.
func _check_kept(match_node: Match) -> void:
	for slot: PlayerSlot in match_node.slots:
		var given: Array = _given.get(slot.index, [])
		var held := slot.kart.jokers.ids()
		var right := false
		match _keep:
			GrandPrix.Keep.NONE:
				right = held.is_empty()
			GrandPrix.Keep.ALL:
				right = held.size() == 2 and held.has(given[0]) and held.has(given[1])
			GrandPrix.Keep.CHOOSE:
				right = (
					held.size() == 1
					and (held[0] == given[1] if slot.is_human() else given.has(held[0]))
				)
			_:
				right = held.size() == 1 and given.has(held[0])
		_check(right, "seat %d took on the jokers it should: %s of %s" % [slot.index, held, given])


## A map's podium in the middle of the run, then how the run stands, which is where the next map
## is started from.
func _on_to_the_standings(podium: ResultsScreen, round: int) -> bool:
	if not await _to_the_run(podium):
		return false
	_check(
		podium._caption.text.contains("after map %d of %d" % [round, MAPS]),
		"saying how it stands after map %d" % round
	)
	return _check(podium._next.visible, "and they offer Next map")


## The last map's podium is the map's, like every other; the run's is one press on from it.
func _to_the_run(last: ResultsScreen) -> bool:
	if not _check(last._title.text == ResultsScreen.TITLE, "the last map has its own podium"):
		return false
	await _until(func() -> bool: return last._standings.visible, 10.0, "it offers the run's")
	await _seconds(READING / 2.0)
	last._standings.pressed.emit()
	# After the last map the finale in the room comes first, and the standings go up over it.
	return await _until(
		func() -> bool: return last.visible and last._title.text == ResultsScreen.GRAND_PRIX_TITLE,
		20.0,
		"then the Grand Prix's"
	)


func _podium(scene: Node, seconds: float) -> ResultsScreen:
	var up := await _until(
		func() -> bool:
			return (
				is_instance_valid(scene)
				and scene.match_node.hud != null
				and scene.match_node.hud._results.visible
			),
		seconds,
		"the podium came up"
	)
	return scene.match_node.hud._results if up else null


## Brings the kart in [param seat] to the pad and keeps it there. True, so it can sit in a
## condition. On a client it is walked there a step a frame rather than put there: the host only
## believes a client about where its kart is while the kart stays within reach of where the host
## had it, NetInput.CLAIM_REACH, and a kart that jumped the room is one it would take back.
func _park(match_node: Match, seat: int) -> bool:
	if not is_instance_valid(match_node) or seat < 0 or seat >= match_node.slots.size():
		return true
	var kart := match_node.slots[seat].kart
	if kart == null or not kart.is_inside_tree() or match_node.arena == null:
		return true
	if match_node.arena.junction == null:
		return true
	# A spot of its own on the pad for every seat: two karts parked on the same point are two
	# karts shoving each other off it.
	var pad := match_node.arena.junction.global_position + SPOTS[seat % SPOTS.size()]
	return _walk(match_node, seat, pad)


## Moves the kart in [param seat] toward [param to], a step a frame on a client and at once on
## the host. True once it is there.
func _walk(match_node: Match, seat: int, to: Vector3) -> bool:
	var kart := match_node.slots[seat].kart
	var step := STEP if match_node.puppet else INF
	var way := to - kart.global_position
	way.y = 0.0
	kart.global_position += way if way.length() <= step else way.normalized() * step
	return way.length() <= step


func _remote(match_node: Match) -> int:
	if not is_instance_valid(match_node):
		return 0
	var count := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.input is NetInput:
			count += 1
	return count


## Seat to color for every client's seat.
func _colors(match_node: Match) -> Dictionary:
	var found := {}
	for slot: PlayerSlot in match_node.slots:
		if slot.input is NetInput:
			found[slot.index] = slot.color_index
	return found


## Brings every kart played at this machine to the pad. True, so it can sit in a condition.
func _park_mine(match_node: Match) -> bool:
	if not is_instance_valid(match_node):
		return true
	for slot: PlayerSlot in match_node.slots:
		if slot.is_local_human():
			_park(match_node, slot.index)
	return true


func _bot_seat(match_node: Match) -> int:
	for slot: PlayerSlot in match_node.slots:
		if slot.input is BotInput and slot.bot_trait != null:
			return slot.index
	return -1


## Whether a podium has the points chips on it that a map of a run pays.
func _scene_has_points(podium: ResultsScreen) -> bool:
	for label: Node in podium.find_children("*", "Label", true, false):
		if (label as Label).text.begins_with("+") and (label as Label).text.ends_with(" points"):
			return true
	return false


## Everybody's points so far, by seat, for the two ends to be held against each other.
func _scores(match_node: Match) -> String:
	var parts: PackedStringArray = []
	for slot: PlayerSlot in match_node.slots:
		parts.append("%d=%d" % [slot.index, Game.grand_prix.total(slot.index)])
	return " ".join(parts)


func multiplayer_peers() -> int:
	if not Net.online() or multiplayer.multiplayer_peer == null:
		return 0
	return multiplayer.get_peers().size()


## However the host's door is got through: with a wrong password first and back from Play LAN
## for it, then with the right one when it is asked for, or straight in with no password at all.
func _through_the_door() -> bool:
	if _wrong_first and not await _back_for_a_wrong_password():
		return false
	if _password.is_empty():
		return true
	return await _through_the_password(_password)


## The host wants a password: the room this client knocked from asks for it, [param typed] is
## given, and a room of its own is opened to knock again with it.
func _through_the_password(typed: String) -> bool:
	if not await _until(
		func() -> bool: return _password_pane() != null, 20.0, "the host asked for a password"
	):
		return false
	var asked := _scene()
	var pane := _password_pane()
	pane._box.text = typed
	pane._join.pressed.emit()
	return await _until(
		func() -> bool: return _scene() != asked, 10.0, "it knocked again with the password"
	)


## A wrong password given when asked: back on Play LAN, told so, and joining again from there
## the way a player would, with the address in the boxes.
func _back_for_a_wrong_password() -> bool:
	if not await _through_the_password(_password + " not"):
		return false
	if not await _until(
		func() -> bool: return _scene() != null and _scene().scene_file_path == ONLINE_SCENE,
		10.0,
		"a wrong password went back to Play LAN"
	):
		return false
	var lan := _scene()
	_check(lan.status.text == "Wrong password", "and said it was wrong")
	lan.name_field.text = "" if _nameless else "Client"
	lan.address_field.text = "127.0.0.1"
	lan.port_field.text = str(_port)
	lan.join_button.pressed.emit()
	return true


func _password_pane() -> PasswordPane:
	var scene := _scene()
	if scene == null:
		return null
	return scene.get_node_or_null("Password") as PasswordPane


func _scene() -> Node:
	var scene := get_tree().current_scene
	return scene if is_instance_valid(scene) else null


func _until(condition: Callable, seconds: float, what: String) -> bool:
	var ends := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < ends:
		if _failed:
			return false
		if condition.call():
			_say("ok: %s" % what)
			return true
		await get_tree().process_frame
	_fail("timed out: %s" % what)
	return false


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame


func _check(passed: bool, what: String) -> bool:
	if passed:
		_say("ok: %s" % what)
	else:
		_fail(what)
	return passed


func _fail(what: String) -> void:
	if _failed:
		return
	_failed = true
	printerr("MPCHECK %s FAIL: %s" % [_role, what])


func _say(what: String) -> void:
	print("MPCHECK %s %s (%.1f s)" % [_role, what, Time.get_ticks_msec() / 1000.0])
