class_name ServerGames
extends Control
## The games on a dedicated server, GAME.md 9.3a, once Play Online has connected to it: a row each
## the way Play LAN lists the games on the network, with Join and Watch, see [GameList], and under
## them Make a game, which starts one there and goes into its lobby with the host's say. Joining or
## watching one goes into its lobby the way joining a LAN game does. Back hangs up and goes back to
## Play Online, and so does the server going away.

## The line to the server Play Online made, see [ServerLink].
var link: ServerLink
## Goes into a game's lobby with the configuration for it, and back to Play Online saying why:
## the waiting room and the screen, unless a test says otherwise.
var enter: Callable = Game.go_to_waiting
var leave: Callable = Game.go_to_play_online
var make_button: Button
var status: Label
## How far along the game being made for this machine is, under the line saying it is being made.
var making_bar: ProgressBar
## Why the screen is up again, back from one of the server's games.
var note: Label

var _games_line: Label
var _games: GameList


## A line in red for what went wrong, hidden while there is nothing to say.
static func red_line() -> Label:
	var line := Label.new()
	line.add_theme_font_size_override("font_size", 20)
	line.add_theme_color_override("font_color", Palette.CHIP_RED)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.visible = false
	return line


func _ready() -> void:
	link = Net.link
	var column := MenuTheme.screen(self, 16)
	column.add_child(MenuTheme.title("Games", 64))
	var at := "%s:%d" % [link.address, link.port] if link != null else "the server"
	column.add_child(
		MenuTheme.subtitle(
			"On the server at %s. Join or watch a game, or make one and host it from here." % at
		)
	)
	note = red_line()
	note.text = Game.play_online_note
	note.visible = not note.text.is_empty()
	Game.play_online_note = ""
	column.add_child(note)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 20)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.visible = false
	column.add_child(status)
	making_bar = LoadingScreen.bar()
	making_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	making_bar.visible = false
	column.add_child(making_bar)
	_games_line = MenuTheme.subtitle("", Type.LABEL)
	column.add_child(_games_line)
	_games = GameList.new()
	_games.chosen.connect(_join)
	column.add_child(_games)
	make_button = MenuTheme.button("Make a game")
	make_button.pressed.connect(_make)
	column.add_child(make_button)
	var back := MenuTheme.button("Back", 24)
	back.pressed.connect(func() -> void: leave.call(""))
	column.add_child(back)
	make_button.grab_focus()
	if link == null:
		leave.call_deferred("")
		return
	link.listed.connect(_show_games)
	link.made.connect(_on_made)
	link.not_made.connect(_on_not_made)
	link.making.connect(_on_making)
	link.lost.connect(func() -> void: leave.call("The server closed the connection"))
	_show_games(link.games)


## B on a pad, or Escape, is the Back button, GAME.md 4.2.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		leave.call("")


func _show_games(games: Array[Dictionary]) -> void:
	_games_line.text = (
		"Games on this server" if not games.is_empty() else "No games on this server yet"
	)
	_games.show_games(games, make_button)


func _make() -> void:
	if make_button.disabled:
		return
	make_button.disabled = true
	_say("Making a game...")
	making_bar.value = 0.0
	making_bar.visible = true
	link.make_game()


## The server's word on how far along the game is: the bar moves when a part of it is done, the way
## a loading screen's does, GAME.md 8.6, eased there over a moment rather than jumping.
func _on_making(done: float) -> void:
	if not making_bar.visible or done <= making_bar.value:
		return
	var eased := create_tween()
	eased.tween_property(making_bar, "value", done, 0.15)


func _on_made(port: int) -> void:
	making_bar.value = 1.0
	_enter(port, "join", true)


func _on_not_made(reason: String) -> void:
	make_button.disabled = false
	making_bar.visible = false
	_say(reason, true)


func _join(game: Dictionary, mode: String) -> void:
	_enter(int(game["port"]), mode, false)


## Into the lobby of the game on [param port], to play in it or, with [param mode] "watch", to
## watch it; [param making] for the game just made, which comes with the host's say.
func _enter(port: int, mode: String, making: bool) -> void:
	var config := MatchConfig.from_settings(Game.settings)
	config.online = "join"
	config.watching = mode == "watch"
	config.creating = making
	var named: Array[String] = [Game.settings.player_names[0]]
	config.human_names = named
	config.address = link.address
	config.port = port
	config.server = "%s:%d" % [link.address, link.port]
	enter.call(config)


func _say(text: String, bad := false) -> void:
	status.text = text
	status.visible = not text.is_empty()
	if bad:
		status.add_theme_color_override("font_color", Palette.CHIP_RED)
	else:
		status.remove_theme_color_override("font_color")
