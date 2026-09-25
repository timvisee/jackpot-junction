class_name LobbySettings
extends PanelContainer
## The host's settings for who may come into its game, GAME.md 9.6, from its pause menu in place of
## the menu itself: how many may play, its own players included, and a password to keep the game
## to the people who were told it. Changed at once; nobody already in is shown out by either, they
## only answer the next knock. The number is kept for next time and the password is not.

## Back: the menu is up again in its place.
signal closed

var session: NetSession

var _players: OptionButton
var _password: LineEdit
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
	var note := MenuTheme.subtitle(
		"Anybody joining is asked for it. Nobody already here is shown out.", Type.LABEL
	)
	column.add_child(note)
	_back = MenuTheme.button("Back")
	_back.pressed.connect(func() -> void: closed.emit())
	column.add_child(_back)


## Up, showing what the door is set to now, with the cursor on the number of players.
func open() -> void:
	visible = true
	var door := session.door if session != null else NetDoor.new()
	var count := clampi(door.max_players, NetDoor.FEWEST_PLAYERS, NetDoor.MOST_PLAYERS)
	_players.select(count - NetDoor.FEWEST_PLAYERS)
	_password.text = door.password
	_players.grab_focus()


func _on_players(index: int) -> void:
	var count := index + NetDoor.FEWEST_PLAYERS
	if session != null:
		session.door.max_players = count
	Game.settings.lobby_players = count
	Game.settings.save_to_disk()


func _exit_tree() -> void:
	PlayerInput.typing = false
