extends Node3D
## The playable match: environment, a [Match] built from the pending [MatchConfig], the F3
## debug overlay and the pause menu. Online, the host runs the match with a [NetSession] and
## clients run a puppet match fed by snapshots. Falls back to one human against three bots when
## started directly.

## Told once the room is up and the match has started, for anything waiting on a scene that no
## longer finishes building inside one frame.
signal loaded

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
## The pause menu's way to the end of the House's table in a debug build, STORY.md 8.
const DEBUG_SKIP := "Debug: skip to end"

var match_node: Match
var config: MatchConfig
var session: NetSession

var _status: StatusPane


func _ready() -> void:
	config = Game.pending_config if Game.pending_config != null else MatchConfig.new()
	# The story's Final Hand, STORY.md 8, at the machine that deals it, here or online the host's
	# or a dedicated server's: said before the room goes up, which dresses itself for it. A client
	# is told it with the rules, see [method _build_puppet_arena].
	Story.final_hand_on = config.final_hand and config.online != "join"
	ArenaEnvironment.add_to(self)
	match_node = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	match_node.rules = config.rules(
		match_node.rules if match_node.rules != null else load("res://data/match/default.tres")
	)
	match_node.bot_difficulty = load("res://data/ai/%s.tres" % config.difficulty)
	# What the table deals, GAME.md 8.9: the cards and the later items the loyalty program has added
	# for the profile playing, or at a dedicated server for whoever has the host's say there.
	Loyalty.deal_table(match_node, config.power_ups(), config.dedicated)
	# Which map of a Grand Prix this is, GAME.md 9.7. The host's to say; a client is told it with
	# the rest of the rules.
	if Game.grand_prix != null and config.online != "join":
		Game.grand_prix.label(match_node.rules)
		match_node.bot_traits = Game.grand_prix.bot_table(match_node.bot_traits)
	match_node.arena_layout = ArenaMaps.layout_for(match_node.rules)
	Showdown.dress(match_node)
	# Nobody looks at a match hosted with nobody at it, GAME.md 9.3a.
	match_node.with_hud = not config.dedicated
	add_child(match_node)
	match config.online:
		"host":
			await _put_the_room_up()
			var arriving := Net.online()
			match_node.hold_start = arriving
			_start_match()
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
				session.local_input = PlayerInput.new(DeviceInput.ANY, 0)
				# This machine's seat is the first one in the lobby's list, GAME.md 3.8.
				session.player_name = (
					config.human_names[0] if not config.human_names.is_empty() else ""
				)
				if not config.human_styles.is_empty():
					session.player_style = PackedInt32Array(config.human_styles[0])
			session.rules_applied.connect(_build_puppet_arena, CONNECT_ONE_SHOT)
			session.connection_failed.connect(
				func() -> void: _fail("Could not connect to %s:%d" % [config.address, config.port])
			)
			var gone := "The host disconnected"
			if not config.server.is_empty():
				gone = "The connection to the game was lost"
			session.disconnected.connect(func() -> void: _fail(gone))
			session.refused.connect(_fail)
			session.seat_refused.connect(_on_seat_refused)
			session.slot_assigned.connect(
				func(_index: int) -> void:
					_pane().visible = false
					_pane().backdrop = false
			)
			# Somebody watching is never given a seat, and is in once the host says so, GAME.md
			# 10.3.
			session.watching_started.connect(
				func() -> void:
					_pane().visible = false
					_pane().backdrop = false
			)
			# At a dedicated server the host's say can pass to this machine mid-match, 9.3a.
			session.host_controls.granted_changed.connect(_on_granted)
			# When the match is over the host takes everybody back to the waiting room, GAME.md
			# 9.6, and this machine goes with it.
			session.back_to_room.connect(func() -> void: Game.go_to_waiting(config))
			# And in a Grand Prix the host goes on to the next map, and everybody goes with it.
			session.match_beginning.connect(func() -> void: Game.start_match(config))
			if already:
				# Already through the door: the waiting room opened this connection. The host
				# seats whoever asks once its arena is up, so this machine asks now that its own
				# end is listening for the answer.
				# Nothing is built until the host has seated this machine, so the words stand on
				# the menus' background rather than on an empty world.
				_pane().backdrop = true
				_show_status("Starting the match...")
				session.ready_for_seat()
			else:
				var error := session.join(config.address, config.port)
				if error != OK:
					_fail("Could not connect: %s" % error_string(error))
				else:
					_pane().backdrop = true
					_show_status("Connecting to %s:%d..." % [config.address, config.port])
		_:
			await _put_the_room_up()
			# Anybody choosing which joker to keep does it on the grid, with the lamps waiting for
			# them, GAME.md 9.7.
			match_node.hold_start = Game.grand_prix != null and Game.grand_prix.has_choices()
			_start_match()
			_deal_carried_jokers()
			match_node.begin_from_lobby()
	if not config.dedicated:
		DebugOverlay.add_to(self, match_node, session)
	# Even with nobody here to open it: it is what stops the match once everybody asks.
	var menu := PauseMenu.add_to(self, session)
	# The way back to the lobby is whoever decides where the room goes: this machine alone, or
	# the host, GAME.md 3.8, which at a dedicated server is a player at a client, 9.3a. The menu
	# shows it while the say is this machine's.
	if Demo.playing():
		menu.for_the_demo(func() -> void: DemoHost.of(get_tree()).leave())
	elif session == null or not session.dedicated:
		menu.offer_the_lobby()
	if config.dedicated:
		session.host_controls.asked_to_go.connect(_on_asked_to_go)
	Events.match_state_changed.connect(_on_state_changed)
	Events.grand_prix_scored.connect(_on_grand_prix_scored)
	# A match played to the whistle goes into the profile playing, GAME.md 8.5, every card and item
	# taken into its catalog, 8.8, and Kit's notes turn up on this machine's table alone, STORY.md 7.1.
	# A showdown is no map of the run, 9.7a: it counts for the run it settles alone. Nothing played
	# in the demo for a booth counts for anybody, 9.8.
	var recorded := not config.dedicated and not Demo.playing()
	if recorded and match_node.rules.showdown():
		MatchRecord.add_to(match_node)
		AchievementRecord.add_to(match_node, false)
	elif recorded:
		MatchRecord.add_to(match_node)
		CatalogRecord.add_to(match_node)
		LoyaltyRecord.add_to(match_node)
		AchievementRecord.add_to(match_node)
		LostProperty.add_to(match_node)
		PinnedStrip.add_to(match_node)
		NoteDealer.add_to(match_node, FinalHandTable.note_for(Game.settings.profile))
		StoryTable.add_to(match_node)
	if Story.final_hand_on:
		FinalHandTable.add_to(match_node, config.house)
		# A debug build may blow the House's whistle at once, to look at its slip without playing
		# the table out, wherever the match is this machine's to end.
		if OS.is_debug_build() and config.online != "join" and not config.dedicated:
			menu.add_entry(DEBUG_SKIP, _skip_to_the_slip)
	loaded.emit()


## The whistle at once, with no overtime, and the slip up without the podium's wait.
func _skip_to_the_slip() -> void:
	MatchEnd.whistle_now(match_node)
	if match_node.hud != null:
		match_node.hud.skip_the_whistle()


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
	# A showdown settles the run's ties rather than paying points, GAME.md 9.7a.
	if match_node.rules.showdown():
		Game.grand_prix.settle(Showdown.lasted(match_node))
	else:
		Game.grand_prix.score(match_node.standings())
	Events.grand_prix_scored.emit(Game.grand_prix.to_wire())


## At a dedicated server, the player with the say wants the room somewhere else, GAME.md 9.3a:
## back to the waiting room at any time, as a host's pause menu takes it, and on to the next map or
## into a rematch only from the podium, where a host's own buttons for them are.
func _on_asked_to_go(where: StringName) -> void:
	var over := match_node.state == Match.State.RESULTS
	match where:
		&"lobby":
			Game.back_to_the_room()
		&"next":
			if over:
				Game.next_map(match_node)
		&"rematch":
			if over and Game.grand_prix == null:
				match_node.rematch()


func _on_granted(mine: bool) -> void:
	if mine:
		HostSettings.tell_new_host(self, session.host_controls.given_by)


## The run as the host has scored it. A client keeps it as its own; the host already has it.
func _on_grand_prix_scored(run: Dictionary) -> void:
	if config.online == "join":
		Game.grand_prix = GrandPrix.from_wire(run)


## Builds the room a phase at a time with a loading screen over it, GAME.md 8.6. A room takes
## about a sixth of a second to put up and bake, which is ten frames of a screen that has stopped
## if it is done in one go.
func _put_the_room_up() -> void:
	var named := ArenaMaps.NAMES[ArenaMaps.index_of(match_node.rules.map)]
	await LoadingScreen.put_up(self, match_node, named)


## Builds the client's match once the host's settings are in, including which map it is.
func _build_puppet_arena() -> void:
	match_node.arena_layout = ArenaMaps.layout_for(match_node.rules)
	Showdown.dress(match_node)
	# The host's Final Hand is this screen's as well, its own player the candidate, STORY.md 8.1,
	# where the story is on here; an ordinary match in the House's room where it is not.
	var house := match_node.rules.final_hand
	Story.final_hand_on = house and Story.on_here()
	if house:
		FinalHandTable.add_to(match_node)
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
	session.dedicated = config.dedicated


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
	if not event.is_action_pressed(InputActions.JOIN) or get_tree().paused:
		return
	var device := DeviceInput.KEYBOARD if event is InputEventKey else event.device
	if SeatLimit.join(self, match_node, session, device):
		get_viewport().set_input_as_handled()


## Another player here asked the host for a seat and the game had none, GAME.md 10.3.
func _on_seat_refused(_seat: int) -> void:
	SeatLimit.say_full(self, SeatLimit.limit(match_node, session))


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


## Starts the match with everybody the lobby sent: their seats, colors, names, dress and teams.
func _start_match() -> void:
	var teams := config.team_list()
	# The demo's seats have a bot at the wheel until somebody takes one over, GAME.md 9.8.
	var inputs := DemoRun.inputs(config) if Demo.playing() else config.inputs()
	match_node.start(inputs, 0, config.colors(), config.names(), config.styles(), teams)
