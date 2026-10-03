class_name ListBox
extends VBoxContainer
## The box a list of servers or games is shown in, GAME.md 9.3 and 9.3a: a well sunk into the
## screen, darker than it with a shade along its inside top edge and a faint rim, under a small
## gray heading, with room for about five rows, which scrolls once there are more. It is there and
## as big empty as full, with a line in the middle of it saying why it is empty, so the list reads
## as the list and the buttons round it as buttons rather than one column running into the next.
## Sunk into the screen rather than raised off it: the game's pane, the gold-barred card of the
## questions and the pause menu, read as a dialog box come up over the screen, and this is part of
## it. Play Online's servers, LAN games' games and a server's games are each shown in one.
##
## At the very bottom of the well, under the rows or the line saying there are none, a link the way
## to put something on the list: Add a server, Host a game or Make a game, the same as the button
## for it under the box, but where the eye already is when it finds the list wanting.

## How wide the box is, and how tall its room for rows: five of the tallest, with the gaps.
const WIDTH := 760.0
const ROOM := 5 * 64.0 + 4 * 8.0
## The heading's ink, the well's fill over the screen, its shade and its rim, its corners, how far
## in from its edge the rows stand, and how deep the shade along its top is.
const HEADING_INK := Color(0.62, 0.62, 0.68)
const FILL := Color(0.0, 0.0, 0.0, 0.32)
const SHADE := Color(0.0, 0.0, 0.0, 0.3)
const RIM := Color(1.0, 1.0, 1.0, 0.09)
const RADIUS := 6
const INSET := 12
const SHADE_DEPTH := 7
## The link at the bottom: its ink, under the cursor or a pointer, and its size.
const LINK_INK := Palette.CHIP_GOLD
const LINK_HOVER := Color(1.0, 0.9, 0.62)
const LINK_SIZE := Type.BODY

## What is listed: a [ServerList] or a [GameList], or anything else with rows in it.
var list: Control
## The link at the bottom of the well, which puts something on the list.
var link: LinkButton

var _heading: Label
var _empty: Label
var _scroll: ScrollContainer


## The well itself: its fill, the shade along its inside top edge, and its rim, drawn under the
## rows it holds.
class Well:
	extends MarginContainer

	func _ready() -> void:
		for side: String in ["left", "right", "top", "bottom"]:
			add_theme_constant_override("margin_%s" % side, ListBox.INSET)

	func _draw() -> void:
		var whole := Rect2(Vector2.ZERO, size)
		var fill := StyleBoxFlat.new()
		fill.bg_color = ListBox.FILL
		fill.set_corner_radius_all(ListBox.RADIUS)
		draw_style_box(fill, whole)
		for i: int in ListBox.SHADE_DEPTH:
			var fade := 1.0 - float(i) / ListBox.SHADE_DEPTH
			var shade := Color(ListBox.SHADE, ListBox.SHADE.a * fade * fade)
			draw_rect(Rect2(ListBox.RADIUS * 0.5, 1.0 + i, size.x - ListBox.RADIUS, 1.0), shade)
		var rim := StyleBoxFlat.new()
		rim.draw_center = false
		rim.border_color = ListBox.RIM
		rim.set_border_width_all(1)
		rim.set_corner_radius_all(ListBox.RADIUS)
		draw_style_box(rim, whole)


## A box headed [param heading] holding [param rows], saying [param empty] while it has none, with
## [param linked] on the link at its bottom.
static func of(heading: String, rows: Control, empty: String, linked: String) -> ListBox:
	var box := ListBox.new()
	box.list = rows
	box._build(heading, empty, linked)
	return box


func _build(heading: String, empty: String, linked: String) -> void:
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
	var inside := VBoxContainer.new()
	inside.add_theme_constant_override("separation", 10)
	well.add_child(inside)
	var room := Control.new()
	room.custom_minimum_size = Vector2(0.0, ROOM)
	inside.add_child(room)
	link = _link(linked)
	inside.add_child(link)
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	room.add_child(_scroll)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(list)
	_empty = MenuTheme.subtitle(empty, Type.BODY)
	_empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	room.add_child(_empty)
	list.child_entered_tree.connect(func(_row: Node) -> void: _refresh.call_deferred())
	list.child_exiting_tree.connect(func(_row: Node) -> void: _refresh.call_deferred())
	_refresh()


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
## the cursor, centered at the bottom of the well.
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


func set_empty(empty: String) -> void:
	_empty.text = empty


## Whether there is nothing to show, which the line in the middle says.
func is_empty() -> bool:
	for row: Node in list.get_children():
		if not row.is_queued_for_deletion():
			return false
	return true


## The line in the middle while there are no rows, and the rows while there are.
func _refresh() -> void:
	if not is_instance_valid(_empty):
		return
	var nothing := is_empty()
	_empty.visible = nothing
	_scroll.visible = not nothing
