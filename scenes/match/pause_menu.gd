class_name PauseMenu
extends CanvasLayer
## Pausing freezes the whole match in single-player and local play, GAME.md 3.8. Online it takes
## the whole room: the menu opens straight away, and the match stops once everybody has opened
## theirs. Resume, Settings, or back to the title.
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

var _panel: CenterContainer
var _resume: Button
## The settings while they are open over the room, null otherwise.
var _settings: SettingsScreen


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
	_panel = CenterContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.visible = false
	add_child(_panel)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(shade)
	var pane := MenuTheme.pane()
	_panel.add_child(pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	pane.add_child(column)
	column.add_child(MenuTheme.title("Paused", 48))
	_resume = MenuTheme.button("Resume")
	_resume.pressed.connect(set_paused.bind(false))
	column.add_child(_resume)
	var settings := MenuTheme.button("Settings")
	settings.pressed.connect(open_settings)
	column.add_child(settings)
	var quit := MenuTheme.button("Back to title")
	quit.pressed.connect(
		func() -> void:
			set_paused(false)
			Game.go_to_title()
	)
	column.add_child(quit)


## Another thing the menu can do in this room, put under Resume. The waiting room of GAME.md 9.6
## adds the host's match settings, which are only a thing in there and only for the host.
func add_entry(text: String, action: Callable) -> Button:
	var button := MenuTheme.button(text)
	button.pressed.connect(
		func() -> void:
			set_paused(false)
			action.call()
	)
	_resume.add_sibling(button)
	return button


## The settings, over the room, with the menu waiting underneath for Back. The match stays paused
## while they are open, as far as this machine has any say in it, GAME.md 3.8.
func open_settings() -> void:
	if _settings != null:
		return
	_panel.visible = false
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
	# not something to back out of, and B is a button a player will be leaning on anyway.
	if _panel.visible and event.is_action_pressed(&"ui_cancel"):
		set_paused(false)
		get_viewport().set_input_as_handled()


## Opens or closes the menu for whoever is at this screen. Alone that is the same thing as
## stopping the match; online it is a request, and the match stops when the last player makes it.
func set_paused(paused: bool) -> void:
	_panel.visible = paused
	if session == null:
		_freeze(paused)
	else:
		session.want_pause(paused)
	if paused:
		_resume.grab_focus()


func _freeze(on: bool) -> void:
	get_tree().paused = on
