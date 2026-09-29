extends Control
## Play Online, GAME.md 9.3a: the games on a dedicated server. Connected to its address and port,
## it lists them the way Play LAN lists the games on the network, a row each with Join and Watch,
## see [GameList], and under them Make a game, which starts one there and goes into its lobby with
## the host's say. Joining or watching one goes into its lobby the way joining a LAN game does.
##
## The server last connected to is connected to again as the screen comes up, so coming back from
## one of its games is coming back to its list.

## The longest address the box takes: a host name at its longest.
const ADDRESS_LENGTH := 253

var name_field: LineEdit
var address_field: LineEdit
var port_field: LineEdit
var connect_button: Button
var make_button: Button
var status: Label
## Why the screen is up again, back from one of the server's games, kept over what connecting says.
var note: Label
## The line to the server's list, see [ServerLink], while there is one.
var link: ServerLink
## Goes into a game's lobby with the configuration for it: the waiting room, unless a test says
## otherwise.
var enter: Callable = Game.go_to_waiting

## The line over the games, and the games.
var _games_line: Label
var _games: GameList
## The server the link knocked at, as its address and its port.
var _address := ""
var _port := 0


func _ready() -> void:
	var column := MenuTheme.screen(self, 16)
	column.add_child(MenuTheme.title("Play Online", 64))
	(
		column
		. add_child(
			(
				MenuTheme
				. subtitle(
					"Games on a dedicated server: make one and host it from here, or join one somebody made."
				)
			)
		)
	)
	name_field = MenuTheme.field(
		Game.settings.player_names[0], PlayerNames.PLACEHOLDER, PlayerNames.MAX_LENGTH
	)
	name_field.custom_minimum_size = Vector2(320.0, 44.0)
	column.add_child(MenuTheme.row("Your name", name_field))
	address_field = MenuTheme.field(Game.settings.last_server, "Its address", ADDRESS_LENGTH)
	address_field.custom_minimum_size = Vector2(320.0, 44.0)
	address_field.text_submitted.connect(func(_typed: String) -> void: _connect())
	column.add_child(MenuTheme.row("Server", address_field))
	port_field = MenuTheme.field(str(Game.settings.last_server_port), str(ServerArgs.PORT), 5)
	port_field.custom_minimum_size = Vector2(320.0, 44.0)
	port_field.text_submitted.connect(func(_typed: String) -> void: _connect())
	column.add_child(MenuTheme.row("Port", port_field))
	connect_button = MenuTheme.button("Connect")
	connect_button.pressed.connect(_connect)
	column.add_child(connect_button)
	note = Label.new()
	note.add_theme_font_size_override("font_size", 20)
	note.add_theme_color_override("font_color", Palette.CHIP_RED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.visible = false
	column.add_child(note)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 20)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status)
	_games_line = MenuTheme.subtitle("", Type.LABEL)
	_games_line.visible = false
	column.add_child(_games_line)
	_games = GameList.new()
	_games.chosen.connect(_join)
	column.add_child(_games)
	make_button = MenuTheme.button("Make a game")
	make_button.pressed.connect(_make)
	make_button.disabled = true
	column.add_child(make_button)
	var back := MenuTheme.button("Back", 24)
	back.pressed.connect(func() -> void: Game.go_to_title())
	column.add_child(back)
	connect_button.grab_focus()
	# Back from one of the server's games with something to say about why: a wrong password, a
	# kick, a game that is over.
	note.text = Game.play_online_note
	note.visible = not note.text.is_empty()
	Game.play_online_note = ""
	if not address_field.text.strip_edges().is_empty():
		_connect()


## B on a pad, or Escape, is the Back button, GAME.md 4.2.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		Game.go_to_title()


## Knocks at the server in the boxes, and remembers it for next time.
func _connect() -> void:
	var address := address_field.text.strip_edges()
	var port := int(port_field.text) if port_field.text.is_valid_int() else ServerArgs.PORT
	if address.is_empty():
		_say("Enter the server's address", true)
		return
	if port <= 0 or port > 65535:
		_say("Port must be between 1 and 65535", true)
		return
	_address = address
	_port = port
	_keep()
	make_button.disabled = true
	_show_games([] as Array[Dictionary])
	_games_line.visible = false
	link = Net.open_link()
	link.player_name = PlayerNames.clean(name_field.text)
	link.connected.connect(_on_connected)
	link.failed.connect(func() -> void: _say("Could not connect to %s" % _where(), true))
	link.refused.connect(func(reason: String) -> void: _say(reason, true))
	link.lost.connect(_on_lost)
	link.listed.connect(_show_games)
	link.made.connect(func(at: int) -> void: _enter(at, "join", true))
	link.not_made.connect(_on_not_made)
	var error := link.reach(address, port)
	if error != OK:
		_say("Could not connect: %s" % error_string(error), true)
		return
	_say("Connecting to %s..." % _where())


func _on_connected() -> void:
	_say("Connected to %s" % _where())
	make_button.disabled = false
	if get_viewport().gui_get_focus_owner() == connect_button:
		make_button.grab_focus()


func _on_lost() -> void:
	_say("The server closed the connection", true)
	make_button.disabled = true
	_show_games([] as Array[Dictionary])
	_games_line.visible = false


func _show_games(games: Array[Dictionary]) -> void:
	_games_line.visible = true
	_games_line.text = (
		"Games on this server" if not games.is_empty() else "No games on this server yet"
	)
	_games.show_games(games, make_button)


func _make() -> void:
	if link == null or make_button.disabled:
		return
	make_button.disabled = true
	_say("Making a game...")
	link.make_game()


func _on_not_made(reason: String) -> void:
	make_button.disabled = false
	_say(reason, true)


func _join(game: Dictionary, mode: String) -> void:
	_enter(int(game["port"]), mode, false)


## Into the lobby of the game on [param port], to play in it or, with [param mode] "watch", to
## watch it; [param making] for the game just made, which comes with the host's say.
func _enter(port: int, mode: String, making: bool) -> void:
	_keep()
	var config := MatchConfig.from_settings(Game.settings)
	config.online = "join"
	config.watching = mode == "watch"
	config.creating = making
	var named: Array[String] = [PlayerNames.clean(name_field.text)]
	config.human_names = named
	config.address = _address
	config.port = port
	config.server = _where()
	enter.call(config)


## The name and the server, kept for next time.
func _keep() -> void:
	Game.settings.player_names[0] = PlayerNames.clean(name_field.text)
	if not _address.is_empty():
		Game.settings.last_server = _address
		Game.settings.last_server_port = _port
	Game.settings.save_to_disk()


func _where() -> String:
	return "%s:%d" % [_address, _port]


func _say(text: String, bad := false) -> void:
	status.text = text
	if bad:
		status.add_theme_color_override("font_color", Palette.CHIP_RED)
	else:
		status.remove_theme_color_override("font_color")
