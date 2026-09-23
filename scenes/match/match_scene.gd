extends Node3D
## The playable match: environment, a [Match] built from the pending [MatchConfig], the F3
## debug overlay and the pause menu. Online, the host runs the match with a [NetSession] and
## clients run a puppet match fed by snapshots. Falls back to one human against three bots when
## started directly.

## Told once the room is up and the match has started, for anything waiting on a scene that no
## longer finishes building inside one frame.
signal loaded

const MATCH_SCENE := preload("res://scenes/match/match.tscn")

var match_node: Match
var config: MatchConfig
var session: NetSession

var _status: StatusPane


func _ready() -> void:
	config = Game.pending_config if Game.pending_config != null else MatchConfig.new()
	ArenaEnvironment.add_to(self)
	match_node = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	match_node.rules = config.rules(
		match_node.rules if match_node.rules != null else load("res://data/match/default.tres")
	)
	match_node.bot_difficulty = load("res://data/ai/%s.tres" % config.difficulty)
	match_node.power_ups = config.power_ups()
	match_node.arena_layout = ArenaMaps.layout(match_node.rules.map)
	# Which map of a Grand Prix this is, GAME.md 9.7. The host's to say; a client is told it with
	# the rest of the rules.
	if Game.grand_prix != null and config.online != "join":
		Game.grand_prix.label(match_node.rules)
		match_node.bot_traits = Game.grand_prix.bot_table(match_node.bot_traits)
	add_child(match_node)
	match config.online:
		"host":
			await _put_the_room_up()
			var arriving := Net.online()
			match_node.hold_start = arriving
			match_node.start(config.inputs(), 0, config.colors(), config.names(), config.styles())
			_deal_carried_jokers()
			if arriving:
				# Arrived from the waiting room of 9.6, or from the map before, with everybody
				# already here and ready. The lamps still wait for all of them to have this room
				# up as well, GAME.md 10.3, or a slow machine arrives to a match already going.
				_adopt_session()
				# Anybody who connects from here on is shown in here, GAME.md 10.3.
				session.in_arena = true
				session.re_seat()
				session.hold_the_start()
			else:
				_start_session()
				session.in_arena = true
				var error := session.host(config.port)
				if error != OK:
					_fail("Could not host on port %d: %s" % [config.port, error_string(error)])
				else:
					match_node.lobby_hint = (
						"Friends join on port %d at %s"
						% [config.port, ", ".join(_local_addresses())]
					)
					match_node.hold_in_lobby()
		"join":
			# Nothing is built until the host has said which arena this is, GAME.md 6.3. It
			# arrives in the first message a client is sent, before its seat and long before a
			# snapshot; a client that guessed from its own lobby would be driving a kart round
			# the wrong room.
			var already := Net.online()
			if already:
				_adopt_session()
			else:
				_start_session()
				session.local_input = PlayerInput.new()
				# This machine's seat is the first one in the lobby's list, GAME.md 3.8.
				session.player_name = (
					config.human_names[0] if not config.human_names.is_empty() else ""
				)
			session.rules_applied.connect(_build_puppet_arena, CONNECT_ONE_SHOT)
			session.connection_failed.connect(
				func() -> void: _fail("Could not connect to %s:%d" % [config.address, config.port])
			)
			session.disconnected.connect(func() -> void: _fail("The host disconnected"))
			session.refused.connect(_fail)
			session.slot_assigned.connect(func(_index: int) -> void: _pane().visible = false)
			# When the match is over the host takes everybody back to the waiting room, GAME.md
			# 9.6, and this machine goes with it.
			session.back_to_room.connect(func() -> void: Game.go_to_waiting(config))
			# And in a Grand Prix the host goes on to the next map, and everybody goes with it.
			session.match_beginning.connect(func() -> void: Game.start_match(config))
			if already:
				# Already through the door: the waiting room opened this connection. The host
				# seats whoever asks once its arena is up, so this machine asks now that its own
				# end is listening for the answer.
				_show_status("Starting the match...")
				session.ready_for_seat()
			else:
				var error := session.join(config.address, config.port)
				if error != OK:
					_fail("Could not connect: %s" % error_string(error))
				else:
					_show_status("Connecting to %s:%d..." % [config.address, config.port])
		_:
			await _put_the_room_up()
			match_node.start(config.inputs(), 0, config.colors(), config.names(), config.styles())
			_deal_carried_jokers()
	DebugOverlay.add_to(self, match_node, session)
	PauseMenu.add_to(self, session)
	Events.match_state_changed.connect(_on_state_changed)
	Events.grand_prix_scored.connect(_on_grand_prix_scored)
	loaded.emit()


## Whatever jokers everybody carried on from the map before, GAME.md 9.7, back in their hands
## before the lamps go. A seat kept for a client holds them until the client sits in it.
func _deal_carried_jokers() -> void:
	if Game.grand_prix != null:
		Game.grand_prix.deal_jokers(match_node)


## At the whistle of a Grand Prix map the host scores it, GAME.md 9.7, and says how the run stands
## so every podium can show it. A client's whistle is the host's word arriving; it scores nothing.
## Which of the two this machine is comes from the configuration rather than from the match: a
## client's match is only a puppet once the host's rules have built its arena, and the host's
## word can arrive before that.
func _on_state_changed(state: int) -> void:
	if state != Match.State.RESULTS or config.online == "join" or Game.grand_prix == null:
		return
	if match_node.state != Match.State.RESULTS:
		return
	Game.grand_prix.score(match_node.standings())
	Events.grand_prix_scored.emit(Game.grand_prix.to_wire())


## The run as the host has scored it. A client keeps it as its own; the host already has it.
func _on_grand_prix_scored(run: Dictionary) -> void:
	if config.online == "join":
		Game.grand_prix = GrandPrix.from_wire(run)


## Builds the room a phase at a time with a loading screen over it, GAME.md 8.6. A room takes
## about a sixth of a second to put up and bake, which is ten frames of a screen that has stopped
## if it is done in one go.
func _put_the_room_up() -> void:
	var arena := match_node.prepare_arena(true)
	var named := ArenaMaps.NAMES[ArenaMaps.index_of(match_node.rules.map)]
	var screen := LoadingScreen.add_to(self, named)
	await screen.run(arena.build_steps(), "Building the room")


## Builds the client's match once the host's settings are in, including which map it is.
func _build_puppet_arena() -> void:
	match_node.arena_layout = ArenaMaps.layout(match_node.rules.map)
	await _put_the_room_up()
	match_node.start_puppet()
	# The host is holding the lamps for this, GAME.md 10.3.
	session.room_built()
	loaded.emit()


## IPv4 addresses of this machine other than loopback, for the lobby hint.
func _local_addresses() -> PackedStringArray:
	var result: PackedStringArray = []
	for address: String in IP.get_local_addresses():
		if address.contains(".") and not address.begins_with("127."):
			result.append(address)
	if result.is_empty():
		result.append("127.0.0.1")
	return result


## The connection is the [Net] autoload's rather than this scene's, GAME.md 10.3: a scene that
## owned it would take it down with itself, and the room a match is played in is not the room it
## was waited in.
func _start_session() -> void:
	session = Net.open(match_node)


## Takes over the connection the waiting room opened, GAME.md 9.6. It is the same peers and the
## same people; what has changed is the room they are in.
func _adopt_session() -> void:
	Net.attach(match_node)
	session = Net.session


## Pressing the join button on a device nobody plays with adds that player mid-match. Heard before
## the pause menu is: on a pad the join button is also the pause button, and a pad nobody is
## driving pressing it is somebody sitting down. A pad somebody is driving is let through, and
## pauses.
func _input(event: InputEvent) -> void:
	if (
		not event.is_action_pressed(InputActions.JOIN)
		or get_tree().paused
		or config.online == "join"
	):
		return
	var device := DeviceInput.KEYBOARD if event is InputEventKey else event.device
	if match_node.join_human(device) != null:
		get_viewport().set_input_as_handled()


## Something the player has to be told, in the middle of the screen, see [StatusPane].
func _show_status(text: String, color: Color = Palette.NEON_CYAN) -> void:
	_pane().say(text, color)


func _pane() -> StatusPane:
	if _status == null:
		_status = StatusPane.add_to(self)
	return _status


## The room is over and nothing in it can be answered any more, so the notice has the screen to
## itself: the HUD stands down, taking any open joker pick, the standings and the blocks with it,
## and the pane is the only thing left to read.
func _fail(message: String) -> void:
	_pane().fail(message)
	if match_node != null and match_node.hud != null:
		match_node.hud.stand_down()
