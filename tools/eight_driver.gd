extends "res://tools/multiplayer_driver.gd"
## Development harness: a room of eight online, GAME.md 9.3, through the real scenes and short.
## The host with two players at it and three clients with two each, so every seat of the room is
## somebody's at four machines; the room goes to a quick match on a map at the usual size, which
## eight karts play as its XL; every machine sees the eight start on spots of their own, the
## whistle goes, and every podium has a row for each of them. Started by tools/multiplayer_check.gd
## with --eight, and says what it saw the way tools/multiplayer_driver.gd does, a line starting
## MPCHECK for every step.
##
##   godot --headless --path . -s tools/multiplayer_check.gd -- --eight --role=host --port=7853

## How many play, how many at each machine, and so how many play at the clients.
const KARTS := 8
const HERE := 2
const AWAY := KARTS - HERE
## The map chosen, and what eight karts play it as.
const CHOSEN := &"lucky_crossing"
const PLAYED := &"lucky_crossing_xl"
## How far apart any two karts start, in meters, at the least.
const APART := 2.0


func _run() -> void:
	multiplayer.server_disconnected.connect(func() -> void: _say("the server hung up"))
	# Settings of its own, by process, since three clients run at once.
	Game.settings = Settings.new()
	Game.settings.path = "user://multiplayer_check_eight_%s_%d.cfg" % [_role, OS.get_process_id()]
	match _role:
		"host":
			await _host()
		"client":
			await _client()
		_:
			_fail("no --role=host or client")
	if not _failed and not _finished:
		_fail("stopped before the end")
	if not _failed and _role == "host" and Net.session != null:
		_check(Net.session.conduct.total == 0, "no client sent what no copy of the game sends")
	if not _failed:
		_say("PASSED")
	Settings.remove_files(Game.settings.path)
	Game.quit(1 if _failed else 0)


## Opens a lobby for eight with a second player here, waits for three clients of two, sends the
## room on to a quick match, and checks the arena, its start and its podium.
func _host() -> void:
	Game.settings.lobby_players = KARTS
	var config := MatchConfig.from_settings(Game.settings)
	config.online = "host"
	config.port = _port
	config.human_names = ["Host", "Beside"] as Array[String]
	Game.go_to_waiting(config)
	var room := await _room()
	if room == null:
		return
	var pane: HostSettings = room.host_settings
	if not _check(pane != null and pane.is_open(), "the match settings are up in the room"):
		return
	_check(room.session.door.max_players == KARTS, "the lobby takes eight")
	pane.options.choose(false)
	pane.options.map_option.selected = ArenaMaps.index_of(CHOSEN)
	pane.options.bots_option.selected = 0
	pane.options.small_maps_toggle.button_pressed = false
	pane.options.minutes_option.selected = MatchOptions.match_lengths().find(60)
	pane.close()
	var match_node: Match = room.match_node
	_check(match_node.join_human(0) != null, "a second player here took a seat")
	if not await _until(
		func() -> bool: return _remote(match_node) == AWAY,
		40.0,
		"six players sat down at three clients"
	):
		return
	_check(SeatLimit.full(match_node, room.session), "and the room is full")
	await _seconds(1.0)
	# Readying up on the pad has checks of its own; this is about the room of eight that goes.
	room.ready_room.everybody_ready.emit()
	var arena := await _arena()
	if arena == null:
		return
	var played: Match = arena.match_node
	_check(played.slots.size() == KARTS, "the arena seats eight")
	var people := 0
	for slot: PlayerSlot in played.slots:
		people += 1 if slot.is_human() else 0
	_check(people == KARTS, "every one of them a player")
	_check(played.rules.map == PLAYED, "%s is played as its XL" % CHOSEN)
	_check(_apart(played), "everybody starts on a spot of their own")
	if not await _until(func() -> bool: return played.is_running(), 30.0, "the lamps went"):
		return
	await _seconds(1.0)
	for slot: PlayerSlot in played.slots:
		slot.banked = 100 * (slot.index + 1)
	played._finish()
	var podium := await _podium(arena, 15.0)
	if podium == null:
		return
	_check(podium._compact and podium._rows.get_child_count() == KARTS, "a compact row each")
	await _until(func() -> bool: return multiplayer_peers() == 0, 30.0, "the clients finished")
	_finished = true


## Joins, sits a second player down beside the first, follows the host to the arena, and checks
## what it sees there.
func _client() -> void:
	var config := MatchConfig.new()
	config.online = "join"
	config.address = "127.0.0.1"
	config.port = _port
	config.human_names = ["Client"] as Array[String]
	# The host may still be opening its room.
	await _frames(60)
	Game.go_to_waiting(config)
	var room := await _room()
	if room == null:
		return
	var session: NetSession = room.session
	var match_node: Match = room.match_node
	if not await _until(
		func() -> bool:
			return session.local_slot >= 0 and match_node.slots.size() > session.local_slot,
		30.0,
		"seated in the room"
	):
		return
	session.add_seat(0)
	if not await _until(
		func() -> bool: return session.seats.size() == HERE and session.seats[1].slot >= 0,
		30.0,
		"a second player here was seated"
	):
		return
	session.seats[1].input = KartInput.new()
	var arena := await _arena()
	if arena == null:
		return
	var played: Match = arena.match_node
	if not await _until(
		func() -> bool: return played.puppet_karts.size() >= KARTS,
		30.0,
		"eight karts on this screen"
	):
		return
	_check(played.rules.max_players == KARTS, "the arena has eight seats")
	_check(played.rules.map == PLAYED, "%s is played as its XL" % CHOSEN)
	var here := 0
	for slot: PlayerSlot in played.slots:
		here += 1 if played.is_local_seat(slot.index) else 0
	_check(here == HERE, "both players here play it")
	if not played.is_running():
		_check(_apart(played), "everybody starts on a spot of their own")
	var podium := await _podium(arena, 40.0)
	if podium == null:
		return
	_check(podium._rows.get_child_count() == KARTS, "its podium has a row for each of the eight")
	_finished = true


## The quick match the room went to, once it is up and everybody is seated in it.
func _arena() -> Node:
	var up := await _until(
		func() -> bool:
			var scene := _scene()
			if scene == null or scene.scene_file_path != MATCH_SCENE or scene.match_node == null:
				return false
			var match_node: Match = scene.match_node
			if match_node.arena == null or match_node.slots.is_empty():
				return false
			if match_node.puppet:
				return match_node.local_slot >= 0
			return _remote(match_node) == AWAY,
		60.0,
		"the arena is up and everybody is seated"
	)
	return _scene() if up else null


## Whether no two karts of [param match_node] stand nearer each other than [constant APART].
func _apart(match_node: Match) -> bool:
	var karts: Array[Vector3] = []
	for slot: PlayerSlot in match_node.slots:
		if slot.kart != null:
			karts.append(slot.kart.global_position)
	for i: int in karts.size():
		for j: int in range(i + 1, karts.size()):
			if Vector2(karts[i].x, karts[i].z).distance_to(Vector2(karts[j].x, karts[j].z)) < APART:
				return false
	return karts.size() == KARTS
