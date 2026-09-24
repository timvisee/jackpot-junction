class_name StatusPane
extends CanvasLayer
## Something the player has to be told, in the middle of the screen, on a pane built the way the
## joker detail pane is so the two read as the same game rather than as a label dropped on the
## floor: connecting, starting, and why a room is being left.

## Over the room and its HUD.
const LAYER := 30
## How long a room that has failed stays up to be read before it goes back to the menu.
const RETURN_DELAY := 2.5

## Whether the pane stands on the menus' background rather than over the room: for what is said
## before there is any room to stand over, such as a client waiting for the host to seat it.
var backdrop := false:
	set(on):
		backdrop = on
		if _backdrop != null:
			_backdrop.visible = on

var _panel: PanelContainer
var _label: Label
var _backdrop: ColorRect


## A pane over [param parent], empty and hidden until it has something to say.
static func add_to(parent: Node) -> StatusPane:
	var pane := StatusPane.new()
	pane.name = "Status"
	pane.layer = LAYER
	pane._build()
	pane.visible = false
	parent.add_child(pane)
	return pane


## Shows [param text], with [param color] as the bar along the pane's top edge.
func say(text: String, color: Color = Palette.NEON_CYAN) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = JokerDetail.BG
	style.set_corner_radius_all(8)
	style.content_margin_left = 34.0
	style.content_margin_right = 34.0
	style.content_margin_top = 22.0
	style.content_margin_bottom = 22.0
	style.border_width_top = JokerDetail.EDGE
	style.border_color = color
	_panel.add_theme_stylebox_override("panel", style)
	_label.text = text
	visible = true


## The room is over: says why, in red, and goes back to the menu once it has been read.
func fail(message: String) -> void:
	say(message + "\nReturning to the menu...", Palette.CHIP_RED)
	get_tree().create_timer(RETURN_DELAY).timeout.connect(func() -> void: Game.go_to_title())


## What [method say] writes on.
func text() -> String:
	return _label.text


func _build() -> void:
	_backdrop = ColorRect.new()
	# The loading screen's, which is what comes up after the words on the way to a map: the
	# menus' own slate there was a second screen flashing up between two dark ones.
	_backdrop.color = LoadingScreen.BACKDROP
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.visible = backdrop
	add_child(_backdrop)
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 34)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudText.shadowed(_label)
	_panel.add_child(_label)
