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

## How far in from the edges of the screen the pane keeps, when it has to be shrunk to fit.
const FIT_EDGE := 12.0

var options: MatchOptions
## Whether this is a room on one machine rather than an online one, which is only a matter of who
## it says can join while the choosing goes on.
var alone := false

var _panel: Control
var _middle: CenterContainer
var _pane: PanelContainer
var _done: Button


static func add_to(parent: Node, on_one_machine := false) -> HostSettings:
	var pane := HostSettings.new()
	pane.name = "HostSettings"
	pane.alone = on_one_machine
	parent.add_child(pane)
	return pane


func _ready() -> void:
	# Under the pause menu and over the HUD: it is a menu, but not the one that stops the room.
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = Control.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	add_child(_panel)
	# Beside the pane rather than in with it, as the pause menu's is, or the centering would shrink
	# it to nothing. The room carries on under it, so it lets everything through.
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(shade)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(middle)
	var pane := MenuTheme.pane()
	middle.add_child(pane)
	_pane = pane
	_middle = middle
	# Drawn smaller on a screen too short for it, a phone's under a big UI scale, GAME.md 8.5,
	# rather than running off the top and the bottom with Done out of reach.
	pane.resized.connect(_fit)
	middle.resized.connect(_fit)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	pane.add_child(column)
	column.add_child(MenuTheme.title("Match settings", 44))
	var joining := (
		"Anybody else here joins with J or Start while you choose."
		if alone
		else "Friends can join and drive while you choose."
	)
	column.add_child(MenuTheme.subtitle(joining, Type.LABEL))
	options = MatchOptions.add_to(column, Game.settings)
	_done = MenuTheme.button("Done")
	_done.pressed.connect(close)
	column.add_child(_done)


func is_open() -> bool:
	return _panel.visible


## The pane at its own size where the screen has room for it, and shrunk about the middle of the
## screen where it has not. What is shrunk is the holder that centers it: a container lays its
## children out at their own scale every time it sorts them, so the pane itself would not stay
## small.
func _fit() -> void:
	var room := _panel.size - Vector2.ONE * FIT_EDGE * 2.0
	var need := _pane.get_combined_minimum_size()
	if need.x <= 0.0 or need.y <= 0.0:
		return
	var fit := minf(room.x / need.x, room.y / need.y)
	_middle.pivot_offset = _middle.size * 0.5
	_middle.scale = Vector2.ONE * clampf(fit, 0.3, 1.0)


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


## Back closes it, caught before anything else sees it so the pause menu does not open on the same
## press of Escape; an open list of choices is a window of its own and closes itself first. A
## pad's Start is left alone: it is also how somebody new takes a seat, and a friend sitting down
## should not close the host's menu for them.
func _input(event: InputEvent) -> void:
	if not _panel.visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
