extends Control
## LAN games, GAME.md 9.3, reached from Play Online: the games on the network, found by asking, see
## [LanFinder], in a [GameList], a row each with whose it is and how it stands on the button that
## joins it, and Watch beside it to watch it instead, if its host lets anybody watch. Under them
## Host a game, which hosts one on this machine, and Direct connect, which puts up the address and
## port of a game the asking does not reach in place of the list, with Join and Watch under them.
## Any of them opens into the waiting room of 9.6, which is where the connection is made.
##
## The name box is here as well as in the local lobby, GAME.md 3.8, because somebody joining a
## friend's match never passes through the lobby: without it every visitor would be playing
## under whatever name this machine last set, or under one the table handed them.

var name_field: LineEdit
var address_field: LineEdit
var port_field: LineEdit
var host_button: Button
var direct_button: Button
var join_button: Button
var watch_button: Button
var status: Label
var finder: LanFinder
## Back to the servers this screen is reached from: Play Online, unless a test says otherwise.
var leave: Callable = Game.go_to_play_online

## The found games' buttons, and the line over them while there are none.
var _found: GameList
var _looking: Label
var _subtitle: Label
var _list_view: VBoxContainer
var _form_view: VBoxContainer


func _ready() -> void:
	var column := MenuTheme.screen(self, 16)
	column.add_child(MenuTheme.title("LAN games", 64))
	_subtitle = MenuTheme.subtitle("")
	column.add_child(_subtitle)
	name_field = MenuTheme.field(
		Game.settings.player_names[0], PlayerNames.PLACEHOLDER, PlayerNames.MAX_LENGTH
	)
	name_field.custom_minimum_size = Vector2(320.0, 44.0)
	column.add_child(MenuTheme.row("Your name", name_field))
	_list_view = VBoxContainer.new()
	_list_view.name = "List"
	_list_view.add_theme_constant_override("separation", 16)
	column.add_child(_list_view)
	_looking = MenuTheme.subtitle("Looking for games on your network...", Type.LABEL)
	_list_view.add_child(_looking)
	_found = GameList.new()
	_found.chosen.connect(_join_found)
	_list_view.add_child(_found)
	finder = LanFinder.new()
	finder.name = "LanFinder"
	finder.changed.connect(_show_found)
	add_child(finder)
	host_button = MenuTheme.button("Host a game")
	host_button.pressed.connect(func() -> void: _start("host"))
	_list_view.add_child(host_button)
	direct_button = MenuTheme.button("Direct connect")
	direct_button.pressed.connect(show_form)
	_list_view.add_child(direct_button)
	_build_form(column)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 20)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status)
	var back := MenuTheme.button("Back", 24)
	back.pressed.connect(_back)
	column.add_child(back)
	show_list()
	# Back from a game that turned this machine away, GAME.md 9.6: why, with the address it
	# knocked at in the boxes and the cursor on Join, which is what the player was doing.
	if not Game.online_note.is_empty():
		show_form()
		status.text = Game.online_note
		status.add_theme_color_override("font_color", Palette.CHIP_RED)
		Game.online_note = ""
		join_button.grab_focus.call_deferred()


func _build_form(column: VBoxContainer) -> void:
	_form_view = VBoxContainer.new()
	_form_view.name = "Form"
	_form_view.add_theme_constant_override("separation", 16)
	column.add_child(_form_view)
	_form_view.add_child(MenuTheme.title("Direct connect", Type.TITLE))
	address_field = MenuTheme.field(Game.settings.last_address, "", ServerList.ADDRESS_LENGTH)
	address_field.custom_minimum_size = Vector2(320.0, 44.0)
	address_field.text_submitted.connect(func(_typed: String) -> void: _start("join"))
	_form_view.add_child(MenuTheme.row("Address", address_field))
	port_field = MenuTheme.field(str(Game.settings.last_port), str(NetSession.DEFAULT_PORT), 5)
	port_field.custom_minimum_size = Vector2(320.0, 44.0)
	port_field.text_submitted.connect(func(_typed: String) -> void: _start("join"))
	_form_view.add_child(MenuTheme.row("Port", port_field))
	join_button = MenuTheme.button("Join")
	join_button.pressed.connect(func() -> void: _start("join"))
	_form_view.add_child(join_button)
	# Join to watch, GAME.md 10.3: in the room with everybody, with no kart of your own.
	watch_button = MenuTheme.button("Watch")
	watch_button.pressed.connect(func() -> void: _start("watch"))
	_form_view.add_child(watch_button)


## The games found, and Host a game and Direct connect under them.
func show_list() -> void:
	_subtitle.text = "Games on your network show up here by themselves. Host one, or join a host."
	_list_view.visible = true
	_form_view.visible = false
	host_button.grab_focus.call_deferred()


## The address and port of a game to join directly, in place of the list.
func show_form() -> void:
	_subtitle.text = "Join a game by its host's address, for one the list does not find."
	_list_view.visible = false
	_form_view.visible = true
	status.text = ""
	address_field.grab_focus.call_deferred()


## Whether the form is up rather than the list.
func is_form_up() -> bool:
	return _form_view.visible


## A row for each game found, and the line saying none are while none are. Made again whenever a
## game comes, goes or changes, with the cursor kept where it was, see [method GameList.show_games].
func _show_found() -> void:
	var games := finder.games()
	_looking.text = (
		"Looking for games on your network..." if games.is_empty() else "Games on your network"
	)
	_found.show_games(games, host_button)


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


## Back to the list from the form, and back to the servers from the list.
func _back() -> void:
	if is_form_up():
		status.text = ""
		show_list()
	else:
		leave.call("")


## The configuration for hosting, joining or watching: hosting on the game's own port, the others
## at the address and port in the boxes.
func config(mode: String) -> MatchConfig:
	var result := MatchConfig.from_settings(Game.settings)
	result.online = "join" if mode == "watch" else mode
	result.watching = mode == "watch"
	var named: Array[String] = [PlayerNames.clean(name_field.text)]
	result.human_names = named
	if mode == "host":
		result.port = NetSession.DEFAULT_PORT
		return result
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
	if result.online == "join":
		Game.settings.last_address = result.address
		Game.settings.last_port = result.port
	Game.settings.player_names[0] = result.human_names[0]
	Game.settings.save_to_disk()
	# Into the waiting room of GAME.md 9.6 rather than straight onto the felt. Hosting and
	# joining both open the connection in there, and the arena is built once everybody in the
	# room has readied up.
	Game.go_to_waiting(result)
