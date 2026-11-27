extends "res://tools/multiplayer_driver.gd"
## Development harness: a LAN game handed to a new host as its host goes, GAME.md 10.8, through
## the real scenes, a process for each machine. The host opens a room, two clients sit down in it,
## the first before the second, and the host goes: the first in line hosts the game next and the
## second follows them in. With --in-a-map the host sends the room to a map first and goes during
## it: the new host carries the map on, the same map with its clock where it was, and the second
## sits down in it again. Otherwise the host goes from the lobby, and the new host opens a lobby,
## never a map. With --make-host the host hands the game to the second in line by Make host
## instead, from the lobby or with --in-a-map during the map, and follows them in with the first,
## back in its own kart with its score in a map. With --killed, and --in-a-map, the host's process
## is killed during the map, as a crash goes, saying nothing to anybody: the others find it gone
## once its line goes quiet, and the game is handed down the line they were told before, each back
## in its own kart by its secret. Started by tools/multiplayer_check.gd with --handover, and says
## what it saw the way tools/multiplayer_driver.gd does, a line starting MPCHECK for every step.
##
##   godot --headless --path . -s tools/multiplayer_check.gd -- --handover --role=host --port=7855
##   ... --role=first, then --role=second, each with the same port and the same --in-a-map,
##   --make-host or --killed

## The map played with --in-a-map, chosen for a few minutes: long enough to be left in the middle
## of.
const MAP := &"lucky_crossing"
const MINUTES := 3
## What the old host has banked as it makes another host during a map, to find again.
const BANKED := 345
## How long the others may take to find a killed host gone, as its line goes quiet, see [NetLine],
## and to ask after it at its address before going down the line, see [HostHandover], in seconds.
const FOUND_GONE := 60.0

var _in_a_map := false
var _made := false
var _killed := false


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_in_a_map = "--in-a-map" in args
	_made = "--make-host" in args
	_killed = "--killed" in args
	multiplayer.server_disconnected.connect(func() -> void: _say("the host hung up"))
	# Settings of its own, by process, since three run at once.
	Game.settings = Settings.new()
	Game.settings.profile.stats[&"maps"] = float(TableCards.Card.size())
	Game.settings.path = "user://handover_check_%s_%d.cfg" % [_role, OS.get_process_id()]
	# What hands the game on, which a run from a script under tools/ is not given by Game.
	Game.add_child(load("res://scenes/net/host_handover.gd").new())
	# Who hosts next: the first in line as the host goes, the second as it is made host.
	var next := 1 if _made else 0
	match _role:
		"host":
			await _host_goes()
		"first", "second":
			var place := 0 if _role == "first" else 1
			if place == next:
				await _takes_it_on(place)
			else:
				await _follows(place)
		_:
			_fail("no --role=host, first or second")
	if not _failed and not _finished:
		_fail("stopped before the end")
	if not _failed:
		_say("PASSED")
	Settings.remove_files(Game.settings.path)
	Game.quit(1 if _failed else 0)


## Opens a room, waits for both clients and for them to have been told who hosts next, sends the
## room to a map with --in-a-map and plays a little of it, and goes; with --make-host hands the
## game to the second in line from Manage players instead, and follows them in.
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
	var played: Match = null
	if _in_a_map:
		room.ready_room.go_now()
		var arena := await _up_in_a_map(true)
		if arena == null:
			return
		played = arena.match_node
		if not await _until(func() -> bool: return played.is_running(), 30.0, "the lamps went"):
			return
		await _seconds(3.0)
	if _made:
		await _makes_host(Net.session, played)
		return
	if played != null:
		_say("leaving with %.0f s on the clock" % played.time_left)
	if _killed:
		# Nothing said, nothing closed: tools/multiplayer_check counts this process's death as its
		# end.
		_say("killed")
		OS.kill(OS.get_process_id())
	_say("leaving")
	Game.go_to_title()
	_finished = true
	await _seconds(1.0)


## Make host to the second in line, as Manage players does it, from the lobby or during
## [param played]: this machine then follows them in as everybody else does, sat down in their
## lobby, or back in its own kart in the map with what it had banked.
func _makes_host(session: NetSession, played: Match) -> void:
	var controls := session.host_controls
	var old := session.get_instance_id()
	var to := int(controls.succession_line()[1]["peer"])
	var color := -1
	# Said now: the match is freed once this machine follows, and a freed match reads as null.
	var in_map := played != null
	if in_map:
		for slot: PlayerSlot in played.slots:
			if slot.is_local_human():
				slot.banked = BANKED
				color = slot.color_index
		# Seen at the others before it goes.
		await _seconds(0.5)
	_say("making the second in line host%s" % (" during the map" if in_map else ""))
	controls.hand_on(to)
	if not await _sat_down_away_from(old):
		return
	var back := await _back_in_the_map(MAP, color, BANKED) if in_map else await _in_the_lobby()
	if not back:
		return
	await _seconds(2.0)
	_finished = true


## Joins as [param place] in line and hosts the game next: as the host goes, a lobby from a lobby
## or the map carried on from a map; as it is made host, a lobby. The others sit down with it.
func _takes_it_on(place: int) -> void:
	await _frames(60 + 180 * place)
	var room := await _joined()
	if room == null or not await _in_line(room.session, place, "told its place in line"):
		return
	var map := &""
	if _in_a_map:
		map = await _the_map_played(true)
	if _failed:
		return
	var hosting := await _until(
		func() -> bool: return Net.session != null and Net.session.is_host,
		FOUND_GONE if _killed else 30.0,
		"the game came to this machine and it hosts it now"
	)
	if not hosting:
		return
	var others := 2 if _made else 1
	var on := await _carries_on(map, others) if _in_a_map else await _opens_the_lobby(others)
	if not on:
		return
	await _until(func() -> bool: return multiplayer_peers() == 0, 30.0, "the others finished")
	_finished = true


## Joins as [param place] in line and follows whoever hosts next into the game they host: their
## lobby, or the map carried on, sat down in it again.
func _follows(place: int) -> void:
	await _frames(60 + 180 * place)
	var room := await _joined()
	if room == null or not await _in_line(room.session, place, "told its place in line"):
		return
	# By its id: a lambda holding the session itself would hold it freed once the host goes.
	var old := (room.session as NetSession).get_instance_id()
	var map := &""
	var color := -1
	if _in_a_map:
		map = await _the_map_played(false)
		var playing: Match = _scene().match_node if not _failed else null
		color = playing.slots[playing.local_slot].color_index if playing != null else -1
	if _failed or not await _sat_down_away_from(old):
		return
	var back := await _back_in_the_map(map, color) if _in_a_map else await _in_the_lobby()
	if not back:
		return
	await _seconds(2.0)
	_finished = true


## Whether this machine sat down at the game's new host, in another session than [param old].
func _sat_down_away_from(old: int) -> bool:
	return await _until(
		func() -> bool:
			return (
				Net.session != null
				and Net.session.get_instance_id() != old
				and not Net.session.is_host
				and Net.session.local_slot >= 0
			),
		FOUND_GONE if _killed else 40.0,
		"the game changed hands and this machine sat down at the new host"
	)


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


## The new host's lobby: its match settings, a lobby and not a map, the [param others] in it.
func _opens_the_lobby(others: int) -> bool:
	var lobby := await _room()
	if lobby == null:
		return false
	_check(lobby.host_settings != null, "the new host has the match settings")
	_check(Net.session.match_node == lobby.match_node, "a lobby, not a map")
	if not _told_it_hosts() or not await _word_gone():
		return false
	return await _until(
		func() -> bool: return _remote(lobby.match_node) == others,
		40.0,
		"the others followed into the lobby"
	)


## The new host's map: [param map] carried on with its clock, the [param others] back in it, and
## playing on after a countdown.
func _carries_on(map: StringName, others: int) -> bool:
	var carried := await _up_in_a_map(true, others)
	if carried == null:
		return false
	var played: Match = carried.match_node
	_check(played.rules.map == map, "the same map carried on")
	var left := played.time_left
	_check(left < played.rules.duration - 2.0, "its clock where it was, %.0f s left" % left)
	if not _told_it_hosts():
		return false
	# While it is told, the players here count as still on their way on every screen.
	_check(played.loading.x < played.loading.y, "counted as still on its way while it is told")
	# Held on the grid until the other player is back and has the map up, and the word has gone,
	# then counted down.
	var controls := Net.session.host_controls
	if not await _until(
		func() -> bool: return played.state != Match.State.LOBBY, 40.0, "the countdown starts"
	):
		return false
	var back := controls._returned.keys()
	_check(
		not back.is_empty() and back.all(func(peer: int) -> bool: return controls._built.has(peer)),
		"only once the other player was back with the map up"
	)
	_check(not HostControls.being_told(get_tree()), "and once the word had gone, never over it")
	return await _until(
		func() -> bool: return played.is_running(), 40.0, "and it plays on after a countdown"
	)


## Whether this machine, the game's new host, is being told so, on the handover's own pane.
func _told_it_hosts() -> bool:
	return _check(HostControls.being_told(get_tree()), "told it is the host now")


## Whether the new host's word went by itself, nothing to close.
func _word_gone() -> bool:
	return await _until(
		func() -> bool: return not HostControls.being_told(get_tree()),
		10.0,
		"and the word went by itself"
	)


## Whether this machine's list of players says who hosts the game: the one it followed in.
func _sees_who_hosts() -> bool:
	return await _until(
		func() -> bool:
			for guest: Dictionary in Net.session.host_controls.guests():
				if bool(guest.get("host", false)):
					return true
			return false,
		10.0,
		"its players list says who hosts the game now"
	)


## In the new host's lobby, sat down.
func _in_the_lobby() -> bool:
	var lobby := await _room()
	return (
		lobby != null
		and _check(Net.session.match_node == lobby.match_node, "in the new host's lobby")
		and await _sees_who_hosts()
	)


## Back in [param map] at the new host, in its own kart, the one in [param color], with
## [param banked] banked where it is given, and playing on.
func _back_in_the_map(map: StringName, color: int, banked := -1) -> bool:
	var carried := await _up_in_a_map(false)
	if carried == null:
		return false
	var played: Match = carried.match_node
	_check(played.rules.map == map, "the same map carried on here too")
	var mine := played.slots[played.local_slot].color_index
	_check(mine == color, "in its own kart again, color %d" % mine)
	if banked >= 0:
		var has := played.slots[played.local_slot].banked
		_check(has == banked, "with what it had banked, %d" % has)
	if not await _sees_who_hosts():
		return false
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
