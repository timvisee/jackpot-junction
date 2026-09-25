extends Control
## Host or join an online match by address and port, GAME.md 9.3. Either one opens into the
## waiting room of 9.6, which is where the connection is made and where everybody says they are
## ready before a kart turns a wheel in anger.
##
## The name box is here as well as in the local lobby, GAME.md 3.8, because somebody joining a
## friend's match never passes through the lobby: without it every visitor would be playing
## under whatever name this machine last set, or under one the table handed them.
##
## Over the boxes, the games on the network, found by asking, see [LanFinder]: one button each,
## whose it is and how it stands, which joins it. The address is for a game the asking does not
## reach.

var name_field: LineEdit
var address_field: LineEdit
var port_field: LineEdit
var host_button: Button
var join_button: Button
var watch_button: Button
var status: Label
var finder: LanFinder

## The found games' buttons, and the line over them while there are none.
var _found: VBoxContainer
var _looking: Label


func _ready() -> void:
	var column := MenuTheme.screen(self, 16)
	column.add_child(MenuTheme.title("Play LAN", 64))
	column.add_child(
		MenuTheme.subtitle(
			"Host a match on your port, or join a friend's address. Direct connection, no relay."
		)
	)
	_looking = MenuTheme.subtitle("Looking for games on your network...", Type.LABEL)
	column.add_child(_looking)
	_found = VBoxContainer.new()
	_found.add_theme_constant_override("separation", 8)
	column.add_child(_found)
	finder = LanFinder.new()
	finder.name = "LanFinder"
	finder.changed.connect(_show_found)
	add_child(finder)
	name_field = MenuTheme.field(
		Game.settings.player_names[0], PlayerNames.PLACEHOLDER, PlayerNames.MAX_LENGTH
	)
	name_field.custom_minimum_size = Vector2(320.0, 44.0)
	column.add_child(MenuTheme.row("Your name", name_field))
	address_field = LineEdit.new()
	address_field.text = Game.settings.last_address
	address_field.custom_minimum_size = Vector2(320.0, 44.0)
	address_field.add_theme_font_size_override("font_size", 22)
	column.add_child(MenuTheme.row("Address", address_field))
	port_field = LineEdit.new()
	port_field.text = str(Game.settings.last_port)
	port_field.custom_minimum_size = Vector2(320.0, 44.0)
	port_field.add_theme_font_size_override("font_size", 22)
	column.add_child(MenuTheme.row("Port", port_field))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 16.0)
	column.add_child(spacer)
	host_button = MenuTheme.button("Host")
	host_button.pressed.connect(func() -> void: _start("host"))
	column.add_child(host_button)
	join_button = MenuTheme.button("Join")
	join_button.pressed.connect(func() -> void: _start("join"))
	column.add_child(join_button)
	# Join to watch, GAME.md 10.3: in the room with everybody, with no kart of your own.
	watch_button = MenuTheme.button("Watch")
	watch_button.pressed.connect(func() -> void: _start("watch"))
	column.add_child(watch_button)
	var back := MenuTheme.button("Back", 24)
	back.pressed.connect(func() -> void: Game.go_to_title())
	column.add_child(back)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 20)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status)
	host_button.grab_focus()


## A button for each game found, which joins it, and the line saying none are while none are.
## A game this version cannot play says which it is, and cannot be pressed.
func _show_found() -> void:
	var had := get_viewport().gui_get_focus_owner()
	var lost := had != null and _found.is_ancestor_of(had)
	for old: Node in _found.get_children():
		_found.remove_child(old)
		old.queue_free()
	var games := finder.games()
	_looking.text = (
		"Looking for games on your network..." if games.is_empty() else "Games on your network"
	)
	for game: Dictionary in games:
		var button := MenuTheme.button(describe(game), Type.BODY)
		button.custom_minimum_size = Vector2(0.0, 52.0)
		button.disabled = not NetDoor.compatible(Game.version(), str(game["version"]))
		button.pressed.connect(_join_found.bind(game))
		_found.add_child(button)
	if lost:
		host_button.grab_focus()


## A found game in a line: whose, how it stands, how many play in it and may, and the rest.
static func describe(game: Dictionary) -> String:
	var parts: PackedStringArray = [
		"%s's game" % game["name"],
		"in the lobby" if game["lobby"] else "playing",
		"%d/%d players" % [game["players"], game["most"]],
	]
	if game["password"]:
		parts.append("password")
	if not NetDoor.compatible(Game.version(), str(game["version"])):
		parts.append("version %s" % game["version"])
	return " \u00b7 ".join(parts)


func _join_found(game: Dictionary) -> void:
	address_field.text = str(game["address"])
	port_field.text = str(game["port"])
	_start("join")


## B on a pad, or Escape, is the Back button, GAME.md 4.2.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		# Handled before going: the scene change takes this screen out of the tree, and its
		# viewport with it.
		get_viewport().set_input_as_handled()
		Game.go_to_title()


## The configuration for hosting or joining with the current fields.
func config(mode: String) -> MatchConfig:
	var result := MatchConfig.from_settings(Game.settings)
	result.online = "join" if mode == "watch" else mode
	result.watching = mode == "watch"
	var named: Array[String] = [PlayerNames.clean(name_field.text)]
	result.human_names = named
	result.address = address_field.text.strip_edges()
	result.port = (
		int(port_field.text) if port_field.text.is_valid_int() else NetSession.DEFAULT_PORT
	)
	return result


func _start(mode: String) -> void:
	var result := config(mode)
	if result.port <= 0 or result.port > 65535:
		status.text = "Port must be between 1 and 65535"
		return
	if result.online == "join" and result.address.is_empty():
		status.text = "Enter the host's address"
		return
	Game.settings.last_address = result.address
	Game.settings.last_port = result.port
	Game.settings.player_names[0] = result.human_names[0]
	Game.settings.save_to_disk()
	# Into the waiting room of GAME.md 9.6 rather than straight onto the felt. Hosting and
	# joining both open the connection in there, and the arena is built once everybody in the
	# room has readied up.
	Game.go_to_waiting(result)
