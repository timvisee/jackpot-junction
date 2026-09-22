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
## A button is the same card as a pane, smaller and lit from behind when it has the cursor on
## it. Four states, because a menu you drive with a stick has to say where the cursor is without
## being pointed at.
const BUTTON_BG := Color(0.12, 0.12, 0.15, 0.92)
const BUTTON_HOVER := Color(0.17, 0.17, 0.21, 0.96)
const BUTTON_DOWN := Color(0.09, 0.09, 0.11, 0.98)
const BUTTON_RADIUS := 8
## The edge a button wears when nothing is on it: enough to say it is a button and not enough
## to compete with the one that has the cursor.
const BUTTON_RIM := Color(1.0, 1.0, 1.0, 0.1)
## How big a switch is drawn, in pixels.
const SWITCH := Vector2i(48, 24)

## The two pictures of one, drawn the first time one is asked for.
static var _switch_on: ImageTexture
static var _switch_off: ImageTexture


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


## The look of one button state: a dark card, optionally with the house's gold round it.
static func button_style(fill: Color, edge: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(BUTTON_RADIUS)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	if edge.a > 0.0:
		style.set_border_width_all(2)
		style.border_color = edge
	return style


static func button(text: String, size: int = Type.LARGE) -> Button:
	var control := Button.new()
	control.text = text
	Type.set_font(control, Type.STRONG, size)
	control.add_theme_stylebox_override("normal", button_style(BUTTON_BG, BUTTON_RIM))
	control.add_theme_stylebox_override("hover", button_style(BUTTON_HOVER, Palette.CHIP_GOLD))
	control.add_theme_stylebox_override("pressed", button_style(BUTTON_DOWN, Palette.CHIP_GOLD))
	control.add_theme_stylebox_override("focus", button_style(BUTTON_HOVER, Palette.CHIP_GOLD))
	control.add_theme_color_override("font_color", Color(0.88, 0.88, 0.92))
	control.add_theme_color_override("font_hover_color", Color.WHITE)
	control.add_theme_color_override("font_focus_color", Color.WHITE)
	control.custom_minimum_size = Vector2(320.0, 56.0)
	control.pressed.connect(func() -> void: Audio.play_sfx(&"ui_click", -6.0, 0.0))
	control.focus_entered.connect(func() -> void: Audio.play_sfx(&"ui_move", -12.0, 0.0))
	return control


## A switch for a setting that is on or off, GAME.md 8.5, drawn here rather than taken from the
## engine's theme: its empty tick box is a dark outline on a dark menu, so a row that was off
## showed nothing at all beside it. This one is a track with a knob in it -- dark with the knob
## at the near end when it is off, the house's gold with the knob at the far end when it is on --
## which reads across the room either way.
static func toggle(on: bool) -> CheckButton:
	var switch := CheckButton.new()
	switch.button_pressed = on
	for state: String in ["unchecked", "unchecked_mirrored", "unchecked_disabled"]:
		switch.add_theme_icon_override(state, _switch(false))
	for state: String in ["checked", "checked_mirrored", "checked_disabled"]:
		switch.add_theme_icon_override(state, _switch(true))
	switch.add_theme_color_override("icon_normal_color", Color.WHITE)
	switch.add_theme_color_override("icon_pressed_color", Color.WHITE)
	switch.add_theme_color_override("icon_hover_color", Color.WHITE)
	switch.add_theme_color_override("icon_hover_pressed_color", Color.WHITE)
	switch.add_theme_color_override("icon_focus_color", Color.WHITE)
	return switch


## The picture of a switch in one of its two states, drawn once and kept.
static func _switch(on: bool) -> ImageTexture:
	if on and _switch_on != null:
		return _switch_on
	if not on and _switch_off != null:
		return _switch_off
	var image := Image.create(SWITCH.x, SWITCH.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var radius := float(SWITCH.y) * 0.5
	var track := Palette.CHIP_GOLD.darkened(0.15) if on else Color(0.2, 0.2, 0.25)
	var rim := Color(0.86, 0.86, 0.92, 0.85)
	var knob := Vector2(float(SWITCH.x) - radius if on else radius, radius)
	for y: int in SWITCH.y:
		for x: int in SWITCH.x:
			var at := Vector2(float(x) + 0.5, float(y) + 0.5)
			var spine := Vector2(clampf(at.x, radius, float(SWITCH.x) - radius), radius)
			var edge := at.distance_to(spine)
			if edge > radius:
				continue
			if at.distance_to(knob) <= radius - 3.0:
				image.set_pixel(x, y, Color(0.96, 0.96, 0.98))
			elif edge > radius - 1.6:
				image.set_pixel(x, y, rim)
			else:
				image.set_pixel(x, y, track)
	var drawn := ImageTexture.create_from_image(image)
	if on:
		_switch_on = drawn
	else:
		_switch_off = drawn
	return drawn


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
