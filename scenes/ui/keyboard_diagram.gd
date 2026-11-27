class_name KeyboardDiagram
extends RefCounted
## The keyboard and the mouse drawn whole on the blueprint of GAME.md 8.3b, see [PadLeaflet], as
## [PadDiagram] draws a pad: a keyboard without its number pad, the US layout's shape, every key in
## outline with its name as the player's own keyboard prints it, see [member InputActions.label_of],
## the keys bound on the sheet lit, and a mouse beside it. Keys are bound by where they are, so one
## drawing serves every layout. The words for a lit key stand over the keyboard for one in its top
## three rows and under it for the rest, in the order of their keys, a line from each key straight
## out to a rail along the keyboard's edge and on to its words, so no two lines cross; a key that
## does two things says them one over the other. Drawn in the leaflet's design units, see
## [constant PadLeaflet.SIZE].

## How big a key is, the room between two, where the keyboard's top is, and how far its frame
## stands round the keys.
const U := 60.0
const GAP := 6.0
const TOP := 420.0
const FRAME := 18.0
## How wide the keyboard is and the room it and the mouse beside it take, in keys.
const KEYS_WIDE := 18.25
const ROWS_TALL := 6.5
const WITH_MOUSE := 21.55
## How far out the rail runs from the frame, and the words' lines from the rail; the words' size
## and the room between two lines of them and between two labels.
const RAIL := 22.0
const OUT := 64.0
const WORDS := 24
const LINE_TALL := 28.0
const APART := 16.0
## The left of the pairs both hands have, the one lit for a key bound by its kind: the right ones
## work the same, and lit too they only crowd the sheet.
const LEFT_ONLY: Array[Key] = [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]
const INK := BlueprintArt.INK
const FAINT := BlueprintArt.FAINT

## Each key: where it is and how wide, in keys, the engine's key at that place, and its name where
## it has one rather than a sign.
static var _keys: Array[Dictionary] = []


## What the sheet [param on_page] says at each key and mouse button, as the actions are bound now:
## the words of everything bound to it there, once each, by the key's place, see
## [constant KEY_NONE], or for a mouse button by its index negated. Only what a keyboard player
## needs, see [method PadSheets.entries].
static func said(on_page: int, simple: bool) -> Dictionary:
	var by_key := {}
	for each: Dictionary in PadSheets.entries(on_page, simple):
		if not each.get("keys", true):
			continue
		var actions: Array[StringName] = each["actions"]
		for action: StringName in actions:
			if not InputMap.has_action(action):
				continue
			for event: InputEvent in InputMap.action_get_events(action):
				var at := _place_of(event)
				if at == KEY_NONE:
					continue
				if not by_key.has(at):
					by_key[at] = [] as Array[String]
				var words: Array[String] = by_key[at]
				if not words.has(each["words"]):
					words.append(each["words"])
	return by_key


## What the key at [param at], or the mouse button, see [method said], is called, for a screen
## reader.
static func name_of(at: int) -> String:
	if at < 0:
		var buttons := [
			"",
			Lang.t("Left mouse button"),
			Lang.t("Right mouse button"),
			Lang.t("Middle mouse button")
		]
		return buttons[mini(-at, 3)]
	var event := InputEventKey.new()
	event.physical_keycode = at as Key
	return InputActions.event_text(event)


## Where [param event] is on the drawing: a key's place, a mouse button's index negated, or
## [constant KEY_NONE] for a pad's.
static func _place_of(event: InputEvent) -> int:
	var key := event as InputEventKey
	if key != null:
		return key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	var click := event as InputEventMouseButton
	if click != null:
		return -click.button_index
	return KEY_NONE


## The keyboard, the mouse and the words on [param on], for the sheet [param on_page].
static func draw(on: CanvasItem, on_page: int, simple: bool) -> void:
	_lay_out()
	var origin := Vector2((PadLeaflet.SIZE.x - WITH_MOUSE * U) * 0.5, TOP)
	var bound := said(on_page, simple)
	var frame := Rect2(
		origin - Vector2.ONE * FRAME,
		Vector2(KEYS_WIDE * U - GAP, ROWS_TALL * U - GAP) + Vector2.ONE * FRAME * 2.0
	)
	_round(on, frame, 18.0, Color(INK, 0.9), 2.0)
	_round(on, frame.grow(-6.0), 14.0, Color(INK, 0.3), 1.0)
	var lit: Array[Dictionary] = []
	var seen := {}
	for key: Dictionary in _keys:
		var rect := _rect(key, origin)
		var code: int = key["code"]
		var on_sheet := bound.has(code) and not (code in LEFT_ONLY and seen.has(code))
		if on_sheet:
			seen[code] = true
			lit.append({"rect": rect, "words": bound[code]})
		_draw_key(on, key, rect, on_sheet)
	_draw_mouse(on, origin, bound, on_page)
	for each: Dictionary in lit:
		var rect: Rect2 = each["rect"]
		var down := rect.position.y > origin.y + 3.0 * U
		if _blocked(each, lit, down) and not _blocked(each, lit, not down):
			down = not down
		each["down"] = down
	var labels := _share(lit)
	for down: bool in [false, true]:
		var row: Array[Dictionary] = []
		for label: Dictionary in labels:
			if label["down"] == down:
				row.append(label)
		row.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["x"] < b["x"])
		_spread(row)
		var rail := frame.end.y + RAIL if down else frame.position.y - RAIL
		for label: Dictionary in row:
			_label(on, label, rail, rail + OUT if down else rail - OUT, down)


## The keyboard's keys, the US layout's without its number pad, laid out the once. The keys go by
## their names, which are not translated, as no key's is.
static func _lay_out() -> void:
	if not _keys.is_empty():
		return
	_key(0, 0, 1, KEY_ESCAPE, "Esc")  # NO_TRANSLATE
	for i: int in 12:
		_key(2.0 + i + floorf(i / 4.0) * 0.5, 0, 1, (KEY_F1 + i) as Key, "F%d" % (i + 1))
	for i: int in 3:
		# NO_TRANSLATE
		_key(
			15.25 + i,
			0,
			1,
			[KEY_PRINT, KEY_SCROLLLOCK, KEY_PAUSE][i],
			["PrtSc", "ScrLk", "Pause"][i]
		)
	var digits: Array[Key] = [
		KEY_QUOTELEFT, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0
	]
	digits.append_array([KEY_MINUS, KEY_EQUAL])
	for i: int in digits.size():
		_key(i, 1.5, 1, digits[i])
	_key(13, 1.5, 2, KEY_BACKSPACE, "Backspace")  # NO_TRANSLATE
	for i: int in 3:
		# NO_TRANSLATE
		_key(15.25 + i, 1.5, 1, [KEY_INSERT, KEY_HOME, KEY_PAGEUP][i], ["Ins", "Home", "PgUp"][i])
	_key(0, 2.5, 1.5, KEY_TAB, "Tab")  # NO_TRANSLATE
	var top: Array[Key] = [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_T, KEY_Y, KEY_U, KEY_I, KEY_O, KEY_P]
	top.append_array([KEY_BRACKETLEFT, KEY_BRACKETRIGHT])
	for i: int in top.size():
		_key(1.5 + i, 2.5, 1, top[i])
	_key(13.5, 2.5, 1.5, KEY_BACKSLASH)
	for i: int in 3:
		# NO_TRANSLATE
		_key(15.25 + i, 2.5, 1, [KEY_DELETE, KEY_END, KEY_PAGEDOWN][i], ["Del", "End", "PgDn"][i])
	_key(0, 3.5, 1.75, KEY_CAPSLOCK, "Caps")  # NO_TRANSLATE
	var home: Array[Key] = [KEY_A, KEY_S, KEY_D, KEY_F, KEY_G, KEY_H, KEY_J, KEY_K, KEY_L]
	home.append_array([KEY_SEMICOLON, KEY_APOSTROPHE])
	for i: int in home.size():
		_key(1.75 + i, 3.5, 1, home[i])
	_key(12.75, 3.5, 2.25, KEY_ENTER, "Enter")  # NO_TRANSLATE
	_key(0, 4.5, 2.25, KEY_SHIFT, "Shift")  # NO_TRANSLATE
	var bottom: Array[Key] = [KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B, KEY_N, KEY_M]
	bottom.append_array([KEY_COMMA, KEY_PERIOD, KEY_SLASH])
	for i: int in bottom.size():
		_key(2.25 + i, 4.5, 1, bottom[i])
	_key(12.25, 4.5, 2.75, KEY_SHIFT, "Shift")  # NO_TRANSLATE
	_key(16.25, 4.5, 1, KEY_UP, "↑")
	# NO_TRANSLATE
	var mods: Array[Array] = [
		[KEY_CTRL, "Ctrl"],
		[KEY_META, "Super"],
		[KEY_ALT, "Alt"],
		[KEY_SPACE, ""],
		[KEY_ALT, "Alt"],
		[KEY_META, "Super"],
		[KEY_MENU, "Menu"],
		[KEY_CTRL, "Ctrl"],
	]
	var at := 0.0
	for mod: Array in mods:
		var wide := 6.25 if mod[0] == KEY_SPACE else 1.25
		_key(at, 5.5, wide, mod[0], mod[1])
		at += wide
	for i: int in 3:
		_key(15.25 + i, 5.5, 1, [KEY_LEFT, KEY_DOWN, KEY_RIGHT][i], ["←", "↓", "→"][i])


static func _key(x: float, y: float, wide: float, code: Key, name := "") -> void:
	_keys.append({"x": x, "y": y, "w": wide, "code": code, "name": name})


static func _rect(key: Dictionary, origin: Vector2) -> Rect2:
	return Rect2(origin + Vector2(key["x"], key["y"]) * U, Vector2(key["w"] * U - GAP, U - GAP))


## [param key] in outline over [param rect], its name in it, brighter [param lit]. A key a key wide
## has its name in its middle, smaller the longer it is, so F1 to F12 stand alike; a wider one has
## it at its top left, as a keyboard prints Tab or Shift.
static func _draw_key(on: CanvasItem, key: Dictionary, rect: Rect2, lit: bool) -> void:
	_round(on, rect, 6.0, Color(INK, 0.95 if lit else 0.4), 2.0 if lit else 1.2)
	if lit:
		on.draw_rect(rect.grow(-3.0), Color(INK, 0.08))
	var name: String = key["name"]
	if name.is_empty():
		var event := InputEventKey.new()
		event.physical_keycode = key["code"]
		name = InputActions.event_text(event)
	var font := Type.STRONG
	var ink := Color(INK, 0.95 if lit else 0.45)
	if key["w"] > 1.0:
		on.draw_string(
			font, rect.position + Vector2(10.0, 22.0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ink
		)
		return
	var size := 19 if name.length() <= 2 else (16 if name.length() == 3 else 13)
	var wide := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := rect.get_center() + Vector2(-wide * 0.5, size * 0.36)
	on.draw_string(font, at, name, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink)


## The mouse beside the keyboard, its buttons lit where something is bound to them, and on the
## driving sheet what it aims, the Swivel Cannon, GAME.md 7.1, its words beside it.
static func _draw_mouse(on: CanvasItem, origin: Vector2, bound: Dictionary, on_page: int) -> void:
	var body := Rect2(origin + Vector2((KEYS_WIDE + 1.0) * U, 1.2 * U), Vector2(2.3, 3.9) * U)
	_round(on, body, 60.0, Color(INK, 0.9), 2.0)
	var split := body.position.y + body.size.y * 0.4
	on.draw_line(
		Vector2(body.position.x + 8.0, split),
		Vector2(body.end.x - 8.0, split),
		Color(INK, 0.5),
		1.2
	)
	var middle := body.get_center().x
	on.draw_line(
		Vector2(middle, body.position.y + 6.0), Vector2(middle, split), Color(INK, 0.5), 1.2
	)
	var wheel := Rect2(Vector2(middle - 7.0, body.position.y + 28.0), Vector2(14.0, 34.0))
	_round(on, wheel, 7.0, Color(INK, 0.7), 1.4)
	var lines: Array[Array] = []
	var buttons := {
		MOUSE_BUTTON_LEFT: Vector2(middle - body.size.x * 0.25, body.position.y + 40.0),
		MOUSE_BUTTON_RIGHT: Vector2(middle + body.size.x * 0.25, body.position.y + 40.0),
		MOUSE_BUTTON_MIDDLE: wheel.get_center(),
	}
	for button: int in buttons:
		if bound.has(-button):
			lines.append([buttons[button], bound[-button], ""])
	if on_page == 0:
		lines.append(
			[
				body.get_center() + Vector2(0.0, 40.0),
				[Lang.t("Aim")] as Array[String],
				Lang.t("the Swivel Cannon")
			]
		)
	var x := body.end.x + 44.0
	var y := body.get_center().y - (lines.size() - 1) * 40.0
	for line: Array in lines:
		var from: Vector2 = line[0]
		on.draw_line(from, Vector2(x - 10.0, y - 8.0), INK, 1.6, true)
		_dot(on, from)
		var words: Array[String] = line[1]
		on.draw_string(
			Type.STRONG, Vector2(x, y), words[0], HORIZONTAL_ALIGNMENT_LEFT, -1, WORDS, INK
		)
		if not str(line[2]).is_empty():
			on.draw_string(
				Type.TEXT, Vector2(x, y + 24.0), line[2], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, FAINT
			)
		y += 80.0


## Whether a lit key's line [param down], or up, would run through another lit key.
static func _blocked(each: Dictionary, lit: Array[Dictionary], down: bool) -> bool:
	var rect: Rect2 = each["rect"]
	var x := rect.get_center().x
	for other: Dictionary in lit:
		if other == each:
			continue
		var o: Rect2 = other["rect"]
		if x < o.position.x or x > o.end.x:
			continue
		if (
			(down and o.position.y > rect.position.y)
			or (not down and o.position.y < rect.position.y)
		):
			return true
	return false


## The labels for [param lit]: one a key, but for neighbours on one row that do the same and go
## the same way, with no other lit key going that way between them, which share one.
static func _share(lit: Array[Dictionary]) -> Array[Dictionary]:
	var labels: Array[Dictionary] = []
	for each: Dictionary in lit:
		var rect: Rect2 = each["rect"]
		var shared := false
		for label: Dictionary in labels:
			var last: Rect2 = label["rects"][-1]
			if label["words"] != each["words"] or label["down"] != each["down"]:
				continue
			if absf(last.position.y - rect.position.y) >= 1.0:
				continue
			var low := minf(last.get_center().x, rect.get_center().x)
			var high := maxf(last.get_center().x, rect.get_center().x)
			if high - low > 2.6 * U or _between(lit, each, low, high):
				continue
			label["rects"].append(rect)
			shared = true
			break
		if not shared:
			labels.append({"words": each["words"], "down": each["down"], "rects": [rect]})
	for label: Dictionary in labels:
		var xs := 0.0
		for rect: Rect2 in label["rects"]:
			xs += rect.get_center().x
		label["x"] = xs / label["rects"].size()
		var wide := 0.0
		for words: String in label["words"]:
			wide = maxf(
				wide, Type.STRONG.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, WORDS).x
			)
		label["wide"] = wide + 18.0
	return labels


## Whether a lit key other than [param each]'s kind, going its way, stands between [param low] and
## [param high] across.
static func _between(lit: Array[Dictionary], each: Dictionary, low: float, high: float) -> bool:
	for other: Dictionary in lit:
		var x := (other["rect"] as Rect2).get_center().x
		if (
			other["down"] == each["down"]
			and other["words"] != each["words"]
			and x > low
			and x < high
		):
			return true
	return false


## [param row]'s labels each as near its keys as it can be, apart from the next, on the sheet.
static func _spread(row: Array[Dictionary]) -> void:
	for i: int in range(1, row.size()):
		var need: float = (row[i - 1]["wide"] + row[i]["wide"]) * 0.5 + APART
		row[i]["x"] = maxf(row[i]["x"], row[i - 1]["x"] + need)
	var last := row.size() - 1
	if last < 0:
		return
	row[last]["x"] = minf(row[last]["x"], PadLeaflet.SIZE.x - 120.0 - row[last]["wide"] * 0.5)
	for i: int in range(last - 1, -1, -1):
		var need: float = (row[i]["wide"] + row[i + 1]["wide"]) * 0.5 + APART
		row[i]["x"] = minf(row[i]["x"], row[i + 1]["x"] - need)


## A label's words, one over the other for a key that does two things, its line, and a line from
## each of its keys straight out to [param rail] along the keyboard's edge and on to the label's
## line at [param line_y], under the words [param down] and over them up.
static func _label(
	on: CanvasItem, label: Dictionary, rail: float, line_y: float, down: bool
) -> void:
	var middle: float = label["x"]
	var wide: float = label["wide"]
	var words: Array[String] = label["words"]
	for i: int in words.size():
		var line := words[i]
		var text_wide := Type.STRONG.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, WORDS).x
		var y := (
			line_y + 28.0 + i * LINE_TALL
			if down
			else line_y - 8.0 - (words.size() - 1 - i) * LINE_TALL
		)
		on.draw_string(
			Type.STRONG,
			Vector2(middle - text_wide * 0.5, y),
			line,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			WORDS,
			INK
		)
	on.draw_line(
		Vector2(middle - wide * 0.5, line_y), Vector2(middle + wide * 0.5, line_y), INK, 1.6
	)
	for rect: Rect2 in label["rects"]:
		var x := rect.get_center().x
		var from := Vector2(x, rect.end.y - 6.0) if down else Vector2(x, rect.position.y + 6.0)
		var turn := Vector2(x, rail)
		var to := Vector2(clampf(x, middle - wide * 0.5 + 8.0, middle + wide * 0.5 - 8.0), line_y)
		on.draw_line(from, turn, INK, 1.6, true)
		on.draw_line(turn, to, INK, 1.6, true)
		_dot(on, from)


## Where a line leaves a key: a white dot ringed in the sheet's blue, as the pad's have.
static func _dot(on: CanvasItem, at: Vector2) -> void:
	on.draw_circle(at, 5.5, BlueprintArt.BLUE)
	on.draw_circle(at, 3.8, INK)


static func _round(on: CanvasItem, rect: Rect2, radius: float, ink: Color, width: float) -> void:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = ink
	box.set_border_width_all(maxi(roundi(width), 1))
	box.set_corner_radius_all(roundi(radius))
	box.anti_aliasing = true
	on.draw_style_box(box, rect)
