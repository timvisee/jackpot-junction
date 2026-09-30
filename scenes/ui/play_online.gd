extends Control
## Play Online, GAME.md 9.3a: connecting to a dedicated server. The player's name, the server's
## address and port, and Connect; once the server has let this machine in, its games are listed
## on a screen of their own, see server_games.gd, over the connection made here.
##
## Back from one of the server's games, the screen connects to it again by itself and goes on to
## its games, saying why it is back: a wrong password, a kick, a game that is over.

## The longest address the box takes: a host name at its longest.
const ADDRESS_LENGTH := 253

var name_field: LineEdit
var address_field: LineEdit
var port_field: LineEdit
var connect_button: Button
var status: Label
## Why the screen is up again, if there is something to say about it.
var note: Label
## The line to the server, see [ServerLink], while there is one.
var link: ServerLink
## On to the server's games once connected: their screen, unless a test says otherwise.
var open_games: Callable = Game.go_to_server_games

## The server the link knocked at, as its address and its port.
var _address := ""
var _port := 0


func _ready() -> void:
	var column := MenuTheme.screen(self, 16)
	column.add_child(MenuTheme.title("Play Online", 64))
	column.add_child(
		MenuTheme.subtitle("Connect to a dedicated server to see the games being played on it.")
	)
	name_field = MenuTheme.field(
		Game.settings.player_names[0], PlayerNames.PLACEHOLDER, PlayerNames.MAX_LENGTH
	)
	name_field.custom_minimum_size = Vector2(320.0, 44.0)
	column.add_child(MenuTheme.row("Your name", name_field))
	address_field = MenuTheme.field(Game.settings.last_server, "", ADDRESS_LENGTH)
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
	note = ServerGames.red_line()
	column.add_child(note)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 20)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.visible = false
	column.add_child(status)
	var back := MenuTheme.button("Back", 24)
	back.pressed.connect(func() -> void: Game.go_to_title())
	column.add_child(back)
	connect_button.grab_focus()
	note.text = Game.play_online_note
	note.visible = not note.text.is_empty()
	if Game.play_online_reconnect:
		# Back from a game of the server's: straight on to its games again, which say why.
		Game.play_online_reconnect = false
		_connect()
	else:
		Game.play_online_note = ""


## B on a pad, or Escape, is the Back button, GAME.md 4.2.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		Game.go_to_title()


## Knocks at the server in the boxes, and remembers it and the name for next time.
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
	Game.settings.player_names[0] = PlayerNames.clean(name_field.text)
	Game.settings.last_server = address
	Game.settings.last_server_port = port
	Game.settings.save_to_disk()
	link = Net.open_link()
	link.player_name = PlayerNames.clean(name_field.text)
	link.connected.connect(func() -> void: open_games.call())
	link.failed.connect(func() -> void: _say("Could not connect to %s" % _where(), true))
	link.refused.connect(func(reason: String) -> void: _say(reason, true))
	link.lost.connect(func() -> void: _say("The server closed the connection", true))
	var error := link.reach(address, port)
	if error != OK:
		_say("Could not connect: %s" % error_string(error), true)
		return
	_say("Connecting to %s..." % _where())


func _where() -> String:
	return "%s:%d" % [_address, _port]


func _say(text: String, bad := false) -> void:
	status.text = text
	status.visible = not text.is_empty()
	if bad:
		status.add_theme_color_override("font_color", Palette.CHIP_RED)
	else:
		status.remove_theme_color_override("font_color")
