class_name HostSettings
extends CanvasLayer
## The host choosing what the next match is going to be, in the waiting room, GAME.md 9.6: the
## same rows the lobby puts in front of a local match, laid over the room rather than instead of
## it.
##
## Over it, because the room is already open. Friends can join and drive round while the host is
## still choosing, and a host who has made up their mind closes it and drives too. It comes up
## when the room is first opened, since that is when the choosing is done, and again from the
## pause menu for a host who changes their mind.

## The host has finished choosing. What they chose is in [member options].
signal closed

var options: MatchOptions

var _panel: CenterContainer
var _done: Button


static func add_to(parent: Node) -> HostSettings:
	var pane := HostSettings.new()
	pane.name = "HostSettings"
	parent.add_child(pane)
	return pane


func _ready() -> void:
	# Under the pause menu and over the HUD: it is a menu, but not the one that stops the room.
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = CenterContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.visible = false
	add_child(_panel)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(shade)
	var pane := MenuTheme.pane()
	_panel.add_child(pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	pane.add_child(column)
	column.add_child(MenuTheme.title("Match settings", 44))
	column.add_child(MenuTheme.subtitle("Friends can join and drive while you choose.", Type.LABEL))
	options = MatchOptions.add_to(column, Game.settings)
	_done = MenuTheme.button("Done")
	_done.pressed.connect(close)
	column.add_child(_done)


func is_open() -> bool:
	return _panel.visible


func open() -> void:
	_panel.visible = true
	_done.grab_focus()


## Puts the choices away for next time and says the host is done. Closing is the only way out,
## so there is no choosing that is not kept: the rows are what the host was looking at.
func close() -> void:
	if not _panel.visible:
		return
	_panel.visible = false
	options.remember(Game.settings)
	Game.settings.save_to_disk()
	closed.emit()


## Back and pause both close it. Caught before anything else sees them, so the pause menu under it
## does not open on the same press; an open list of choices is a window of its own and closes
## itself first.
func _input(event: InputEvent) -> void:
	if not _panel.visible:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(InputActions.PAUSE):
		close()
		get_viewport().set_input_as_handled()
