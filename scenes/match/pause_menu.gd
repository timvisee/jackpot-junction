class_name PauseMenu
extends CanvasLayer
## Pausing freezes the whole match in single-player and local play, GAME.md 3.8. Online it takes
## the whole room: the menu opens straight away, and the match stops once everybody has opened
## theirs. Resume, Settings, or back to the title, and over each local player's corner of the HUD
## a switch for how they drive, and in the lobby and the Garage for their name and color too, see
## [DriveSwitches]. A map adds a way back to the lobby for whoever
## decides where the room goes: the one machine offline, the host online. Both ways out that end
## something for other people, or a Grand Prix, ask first, see [ConfirmPane].
##
## Settings opens over the room, and Back from it comes back here. It used to change scene, and
## coming back built the room again from scratch: a match in progress was thrown away for a new
## one, and online the room came back re-seating a match nobody else was in.

const SETTINGS_SCENE := preload("res://scenes/ui/settings_screen.tscn")
## Every room's menu is in this group, so something with no way to press Escape, such as the menu
## button on a touch screen, GAME.md 4.2, can open it.
const GROUP := &"pause_menu"
##
## Built on the pane every panel in the game is cut from, GAME.md 8.3, over a shade of the arena
## it is holding up.

## The session to ask online, null in a room where this machine is the only one.
var session: NetSession
## Whether the players here can change their names and colors from their switches: in the lobby
## and the Garage, GAME.md 4.4, and not in the middle of a map.
var names_and_colors := false:
	set(value):
		names_and_colors = value
		if _switches != null:
			_switches.names_and_colors = value

var _panel: Control
var _resume: Button
var _quit: Button
## Online, on the host: stopping the match for everybody now rather than waiting for them all to
## ask. On a client: the line saying the host has done that, for a player with no menu open.
var _force: Button
var _held: Control
var _switches: DriveSwitches
## The menu's own pane, and the question that takes its place while it is being asked.
var _main: PanelContainer
var _confirm: ConfirmPane
## What the question is asked before, and the button that asked it, for the cursor to go back to.
var _on_yes: Callable
var _asked_by: Button
## The settings while they are open over the room, null otherwise.
var _settings: SettingsScreen
## Online, on the host: who else is in the game, with a way to show any of them out, and the
## button that opens it. Up in place of the menu while it is open, as a question is.
var _players: ManagePlayers
var _manage: Button
## And who may come in: how many may play, and the password, GAME.md 9.6.
var _door: LobbySettings
var _door_button: Button
## Back to the lobby from a map, for whoever has the say, see [method offer_the_lobby].
var _to_lobby: Button
## Whatever is up in place of the menu just now, and the button that put it there.
var _aside: Control
var _aside_from: Button


## Hangs one over a room. An online room passes its session, which is what decides whether the
## whole room has asked to stop, see GAME.md 3.8.
static func add_to(parent: Node, net: NetSession = null) -> PauseMenu:
	var menu := PauseMenu.new()
	menu.name = "PauseMenu"
	menu.session = net
	parent.add_child(menu)
	return menu


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP)
	if session != null:
		session.pause_agreed.connect(_freeze)
	# The menu and the switches over the corners share one root, since a pad's cursor only looks for
	# the next button inside the tree it is in, and they are to be one screen to it.
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_panel = Control.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	root.add_child(_panel)
	# The shade beside the pane rather than in with it: a container centering the pane would
	# center the shade too, at the nothing it asks for, and the room would never go dark.
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(middle)
	var pane := MenuTheme.pane()
	middle.add_child(pane)
	_main = pane
	_confirm = ConfirmPane.new()
	_confirm.visible = false
	_confirm.answered.connect(_answered)
	middle.add_child(_confirm)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	pane.add_child(column)
	column.add_child(MenuTheme.title("Paused", 48))
	_resume = MenuTheme.button("Resume")
	_resume.pressed.connect(set_paused.bind(false))
	column.add_child(_resume)
	_force = MenuTheme.button("Pause game")
	_force.pressed.connect(_force_pause)
	_force.visible = false
	column.add_child(_force)
	_door = LobbySettings.new()
	_door.session = session
	_door.visible = false
	_door.closed.connect(_put_away_aside)
	middle.add_child(_door)
	_door_button = MenuTheme.button("Lobby settings")
	_door_button.pressed.connect(func() -> void: _open_aside(_door, _door_button))
	_door_button.visible = false
	column.add_child(_door_button)
	_players = ManagePlayers.new()
	_players.session = session
	_players.visible = false
	_players.closed.connect(_put_away_aside)
	middle.add_child(_players)
	_manage = MenuTheme.button("Manage players")
	_manage.pressed.connect(func() -> void: _open_aside(_players, _manage))
	_manage.visible = false
	column.add_child(_manage)
	var settings := MenuTheme.button("Settings")
	settings.pressed.connect(open_settings)
	column.add_child(settings)
	_quit = MenuTheme.button("Back to title")
	_quit.pressed.connect(_back_to_title)
	column.add_child(_quit)
	_switches = DriveSwitches.new()
	_switches.names_and_colors = names_and_colors
	_switches.visible = false
	root.add_child(_switches)
	# In the middle of the screen, on a pane of its own: a client that has not opened its menu is
	# looking at the room, and a line of text over the arena is a line nobody reads.
	var held := CenterContainer.new()
	held.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	held.mouse_filter = Control.MOUSE_FILTER_IGNORE
	held.visible = false
	root.add_child(held)
	var held_pane := MenuTheme.pane()
	held.add_child(held_pane)
	var words := Label.new()
	words.text = "The host paused the game"
	Type.strong(words, Type.HEADING, Palette.CHIP_WHITE)
	held_pane.add_child(words)
	_held = held


## Another thing the menu can do in this room, put under Resume, and under Pause game where the
## host has that. The waiting room of GAME.md 9.6 adds the host's match settings, which are only a
## thing in there and only for the host.
func add_entry(text: String, action: Callable) -> Button:
	var button := MenuTheme.button(text)
	button.pressed.connect(
		func() -> void:
			set_paused(false)
			action.call()
	)
	# Under Pause game rather than over it: stopping everybody is the host's first thing to reach for
	# in a room that is still running, and the match settings are a second thing to do in it.
	_force.add_sibling(button)
	return button


## Back to the lobby from a map, over Back to title, for whoever decides where the room goes: the
## one machine offline, back to Play, and the host online, back to the waiting room of GAME.md 9.6
## with everybody still connected. Either way it asks first, since it ends the map and any Grand
## Prix it is part of. Online it is only there while the host's say is this machine's, which at a
## dedicated server may come to it in the middle of a map, GAME.md 9.3a.
func offer_the_lobby() -> Button:
	var button := MenuTheme.button("Back to lobby")
	_to_lobby = button
	button.pressed.connect(
		func() -> void:
			var words := lobby_words(session != null, Game.grand_prix != null)
			ask(words, _leave_to_lobby, button)
	)
	_quit.add_sibling(button)
	_quit.get_parent().move_child(button, _quit.get_index())
	return button


## What is asked before going back to the lobby: the question, the line under it and the button
## that goes. Online, with everybody still connected; either way, the end of what is being played.
static func lobby_words(online: bool, grand_prix: bool) -> Array[String]:
	var line := "The Grand Prix ends here." if grand_prix else "This match ends here."
	if online:
		var what := "the Grand Prix" if grand_prix else "this match"
		line = (
			"Everybody comes back to the lobby with you and stays connected, but %s ends here."
			% what
		)
	return ["Back to the lobby?", line, "Back to lobby"]


## What is asked before leaving for the title online, and not offline, where nobody else is in
## it: the host takes everybody's room away with it, and a client only leaves, handing on the host's
## say if it has it at a dedicated server, GAME.md 9.3a, [param saying].
static func leave_words(hosting: bool, saying := false) -> Array[String]:
	if hosting:
		return [
			"Back to the title?",
			"Everybody who has joined will be disconnected.",
			"Disconnect everybody"
		]
	var line := "You leave the room, and the others play on without you."
	if saying:
		line = "You leave the room, the others play on without you, and the host's say passes on."
	return ["Back to the title?", line, "Leave"]


func _back_to_title() -> void:
	if not asks_before_leaving():
		_leave_to_title()
		return
	var saying := not session.is_host and session.host_controls.mine()
	ask(leave_words(session.is_host, saying), _leave_to_title, _quit)


## Whether the way back to the title asks first, see [method leave_words]: online, except for a
## host nobody has joined yet, player or watcher. There is nobody to disconnect, and a question
## about them would be a question about nothing.
func asks_before_leaving() -> bool:
	if session == null:
		return false
	return not session.is_host or session.anybody_connected()


func _leave_to_title() -> void:
	set_paused(false)
	Game.go_to_title()


func _leave_to_lobby() -> void:
	set_paused(false)
	if session != null:
		Game.back_to_the_room()
	else:
		Game.go_to_lobby(get_tree().get_first_node_in_group(&"match") as Match)


## Puts [param words], a question, the line under it and the button that goes ahead, in place of
## the menu, and does [param action] if the answer is yes. No, or Back, is the menu again with the
## cursor on [param from], the button that asked.
func ask(words: Array[String], action: Callable, from: Button) -> void:
	_on_yes = action
	_asked_by = from
	_main.visible = false
	_switches.visible = false
	_confirm.ask(words[0], words[1], words[2])


## Whether a question is up in place of the menu.
func asking() -> bool:
	return _confirm.visible


func _answered(yes: bool) -> void:
	_put_the_question_away()
	if yes:
		_on_yes.call()
	elif _asked_by != null and is_instance_valid(_asked_by):
		_asked_by.grab_focus()


func _put_the_question_away() -> void:
	_confirm.visible = false
	_main.visible = true
	_switches.visible = _panel.visible


## The settings, over the room, with the menu waiting underneath for Back. The match stays paused
## while they are open, as far as this machine has any say in it, GAME.md 3.8.
func open_settings() -> void:
	if _settings != null:
		return
	_panel.visible = false
	_switches.visible = false
	_settings = SETTINGS_SCENE.instantiate()
	_settings.overlay = true
	_settings.closed.connect(_settings_closed)
	add_child(_settings)


## Whether the settings are open over the room.
func settings_open() -> bool:
	return _settings != null


## Whether the menu or the settings from it are up, which is when nothing else in the room is
## listening.
func is_open() -> bool:
	return _panel.visible or _settings != null


## Opens the menu of the room [param tree] is running, if it has one.
static func open_in(tree: SceneTree) -> void:
	tree.call_group(GROUP, &"set_paused", true)


## Whether the room [param tree] is running has its menu up.
static func is_open_in(tree: SceneTree) -> bool:
	for menu: Node in tree.get_nodes_in_group(GROUP):
		if (menu as PauseMenu).is_open():
			return true
	return false


func _settings_closed() -> void:
	_settings = null
	_panel.visible = true
	# Up again as they now are: the settings may have changed how the first player drives.
	_switches.visible = true
	_switches.put_up(_buttons())
	_resume.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	# The settings have the controls while they are up: Escape there is their Back, and a rebind
	# of the pause button is a binding, not a request to close the menu.
	if _settings != null:
		return
	if event.is_action_pressed(InputActions.PAUSE):
		set_paused(not _panel.visible)
		get_viewport().set_input_as_handled()
		return
	# B on a pad backs out of the menu, GAME.md 4.2. It only closes: a menu nobody has opened is
	# not something to back out of, and B is a button a player will be leaning on anyway. Out of a
	# question it is no, and back to the menu.
	if _panel.visible and event.is_action_pressed(&"ui_cancel"):
		if asking():
			_answered(false)
		elif _aside != null:
			_put_away_aside()
		else:
			set_paused(false)
		get_viewport().set_input_as_handled()


## Opens or closes the menu for whoever is at this screen. Alone that is the same thing as
## stopping the match; online it is a request, and the match stops when the last player makes it.
func set_paused(paused: bool) -> void:
	# A question left up is not there the next time the menu opens, nor anything else in its place.
	if asking():
		_put_the_question_away()
	_put_away_aside()
	_panel.visible = paused
	_switches.visible = paused
	if paused:
		_switches.put_up(_buttons())
	else:
		_switches.take_down()
	if session == null:
		_freeze(paused)
	else:
		# The host closing its menu lets go of a pause it made everybody take.
		if not paused:
			session.host_controls.force_pause(false)
		session.want_pause(paused)
	if paused:
		_resume.grab_focus()


## The menu's own buttons, top to bottom, for the switches to be reached from.
func _buttons() -> Array[Button]:
	var found: Array[Button] = []
	for child: Node in _resume.get_parent().get_children():
		if child is Button:
			found.append(child)
	return found


## The match stopped for everybody, from the host's menu, GAME.md 3.8. Online a room only stops
## once everybody has asked, which is the right thing to wait for until somebody has to answer
## the door; this is the host not waiting. Closing the menu lets go of it.
func _force_pause() -> void:
	if session == null or not session.host_controls.mine():
		return
	session.host_controls.force_pause(true)
	_resume.grab_focus()


## Whether the host's button to stop everybody is worth showing: online, with the host's say,
## while the room is still running because somebody has not asked.
func _can_force() -> bool:
	return session != null and session.host_controls.mine() and not session.paused


## Puts [param pane] up in place of the menu, with the cursor in it; its Back, or B, is the menu
## again with the cursor on [param from].
func _open_aside(pane: Control, from: Button) -> void:
	_aside = pane
	_aside_from = from
	_main.visible = false
	_switches.visible = false
	pane.call(&"open")


func _put_away_aside() -> void:
	if _aside == null:
		return
	_aside.visible = false
	_aside = null
	_main.visible = true
	_switches.visible = _panel.visible
	if _panel.visible and is_instance_valid(_aside_from) and _aside_from.visible:
		_aside_from.grab_focus()


## The host's button comes and goes as the room stops and starts, and a client that has not opened
## its own menu is told why nothing is moving.
func _process(_delta: float) -> void:
	_force.visible = _panel.visible and _can_force()
	var says := session == null or session.host_controls.mine()
	_manage.visible = session != null and says
	_door_button.visible = _manage.visible
	if _to_lobby != null:
		_to_lobby.visible = says
	# The say handed to somebody else at a dedicated server, GAME.md 9.3a, takes its panes with it.
	if not says and (_aside == _players or _aside == _door):
		_put_away_aside()
	_held.visible = (
		session != null
		and not session.is_host
		and session.paused
		and not _panel.visible
		and _settings == null
	)


func _freeze(on: bool) -> void:
	get_tree().paused = on
