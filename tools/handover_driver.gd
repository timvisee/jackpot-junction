extends "res://tools/multiplayer_driver.gd"
## Development harness: a LAN game handed to a new host as its host goes, GAME.md 10.8, through
## the real scenes, a process for each machine. The host opens a room, two clients sit down in it,
## the first before the second, and the host goes: the first in line hosts the game next and the
## second follows them in. With --in-a-map the host sends the room to a map first and goes during
## it: the new host carries the map on, the same map with its clock where it was, and the second
## sits down in it again. Otherwise the host goes from the lobby, and the new host opens a lobby,
## never a map. Started by tools/multiplayer_check.gd with --handover, and says what it saw the
## way tools/multiplayer_driver.gd does, a line starting MPCHECK for every step.
##
##   godot --headless --path . -s tools/multiplayer_check.gd -- --handover --role=host --port=7855
##   ... --role=first, then --role=second, each with the same port and --in-a-map or not

## The map played with --in-a-map, chosen for a few minutes: long enough to be left in the middle
## of.
const MAP := &"lucky_crossing"
const MINUTES := 3

var _in_a_map := false


func _run() -> void:
	_in_a_map = "--in-a-map" in OS.get_cmdline_user_args()
	multiplayer.server_disconnected.connect(func() -> void: _say("the host hung up"))
	# Settings of its own, by process, since three run at once.
	Game.settings = Settings.new()
	Game.settings.profile.stats[&"maps"] = float(TableCards.Card.size())
	Game.settings.path = "user://handover_check_%s_%d.cfg" % [_role, OS.get_process_id()]
	# What hands the game on, which a run from a script under tools/ is not given by Game.
	if _role != "host":
		Game.add_child(load("res://scenes/net/host_handover.gd").new())
	match _role:
		"host":
			await _host_goes()
		"first":
			await _first_takes_it_on()
		"second":
			await _second_follows()
		_:
			_fail("no --role=host, first or second")
	if not _failed and not _finished:
		_fail("stopped before the end")
	if not _failed:
		_say("PASSED")
	Settings.remove_files(Game.settings.path)
	Game.quit(1 if _failed else 0)


## Opens a room, waits for both clients and for them to have been told who hosts next, sends the
## room to a map with --in-a-map and plays a little of it, and goes.
func _host_goes() -> void:
	var config := MatchConfig.from_settings(Game.settings)
	config.online = "host"
	config.port = _port
	config.human_names = ["Old host"] as Array[String]
	Game.go_to_waiting(config)
	var room := await _room()
	if room == null:
		return
	var pane: HostSettings = room.host_settings
	if not _check(pane != null and pane.is_open(), "the match settings are up in the room"):
		return
	pane.options.choose(false)
	pane.options.map_option.selected = ArenaMaps.index_of(MAP)
	pane.options.bots_option.selected = 1
	pane.options.minutes_option.selected = MatchOptions.match_lengths().find(MINUTES)
	pane.close()
	if not await _until(
		func() -> bool: return _remote(room.match_node) == 2, 40.0, "both clients sat down"
	):
		return
	# Told who hosts after it, and knocked on a few times, as a host long in a room has.
	await _seconds(2.0)
	if _in_a_map:
		room.ready_room.go_now()
		var arena := await _up_in_a_map(true)
		if arena == null:
			return
		var played: Match = arena.match_node
		if not await _until(func() -> bool: return played.is_running(), 30.0, "the lamps went"):
			return
		await _seconds(3.0)
		_say("leaving with %.0f s on the clock" % played.time_left)
	_say("leaving")
	Game.go_to_title()
	_finished = true
	await _seconds(1.0)


## Joins first, so it is first in line; once the host goes, hosts the game: a lobby from a lobby,
## the map carried on from a map, and the second player sits down with it.
func _first_takes_it_on() -> void:
	await _frames(60)
	var room := await _joined()
	if room == null or not await _in_line(room.session, 0, "told it hosts next"):
		return
	var map := &""
	if _in_a_map:
		map = await _the_map_played(true)
	if _failed:
		return
	var hosting := await _until(
		func() -> bool: return Net.session != null and Net.session.is_host,
		30.0,
		"the host went and this machine hosts the game now"
	)
	if not hosting:
		return
	var on := await _carries_on(map) if _in_a_map else await _opens_the_lobby()
	if not on:
		return
	await _until(func() -> bool: return multiplayer_peers() == 0, 30.0, "the other player finished")
	_finished = true


## Joins second, so it is second in line; once the host goes, follows the first in line into the
## game they host: their lobby, or the map carried on, sat down in it again.
func _second_follows() -> void:
	await _frames(240)
	var room := await _joined()
	if room == null or not await _in_line(room.session, 1, "told it is second in line"):
		return
	# By its id: a lambda holding the session itself would hold it freed once the host goes.
	var old := (room.session as NetSession).get_instance_id()
	var map := &""
	if _in_a_map:
		map = await _the_map_played(false)
	if _failed:
		return
	var following := await _until(
		func() -> bool:
			return (
				Net.session != null
				and Net.session.get_instance_id() != old
				and not Net.session.is_host
				and Net.session.local_slot >= 0
			),
		40.0,
		"the host went and this machine sat down at the new host"
	)
	if not following:
		return
	var back := await _back_in_the_map(map) if _in_a_map else await _in_the_lobby()
	if not back:
		return
	await _seconds(2.0)
	_finished = true


## Whether [param session] has been told this machine is [param place] in the line of two who host
## after the host, saying [param what].
func _in_line(session: NetSession, place: int, what: String) -> bool:
	var me := multiplayer.get_unique_id()
	return await _until(
		func() -> bool:
			var line := session.host_controls.succession
			return line.size() == 2 and int(line[place]["peer"]) == me,
		20.0,
		what
	)


## The map the host sent the room to, once it is up here, and once its lamps went with
## [param lamps]; empty, and failed, if it never is.
func _the_map_played(lamps: bool) -> StringName:
	var arena := await _up_in_a_map(false)
	if arena == null:
		return &""
	var played: Match = arena.match_node
	if (
		lamps
		and not await _until(func() -> bool: return played.is_running(), 30.0, "the lamps went")
	):
		return &""
	return played.rules.map


## The new host's lobby: its match settings, a lobby and not a map, the other player in it.
func _opens_the_lobby() -> bool:
	var lobby := await _room()
	if lobby == null:
		return false
	_check(lobby.host_settings != null, "the new host has the match settings")
	_check(Net.session.match_node == lobby.match_node, "a lobby, not a map")
	return await _until(
		func() -> bool: return _remote(lobby.match_node) == 1,
		40.0,
		"the other player followed into the lobby"
	)


## The new host's map: [param map] carried on with its clock, the other player back in it, and
## playing on after a countdown.
func _carries_on(map: StringName) -> bool:
	var carried := await _up_in_a_map(true, 1)
	if carried == null:
		return false
	var played: Match = carried.match_node
	_check(played.rules.map == map, "the same map carried on")
	var left := played.time_left
	_check(left < played.rules.duration - 2.0, "its clock where it was, %.0f s left" % left)
	return await _until(
		func() -> bool: return played.is_running(), 40.0, "and it plays on after a countdown"
	)


## In the new host's lobby, sat down.
func _in_the_lobby() -> bool:
	var lobby := await _room()
	return (
		lobby != null
		and _check(Net.session.match_node == lobby.match_node, "in the new host's lobby")
	)


## Back in [param map] at the new host, and playing on.
func _back_in_the_map(map: StringName) -> bool:
	var carried := await _up_in_a_map(false)
	if carried == null:
		return false
	var played: Match = carried.match_node
	_check(played.rules.map == map, "the same map carried on here too")
	return await _until(func() -> bool: return played.is_running(), 40.0, "and it plays on here")


## Joins the host's room on this machine and sits down in it, and returns the room.
func _joined() -> Node:
	var config := MatchConfig.new()
	config.online = "join"
	config.address = "127.0.0.1"
	config.port = _port
	config.human_names = ["First" if _role == "first" else "Second"] as Array[String]
	Game.go_to_waiting(config)
	var room := await _room()
	if room == null:
		return null
	var session: NetSession = room.session
	var match_node: Match = room.match_node
	if not await _until(
		func() -> bool:
			return session.local_slot >= 0 and match_node.slots.size() > session.local_slot,
		30.0,
		"seated in the room"
	):
		return null
	return room


## Waits for a map to be up and this machine in it: hosting it with [param hosting], with
## [param away] players at other machines seated, or seated in it as a client.
func _up_in_a_map(hosting: bool, away := 2) -> Node:
	var up := await _until(
		func() -> bool:
			var scene := _scene()
			if scene == null or scene.scene_file_path != MATCH_SCENE or scene.match_node == null:
				return false
			var match_node: Match = scene.match_node
			if match_node.arena == null:
				return false
			if match_node.slots.is_empty() or match_node.hud == null:
				return false
			if not hosting:
				return (
					match_node.puppet
					and match_node.local_slot >= 0
					and match_node.slots.size() > match_node.local_slot
				)
			return not match_node.puppet and _remote(match_node) == away,
		60.0,
		"a map is up and everybody is seated" if hosting else "a map is up and this seat in it"
	)
	return _scene() if up else null
