class_name ServerGames
extends Control
## The games on a dedicated server, GAME.md 9.3a, once Play Online has connected to it: a row each
## the way the LAN games screen lists the games on the network, with Join and Watch, see
## [GameList], and under them Make a game, which starts one there and goes into its lobby with the
## host's say. Joining or watching one goes into its lobby the way joining a LAN game does. Back
## hangs up and goes back to Play Online's servers, and so does the server going away.

## The line to the server Play Online made, see [ServerLink].
var link: ServerLink
## Goes into a game's lobby with the configuration for it, and back to Play Online saying why:
## the waiting room and the screen, unless a test says otherwise.
var enter: Callable = Game.go_to_waiting
var leave: Callable = Game.go_to_play_online
var make_button: Button
## The dialog saying a game is being made, with a bar for how far along it is, and OK once it
## could not be.
var busy: FormDialog
var making_bar: ProgressBar
var busy_button: Button
## Why the screen is up again, back from one of the server's games.
var note: Label

var _games: GameList
## The box the games are listed in, see [ListBox].
var _box: ListBox


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
		ListBox.fit(
			MenuTheme.subtitle("Connected to %s. Join a game on this server, or make one now." % at)
		)
	)
	note = ListBox.fit(red_line())
	note.text = Game.play_online_note
	note.visible = not note.text.is_empty()
	Game.play_online_note = ""
	column.add_child(note)
	_games = GameList.new()
	_games.chosen.connect(_join)
	_box = ListBox.of("Games on this server", _games, "Make a game")
	_box.link.pressed.connect(_make)
	column.add_child(_box)
	make_button = MenuTheme.button("Make a game")
	make_button.pressed.connect(_make)
	column.add_child(make_button)
	var back := MenuTheme.button("Back", 24)
	back.pressed.connect(func() -> void: leave.call(""))
	column.add_child(back)
	busy = FormDialog.add_to(self, "Making a game", "The server is starting it for you.")
	busy.name = "Busy"
	making_bar = busy.add_bar()
	making_bar.visible = false
	busy_button = busy.add_button("OK")
	busy_button.pressed.connect(_busy_done)
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


## B on a pad, or Escape, is the Back button, GAME.md 4.2: OK on a game that could not be made, and
## nothing while one is being made, which is under way at the server.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if not busy.is_open():
			leave.call("")
		elif busy_button.visible:
			_busy_done()


func _show_games(games: Array[Dictionary]) -> void:
	_games.show_games(games, make_button)


func _make() -> void:
	if make_button.disabled:
		return
	make_button.disabled = true
	busy.set_title("Making a game", "The server is starting it for you.")
	making_bar.value = 0.0
	making_bar.visible = true
	busy_button.visible = false
	busy.open(null)
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
	busy.set_title("Could not make a game", "")
	busy_button.visible = true
	if not busy.is_open():
		busy.open(busy_button)
	busy.say(reason)
	busy.focus(busy_button)


## OK on a game that could not be made: the dialog away, and the cursor on Make a game again.
func _busy_done() -> void:
	busy.close()
	make_button.grab_focus.call_deferred()


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
