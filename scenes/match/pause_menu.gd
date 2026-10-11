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
## Over the room, its HUD and the host's match settings, and over what the room is saying while
## it connects, see [StatusPane], so a player kept waiting can open it and leave.
const LAYER := 20
## The air between the menu's buttons, its heading's size and its buttons' height: as ever, and on a
## short screen, see [method _fit].
const SEPARATION := 16
const HEADING := 48
const SHORT_SEPARATION := 8
const SHORT_HEADING := 36
const SHORT_BUTTON := 40.0
## On a short screen the buttons' words are body-sized and this much less of their padding is kept
## over and under them, see [method _compact].
const SHORT_WORDS := Type.BODY
const SHORT_PADDING := 6.0
## The looks a button has, each made tighter on a short screen.
const LOOKS: Array[StringName] = [
	&"normal", &"hover", &"focus", &"pressed", &"hover_pressed", &"disabled"
]

## Every menu in a tree, kept as they come and go, for [method is_open_in]: the touch controls,
## the emotes and the mouse each ask it every frame, and asking the tree walks the group.
static var _in_tree: Array[PauseMenu] = []
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

## The menu's heading, Paused or Menu, see [method heading].
var _heading: Label
var _panel: Control
## The shade behind the menu, which fades out with it, and whether the menu is on its way out,
## which is not open: the room is the player's again from the moment they close it.
var _shade: ColorRect
var _leaving := false
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
## What the question is asked before, the button that asked it, for the cursor to go back to, and
## what it stands in place of: the menu, or what is up in its place, see [member _aside].
var _on_yes: Callable
var _asked_by: Button
var _asked_over: Control
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
## The loyalty program over the menu while it is up, GAME.md 8.9, opened by its button over
## Settings once the profile playing has been welcomed to it.
var _loyalty: LoyaltyDialog
## What is pinned in the loyalty program, on a scrap of its own under the menu's pane.
var _pinned_note: PinnedNote


## Hangs one over a room. An online room passes its session, which is what decides whether the
## whole room has asked to stop, see GAME.md 3.8.
static func add_to(parent: Node, net: NetSession = null) -> PauseMenu:
	var menu := PauseMenu.new()
	menu.name = "PauseMenu"
	menu.session = net
	parent.add_child(menu)
	return menu


func _enter_tree() -> void:
	_in_tree.append(self)


func _ready() -> void:
	layer = LAYER
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
	_shade = shade
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
	column.add_theme_constant_override("separation", SEPARATION)
	pane.add_child(column)
	_heading = MenuTheme.title(heading(session != null, false), HEADING)
	column.add_child(_heading)
	column.add_child(MenuTheme.perforation())
	# Back to driving is the way on from here, GAME.md 8.1a, in foil.
	_resume = MenuTheme.primary(MenuTheme.button("Resume"))
	_resume.pressed.connect(set_paused.bind(false))
	column.add_child(_resume)
	_force = MenuTheme.button("Pause game")
	_force.pressed.connect(_force_pause)
	_force.visible = false
	# The tick on the far end of the words, and no bigger than they are.
	_force.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_force.expand_icon = false
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
	_players.asking.connect(ask)
	middle.add_child(_players)
	_manage = MenuTheme.button("Manage players")
	_manage.pressed.connect(func() -> void: _open_aside(_players, _manage))
	_manage.visible = false
	column.add_child(_manage)
	if Game.settings.profile.loyalty.welcomed:
		var program := MenuTheme.button(LoyaltyDialog.program_name(Game.settings.profile))
		program.name = "Loyalty"
		program.pressed.connect(open_loyalty)
		column.add_child(program)
		# What is pinned in it, apart from the pane, GAME.md 8.9.
		_pinned_note = PinnedNote.new(pane)
		_pinned_note.opened.connect(open_loyalty)
		_panel.add_child(_pinned_note)
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
## host has that, or under [param under], an entry added before. The waiting room of GAME.md 9.6
## adds the host's match settings, which are only a thing in there and only for the host.
func add_entry(text: String, action: Callable, under: Control = null) -> Button:
	var button := MenuTheme.button(text)
	button.pressed.connect(
		func() -> void:
			set_paused(false)
			action.call()
	)
	# Under Pause game rather than over it: stopping everybody is the host's first thing to reach for
	# in a room that is still running, and the match settings are a second thing to do in it.
	if under != null:
		under.add_sibling(button)
	else:
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
## say if it has it at a dedicated server, GAME.md 9.3a, [param saying], to one of the
## [param others] still playing. With nobody else playing there is nobody to hand it to: the game
## ends, for the [param watching] watchers there are, or for nobody.
static func leave_words(
	hosting: bool, saying := false, others := 1, watching := 0
) -> Array[String]:
	if hosting:
		return [
			"Back to the title?",
			"Everybody who has joined will be disconnected.",
			"Disconnect everybody"
		]
	var line := "You leave the room, and the others play on without you."
	if saying and others <= 0:
		line = (
			"You leave the room, and with nobody else playing the game ends for those watching."
			if watching > 0
			else "You leave the room, and with nobody else in it the game ends."
		)
	elif saying:
		line = "You leave the room, the others play on without you, and the host's say passes on."
	return ["Back to the title?", line, "Leave"]


## Who else is in the room, as the host's say sees it, GAME.md 9.3a: players at other machines,
## and watchers. The same list Manage players shows.
static func others_here(session: NetSession) -> Vector2i:
	var others := 0
	var watching := 0
	for guest: Dictionary in session.host_controls.guests():
		if guest.has("color"):
			others += 1
		else:
			watching += 1
	return Vector2i(others, watching)


func _back_to_title() -> void:
	if not asks_before_leaving():
		_leave_to_title()
		return
	var saying := not session.is_host and session.host_controls.mine()
	var here := others_here(session) if saying else Vector2i(1, 0)
	ask(leave_words(session.is_host, saying, here.x, here.y), _leave_to_title, _quit)


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
## the menu, or of what is up in its place, and does [param action] if the answer is yes. No, or
## Back, is the menu or that again, with the cursor on [param from], the button that asked.
func ask(words: Array[String], action: Callable, from: Button) -> void:
	_on_yes = action
	_asked_by = from
	_asked_over = _aside if _aside != null else _main
	_asked_over.visible = false
	_switches.visible = false
	_confirm.ask(words[0], words[1], words[2])


## Whether a question is up in place of the menu.
func asking() -> bool:
	return _confirm.visible


func _answered(yes: bool) -> void:
	var over := _asked_over
	_put_the_question_away()
	if yes:
		_on_yes.call()
		# Asked over the menu, yes goes on somewhere else; over the list of players, the list is
		# up again, and the row of somebody gone gives the cursor to its Back.
		if over == _main:
			return
	if _asked_by != null and is_instance_valid(_asked_by) and _asked_by.is_visible_in_tree():
		_asked_by.grab_focus()


func _put_the_question_away() -> void:
	_confirm.visible = false
	var over := _asked_over if _asked_over != null and is_instance_valid(_asked_over) else _main
	_asked_over = null
	over.visible = true
	_switches.visible = _panel.visible and over == _main


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


## The loyalty program over the menu, GAME.md 8.9, where it was left or on the map at [param at],
## as the pinned note asks; put away, the cursor goes back to its button.
func open_loyalty(at := &"") -> void:
	if _loyalty != null:
		return
	_loyalty = LoyaltyDialog.open(self, false, at)
	_loyalty.put_away.connect(
		func() -> void:
			_loyalty = null
			if _pinned_note != null:
				_pinned_note.look()
	)


## Whether the settings are open over the room.
func settings_open() -> bool:
	return _settings != null


## Whether the menu or the settings from it are up, which is when nothing else in the room is
## listening.
func is_open() -> bool:
	return (_panel.visible and not _leaving) or _settings != null


## Opens the menu of the room [param tree] is running, if it has one.
static func open_in(tree: SceneTree) -> void:
	tree.call_group(GROUP, &"set_paused", true)


func _exit_tree() -> void:
	_in_tree.erase(self)


## Whether the room [param tree] is running has its menu up.
static func is_open_in(tree: SceneTree) -> bool:
	for menu: PauseMenu in _in_tree:
		if menu.get_tree() == tree and menu.is_open():
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
		MenuTheme.back_sound()
		if asking():
			_answered(false)
		elif _aside != null:
			_put_away_aside()
		else:
			set_paused(false)
		get_viewport().set_input_as_handled()


## Opens or closes the menu for whoever is at this screen. Alone that is the same thing as
## stopping the match; online it is a request, and the match stops when the last player makes it.
## The menu as tall as the screen has room for: on a short screen, a phone's under a big UI scale,
## its buttons shorter, closer together and under a smaller heading, so all of a host's at a
## server fit, eight of them, the cursor and the drive switches beside it going as ever.
func _fit() -> void:
	var short := MenuTheme.is_short(self)
	var column := _resume.get_parent() as VBoxContainer
	column.add_theme_constant_override("separation", SHORT_SEPARATION if short else SEPARATION)
	_heading.add_theme_font_size_override("font_size", SHORT_HEADING if short else HEADING)
	var tall := SHORT_BUTTON if short else MenuTheme.button_size().y
	for button: Button in _buttons():
		button.custom_minimum_size.y = tall
		_compact(button, short)


## [param button] tighter on a short screen, or as the theme has it: its words body-sized, and its
## looks, whichever they are, the foil of Resume's or the stock of the rest, with less padding over
## and under the words.
func _compact(button: Button, short: bool) -> void:
	for look: StringName in LOOKS:
		button.remove_theme_stylebox_override(look)
		if not short:
			continue
		var tight := button.get_theme_stylebox(look).duplicate() as StyleBox
		tight.content_margin_top = maxf(tight.content_margin_top - SHORT_PADDING, 0.0)
		tight.content_margin_bottom = maxf(tight.content_margin_bottom - SHORT_PADDING, 0.0)
		button.add_theme_stylebox_override(look, tight)
	button.add_theme_font_size_override(&"font_size", SHORT_WORDS if short else Type.LARGE)


func set_paused(paused: bool) -> void:
	# A question left up is not there the next time the menu opens, nor anything else in its place.
	if asking():
		_put_the_question_away()
	_put_away_aside()
	_leaving = not paused and _panel.visible
	if paused:
		_fit()
		_panel.visible = true
		_shade.modulate.a = 1.0
	else:
		var shades: Array[CanvasItem] = [_shade]
		MenuTheme.put_away(_main, _gone, shades)
	_switches.visible = paused
	if paused:
		MenuTheme.deal(_main)
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


## The menu put away, once it has gone, see [method MenuTheme.put_away].
func _gone() -> void:
	if not _leaving and _panel.visible and _main.visible:
		return
	_leaving = false
	_panel.visible = false


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
	# Pressed again, it lets go: the room runs on for whoever is not asking to stop.
	session.host_controls.force_pause(not session.host_controls.forcing)
	_show_force()


## Whether the host's button to stop everybody is there: online, with the host's say. Kept up
## while the room stands, with a tick in it while its own pause is what is holding the room, so
## the one who stopped everybody can see they did and let go again, GAME.md 3.8.
func _can_force() -> bool:
	return session != null and session.host_controls.mine()


## The button as the pause stands: ticked and held down while this machine's pause holds the room.
func _show_force() -> void:
	var forcing := session != null and session.host_controls.forcing
	_force.icon = MenuTheme.tick() if forcing else null
	MenuTheme.hold(_force, forcing)


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
	if _force.visible:
		_show_force()
	var says := session == null or session.host_controls.mine()
	_manage.visible = session != null and says
	_door_button.visible = _manage.visible
	if _to_lobby != null:
		_to_lobby.visible = says
	# The say handed to somebody else at a dedicated server, GAME.md 9.3a, takes its panes with it.
	if not says and (_aside == _players or _aside == _door):
		if asking() and _asked_over == _aside:
			_put_the_question_away()
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
	if _heading != null:
		_heading.text = heading(session != null, on)


## What the menu is headed, GAME.md 3.8: Paused, which it always is alone, since opening it stops
## the match; online Menu, as the match goes on for the others, until everybody has it open and the
## match has stopped, [param stopped].
static func heading(online: bool, stopped: bool) -> String:
	return "Paused" if stopped or not online else "Menu"
