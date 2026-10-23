class_name NoteWear
extends RefCounted
## The age and wear a note picks up in a worn folder, STORY.md 7.3, drawn onto a [NotePage] over its
## paper: a stock tinted a hair off any other of its kind, grain and foxing, and the odd mark a
## page carries — a coffee ring, a dog-eared corner, a punched hole, a smudge. Seeded by the note's
## own number so a page's wear is its own and the same every time. Drawn by [NotePaper].

## The plain stocks that pick up wear, not those that read as themselves already (a blueprint, a
## calendar, a torn flyer).
const WORN_PAPERS: Array[StringName] = [
	&"graph",
	&"graph_torn",
	&"sheet",
	&"memo",
	&"form",
	&"letter",
	&"slip",
	&"clipboard",
	&"roll",
	&"legal_pad",
	&"index_card",
	&"engineering",
]
## A coffee ring's brown, a rusted clip's stain, a punched hole's shadow, the tan of age spots, and
## an ink blot's and a smudge's dark.
const COFFEE := Color(0.5, 0.32, 0.12, 0.22)
const RUST := Color(0.54, 0.36, 0.18, 0.2)
const HOLE := Color(0.0, 0.0, 0.0, 0.14)
const FOXING := Color(0.55, 0.42, 0.22)
const INK := Color(0.12, 0.12, 0.2)
const SMUDGE := Color(0.2, 0.2, 0.22)
## The marks a page may pick up, one drawn at random for a seeded page or named for a set one. A
## coffee ring is one of many, not the usual, so a drawer is not all rings.
const MARKS: Array[StringName] = [
	&"coffee", &"dogear", &"punch", &"clip", &"smudge", &"inkblot", &"tack"
]
## Pages marked by hand not seed, so two House memos on one stock are told apart: the loyalty design
## note, 102, and the names memo, 106.
const WEAR_SET := {102: [&"coffee"], 106: [&"dogear", &"smudge"]}


## [param color] aged by [param worn], the note's number: a light stock warmed and darkened by a
## hair, so two sheets of the same are never the same shade; a dark one is left as it is.
static func aged(color: Color, worn: int) -> Color:
	if worn == 0 or color.get_luminance() < 0.5:
		return color
	var rng := RandomNumberGenerator.new()
	rng.seed = worn * 2246822519 + 1
	var warm := rng.randf_range(-0.03, 0.08)
	var dim := rng.randf_range(-0.08, 0.0)
	return Color(
		clampf(color.r + warm + dim, 0.0, 1.0),
		clampf(color.g + warm * 0.3 + dim, 0.0, 1.0),
		clampf(color.b - warm * 0.5 + dim, 0.0, 1.0),
		color.a
	)


## The grain age leaves over the tint, STORY.md 7.3: foxing, a damp blotch or two and dark edges.
static func texture(canvas: CanvasItem, rect: Rect2, worn: int) -> void:
	if worn == 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = worn * 374761393 + 3
	for i: int in 12 + rng.randi() % 10:
		var at := rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
		canvas.draw_circle(
			at, rng.randf_range(0.8, 2.6), Color(FOXING, rng.randf_range(0.05, 0.12))
		)
	for i: int in 1 + rng.randi() % 2:
		var at := rect.position + Vector2(rng.randf() * rect.size.x, rng.randf() * rect.size.y)
		for ring: float in [1.0, 0.6]:
			canvas.draw_circle(at, rng.randf_range(20.0, 46.0) * ring, Color(FOXING, 0.035))
	for i: int in 4:
		canvas.draw_rect(rect.grow(-float(i) * 2.0), Color(0.3, 0.24, 0.12, 0.035), false, 2.0)


## The marks a page picks up, STORY.md 7.3: set by hand (see [constant WEAR_SET]) or seeded by
## [param worn]; a dog-ear folds back onto the page, so it is given the [param paper] it folds.
static func marks(canvas: CanvasItem, rect: Rect2, worn: int, paper: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = worn * 40503 + 7
	var tokens: Array = (WEAR_SET.get(worn, []) as Array).duplicate()
	if tokens.is_empty():
		for i: int in [0, 1, 1, 1, 2, 2][rng.randi() % 6]:
			tokens.append(MARKS[rng.randi() % MARKS.size()])
	for token: StringName in tokens:
		match token:
			&"coffee":
				_coffee(canvas, rect, rng)
			&"dogear":
				_dogear(canvas, rect, rng, paper)
			&"punch":
				_punch(canvas, rect, rng)
			&"smudge":
				_smudge(canvas, rect, rng)
			&"inkblot":
				_inkblot(canvas, rect, rng)
			&"tack":
				_tack(canvas, rect, rng)
			_:
				_clip_rust(canvas, rect, rng)


## A coffee ring left on the page.
static func _coffee(canvas: CanvasItem, rect: Rect2, rng: RandomNumberGenerator) -> void:
	var at := Vector2(
		rng.randf_range(rect.position.x + 24.0, rect.end.x - 24.0),
		rng.randf_range(rect.position.y + 48.0, rect.end.y - 24.0)
	)
	var radius := rng.randf_range(22.0, 34.0)
	canvas.draw_arc(at, radius, 0.0, TAU, 40, COFFEE, rng.randf_range(2.5, 4.0), true)
	canvas.draw_arc(at, radius - 3.0, 0.0, TAU, 40, Color(COFFEE, 0.05), 2.0, true)


## A dog-eared corner: the gap showing the leaf behind, the flap folded back over the page in the
## paper's own underside a shade darker, with its crease and the shadow it casts.
static func _dogear(
	canvas: CanvasItem, rect: Rect2, rng: RandomNumberGenerator, paper: Color
) -> void:
	var size := rng.randf_range(20.0, 30.0)
	var right := rng.randf() < 0.5
	var bottom := rng.randf() < 0.5
	var corner := Vector2(
		rect.end.x if right else rect.position.x, rect.end.y if bottom else rect.position.y
	)
	var a := corner + Vector2(-size if right else size, 0.0)
	var b := corner + Vector2(0.0, -size if bottom else size)
	var tip := corner + Vector2(a.x - corner.x, b.y - corner.y)
	canvas.draw_colored_polygon(PackedVector2Array([corner, a, b]), NotePage.LEAF.darkened(0.06))
	canvas.draw_colored_polygon(PackedVector2Array([a, b, tip]), paper.darkened(0.12))
	canvas.draw_line(a, tip, Color(0.0, 0.0, 0.0, 0.12), 1.5, true)
	canvas.draw_line(b, tip, Color(0.0, 0.0, 0.0, 0.12), 1.5, true)
	canvas.draw_line(a, b, Color(0.0, 0.0, 0.0, 0.18), 1.0, true)


## A hole or two punched along the top, the leaf showing through under a soft rim.
static func _punch(canvas: CanvasItem, rect: Rect2, rng: RandomNumberGenerator) -> void:
	var count := 1 + rng.randi() % 2
	var top := rect.position.y + rng.randf_range(10.0, 16.0)
	var gap := rng.randf_range(44.0, 70.0)
	var first := rect.get_center().x - gap * float(count - 1) * 0.5
	for i: int in count:
		var at := Vector2(first + gap * float(i), top)
		canvas.draw_circle(at + Vector2(0.0, 1.5), 5.0, HOLE)
		canvas.draw_circle(at, 5.0, NotePage.LEAF)


## The rust a paperclip left where it sat on the page's top corner.
static func _clip_rust(canvas: CanvasItem, rect: Rect2, rng: RandomNumberGenerator) -> void:
	var at := Vector2(
		rect.position.x + rng.randf_range(16.0, 30.0), rect.position.y + rng.randf_range(18.0, 32.0)
	)
	for i: int in 3:
		var off := Vector2(rng.randf_range(-3.0, 3.0), rng.randf_range(-6.0, 6.0))
		canvas.draw_circle(at + off, rng.randf_range(2.0, 4.0), Color(RUST, 0.14))
	canvas.draw_arc(at, 7.0, -0.4, 2.6, 16, RUST, 2.2, true)


## A graphite smudge, where a hand dragged across pencil.
static func _smudge(canvas: CanvasItem, rect: Rect2, rng: RandomNumberGenerator) -> void:
	var at := Vector2(
		rng.randf_range(rect.position.x + 34.0, rect.end.x - 34.0),
		rng.randf_range(rect.position.y + 54.0, rect.end.y - 30.0)
	)
	canvas.draw_set_transform(at, rng.randf_range(-0.4, 0.4), Vector2.ONE)
	for i: int in 6:
		var spot := Vector2(rng.randf_range(-22.0, 22.0), rng.randf_range(-6.0, 6.0))
		canvas.draw_circle(spot, rng.randf_range(4.0, 8.0), Color(SMUDGE, 0.045))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A small ink blot with a little spatter round it.
static func _inkblot(canvas: CanvasItem, rect: Rect2, rng: RandomNumberGenerator) -> void:
	var at := Vector2(
		rng.randf_range(rect.position.x + 26.0, rect.end.x - 26.0),
		rng.randf_range(rect.position.y + 54.0, rect.end.y - 26.0)
	)
	canvas.draw_circle(at, rng.randf_range(3.0, 5.5), Color(INK, 0.5))
	for i: int in 5:
		var off := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(6.0, 16.0)
		canvas.draw_circle(at + off, rng.randf_range(0.6, 1.8), Color(INK, 0.4))


## A thumbtack's hole along the top, the puncture and the rust round it.
static func _tack(canvas: CanvasItem, rect: Rect2, rng: RandomNumberGenerator) -> void:
	var at := Vector2(
		rng.randf_range(rect.position.x + 20.0, rect.end.x - 20.0),
		rect.position.y + rng.randf_range(10.0, 18.0)
	)
	canvas.draw_circle(at, 4.0, Color(RUST, 0.2))
	canvas.draw_circle(at, 1.6, HOLE)
