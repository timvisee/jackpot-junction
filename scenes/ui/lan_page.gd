class_name LanPage
extends VBoxContainer
## LAN games, GAME.md 9.3, the last of Play Online's tabs: the games on the network, found by
## asking, see [LanFinder], in a [GameList] in a box of its own, see [ListBox], a row each with
## whose it is and how it stands on the button that joins it, and an eye beside it to watch it
## instead, if its host lets anybody watch. Under them, side by side, Host a game, which hosts one
## on this machine, and Direct connect, which asks for the address and port of a game the asking
## does not reach in a dialog over the screen, see [FormDialog], with Join, Watch and Cancel. Any of
## them opens into the waiting room of 9.6, which is where the connection is made. The network is
## only asked while the tab is up.
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
## Asking the network for games while the tab is up, or null while it is not.
var finder: LanFinder
## The found games' buttons, and the box they are in.
var found: GameList
var box: ListBox


## The page, its dialog put up over [param over], the screen it is on.
func _init(over: Control) -> void:
	name = "LanPage"
	add_theme_constant_override("separation", 16)
	add_child(
		ListBox.fit(
			MenuTheme.subtitle(
				"Games on your network show up here by themselves. Host one, or join a host."
			)
		)
	)
	found = GameList.new()
	found.chosen.connect(_join_found)
	box = ListBox.of("Games on your network", found, "Host a game")
	box.link.pressed.connect(func() -> void: start("host"))
	add_child(box)
	var ways := ListBox.button_row()
	add_child(ways)
	host_button = ListBox.add_row_button(ways, "Host a game")
	host_button.pressed.connect(func() -> void: start("host"))
	direct_button = ListBox.add_row_button(ways, "Direct connect")
	direct_button.pressed.connect(show_form)
	_build_dialog(over)
	visibility_changed.connect(_ask_while_up)


func _ready() -> void:
	_ask_while_up()


## The network asked for games while the page is up, and left alone while it is not.
func _ask_while_up() -> void:
	if is_visible_in_tree() and finder == null:
		finder = LanFinder.new()
		finder.name = "LanFinder"
		finder.changed.connect(show_found)
		add_child(finder)
	elif not is_visible_in_tree() and finder != null:
		finder.queue_free()
		finder = null


func _build_dialog(over: Control) -> void:
	dialog = FormDialog.add_to(
		over, "Direct connect", "Join a game by its host's address, for one the list does not find."
	)
	address_field = MenuTheme.host_field(Game.settings.last_address, ServerList.ADDRESS_LENGTH)
	address_field.custom_minimum_size = Vector2(320.0, 44.0)
	address_field.text_submitted.connect(func(_typed: String) -> void: start("join"))
	dialog.add_box("Address", address_field)
	port_field = MenuTheme.port_field(str(Game.settings.last_port), str(NetSession.DEFAULT_PORT))
	port_field.custom_minimum_size = Vector2(320.0, 44.0)
	port_field.text_submitted.connect(func(_typed: String) -> void: start("join"))
	dialog.add_box("Port", port_field)
	join_button = dialog.add_button("Join", true)
	join_button.pressed.connect(func() -> void: start("join"))
	# Join to watch, GAME.md 10.3: in the room with everybody, with no kart of your own.
	watch_button = dialog.add_button("Watch")
	watch_button.pressed.connect(func() -> void: start("watch"))
	cancel_button = dialog.add_button("Cancel")
	cancel_button.pressed.connect(put_dialog_away)


## The dialog for the address and port of a game to join directly, over the list.
func show_form() -> void:
	dialog.open(address_field)


## Whether the dialog is up over the list.
func is_form_up() -> bool:
	return dialog.is_open()


func put_dialog_away() -> void:
	dialog.close()
	direct_button.grab_focus.call_deferred()


## Back from a game that turned this machine away, GAME.md 9.6: [param why] said in the dialog,
## with the address it knocked at in the boxes and the cursor on Join, which is what the player was
## doing.
func say_why(why: String) -> void:
	if why.is_empty():
		return
	show_form()
	dialog.say(why)
	join_button.grab_focus.call_deferred()


## A row for each game found, the box saying it is still looking while there are none. Made again
## whenever a game comes, goes or changes, with the cursor kept where it was, see [method
## GameList.show_games].
func show_found() -> void:
	if finder != null:
		found.show_games(finder.games(), host_button)


## The first way on, for the cursor as the tab comes up: the first game found, or Host a game.
func first_way() -> Control:
	var first := found.find_child("Join*", true, false) as Button
	return first if first != null else host_button


## Into [param game], to play in it or, with [param mode] "watch", to watch it.
func _join_found(game: Dictionary, mode: String) -> void:
	address_field.text = str(game["address"])
	port_field.text = str(game["port"])
	start(mode)


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


## What is wrong with joining, said in the dialog, which comes up for it if it is not up already:
## a found game's address in its boxes, there to be put right. Hosting is on the game's own port and
## has nothing to be wrong with.
func _wrong(text: String) -> void:
	if not is_form_up():
		show_form()
	dialog.say(text)


## Hosting, joining or watching, [param mode]: into the waiting room of GAME.md 9.6 rather than
## straight onto the felt. Hosting and joining both open the connection in there, and the arena is
## built once everybody in the room has readied up.
func start(mode: String) -> void:
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
	Game.go_to_waiting(result)
