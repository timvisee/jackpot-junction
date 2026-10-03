extends Control
## Play Online, GAME.md 9.3a: the dedicated servers the player keeps, a row each, see [ServerList],
## which connect to it; under them Add a server, Direct connect, and LAN games, which goes on to
## the games on the network, see online.gd. Once a server has let this machine in, its games are
## listed on a screen of their own, see server_games.gd, over the connection made here.
##
## Add a server and Direct connect put up the server's address and port in place of the list,
## and the name it is kept under for Add: Add keeps it and goes back to the list, Connect connects
## to it without keeping it. Back, or B, goes back to the list from there.
##
## Back from one of the server's games, the screen connects to it again by itself and goes on to
## its games, saying why it is back: a wrong password, a kick, a game that is over.

## What the list says while it is empty.
const NONE_YET := "No servers yet. Add one or connect directly."

var name_field: LineEdit
## The form: the server's address and port, the name it is kept under, and the buttons that keep
## it and connect to it.
var server_name_field: LineEdit
var address_field: LineEdit
var port_field: LineEdit
var add_button: Button
var connect_button: Button
## Under the list: keep a server, connect to one directly, and the games on the network.
var adding_button: Button
var direct_button: Button
var lan_button: Button
var status: Label
## Why the screen is up again, if there is something to say about it.
var note: Label
## The line to the server, see [ServerLink], while there is one.
var link: ServerLink
## On to the server's games once connected, and on to the games on the network: their screens,
## unless a test says otherwise.
var open_games: Callable = Game.go_to_server_games
var open_lan: Callable = Game.go_to_online

## The server the link knocked at, as its address and its port.
var _address := ""
var _port := 0
var _subtitle: Label
var _list_view: VBoxContainer
var _servers: ServerList
var _none: Label
var _form_view: VBoxContainer
var _form_title: Label
var _name_row: Control
var _ask: ConfirmPane
var _ask_layer: Control
## The kept server Remove was pressed on, while it is asked about.
var _removing: Dictionary = {}


func _ready() -> void:
	var column := MenuTheme.screen(self, 16)
	column.add_child(MenuTheme.title("Play Online", 64))
	_subtitle = MenuTheme.subtitle("")
	column.add_child(_subtitle)
	name_field = MenuTheme.field(
		Game.settings.player_names[0], PlayerNames.PLACEHOLDER, PlayerNames.MAX_LENGTH
	)
	name_field.custom_minimum_size = Vector2(320.0, 44.0)
	column.add_child(MenuTheme.row("Your name", name_field))
	_build_list(column)
	_build_form(column)
	note = ServerGames.red_line()
	column.add_child(note)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 20)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.visible = false
	column.add_child(status)
	var back := MenuTheme.button("Back", 24)
	back.pressed.connect(_back)
	column.add_child(back)
	# The question over a shade of the whole screen, which takes the clicks meant for what is under
	# it, the way the title asks about the license.
	_ask_layer = Control.new()
	_ask_layer.name = "RemoveQuestion"
	_ask_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ask_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_ask_layer.visible = false
	add_child(_ask_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.6)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ask_layer.add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ask_layer.add_child(middle)
	_ask = ConfirmPane.new()
	_ask.name = "Remove"
	_ask.answered.connect(_on_remove_answered)
	middle.add_child(_ask)
	show_list()
	note.text = Game.play_online_note
	note.visible = not note.text.is_empty()
	if Game.play_online_reconnect:
		# Back from a game of the server's: straight on to its games again, which say why.
		Game.play_online_reconnect = false
		_connect_to(Game.settings.last_server, Game.settings.last_server_port)
	else:
		Game.play_online_note = ""


func _build_list(column: VBoxContainer) -> void:
	_list_view = VBoxContainer.new()
	_list_view.name = "List"
	_list_view.add_theme_constant_override("separation", 16)
	column.add_child(_list_view)
	_servers = ServerList.new()
	_servers.chosen.connect(
		func(server: Dictionary) -> void: _connect_to(server["address"], server["port"])
	)
	_servers.removing.connect(_ask_to_remove)
	_list_view.add_child(_servers)
	_none = MenuTheme.subtitle(NONE_YET, Type.LABEL)
	_list_view.add_child(_none)
	adding_button = MenuTheme.button("Add a server")
	adding_button.pressed.connect(func() -> void: show_form(true))
	_list_view.add_child(adding_button)
	direct_button = MenuTheme.button("Direct connect")
	direct_button.pressed.connect(func() -> void: show_form(false))
	_list_view.add_child(direct_button)
	# Somebody's machine on the same network hosting rather than a server, GAME.md 9.3.
	lan_button = MenuTheme.button("LAN games")
	lan_button.pressed.connect(func() -> void: open_lan.call(""))
	_list_view.add_child(lan_button)


func _build_form(column: VBoxContainer) -> void:
	_form_view = VBoxContainer.new()
	_form_view.name = "Form"
	_form_view.add_theme_constant_override("separation", 16)
	column.add_child(_form_view)
	_form_title = MenuTheme.title("", Type.TITLE)
	_form_view.add_child(_form_title)
	server_name_field = MenuTheme.field("", "Optional", ServerList.NAME_LENGTH)
	server_name_field.custom_minimum_size = Vector2(320.0, 44.0)
	server_name_field.text_submitted.connect(func(_typed: String) -> void: _submit())
	_name_row = MenuTheme.row("Name", server_name_field)
	_form_view.add_child(_name_row)
	address_field = MenuTheme.field(Game.settings.last_server, "", ServerList.ADDRESS_LENGTH)
	address_field.custom_minimum_size = Vector2(320.0, 44.0)
	address_field.text_submitted.connect(func(_typed: String) -> void: _submit())
	_form_view.add_child(MenuTheme.row("Server", address_field))
	port_field = MenuTheme.field(str(Game.settings.last_server_port), str(ServerArgs.PORT), 5)
	port_field.custom_minimum_size = Vector2(320.0, 44.0)
	port_field.text_submitted.connect(func(_typed: String) -> void: _submit())
	_form_view.add_child(MenuTheme.row("Port", port_field))
	add_button = MenuTheme.button("Add")
	add_button.pressed.connect(_add)
	_form_view.add_child(add_button)
	connect_button = MenuTheme.button("Connect")
	connect_button.pressed.connect(_connect)
	_form_view.add_child(connect_button)


## The kept servers, and the three ways on under them, with the cursor on the row of [param
## focus] if it is one of them, or else on the first row, or on Add a server.
func show_list(focus: Dictionary = {}) -> void:
	_subtitle.text = "Connect to a dedicated server to see the games being played on it."
	_list_view.visible = true
	_form_view.visible = false
	var kept := Game.settings.servers
	_servers.show_servers(kept, focus)
	_servers.visible = not kept.is_empty()
	_none.visible = kept.is_empty()
	if focus.is_empty() or not _kept(focus):
		var first := _servers.connect_button(0)
		(first if first != null else adding_button).grab_focus.call_deferred()


## The form in place of the list: to keep a server with [param adding], or else to connect to one
## without keeping it.
func show_form(adding: bool) -> void:
	_list_view.visible = false
	_form_view.visible = true
	_form_title.text = "Add a server" if adding else "Direct connect"
	_subtitle.text = (
		"Keep a server on your list, to connect to it again in one press."
		if adding
		else "Connect to a server without keeping it on your list."
	)
	_name_row.visible = adding
	add_button.visible = adding
	connect_button.visible = not adding
	server_name_field.text = ""
	if adding:
		address_field.text = ""
		port_field.text = str(ServerArgs.PORT)
	_say("")
	(server_name_field if adding else address_field).grab_focus.call_deferred()


## Whether the form is up rather than the list.
func is_form_up() -> bool:
	return _form_view.visible


## B on a pad, or Escape, is the Back button, GAME.md 4.2.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()


## Back: out of the question about removing a server, back to the list from the form, and back to
## the title from the list.
func _back() -> void:
	if _ask_layer.visible:
		_on_remove_answered(false)
	elif is_form_up():
		_say("")
		show_list()
	else:
		Game.go_to_title()


## Enter in a box of the form presses whichever of Add and Connect it has.
func _submit() -> void:
	if add_button.visible:
		_add()
	else:
		_connect()


## The server in the form's boxes, or empty with the reason said when they hold none.
func _typed_server() -> Dictionary:
	var address := address_field.text.strip_edges()
	var port := int(port_field.text) if port_field.text.is_valid_int() else ServerArgs.PORT
	if address.is_empty():
		_say("Enter the server's address", true)
		return {}
	if port <= 0 or port > 65535:
		_say("Port must be between 1 and 65535", true)
		return {}
	return ServerList.entry(server_name_field.text, address, port)


## Keeps the server in the form's boxes and goes back to the list with the cursor on it. One the
## list already has is called what it is called now rather than kept twice.
func _add() -> void:
	var server := _typed_server()
	if server.is_empty():
		return
	var kept := Game.settings.servers
	var at := -1
	for i: int in kept.size():
		if ServerList.same(kept[i], server):
			at = i
	if at >= 0:
		kept[at] = server
	elif kept.size() >= ServerList.MOST:
		_say("Your list is full: remove a server first", true)
		return
	else:
		kept.append(server)
	Game.settings.save_to_disk()
	_say("")
	show_list(server)


## Connects to the server in the form's boxes, without keeping it.
func _connect() -> void:
	var server := _typed_server()
	if not server.is_empty():
		_connect_to(server["address"], server["port"])


func _kept(server: Dictionary) -> bool:
	for each: Dictionary in Game.settings.servers:
		if ServerList.same(each, server):
			return true
	return false


func _ask_to_remove(server: Dictionary) -> void:
	_removing = server
	_ask_layer.visible = true
	_ask.ask(
		"Remove this server?",
		"%s comes off your list. You can add it again." % ServerList.label(server),
		"Remove",
		"Keep"
	)


func _on_remove_answered(yes: bool) -> void:
	_ask.visible = false
	_ask_layer.visible = false
	var server := _removing
	_removing = {}
	if server.is_empty():
		return
	var kept := Game.settings.servers
	var at := -1
	for i: int in kept.size():
		if ServerList.same(kept[i], server):
			at = i
	if not yes or at < 0:
		show_list(server)
		return
	kept.remove_at(at)
	Game.settings.save_to_disk()
	show_list(kept[mini(at, kept.size() - 1)] if not kept.is_empty() else {})


## Knocks at the server at [param address] and [param port], and remembers it and the name for
## next time.
func _connect_to(address: String, port: int) -> void:
	if address.is_empty():
		_say("Enter the server's address", true)
		return
	# A second press, or another server, while the first is still being knocked at: the new link
	# takes the old one's place, see [method Net.open_link].
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
