extends Node
## Development harness: plays a game on a dedicated server, GAME.md 9.3a, through the real
## scenes, the way the people in it would, and says at every step whether what should have
## happened did. Started by tools/server_check.gd, which tools/server_check runs as three clients
## of a real server, each a process of its own on this machine: nothing is shared between them
## but the server, so what each checks is what that machine really saw.
##
## The maker makes a game from Play Online and chooses a Grand Prix of two maps, the joiner joins it
## from the list and the watcher watches it. Both players drive onto the pad, each map is played to
## its whistle, and from the podiums the maker goes on to the second map and then takes everybody
## back to the lobby. There the maker hands the host's say to the joiner with Make host, the joiner
## leaves and the say passes back to the maker, the maker leaves, and the watcher is told the game is
## over and is back on the server's games. Every step prints a line starting SVCHECK, and a step that
## does not happen in time fails the run with the reason.

## The server's password, as tools/server_check gives it the server.
const SERVER_PASSWORD := "open sesame"
const WAITING_SCENE := "res://scenes/waiting/waiting_room.tscn"
const MATCH_SCENE := "res://scenes/match/match_scene.tscn"
const PLAY_ONLINE_SCENE := "res://scenes/ui/play_online.tscn"
const SERVER_GAMES_SCENE := "res://scenes/ui/server_games.tscn"
## How far a kart walks toward the pad in a frame, and where on it each seat parks, as the LAN
## check has it: the host only believes a client about its kart while it stays within reach.
const STEP := 0.05
const SPOTS: Array[Vector3] = [
	Vector3(-1.3, 0.0, -1.3),
	Vector3(1.3, 0.0, 1.3),
	Vector3(1.3, 0.0, -1.3),
	Vector3(-1.3, 0.0, 1.3)
]

## How many maps the Grand Prix runs.
const MAPS := 2

var _role := ""
var _port := 7990
## How long the maker's match runs, in seconds: the five a debug build offers unless told otherwise,
## as a release server will be, which offers none that short.
var _length := MatchOptions.DEBUG_LENGTH
var _failed := false
var _finished := false


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):
			_role = arg.get_slice("=", 1)
		elif arg.begins_with("--port="):
			_port = int(arg.get_slice("=", 1))
		elif arg.begins_with("--length="):
			_length = int(arg.get_slice("=", 1))
	_run.call_deferred()


func _run() -> void:
	# Settings of its own, so a check never writes anybody's.
	Game.settings = Settings.new()
	Game.settings.path = "user://server_check_%s.cfg" % _role
	Game.settings.player_names[0] = _role.capitalize()
	Game.settings.last_server = "127.0.0.1"
	Game.settings.last_server_port = _port
	# The maker's game is named as a test's, the way tools/server_check names the server, GAME.md
	# 9.3: a game's own process is the game, and cannot tell.
	Game.settings.lobby_title = "Server check (test)"
	match _role:
		"maker":
			await _maker()
		"joiner":
			await _joiner()
		"watcher":
			await _watcher()
		"stranger":
			await _stranger()
		_:
			_fail("no --role=maker, joiner, watcher or stranger")
	if not _failed and not _finished:
		_fail("stopped before the end")
	if not _failed:
		_say("PASSED")
	SafeFile.remove(Game.settings.path)
	Game.quit(1 if _failed else 0)


## Makes the game, chooses the match, plays it, takes everybody back and leaves.
func _maker() -> void:
	var screen := await _play_online()
	if screen == null:
		return
	screen.make_button.pressed.emit()
	var room := await _room()
	if room == null:
		return
	var session: NetSession = room.session
	if not await _until(session.host_controls.mine, 20.0, "the maker has the host's say"):
		return
	var pane: HostSettings = room.host_settings
	if not await _until(pane.is_open, 10.0, "the match settings came up with it"):
		return
	_check(pane.on_lobby(), "Lobby settings first, as a host's are")
	pane._lobby._back.pressed.emit()
	pane.options.choose(true)
	pane.options.maps_option.selected = MatchOptions.MAPS.find(MAPS)
	pane.options.bots_option.selected = MatchOptions.BOTS.find(1)
	pane.options.minutes_option.selected = MatchOptions.match_lengths().find(_length)
	pane.options.overtime_option.selected = MatchOptions.OVERTIME.find(false)
	pane.close()
	var ready_room: ReadyRoom = room.ready_room
	if not await _until(
		func() -> bool: return ready_room._plan.text.begins_with("Next: Grand Prix of %d" % MAPS),
		10.0,
		"the server told the room what the match is"
	):
		return
	var match_node: Match = room.match_node
	if not await _until(
		func() -> bool: return SeatLimit.players(match_node) == 2, 60.0, "the joiner sat down"
	):
		return
	var first := await _play(room)
	if first == null:
		return
	var podium: ResultsScreen = first.match_node.hud._results
	if not _check(podium._next.visible, "the first podium offers Next map to the maker"):
		return
	_check(not podium._host_decides.visible, "and does not say the host decides")
	podium._next.pressed.emit()
	var second := await _podium_of(2)
	if second == null:
		return
	podium = second.match_node.hud._results
	if not await _until(podium._continue.is_visible_in_tree, 20.0, "the last podium goes on"):
		return
	podium._continue.pressed.emit()
	# After the last map the finale in the room comes first, and the standings go up over it.
	if not await _until(
		func() -> bool: return podium.visible and podium._lobby.visible,
		30.0,
		"and after the finale the run's standings offer Back to lobby"
	):
		return
	podium._lobby.pressed.emit()
	var back := await _room()
	if back == null:
		return
	if not await _until(back.host_settings.is_open, 20.0, "the match settings came up again"):
		return
	back.host_settings.close()
	if not await _hand_the_say_on(back):
		return
	# The joiner leaves, and the say comes back to whoever has been in the longest since.
	if not await _until(session.host_controls.mine, 40.0, "the say came back once the joiner left"):
		return
	_check(_told(back, "The host left."), "and the maker was told it is the host again")
	await _seconds(1.0)
	_say("leaving")
	Game.go_to_title()
	_finished = true
	await _seconds(1.0)


## Make host on the joiner's row of Manage players, from the pause menu, the way a player hands the
## say on, yes to the question it asks first, and the say gone from here with the pane.
func _hand_the_say_on(room: Node) -> bool:
	var session: NetSession = room.session
	if not await _until(
		func() -> bool: return session.host_controls.guests().size() >= 2,
		10.0,
		"Manage players has the joiner and the watcher to list"
	):
		return false
	var menu: PauseMenu = room.get_node("PauseMenu")
	menu.set_paused(true)
	menu._manage.pressed.emit()
	var hand: Button = null
	# Each somebody in the game is a seat card, its buttons at its right end, see [SeatCard].
	for row: Node in menu._players._rows.get_children():
		var card := row as SeatCard
		if card != null and card.name_label.text == "Joiner":
			for button: Node in card.actions.get_children():
				if button is Button and (button as Button).text == "Make host":
					hand = button
	if not _check(hand != null, "Manage players has Make host beside the joiner"):
		return false
	hand.pressed.emit()
	if not _check(menu.asking(), "Make host asks first"):
		return false
	menu._confirm.yes_button().pressed.emit()
	if not await _until(
		func() -> bool: return not session.host_controls.mine(), 10.0, "Make host handed it on"
	):
		return false
	await _frames(2)
	_check(not menu._players.visible, "and Manage players went with the say")
	menu.set_paused(false)
	return true


## Whether the notice over [param room] says [param words] at the start of its message.
func _told(room: Node, words: String) -> bool:
	var notice := room.get_node_or_null("Notice") as NoticePane
	return notice != null and notice.visible and notice._message.text.begins_with(words)


## Joins the maker's game from the list, plays it, is handed the say with Make host, and leaves.
func _joiner() -> void:
	var screen := await _play_online()
	if screen == null:
		return
	var join := await _listed_button(screen, "Join")
	if join == null:
		return
	var titles := screen.find_children("*", "Label", true, false).map(
		func(each: Node) -> String: return (each as Label).text
	)
	_check("Server check (test)" in titles, "the server's name is over its games")
	_check(
		MenuTheme.lines_of(join).begins_with("Server check (test)\nIn the lobby"),
		"the maker's game is listed by its name, over how it stands"
	)
	join.pressed.emit()
	var room := await _room()
	if room == null:
		return
	var session: NetSession = room.session
	_check(not session.host_controls.mine(), "the joiner has no say")
	_check(
		room.ready_room._online_hint.text.begins_with(
			"Friends find this game in Play Online, on Server check (test) at 127.0.0.1:"
		),
		"the lobby says which server friends find the game on"
	)
	var first := await _play(room)
	if first == null:
		return
	var podium: ResultsScreen = first.match_node.hud._results
	_check(not podium._next.visible, "the first podium offers the joiner no way on")
	_check(podium._host_decides.visible, "and says the host decides")
	_check(podium._host_decides.text == "The host starts the next map.", "which is the next map")
	if await _podium_of(2) == null:
		return
	var back := await _room()
	if back == null:
		return
	if not await _until(
		func() -> bool: return is_instance_valid(back) and session.host_controls.mine(),
		40.0,
		"the maker handed the joiner the say"
	):
		return
	_check(_told(back, "Maker made you the host."), "and it was told who made it the host")
	await _seconds(2.0)
	_say("leaving")
	Game.go_to_title()
	_finished = true
	await _seconds(1.0)


## Says garbage for a hello, as a scan or another program would, at the server and at its game once
## it is listed: dropped at both, and written in the server's log, see [NetGuard], which is checked
## there. Everybody else plays on meanwhile.
func _stranger() -> void:
	await _garbage_at(_port)
	var screen := await _play_online()
	if screen == null:
		return
	if not await _until(
		func() -> bool: return not screen.link.games.is_empty(), 60.0, "the maker's game is listed"
	):
		return
	var at := int(screen.link.games[0]["port"])
	Net.close()
	await _garbage_at(at)
	await _outsider_at(at)
	_finished = true


## A player who never came by the server's list knocking at [param at], one of its games' own
## ports: turned away, since the server has a password, tools/server_check, that they never gave,
## and which the game has from the environment the server started it in.
func _outsider_at(at: int) -> void:
	var root := Node.new()
	root.name = "Outsider"
	get_tree().root.add_child(root)
	var path := root.get_path()
	get_tree().set_multiplayer(SceneMultiplayer.new(), path)
	var session := NetSession.new()
	session.name = "Session"
	session.player_name = "Outsider"
	root.add_child(session)
	var why := [""]
	session.refused.connect(func(reason: String) -> void: why[0] = reason)
	if session.join("127.0.0.1", at) != OK:
		_fail("could not reach port %d" % at)
		return
	if await _until(
		func() -> bool: return not str(why[0]).is_empty(),
		20.0,
		"an outsider at the game's own port was turned away"
	):
		_check(
			why[0] == "This server has a password: join its games from Play Online",
			"and told to come by the server's list"
		)
	root.queue_free()
	await _seconds(0.2)
	get_tree().set_multiplayer(null, path)


## A connection of the game's own kind to [param at] whose first word is not a hello at all.
func _garbage_at(at: int) -> void:
	var root := Node.new()
	root.name = "Stranger%d" % at
	get_tree().root.add_child(root)
	var scene := SceneMultiplayer.new()
	get_tree().set_multiplayer(scene, root.get_path())
	scene.auth_callback = func(_id: int, _data: PackedByteArray) -> void: pass
	var hello := func(id: int) -> void:
		scene.send_auth(id, "GET / HTTP/1.1\r\n\r\n".to_utf8_buffer())
	scene.peer_authenticating.connect(hello)
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client("127.0.0.1", at) != OK:
		_fail("could not reach port %d" % at)
		return
	NetLine.compress(peer)
	scene.multiplayer_peer = peer
	await _seconds(1.5)
	peer.close()
	# The hello holds the multiplayer it is said on, and the multiplayer holds the hello: undone by
	# hand, or neither is ever freed.
	scene.peer_authenticating.disconnect(hello)
	scene.auth_callback = Callable()
	scene.multiplayer_peer = null
	get_tree().set_multiplayer(null, root.get_path())
	root.queue_free()
	_say("ok: said garbage at port %d" % at)


## Watches the maker's game from the list, all the way to being told it is over.
func _watcher() -> void:
	var screen := await _play_online()
	if screen == null:
		return
	var watch := await _listed_button(screen, "Watch")
	if watch == null:
		return
	watch.pressed.emit()
	if not await _room():
		return
	if not await _until(
		func() -> bool: return _scene() != null and _scene().scene_file_path == MATCH_SCENE,
		90.0,
		"followed the players into the arena"
	):
		return
	if not await _until(
		func() -> bool:
			var scene := _scene()
			return scene != null and scene.scene_file_path == SERVER_GAMES_SCENE,
		_length * MAPS + 120.0,
		"was told the game is over and went back to the server's games"
	):
		return
	var back := _scene()
	_check(
		back.note.text == "Everybody left, so the game is over" and back.note.visible,
		"which said why: %s" % back.note.text
	)
	_finished = true


## Play Online, connected to the server the check was given with Direct connect, and on to its
## games.
func _play_online() -> Control:
	Game.go_to_play_online()
	if not await _until(
		func() -> bool:
			var scene := _scene()
			return scene != null and scene.scene_file_path == PLAY_ONLINE_SCENE,
		20.0,
		"Play Online is up and waits for Connect"
	):
		return null
	var screen := _scene()
	screen.direct_button.pressed.emit()
	_check(screen.is_form_up(), "Direct connect put up the boxes")
	screen.connect_button.pressed.emit()
	# The server has a password, tools/server_check: asked for, and the joiner gets it wrong first.
	if not await _until(
		func() -> bool: return screen.password_dialog.is_open(),
		20.0,
		"the server asked for its password"
	):
		return null
	if _role == "joiner":
		screen.password_field.text = "not it"
		screen.password_button.pressed.emit()
		if not await _until(
			func() -> bool: return screen.password_dialog.said() == "Wrong password",
			20.0,
			"a wrong password was said to be wrong"
		):
			return null
	screen.password_field.text = SERVER_PASSWORD
	screen.password_button.pressed.emit()
	if not await _until(
		func() -> bool:
			var scene := _scene()
			return scene != null and scene.scene_file_path == SERVER_GAMES_SCENE,
		20.0,
		"Connect went on to the server's games"
	):
		return null
	return _scene()


## The button of the first game on the server's list, [param which] of Join and Watch.
func _listed_button(screen: Control, which: String) -> Button:
	var found := [null]
	if not await _until(
		func() -> bool:
			var games: GameList = screen._games
			for row: Node in games.get_children():
				for button: Node in row.get_children():
					if button is Button and String(button.name).begins_with(which):
						found[0] = button
						# By its name, since Watch is an eye with no word on it.
						return not (button as Button).disabled
			return false,
		60.0,
		"the maker's game is on the list to %s" % which.to_lower()
	):
		return null
	return found[0]


## The lobby this machine is in, once it is up and it is seated in it or watching.
func _room() -> Node:
	var up := await _until(
		func() -> bool:
			var scene := _scene()
			if scene == null or scene.scene_file_path != WAITING_SCENE:
				return false
			if scene.ready_room == null or scene.session == null:
				return false
			var session: NetSession = scene.session
			return session.watching or session.local_slot >= 0,
		40.0,
		"in the lobby"
	)
	return _scene() if up else null


## Onto the pad, into the arena when the room goes, and through the first map to its podium.
func _play(room: Node) -> Node:
	var match_node: Match = room.match_node
	var session: NetSession = room.session
	if not await _until(
		func() -> bool:
			if _scene() != room:
				return true
			_park(match_node, session.local_slot)
			return false,
		60.0,
		"everybody on the pad took the room to the arena"
	):
		return null
	return await _podium_of(1)


## Map [param round] of the run up and this machine seated in it, played to its podium.
func _podium_of(round: int) -> Node:
	if not await _until(
		func() -> bool:
			var scene := _scene()
			return (
				scene != null
				and scene.scene_file_path == MATCH_SCENE
				and scene.match_node != null
				and scene.match_node.rules.round == round
				and scene.match_node.local_slot >= 0
			),
		60.0,
		"seated on map %d" % round
	):
		return null
	var arena := _scene()
	if not await _until(
		func() -> bool:
			return (
				is_instance_valid(arena)
				and arena.match_node.hud != null
				and arena.match_node.hud._results.visible
			),
		_length + 60.0,
		"map %d was played to its podium" % round
	):
		return null
	return arena


## Walks the kart in [param seat] a step a frame toward a spot of its own on the pad.
func _park(match_node: Match, seat: int) -> void:
	if not is_instance_valid(match_node) or seat < 0 or seat >= match_node.slots.size():
		return
	var kart := match_node.slots[seat].kart
	if kart == null or not kart.is_inside_tree() or match_node.arena.junction == null:
		return
	var to := match_node.arena.junction.global_position + SPOTS[seat % SPOTS.size()]
	var way := to - kart.global_position
	way.y = 0.0
	kart.global_position += way if way.length() <= STEP else way.normalized() * STEP


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
	printerr("SVCHECK %s FAIL: %s" % [_role, what])


func _say(what: String) -> void:
	print("SVCHECK %s %s (%.1f s)" % [_role, what, Time.get_ticks_msec() / 1000.0])
