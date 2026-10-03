extends Control
## LAN games, GAME.md 9.3, reached from Play Online: the games on the network, found by asking, see
## [LanFinder], in a [GameList] in a box of its own, see [ListBox], a row each with whose it is and
## how it stands on the button that joins it, and an eye beside it to watch it instead, if its host
## lets anybody watch. Under them, side by side, Host a game, which hosts one on this machine, and
## Direct connect, which asks for the address and port of a game the asking does not reach in a
## dialog over the list, see [FormDialog], with Join, Watch and Cancel. Any of them opens into the
## waiting room of 9.6, which is where the connection is made.
##
## Everybody plays under the first seat's name, GAME.md 3.8, which the settings and the lobby's
## switch change.

var address_field: LineEdit
var port_field: LineEdit
var host_button: Button
var direct_button: Button
var join_button: Button
var watch_button: Button
var cancel_button: Button
var dialog: FormDialog
var status: Label
var finder: LanFinder
## Back to the servers this screen is reached from: Play Online, unless a test says otherwise.
var leave: Callable = Game.go_to_play_online

## The found games' buttons, and the box they are in.
var _found: GameList
var _box: ListBox


func _ready() -> void:
	var column := MenuTheme.screen(self, 16)
	column.add_child(MenuTheme.title("LAN games", 64))
	column.add_child(
		ListBox.fit(
			MenuTheme.subtitle(
				"Games on your network show up here by themselves. Host one, or join a host."
			)
		)
	)
	_found = GameList.new()
	_found.chosen.connect(_join_found)
	_box = ListBox.of("Games on your network", _found, "Host a game")
	_box.link.pressed.connect(func() -> void: _start("host"))
	column.add_child(_box)
	finder = LanFinder.new()
	finder.name = "LanFinder"
	finder.changed.connect(_show_found)
	add_child(finder)
	var ways := ListBox.button_row()
	column.add_child(ways)
	host_button = ListBox.add_row_button(ways, "Host a game")
	host_button.pressed.connect(func() -> void: _start("host"))
	direct_button = ListBox.add_row_button(ways, "Direct connect")
	direct_button.pressed.connect(show_form)
	status = ListBox.fit(Label.new())
	status.add_theme_font_size_override("font_size", 20)
	column.add_child(status)
	var back := MenuTheme.button("Back", 24)
	back.pressed.connect(_back)
	column.add_child(back)
	_build_dialog()
	host_button.grab_focus.call_deferred()
	# Back from a game that turned this machine away, GAME.md 9.6: why, in the dialog, with the
	# address it knocked at in the boxes and the cursor on Join, which is what the player was doing.
	if not Game.online_note.is_empty():
		show_form()
		dialog.say(Game.online_note)
		Game.online_note = ""
		join_button.grab_focus.call_deferred()


func _build_dialog() -> void:
	dialog = FormDialog.add_to(
		self, "Direct connect", "Join a game by its host's address, for one the list does not find."
	)
	address_field = MenuTheme.field(Game.settings.last_address, "", ServerList.ADDRESS_LENGTH)
	address_field.custom_minimum_size = Vector2(320.0, 44.0)
	address_field.text_submitted.connect(func(_typed: String) -> void: _start("join"))
	dialog.add_box("Address", address_field)
	port_field = MenuTheme.field(str(Game.settings.last_port), str(NetSession.DEFAULT_PORT), 5)
	port_field.custom_minimum_size = Vector2(320.0, 44.0)
	port_field.text_submitted.connect(func(_typed: String) -> void: _start("join"))
	dialog.add_box("Port", port_field)
	join_button = dialog.add_button("Join")
	join_button.pressed.connect(func() -> void: _start("join"))
	# Join to watch, GAME.md 10.3: in the room with everybody, with no kart of your own.
	watch_button = dialog.add_button("Watch")
	watch_button.pressed.connect(func() -> void: _start("watch"))
	cancel_button = dialog.add_button("Cancel")
	cancel_button.pressed.connect(_put_dialog_away)


## The dialog for the address and port of a game to join directly, over the list.
func show_form() -> void:
	dialog.open(address_field)


## Whether the dialog is up over the list.
func is_form_up() -> bool:
	return dialog.is_open()


## A row for each game found, the box saying it is still looking while there are none. Made again
## whenever a game comes, goes or changes, with the cursor kept where it was, see [method
## GameList.show_games].
func _show_found() -> void:
	_found.show_games(finder.games(), host_button)


## Into [param game], to play in it or, with [param mode] "watch", to watch it.
func _join_found(game: Dictionary, mode: String) -> void:
	address_field.text = str(game["address"])
	port_field.text = str(game["port"])
	_start(mode)


## B on a pad, or Escape, is the Back button, GAME.md 4.2.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		# Handled before going: the scene change takes this screen out of the tree, and its
		# viewport with it.
		get_viewport().set_input_as_handled()
		_back()


## Out of the dialog, and back to the servers from the list.
func _back() -> void:
	if is_form_up():
		_put_dialog_away()
	else:
		leave.call("")


func _put_dialog_away() -> void:
	dialog.close()
	direct_button.grab_focus.call_deferred()


## The configuration for hosting, joining or watching: hosting on the game's own port, the others
## at the address and port in the boxes.
func config(mode: String) -> MatchConfig:
	var result := MatchConfig.from_settings(Game.settings)
	result.online = "join" if mode == "watch" else mode
	result.watching = mode == "watch"
	var named: Array[String] = [PlayerNames.clean(Game.settings.player_names[0])]
	result.human_names = named
	if mode == "host":
		result.port = NetSession.DEFAULT_PORT
		return result
	result.address = address_field.text.strip_edges()
	result.port = (
		int(port_field.text) if port_field.text.is_valid_int() else NetSession.DEFAULT_PORT
	)
	return result


## What is wrong with joining, said where it was asked: in the dialog while it is up.
func _wrong(text: String) -> void:
	if is_form_up():
		dialog.say(text)
	else:
		status.text = text


func _start(mode: String) -> void:
	var result := config(mode)
	if result.port <= 0 or result.port > 65535:
		_wrong("Port must be between 1 and 65535")
		return
	if result.online == "join" and result.address.is_empty():
		_wrong("Enter the host's address")
		return
	if result.online == "join" and not ServerList.address_problem(result.address).is_empty():
		_wrong(ServerList.address_problem(result.address))
		return
	if result.online == "join":
		Game.settings.last_address = result.address
		Game.settings.last_port = result.port
	Game.settings.save_to_disk()
	# Into the waiting room of GAME.md 9.6 rather than straight onto the felt. Hosting and
	# joining both open the connection in there, and the arena is built once everybody in the
	# room has readied up.
	Game.go_to_waiting(result)
