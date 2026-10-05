extends Control
## Play Online, GAME.md 9.3a: the dedicated servers the player keeps, a row each in a box of their
## own, see [ServerList] and [ListBox], which connect to it; under them, in a row, Add a server,
## Direct connect, and LAN games, which goes on to the games on the network, see online.gd. Once a
## server has let this machine in, its games are listed on a screen of their own, see
## server_games.gd, over the connection made here.
##
## Add a server and Direct connect ask for the server's address and port in a dialog over the list,
## see [FormDialog], and for the name it is kept under for Add: Add keeps it and closes the dialog
## onto the list, Connect connects to it without keeping it. Back, or B, or Cancel puts the dialog
## away.
##
## Connecting says so in a dialog of the same look, with a bar that eases along over the few
## seconds a server is given to answer and Cancel, which hangs up; what went wrong is said there
## after, with OK.
##
## Back from one of the server's games, the screen connects to it again by itself and goes on to
## its games, saying why it is back: a wrong password, a kick, a game that is over.
##
## A server with a password asks for it in a dialog of the same look, Connect and Cancel, saying
## "Wrong password" in red after a wrong one, GAME.md 9.3a. The one it lets the player in with is
## kept with the server if it is on the list, and for the rest of the run if it is not, so coming
## back from its games, or to it again, does not ask again.

## How long the bar takes to ease along while a server is being knocked at, in seconds: as long as
## nobody answering takes to be given up on, see [method NetLine.trying], and how far it goes.
const KNOCK_FOR := NetLine.CONNECT_TIMEOUT_MAX / 1000.0
const KNOCK_REACH := 0.9

## The passwords servers not on the list let the player in with this run, by where they are.
static var _passwords: Dictionary[String, String] = {}

## The dialog: the server's address and port, the name it is kept under, and the buttons that keep
## it, connect to it and put the dialog away.
var dialog: FormDialog
var server_name_field: LineEdit
var address_field: LineEdit
var port_field: LineEdit
var add_button: Button
var connect_button: Button
var cancel_button: Button
## Under the list: keep a server, connect to one directly, and the games on the network.
var adding_button: Button
var direct_button: Button
var lan_button: Button
## The dialog saying a server is being connected to, its bar, and the button that hangs up while it
## is and puts the dialog away once it is not.
var busy: FormDialog
var busy_bar: ProgressBar
var busy_button: Button
## Why the screen is up again, if there is something to say about it.
var note: Label
## The line to the server, see [ServerLink], while there is one.
var link: ServerLink
## The dialog asking for a server's password, its box, and its Connect.
var password_dialog: FormDialog
var password_field: LineEdit
var password_button: Button
## On to the server's games once connected, and on to the games on the network: their screens,
## unless a test says otherwise.
var open_games: Callable = Game.go_to_server_games
var open_lan: Callable = Game.go_to_online
## The box the kept servers are listed in.
var servers_box: ListBox

## The server the link knocked at, as its address and its port.
var _address := ""
var _port := 0
var _servers: ServerList
var _name_row: Control
var _ask: ConfirmPane
var _ask_layer: Control
## The kept server Remove was pressed on, while it is asked about.
var _removing: Dictionary = {}
## The kept server the dialog is editing, or empty while it adds one or connects.
var _editing: Dictionary = {}
var _knocking: Tween
## Whether the busy dialog says what went wrong rather than that a server is being knocked at.
var _failed := false


func _ready() -> void:
	var column := MenuTheme.screen(self, 16)
	column.add_child(MenuTheme.title("Play Online", 64))
	column.add_child(
		ListBox.fit(
			MenuTheme.subtitle("Connect to a dedicated server to see the games being played on it.")
		)
	)
	_servers = ServerList.new()
	_servers.chosen.connect(
		func(server: Dictionary) -> void: _connect_to(server["address"], server["port"])
	)
	_servers.removing.connect(_ask_to_remove)
	_servers.editing.connect(show_edit)
	_servers.moved.connect(_move)
	servers_box = ListBox.of("Your servers", _servers, "Add a server")
	servers_box.link.pressed.connect(func() -> void: show_form(true))
	column.add_child(servers_box)
	var ways := ListBox.button_row()
	column.add_child(ways)
	adding_button = ListBox.add_row_button(ways, "Add a server")
	adding_button.pressed.connect(func() -> void: show_form(true))
	direct_button = ListBox.add_row_button(ways, "Direct connect")
	direct_button.pressed.connect(func() -> void: show_form(false))
	# Somebody's machine on the same network hosting rather than a server, GAME.md 9.3.
	lan_button = ListBox.add_row_button(ways, "LAN games")
	lan_button.pressed.connect(func() -> void: open_lan.call(""))
	note = ListBox.fit(ServerGames.red_line())
	column.add_child(note)
	var back := MenuTheme.button("Back", 24)
	back.pressed.connect(_back)
	column.add_child(back)
	_build_dialog()
	_build_busy()
	_build_password()
	_build_question()
	show_list()
	note.text = Game.play_online_note
	note.visible = not note.text.is_empty()
	if Game.play_online_reconnect:
		# Back from a game of the server's: straight on to its games again, which say why.
		Game.play_online_reconnect = false
		_connect_to(Game.settings.last_server, Game.settings.last_server_port)
	else:
		Game.play_online_note = ""


func _build_dialog() -> void:
	dialog = FormDialog.add_to(self, "", "")
	server_name_field = MenuTheme.field("", "Optional", ServerList.NAME_LENGTH)
	server_name_field.custom_minimum_size = Vector2(320.0, 44.0)
	server_name_field.text_submitted.connect(func(_typed: String) -> void: _submit())
	_name_row = dialog.add_box("Name", server_name_field)
	address_field = MenuTheme.host_field(Game.settings.last_server, ServerList.ADDRESS_LENGTH)
	address_field.custom_minimum_size = Vector2(320.0, 44.0)
	address_field.text_submitted.connect(func(_typed: String) -> void: _submit())
	dialog.add_box("Server", address_field)
	port_field = MenuTheme.port_field(str(Game.settings.last_server_port), str(ServerArgs.PORT))
	port_field.custom_minimum_size = Vector2(320.0, 44.0)
	port_field.text_submitted.connect(func(_typed: String) -> void: _submit())
	dialog.add_box("Port", port_field)
	add_button = dialog.add_button("Add", true)
	add_button.pressed.connect(_add)
	connect_button = dialog.add_button("Connect", true)
	connect_button.pressed.connect(_connect)
	cancel_button = dialog.add_button("Cancel")
	cancel_button.pressed.connect(_put_dialog_away)


func _build_busy() -> void:
	busy = FormDialog.add_to(self, "Connecting", "")
	busy.name = "Busy"
	busy_bar = busy.add_bar()
	busy_button = busy.add_button("Cancel")
	busy_button.pressed.connect(_busy_pressed)


func _build_password() -> void:
	password_dialog = FormDialog.add_to(self, "Password", "")
	password_dialog.name = "Password"
	password_field = MenuTheme.field("", "", ServerArgs.PASSWORD_LENGTH)
	password_field.secret = true
	password_field.custom_minimum_size = Vector2(320.0, 44.0)
	password_field.text_submitted.connect(func(_typed: String) -> void: _give_password())
	password_dialog.add_box("Password", password_field)
	password_button = password_dialog.add_button("Connect")
	password_button.pressed.connect(_give_password)
	var cancel := password_dialog.add_button("Cancel")
	cancel.pressed.connect(_put_password_away)


## The question over a shade of the whole screen, which takes the clicks meant for what is under
## it, the way the title asks about the license.
func _build_question() -> void:
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


## The kept servers again, with the cursor on the row of [param focus] if it is one of them, on its
## button called [param part], see [method ServerList.show_servers], or else on the first row, or
## on Add a server.
func show_list(focus: Dictionary = {}, part := "Server") -> void:
	_servers.show_servers(Game.settings.servers, focus, part)
	if focus.is_empty() or not _kept(focus):
		var first := _servers.connect_button(0)
		(first if first != null else adding_button).grab_focus.call_deferred()


## The dialog over the list: to keep a server with [param adding], or else to connect to one
## without keeping it.
func show_form(adding: bool) -> void:
	dialog.set_title(
		"Add a server" if adding else "Direct connect",
		(
			"Keep a server on your list, to connect to it again in one press."
			if adding
			else "Connect to a server without keeping it on your list."
		)
	)
	_editing = {}
	add_button.text = "Add"
	_name_row.visible = adding
	add_button.visible = adding
	connect_button.visible = not adding
	server_name_field.text = ""
	if adding:
		address_field.text = ""
		port_field.text = str(ServerArgs.PORT)
	dialog.open(server_name_field if adding else address_field)


## The dialog over the list holding [param server] to change, GAME.md 9.3a: what it is called and
## where it is, kept in its place on the list with Save.
func show_edit(server: Dictionary) -> void:
	show_form(true)
	dialog.set_title("Edit a server", "Change what a kept server is called or where it is.")
	add_button.text = "Save"
	_editing = server
	server_name_field.text = str(server["name"])
	address_field.text = str(server["address"])
	port_field.text = str(server["port"])


## [param server] moved to place [param to] on the list by its grip, and kept there, the cursor
## staying on the grip so it can be moved on.
func _move(server: Dictionary, to: int) -> void:
	var kept := Game.settings.servers
	var at := _index_of(server)
	if at < 0 or to < 0 or to >= kept.size() or to == at:
		return
	kept.remove_at(at)
	kept.insert(to, server)
	Game.settings.save_to_disk()
	show_list(server, "Grip")


func _index_of(server: Dictionary) -> int:
	var kept := Game.settings.servers
	for i: int in kept.size():
		if ServerList.same(kept[i], server):
			return i
	return -1


## Whether the dialog is up over the list.
func is_form_up() -> bool:
	return dialog.is_open()


## B on a pad, or Escape, is the Back button, GAME.md 4.2.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()


## Back: hanging up on a server being connected to, out of the question about removing a server,
## out of the dialog, and back to the title from the list.
func _back() -> void:
	if password_dialog.is_open():
		_put_password_away()
	elif busy.is_open():
		_busy_pressed()
	elif _ask_layer.visible:
		_on_remove_answered(false)
	elif is_form_up():
		_put_dialog_away()
	else:
		Game.go_to_title()


## The dialog put away, the cursor back on the button that put it up.
func _put_dialog_away() -> void:
	var adding := add_button.visible
	dialog.close()
	if not _editing.is_empty():
		show_list(_editing, "Edit")
		_editing = {}
		return
	(adding_button if adding else direct_button).grab_focus.call_deferred()


## Enter in a box of the dialog presses whichever of Add and Connect it has.
func _submit() -> void:
	if add_button.visible:
		_add()
	else:
		_connect()


## The server in the dialog's boxes, or empty with the reason said when they hold none.
func _typed_server() -> Dictionary:
	var address := address_field.text.strip_edges()
	var port := int(port_field.text) if port_field.text.is_valid_int() else ServerArgs.PORT
	if address.is_empty():
		dialog.say("Enter the server's address")
		return {}
	var wrong := ServerList.address_problem(address)
	if not wrong.is_empty():
		dialog.say(wrong)
		return {}
	if port <= 0 or port > 65535:
		dialog.say("Port must be between 1 and 65535")
		return {}
	return ServerList.entry(server_name_field.text, address, port)


## Keeps the server in the dialog's boxes and closes it onto the list with the cursor on it. One
## the list already has is called what it is called now rather than kept twice. Editing, it takes
## the place of the server edited, unless it is now another one already on the list.
func _add() -> void:
	var server := _typed_server()
	if server.is_empty():
		return
	var kept := Game.settings.servers
	var at := _index_of(server)
	if not _editing.is_empty():
		var editing := _index_of(_editing)
		if at >= 0 and at != editing:
			dialog.say("That server is on your list already")
			return
		at = editing
		_editing = {}
	if at >= 0:
		# Still the same server, it still says it is called what it did.
		if ServerList.same(kept[at], server):
			server["called"] = kept[at].get("called", "")
		kept[at] = server
	elif kept.size() >= ServerList.MOST:
		dialog.say("Your list is full: remove a server first")
		return
	else:
		kept.append(server)
	Game.settings.save_to_disk()
	dialog.close()
	show_list(server)


## Connects to the server in the dialog's boxes, without keeping it, the dialog closing onto the
## line saying it is connecting.
func _connect() -> void:
	var server := _typed_server()
	if server.is_empty():
		return
	dialog.close()
	direct_button.grab_focus.call_deferred()
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


## Knocks at the server at [param address] and [param port], under the player's name, with
## [param password], or the one it last let the player in with, and remembers it for next time,
## saying so in the busy dialog.
func _connect_to(address: String, port: int, password := "") -> void:
	if address.is_empty():
		_fail("There is no server to connect to")
		return
	# A second press, or another server, while the first is still being knocked at: the new link
	# takes the old one's place, see [method Net.open_link].
	_address = address
	_port = port
	Game.settings.last_server = address
	Game.settings.last_server_port = port
	Game.settings.save_to_disk()
	link = Net.open_link()
	link.player_name = PlayerNames.clean(Game.settings.player_names[0])
	link.password = password if not password.is_empty() else _password_for(address, port)
	link.connected.connect(_on_connected)
	link.locked.connect(_ask_password)
	link.failed.connect(func() -> void: _fail("Could not connect to %s" % _where()))
	link.refused.connect(_fail)
	link.lost.connect(func() -> void: _fail("The server closed the connection"))
	var error := link.reach(address, port)
	if error != OK:
		_fail("Could not connect: %s" % error_string(error))
		return
	_knock()


func _where() -> String:
	return "%s:%d" % [_address, _port]


## The busy dialog up, saying the server is being knocked at, its bar easing along.
func _knock() -> void:
	_failed = false
	busy.set_title("Connecting", "Connecting to %s..." % _where())
	busy_bar.visible = true
	busy_bar.value = 0.0
	busy_button.text = "Cancel"
	busy.open(busy_button)
	if _knocking != null:
		_knocking.kill()
	_knocking = create_tween()
	_knocking.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_knocking.tween_property(busy_bar, "value", KNOCK_REACH, KNOCK_FOR)


## Let in: the bar full, what the server calls itself and the password it took kept with it if it
## is on the list, the password for the run if it is not, and on to the server's games.
func _on_connected() -> void:
	if _knocking != null:
		_knocking.kill()
	busy_bar.value = 1.0
	var here := {"address": _address, "port": _port}
	var learned := false
	for kept: Dictionary in Game.settings.servers:
		if not ServerList.same(kept, here):
			continue
		if str(kept.get("called", "")) != link.server_name:
			kept["called"] = link.server_name
			learned = true
		if str(kept.get("password", "")) != link.password:
			kept["password"] = link.password
			learned = true
	if learned:
		Game.settings.save_to_disk()
	_passwords[_where()] = link.password
	open_games.call()


## The password the player was last let into the server at [param address] and [param port] with:
## kept with it on the list, or given this run.
func _password_for(address: String, port: int) -> String:
	var here := {"address": address, "port": port}
	for kept: Dictionary in Game.settings.servers:
		if ServerList.same(kept, here) and not str(kept.get("password", "")).is_empty():
			return str(kept["password"])
	return _passwords.get(ServerList.where(here), "")


## The server wants its password: asked for in its own dialog, by the name the server gives itself,
## saying it was wrong after a [param wrong] one.
func _ask_password(wrong: bool) -> void:
	if _knocking != null:
		_knocking.kill()
	busy.close()
	link = null
	var called := Net.link.server_name if Net.link != null else ""
	var which := called if not called.is_empty() else _where()
	password_dialog.set_title("Password", "%s needs a password." % which)
	password_field.text = ""
	password_dialog.open(password_field)
	if wrong:
		password_dialog.say("Wrong password")


## Connect: knocked at again with what was typed.
func _give_password() -> void:
	var typed := password_field.text.strip_edges()
	if typed.is_empty():
		password_dialog.say("Enter the password")
		return
	password_dialog.close()
	_connect_to(_address, _port, typed)


## Cancel, or Back: no password, and no server.
func _put_password_away() -> void:
	password_dialog.close()
	Net.close()
	direct_button.grab_focus.call_deferred()


## What went wrong, in the busy dialog, with OK to put it away.
func _fail(reason: String) -> void:
	if _knocking != null:
		_knocking.kill()
	_failed = true
	busy.set_title("Could not connect", "")
	busy_bar.visible = false
	busy_button.text = "OK"
	if not busy.is_open():
		busy.open(busy_button)
	busy.say(reason)
	busy.focus(busy_button)


## Cancel while a server is being knocked at hangs up; OK once it has gone wrong puts it away.
func _busy_pressed() -> void:
	if not _failed:
		if _knocking != null:
			_knocking.kill()
		Net.close()
		link = null
	busy.close()
	direct_button.grab_focus.call_deferred()


## What the busy dialog says just now, its title and what went wrong, for asking what was said.
func busy_said() -> String:
	return busy.said()
