class_name OpeningEnvelope
extends Control
## The envelope the invitation came in, STORY.md 6.1a, see [OpeningInvitation]: the House's bulk
## mail, cheap cream paper, the House's name in the corner, a box of postage in the other, a window
## with nobody in particular in it, a promise in red across the foot and a postal barcode; and a
## green road sign somebody stuck on it, pointing the way, one corner lifting. Drawn in code at
## [constant SIZE].

const SIZE := Vector2(840.0, 450.0)
const PAPER := Color("#ece3cf")
const INK := HouseTheme.INK
const FAINT := HouseTheme.INK_FAINT
const RED := Palette.CHIP_RED
## The window and the postage box, and where the promise and the barcode go.
const WINDOW := Rect2(105.0, 174.0, 450.0, 138.0)
const POSTAGE_WIDE := 150.0
const POSTAGE_AT := Vector2(SIZE.x - 39.0 - POSTAGE_WIDE, 33.0)
const WINNER_AT := Vector2(60.0, 418.0)
const WINNER_TURN := -0.07
const BARCODE := Rect2(540.0, 400.0, 258.0, 21.0)
## The road sign stuck on it: where, how big and how far turned, white round its edge as a sticker
## is cut, and how much of its corner has come away, a share of its width and of its height.
const SIGN_AT := Vector2(408.0, 75.0)
const SIGN_SIZE := Vector2(213.0, 112.0)
const SIGN_TURN := 0.12
const SIGN_GREEN := Color("#0d6b3e")
const SIGN_LIFT := Vector2(0.15, 0.27)
const BACKING := Color("#cfcabd")


func _ready() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	pivot_offset = SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.set_corner_radius_all(5)
	paper.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	paper.shadow_size = 30
	paper.shadow_offset = Vector2(0.0, 22.0)
	paper.anti_aliasing = true
	draw_style_box(paper, Rect2(Vector2.ZERO, SIZE))
	# Who it is from, in the corner.
	var from := _spaced(Type.DISPLAY, 3.0)
	draw_string(from, Vector2(42.0, 66.0), StoryLines.OPENING_FROM, 0, -1, 30, INK)
	draw_string(Type.TEXT, Vector2(42.0, 92.0), StoryLines.OPENING_FROM_PLACE, 0, -1, 20, FAINT)
	_draw_postage()
	# The window, and nobody in particular in it.
	draw_rect(WINDOW, Color(1.0, 1.0, 1.0, 0.5))
	draw_rect(WINDOW, Color(0.0, 0.0, 0.0, 0.14), false, 1.5)
	var y := WINDOW.position.y + 54.0
	for line: String in StoryLines.OPENING_TO:
		draw_string(NotePage.TYPED, Vector2(WINDOW.position.x + 33.0, y), line, 0, -1, 28, INK)
		y += 40.0
	draw_set_transform(WINNER_AT, WINNER_TURN, Vector2.ONE)
	draw_string(Type.mark_font(), Vector2.ZERO, StoryLines.OPENING_WINNER, 0, -1, 45, RED)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_barcode()
	_draw_sign()


## The postage in its box at the top right: presorted, paid, by the House.
func _draw_postage() -> void:
	var lines := StoryLines.OPENING_POSTAGE
	var tall := 24.0 + 22.0 * lines.size()
	draw_rect(Rect2(POSTAGE_AT, Vector2(POSTAGE_WIDE, tall)), INK, false, 3.0)
	var y := POSTAGE_AT.y + 28.0
	for line: String in lines:
		var wide := NotePage.TYPED.get_string_size(line, 0, -1, 16).x
		var x := POSTAGE_AT.x + (POSTAGE_WIDE - wide) * 0.5
		draw_string(NotePage.TYPED, Vector2(x, y), line, 0, -1, 16, INK)
		y += 22.0


## A postal barcode along the foot, tall bars and short ones, the same every time.
func _draw_barcode() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 212
	var x := BARCODE.position.x
	while x < BARCODE.end.x:
		var tall := BARCODE.size.y if rng.randf() < 0.5 else BARCODE.size.y * 0.45
		draw_rect(Rect2(x, BARCODE.end.y - tall, 2.6, tall), INK)
		x += 6.3


## The green road sign stuck on it, turned a little, its corner come unstuck and folded back on
## its face: the paper under the corner showing, a shadow where the corner lifts off it, and the
## sticker's back on the flap, white at the fold and greying toward its tip.
func _draw_sign() -> void:
	draw_set_transform(SIGN_AT, SIGN_TURN, Vector2.ONE)
	var w := SIGN_SIZE.x
	var h := SIGN_SIZE.y
	var fold_from := Vector2(w, h * (1.0 - SIGN_LIFT.y))
	var fold_to := Vector2(w * (1.0 - SIGN_LIFT.x), h)
	var along := (fold_to - fold_from).normalized()
	var out := Vector2(along.y, -along.x)
	var whole := _rounded(Rect2(Vector2.ZERO, SIGN_SIZE), 13.0)
	var kept := _cut(whole, fold_from, fold_to, 0.0)
	# Its shadow on the paper, and a darker one under the fold where the corner lifts off it.
	var shadow := PackedVector2Array()
	for point: Vector2 in kept:
		shadow.append(point + Vector2(1.5, 3.0))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.2))
	var lifted := Color(0.0, 0.0, 0.0, 0.22)
	draw_polygon(
		PackedVector2Array([fold_from, fold_to, fold_to + out * 9.0, fold_from + out * 9.0]),
		PackedColorArray([lifted, lifted, Color(lifted, 0.0), Color(lifted, 0.0)])
	)
	_fill(kept, Color.WHITE)
	_fill(
		_cut(
			_rounded(Rect2(Vector2.ONE * 6.0, SIGN_SIZE - Vector2.ONE * 12.0), 9.0),
			fold_from,
			fold_to,
			5.0
		),
		SIGN_GREEN
	)
	var line := _rounded(Rect2(Vector2.ONE * 11.0, SIGN_SIZE - Vector2.ONE * 22.0), 6.0)
	line.append(line[0])
	for part: PackedVector2Array in Geometry2D.clip_polyline_with_polygon(
		line, _cutter(fold_from, fold_to, 9.0)
	):
		draw_polyline(part, Color.WHITE, 3.0, true)
	var words := Type.STRONG
	draw_string(words, Vector2(23.0, 45.0), StoryLines.OPENING_SIGN, 0, -1, 20, Color.WHITE)
	draw_string(words, Vector2(23.0, 70.0), StoryLines.OPENING_SIGN_EXIT, 0, -1, 17, Color.WHITE)
	_draw_arrow(Vector2(w - 42.0, 52.0), 18.0)
	var joke := _spaced(words, 1.5)
	draw_string(joke, Vector2(23.0, 91.0), StoryLines.OPENING_SIGN_JOKE, 0, -1, 12, Color.WHITE)
	# The corner, folded back over the fold onto the face, its own shadow on the face under it.
	var corner := Geometry2D.intersect_polygons(whole, _cutter(fold_from, fold_to, 0.0))
	if not corner.is_empty():
		var flap := PackedVector2Array()
		var tints := PackedColorArray()
		var reach := 0.0
		for point: Vector2 in corner[0]:
			reach = maxf(reach, (point - fold_from).dot(out))
		for point: Vector2 in corner[0]:
			var folded := _reflected(point, fold_from, fold_to)
			flap.append(folded)
			var far := clampf((point - fold_from).dot(out) / maxf(reach, 1.0), 0.0, 1.0)
			tints.append(Color(0.97, 0.97, 0.95).lerp(BACKING, far))
		var under := PackedVector2Array()
		for point: Vector2 in flap:
			under.append(point + Vector2(1.5, 2.5))
		for shade: PackedVector2Array in Geometry2D.intersect_polygons(under, kept):
			draw_colored_polygon(shade, Color(0.0, 0.0, 0.0, 0.22))
		draw_polygon(flap, tints)
		var edge := flap.duplicate()
		edge.append(flap[0])
		draw_polyline(edge, Color(BACKING, 0.9), 1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## [param shape] filled with [param ink], its edge smoothed.
func _fill(shape: PackedVector2Array, ink: Color) -> void:
	draw_colored_polygon(shape, ink)
	var edge := shape.duplicate()
	edge.append(shape[0])
	draw_polyline(edge, ink, 1.0, true)


## A rectangle with its corners [param radius] round, as a polygon.
static func _rounded(rect: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var middles: Array[Vector2] = [
		rect.position + Vector2(radius, radius),
		Vector2(rect.end.x - radius, rect.position.y + radius),
		rect.end - Vector2(radius, radius),
		Vector2(rect.position.x + radius, rect.end.y - radius),
	]
	for i: int in middles.size():
		var from := PI + PI * 0.5 * float(i)
		for step: int in 7:
			points.append(middles[i] + Vector2.from_angle(from + PI * 0.5 * step / 6.0) * radius)
	return points


## [param shape] less what lies beyond the fold from [param from] to [param to], the fold moved
## [param inset] in.
static func _cut(
	shape: PackedVector2Array, from: Vector2, to: Vector2, inset: float
) -> PackedVector2Array:
	var left := Geometry2D.clip_polygons(shape, _cutter(from, to, inset))
	return left[0] if not left.is_empty() else shape


## Everything beyond the fold from [param from] to [param to], the fold moved [param inset] in.
static func _cutter(from: Vector2, to: Vector2, inset: float) -> PackedVector2Array:
	var along := (to - from).normalized()
	var out := Vector2(along.y, -along.x)
	var back := -out * inset
	return PackedVector2Array(
		[
			from - along * 1000.0 + back,
			to + along * 1000.0 + back,
			(from + to) * 0.5 + out * 1000.0 + back,
		]
	)


## An arrow up and to the right, the way the sign points, its tip at [param tip] reaching back
## [param reach].
func _draw_arrow(tip: Vector2, reach: float) -> void:
	var tail := tip + Vector2(-reach, reach)
	draw_line(tail, tip, Color.WHITE, 3.0, true)
	draw_polyline(
		PackedVector2Array(
			[tip + Vector2(-reach * 0.6, 0.0), tip, tip + Vector2(0.0, reach * 0.6)]
		),
		Color.WHITE,
		3.0,
		true
	)


## [param point] mirrored over the line through [param a] and [param b].
static func _reflected(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var along := (b - a).normalized()
	var foot := a + along * (point - a).dot(along)
	return foot * 2.0 - point


## [param font] with [param by] pixels between its letters.
static func _spaced(font: Font, by: float) -> FontVariation:
	var spaced := FontVariation.new()
	spaced.base_font = font
	spaced.spacing_glyph = roundi(by)
	return spaced
