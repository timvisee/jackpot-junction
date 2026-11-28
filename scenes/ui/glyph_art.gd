class_name GlyphArt
extends RefCounted
## The picture of a bind glyph, see [InputGlyph], drawn the way Steam Input draws its own, GAME.md
## 8.3: the control itself as one solid shape, a key cap, a round face button, a bumper, a trigger,
## a stick seen from above with the way it is pushed beside it, the D-pad as a cross with the arm
## pressed marked on it, a mouse with its pressed button lit, and whatever is written on it in the
## shape's other color. Steam's own pictures, of what a pad has and the game does not draw, are
## given the same two colors, so a line of hints reads as one set.
##
## Made as an SVG and drawn into a picture the size it is on the screen, so a glyph is as sharp at
## 4K as at 720p. The letters are the font's own outlines, set in the middle of their own ink
## rather than of the line they would sit on: an L has all its weight on the left of its advance,
## and centered by its advance it sat right of the middle of its button.

## How a glyph is painted, chosen by where it stands, see [member InputGlyph.look]:
## [constant LIGHT] in the ink of its line with dark marks on it, the way Steam's light set is;
## [constant DARK] dark with the marks in the ink and a rim; and [constant OUTLINE] only drawn
## round, Steam's knockout set.
enum Look { LIGHT, DARK, OUTLINE }

## How tall every glyph is drawn, in the units its shapes are given in. Steam's are 32 too.
const TALL := 32.0
## The dark that marks are drawn in on a light glyph, the light they are drawn in on a glyph in a
## dark ink (the tap hand on a pale tab), and the edge round a glyph that keeps it apart from a
## pale floor.
const MARK := Color("#141318")
const PALE := Color("#f4f0e8")
const EDGE := Color(0.0, 0.0, 0.0, 0.5)
## How far the edge reaches out of the shape, in units, and how far in from the glyph's box every
## shape keeps, so the edge has room. Steam's own fill their box to its edge, and are set in by it.
const SPREAD := 1.4
const INSET := 1.5
## The arrow keys by their names, which the language spoken may translate, see
## [constant InputActions.KEY_WORDS]. NO_TRANSLATE: their English names, translated where shown.
const ARROW_KEYS: Dictionary[String, Vector2] = {
	"Up": Vector2.UP, "Down": Vector2.DOWN, "Left": Vector2.LEFT, "Right": Vector2.RIGHT
}
## How wide an outlined glyph's line is, in units, and the least it comes to on the screen, in
## pixels: at a Steam Deck's size the units alone are under a pixel, which smudges rather than
## draws.
const LINE := 1.4
const LINE_LEAST := 1.0
## How strongly a dark glyph's rim shows, and how far it reaches out: a touch of the House's foil
## rather than a frame round it.
const RIM_ALPHA := 0.5
const RIM_SPREAD := 1.1
## How strongly a dark glyph's rim shows in its player's color, which is there to be seen.
const SEAT_RIM_ALPHA := 0.85
## How tall a capital is set: alone on a button, two or three together, and a whole word.
const CAP_ONE := 13.5
const CAP_FEW := 12.0
const CAP_WORD := 11.5
## How much heavier than the house's strong cut the letters are set, toward Steam's own; and on an
## outlined glyph, whose line is thin, the cut as it is.
const EMBOLDEN := 0.35
const EMBOLDEN_OUTLINED := 0.0
## The font size the letters' outlines are taken at, big enough that its hinting is nothing.
const OUTLINE_SIZE := 128
## How many pictures are kept made before they are all let go.
const KEEP := 384
## The names of a pad's small buttons drawn as a picture rather than written, see [method icon].
const ICONS: Array[String] = ["Menu", "View", "+", "−", "-", "Home", "Capture"]  # NO_TRANSLATE
## Steam's colors, by what each is in its dark set: the body of a control, its marks, and the
## grays between, as how far from the body toward the marks each is.
const STEAM_BODY: Array[String] = ["#0e141b", "black", "#000000", "#000"]
const STEAM_MARK: Array[String] = ["white", "#ffffff", "#fff"]
const STEAM_GRAYS: Dictionary[String, float] = {
	"#67707b": 0.45,
	"#b8bcbf": 0.75,
	"#dcdedf": 0.85,
	"#3d4450": 0.2,
	"#8b929a": 0.55,
}
## Material Symbols' touch_app, see THIRD_PARTY.md: a hand with its finger on the glass and the
## ring of the tap round the fingertip, in a 960 box whose top is at -960.
# NO_TRANSLATE: an SVG path.
const TAP := (
	"M445-80q-29 0-56-12t-45-35L143-383q-7-9-7-20t8-19l4-4q14-15 34.5-18.5T221-438l99 53v-365"
	+ "q0-12.75 8.68-21.38 8.67-8.62 21.5-8.62 12.82 0 21.32 8.62 8.5 8.63 8.5 21.38v230h299.86"
	+ "Q730-520 765-485t35 85v170q0 63-43.5 106.5T650-80H445Zm26.3-570q-13.3 0-21.8-8.63-8.5-8.62"
	+ "-8.5-21.37 0-1.5 4-15 7-12 11-26t4-29.48Q460-796 427.88-828q-32.12-32-78-32T272-827.92"
	+ "q-32 32.09-32 77.92 0 15 4 29t11 26q2 3 3 6.5t1 8.5q0 12.75-8.58 21.37-8.58 8.63-21.84"
	+ " 8.63-8.58 0-15.58-4t-11.17-11.84Q191-685 185.5-706.25q-5.5-21.25-5.5-44.2 0-70.55"
	+ " 49.73-120.05Q279.45-920 350-920t120.27 49.5Q520-821 520-750.31q0 22.99-5.7 44.28-5.71"
	+ " 21.29-16.3 40.03-4 8-11.04 12-7.05 4-15.66 4Z"
)

static var _letters: Dictionary[String, Array] = {}
static var _types: Dictionary[float, Font] = {}
static var _cap := 0.0
static var _made: Dictionary[String, Texture2D] = {}


## One glyph's picture: its shapes in the order they are painted, how big it is in units, and
## Steam's own picture where it is one of those.
class Art:
	var wide := TALL
	var tall := TALL
	var parts: Array[Dictionary] = []
	var steam := ""

	## A shape [param d] painted in [param fill], a role ("body", "mark", "dim", "lit", "gap",
	## "lip", and "face" and "face_ink" for a face button, which no player's color changes) or a
	## color, and outlined in [param stroke] that wide. A solid one is part of the outline the
	## glyph's edge is drawn round.
	func add(
		d: String,
		fill: Variant,
		solid := true,
		stroke: Variant = null,
		width := 0.0,
		xf := "",
	) -> void:
		parts.append(
			{"d": d, "fill": fill, "solid": solid, "stroke": stroke, "width": width, "xf": xf}
		)

	## The last shape added painted only where the glyph is [param outlined], or only where it is
	## filled: a glyph whose filled pieces, outlined each, would cross one another is drawn round
	## as one, see [method mouse].
	func only(outlined: bool) -> void:
		parts[-1]["only"] = outlined

	## [param text] set [param cap] tall in the middle of [param middle], in [param fill]: its
	## outline is drawn when it is painted, in the weight the look sets, see [method svg].
	func letters(text: String, middle: Vector2, cap: float, fill: Variant, solid: bool) -> void:
		add("", fill, solid)
		parts[-1].merge({"text": text, "middle": middle, "cap": cap})


## The picture of [param art] painted for a line in [param ink] in [param look], [param px] pixels
## big, as an SVG; for one player's line, in their [param seat] color, see [method _seated].
static func svg(
	art: Art, ink: Color, px: Vector2i, look := Look.LIGHT, seat := Color(0, 0, 0, 0)
) -> String:
	var paint := _paint(ink, look)
	# A face button keeps its pad's colors whoever's line it is in: a PlayStation shape in its color
	# on a disc of the player's was all but lost.
	paint["face"] = paint["body"]
	paint["face_ink"] = paint["mark"]
	if seat.a > 0.0:
		_seated(paint, look, Color(seat, 1.0))
	paint["line"] = maxf(LINE, art.tall / maxf(px.y, 1.0) * LINE_LEAST)
	var weight := EMBOLDEN_OUTLINED if paint["outline"] else EMBOLDEN
	var parts: Array[Dictionary] = []
	for part: Dictionary in art.parts:
		if part.get("only", paint["outline"]) != paint["outline"]:
			continue
		parts.append(_set_letters(part, weight) if part.has("text") else part)
	var out := PackedStringArray()
	var head := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d"' % [px.x, px.y]
	# NO_TRANSLATE: the picture's SVG.
	head += ' viewBox="0 0 %s %s" preserveAspectRatio="none">' % [_n(art.wide), _n(art.tall)]
	out.append(head)
	var edge: Color = paint["edge"]
	if edge.a > 0.0:
		out.append('<g opacity="%s">' % _n(edge.a))  # NO_TRANSLATE
		var hex := _hex(edge)
		var spread := _n(float(paint["spread"]) * 2.0)
		var around := ' fill="%s" stroke="%s" stroke-width="%s"' % [hex, hex, spread]  # NO_TRANSLATE
		for part: Dictionary in parts:
			if part["solid"]:
				# NO_TRANSLATE: the picture's SVG.
				out.append(
					'<path d="%s"%s stroke-linejoin="round"%s/>' % [part["d"], around, _xf(part)]
				)
		if not art.steam.is_empty():
			out.append(_steam_edge(art, hex, spread))
		out.append("</g>")
	for part: Dictionary in parts:
		out.append(_path(part, paint))
	if not art.steam.is_empty():
		out.append(_steam_painted(art, paint))
	out.append("</svg>")  # NO_TRANSLATE
	return "\n".join(out)


## [param svg_text] drawn into a picture, made once and kept.
static func texture(svg_text: String) -> Texture2D:
	var known: Texture2D = _made.get(svg_text)
	if known != null:
		return known
	if _made.size() >= KEEP:
		_made.clear()
	var image := Image.new()
	if image.load_svg_from_string(svg_text) != OK or image.is_empty():
		return null
	var made := ImageTexture.create_from_image(image)
	_made[svg_text] = made
	return made


## The colors a glyph in [param ink] is painted in, for the [param look] it is drawn in.
static func _paint(ink: Color, look: Look) -> Dictionary:
	var plain := Color(ink, 1.0)
	var dark_ink := plain.get_luminance() < 0.4
	match look:
		Look.DARK:
			var body := PALE if dark_ink else Color(HouseTheme.STOCK, 1.0)
			var rim := HouseTheme.FOIL if ink.s < 0.25 else plain
			return {
				"body": body,
				"mark": plain,
				"dim": body.lerp(plain, 0.3),
				"lit": plain,
				"gap": body,
				"lip": body.lerp(plain, 0.16),
				"face_mark": MARK,
				"edge": Color(rim, RIM_ALPHA),
				"spread": RIM_SPREAD,
				"outline": false,
			}
		Look.OUTLINE:
			return {
				"body": plain,
				"mark": plain,
				"dim": Color(plain, 0.45),
				"lit": plain,
				"gap": null,
				"lip": null,
				"face_mark": MARK,
				"edge": Color(0.0, 0.0, 0.0, 0.3),
				"spread": 0.6,
				"outline": true,
			}
	var mark := PALE if dark_ink else MARK
	return {
		"body": plain,
		"mark": mark,
		"dim": plain.lerp(mark, 0.5),
		"lit": plain,
		"gap": mark,
		"lip": plain.darkened(0.3),
		"face_mark": MARK,
		"edge": EDGE,
		"spread": SPREAD,
		"outline": false,
	}


## [param paint] made one player's, in their [param seat] color: a light glyph is drawn in it, its
## marks dark or pale on it as they read best, and a dark one, the joker hand's button standing on
## its own, wears it as its rim.
static func _seated(paint: Dictionary, look: Look, seat: Color) -> void:
	if look == Look.DARK:
		paint["edge"] = Color(seat, SEAT_RIM_ALPHA)
		return
	paint["body"] = seat
	paint["lit"] = seat
	if look == Look.LIGHT:
		var mark := PALE if seat.get_luminance() < 0.4 else MARK
		paint["mark"] = mark
		paint["gap"] = mark
		paint["dim"] = seat.lerp(mark, 0.5)
		paint["lip"] = seat.darkened(0.3)


static func _path(part: Dictionary, paint: Dictionary) -> String:
	var fill: Variant = part["fill"]
	var stroke: Variant = part["stroke"]
	var width: float = part["width"]
	if paint["outline"] and fill is String and fill in ["body", "face", "dim", "lip"]:
		if fill == "lip":
			return ""
		stroke = fill
		width = paint["line"]
		fill = null
	if width < 0.0:
		width = paint["line"]
	var attrs := ""
	var fill_tone: Variant = _tone(fill, paint)
	if fill_tone is Color:
		attrs += ' fill="%s"' % _hex(fill_tone)  # NO_TRANSLATE
		if (fill_tone as Color).a < 1.0:
			attrs += ' fill-opacity="%s"' % _n((fill_tone as Color).a)  # NO_TRANSLATE
	else:
		attrs += ' fill="none"'  # NO_TRANSLATE
	var stroke_tone: Variant = _tone(stroke, paint)
	if stroke_tone is Color and width > 0.0:
		attrs += ' stroke="%s" stroke-width="%s"' % [_hex(stroke_tone), _n(width)]  # NO_TRANSLATE
		attrs += ' stroke-linejoin="round" stroke-linecap="round"'  # NO_TRANSLATE
		if (stroke_tone as Color).a < 1.0:
			attrs += ' stroke-opacity="%s"' % _n((stroke_tone as Color).a)  # NO_TRANSLATE
	return '<path d="%s"%s%s/>' % [part["d"], attrs, _xf(part)]  # NO_TRANSLATE


static func _tone(role: Variant, paint: Dictionary) -> Variant:
	if role is Color:
		return role
	if role is String or role is StringName:
		return paint.get(role)
	return null


static func _xf(part: Dictionary) -> String:
	var xf: String = part["xf"]
	return "" if xf.is_empty() else ' transform="%s"' % xf  # NO_TRANSLATE


static func _n(value: float) -> String:
	return String.num(value, 2)


static func _hex(color: Color) -> String:
	return "#" + color.to_html(false)


## A face button: the round one under the thumb with [param letter] on it, or a PlayStation pad's
## shape for the engine's button [param shape], the disc in [param disc] and the mark in
## [param ink], each a role or a color.
static func face(
	letter: String, shape: int, disc: Variant = "face", ink: Variant = "face_ink"
) -> Art:
	var art := Art.new()
	art.add(_circle(Vector2(16.0, 16.0), 14.5), disc)
	if shape != JOY_BUTTON_INVALID:
		_ps_shape(art, shape, ink)
	elif not letter.is_empty():
		_letter(art, letter, Vector2(16.0, 16.0), CAP_ONE, ink)
	return art


## A PlayStation pad's four shapes, as lines the weight of the letters on the other pads.
static func _ps_shape(art: Art, shape: int, ink: Variant) -> void:
	var thick := 2.7
	match shape:
		JOY_BUTTON_A:
			art.add("M10.6 10.6L21.4 21.4M10.6 21.4L21.4 10.6", null, false, ink, thick)
		JOY_BUTTON_B:
			art.add(_circle(Vector2(16.0, 16.0), 6.4), null, false, ink, thick)
		JOY_BUTTON_X:
			art.add(_box(Rect2(10.2, 10.2, 11.6, 11.6), 0.6), null, false, ink, thick)
		JOY_BUTTON_Y:
			art.add("M16 9.2L22.9 21.1H9.1Z", null, false, ink, thick)


## A key on a keyboard: its cap, with a lip along its foot the way a key stands on the board, and
## the key written on it, or an arrow drawn on it for an arrow key.
static func key(text: String) -> Art:
	var art := Art.new()
	var way := arrow_of(text)
	var cap := _cap_for(text)
	var run := 10.0 if way != Vector2.ZERO else words_wide(text, cap)
	art.wide = maxf(TALL, run + 18.0)
	var all := Rect2(INSET, INSET, art.wide - INSET * 2.0, TALL - INSET * 2.0)
	art.add(_box(all, 5.0), "lip")
	var top := Rect2(all.position, Vector2(all.size.x, all.size.y - 4.0))
	art.add(_box(top, 5.0), "body")
	var middle := top.get_center()
	if way != Vector2.ZERO:
		art.add(_head(middle, way, 11.0, 7.6), "mark", false)
	elif not text.is_empty():
		_letter(art, text, middle, cap, "mark")
	return art


## Which way an arrow key points, from its name, in English or as the language spoken names it, see
## [constant InputActions.KEY_WORDS], or the arrow written on it; or none.
static func arrow_of(text: String) -> Vector2:
	match text:
		"Up", "↑":  # NO_TRANSLATE
			return Vector2.UP
		"Down", "↓":  # NO_TRANSLATE
			return Vector2.DOWN
		"Left", "←":  # NO_TRANSLATE
			return Vector2.LEFT
		"Right", "→":  # NO_TRANSLATE
			return Vector2.RIGHT
	for way: String in ARROW_KEYS:
		if text == Lang.t(way):
			return ARROW_KEYS[way]
	return Vector2.ZERO


## A pill with [param text] on it: a word on a pad, Steam's name for a button, a touch button.
static func pill(text: String) -> Art:
	var art := Art.new()
	var cap := _cap_for(text)
	art.wide = maxf(TALL, words_wide(text, cap) + 17.0)
	art.add(_box(Rect2(INSET, 3.0, art.wide - INSET * 2.0, 26.0), 13.0), "body")
	_letter(art, text, Vector2(art.wide * 0.5, 16.0), cap, "mark")
	return art


## A shoulder button, on the [param side] of the pad it is (-1 the left): low and wide, rounded off
## into the pad's top corner on the outside and round on the inside, the way Steam draws them.
static func bumper(text: String, side: int) -> Art:
	var art := Art.new()
	var cap := minf(_cap_for(text), CAP_FEW)
	art.wide = maxf(34.0, words_wide(text, cap) + 18.0)
	var left := INSET
	var right := art.wide - INSET
	var top := 4.5
	var foot := 27.5
	var round := (foot - top) * 0.5
	var d := (
		_d(["M", Vector2(left + 4.0, foot), "L", Vector2(right - round, foot)])
		+ _d(["A", round, round, 0, 0, 0, Vector2(right - round, top)])
		+ _d(["L", Vector2(left + 13.0, top)])
		+ _d(["C", Vector2(left + 5.5, top), Vector2(left, top + 5.5), Vector2(left, top + 13.0)])
		+ _d(["L", Vector2(left, foot - 4.0), "Q", Vector2(left, foot), Vector2(left + 4.0, foot)])
		+ "Z"
	)
	art.add(d, "body", true, null, 0.0, _mirror(art, side))
	_letter(art, text, Vector2(art.wide * 0.5 - 0.5 * side, 16.6), cap, "mark")
	return art


## A trigger, on the [param side] of the pad it is: tall, flat across its top, round at its outer
## foot and hollowed along its inner edge the way a finger curls round it.
static func trigger(text: String, side: int) -> Art:
	var art := Art.new()
	var cap := minf(_cap_for(text), CAP_FEW)
	art.wide = maxf(30.0, words_wide(text, cap) + 17.0)
	var left := 2.0
	var right := art.wide - INSET
	var top := INSET
	var foot := TALL - INSET
	var d := (
		_d(["M", Vector2(left + 3.5, top), "L", Vector2(right - 3.0, top)])
		+ _d(["Q", Vector2(right, top), Vector2(right, top + 3.0), "L", Vector2(right, top + 10.0)])
		+ _d(["C", Vector2(right, foot - 4.0), Vector2(right - 7.0, foot)])
		+ _d([Vector2(right - 13.0, foot), "L", Vector2(left + 4.0, foot)])
		+ _d(["Q", Vector2(left + 0.4, foot), Vector2(left + 1.0, foot - 3.6)])
		+ _d(["C", Vector2(left + 5.2, foot - 11.0), Vector2(left + 5.2, top + 11.0)])
		+ _d([Vector2(left + 1.0, top + 3.6), "Q", Vector2(left + 0.4, top)])
		+ _d([Vector2(left + 3.5, top), "Z"])
	)
	art.add(d, "body", true, null, 0.0, _mirror(art, side))
	var middle := (left + 4.0 + right) * 0.5
	if side > 0:
		middle = art.wide - middle
	_letter(art, text, Vector2(middle, 14.0), cap, "mark")
	return art


## A stick pressed in, seen from the side: its head and its shaft, with what it is written on it
## and a head above it pointing down onto it.
static func click(text: String) -> Art:
	var art := Art.new()
	var cap := 9.5
	art.wide = maxf(TALL, words_wide(text, cap) + 15.0)
	var middle := art.wide * 0.5
	art.add(_head(Vector2(middle, 4.4), Vector2.DOWN, 10.4, 5.8), "body")
	# The stick's head, round at its ends, and its shaft under it as one shape: as two, an outlined
	# glyph's lines crossed each other and the words on it.
	var left := INSET
	var right := art.wide - INSET
	var top := 9.5
	var rim := 19.5
	var round := (rim - top) * 0.5
	var shaft := Vector2(art.wide * 0.21, art.wide * 0.79)
	var foot := TALL - INSET
	var corner := 2.5
	var d := (
		_d(["M", Vector2(left + round, top), "L", Vector2(right - round, top)])
		+ _d(["Q", Vector2(right, top), Vector2(right, top + round)])
		+ _d(["Q", Vector2(right, rim), Vector2(right - round, rim)])
		+ _d(["L", Vector2(shaft.y, rim), "L", Vector2(shaft.y, foot - corner)])
		+ _d(["Q", Vector2(shaft.y, foot), Vector2(shaft.y - corner, foot)])
		+ _d(["L", Vector2(shaft.x + corner, foot), "Q", Vector2(shaft.x, foot)])
		+ _d([Vector2(shaft.x, foot - corner), "L", Vector2(shaft.x, rim)])
		+ _d(["L", Vector2(left + round, rim), "Q", Vector2(left, rim), Vector2(left, rim - round)])
		+ _d(["Q", Vector2(left, top), Vector2(left + round, top), "Z"])
	)
	art.add(d, "body")
	_letter(art, text, Vector2(middle, 21.4), cap, "mark")
	return art


## A stick seen from above, with [param letter] in its ring and a head beside it each way in
## [param ways]: square when it is pushed every way, else [param wide] times as wide as tall.
static func stick(letter: String, ways: Array[Vector2], wide: float, square: bool) -> Art:
	var art := Art.new()
	art.wide = TALL * wide
	art.tall = art.wide if square else TALL
	var middle := Vector2(art.wide, art.tall) * 0.5
	var reach := 13.25
	var upright := not square and ways.any(func(way: Vector2) -> bool: return way.y != 0.0)
	if upright:
		# Pushed up or down in a glyph only one tall: a smaller stick, out of the way of its head.
		reach = 8.2 if ways.size() > 1 else 10.4
		if ways.size() == 1:
			middle.y -= ways[0].y * 4.2
	var gap := 1.8 if upright else 2.3
	var deep := 4.4 if upright and ways.size() > 1 else 6.2
	for way: Vector2 in ways:
		var base := middle + way * (reach + gap)
		art.add(_head(base + way * deep * 0.5, way, deep * 1.75, deep), "body")
	art.add(_circle(middle, reach), "body")
	art.add(_circle(middle, reach * 0.72), null, false, "mark", maxf(reach * 0.15, 1.4))
	if not letter.is_empty():
		_letter(art, letter, middle, reach * 0.66, "mark")
	return art


## The D-pad as its cross, a head marked on each arm in [param ways].
static func dpad(ways: Array[Vector2]) -> Art:
	var art := Art.new()
	var near := 16.0 - 5.25
	var far := 16.0 + 5.25
	var low := INSET
	var high := TALL - INSET
	var corners := PackedVector2Array(
		[
			Vector2(near, low),
			Vector2(far, low),
			Vector2(far, near),
			Vector2(high, near),
			Vector2(high, far),
			Vector2(far, far),
			Vector2(far, high),
			Vector2(near, high),
			Vector2(near, far),
			Vector2(low, far),
			Vector2(low, near),
			Vector2(near, near),
		]
	)
	var rounds := PackedFloat32Array([2.0, 2.0, 1.0, 2.0, 2.0, 1.0, 2.0, 2.0, 1.0, 2.0, 2.0, 1.0])
	art.add(_rounded_polygon(corners, rounds), "body")
	for way: Vector2 in ways:
		art.add(_head(Vector2(16.0, 16.0) + way * 10.3, way, 7.8, 4.6), "mark", false)
	return art


## A mouse seen from above: its two buttons over its body, split by a groove with the wheel in it,
## [param button] lit and the rest dimmed, and [param mark] beside it for a double click. Every
## part of it follows the one line round it, round at its top and its foot, so nothing it is
## painted in shows past another at its edge.
static func mouse(button: MouseButton, mark: String, wide: float) -> Art:
	var art := Art.new()
	var span := TALL * wide - INSET * 2.0
	var round := span * 0.5
	var left := INSET
	var right := left + span
	var middle := left + round
	var crown := INSET + round
	var heel := TALL - INSET - round
	var split := 14.4
	var groove := 1.5
	var wheel := Rect2(middle - 2.3, 4.4, 4.6, 7.6)
	var arc := ["A", round, round, 0, 0, 1]
	var body := (
		_d(["M", Vector2(left, crown)] + arc + [Vector2(right, crown), "L", Vector2(right, heel)])
		+ _d(arc + [Vector2(left, heel), "Z"])
	)
	# NO_TRANSLATE: the picture's SVG.
	var turn := "" if button != MOUSE_BUTTON_RIGHT else "matrix(-1 0 0 1 %s 0)" % _n(middle * 2.0)
	var pressed := button in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
	var lit_wheel := "lit" if button == MOUSE_BUTTON_MIDDLE else "dim"
	# Filled: the mouse in the dim tone, the button pressed lit on it to its edge, and the groove cut
	# in over both in the gap's tone with the wheel in it.
	art.add(body, "dim")
	art.only(false)
	if pressed:
		art.add(_pressed(left, round, split, wheel, 0.0), "lit", false, null, 0.0, turn)
		art.only(false)
	art.add(_grooves(left, right, split, wheel, groove * 0.5), null, false, "gap", groove)
	art.only(false)
	art.add(_box(wheel, 2.3), lit_wheel, false, "gap", 1.3)
	art.only(false)
	# Outlined: one line round it with its groove drawn in, stopping at the wheel, and the button
	# pressed filled short of the groove: its pieces each drawn round crossed one another.
	art.add(body, "body")
	art.only(true)
	if pressed:
		art.add(_pressed(left, round, split, wheel, groove), "lit", false, null, 0.0, turn)
		art.only(true)
	art.add(_grooves(left, right, split, wheel, LINE * 0.5), null, false, "body", -1.0)
	art.only(true)
	var wheel_fill: Variant = "lit" if button == MOUSE_BUTTON_MIDDLE else null
	art.add(_box(wheel, 2.3), wheel_fill, false, "body", -1.0)
	art.only(true)
	art.wide = TALL * wide
	if not mark.is_empty():
		var run := words_wide(mark, CAP_FEW)
		_letter(art, mark, Vector2(art.wide + 2.0 + run * 0.5, 16.0), CAP_FEW, "lit", true)
		art.wide += run + 4.0
	return art


## A mouse's groove: across under its buttons at [param split] from side to side, and up between
## them from there to the wheel and on above it, each end [param end] short of the line round the
## mouse, so the round end of a line that wide meets that line rather than poking past it.
static func _grooves(left: float, right: float, split: float, wheel: Rect2, end: float) -> String:
	var middle := (left + right) * 0.5
	return (
		_d(["M", Vector2(left + end, split), "L", Vector2(right - end, split)])
		+ _d(["M", Vector2(middle, INSET + end), "L", Vector2(middle, wheel.position.y)])
		+ _d(["M", Vector2(middle, wheel.end.y), "L", Vector2(middle, split)])
	)


## A mouse's left button pressed, filled: from the line round the mouse, along it, to
## [param clear] short of the groove and round the wheel, so an outlined mouse's groove and wheel
## stay drawn; none for a filled one, whose groove and wheel are drawn over it. [param left] is the
## mouse's side, its top [param round] round, [param split] the groove under the buttons. Mirrored
## for the right.
static func _pressed(left: float, round: float, split: float, wheel: Rect2, clear: float) -> String:
	var middle := left + round
	var inner := middle - clear
	var crown := INSET + round
	var foot := split - clear
	# The line round the mouse's top is an arc round its middle: up it to where it is [param clear]
	# from the groove, then down beside the groove and round the wheel.
	var reach := Vector2(inner, crown - sqrt(round * round - clear * clear))
	var ring := wheel.size.x * 0.5 + clear
	var top := wheel.position.y + wheel.size.x * 0.5
	var low := wheel.end.y - wheel.size.x * 0.5
	var into := sqrt(ring * ring - clear * clear)
	var path := _d(["M", Vector2(left, foot), "L", Vector2(left, crown)])
	path += _d(["A", round, round, 0, 0, 1, reach, "L", Vector2(inner, top - into)])
	path += _d(
		["A", ring, ring, 0, 0, 0, Vector2(middle - ring, top), "L", Vector2(middle - ring, low)]
	)
	# Round the wheel's foot back to the groove, or cut off where the groove under the buttons
	# comes first.
	if low + into <= foot:
		path += _d(
			["A", ring, ring, 0, 0, 0, Vector2(inner, low + into), "L", Vector2(inner, foot)]
		)
	else:
		var under := foot - low
		path += _d(
			["A", ring, ring, 0, 0, 0, Vector2(middle - sqrt(ring * ring - under * under), foot)]
		)
	return path + "Z"


## One of a pad's small buttons that carry a picture rather than a word, on a round button: the
## three bars of Menu, the two windows of View, Nintendo's plus and minus, a house for Home and
## the framed dot of Capture. Null for a name it has no picture of, see [constant ICONS].
static func icon(name: String) -> Art:
	if name not in ICONS:
		return null
	var art := Art.new()
	var middle := Vector2(16.0, 16.0)
	art.add(_circle(middle, 13.0), "body")
	match name:
		"Menu":
			for row: int in 3:
				art.add(_box(Rect2(10.0, 10.9 + row * 4.0, 12.0, 2.2), 1.1), "mark", false)
		"View":
			# The window behind only where the one in front leaves it, so no line crosses another
			# where the glyph is only drawn round.
			var behind := (
				_d(["M", Vector2(13.6, 16.8), "L", Vector2(11.0, 16.8), "Q", Vector2(9.8, 16.8)])
				+ _d([Vector2(9.8, 15.6), "L", Vector2(9.8, 11.0), "Q", Vector2(9.8, 9.8)])
				+ _d([Vector2(11.0, 9.8), "L", Vector2(17.2, 9.8), "Q", Vector2(18.4, 9.8)])
				+ _d([Vector2(18.4, 11.0), "L", Vector2(18.4, 15.2)])
			)
			art.add(behind, null, false, "mark", 1.9)
			art.add(_box(Rect2(13.6, 15.2, 8.6, 7.0), 1.2), null, false, "mark", 1.9)
		"+":
			art.add(_box(Rect2(9.6, 14.7, 12.8, 2.6), 0.8), "mark", false)
			art.add(_box(Rect2(14.7, 9.6, 2.6, 12.8), 0.8), "mark", false)
		"−", "-":
			art.add(_box(Rect2(9.6, 14.7, 12.8, 2.6), 0.8), "mark", false)
		"Home":
			# The door a notch in the house, not a patch of the button over it, which drawn round
			# stood out under it.
			art.add("M16 8.6L23.6 15.4H21.4V22.6H17.5V17.6H14.5V22.6H10.6V15.4H8.4Z", "mark", false)
		"Capture":
			art.add(_box(Rect2(10.0, 10.0, 12.0, 12.0), 2.0), null, false, "mark", 2.0)
			art.add(_circle(middle, 2.8), "mark", false)
	return art


## A tap on a touch screen: a hand with its finger on the glass, see [constant TAP], in the ink
## of its line whatever the look, being a picture of a hand rather than of a button.
static func finger(wide: float) -> Art:
	var art := Art.new()
	art.wide = TALL * wide
	var scale := TALL / 960.0
	# The hand's ink runs from 136 to 800 of the 960 across: set in the middle of the glyph.
	var across := art.wide * 0.5 - 468.0 * scale
	# NO_TRANSLATE: the picture's SVG.
	art.add(TAP, "lit", true, null, 0.0, "translate(%s 32) scale(%s)" % [_n(across), _n(scale)])
	return art


## A touch screen's steering wheel, on a round button: its rim with a band at the top, a hub and
## three spokes.
static func wheel() -> Art:
	var art := Art.new()
	var middle := Vector2(16.0, 16.0)
	art.add(_circle(middle, 14.5), "body")
	art.add(_circle(middle, 8.6), null, false, "mark", 2.6)
	art.add(_circle(middle, 2.6), "mark", false)
	art.add("M8.6 16H13.4M18.6 16H23.4M16 18.6V24.6", null, false, "mark", 2.4)
	art.add("M13.2 7.8A8.6 8.6 0 0 1 18.8 7.8", null, false, "mark", 4.4)
	return art


## Steam's own picture, [param source] being its SVG, painted in the glyph's two colors.
static func steam(source: String) -> Art:
	var art := Art.new()
	art.steam = source
	var view := _view_of(source)
	if view.size.y > 0.0:
		art.wide = (TALL - INSET * 2.0) * view.size.x / view.size.y + INSET * 2.0
	return art


static func _view_of(source: String) -> Rect2:
	var found := RegEx.create_from_string('viewBox="([^"]*)"').search(source)
	if found == null:
		return Rect2(0.0, 0.0, TALL, TALL)
	var numbers := found.get_string(1).split_floats(" ", false)
	if numbers.size() < 4:
		return Rect2(0.0, 0.0, TALL, TALL)
	return Rect2(numbers[0], numbers[1], numbers[2], numbers[3])


## Steam's picture without its own <svg> round it, set into the glyph's box inside its edge.
static func _steam_inside(art: Art, body: String) -> String:
	var view := _view_of(art.steam)
	var scale := (art.tall - INSET * 2.0) / maxf(view.size.y, 1.0)
	var into := "translate(%s %s) scale(%s)" % [_n(INSET), _n(INSET), _n(scale)]  # NO_TRANSLATE
	into += " translate(%s %s)" % [_n(-view.position.x), _n(-view.position.y)]  # NO_TRANSLATE
	return '<g transform="%s">%s</g>' % [into, body]  # NO_TRANSLATE


static func _steam_body(source: String) -> String:
	var open := source.find(">", source.find("<svg"))
	var close := source.rfind("</svg>")
	if open < 0 or close < open:
		return ""
	return source.substr(open + 1, close - open - 1)


## Steam's picture with each of its colors swapped for the glyph's own: its black for the body,
## its white for the marks and its grays between the two. A color of a button's own stays.
static func _steam_painted(art: Art, paint: Dictionary) -> String:
	var body := _steam_body(art.steam)
	var swap := RegEx.create_from_string('(fill|stroke)="([^"]*)"')
	var out := ""
	var at := 0
	for found: RegExMatch in swap.search_all(body):
		out += body.substr(at, found.get_start() - at)
		var was := found.get_string(2).to_lower()
		var now := found.get_string(2)
		var tone: Variant = null
		if was in STEAM_BODY:
			tone = paint["body"]
		elif was in STEAM_MARK:
			tone = paint["mark"]
		elif STEAM_GRAYS.has(was):
			var body_tone: Color = paint["body"]
			tone = body_tone.lerp(paint["mark"], STEAM_GRAYS[was])
		if paint["outline"] and was in STEAM_BODY:
			now = "none"
		elif tone is Color:
			now = _hex(tone)
		out += '%s="%s"' % [found.get_string(1), now]
		at = found.get_end()
	out += body.substr(at)
	return _steam_inside(art, out)


## Steam's picture as one shape in [param hex], [param spread] wider than itself, for its edge.
static func _steam_edge(art: Art, hex: String, spread: String) -> String:
	var body := _steam_body(art.steam)
	# NO_TRANSLATE: the picture's SVG.
	var strip := RegEx.create_from_string('\\s(stroke|stroke-width|opacity|fill-opacity)="[^"]*"')
	body = strip.sub(body, "", true)
	var fill := RegEx.create_from_string('fill="(?!none)[^"]*"')
	var around := 'fill="%s" stroke="%s" stroke-width="%s"' % [hex, hex, spread]  # NO_TRANSLATE
	body = fill.sub(body, around + ' stroke-linejoin="round"', true)  # NO_TRANSLATE
	return _steam_inside(art, body)


## [param text] in the font's outlines, set with its ink in the middle of [param middle] across
## and its capitals' height in the middle of it down, [param cap] tall, painted in [param fill].
static func _letter(
	art: Art, text: String, middle: Vector2, cap: float, fill: Variant, solid := false
) -> void:
	if not text.is_empty():
		art.letters(text, middle, cap, fill, solid)


## The letters [param part] holds, see [method Art.letters], as their outline in [param weight]:
## in the middle of their own ink, their capitals as tall as the part says.
static func _set_letters(part: Dictionary, weight: float) -> Dictionary:
	var outline := _outline(part["text"], weight)
	var cap: float = part["cap"]
	var middle: Vector2 = part["middle"]
	var scale := cap / _cap_height()
	var low: Vector2 = outline[1]
	var high: Vector2 = outline[2]
	var x := middle.x - (low.x + high.x) * 0.5 * scale
	var y := middle.y + cap * 0.5
	var placed := part.duplicate()
	placed["d"] = outline[0]
	placed["xf"] = "translate(%s %s) scale(%s)" % [_n(x), _n(y), _n(scale)]  # NO_TRANSLATE
	return placed


## How wide [param text] is in units, its capitals [param cap] tall.
static func words_wide(text: String, cap: float) -> float:
	if text.is_empty():
		return 0.0
	var outline := _outline(text)
	var low: Vector2 = outline[1]
	var high: Vector2 = outline[2]
	return (high.x - low.x) * cap / _cap_height()


## How tall a capital is set for [param text]: big alone, smaller the more there is of it.
static func _cap_for(text: String) -> float:
	var count := text.length()
	if count <= 1:
		return CAP_ONE
	return CAP_FEW if count <= 3 else CAP_WORD


static func _cap_height() -> float:
	if _cap <= 0.0:
		var outline := _outline("H")
		var low: Vector2 = outline[1]
		var high: Vector2 = outline[2]
		_cap = maxf(high.y - low.y, 1.0)
	return _cap


## The house's strong cut, set [param weight] heavier, see [constant EMBOLDEN].
static func _font(weight: float) -> Font:
	if not _types.has(weight):
		var bolder := FontVariation.new()
		bolder.base_font = Type.STRONG
		bolder.variation_embolden = weight
		_types[weight] = bolder
	return _types[weight]


## [param text] shaped in the glyph font set [param weight] heavier, as one SVG path at
## [constant OUTLINE_SIZE] with its baseline at nought, and the box its ink takes: [path, top left,
## bottom right]. Kept by the language spoken too, whose words they may be, GAME.md 10.9.
static func _outline(text: String, weight := EMBOLDEN) -> Array:
	var key := "%s|%s|%s" % [text, weight, Lang.current]
	var known: Array = _letters.get(key, [])
	if not known.is_empty():
		return known
	var server := TextServerManager.get_primary_interface()
	var line := TextLine.new()
	line.add_string(text, _font(weight), OUTLINE_SIZE)
	var path := PackedStringArray()
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	var pen := 0.0
	for glyph: Dictionary in server.shaped_text_get_glyphs(line.get_rid()):
		var at := Vector2(pen, 0.0) + (glyph["offset"] as Vector2)
		var shape: Dictionary = server.font_get_glyph_contours(
			glyph["font_rid"], glyph["font_size"], glyph["index"]
		)
		if not shape.is_empty():
			var points: PackedVector3Array = shape["points"]
			var ends: PackedInt32Array = shape["contours"]
			var from := 0
			for end: int in ends:
				_contour(points, from, end, at, path)
				for i: int in range(from, end + 1):
					var point := Vector2(points[i].x, points[i].y) + at
					low = low.min(point)
					high = high.max(point)
				from = end + 1
		pen += float(glyph["advance"]) * int(glyph.get("repeat", 1))
	if low.x == INF:
		low = Vector2.ZERO
		high = Vector2(pen, 0.0)
	var made := ["".join(path), low, high]
	_letters[key] = made
	return made


## One closed contour of a glyph's outline, its points [param from] to [param to], as SVG path
## commands: TrueType's quadratic curves, with an on-curve point implied between two off-curve
## ones, and OpenType's cubic ones.
static func _contour(
	points: PackedVector3Array, from: int, to: int, at: Vector2, path: PackedStringArray
) -> void:
	var spots: Array[Vector2] = []
	var tags: Array[int] = []
	for i: int in range(from, to + 1):
		spots.append(Vector2(points[i].x, points[i].y) + at)
		tags.append(int(points[i].z) & 3)
	var count := spots.size()
	if count < 2:
		return
	var first := tags.find(1)
	if first < 0:
		spots.insert(0, (spots[0] + spots[count - 1]) * 0.5)
		tags.insert(0, 1)
		count += 1
	elif first > 0:
		spots = spots.slice(first) + spots.slice(0, first)
		tags = tags.slice(first) + tags.slice(0, first)
	path.append("M" + _v(spots[0]))
	var i := 1
	while i <= count:
		var k := i % count
		if tags[k] == 1:
			path.append("L" + _v(spots[k]))
			i += 1
		elif tags[k] == 0:
			var next := (i + 1) % count
			var end := spots[next]
			if tags[next] == 0:
				end = (spots[k] + spots[next]) * 0.5
				i += 1
			else:
				i += 2
			path.append("Q" + _v(spots[k]) + " " + _v(end))
		else:
			var second := spots[(i + 1) % count]
			var end := spots[(i + 2) % count]
			path.append("C" + _v(spots[k]) + " " + _v(second) + " " + _v(end))
			i += 3
	path.append("Z")


static func _v(point: Vector2) -> String:
	return _n(point.x) + " " + _n(point.y)


## Path commands [param steps] as SVG, with a space after: a letter for a command, a [Vector2] for
## a point, a whole number for an arc's flags and a float for anything else, an arc's radius.
static func _d(steps: Array) -> String:
	var out := PackedStringArray()
	for step: Variant in steps:
		if step is Vector2:
			out.append(_v(step))
		elif step is String:
			out.append(step)
		elif step is int:
			# An arc's flags, which SVG takes as a bare 0 or 1 and "1.0" breaks.
			out.append(str(step))
		else:
			out.append(_n(float(step)))
	return " ".join(out) + " "


## The transform that turns a shape drawn for the left of the pad round to the right.
static func _mirror(art: Art, side: int) -> String:
	return "" if side <= 0 else "matrix(-1 0 0 1 %s 0)" % _n(art.wide)  # NO_TRANSLATE


static func _circle(middle: Vector2, radius: float) -> String:
	var west := middle - Vector2(radius, 0.0)
	var east := middle + Vector2(radius, 0.0)
	var half := ["A", radius, radius, 0, 1, 0]
	return _d(["M", west] + half + [east] + half + [west, "Z"])


static func _box(rect: Rect2, radius: float) -> String:
	return _corners(rect, [radius, radius, radius, radius])


## [param rect] with its corners rounded, top left, top right, bottom right and bottom left.
static func _corners(rect: Rect2, radii: Array) -> String:
	var most := minf(rect.size.x, rect.size.y) * 0.5
	var r: Array[float] = []
	for each: Variant in radii:
		r.append(minf(float(each), most))
	var a := rect.position
	var b := rect.end
	return (
		_d(["M", Vector2(a.x + r[0], a.y), "L", Vector2(b.x - r[1], a.y)])
		+ _d(["Q", Vector2(b.x, a.y), Vector2(b.x, a.y + r[1]), "L", Vector2(b.x, b.y - r[2])])
		+ _d(["Q", b, Vector2(b.x - r[2], b.y), "L", Vector2(a.x + r[3], b.y)])
		+ _d(["Q", Vector2(a.x, b.y), Vector2(a.x, b.y - r[3]), "L", Vector2(a.x, a.y + r[0])])
		+ _d(["Q", a, Vector2(a.x + r[0], a.y), "Z"])
	)


## A polygon through [param corners] with each rounded off by its own radius in [param rounds].
static func _rounded_polygon(corners: PackedVector2Array, rounds: PackedFloat32Array) -> String:
	var path := ""
	var count := corners.size()
	for i: int in count:
		var corner := corners[i]
		var into := corner + (corners[(i + count - 1) % count] - corner).normalized() * rounds[i]
		var out := corner + (corners[(i + 1) % count] - corner).normalized() * rounds[i]
		path += _d(["M" if i == 0 else "L", into, "Q", corner, out])
	return path + "Z"


## A solid arrowhead centered on [param middle], its point [param deep] ahead of its back the way
## [param way] goes, [param span] across its back.
static func _head(middle: Vector2, way: Vector2, span: float, deep: float) -> String:
	var side := Vector2(-way.y, way.x)
	var back := middle - way * deep * 0.5
	var tip := back + way * deep
	return _d(["M", tip, "L", back + side * span * 0.5, "L", back - side * span * 0.5, "Z"])
