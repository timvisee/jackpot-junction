class_name MenuTheme
extends RefCounted
## Shared helpers for the menu screens: the screen itself, a title, rows of options, buttons.


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


static func title(text: String, size: int = 72) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Palette.CHIP_GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


static func subtitle(text: String, size: int = 24) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.88))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


static func button(text: String, size: int = 32) -> Button:
	var control := Button.new()
	control.text = text
	control.add_theme_font_size_override("font_size", size)
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
	control.add_theme_font_size_override("font_size", 22)
	return control


static func row(label_text: String, control: Control) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 24)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 24)
	label.custom_minimum_size = Vector2(260.0, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(label)
	line.add_child(control)
	return line
