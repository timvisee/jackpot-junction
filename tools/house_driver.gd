extends "res://tools/multiplayer_driver.gd"
## Development harness: the story's Final Hand online, STORY.md 8.1, through the real scenes and
## short. The host's profile has it due and deals it; a client's has not, and plays it all the same,
## its own player the candidate on its screen. The client's next match is blacked out in the lobby
## without the ticket; both screens play the House's table; at the whistle each has the House's
## evaluation of its own player, the host's stamp writing the ending and the client's keeping
## nothing; the client through first waits on its slip, saying the others are still with the House;
## and once the host is through too, the room is back in its lobby with an ordinary next match.
## Started by tools/multiplayer_check.gd with --house, and says what it saw the way
## tools/multiplayer_driver.gd does, a line starting MPCHECK for every step.
##
##   godot --headless --path . -s tools/multiplayer_check.gd -- --house --role=host --port=7854

const HOST_NAME := "Hostess"


func _run() -> void:
	multiplayer.server_disconnected.connect(func() -> void: _say("the server hung up"))
	# Settings of its own, by process, since the ending is written into the host's profile.
	Game.settings = Settings.new()
	Game.settings.path = "user://multiplayer_check_house_%s_%d.cfg" % [_role, OS.get_process_id()]
	var profile := Game.settings.profile
	profile.license_number = "JJ-212212"
	# Due at the host alone: the client plays it through and keeps nothing.
	profile.story.seconds = Story.FINAL_HAND_AT if _role == "host" else 0.0
	# The story is on at both, which a run with no screen would otherwise leave off.
	Story.override = Story.Stage.CANDIDATE
	match _role:
		"host":
			profile.license_holder = HOST_NAME
			await _host()
		"client":
			profile.license_holder = "Guest"
			await _client()
		_:
			_fail("no --role=host or client")
	if not _failed and not _finished:
		_fail("stopped before the end")
	if not _failed:
		_say("PASSED")
	Settings.remove_files(Game.settings.path)
	Game.quit(1 if _failed else 0)


## Opens a lobby, takes the House's seat, waits for the client, plays the Final Hand to its
## whistle, stamps, goes through the last lines once the client is through, and checks the room is
## back in its lobby with an ordinary next match.
func _host() -> void:
	var config := MatchConfig.from_settings(Game.settings)
	config.online = "host"
	config.port = _port
	config.human_names = [HOST_NAME] as Array[String]
	Game.go_to_waiting(config)
	var room := await _room()
	if room == null:
		return
	if not await _until(
		func() -> bool:
			var pane := room.find_child("FinalHandPane", true, false) as FinalHandPane
			return pane != null and pane.dealt(),
		30.0,
		"the House deals its invitation online"
	):
		return
	(room.find_child("FinalHandPane", true, false) as FinalHandPane).take.pressed.emit()
	if not await _until(
		func() -> bool: return room.host_settings != null and room.host_settings.is_open(),
		30.0,
		"the seat is taken and the match settings are up"
	):
		return
	_check(room.config.final_hand, "the House's table is set")
	room.host_settings.close()
	var match_node: Match = room.match_node
	if not await _until(
		func() -> bool: return _remote(match_node) == 1, 40.0, "the client sat down"
	):
		return
	await _seconds(1.0)
	room.ready_room.everybody_ready.emit()
	var arena := await _arena(true)
	if arena == null:
		return
	var played: Match = arena.match_node
	_check(played.rules.final_hand and Story.final_hand_on, "the room plays the Final Hand")
	var mine := FinalHand.candidate(played)
	_check(mine != null and mine.is_local_human(), "the host's own player is its candidate")
	if not await _until(
		func() -> bool:
			for slot: PlayerSlot in played.slots:
				if slot.input is BotInput and slot.player_name.begins_with(HOST_NAME + " "):
					return true
			return false,
		10.0,
		"the bots are the host's models"
	):
		return
	if not await _until(func() -> bool: return played.is_running(), 30.0, "the lamps went"):
		return
	await _seconds(1.0)
	var acted := await _acts(played)
	await _seconds(1.0)
	played._finish()
	var table := played.find_child("FinalHandTable", true, false) as FinalHandTable
	if (
		not acted
		or not await _until(
			func() -> bool: return table != null and table.evaluation != null,
			20.0,
			"the House's evaluation is on the host's slip"
		)
	):
		return
	table.evaluation._on_stamped()
	_check(Game.settings.profile.story.ended(), "the host's stamp is the ending")
	table.evaluation.go_on.pressed.emit()
	if not await _until(
		func() -> bool: return get_tree().get_first_node_in_group(LastLines.GROUP) != null,
		10.0,
		"the last lines are up"
	):
		return
	var client := multiplayer.get_peers()[0]
	if not await _until(
		func() -> bool: return Net.session.final_hand._through.has(client),
		60.0,
		"the client is through"
	):
		return
	_check(_scene() == arena, "and the room waits for the host")
	(get_tree().get_first_node_in_group(LastLines.GROUP) as LastLines)._home()
	var back := await _room()
	if back == null:
		return
	_check(not back.config.final_hand, "back in the lobby the next match is the room's own")
	_check(back.ready_room._plan_redacted == null, "and not blacked out")
	await _until(func() -> bool: return multiplayer_peers() == 0, 30.0, "the client finished")
	_finished = true


## Joins, sees the next match blacked out, plays the House's table as its own candidate, stamps
## without keeping anything, goes through first and waits, and follows the room back to its lobby.
func _client() -> void:
	var config := MatchConfig.new()
	config.online = "join"
	config.address = "127.0.0.1"
	config.port = _port
	config.human_names = ["Guest"] as Array[String]
	# The host may still be opening its room.
	await _frames(60)
	Game.go_to_waiting(config)
	var room := await _room()
	if room == null:
		return
	var lobby: ReadyRoom = room.ready_room
	if not await _until(
		func() -> bool: return lobby._plan_redacted != null, 60.0, "the next match is blacked out"
	):
		return
	_check(lobby._ticket == null, "without the dealer's ticket")
	var arena := await _arena(false)
	if arena == null:
		return
	var played: Match = arena.match_node
	_check(played.rules.final_hand and Story.final_hand_on, "this screen plays the Final Hand")
	var mine := FinalHand.candidate(played)
	_check(mine != null and mine.index == played.local_slot, "its own player is its candidate")
	_check(FinalHand.name_of(mine) == StoryLines.CANDIDATE, "printed CANDIDATE here")
	var table := played.find_child("FinalHandTable", true, false) as FinalHandTable
	var saw := await _sees_the_racks(played, table)
	if (
		not saw
		or not await _until(
			func() -> bool: return table != null and table.evaluation != null,
			60.0,
			"the House's evaluation is on this slip"
		)
	):
		return
	_check(not table.evaluation.counts, "a stamp that keeps nothing here")
	table.evaluation._on_stamped()
	_check(not Game.settings.profile.story.ended(), "and the client's story goes on")
	table.evaluation.go_on.pressed.emit()
	if not await _until(
		func() -> bool: return get_tree().get_first_node_in_group(LastLines.GROUP) != null,
		10.0,
		"the last lines are up"
	):
		return
	# Looked at there and then: the host goes through as soon as it hears this one is.
	(get_tree().get_first_node_in_group(LastLines.GROUP) as LastLines)._home()
	_check(
		table.evaluation.hint.text == StoryLines.STILL_WITH_THE_HOUSE,
		"through first, the slip says the others are still with the House"
	)
	var back := await _room()
	if back == null:
		return
	await _seconds(1.0)
	_check(back.ready_room._plan_redacted == null, "back in the lobby nothing is blacked out")
	_finished = true


## The House's acts at the host, STORY.md 8.2: the clock past half way, a rack rises where a
## forecast ends; past three quarters, the models follow a person's line. Whether they did.
func _acts(played: Match) -> bool:
	played.time_left = played.rules.duration * 0.45
	if not await _until(
		func() -> bool: return not MatchSnapshot.own_nodes(played, HouseRack.GROUP).is_empty(),
		20.0,
		"the House raises a rack where a forecast ends"
	):
		return false
	# Long enough for the client to see one too.
	await _seconds(4.0)
	played.time_left = played.rules.duration * 0.2
	return await _until(
		func() -> bool:
			for slot: PlayerSlot in played.slots:
				var brain := HouseForecast._brain_of(slot)
				if brain != null and brain.led.is_on():
					return true
			return false,
		10.0,
		"at convergence the models follow a person's line"
	)


## The host's racks risen at the client as well, and the House anticipating on this screen.
func _sees_the_racks(played: Match, table: FinalHandTable) -> bool:
	if not await _until(
		func() -> bool:
			for node: Node in MatchSnapshot.own_nodes(played, HouseRack.GROUP):
				if (node as HouseRack).puppet:
					return true
			return false,
		60.0,
		"the host's racks rise here too"
	):
		return false
	_check(
		table.watch != null and table.watch.act >= HouseForecast.Act.ANTICIPATION,
		"and this screen shows the House anticipating"
	)
	return true


## The Final Hand's arena once it is up and everybody is seated in it, [param hosting] or not.
func _arena(hosting: bool) -> Node:
	var up := await _until(
		func() -> bool:
			var scene := _scene()
			if scene == null or scene.scene_file_path != MATCH_SCENE or scene.match_node == null:
				return false
			var match_node: Match = scene.match_node
			if match_node.arena == null or match_node.slots.is_empty():
				return false
			if not hosting:
				return match_node.puppet and match_node.local_slot >= 0
			return _remote(match_node) == 1,
		90.0,
		"the arena is up and everybody is seated"
	)
	return _scene() if up else null
