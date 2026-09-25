class_name LobbySettings
extends PanelContainer
## The host's settings for who may come into its game, GAME.md 9.6, from its pause menu in place of
## the menu itself: how many may play, its own players included, a password to keep the game to
## the people who were told it, whether anybody may come to watch, and whether a watcher has to
## give the password too. Changed at once; nobody already in is shown out by any of them, they
## only answer the next knock. The number and the two about watchers are kept for next time; the
## password is not.

## Back: the menu is up again in its place.
signal closed

var session: NetSession
## Up as the first step of opening a hosted room, before the match settings, GAME.md 9.6: its
## button goes on to them rather than back to a menu.
var onward := false

var _players: OptionButton
var _password: LineEdit
var _watchers: CheckButton
var _watch_free: CheckButton
var _back: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuTheme.pane_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	column.add_child(MenuTheme.title("Lobby settings", Type.TITLE))
	var counts: Array = []
	for count: int in range(NetDoor.FEWEST_PLAYERS, NetDoor.MOST_PLAYERS + 1):
		counts.append("%d players" % count)
	_players = MenuTheme.option(counts, 0)
	_players.item_selected.connect(_on_players)
	column.add_child(MenuTheme.row("Most players", _players))
	_password = MenuTheme.field("", "None", 64)
	_password.custom_minimum_size = Vector2(300.0, 44.0)
	_password.text_changed.connect(
		func(typed: String) -> void:
			if session != null:
				session.door.password = typed.strip_edges()
	)
	# The keys are the box's while it has the cursor: the room goes on under the menu online.
	_password.focus_entered.connect(func() -> void: PlayerInput.typing = true)
	_password.focus_exited.connect(func() -> void: PlayerInput.typing = false)
	column.add_child(MenuTheme.row("Password", _password))
	_watchers = MenuTheme.toggle(true)
	_watchers.toggled.connect(_on_watchers)
	column.add_child(MenuTheme.row("Allow watchers", _watchers))
	_watch_free = MenuTheme.toggle(false)
	_watch_free.toggled.connect(_on_watch_free)
	column.add_child(MenuTheme.row("Watch without password", _watch_free))
	var note := MenuTheme.subtitle(
		"These only change who can join next. Nobody already here is shown out.", Type.LABEL
	)
	column.add_child(note)
	_back = MenuTheme.button("Back")
	_back.pressed.connect(func() -> void: closed.emit())
	column.add_child(_back)


## Up, showing what the door is set to now, with the cursor on the number of players.
func open() -> void:
	visible = true
	_back.text = "Next" if onward else "Back"
	var door := session.door if session != null else NetDoor.new()
	var count := clampi(door.max_players, NetDoor.FEWEST_PLAYERS, NetDoor.MOST_PLAYERS)
	_players.select(count - NetDoor.FEWEST_PLAYERS)
	_password.text = door.password
	_watchers.set_pressed_no_signal(door.watchers_allowed)
	_watch_free.set_pressed_no_signal(not door.watchers_need_password)
	_show_watching()
	_players.grab_focus()


func _on_players(index: int) -> void:
	var count := index + NetDoor.FEWEST_PLAYERS
	if session != null:
		session.door.max_players = count
	Game.settings.lobby_players = count
	Game.settings.save_to_disk()


func _on_watchers(on: bool) -> void:
	if session != null:
		session.door.watchers_allowed = on
	Game.settings.lobby_watchers = on
	Game.settings.save_to_disk()
	_show_watching()


func _on_watch_free(on: bool) -> void:
	if session != null:
		session.door.watchers_need_password = not on
	Game.settings.lobby_watch_free = on
	Game.settings.save_to_disk()


## Watching without the password is only a question while anybody may watch at all.
func _show_watching() -> void:
	_watch_free.disabled = not _watchers.button_pressed


func _exit_tree() -> void:
	PlayerInput.typing = false
