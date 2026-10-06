class_name MenuTheme
extends RefCounted
## Shared helpers for the menu screens: the screen itself, a title, rows of options, buttons, and
## the pane every panel in the game is cut from. How they all look is the house's, GAME.md 8.1a,
## set once on the root window by [HouseTheme]; what is here is what each of them is made of.

## What is behind every menu screen: the house's stock, engraved, see [Backdrop].
const BACKGROUND := HouseTheme.STOCK
## The pane, GAME.md 8.1a: a ticket of stock with room to breathe, a hairline of foil inside its
## edge in the color of whatever the pane is about, banknote waves under its head and a shadow
## under it all. The joker detail pane was the first thing built as a pane and everything since has
## followed it, so the shape lives here rather than being written out again per screen.
const PANE_BG := Color(0.075, 0.07, 0.094, 0.95)
const PANE_NOTCH := 14.0
## How far in from a pane's edge its foil hairline runs, and the one gap between that hairline and
## whatever is inside it, on every side, above and below a perforation as much as beside the words:
## a box with more room either side of it than over it looks dropped in rather than set.
const PANE_INSET := 7.0
const PANE_GAP := 20.0
## How strongly the hairline of a pane shows round its head, and round its body under a
## perforation, see [Perforation].
const PANE_FRAME := 0.6
const PANE_FRAME_BODY := 0.16
## How far down a pane's waves reach.
const PANE_WAVES := 110.0
## A button is a ticket too, smaller, see [method HouseTheme.button_looks]: the stock it is cut
## from at rest, lit and held down, for the few places that cut one of their own.
const BUTTON_BG := HouseTheme.STOCK_RAISED
const BUTTON_HOVER := HouseTheme.STOCK_LIT
const BUTTON_DOWN := HouseTheme.STOCK_DOWN
const BUTTON_NOTCH := 9.0
## How loud a button is as it is pressed and as the cursor lands on it, GAME.md 8.4: well under
## everything else, since on a touch screen a tap is both at once.
const CLICK_DB := -20.0
const MOVE_DB := -26.0
## The edge a button wears when nothing is on it: enough to say it is a button and not enough
## to compete with the one that has the cursor.
const BUTTON_RIM := Color(1.0, 1.0, 1.0, 0.1)
## How big a switch is shown, in pixels.
const SWITCH := HouseArt.SWITCH
## How tall a box to pick from or type into is, for a pointer and for a finger, GAME.md 4.2: about
## the height of the buttons round it, and a thumb's width on a touch screen.
const BOX_HEIGHT := 52.0
const BOX_HEIGHT_TOUCH := 60.0
## How big the tick on a button that is on is, see [method tick], and how many times finer than
## that it is drawn.
const TICK := 24
const TICK_DETAIL := 4
## How far below where it settles a pane is dealt from, and how long it takes to get there, see
## [method deal].
const DEAL_RISE := 24.0
const DEAL_TIME := 0.18
## How far a pane drops as it is put away, and how long it takes to go, see [method put_away]:
## quicker than it came, since a player who closed it has already moved on.
const LEAVE_DROP := 14.0
const LEAVE_TIME := 0.12

## The tick, drawn the first time one is asked for.
static var _tick: ImageTexture


static func background(parent: Control) -> void:
	Backdrop.behind(parent)


## A screen: the background behind it and a column down the middle of it, which is the shape
## every menu in the game has. Returns the column to fill.
##
## A column taller than the window scrolls, following the cursor as it goes down the list, and
## sits in the middle of the window when it fits. A big UI scale on a short screen, GAME.md 8.5,
## makes a long list of settings longer than the window it is in.
static func screen(parent: Control, separation: int = 16) -> VBoxContainer:
	background(parent)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", separation)
	centered(parent).add_child(column)
	return column


## The middle of [param parent], for a page or a pane to sit in: in the middle of the window when
## it fits, and scrolled, following the cursor, when it does not, which a big UI scale on a short
## screen does to most of them, GAME.md 8.5. Returns the container to put it in.
static func centered(parent: Control) -> CenterContainer:
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
	return center


## A heading, GAME.md 8.1a: the display cut in capitals, in foil, standing on a dark shadow a few
## pixels down the way foil pressed into card stands proud of it.
static func title(text: String, size: int = Type.HERO) -> Label:
	var label := Label.new()
	label.text = text
	label.uppercase = true
	Type.display(label, size, HouseTheme.FOIL)
	# Barlow keeps more of a line over its capitals than under its baseline, so a line of nothing
	# but capitals sits low in its own box. A little room under it, or over it, puts them in the
	# middle of the box, which is where a header and a row center them.
	var font := Type.display_font()
	var over := font.get_ascent(size) - float(size) * Type.CAP_HEIGHT
	var under := font.get_descent(size)
	var even := StyleBoxEmpty.new()
	even.content_margin_top = maxf(under - over, 0.0)
	even.content_margin_bottom = maxf(over - under, 0.0)
	label.add_theme_stylebox_override("normal", even)
	label.add_theme_color_override("font_shadow_color", Color(0.29, 0.21, 0.06))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", maxi(2, size / 24))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


static func subtitle(text: String, size: int = Type.BODY) -> Label:
	var label := Label.new()
	label.text = text
	Type.text(label, size, HouseTheme.QUIET)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


## The look of one button state, for the few places that cut one of their own: a ticket of
## [param fill] with a foil hairline inside its edge, and [param edge] round it where that is given.
static func button_style(fill: Color, edge: Color = Color.TRANSPARENT) -> TicketStyle:
	var style := TicketStyle.cut(fill, BUTTON_NOTCH, 22.0, 12.0)
	style.frame = Color(HouseTheme.FOIL, HouseTheme.RIM)
	if edge.a > 0.0:
		style.border = edge
	return style


## How big a button is at the least.
static func button_size() -> Vector2:
	return Vector2(320.0, 56.0)


static func button(text: String, size: int = Type.LARGE) -> Button:
	var control := Button.new()
	control.text = text
	Type.set_font(control, Type.STRONG, size)
	control.custom_minimum_size = button_size()
	control.pressed.connect(func() -> void: Audio.play_sfx(&"ui_click", CLICK_DB, 0.0))
	control.focus_entered.connect(func() -> void: Audio.play_sfx(&"ui_move", MOVE_DB, 0.0))
	return control


## Makes [param control] the button that moves things on, GAME.md 8.1a: gold foil all the time,
## the one way forward on a screen, seen before anything else on it. One to a screen.
static func primary(control: Button) -> Button:
	control.theme_type_variation = HouseTheme.PRIMARY
	return control


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


## A switch for a setting that is on or off, GAME.md 8.5: a lane with a chip in it, see
## [method HouseArt.switch], which reads across the room either way. The engine's own empty tick
## box was a dark outline on a dark menu, so a row that was off showed nothing beside it at all.
## Its pictures are given here as well as by the house's theme, so a switch made before it is
## shown already wears them.
static func toggle(on: bool) -> CheckButton:
	var switch := CheckButton.new()
	switch.button_pressed = on
	for state: String in ["unchecked", "unchecked_mirrored", "unchecked_disabled"]:
		switch.add_theme_icon_override(state, HouseArt.switch(false))
	for state: String in ["checked", "checked_mirrored", "checked_disabled"]:
		switch.add_theme_icon_override(state, HouseArt.switch(true))
	# Shown at the size it was designed at whatever the picture's own size is, so the detail it is
	# drawn at goes into how it looks rather than into how big it is.
	switch.add_theme_constant_override("icon_max_width", SWITCH.x)
	return switch


## A tick in the house's gold, [constant TICK] across, for a button that is on: the host's Pause
## game while its pause holds the room, GAME.md 3.8. Drawn once, at [constant TICK_DETAIL] times
## its size with soft edges, the way the switches are.
static func tick() -> ImageTexture:
	if _tick != null:
		return _tick
	var side := TICK * TICK_DETAIL
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
				var ink := HouseTheme.FOIL
				image.set_pixel(x, y, Color(ink.r, ink.g, ink.b, covered))
	_tick = ImageTexture.create_from_image(image)
	_tick.set_size_override(Vector2i(TICK, TICK))
	return _tick


## A box to pick one of [param values] from, GAME.md 8.5: the same ticket as a button, its words
## clear of the chevron, and the list it opens a ticket too, see [method list].
static func option(values: Array, selected: int) -> OptionButton:
	var control := OptionButton.new()
	for value: Variant in values:
		control.add_item(str(value))
	control.selected = clampi(selected, 0, maxi(values.size() - 1, 0))
	control.custom_minimum_size = Vector2(240.0, box_height())
	Type.set_font(control, Type.STRONG, Type.BODY)
	list(control.get_popup())
	return control


## The list an option opens, as big as the box it drops from and spaced out further for a finger,
## GAME.md 4.2. The engine's own was a gray strip of small print, the smallest thing on any screen
## it opened over; the ticket it is cut from is the house's, see [HouseTheme].
static func list(popup: PopupMenu) -> void:
	var finger := TouchInput.enabled
	# A window rather than a control, so the font goes on by hand.
	popup.add_theme_font_override("font", Type.TEXT)
	popup.add_theme_font_size_override("font_size", Type.LARGE if finger else Type.BODY)
	if finger:
		popup.add_theme_constant_override("v_separation", 28)


## A row of tabs, GAME.md 8.5: index tabs on the pane under them, see
## [method HouseTheme.tab_looks], taller for a finger.
static func tabs(container: TabContainer) -> void:
	Type.set_font(container, Type.STRONG, Type.BODY)
	if not TouchInput.enabled:
		return
	var looks := HouseTheme.tab_looks(16.0)
	for state: StringName in looks:
		container.add_theme_stylebox_override(state, looks[state])


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


## The look of a pane, with [param edge] as the foil inside its edge. Handed out as a style rather
## than as a panel so that a screen which changes its own edge color, such as the podium wearing
## the winner's, can keep hold of it, see [method wear].
static func pane_style(edge: Color = HouseTheme.FOIL) -> TicketStyle:
	var style := TicketStyle.cut(PANE_BG, PANE_NOTCH, PANE_INSET + PANE_GAP, PANE_INSET + PANE_GAP)
	style.frame_inset = PANE_INSET
	style.engraving = Color(HouseTheme.FOIL, Engraving.ON_STOCK)
	style.waves = PANE_WAVES
	style.shadow = 18.0
	wear(style, edge)
	Surface.wear(style, "pane")
	return style


## The look of a slip, GAME.md 8.1a: a document rather than a pane, cream paper torn off the
## house's printer along its top and its foot, the license's arcs and a band of waves engraved in
## ink, and the hairline inside its edge in the color of what it is about, see [method wear]. The
## same one gap inside it as a pane has, clear of its teeth.
static func slip_style(edge: Color = HouseTheme.FOIL) -> TicketStyle:
	var style := TicketStyle.cut(
		HouseTheme.PAPER, 0.0, PANE_INSET + PANE_GAP, PANE_INSET + PANE_GAP + TicketStyle.TOOTH
	)
	style.torn = true
	style.fill_low = HouseTheme.PAPER.lerp(HouseTheme.PAPER_LOW, 0.6)
	style.frame_inset = PANE_INSET
	style.engraving = Color(HouseTheme.INK, Engraving.ON_PAPER)
	style.waves = PANE_WAVES
	style.arcs = true
	style.shadow = 18.0
	wear(style, edge)
	Surface.wear(style, "slip")
	return style


## Puts [param edge] on a pane's [param style] as the foil inside its edge.
static func wear(style: TicketStyle, edge: Color) -> void:
	style.frame = Color(edge, PANE_FRAME)
	style.frame_body = Color(edge, PANE_FRAME_BODY)


## The perforation under a pane's header, GAME.md 8.1a: put it in the pane's column after the
## title and whatever line goes with it, and the pane tears there, see [Perforation].
static func perforation() -> Perforation:
	return Perforation.new()


## A title with a road sign of [param kind] before it, for the header of a question, GAME.md 8.1a,
## both centered together.
static func signed(title_label: Label, kind: RoadSign.Kind) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 16)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sign_side := float(title_label.get_theme_font_size(&"font_size")) * 1.15
	line.add_child(RoadSign.of(kind, sign_side))
	title_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(title_label)
	return line


## Deals [param pane] in, GAME.md 8.1a: up from a little below where it settles and out of nothing,
## the way a ticket comes out of a printer, rather than just being there. It waits a frame for the
## pane to be laid out, and through the rise it asks its container where it rests every frame, see
## [method _place], so it rises to where it is put however late that is settled, and a pane dealt
## again on its way up or down starts from where it rests rather than from where it was caught. It
## runs under a paused room, which is where most panes come up. Not where nothing is drawn, which
## is where the tests run: a pane still on its way up is a button a click lands beside.
static func deal(pane: Control) -> void:
	if pane == null or not pane.is_inside_tree() or Game.is_headless():
		return
	_place(pane, _rest_of(pane), 0.0)
	_stop(pane)
	pane.modulate.a = 0.0
	var holder := pane.get_parent() as Container
	if holder != null:
		holder.queue_sort()
	pane.get_tree().process_frame.connect(func() -> void: _rise(pane), CONNECT_ONE_SHOT)


## The rise of [method deal], a frame on, once the pane has been laid out. Untyped, since the pane
## may have gone in that frame.
static func _rise(held: Variant) -> void:
	if not is_instance_valid(held):
		return
	var pane := held as Control
	pane.modulate.a = 1.0
	if not pane.is_visible_in_tree():
		return
	var rest := _rest_of(pane)
	var rise := pane.create_tween()
	rise.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	rise.set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	rise.tween_method(func(by: float) -> void: _place(pane, rest, by), DEAL_RISE, 0.0, DEAL_TIME)
	rise.tween_property(pane, "modulate:a", 1.0, DEAL_TIME * 0.7).from(0.0)
	pane.set_meta(&"dealing", rise)


## Puts [param pane] away the way [method deal] brings it, GAME.md 8.1a: down a little and out
## of sight, with [param shades] fading out alongside it, and then [param gone], which hides the
## pane or frees it, with the pane back where it rests. At once where nothing is drawn, as
## [method deal] is, and for a pane that is not showing. Dealt in again on its way out, it stays,
## and [param gone] never comes.
static func put_away(pane: Control, gone: Callable, shades: Array[CanvasItem] = []) -> void:
	if pane == null or not pane.is_inside_tree() or Game.is_headless():
		gone.call()
		return
	if not pane.is_visible_in_tree():
		gone.call()
		return
	var rest := _rest_of(pane)
	_stop(pane)
	var fall := pane.create_tween()
	fall.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fall.set_parallel(true).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	fall.tween_method(func(by: float) -> void: _place(pane, rest, by), 0.0, LEAVE_DROP, LEAVE_TIME)
	fall.tween_property(pane, "modulate:a", 0.0, LEAVE_TIME)
	for shade: CanvasItem in shades:
		fall.tween_property(shade, "modulate:a", 0.0, LEAVE_TIME)
	fall.chain().tween_callback(
		func() -> void:
			_place(pane, rest, 0.0)
			pane.modulate.a = 1.0
			for shade: CanvasItem in shades:
				if is_instance_valid(shade):
					shade.modulate.a = 1.0
			gone.call()
	)
	pane.set_meta(&"dealing", fall)


## Puts [param pane] [param by] below where it rests: where its container lays it, laid out again
## first so a late layout or one changed mid-way is where it ends up, or [param rest] for a pane
## placed by hand.
static func _place(pane: Control, rest: float, by: float) -> void:
	if not is_instance_valid(pane):
		return
	var holder := pane.get_parent() as Container
	if holder != null:
		holder.notification(Container.NOTIFICATION_SORT_CHILDREN)
		pane.position.y += by
	else:
		pane.position.y = rest + by


## Where a pane placed by hand rests: where it is, unless it is on its way in or out, when it is
## where it was before that began.
static func _rest_of(pane: Control) -> float:
	if not pane.has_meta(&"rest") or not _moving(pane):
		pane.set_meta(&"rest", pane.position.y)
	return pane.get_meta(&"rest")


static func _moving(pane: Control) -> bool:
	if not pane.has_meta(&"dealing"):
		return false
	var motion: Tween = pane.get_meta(&"dealing")
	return motion != null and motion.is_valid() and motion.is_running()


static func _stop(pane: Control) -> void:
	if pane.has_meta(&"dealing"):
		var before: Tween = pane.get_meta(&"dealing")
		if before != null and before.is_valid():
			before.kill()


## A pane to put things in.
static func pane(edge: Color = HouseTheme.FOIL) -> PanelContainer:
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


## [param button]'s words on lines of their own, centered over it: [param top] in bold over
## [param under], smaller and in [param under_ink], or [param top] alone for no [param under]. A
## line too long for the button ends in an ellipsis rather than running out of it. A kept server's
## row has them, GAME.md 9.3a, and a game's in a list of games, 9.3.
static func two_lines(button: Button, top: String, under: String, under_ink: Color) -> void:
	var words := VBoxContainer.new()
	words.name = "Words"
	words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(words)
	var title := _button_line(top, Type.STRONG, Type.BODY, HouseTheme.WORDS)
	title.name = "Name"
	words.add_child(title)
	if not under.is_empty():
		var line := _button_line(under, Type.TEXT, Type.SMALL, under_ink)
		line.name = "Where"
		words.add_child(line)


## What [param button]'s lines say, one under the other, for asking what it shows.
static func lines_of(button: Button) -> String:
	var lines: PackedStringArray = []
	if button != null and button.has_node("Words"):
		for each: Node in button.get_node("Words").get_children():
			lines.append((each as Label).text)
	return "\n".join(lines)


static func _button_line(text: String, font: Font, size: int, ink: Color) -> Label:
	var line := Label.new()
	line.text = text
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(line, font, size)
	Type.ink(line, ink)
	return line
