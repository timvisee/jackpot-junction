class_name ListBox
extends VBoxContainer
## The box a list of servers or games is shown in, GAME.md 9.3 and 9.3a: a well sunk into the
## screen, darker than it with a shade along its inside top edge and a faint rim, under a small
## gray heading, with room for about five rows, which scrolls once there are more. It is there and
## as big empty as full, so the list reads as the list and the buttons round it as buttons rather
## than one column running into the next.
## Sunk into the screen rather than raised off it: the game's pane, the gold-barred card of the
## questions and the pause menu, read as a dialog box come up over the screen, and this is part of
## it. Play Online's servers, LAN games' games and a server's games are each shown in one.
##
## Under the last row of the list is a link, the way to put something on it: Add a server, Host a
## game or Make a game, the same as the button for it under the box, but where the eye already is
## when it finds the list wanting. An empty list is the link alone at the top, where it would have
## said it was empty, which is the same thing said as something to do about it.

## How wide the box is, and how tall a row is at the tallest, and the gap between rows: a box has
## room for five unless it says fewer.
const WIDTH := 760.0
const ROW := 64.0
const GAP := 8.0
const ROOMY := 5
const ROOM := ROOMY * ROW + (ROOMY - 1) * GAP
## The heading's ink, the well's fill over the screen, its shade and its rim, how deep the notches
## of its corners are, a ticket's, GAME.md 8.1a, how far in from its edge the rows stand, and how
## deep the shade along its top is.
const HEADING_INK := Color(0.62, 0.62, 0.68)
const FILL := Color(0.0, 0.0, 0.0, 0.32)
const SHADE := Color(0.0, 0.0, 0.0, 0.3)
const RIM := Color(1.0, 1.0, 1.0, 0.09)
const NOTCH := 9.0
const INSET := 12
const SHADE_DEPTH := 7
## How dark a flush well's shade is at its foot, a share of how dark along its top, see
## [method Well._draw_inlay].
const FOOT_SHADE := 0.4
## The link at the bottom: its ink, under the cursor or a pointer, and its size.
const LINK_INK := Palette.CHIP_GOLD
const LINK_HOVER := Color(1.0, 0.9, 0.62)
const LINK_SIZE := Type.BODY
## The room round the link, above and below it and either side, so it stands in the list as an item
## of it, about as tall as a row, rather than as a line squeezed in under the last one.
const LINK_ROOM := Vector2(16.0, 12.0)

## What is listed: a [ServerList] or a [GameList], or anything else with rows in it.
var list: Control
## The link at the bottom of the well, which puts something on the list.
var link: LinkButton

var _heading: Label
var _scroll: ScrollContainer


## The well itself: a ticket cut into the screen rather than laid on it, its fill, the shade along
## its inside top edge, and its rim, drawn under the rows it holds.
class Well:
	extends MarginContainer

	## How far in from its edge what it holds stands, [constant ListBox.INSET] or less, see
	## [method set_inset].
	var inset := ListBox.INSET
	## What it holds runs right to its edge, as the loyalty program's map does: held in a [Cut]
	## of the well's own shape, so nothing of it shows in the notches of its corners, and its shade
	## and its rim drawn over it rather than under it. Set before it is in the tree, and what it
	## holds put in [method inside].
	var flush := false
	## Not drawn at all, only holding what it holds in from its edge: for a well something else
	## draws under it, as the catalog's sheet is drawn under its cards, see [ProofCover].
	var bare := false
	var _look: TicketStyle
	var _inside: Cut

	func _ready() -> void:
		set_inset(inset)
		_look = TicketStyle.cut(ListBox.FILL, ListBox.NOTCH, 0.0, 0.0)
		if not flush:
			_look.border = ListBox.RIM
			_look.border_width = 1.0
			return
		# Over everything it holds, whatever is added to it after.
		var over := Control.new()
		over.name = "Over"
		over.mouse_filter = Control.MOUSE_FILTER_IGNORE
		over.draw.connect(_draw_over.bind(over))
		add_child(over, false, Node.INTERNAL_MODE_BACK)

	## Where what it holds goes: in a flush well the [Cut] of its shape, otherwise the well.
	func inside() -> Container:
		if not flush:
			return self
		if _inside == null:
			_inside = Cut.new()
			_inside.name = "Cut"
			add_child(_inside)
		return _inside

	## What it holds [param value] in from its edge; a flush one's always at it.
	func set_inset(value: int) -> void:
		inset = 0 if flush else value
		for side: String in ["left", "right", "top", "bottom"]:
			add_theme_constant_override("margin_%s" % side, inset)

	func _draw() -> void:
		if bare:
			return
		draw_style_box(_look, Rect2(Vector2.ZERO, size))
		if not flush:
			_draw_shade(self)

	## The shade round a flush well's inside, on [param on], so what it holds lies sunk in it: along
	## every edge and round the notches, [constant ListBox.SHADE_DEPTH] lines a pixel further in each,
	## deepest along its top and lighter down its sides to [constant ListBox.FOOT_SHADE] of that at
	## its foot, as light from over it leaves it.
	func _draw_inlay(on: CanvasItem) -> void:
		var outline := TicketStyle.outline(size, ListBox.NOTCH)
		for i: int in ListBox.SHADE_DEPTH:
			var inset := Geometry2D.offset_polygon(outline, -(1.0 + i))
			if inset.is_empty():
				continue
			var line: PackedVector2Array = inset[0]
			line.append(line[0])
			var fade := 1.0 - float(i) / ListBox.SHADE_DEPTH
			var colors := PackedColorArray()
			for point: Vector2 in line:
				var down := clampf(point.y / maxf(size.y, 1.0), 0.0, 1.0)
				var dark := ListBox.SHADE.a * fade * fade * lerpf(1.0, ListBox.FOOT_SHADE, down)
				colors.append(Color(ListBox.SHADE, dark))
			on.draw_polyline_colors(line, colors, 1.0)

	## The shade along its inside top edge, on [param on].
	func _draw_shade(on: CanvasItem) -> void:
		for i: int in ListBox.SHADE_DEPTH:
			var fade := 1.0 - float(i) / ListBox.SHADE_DEPTH
			var shade := Color(ListBox.SHADE, ListBox.SHADE.a * fade * fade)
			on.draw_rect(
				Rect2(ListBox.NOTCH + 1.0, 1.0 + i, size.x - ListBox.NOTCH * 2.0 - 2.0, 1.0), shade
			)

	## Over a flush well's contents, on [param over]: the shade round its inside and its rim.
	func _draw_over(over: Control) -> void:
		_draw_inlay(over)
		var rim := TicketStyle.outline(size, ListBox.NOTCH)
		rim.append(rim[0])
		over.draw_polyline(rim, ListBox.RIM, 1.0, true)


## What a flush [Well] holds, cut to the well's shape: drawn only as a mask its children are
## clipped to, its notched corners left out, so the pane and the well show through them as they do
## round a well of any other kind.
class Cut:
	extends MarginContainer

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		resized.connect(queue_redraw)

	func _draw() -> void:
		var shape := TicketStyle.outline(size, ListBox.NOTCH)
		if shape.size() < 3:
			return
		draw_colored_polygon(shape, Color.WHITE)
		# Its edge smoothed, so the notches' curves are not cut in steps.
		shape.append(shape[0])
		draw_polyline(shape, Color.WHITE, 1.0, true)


## A box headed [param heading] holding [param rows], and under them a link saying [param linked],
## with room for [param room] rows, five unless a screen with two boxes says fewer.
static func of(heading: String, rows: Control, linked: String, room := ROOMY) -> ListBox:
	var box := ListBox.new()
	box.list = rows
	box._build(heading, linked, room)
	return box


func _build(heading: String, linked: String, rows_room: int) -> void:
	add_theme_constant_override("separation", 8)
	custom_minimum_size = Vector2(WIDTH, 0.0)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_heading = Label.new()
	_heading.text = heading.to_upper()
	Type.set_font(_heading, Type.STRONG, Type.LABEL)
	Type.ink(_heading, HEADING_INK)
	add_child(_heading)
	var well := Well.new()
	well.name = "Well"
	add_child(well)
	var room := Control.new()
	room.custom_minimum_size = Vector2(0.0, rows_room * ROW + (rows_room - 1) * GAP)
	well.add_child(room)
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	room.add_child(_scroll)
	var items := VBoxContainer.new()
	items.name = "Items"
	items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items.add_theme_constant_override("separation", 8)
	_scroll.add_child(items)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items.add_child(list)
	link = _link(linked)
	var room_round := MarginContainer.new()
	room_round.name = "LinkRoom"
	room_round.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	room_round.add_theme_constant_override("margin_left", int(LINK_ROOM.x))
	room_round.add_theme_constant_override("margin_right", int(LINK_ROOM.x))
	room_round.add_theme_constant_override("margin_top", int(LINK_ROOM.y))
	room_round.add_theme_constant_override("margin_bottom", int(LINK_ROOM.y))
	room_round.add_child(link)
	items.add_child(room_round)


## The row the buttons under a box stand in, side by side and as wide as the box together, so they
## read as the box's own rather than as a column of their own.
static func button_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(WIDTH, 0.0)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return row


## A button saying [param text] in [param row], sharing its width with the others there.
static func add_row_button(row: HBoxContainer, text: String) -> Button:
	var button := MenuTheme.button(text, Type.BODY)
	button.custom_minimum_size = Vector2(0.0, MenuTheme.button_size().y)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(button)
	return button


## [param line], a line of words on a screen with a box on it, wrapping inside the box's width
## rather than setting the width itself: the screen's column is as wide as the box, and so is
## everything that fills it, the row of buttons and Back among them, whatever the words say.
static func fit(line: Label) -> Label:
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return line


## A link saying [param text]: underlined words in gold with nothing round them, a gold rim under
## the cursor, centered under the rows.
static func _link(text: String) -> LinkButton:
	var button := LinkButton.new()
	button.name = "Link"
	button.text = text
	button.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	Type.set_font(button, Type.STRONG, LINK_SIZE)
	button.add_theme_color_override("font_color", LINK_INK)
	button.add_theme_color_override("font_hover_color", LINK_HOVER)
	button.add_theme_color_override("font_focus_color", LINK_HOVER)
	button.add_theme_color_override("font_pressed_color", LINK_HOVER)
	var rim := StyleBoxFlat.new()
	rim.draw_center = false
	rim.border_color = LINK_INK
	rim.set_border_width_all(2)
	rim.set_corner_radius_all(4)
	rim.set_content_margin_all(4.0)
	rim.expand_margin_left = 8.0
	rim.expand_margin_right = 8.0
	rim.expand_margin_top = 2.0
	rim.expand_margin_bottom = 2.0
	button.add_theme_stylebox_override("focus", rim)
	button.pressed.connect(func() -> void: Audio.play_sfx(&"ui_click", MenuTheme.CLICK_DB, 0.0))
	return button


## What the box is headed, and what it says while it has nothing in it.
func set_heading(heading: String) -> void:
	_heading.text = heading.to_upper()


## Whether there are no rows under the link.
func is_empty() -> bool:
	for row: Node in list.get_children():
		if not row.is_queued_for_deletion():
			return false
	return true
