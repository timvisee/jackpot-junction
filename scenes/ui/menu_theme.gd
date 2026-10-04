class_name MenuTheme
extends RefCounted
## Shared helpers for the menu screens: the screen itself, a title, rows of options, buttons, and
## the pane every panel in the game is cut from.

## What is behind every menu screen.
const BACKGROUND := Color("#1E1E24")
## The pane, GAME.md 8.3: a dark translucent card with room to breathe and a bar of color along
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
## How loud a button is as it is pressed and as the cursor lands on it, GAME.md 8.4: well under
## everything else, since on a touch screen a tap is both at once.
const CLICK_DB := -20.0
const MOVE_DB := -26.0
## The edge a button wears when nothing is on it: enough to say it is a button and not enough
## to compete with the one that has the cursor.
const BUTTON_RIM := Color(1.0, 1.0, 1.0, 0.1)
## How big a switch is shown, in pixels, and how many times that it is drawn at.
const SWITCH := Vector2i(48, 24)
const SWITCH_DETAIL := 4
## How tall a box to pick from or type into is, for a pointer and for a finger, GAME.md 4.2: about
## the height of the buttons round it, and a thumb's width on a touch screen.
const BOX_HEIGHT := 52.0
const BOX_HEIGHT_TOUCH := 60.0
## How big the mark beside each entry of an option's list is shown, in pixels.
const MARK := 16
## How big the tick on a button that is on is, see [method tick].
const TICK := 24

## The two pictures of a switch, and of the mark on an option's list, drawn the first time one is
## asked for.
static var _switch_on: ImageTexture
static var _switch_off: ImageTexture
static var _mark_on: ImageTexture
static var _mark_off: ImageTexture
static var _tick: ImageTexture


static func background(parent: Control) -> void:
	var back := ColorRect.new()
	back.color = BACKGROUND
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(back)
	parent.move_child(back, 0)


## A screen: the background behind it and a column down the middle of it, which is the shape
## every menu in the game has. Returns the column to fill.
##
## A column taller than the window scrolls, following the cursor as it goes down the list, and
## sits in the middle of the window when it fits. A big UI scale on a short screen, GAME.md 8.5,
## makes a long list of settings longer than the window it is in.
static func screen(parent: Control, separation: int = 16) -> VBoxContainer:
	background(parent)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	parent.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", separation)
	center.add_child(column)
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


## How big a button is at the least.
static func button_size() -> Vector2:
	return Vector2(320.0, 56.0)


static func button(text: String, size: int = Type.LARGE) -> Button:
	var control := Button.new()
	control.text = text
	Type.set_font(control, Type.STRONG, size)
	_dress(control)
	control.custom_minimum_size = button_size()
	control.pressed.connect(func() -> void: Audio.play_sfx(&"ui_click", CLICK_DB, 0.0))
	control.focus_entered.connect(func() -> void: Audio.play_sfx(&"ui_move", MOVE_DB, 0.0))
	return control


## The button's card in its four states, and its words lit under the cursor.
static func _dress(control: Button) -> void:
	control.add_theme_stylebox_override("normal", button_style(BUTTON_BG, BUTTON_RIM))
	control.add_theme_stylebox_override("hover", button_style(BUTTON_HOVER, Palette.CHIP_GOLD))
	control.add_theme_stylebox_override("pressed", button_style(BUTTON_DOWN, Palette.CHIP_GOLD))
	control.add_theme_stylebox_override("focus", button_style(BUTTON_HOVER, Palette.CHIP_GOLD))
	control.add_theme_color_override("font_color", Color(0.88, 0.88, 0.92))
	control.add_theme_color_override("font_hover_color", Color.WHITE)
	control.add_theme_color_override("font_focus_color", Color.WHITE)
	control.add_theme_color_override("font_pressed_color", Color.WHITE)


## How tall a box to pick from or type into is here, see [constant BOX_HEIGHT].
static func box_height() -> float:
	return BOX_HEIGHT_TOUCH if TouchInput.enabled else BOX_HEIGHT


## Shows [param button] held down or not, for a button a touch screen presses rather than the
## mouse, GAME.md 4.2. It has no pointer over it to light it up, so while a finger is on it it
## wears the pressed look, gold edge and all, the way every other button does under the cursor.
static func hold(button: Button, held: bool) -> void:
	if button == null or not is_instance_valid(button):
		return
	button.toggle_mode = true
	button.set_pressed_no_signal(held)


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
	# Shown at the size it was designed at whatever the picture's own size is, so the four times
	# detail goes into how it looks rather than into how big it is.
	switch.add_theme_constant_override("icon_max_width", SWITCH.x)
	return switch


## The mark beside an entry of an option's list: a gold dot on the one picked, and a faint ring on
## each of the others so the list reads as a choice of one. Drawn finer than it is shown, as the
## switch is, and shown at [constant MARK] pixels.
static func _mark(on: bool) -> ImageTexture:
	if on and _mark_on != null:
		return _mark_on
	if not on and _mark_off != null:
		return _mark_off
	var side := MARK * SWITCH_DETAIL
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var middle := Vector2(side, side) * 0.5
	var radius := float(side) * 0.5 - 1.0
	var ring := 1.5 * SWITCH_DETAIL
	for y: int in side:
		for x: int in side:
			var inside := radius - (Vector2(x, y) + Vector2.ONE * 0.5).distance_to(middle)
			var covered := clampf(inside + 0.5, 0.0, 1.0)
			if not on:
				covered *= clampf(ring - inside + 0.5, 0.0, 1.0) * 0.35
			if covered <= 0.0:
				continue
			var ink := Palette.CHIP_GOLD if on else Color(0.86, 0.86, 0.92)
			image.set_pixel(x, y, Color(ink.r, ink.g, ink.b, covered))
	var drawn := ImageTexture.create_from_image(image)
	drawn.set_size_override(Vector2i(MARK, MARK))
	if on:
		_mark_on = drawn
	else:
		_mark_off = drawn
	return drawn


## A tick in the house's gold, [constant TICK] across, for a button that is on: the host's Pause
## game while its pause holds the room, GAME.md 3.8. Drawn once, at [constant SWITCH_DETAIL] times
## its size with soft edges, the way the switches are.
static func tick() -> ImageTexture:
	if _tick != null:
		return _tick
	var side := TICK * SWITCH_DETAIL
	var image := Image.create(side, side, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var s := float(side)
	var stroke := [Vector2(0.16, 0.54) * s, Vector2(0.4, 0.78) * s, Vector2(0.86, 0.24) * s]
	var half := 0.075 * s
	for y: int in side:
		for x: int in side:
			var at := Vector2(x, y) + Vector2.ONE * 0.5
			var near := minf(
				at.distance_to(Geometry2D.get_closest_point_to_segment(at, stroke[0], stroke[1])),
				at.distance_to(Geometry2D.get_closest_point_to_segment(at, stroke[1], stroke[2]))
			)
			var covered := clampf(half - near + 0.5, 0.0, 1.0)
			if covered > 0.0:
				var ink := Palette.CHIP_GOLD
				image.set_pixel(x, y, Color(ink.r, ink.g, ink.b, covered))
	_tick = ImageTexture.create_from_image(image)
	_tick.set_size_override(Vector2i(TICK, TICK))
	return _tick


## The picture of a switch in one of its two states, drawn once and kept.
##
## Drawn four times the size it is shown at, with soft edges rather than stepped ones, so that a
## screen that scales the menu up has something to scale up: a switch drawn at its own size is a
## staircase round every curve on a big display.
static func _switch(on: bool) -> ImageTexture:
	if on and _switch_on != null:
		return _switch_on
	if not on and _switch_off != null:
		return _switch_off
	var wide := SWITCH.x * SWITCH_DETAIL
	var high := SWITCH.y * SWITCH_DETAIL
	var image := Image.create(wide, high, true, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var radius := float(high) * 0.5
	var track := Palette.CHIP_GOLD.darkened(0.15) if on else Color(0.2, 0.2, 0.25)
	var rim := Color(0.86, 0.86, 0.92)
	var ball := Color(0.96, 0.96, 0.98)
	var knob := Vector2(float(wide) - radius if on else radius, radius)
	var knob_radius := radius - 3.0 * SWITCH_DETAIL
	for y: int in high:
		for x: int in wide:
			var at := Vector2(float(x) + 0.5, float(y) + 0.5)
			var spine := Vector2(clampf(at.x, radius, float(wide) - radius), radius)
			# How far inside the track's own edge this pixel is, which is also how much of it is
			# covered: half a pixel either side of the edge is the whole of the softness.
			var inside := radius - at.distance_to(spine)
			var covered := clampf(inside + 0.5, 0.0, 1.0)
			if covered <= 0.0:
				continue
			var edged := clampf(1.4 * SWITCH_DETAIL - inside, 0.0, 1.0)
			var on_knob := clampf(knob_radius - at.distance_to(knob) + 0.5, 0.0, 1.0)
			var ink := track.lerp(rim, edged).lerp(ball, on_knob)
			image.set_pixel(x, y, Color(ink.r, ink.g, ink.b, covered))
	image.generate_mipmaps()
	var drawn := ImageTexture.create_from_image(image)
	if on:
		_switch_on = drawn
	else:
		_switch_off = drawn
	return drawn


## A box to pick one of [param values] from, GAME.md 8.5: the same card as a button, and the list it
## opens the same card as a pane, see [method list].
static func option(values: Array, selected: int) -> OptionButton:
	var control := OptionButton.new()
	for value: Variant in values:
		control.add_item(str(value))
	control.selected = clampi(selected, 0, maxi(values.size() - 1, 0))
	control.custom_minimum_size = Vector2(240.0, box_height())
	Type.set_font(control, Type.STRONG, Type.BODY)
	_dress(control)
	control.add_theme_constant_override("arrow_margin", 16)
	list(control.get_popup())
	return control


## The list an option opens: a pane with its entries as big as the box they drop from, spaced out
## further for a finger, GAME.md 4.2, the one under the cursor lit the way a button is and the one
## picked marked in the house's gold. The engine's own was a grey strip of small print, the
## smallest thing on any screen it opened over.
static func list(popup: PopupMenu) -> void:
	var finger := TouchInput.enabled
	# A window rather than a control, so the font goes on by hand.
	popup.add_theme_font_override("font", Type.TEXT)
	popup.add_theme_font_size_override("font_size", Type.LARGE if finger else Type.BODY)
	var card := StyleBoxFlat.new()
	# Solid, unlike a pane: what it drops over is the next row of the same menu, words and all.
	card.bg_color = Color(PANE_BG, 1.0)
	card.set_corner_radius_all(BUTTON_RADIUS)
	card.set_border_width_all(2)
	card.border_color = BUTTON_RIM
	card.set_content_margin_all(10.0 if finger else 8.0)
	card.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	card.shadow_size = 12
	popup.add_theme_stylebox_override("panel", card)
	var lit := button_style(BUTTON_HOVER, Palette.CHIP_GOLD)
	lit.set_content_margin_all(0.0)
	popup.add_theme_stylebox_override("hover", lit)
	popup.add_theme_constant_override("v_separation", 28 if finger else 18)
	popup.add_theme_constant_override("h_separation", 12)
	popup.add_theme_constant_override("item_start_padding", 16)
	popup.add_theme_constant_override("item_end_padding", 28)
	popup.add_theme_color_override("font_color", Color(0.86, 0.86, 0.9))
	popup.add_theme_color_override("font_hover_color", Color.WHITE)
	for state: String in ["radio_checked", "checked"]:
		popup.add_theme_icon_override(state, _mark(true))
	for state: String in ["radio_unchecked", "unchecked"]:
		popup.add_theme_icon_override(state, _mark(false))


## A row of tabs, GAME.md 8.5, each a card like the buttons under them and padded like one, the
## page showing lit with the house's gold along its top, and taller for a finger.
static func tabs(container: TabContainer) -> void:
	var finger := TouchInput.enabled
	Type.set_font(container, Type.STRONG, Type.BODY)
	container.add_theme_stylebox_override("tab_unselected", _tab(BUTTON_BG, BUTTON_RIM, finger))
	container.add_theme_stylebox_override("tab_hovered", _tab(BUTTON_HOVER, BUTTON_RIM, finger))
	container.add_theme_stylebox_override("tab_disabled", _tab(BUTTON_DOWN, BUTTON_RIM, finger))
	container.add_theme_stylebox_override(
		"tab_selected", _tab(BUTTON_HOVER, Palette.CHIP_GOLD, finger)
	)
	var focus := _tab(Color.TRANSPARENT, Palette.CHIP_GOLD, finger)
	focus.draw_center = false
	focus.set_border_width_all(2)
	container.add_theme_stylebox_override("tab_focus", focus)
	container.add_theme_color_override("font_unselected_color", Color(0.72, 0.72, 0.78))
	container.add_theme_color_override("font_hovered_color", Color.WHITE)
	container.add_theme_color_override("font_selected_color", Color.WHITE)


static func _tab(fill: Color, edge: Color, finger: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.corner_radius_top_left = BUTTON_RADIUS
	style.corner_radius_top_right = BUTTON_RADIUS
	style.border_width_top = 3
	style.border_color = edge
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 16.0 if finger else 11.0
	style.content_margin_bottom = 16.0 if finger else 11.0
	return style


## A box to type something short into, sized like the option buttons beside it.
static func field(text: String, hint: String, max_length: int) -> LineEdit:
	var control := LineEdit.new()
	control.text = text
	control.placeholder_text = hint
	control.max_length = max_length
	control.custom_minimum_size = Vector2(240.0, box_height())
	Type.set_font(control, Type.TEXT, Type.BODY)
	return control


## A box for a host's name or address, GAME.md 9.3: a phone gives it the keyboard for addresses,
## which puts no space after a dot the way its keyboard for words does, and a space is dropped as
## it is typed, since no host has one.
static func host_field(text: String, max_length: int) -> LineEdit:
	var control := field(text, "", max_length)
	control.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_URL
	control.text_changed.connect(func(typed: String) -> void: _drop_spaces(control, typed))
	return control


## A box for a port, which a phone gives its keyboard of digits.
static func port_field(text: String, hint: String) -> LineEdit:
	var control := field(text, hint, 5)
	control.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	return control


static func _drop_spaces(control: LineEdit, typed: String) -> void:
	if not typed.contains(" "):
		return
	var caret := control.caret_column
	var before := typed.substr(0, caret).count(" ")
	control.text = typed.replace(" ", "")
	control.caret_column = caret - before


## The look of a pane, with [param edge] painted along its top. Handed out as a style rather
## than as a panel so that a screen which changes its own edge color, such as the podium
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
