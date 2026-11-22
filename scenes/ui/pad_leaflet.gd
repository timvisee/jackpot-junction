class_name PadLeaflet
extends Control
## The leaflet of the pad in the player's hands, GAME.md 8.3b: How to hold the wheel, a form of the
## Dept. of Karts with the whole pad drawn on it, see [PadDiagram], and a line from each of its
## buttons out to what it does as the player has it bound, the button's name under it as their pad
## prints it. Three pages, driving, the jokers and the menus, turned with the page keys or its tabs.
## Up over the settings' Controls page, 8.5, and the room's menu, 3.8; the pad drawn is the one the
## player touched last, a generic one if they have touched none.

signal put_away

const TITLE := "How to hold the wheel"
const ENTRY := "Show gamepad"
const PAGES: Array[String] = ["Driving", "Jokers", "Menus"]
## The card, in its own units, and what it asks of the screen with the air round it.
const SIZE := Vector2(1580.0, 960.0)
const ROOM := Vector2(1660.0, 1010.0)
## Where the pad is drawn on the card and how big; how far out from it the words stand, how far the
## lines run level before them, and how close two lines of words come down a side.
const ART_SCALE := 0.56
const ART_TOP := 295.0
const COLUMN_OUT := 70.0
const ELBOW := 40.0
const ROW_GAP := 84.0
const LINE_WIDTH := 1.6
const INK := HouseTheme.INK
const FAINT := HouseTheme.INK_FAINT
## What the card says of the pad drawn, by its family.
const FAMILY_WORDS: Dictionary[PadFamily.Family, String] = {
	PadFamily.Family.GENERIC: "Your controller",
	PadFamily.Family.XBOX: "Xbox controller",
	PadFamily.Family.PLAYSTATION: "PlayStation controller",
	PadFamily.Family.PLAYSTATION_4: "PlayStation 4 controller",
	PadFamily.Family.NINTENDO: "Nintendo controller",
	PadFamily.Family.STEAM_DECK: "Steam Deck",
}
## Which side of the pad each button's words stand: left, right, or over it for the middle ones.
const SIDES: Dictionary[StringName, int] = {
	&"lt": -1,
	&"lb": -1,
	&"ls": -1,
	&"dpad": -1,
	&"rt": 1,
	&"rb": 1,
	&"rs": 1,
	&"north": 1,
	&"east": 1,
	&"west": 1,
	&"south": 1,
	&"view": 0,
	&"menu": 0,
	&"touch": 0,
}
## The line from the left of the four under the thumb goes down round the bottom one first, in the
## drawing's pixels, rather than through the two right of it.
const AROUND: Dictionary[StringName, Vector2] = {&"west": Vector2(0.0, 150.0)}

var family := PadFamily.Family.GENERIC
## Whether the first player drives the simple way, GAME.md 4.2, where the stick says the way to go.
var simple := false
var page := 0
var diagram: PadDiagram

var _sheet: Control
var _tabs: Array[Button] = []
var _close: Button
var _from: Control
var _closing := false


## The button that puts the leaflet up over [param parent], for the pad touched last; shown wherever
## a pad may be in hand, which on a phone is only once one is plugged in, and not in the booth's
## demo, whose menu is kept to what a passer-by needs, GAME.md 9.8.
static func entry(parent: Node, size := Type.LARGE) -> Button:
	var button := MenuTheme.button(ENTRY, size)
	button.name = "PadLeafletButton"
	var pad_here := not TouchInput.enabled or not Input.get_connected_joypads().is_empty()
	button.visible = pad_here and not Demo.on
	button.pressed.connect(
		func() -> void:
			var simple_driving := Game.settings.drive_mode(0) == Settings.DRIVE_SIMPLE
			open(parent, PadFamily.shown(), simple_driving, button)
	)
	return button


## The Controller row of the settings' Controls page, 8.5, with the button in it: hidden where
## the button is.
static func row(parent: Node) -> HBoxContainer:
	var button := entry(parent, Type.BODY)
	var line := MenuTheme.row("Controller", button)
	line.visible = button.visible
	button.visible = true
	return line


## The leaflet up over [param parent] for a pad of [param for_family]; the cursor back on
## [param from] once it is put away.
static func open(
	parent: Node, for_family: PadFamily.Family, simple_driving := false, from: Control = null
) -> PadLeaflet:
	var leaflet := PadLeaflet.new()
	leaflet.name = "PadLeaflet"
	leaflet.family = for_family
	leaflet.simple = simple_driving
	leaflet._from = from
	parent.add_child(leaflet)
	return leaflet


## What each page names, in order: the actions, the words for them, and a note in red pen.
static func entries(on_page: int, simple_driving: bool) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	match on_page:
		0:
			list.append(_entry([InputActions.THROTTLE], "Gas", "squeeze, don't stab"))
			list.append(_entry([InputActions.BRAKE], "Brake"))
			if simple_driving:
				var ways: Array[StringName] = [
					InputActions.STEER_LEFT,
					InputActions.STEER_RIGHT,
					InputActions.DRIVE_UP,
					InputActions.DRIVE_DOWN,
				]
				list.append(_entry(ways, "Drive"))
			else:
				list.append(_entry([InputActions.STEER_LEFT, InputActions.STEER_RIGHT], "Steer"))
			list.append(_entry([InputActions.HANDBRAKE], "Drift"))
			list.append(_entry([InputActions.NITRO], "Nitro"))
			list.append(_entry([InputActions.FIRE], "Fire"))
			list.append(_entry([InputActions.USE_ITEM], "Use item"))
			list.append(_entry([InputActions.JOKER_MENU], "Joker hand"))
			var aim: Array[StringName] = [
				InputActions.AIM_LEFT,
				InputActions.AIM_RIGHT,
				InputActions.AIM_UP,
				InputActions.AIM_DOWN
			]
			list.append(_entry(aim, "Aim"))
			list.append(_entry([InputActions.PAUSE], "Pause"))
			list.append(_entry([InputActions.JOIN], "Join"))
			list.append(_entry([InputActions.EMOTE_WHEEL], "Emotes"))
		1:
			list.append(_entry([InputActions.STEER_LEFT, InputActions.STEER_RIGHT], "Cycle"))
			var flip: Array[StringName] = [InputActions.JOKER_PREV, InputActions.JOKER_NEXT]
			list.append(_entry(flip, "Previous / next joker", "flip through your hand"))
			list.append(_entry([InputActions.JOKER_DROP], "Drop"))
			list.append(_entry([InputActions.FIRE], "Take"))
			list.append(_entry([InputActions.JOKER_DESTROY], "Destroy or skip", "no take-backs"))
			list.append(_entry([InputActions.JOKER_MENU], "Open or close the hand"))
			list.append(_entry([InputActions.DETAILS], "Details"))
			list.append(_entry([InputActions.NITRO], "Reroll"))
		_:
			var moves: Array[StringName] = [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]
			list.append(_entry(moves, "Move"))
			list.append(_entry([&"ui_accept"], "Choose"))
			list.append(_entry([&"ui_cancel"], "Back", "always a way out"))
			list.append(_entry([InputActions.MENU_PAGE_PREV], "Previous page"))
			list.append(_entry([InputActions.MENU_PAGE_NEXT], "Next page"))
			list.append(_entry([InputActions.MENU_VIEW], "Change the view"))
			list.append(_entry([InputActions.MENU_OPTION], "Option"))
			list.append(_entry([InputActions.MENU_FILTER], "Filter"))
			list.append(_entry([InputActions.MENU_SORT], "Sort"))
			list.append(_entry([InputActions.MENU_HELP], "How it works"))
			list.append(_entry([InputActions.MENU_NEXT_NEW], "Next new"))
			list.append(_entry([InputActions.MATCH_SETTINGS], "Match settings"))
	return list


static func _entry(actions: Array[StringName], words: String, note := "") -> Dictionary:
	return {"actions": actions, "words": words, "note": note}


## What the page [param on_page] says at each button [param drawn] shows, as the actions are bound
## now: by button, the words of everything bound to it there, once each, and the first note.
static func labels(
	on_page: int, simple_driving: bool, drawn: PadDiagram
) -> Dictionary[StringName, Dictionary]:
	var said: Dictionary[StringName, Dictionary] = {}
	for each: Dictionary in entries(on_page, simple_driving):
		var actions: Array[StringName] = each["actions"]
		for action: StringName in actions:
			if not InputMap.has_action(action):
				continue
			for event: InputEvent in InputMap.action_get_events(action):
				var spot := PadDiagram.spot_of(event)
				if spot.is_empty() or not drawn.shows(spot):
					continue
				if not said.has(spot):
					said[spot] = {"words": [] as Array[String], "note": ""}
				var words: Array[String] = said[spot]["words"]
				if not words.has(each["words"]):
					words.append(each["words"])
				if said[spot]["note"] == "":
					said[spot]["note"] = each["note"]
	return said


## Several things one button does, as one line: "Pause · join".
static func joined(words: Array[String]) -> String:
	var parts: PackedStringArray = []
	for i: int in words.size():
		var one := words[i]
		parts.append(one if i == 0 else one.left(1).to_lower() + one.substr(1))
	return "  ·  ".join(parts)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	diagram = PadDiagram.of(family)
	var shade := MenuTheme.closer_shade(0.7)
	shade.gui_input.connect(_on_beside)
	add_child(shade)
	_sheet = Control.new()
	_sheet.name = "Sheet"
	_sheet.size = SIZE
	_sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	_sheet.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_sheet.draw.connect(_draw_sheet)
	add_child(_sheet)
	for i: int in PAGES.size():
		var tab := Button.new()
		tab.name = "Tab%d" % i
		tab.flat = true
		tab.text = PAGES[i].to_upper()
		Type.set_font(tab, Type.STRONG, 22)
		for state: StringName in [&"font_color", &"font_disabled_color"]:
			tab.add_theme_color_override(state, FAINT)
		for state: StringName in [&"font_hover_color", &"font_focus_color", &"font_pressed_color"]:
			tab.add_theme_color_override(state, INK)
		# Words on the paper rather than buttons on it, the cursor's tab boxed in ink.
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"hover_pressed"]:
			tab.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var boxed := StyleBoxFlat.new()
		boxed.draw_center = false
		boxed.border_color = Color(INK, 0.55)
		boxed.set_border_width_all(2)
		boxed.set_corner_radius_all(6)
		tab.add_theme_stylebox_override(&"focus", boxed)
		tab.size = Vector2(190.0, 44.0)
		tab.position = Vector2(SIZE.x * 0.5 + (i - 1) * 230.0 - 95.0, 200.0)
		tab.pressed.connect(_turn_to.bind(i))
		_sheet.add_child(tab)
		_tabs.append(tab)
	# The page keys beside the tabs, as the big dialogs have them, on their own dark chips.
	var keys := DialogBinds.pages(Game.last_input_keyboard, Palette.CHIP_WHITE, 17)
	keys.position = Vector2(SIZE.x * 0.5 + 360.0, 210.0)
	_sheet.add_child(keys)
	_close = Button.new()
	_close.name = "Close"
	_close.text = "Close"
	_close.theme_type_variation = HouseTheme.PAPER_BUTTON
	Type.set_font(_close, Type.STRONG, Type.BODY)
	_close.size = Vector2(220.0, 52.0)
	_close.position = Vector2(SIZE.x * 0.5 - 110.0, 872.0)
	_close.pressed.connect(close)
	ScreenReader.name(_close, "Close")
	_sheet.add_child(_close)
	_link_cursor()
	resized.connect(_fit)
	_fit()
	_turn_to(page, false)
	_tabs[page].grab_focus()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.12)


## The card as big as the screen lets it be, in the middle of it.
func _fit() -> void:
	var room := size if size != Vector2.ZERO else get_viewport_rect().size
	var scale := minf(room.x / ROOM.x, room.y / ROOM.y)
	_sheet.scale = Vector2.ONE * scale
	_sheet.position = ((room - SIZE * scale) * 0.5).round()


## The cursor kept on the leaflet: along its tabs, down to Close and back up.
func _link_cursor() -> void:
	for i: int in _tabs.size():
		var tab := _tabs[i]
		tab.focus_neighbor_left = tab.get_path_to(_tabs[posmod(i - 1, _tabs.size())])
		tab.focus_neighbor_right = tab.get_path_to(_tabs[posmod(i + 1, _tabs.size())])
		tab.focus_neighbor_top = tab.get_path_to(tab)
		tab.focus_neighbor_bottom = tab.get_path_to(_close)
	_close.focus_neighbor_left = _close.get_path_to(_close)
	_close.focus_neighbor_right = _close.get_path_to(_close)
	_close.focus_neighbor_bottom = _close.get_path_to(_close)


func _turn(by: int) -> void:
	_turn_to(posmod(page + by, PAGES.size()))


func _turn_to(to: int, sound := true) -> void:
	if sound and to != page:
		Audio.play_sfx(&"ui_move", MenuTheme.MOVE_DB, 0.0)
	page = to
	_close.focus_neighbor_top = _close.get_path_to(_tabs[page])
	for i: int in _tabs.size():
		var said := _said(i)
		ScreenReader.name(_tabs[i], ScreenReader.line([TITLE, "%s page" % PAGES[i]]), said)
	if _tabs[page].is_inside_tree() and get_viewport().gui_get_focus_owner() in _tabs:
		_tabs[page].grab_focus()
	_sheet.queue_redraw()


## What the page [param on_page] says, for a screen reader: each button's words and its name.
func _said(on_page: int) -> String:
	var parts: PackedStringArray = []
	var said := labels(on_page, simple, diagram)
	for spot: StringName in said:
		var words: Array[String] = said[spot]["words"]
		parts.append("%s: %s" % [joined(words), diagram.name_of(spot)])
	return ". ".join(parts)


## The page keys turn it, and Back, the pause button or a right click put it away, before anything
## under it hears them.
func _input(event: InputEvent) -> void:
	if _closing:
		return
	var click := event as InputEventMouseButton
	if event.is_action_pressed(InputActions.MENU_PAGE_PREV):
		_turn(-1)
	elif event.is_action_pressed(InputActions.MENU_PAGE_NEXT):
		_turn(1)
	elif event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(InputActions.PAUSE):
		MenuTheme.back_sound()
		close()
	elif click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		close()
	else:
		return
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	# Up over a screen, the screen under it hears nothing: no tab of the settings switches.
	if not _closing and (event is InputEventKey or event is InputEventJoypadButton):
		get_viewport().set_input_as_handled()


## A click or a tap beside the card puts it away.
func _on_beside(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (click != null and click.pressed) or (touch != null and touch.pressed):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	if _closing:
		return
	_closing = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	put_away.emit()
	if _from != null and is_instance_valid(_from) and _from.is_visible_in_tree():
		_from.grab_focus()
	queue_free()


## Where the pad's drawing is laid on the card, and how big.
func _art_rect() -> Rect2:
	var drawn := Vector2(diagram.art.get_size()) * ART_SCALE
	return Rect2(Vector2((SIZE.x - drawn.x) * 0.5, ART_TOP), drawn)


## Where on the card the button at [param spot] is, or the point the line from it goes round.
func _on_card(spot: StringName, around := false) -> Vector2:
	var art := _art_rect()
	var at: Vector2 = diagram.spots[spot]
	if around:
		at += AROUND.get(spot, Vector2.ZERO)
	return art.position + at * ART_SCALE


func _draw_sheet() -> void:
	_draw_card()
	_draw_heading()
	var art := _art_rect()
	_sheet.draw_texture_rect(diagram.art, art, false, Color(INK, 0.92))
	diagram.print_faces(_sheet, art.position, ART_SCALE, INK, Type.STRONG)
	var said := labels(page, simple, diagram)
	var sides: Array[Array] = [[], [], []]
	for spot: StringName in said:
		sides[SIDES.get(spot, 0) + 1].append(spot)
	_draw_column(sides[0], said, -1, art.position.x - COLUMN_OUT)
	_draw_column(sides[2], said, 1, art.end.x + COLUMN_OUT)
	_draw_over(sides[1], said)
	_draw_stamp()


## Cream stock in a double rule, torn from its pad down the left.
func _draw_card() -> void:
	var card := Rect2(Vector2.ZERO, SIZE)
	_sheet.draw_rect(card.grow(10.0).grow_individual(0.0, 0.0, 6.0, 10.0), Color(0, 0, 0, 0.35))
	_sheet.draw_rect(card, HouseTheme.PAPER)
	_sheet.draw_rect(card.grow(-18.0), Color(INK, 0.6), false, 1.5)
	_sheet.draw_rect(card.grow(-24.0), Color(INK, 0.35), false, 1.0)
	for i: int in 46:
		_sheet.draw_circle(Vector2(9.0, 14.0 + i * 20.6), 3.2, HouseTheme.STOCK)


func _draw_heading() -> void:
	var middle := SIZE.x * 0.5
	var form := "DEPT. OF KARTS   ·   FORM 8.3   ·   HANDLING THE CONTROLLER"
	_words(Type.micro_font(), form, Vector2(middle, 70.0), 15, FAINT, 0)
	_words(Type.display_font(), TITLE.to_upper(), Vector2(middle, 135.0), 58, INK, 0)
	var line := "%s   ·   as you have it bound" % FAMILY_WORDS[family]
	_words(Type.TEXT, line, Vector2(middle, 174.0), 20, FAINT, 0)
	var tab := _tabs[page]
	var under := tab.position + Vector2(tab.size.x * 0.5, tab.size.y - 4.0)
	_sheet.draw_line(under - Vector2(50.0, 0.0), under + Vector2(50.0, 0.0), INK, 3.0)


## The words down one side of the pad, [param side] of it at [param edge], each beside its button
## and moved apart only as far as they must be, and a line from each button out to its words.
func _draw_column(
	spots: Array, said: Dictionary[StringName, Dictionary], side: int, edge: float
) -> void:
	spots.sort_custom(
		func(a: StringName, b: StringName) -> bool: return _on_card(a, true).y < _on_card(b, true).y
	)
	var art := _art_rect()
	var heights: Array[float] = []
	for spot: StringName in spots:
		heights.append(_on_card(spot, true).y)
	_spread(heights, art.position.y + 10.0, art.end.y - 10.0)
	for i: int in spots.size():
		var spot: StringName = spots[i]
		var y := heights[i]
		var button := _on_card(spot)
		var elbow := Vector2(edge - side * ELBOW, y)
		var face := PadDiagram.FACES.has(spot)
		var first := _on_card(spot, true) if AROUND.has(spot) else elbow
		# A line to one of the four under the thumb starts at its rim, leaving what is on it clear.
		var from := button
		if face:
			from += (first - button).normalized() * (PadDiagram.FACE_RADIUS * ART_SCALE + 2.0)
		else:
			_sheet.draw_circle(button, 5.5, HouseTheme.PAPER)
			_sheet.draw_circle(button, 3.8, INK)
		if AROUND.has(spot):
			_sheet.draw_line(from, first, INK, LINE_WIDTH, true)
			from = first
		_sheet.draw_line(from, elbow, INK, LINE_WIDTH, true)
		_sheet.draw_line(elbow, Vector2(edge, y), INK, LINE_WIDTH, true)
		var words: Array[String] = said[spot]["words"]
		var x := edge + side * 12.0
		_words(Type.STRONG, joined(words), Vector2(x, y + 6.0), 28, INK, side)
		_words(Type.TEXT, diagram.name_of(spot), Vector2(x, y + 32.0), 17, FAINT, side)
		var note: String = said[spot]["note"]
		if not note.is_empty():
			var at := Vector2(x + side * 10.0, y - 26.0)
			_words(BayArt.hand_font(), note, at, 30, HouseTheme.STAMP_RED, side)


## [param heights] each as near the button it is for as it can be, at least a row apart, between
## [param top] and [param bottom]; spread evenly over that where they would not fit.
static func _spread(heights: Array[float], top: float, bottom: float) -> void:
	var count := heights.size()
	if count == 0:
		return
	for i: int in range(1, count):
		heights[i] = maxf(heights[i], heights[i - 1] + ROW_GAP)
	heights[count - 1] = minf(heights[count - 1], bottom)
	for i: int in range(count - 2, -1, -1):
		heights[i] = minf(heights[i], heights[i + 1] - ROW_GAP)
	if heights[0] < top:
		for i: int in count:
			heights[i] = top + i * (bottom - top) / maxf(count - 1, 1)


## The middle buttons' words over the pad: one in the middle, two either side of it.
func _draw_over(spots: Array, said: Dictionary[StringName, Dictionary]) -> void:
	spots.sort_custom(
		func(a: StringName, b: StringName) -> bool: return _on_card(a).x < _on_card(b).x
	)
	var y := ART_TOP - 10.0
	for i: int in spots.size():
		var spot: StringName = spots[i]
		var middle := SIZE.x * 0.5
		if spots.size() > 1:
			middle += (i - (spots.size() - 1) * 0.5) * 340.0
		var words: Array[String] = said[spot]["words"]
		var line := joined(words)
		var wide := Type.STRONG.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 20.0
		_words(Type.STRONG, line, Vector2(middle, y - 12.0), 26, INK, 0)
		var button := _on_card(spot)
		var end := Vector2(middle + clampf(button.x - middle, -wide * 0.5, wide * 0.5), y)
		_sheet.draw_line(Vector2(middle - wide * 0.5, y), Vector2(middle + wide * 0.5, y), INK, 1.6)
		_sheet.draw_line(button, end, INK, LINE_WIDTH, true)
		_sheet.draw_circle(button, 5.5, HouseTheme.PAPER)
		_sheet.draw_circle(button, 3.8, INK)


## The House's stamp in the corner: what is drawn is what the player has bound.
func _draw_stamp() -> void:
	_sheet.draw_set_transform(SIZE - Vector2(138.0, 62.0), -0.14, Vector2.ONE * 0.72)
	var red := Color(HouseTheme.STAMP_RED, 0.78)
	_sheet.draw_rect(Rect2(-120.0, -38.0, 240.0, 76.0), red, false, 4.0)
	_sheet.draw_rect(Rect2(-113.0, -31.0, 226.0, 62.0), red, false, 1.5)
	_words(Type.display_font(), "AS BOUND", Vector2(0.0, 16.0), 44, red, 0)
	_sheet.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## [param line] at [param at]: ending there for [param align] -1, centered on it for 0, and starting
## there for 1.
func _words(font: Font, line: String, at: Vector2, tall: int, ink: Color, align: int) -> void:
	var wide := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, tall).x
	var x := at.x
	if align == 0:
		x -= wide * 0.5
	elif align < 0:
		x -= wide
	_sheet.draw_string(font, Vector2(x, at.y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, tall, ink)
