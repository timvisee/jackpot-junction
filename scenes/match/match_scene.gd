extends Node3D
## The playable match: environment, a [Match] built from the pending [MatchConfig], the F3
## debug overlay and the pause menu. Online, the host runs the match with a [NetSession] and
## clients run a puppet match fed by snapshots. Falls back to one human against three bots when
## started directly.

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
	add_child(match_node)
	match config.online:
		"host":
			match_node.start(config.inputs(), 0, config.colors(), config.names())
			_start_session()
			var error := session.host(config.port)
			if error != OK:
				_fail("Could not host on port %d: %s" % [config.port, error_string(error)])
			else:
				match_node.lobby_hint = (
					"Friends join on port %d at %s" % [config.port, ", ".join(_local_addresses())]
				)
				match_node.hold_in_lobby()
		"join":
			match_node.start_puppet()
			_start_session()
			session.local_input = PlayerInput.new()
			# This machine's seat is the first one in the lobby's list, GAME.md 3.8.
			session.player_name = config.human_names[0] if not config.human_names.is_empty() else ""
			session.connection_failed.connect(
				func() -> void: _fail("Could not connect to %s:%d" % [config.address, config.port])
			)
			session.disconnected.connect(func() -> void: _fail("The host disconnected"))
			session.slot_assigned.connect(func(_index: int) -> void: _status_panel.visible = false)
			var error := session.join(config.address, config.port)
			if error != OK:
				_fail("Could not connect: %s" % error_string(error))
			else:
				_show_status("Connecting to %s:%d..." % [config.address, config.port])
		_:
			match_node.start(config.inputs(), 0, config.colors(), config.names())
	DebugOverlay.add_to(self, match_node, session)
	PauseMenu.add_to(self, session)


## IPv4 addresses of this machine other than loopback, for the lobby hint.
func _local_addresses() -> PackedStringArray:
	var result: PackedStringArray = []
	for address: String in IP.get_local_addresses():
		if address.contains(".") and not address.begins_with("127."):
			result.append(address)
	if result.is_empty():
		result.append("127.0.0.1")
	return result


func _start_session() -> void:
	session = NetSession.new()
	session.name = "Session"
	session.match_node = match_node
	add_child(session)


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
