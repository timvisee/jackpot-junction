class_name NoteCharts
extends RefCounted
## The notes that read better as a drawing than as text, STORY.md 7.3, and the House's letterhead:
## drawn onto a [NotePage] in place of its words or above them. The words stay in the note for the
## screen reader, see [method StoryNotes.read_out]; the figures here mirror them, so edit both.
##
## It also holds the hand-drawn ink on a note -- Kit's pen marks, her pencilled arrow and tally, a
## figure's own drawn line -- see [method stroke]: drawn in place at the note's own size, or set
## aside to be drawn crisp over the note when looked at closer, see [method replay], [NoteView].

const GOLD := NotePaper.HOUSE_GOLD
## Note 13's traits and note 5's weeks, each as the note's own lines have them; the pie's colours, a
## muted set that sits on aged paper.
const TRAITS := [
	["BALANCED", 40],
	["GREEDY", 15],
	["CAUTIOUS", 15],
	["HUNTER", 15],
	["BUMPER", 10],
	["GRAZER", 5]
]
const TRAIT_COLORS := [
	Color(0.42, 0.55, 0.66),
	Color(0.82, 0.64, 0.32),
	Color(0.52, 0.63, 0.44),
	Color(0.74, 0.44, 0.42),
	Color(0.56, 0.48, 0.64),
	Color(0.40, 0.60, 0.60),
]
const WEEKS := [["1", 31], ["9", 18], ["23", 7], ["40", 2], ["41", 0]]
## The bars run from green at full staff to red at none, so the fall reads in colour.
const STAFF_FULL := Color(0.45, 0.60, 0.42)
const STAFF_GONE := Color(0.74, 0.40, 0.38)


## Draws note [param page]'s chart or letterhead onto it over [param rect], the paper. Returns where
## its words go next, [param inside]; an empty rect when the drawing is the whole note and no words
## are written, so the caller stops.
static func dress(page: NotePage, rect: Rect2, inside: Rect2) -> Rect2:
	var note: Dictionary = StoryNotes.NOTES.get(page.number, {})
	match StringName(note.get("chart", &"")):
		&"traits":
			_traits(page, rect)
			return Rect2()
		&"rota":
			_rota(page, rect)
			return Rect2()
		&"dashboard":
			_dashboard(page, rect)
			return Rect2()
		&"linegraph":
			_linegraph(page, rect)
			return Rect2()
	if note.get("letterhead", false):
		var top := maxf(inside.position.y, _letterhead(page, rect))
		return Rect2(Vector2(inside.position.x, top), Vector2(inside.size.x, inside.end.y - top))
	return inside


## Note 13 as a pie of participant types, with a legend and the unclassified sliver spelled out.
static func _traits(canvas: CanvasItem, rect: Rect2) -> void:
	var ink := NotePage.TYPED_INK
	_print(canvas, rect.position + Vector2(18.0, 32.0), "HOUSE MEMO · PARTICIPANT TRAITS", 11)
	var center := rect.position + Vector2(118.0, 190.0)
	var angle := -PI * 0.5
	for i: int in TRAITS.size():
		var frac := float(TRAITS[i][1]) / 100.0
		var to := angle + frac * TAU
		var poly := PackedVector2Array([center])
		for s: int in maxi(2, int(frac * 56.0)) + 1:
			var a := lerpf(angle, to, float(s) / maxi(2, int(frac * 56.0)))
			poly.append(center + Vector2.from_angle(a) * 80.0)
		canvas.draw_colored_polygon(poly, TRAIT_COLORS[i])
		canvas.draw_polyline(poly, ink, 1.4, true)
		angle = to
	var ly := rect.position.y + 108.0
	for i: int in TRAITS.size():
		var box := Rect2(rect.position.x + 232.0, ly, 14.0, 14.0)
		canvas.draw_rect(box, TRAIT_COLORS[i])
		canvas.draw_rect(box, ink, false, 1.2)
		_print(
			canvas, box.position + Vector2(22.0, 12.0), "%s %d%%" % [TRAITS[i][0], TRAITS[i][1]], 10
		)
		ly += 22.0
	_print(canvas, Vector2(rect.position.x + 18.0, rect.end.y - 18.0), "UNCLASSIFIED: UNDER 1%", 10)


## Note 5 as a bar chart of staff on duty falling to zero, the last week automated.
static func _rota(canvas: CanvasItem, rect: Rect2) -> void:
	_print(canvas, rect.position + Vector2(18.0, 28.0), "TABLE 0001 · STAFF ON DUTY", 11)
	var base := rect.end.y - 70.0
	var top := rect.position.y + 52.0
	var x0 := rect.position.x + 40.0
	for i: int in WEEKS.size():
		var v: int = WEEKS[i][1]
		var h := (base - top) * (float(v) / 31.0)
		var bx := x0 + 58.0 * float(i)
		if h > 0.0:
			canvas.draw_rect(
				Rect2(bx, base - h, 32.0, h), STAFF_GONE.lerp(STAFF_FULL, float(v) / 31.0)
			)
			canvas.draw_rect(Rect2(bx, base - h, 32.0, h), NotePage.TYPED_INK, false, 1.2)
		_print(canvas, Vector2(bx - 2.0, base + 15.0), "WK " + str(WEEKS[i][0]), 9)
		_print(canvas, Vector2(bx + 8.0, base - h - 5.0), str(v), 10)
	canvas.draw_line(
		Vector2(x0 - 10.0, base), Vector2(rect.end.x - 14.0, base), NotePage.TYPED_INK, 1.2
	)
	_print(canvas, Vector2(x0 + 222.0, base + 30.0), "AUTOMATED", 9, Color(0.6, 0.2, 0.2))
	canvas.draw_string(
		NotePage.HAND,
		Vector2(rect.position.x + 18.0, rect.end.y - 12.0),
		"Advisory (unpaid): 1. —K.",
		0,
		-1,
		18,
		NotePage.PENCIL
	)


## The House's printed letterhead at the top of [param rect]: its seal in gold over the name and a
## rule, scaled to a narrow page and set clear of the paper's own top (a memo's bar). Returns the y
## below which the words resume.
static func _letterhead(canvas: CanvasItem, rect: Rect2, shine := false) -> float:
	# For the shine mask, white on nothing: where the light is to catch the gold, see [NoteView].
	var gold := Color.WHITE if shine else GOLD
	var scale := clampf(rect.size.x / 380.0, 0.72, 1.0)
	var seal := Vector2(rect.get_center().x, rect.position.y + 42.0 * scale)
	for r: float in [19.0, 14.0, 7.0]:
		arc(canvas, seal, r * scale, gold, 1.6)
	var star := PackedVector2Array()
	for i: int in 10:
		var reach := (5.5 if i % 2 == 0 else 2.5) * scale
		star.append(seal + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * reach)
	canvas.draw_colored_polygon(star, gold)
	var name_at := Vector2(rect.position.x, seal.y + 30.0 * scale)
	canvas.draw_string(
		NotePage.TYPED, name_at, "JACKPOT JUNCTION", 1, rect.size.x, int(11 * scale), gold
	)
	var ruley := seal.y + 42.0 * scale
	canvas.draw_line(
		Vector2(rect.position.x + 40.0, ruley), Vector2(rect.end.x - 40.0, ruley), gold, 1.0
	)
	return ruley + 12.0 * scale


## Where a letterhead note's gold catches the light, white for the shine mask, see [NoteView].
static func letterhead_shine(canvas: CanvasItem, rect: Rect2) -> void:
	_letterhead(canvas, rect, true)


## Note 16 as a dashboard of target meters, green within and red below, oversight bottomed at zero.
static func _dashboard(canvas: CanvasItem, rect: Rect2) -> void:
	_print(canvas, rect.position + Vector2(18.0, 32.0), "HOUSE OPERATIONS · DAILY STATEMENT", 11)
	var rows := [
		["TABLES OPEN", "1,204,388", 1.0, STAFF_FULL],
		["PARTICIPANTS", "9,811,450", 1.0, STAFF_FULL],
		["ECONOMIC ACTIVITY", "WITHIN TARGET", 0.8, STAFF_FULL],
		["SOCIAL STABILITY", "WITHIN TARGET", 0.74, STAFF_FULL],
		["PREDICTION QUALITY", "BELOW TARGET", 0.36, STAFF_GONE],
		["HUMAN OVERSIGHT", "0", 0.0, STAFF_GONE],
	]
	var y := rect.position.y + 58.0
	for row: Array in rows:
		_print(canvas, Vector2(rect.position.x + 18.0, y + 10.0), str(row[0]), 9)
		var track := Rect2(rect.position.x + 150.0, y, 108.0, 12.0)
		canvas.draw_rect(track, Color(0.0, 0.0, 0.0, 0.06))
		canvas.draw_rect(Rect2(track.position, Vector2(track.size.x * float(row[2]), 12.0)), row[3])
		canvas.draw_rect(track, NotePage.TYPED_INK, false, 1.0)
		_print(canvas, Vector2(track.end.x + 8.0, y + 10.0), str(row[1]), 8)
		y += 40.0


## Note 18 as a line of prediction quality falling below a red target.
static func _linegraph(canvas: CanvasItem, rect: Rect2) -> void:
	_print(canvas, rect.position + Vector2(18.0, 30.0), "HOUSE MEMO · PREDICTION QUALITY", 10)
	var plot := Rect2(rect.position + Vector2(40.0, 56.0), Vector2(rect.size.x - 70.0, 140.0))
	canvas.draw_line(plot.position, Vector2(plot.position.x, plot.end.y), NotePage.TYPED_INK, 1.2)
	canvas.draw_line(Vector2(plot.position.x, plot.end.y), plot.end, NotePage.TYPED_INK, 1.2)
	var target := plot.position.y + plot.size.y * 0.42
	canvas.draw_dashed_line(
		Vector2(plot.position.x, target), Vector2(plot.end.x, target), STAFF_GONE, 1.4, 5.0
	)
	_print(canvas, Vector2(plot.end.x - 76.0, target - 4.0), "TARGET", 8, STAFF_GONE)
	var at := [0.12, 0.2, 0.3, 0.46, 0.6, 0.78]
	var line := PackedVector2Array()
	for i: int in at.size():
		var px := plot.position.x + plot.size.x * float(i) / float(at.size() - 1)
		line.append(Vector2(px, plot.position.y + plot.size.y * float(at[i])))
	# The trend is hand-drawn ink: crisp over the note at a closer look, see [NoteCharts].
	var page := canvas as NotePage
	stroke(page, line, Color(0.26, 0.36, 0.58), 3.0)
	for p: Vector2 in line:
		dot(page, p, 3.2, Color(0.26, 0.36, 0.58))
	_print(
		canvas,
		Vector2(rect.position.x + 18.0, rect.end.y - 18.0),
		"MODELS CONVERGING. BELOW TARGET.",
		9
	)


## The effects drawn over a House note's words, STORY.md 7.3: sprocket-fed edges, a printer's ink
## streaks, a line or two redacted, and a faint diagonal watermark, each where the note asks.
static func overlay(page: NotePage, rect: Rect2, spans: Array) -> void:
	var note: Dictionary = StoryNotes.NOTES.get(page.number, {})
	if note.get("feed", false):
		_feed(page, rect)
	if note.get("streaks", false):
		_streaks(page, rect, page.number)
	for i: int in note.get("redact", []):
		if int(i) < spans.size():
			_redact(page, spans[int(i)])
	var mark := str(note.get("watermark", ""))
	if not mark.is_empty():
		_watermark(page, rect, mark)


## Sprocket holes down both edges, the mark of continuous-form computer paper.
static func _feed(canvas: CanvasItem, rect: Rect2) -> void:
	for side: float in [0.0, 1.0]:
		var sx := rect.position.x + 8.0 + side * (rect.size.x - 16.0)
		var lx := rect.position.x + (16.0 if side > 0.0 else 0.0)
		canvas.draw_line(
			Vector2(lx, rect.position.y), Vector2(lx, rect.end.y), Color(0.0, 0.0, 0.0, 0.1), 1.0
		)
		var hy := rect.position.y + 12.0
		while hy < rect.end.y - 8.0:
			canvas.draw_circle(Vector2(sx, hy + 1.0), 3.0, Color(0.0, 0.0, 0.0, 0.1))
			canvas.draw_circle(Vector2(sx, hy), 3.0, NotePage.LEAF)
			hy += 18.0


## A printer's vertical ink streaks down [param rect], a worn drum leaking as the page fed through,
## seeded by [param seed]: each streak a band of a few thin lines close together, darker in patches
## and fading out, the way a toner streak runs rather than a ruled line.
static func _streaks(canvas: CanvasItem, rect: Rect2, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 99991 + 5
	for i: int in 1 + rng.randi() % 3:
		var x := rect.position.x + rng.randf_range(0.14, 0.88) * rect.size.x
		var top := rect.position.y + rng.randf_range(0.0, 20.0)
		var bottom := rect.end.y - rng.randf_range(0.0, 14.0)
		var weight := rng.randf_range(0.06, 0.13)
		# The band: a core line and a couple of fainter neighbours a hair to either side.
		for lane: float in [0.0, rng.randf_range(1.2, 2.4), rng.randf_range(-2.4, -1.2)]:
			var faint := weight if lane == 0.0 else weight * rng.randf_range(0.3, 0.55)
			# Broken into short runs, each a touch darker or lighter, so it reads as a leak.
			var y := top
			while y < bottom:
				var run := minf(rng.randf_range(16.0, 46.0), bottom - y)
				var ink := Color(0.1, 0.1, 0.12, faint * rng.randf_range(0.4, 1.3))
				canvas.draw_line(
					Vector2(x + lane, y), Vector2(x + lane, y + run), ink, rng.randf_range(0.8, 1.5)
				)
				y += run


## A line blacked out by hand, the House redacting its own page, marked over the way a setting is at
## the Final Hand, STORY.md 8.1: uneven bled edges and a ragged end, not a clean box, see
## [RedactionBar]. The same every time for the same line.
static func _redact(canvas: CanvasItem, span: Rect2) -> void:
	var over := Rect2(
		span.position + Vector2(-4.0, -1.0), Vector2(span.size.x + 8.0, span.size.y + 2.0)
	)
	RedactionBar.mark(canvas, over, hash(over.position))


## A faint diagonal watermark [param word] across the page, the way an office stamps a copy.
static func _watermark(canvas: CanvasItem, rect: Rect2, word: String) -> void:
	var font := NotePage.MARKER
	var size := 46
	var wide := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if wide > rect.size.x * 1.08:
		size = maxi(18, int(float(size) * rect.size.x * 1.08 / wide))
		wide = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	canvas.draw_set_transform(rect.get_center(), -0.42, Vector2.ONE)
	canvas.draw_string(
		font, Vector2(-wide * 0.5, size * 0.3), word, 0, -1, size, Color(0.5, 0.2, 0.2, 0.13)
	)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _print(
	canvas: CanvasItem, at: Vector2, text: String, size: int, ink := NotePage.TYPED_INK
) -> void:
	canvas.draw_string(NotePage.TYPED, at, text, 0, -1, size, ink)


## The note whose ink is set aside that [param on] draws under, and the transform from [param on]'s
## own coordinates to the note's; empty when nothing over the note draws its ink, see [NoteView].
## A card laid on a note, its figure drawn in pencil, records this way in the note's space.
static func _sink(on: CanvasItem) -> Array:
	var t := Transform2D.IDENTITY
	var node := on
	while node != null:
		var page := node as NotePage
		if page != null:
			return [page, t] if page.hide_ink else []
		t = node.get_transform() * t
		node = node.get_parent() as CanvasItem
	return []


## A stroke along [param points], [param width] wide, in [param color]: onto [param on], or set
## aside to draw crisp over the note it is under, see [NoteCharts]. A polyline, keeping its joins.
static func stroke(on: CanvasItem, points: PackedVector2Array, color: Color, width: float) -> void:
	var sink := _sink(on)
	if sink.is_empty():
		on.draw_polyline(points, color, width, true)
		return
	var t: Transform2D = sink[1]
	var moved := PackedVector2Array()
	for point: Vector2 in points:
		moved.append(t * point)
	(sink[0] as NotePage)._ink_strokes.append(
		{&"kind": &"poly", &"points": moved, &"color": color, &"width": width * t.get_scale().x}
	)


## A single stroke, see [method stroke].
static func seg(on: CanvasItem, from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var sink := _sink(on)
	if sink.is_empty():
		on.draw_line(from, to, color, width, true)
		return
	var t: Transform2D = sink[1]
	(sink[0] as NotePage)._ink_strokes.append(
		{
			&"kind": &"seg",
			&"a": t * from,
			&"b": t * to,
			&"color": color,
			&"width": width * t.get_scale().x
		}
	)


## A dot of ink, see [method stroke].
static func dot(on: CanvasItem, middle: Vector2, radius: float, color: Color) -> void:
	var sink := _sink(on)
	if sink.is_empty():
		on.draw_circle(middle, radius, color)
		return
	var t: Transform2D = sink[1]
	(sink[0] as NotePage)._ink_strokes.append(
		{&"kind": &"dot", &"at": t * middle, &"radius": radius * t.get_scale().x, &"color": color}
	)


## A ring round [param middle], [param radius] out, from [param from] to [param to], a whole circle
## by default: drawn onto [param on], or set aside to draw crisp over the note, see [method stroke].
## A ring does not turn, so only its middle is placed, letting a stamp's circles be set aside while
## its tilted word is not, see [ApprovedStamp].
static func arc(
	on: CanvasItem,
	middle: Vector2,
	radius: float,
	color: Color,
	width: float,
	from := 0.0,
	to := TAU
) -> void:
	var sink := _sink(on)
	if sink.is_empty():
		on.draw_arc(middle, radius, from, to, _arc_steps(radius), color, width, true)
		return
	var t: Transform2D = sink[1]
	var scale := t.get_scale().x
	(sink[0] as NotePage)._ink_strokes.append(
		{
			&"kind": &"arc",
			&"at": t * middle,
			&"radius": radius * scale,
			&"from": from,
			&"to": to,
			&"color": color,
			&"width": width * scale
		}
	)


## How many straight pieces a ring [param radius] across is drawn in: enough that it reads round at
## the size it is shown, however close that is, see [method arc].
static func _arc_steps(radius: float) -> int:
	return clampi(roundi(radius * 0.7), 16, 160)


## A hand-drawn [param ch] at [param size], see [method stroke].
static func glyph(
	on: CanvasItem, font: Font, pos: Vector2, ch: String, size: int, color: Color
) -> void:
	var sink := _sink(on)
	if sink.is_empty():
		on.draw_char(font, pos, ch, size, color)
		return
	var t: Transform2D = sink[1]
	(sink[0] as NotePage)._ink_strokes.append(
		{
			&"kind": &"glyph",
			&"font": font,
			&"at": t * pos,
			&"ch": ch,
			&"size": roundi(size * t.get_scale().x),
			&"color": color
		}
	)


## The strokes set aside by [member NotePage.hide_ink] drawn onto [param canvas] at [param scale]
## times their size, in their own pixels so they are crisp however close the note is looked at, see
## [NoteView]. The canvas is placed and sized so this lands over the note.
static func replay(canvas: CanvasItem, strokes: Array[Dictionary], scale: float) -> void:
	for stroke: Dictionary in strokes:
		match stroke[&"kind"]:
			&"poly":
				var points := PackedVector2Array()
				for point: Vector2 in stroke[&"points"]:
					points.append(point * scale)
				canvas.draw_polyline(
					points, stroke[&"color"], float(stroke[&"width"]) * scale, true
				)
			&"seg":
				canvas.draw_line(
					stroke[&"a"] * scale,
					stroke[&"b"] * scale,
					stroke[&"color"],
					float(stroke[&"width"]) * scale,
					true
				)
			&"dot":
				canvas.draw_circle(
					stroke[&"at"] * scale, float(stroke[&"radius"]) * scale, stroke[&"color"]
				)
			&"glyph":
				canvas.draw_char(
					stroke[&"font"],
					stroke[&"at"] * scale,
					stroke[&"ch"],
					roundi(int(stroke[&"size"]) * scale),
					stroke[&"color"]
				)
			&"arc":
				var rad := float(stroke[&"radius"]) * scale
				canvas.draw_arc(
					stroke[&"at"] * scale,
					rad,
					stroke[&"from"],
					stroke[&"to"],
					_arc_steps(rad),
					stroke[&"color"],
					float(stroke[&"width"]) * scale,
					true
				)


## A pencil arrow from one of [param page]'s lines to another, where the note asks for one: out from
## the first's start along its row, up the margin clear of the lines between, then in to the second.
static func arrow(page: NotePage) -> void:
	var arrow: Array = StoryNotes.NOTES.get(page.number, {}).get("arrow", [])
	if (
		arrow.size() != 2
		or int(arrow[0]) >= page._spans.size()
		or int(arrow[1]) >= page._spans.size()
	):
		return
	var from_span := page._spans[int(arrow[0])]
	var to_span := page._spans[int(arrow[1])]
	var left := minf(from_span.position.x, to_span.position.x)
	var from := Vector2(from_span.position.x - 6.0, from_span.position.y + from_span.size.y * 0.45)
	var to := Vector2(left - 3.0, to_span.get_center().y)
	# Out into the margin, as far as the paper lets it: its leftmost just inside the paper's edge.
	var edge := page.paper_rect().position.x + NotePage.ARROW_EDGE
	var bow := left - NotePage.ARROW_BOW
	# It comes in to the line rising a little, along [constant NotePage.ARROW_RISE], and the head
	# points the same way, so it carries on from the line rather than turning off it at the last turn.
	var aim := Vector2.from_angle(-NotePage.ARROW_RISE)
	var into := to - aim * NotePage.ARROW_BOW
	var curve := PackedVector2Array()
	for attempt: int in 3:
		var out := Vector2(bow, from.y)
		curve.clear()
		var leftmost := INF
		for i: int in 33:
			var at := from.bezier_interpolate(out, into, to, float(i) / 32.0)
			curve.append(at)
			leftmost = minf(leftmost, at.x)
		if leftmost >= edge - 0.5:
			break
		bow += (edge - leftmost) / 0.5
	# The line stops in the middle of the head, which keeps its point sharp.
	var line := PackedVector2Array()
	for at: Vector2 in curve:
		if at.distance_to(to) > NotePage.ARROW_HEAD * 0.5:
			line.append(at)
	line.append(to - aim * NotePage.ARROW_HEAD * 0.5)
	stroke(page, line, NotePage.PENCIL, 1.5)
	var head := PackedVector2Array(
		[
			to - aim.rotated(NotePage.ARROW_SPREAD) * NotePage.ARROW_HEAD,
			to,
			to - aim.rotated(-NotePage.ARROW_SPREAD) * NotePage.ARROW_HEAD,
		]
	)
	stroke(page, head, NotePage.PENCIL, 1.8)


## Kit's count in pencil, STORY.md 7.3: [param count] upright strokes from [param at], each a little
## off true, the way a tally is kept on whatever is to hand.
static func tally(page: NotePage, at: Vector2, count: int) -> void:
	for i: int in count:
		var lean := page._rng.randf_range(-0.12, 0.12)
		var foot := at + Vector2(8.0 * float(i), 22.0)
		var head := foot + Vector2(sin(lean) * 22.0, -22.0)
		seg(page, foot, head, NotePage.PENCIL, 2.4)


## The first word underlined three times in pen, hard, each stroke a little longer and steeper than
## the one before, STORY.md 7.3.
static func underline(
	page: NotePage, word: String, font: Font, font_size: int, at: Vector2
) -> void:
	var baseline := at.y + font.get_ascent(font_size)
	var wide := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	for i: int in 3:
		var y := baseline + 5.0 + float(i) * 4.0
		var mark := PackedVector2Array()
		for j: int in 7:
			var t := float(j) / 6.0
			mark.append(
				Vector2(
					at.x - 3.0 + t * (wide + 6.0 + float(i) * 6.0),
					y + page._rng.randf_range(-0.8, 0.8) - t * float(i) * 1.5
				)
			)
		stroke(page, mark, NotePage.PEN_INK, 2.2)


## A line struck through by hand, in ink, not quite straight.
static func strike(page: NotePage, over: Rect2) -> void:
	var middle := over.position.y + over.size.y * 0.45
	var points := PackedVector2Array()
	for i: int in 9:
		var t := float(i) / 8.0
		points.append(Vector2(over.position.x + over.size.x * t, middle + sin(t * 9.0) * 1.2))
	stroke(page, points, NotePage.PEN_INK, 2.0)


## Kit's last strip gone over in pen, STORY.md 7.3: a warning triangle drawn twice round, two big
## exclamation marks beside it, and a scribble under them where the pen would not stop.
static func warning(page: NotePage, rect: Rect2) -> void:
	var middle := Vector2(rect.end.x - 96.0, rect.position.y + rect.size.y * 0.4)
	var size := 36.0
	var corners := PackedVector2Array()
	for k: int in 4:
		var a := -PI * 0.5 + TAU * float(k % 3) / 3.0 + 0.08
		corners.append(middle + Vector2.from_angle(a) * size)
	stroke(page, corners, NotePage.PEN_INK, 3.2)
	glyph(page, NotePage.HAND, middle + Vector2(-6.0, 15.0), "!", 42, NotePage.PEN_INK)
	for k: int in 2:
		var at := Vector2(rect.end.x - 56.0 + float(k) * 20.0, middle.y + 26.0)
		glyph(page, NotePage.HAND, at, "!", 72, NotePage.PEN_INK)
	# Round and round, bigger and smaller, faster at the end.
	var coil := PackedVector2Array()
	var from := Vector2(rect.end.x - 150.0, rect.end.y - 24.0)
	for k: int in 90:
		var t := float(k) / 89.0
		var turn := t * 34.0 + t * t * 10.0
		var radius := 7.0 + sin(t * 11.0) * 3.0 + page._rng.randf_range(-1.0, 1.0)
		coil.append(
			from + Vector2(t * 132.0 + cos(turn) * radius, sin(turn) * radius * 0.8 - t * 6.0)
		)
	stroke(page, coil, NotePage.PEN_INK, 1.5)
