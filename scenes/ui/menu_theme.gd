class_name MenuTheme
extends RefCounted
## Shared helpers for the menu screens: the screen itself, a title, rows of options, buttons, and
## the pane every panel in the game is cut from.

## The pane, GAME.md 8.3: a dark translucent card with room to breathe and a bar of colour along
## the top of it. The joker detail pane was the first thing built this way and everything since
## has followed it, so the shape lives here rather than being written out again per screen.
const PANE_BG := Color(0.07, 0.07, 0.09, 0.94)
const PANE_EDGE := 6
const PANE_RADIUS := 10


static func background(parent: Control) -> void:
	var back := ColorRect.new()
	back.color = Color("#1E1E24")
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(back)
	parent.move_child(back, 0)


## A screen: the background behind it and a column down the middle of it, which is the shape
## every menu in the game has. Returns the column to fill.
static func screen(parent: Control, separation: int = 16) -> VBoxContainer:
	background(parent)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(centre)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", separation)
	centre.add_child(column)
	return column


static func title(text: String, size: int = Type.HERO) -> Label:
	var label := Label.new()
	label.text = text
	Type.display(label, size, Palette.CHIP_GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


static func subtitle(text: String, size: int = Type.BODY) -> Label:
	var label := Label.new()
	label.text = text
	Type.text(label, size, Color(0.72, 0.72, 0.78))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


static func button(text: String, size: int = Type.LARGE) -> Button:
	var control := Button.new()
	control.text = text
	Type.set_font(control, Type.STRONG, size)
	control.custom_minimum_size = Vector2(320.0, 56.0)
	control.pressed.connect(func() -> void: Audio.play_sfx(&"ui_click", -6.0, 0.0))
	control.focus_entered.connect(func() -> void: Audio.play_sfx(&"ui_move", -12.0, 0.0))
	return control


static func option(values: Array, selected: int) -> OptionButton:
	var control := OptionButton.new()
	for value: Variant in values:
		control.add_item(str(value))
	control.selected = clampi(selected, 0, maxi(values.size() - 1, 0))
	control.custom_minimum_size = Vector2(220.0, 44.0)
	Type.set_font(control, Type.STRONG, Type.BODY)
	return control


## A box to type something short into, sized like the option buttons beside it.
static func field(text: String, hint: String, max_length: int) -> LineEdit:
	var control := LineEdit.new()
	control.text = text
	control.placeholder_text = hint
	control.max_length = max_length
	control.custom_minimum_size = Vector2(220.0, 44.0)
	Type.set_font(control, Type.TEXT, Type.BODY)
	return control


## The look of a pane, with [param edge] painted along its top. Handed out as a style rather
## than as a panel so that a screen which changes its own edge colour, such as the podium
## wearing the winner's, can keep hold of it.
static func pane_style(edge: Color = Palette.CHIP_GOLD) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANE_BG
	style.set_corner_radius_all(PANE_RADIUS)
	style.content_margin_left = 26.0
	style.content_margin_right = 26.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 22.0
	style.border_width_top = PANE_EDGE
	style.border_color = edge
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size = 20
	return style


## A pane to put things in.
static func pane(edge: Color = Palette.CHIP_GOLD) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", pane_style(edge))
	return panel


static func row(label_text: String, control: Control) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 24)
	var label := Label.new()
	label.text = label_text
	Type.text(label, Type.BODY, Color(0.86, 0.86, 0.9))
	label.custom_minimum_size = Vector2(260.0, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(label)
	line.add_child(control)
	return line
