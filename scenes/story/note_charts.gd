class_name NoteCharts
extends RefCounted
## The notes that read better as a drawing than as text, STORY.md 7.3, and the House's letterhead:
## drawn onto a [NotePage] in place of its words or above them. The words stay in the note for the
## screen reader, see [method StoryNotes.read_out]; the figures here mirror them, so edit both.

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
		canvas.draw_arc(seal, r * scale, 0.0, TAU, 36, gold, 1.6, true)
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
	canvas.draw_polyline(line, Color(0.26, 0.36, 0.58), 3.0, true)
	for p: Vector2 in line:
		canvas.draw_circle(p, 3.2, Color(0.26, 0.36, 0.58))
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


## A line blacked out, the House redacting its own page.
static func _redact(canvas: CanvasItem, span: Rect2) -> void:
	canvas.draw_rect(
		Rect2(span.position + Vector2(-4.0, -1.0), Vector2(span.size.x + 8.0, span.size.y + 2.0)),
		NotePage.TYPED_INK
	)


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
