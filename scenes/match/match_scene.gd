extends Node3D
## The playable match: environment, a [Match] built from the pending [MatchConfig], the F3
## debug overlay and the pause menu. Online, the host runs the match with a [NetSession] and
## clients run a puppet match fed by snapshots. Falls back to one human against three bots when
## started directly.

## Told once the room is up and the match has started, for anything waiting on a scene that no
## longer finishes building inside one frame.
signal loaded

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const RETURN_DELAY := 2.5

var match_node: Match
var config: MatchConfig
var session: NetSession

var _status: Label
var _status_panel: PanelContainer


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
	add_child(match_node)
	match config.online:
		"host":
			await _put_the_room_up()
			match_node.start(config.inputs(), 0, config.colors(), config.names(), config.styles())
			if Net.online():
				# Arrived from the waiting room of 9.6 with everybody already here and already
				# ready. Nothing is held: the waiting was the waiting room's job.
				_adopt_session()
				session.re_seat()
			else:
				_start_session()
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
			session.slot_assigned.connect(func(_index: int) -> void: _status_panel.visible = false)
			if already:
				# Already through the door: the waiting room opened this connection, and the
				# host is re-seating everybody as it starts the match.
				_show_status("Starting the match...")
			else:
				var error := session.join(config.address, config.port)
				if error != OK:
					_fail("Could not connect: %s" % error_string(error))
				else:
					_show_status("Connecting to %s:%d..." % [config.address, config.port])
		_:
			await _put_the_room_up()
			match_node.start(config.inputs(), 0, config.colors(), config.names(), config.styles())
	DebugOverlay.add_to(self, match_node, session)
	PauseMenu.add_to(self, session)
	loaded.emit()


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


## Pressing the join button on a device nobody plays with adds that player mid-match.
func _unhandled_input(event: InputEvent) -> void:
	if (
		not event.is_action_pressed(InputActions.JOIN)
		or get_tree().paused
		or config.online == "join"
	):
		return
	var device := DeviceInput.KEYBOARD if event is InputEventKey else event.device
	if match_node.join_human(device) != null:
		get_viewport().set_input_as_handled()


## Something the player has to be told, in the middle of the screen, on a pane built the way the
## joker detail pane is so the two read as the same game rather than as a label dropped on the
## floor. [param colour] is the bar along its top edge.
func _show_status(text: String, colour: Color = Palette.NEON_CYAN) -> void:
	if _status == null:
		var layer := CanvasLayer.new()
		layer.name = "Status"
		layer.layer = 30
		add_child(layer)
		_status_panel = PanelContainer.new()
		_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_status_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		_status_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_status_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
		layer.add_child(_status_panel)
		_status = Label.new()
		_status.add_theme_font_size_override("font_size", 34)
		_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		HudText.shadowed(_status)
		_status_panel.add_child(_status)
	var style := StyleBoxFlat.new()
	style.bg_color = JokerDetail.BG
	style.set_corner_radius_all(8)
	style.content_margin_left = 34.0
	style.content_margin_right = 34.0
	style.content_margin_top = 22.0
	style.content_margin_bottom = 22.0
	style.border_width_top = JokerDetail.EDGE
	style.border_color = colour
	_status_panel.add_theme_stylebox_override("panel", style)
	_status.text = text
	_status_panel.visible = true


## The room is over and nothing in it can be answered any more, so the notice has the screen to
## itself: the HUD stands down, taking any open joker pick, the standings and the blocks with it,
## and the pane is the only thing left to read.
func _fail(message: String) -> void:
	_show_status(message + "\nReturning to the menu...", Palette.CHIP_RED)
	if match_node != null and match_node.hud != null:
		match_node.hud.stand_down()
	get_tree().create_timer(RETURN_DELAY).timeout.connect(func() -> void: Game.go_to_title())
