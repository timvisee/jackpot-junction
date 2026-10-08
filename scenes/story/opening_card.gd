class_name OpeningCard
extends Control
## The card out of the envelope, STORY.md 6.1a, see [OpeningInvitation]: red velvet edged in gold,
## the gold's rays fanned out from its top, GRAND OPENING over the name and the suits, what the
## place is in a line, YOU'RE ON THE LIST, and at its foot, past a perforation of punched holes with
## a bite either side, one gold stub, ADMIT ONE DRIVER, numbered; a star of a sticker slapped on its
## corner. Torn, see [member torn], the perforation goes ragged along both edges, matching, and the
## card draws itself without its stub while [member stub_only] draws the stub alone, which is how
## the stub falls away. Drawn in code at [constant SIZE], its sticker out past its right edge.

const SIZE := Vector2(675.0, 885.0)
## The gold edge round it, the line of lighter gold inside that, where the perforation runs, how big
## the bites either side of it are, and the holes along it.
const EDGE := 10.5
const LINE := 3.0
const PERFORATION := 696.0
const BITE := 18.0
const HOLE := 4.8
const HOLE_STEP := 19.5
## How far a tear wanders either side of the perforation, and how often it turns.
const RAGGED := 3.5
const RAGGED_STEP := 8.0
## The rays fanned out from the top, how wide each is, in degrees, and how far apart.
const RAY_WIDE := 5.0
const RAY_STEP := 10.0
const VELVET := Color("#6d1420")
const EDGE_GOLD := HouseTheme.FOIL_LOW
const LINE_GOLD := HouseTheme.FOIL_HIGH
const GOLD := HouseTheme.FOIL
const GOLD_SHADOW := Color("#7a4f12")
const CREAM := Palette.CHIP_WHITE
const CREAM_SOFT := Color("#e3c9b6")
const SUIT_RED := Palette.MULT
const STUB_INK := Color("#57101a")
const STUB_FINE := Color("#6b4a14")
const HOLE_INK := HouseTheme.STOCK
## The sticker on its corner: where its middle is, how big, how far it is turned, and its ink.
const STICKER_AT := Vector2(648.0, 198.0)
const STICKER := 93.0
const STICKER_TURN := 0.23
const STICKER_INK := HouseTheme.INK

## The number on the stub.
var number := "0001 2048"
## Whether the stub has been torn off: the perforation ragged, and the stub drawn by itself.
var torn := false
## This card drawn as the stub alone, torn off, for it to fall away; and whether the card draws its
## own stub, which it does until the stub alone has taken its place.
var stub_only := false
var shows_stub := true

## The ragged edge of the tear, left to right between the bites.
var _tear := PackedVector2Array()


func _ready() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	pivot_offset = SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(number)
	var x := BITE
	_tear.append(Vector2(x, PERFORATION))
	x += RAGGED_STEP
	while x < SIZE.x - BITE - RAGGED_STEP * 0.5:
		_tear.append(Vector2(x, PERFORATION + rng.randf_range(-RAGGED, RAGGED)))
		x += RAGGED_STEP * rng.randf_range(0.6, 1.3)
	_tear.append(Vector2(SIZE.x - BITE, PERFORATION))


## Torn along the perforation: from now on the card draws itself without the stub, the edge where
## it came off ragged, and a card drawn [member stub_only] with the same [member number] is the
## stub, with the same edge.
func tear() -> void:
	torn = true
	queue_redraw()


func _draw() -> void:
	if not stub_only:
		_draw_body()
	if stub_only or shows_stub:
		_draw_stub()
	# The holes punched along the perforation, half in the velvet and half in the stub.
	if not torn and not stub_only:
		var x := BITE + HOLE_STEP * 0.75
		while x < SIZE.x - BITE - HOLE_STEP * 0.5:
			draw_circle(Vector2(x, PERFORATION), HOLE, HOLE_INK)
			x += HOLE_STEP
	if not stub_only:
		_draw_sticker()


## The card above the perforation: the gold edge, the velvet in it with its rays and its line, and
## the words.
func _draw_body() -> void:
	var edge := _clipped(_body_outline())
	for part: PackedVector2Array in edge:
		draw_colored_polygon(part, EDGE_GOLD)
	var inside := Rect2(Vector2.ONE * EDGE, Vector2(SIZE.x - EDGE * 2.0, PERFORATION))
	for part: PackedVector2Array in edge:
		for velvet: PackedVector2Array in Geometry2D.intersect_polygons(part, _rect(inside)):
			draw_colored_polygon(velvet, VELVET)
			_draw_rays(velvet)
			_draw_rim(velvet)
	_draw_words()


## The stub under the perforation: the gold edge round it, its own gold inside, and its words.
func _draw_stub() -> void:
	var edge := _clipped(_stub_outline())
	for part: PackedVector2Array in edge:
		draw_colored_polygon(part, EDGE_GOLD)
	var inside := Rect2(
		Vector2(EDGE, PERFORATION - RAGGED * 2.0),
		Vector2(SIZE.x - EDGE * 2.0, SIZE.y - PERFORATION + RAGGED * 2.0 - EDGE)
	)
	for part: PackedVector2Array in edge:
		for gold: PackedVector2Array in Geometry2D.intersect_polygons(part, _rect(inside)):
			draw_colored_polygon(gold, GOLD)
			_draw_rim(gold)
	var left := EDGE + 30.0
	var top := PERFORATION + 20.0
	var mark := Type.mark_font()
	draw_string(
		mark,
		Vector2(left, top + mark.get_ascent(54)),
		StoryLines.OPENING_ADMIT,
		0,
		-1,
		54,
		STUB_INK
	)
	draw_string(
		Type.TEXT, Vector2(left, top + 76.0), StoryLines.OPENING_NO_EXPERIENCE, 0, -1, 21, STUB_INK
	)
	var right := SIZE.x - EDGE - 30.0
	for i: int in 2:
		var said := StoryLines.OPENING_NUMBER if i == 0 else number
		var wide := NotePage.TYPED.get_string_size(said, 0, -1, 21).x
		draw_string(
			NotePage.TYPED, Vector2(right - wide, top + 34.0 + 26.0 * i), said, 0, -1, 21, STUB_INK
		)
	draw_string(
		Type.TEXT,
		Vector2(left, SIZE.y - EDGE - 22.0),
		StoryLines.OPENING_SMALL_PRINT,
		0,
		-1,
		14,
		STUB_FINE
	)


## The lighter gold line round the inside of [param shape], but along the perforation, where the
## velvet meets the stub with nothing between them.
func _draw_rim(shape: PackedVector2Array) -> void:
	for i: int in shape.size():
		var from := shape[i]
		var to := shape[(i + 1) % shape.size()]
		var near := RAGGED + 0.5
		if absf(from.y - PERFORATION) <= near and absf(to.y - PERFORATION) <= near:
			continue
		draw_line(from, to, LINE_GOLD, LINE, true)


## The rays of gold fanned out from the middle of the top, over [param velvet] and no further.
func _draw_rays(velvet: PackedVector2Array) -> void:
	var apex := Vector2(SIZE.x * 0.5, EDGE)
	var angle := 0.0
	while angle < 180.0:
		var ray := PackedVector2Array(
			[
				apex,
				apex + Vector2.from_angle(deg_to_rad(angle)) * 2000.0,
				apex + Vector2.from_angle(deg_to_rad(angle + RAY_WIDE)) * 2000.0,
			]
		)
		for lit: PackedVector2Array in Geometry2D.intersect_polygons(ray, velvet):
			draw_colored_polygon(lit, Color(GOLD, 0.08))
		angle += RAY_STEP


## What the card says, spread evenly from its top to the perforation: GRAND OPENING and TONIGHT,
## the name, the suits, what the place is, and the list.
func _draw_words() -> void:
	var groups: Array[float] = [60.0, 211.0, 30.0, 71.0, 84.0]
	var used := 0.0
	for tall: float in groups:
		used += tall
	var top := EDGE + 12.0
	var room := PERFORATION - 12.0 - top - used
	var gap := room / float(groups.size() + 1)
	var y := top + gap
	var middle := SIZE.x * 0.5
	# GRAND OPENING between two stars, and TONIGHT under it.
	var event_wide := _spaced(Type.DISPLAY, StoryLines.OPENING_EVENT, 28, GOLD, middle, y, 9.0)
	for side: float in [-1.0, 1.0]:
		_draw_star(Vector2(middle + side * (event_wide * 0.5 + 24.0), y + 15.0), 11.0, GOLD)
	_spaced(Type.STRONG, StoryLines.OPENING_WHEN, 19, LINE_GOLD, middle, y + 36.0, 9.0)
	y += groups[0] + gap
	# The name, gold, with its shadow under it.
	var mark := Type.mark_font()
	for i: int in StoryLines.OPENING_NAME.size():
		var line := StoryLines.OPENING_NAME[i]
		var at := y + 105.6 * i - 6.0
		_centered(mark, line, 120, GOLD_SHADOW, middle, at + 4.5)
		_centered(mark, line, 120, GOLD, middle, at)
	y += groups[1] + gap
	# The four suits.
	var suits := [&"spade", &"heart", &"diamond", &"club"]
	for i: int in suits.size():
		var at := Vector2(middle + (float(i) - 1.5) * 57.0, y + 15.0)
		_draw_suit(suits[i], at, 15.0)
	y += groups[2] + gap
	# What the place is.
	_centered(Type.STRONG, StoryLines.OPENING_WHAT, 33, CREAM, middle, y)
	_centered(Type.TEXT, StoryLines.OPENING_WHERE, 22, CREAM_SOFT, middle, y + 43.0)
	y += groups[3] + gap
	# The list, and that the player will come.
	_spaced(Type.STRONG, StoryLines.OPENING_LIST, 36, GOLD, middle, y, 6.0)
	_centered(Type.TEXT, StoryLines.OPENING_RSVP, 24, HouseTheme.PAPER, middle, y + 50.0)


## The star of a sticker on the corner, FREE CHIPS FOR NEW DRIVERS* on it.
func _draw_sticker() -> void:
	draw_set_transform(STICKER_AT, STICKER_TURN, Vector2.ONE)
	var star := PackedVector2Array()
	for i: int in 24:
		var reach := STICKER if i % 2 == 0 else STICKER * 0.76
		star.append(Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 24.0) * reach)
	var shade := PackedVector2Array()
	for point: Vector2 in star:
		shade.append(point + Vector2(3.0, 5.0))
	draw_colored_polygon(shade, Color(0.0, 0.0, 0.0, 0.3))
	draw_colored_polygon(star, GOLD)
	var mark := Type.mark_font()
	var lines := StoryLines.OPENING_STICKER
	var y := -float(lines.size()) * 27.0 * 0.5
	for line: String in lines:
		_centered(mark, line, 27, STICKER_INK, 0.0, y)
		y += 27.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A star of five points round [param at], [param reach] to its points.
func _draw_star(at: Vector2, reach: float, ink: Color) -> void:
	var star := PackedVector2Array()
	for i: int in 10:
		var far := reach if i % 2 == 0 else reach * 0.45
		star.append(at + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * far)
	draw_colored_polygon(star, ink)


## A suit, [param kind], round [param at], [param half] of its height either side.
func _draw_suit(kind: StringName, at: Vector2, half: float) -> void:
	match kind:
		&"diamond":
			draw_colored_polygon(
				PackedVector2Array(
					[
						at + Vector2(0.0, -half),
						at + Vector2(half * 0.7, 0.0),
						at + Vector2(0.0, half),
						at + Vector2(-half * 0.7, 0.0),
					]
				),
				SUIT_RED
			)
		&"heart":
			draw_colored_polygon(_heart(at, half, 1.0), SUIT_RED)
		&"spade":
			draw_colored_polygon(_heart(at + Vector2(0.0, -half * 0.12), half * 0.9, -1.0), CREAM)
			_draw_stem(at, half)
		&"club":
			var r := half * 0.36
			draw_circle(at + Vector2(0.0, -half * 0.45), r, CREAM)
			draw_circle(at + Vector2(-half * 0.42, half * 0.08), r, CREAM)
			draw_circle(at + Vector2(half * 0.42, half * 0.08), r, CREAM)
			_draw_stem(at, half)


## The stem under a spade or a club.
func _draw_stem(at: Vector2, half: float) -> void:
	draw_colored_polygon(
		PackedVector2Array(
			[
				at + Vector2(0.0, half * 0.1),
				at + Vector2(half * 0.3, half),
				at + Vector2(-half * 0.3, half),
			]
		),
		CREAM
	)


## A heart round [param at], [param half] of its height either side, point down, or up when
## [param way] is -1, for a spade.
static func _heart(at: Vector2, half: float, way: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in 48:
		var t := TAU * float(i) / 48.0
		var x := 16.0 * pow(sin(t), 3.0)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(at + Vector2(x, (y + 2.0) * way) * half / 15.0)
	return points


## The card's outline above the perforation, straight or as it tore.
func _body_outline() -> PackedVector2Array:
	var shape := PackedVector2Array([Vector2.ZERO, Vector2(SIZE.x, 0.0)])
	shape.append(Vector2(SIZE.x, PERFORATION))
	var edge := _edge()
	edge.reverse()
	shape.append_array(edge)
	shape.append(Vector2(0.0, PERFORATION))
	return shape


## The stub's outline under the perforation, straight or as it tore.
func _stub_outline() -> PackedVector2Array:
	var shape := PackedVector2Array([Vector2(0.0, PERFORATION)])
	shape.append_array(_edge())
	shape.append(Vector2(SIZE.x, PERFORATION))
	shape.append(SIZE)
	shape.append(Vector2(0.0, SIZE.y))
	return shape


## Along the perforation between the bites, left to right: straight, or ragged once torn.
func _edge() -> PackedVector2Array:
	if torn:
		return _tear.duplicate()
	return PackedVector2Array([Vector2(BITE, PERFORATION), Vector2(SIZE.x - BITE, PERFORATION)])


## [param shape] with the two bites taken out of it, either side of the perforation.
static func _clipped(shape: PackedVector2Array) -> Array[PackedVector2Array]:
	var parts: Array[PackedVector2Array] = [shape]
	for x: float in [0.0, SIZE.x]:
		var bite := PackedVector2Array()
		for i: int in 32:
			bite.append(Vector2(x, PERFORATION) + Vector2.from_angle(TAU * float(i) / 32.0) * BITE)
		var kept: Array[PackedVector2Array] = []
		for part: PackedVector2Array in parts:
			# The bites are at the edges, so what is left has no holes in it.
			kept.append_array(Geometry2D.clip_polygons(part, bite))
		parts = kept
	return parts


static func _rect(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array(
		[
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y)
		]
	)


## How wide [param said] is in [param font] at [param font_size], less the [param spacing] after
## its last letter.
static func _wide(font: Font, said: String, font_size: int, spacing := 0.0) -> float:
	return font.get_string_size(said, 0, -1, font_size).x - spacing


## [param said] spread out, [param spacing] between its letters, across the middle of
## [param middle], the top of its line at [param top]; drawn a letter at a time so it is measured as
## it is drawn. Returns how wide it is.
func _spaced(
	font: Font, said: String, font_size: int, ink: Color, middle: float, top: float, spacing: float
) -> float:
	var wide := -spacing
	for letter: String in said:
		wide += font.get_string_size(letter, 0, -1, font_size).x + spacing
	var x := middle - wide * 0.5
	var baseline := top + font.get_ascent(font_size)
	for letter: String in said:
		draw_string(font, Vector2(x, baseline), letter, 0, -1, font_size, ink)
		x += font.get_string_size(letter, 0, -1, font_size).x + spacing
	return wide


## [param said] across the middle of [param middle], the top of its line at [param top].
func _centered(
	font: Font, said: String, font_size: int, ink: Color, middle: float, top: float, spacing := 0.0
) -> void:
	var wide := _wide(font, said, font_size, spacing)
	draw_string(
		font,
		Vector2(middle - wide * 0.5, top + font.get_ascent(font_size)),
		said,
		0,
		-1,
		font_size,
		ink
	)
