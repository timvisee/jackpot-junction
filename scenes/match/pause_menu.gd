class_name PauseMenu
extends CanvasLayer
## Pausing freezes the whole match in single-player and local play, GAME.md 3.8. Online it takes
## the whole room: the menu opens straight away, and the match stops once everybody has opened
## theirs. Resume, Settings, or back to the title.
##
## Built on the pane every panel in the game is cut from, GAME.md 8.3, over a shade of the arena
## it is holding up.

## The session to ask online, null in a room where this machine is the only one.
var session: NetSession

var _panel: CenterContainer
var _resume: Button


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
	settings.pressed.connect(
		func() -> void:
			set_paused(false)
			Game.go_to_settings(Game.MATCH_SCENE)
	)
	column.add_child(settings)
	var quit := MenuTheme.button("Back to title")
	quit.pressed.connect(
		func() -> void:
			set_paused(false)
			Game.go_to_title()
	)
	column.add_child(quit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.PAUSE):
		set_paused(not _panel.visible)
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
