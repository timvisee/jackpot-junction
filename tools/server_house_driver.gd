extends "res://tools/server_driver.gd"
## Development harness: the story's Final Hand at a dedicated server, STORY.md 8.1, through the real
## scenes and short. The maker of a game has the host's say and the Final Hand due, and the House
## deals it there; the joiner's next match is blacked out without the ticket; the server seats its
## bots as the maker's models; each screen plays it for its own player, the maker's stamp writing
## the ending and the joiner's keeping nothing; and once both are through the server takes the room
## back to its lobby. Started by tools/server_check.gd with --house, and says what it saw the way
## tools/server_driver.gd does, a line starting SVCHECK for every step.
##
##   godot --headless --path . -s tools/server_check.gd -- --house --role=maker --port=8000

const MAKER_NAME := "Dealer"


func _run() -> void:
	Game.settings = Settings.new()
	Game.settings.path = "user://server_check_house_%s.cfg" % _role
	Game.settings.player_names[0] = _role.capitalize()
	Game.settings.last_server = "127.0.0.1"
	Game.settings.last_server_port = _port
	Game.settings.lobby_title = "Server check house (test)"
	var profile := Game.settings.profile
	profile.license_number = "JJ-212212"
	# Due for the maker alone, who has the say: the joiner plays it through and keeps nothing.
	profile.story.seconds = Story.FINAL_HAND_AT if _role == "maker" else 0.0
	profile.license_holder = MAKER_NAME if _role == "maker" else "Joiner"
	# The story is on at both, which a run with no screen would otherwise leave off.
	Story.override = Story.Stage.CANDIDATE
	match _role:
		"maker":
			await _deals()
		"joiner":
			await _plays_along()
		_:
			_fail("no --role=maker or joiner")
	if not _failed and not _finished:
		_fail("stopped before the end")
	if not _failed:
		_say("PASSED")
	Settings.remove_files(Game.settings.path)
	Game.quit(1 if _failed else 0)


## Makes a game, takes the House's seat with the say, plays the Final Hand to its whistle, stamps,
## goes through the last lines, and is back in the lobby once the joiner is through too.
func _deals() -> void:
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
	if not await _until(
		func() -> bool:
			var pane := room.find_child("FinalHandPane", true, false) as FinalHandPane
			return pane != null and pane.dealt(),
		30.0,
		"the House deals its invitation to whoever has the say"
	):
		return
	(room.find_child("FinalHandPane", true, false) as FinalHandPane).take.pressed.emit()
	if not await _until(
		func() -> bool: return room.host_settings != null and room.host_settings.is_open(),
		30.0,
		"the seat is taken and the match settings are up"
	):
		return
	room.host_settings.close()
	# Short, for a check: the House's own is five minutes, and no overtime for a score of nothing.
	room.config.duration = float(_length)
	room.config.overtime = false
	room._say_the_plan()
	var match_node: Match = room.match_node
	if not await _until(
		func() -> bool: return SeatLimit.players(match_node) == 2, 60.0, "the joiner sat down"
	):
		return
	var arena := await _to_the_table(room)
	if arena == null:
		return
	var played: Match = arena.match_node
	if not await _until(
		func() -> bool:
			for slot: PlayerSlot in played.slots:
				if slot.player_name.begins_with(MAKER_NAME + " "):
					return true
			return false,
		20.0,
		"the server seated the bots as the maker's models"
	):
		return
	var table := await _whistle(arena)
	if table == null:
		return
	_check(table.evaluation.counts, "the maker's stamp counts")
	table.evaluation._on_stamped()
	_check(Game.settings.profile.story.ended(), "and is the ending")
	await _through(table)
	var back := await _room()
	if back == null:
		return
	await _seconds(1.0)
	_check(back.ready_room._plan_redacted == null, "back in the lobby nothing is blacked out")
	_say("leaving")
	Game.go_to_title()
	_finished = true
	await _seconds(1.0)


## Joins the maker's game, sees it blacked out, plays the House's table as its own candidate, stamps
## keeping nothing, and is back in the lobby once both are through.
func _plays_along() -> void:
	var screen := await _play_online()
	if screen == null:
		return
	var join := await _listed_button(screen, "Join")
	if join == null:
		return
	join.pressed.emit()
	var room := await _room()
	if room == null:
		return
	var lobby: ReadyRoom = room.ready_room
	if not await _until(
		func() -> bool: return lobby._plan_redacted != null, 60.0, "the next match is blacked out"
	):
		return
	_check(lobby._ticket == null, "without the dealer's ticket")
	var arena := await _to_the_table(room)
	if arena == null:
		return
	var table := await _whistle(arena)
	if table == null:
		return
	_check(not table.evaluation.counts, "the joiner's stamp keeps nothing")
	table.evaluation._on_stamped()
	_check(not Game.settings.profile.story.ended(), "and its story goes on")
	await _through(table)
	if await _room() == null:
		return
	await _seconds(2.0)
	_say("leaving")
	Game.go_to_title()
	_finished = true
	await _seconds(1.0)


## Onto the pad until the room goes, and the Final Hand's arena up with this machine seated in it,
## its own player the candidate.
func _to_the_table(room: Node) -> Node:
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
	if not await _until(
		func() -> bool:
			var scene := _scene()
			return (
				scene != null
				and scene.scene_file_path == MATCH_SCENE
				and scene.match_node != null
				and scene.match_node.local_slot >= 0
				and scene.match_node.arena != null
			),
		60.0,
		"seated at the House's table"
	):
		return null
	var arena := _scene()
	var played: Match = arena.match_node
	_check(played.rules.final_hand and Story.final_hand_on, "this screen plays the Final Hand")
	if not await _until(
		func() -> bool:
			var mine := FinalHand.candidate(played)
			return mine != null and mine.index == played.local_slot,
		20.0,
		"its own player is its candidate"
	):
		return null
	return arena


## The whistle and the House's evaluation on this slip, its table returned.
func _whistle(arena: Node) -> FinalHandTable:
	var table := arena.match_node.find_child("FinalHandTable", true, false) as FinalHandTable
	if not await _until(
		func() -> bool: return table != null and table.evaluation != null,
		_length + 60.0,
		"the House's evaluation is on this slip"
	):
		return null
	return table


## Continue, the last lines, the license put away: through.
func _through(table: FinalHandTable) -> void:
	table.evaluation.go_on.pressed.emit()
	if not await _until(
		func() -> bool: return get_tree().get_first_node_in_group(LastLines.GROUP) != null,
		10.0,
		"the last lines are up"
	):
		return
	(get_tree().get_first_node_in_group(LastLines.GROUP) as LastLines)._home()
	_say("through")
