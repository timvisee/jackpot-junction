class_name InvitationCard
extends Control
## The House's invitation to the Final Hand, STORY.md 8.1: a black card edged in gold foil, the
## House's seal pressed into its top, "The House requests the pleasure of your company at the Final
## Hand" in engraved letters, the player's name typed on a dotted line under it, and the table
## under that. Its back is the House's: a lattice in foil round the seal, as a deck's backs are.
## Drawn in code, at [constant SIZE]; [member face_up] says which side shows.

const SIZE := Vector2(520.0, 740.0)
const RADIUS := 18
const CARD := Color(0.055, 0.052, 0.065)
const EMBOSS_HIGH := Color(1.0, 1.0, 1.0, 0.09)
const EMBOSS_LOW := Color(0.0, 0.0, 0.0, 0.6)
const CREAM := Color(0.92, 0.88, 0.8)
const FOIL := HouseTheme.FOIL
const FOIL_FAINT := Color(HouseTheme.FOIL, 0.55)
## Where the seal sits, and how wide its rings are.
const SEAL_AT := Vector2(0.5, 0.14)
const SEAL_RINGS: Array[float] = [52.0, 40.0, 20.0]
## Where the words start, and how much of the card's width they may use.
const WORDS_TOP := 196.0
const WORDS_WIDE := 400.0
## Where the buttons go, from the foot of the card up.
const BUTTONS_ROOM := 170.0

## Whose name is typed on it.
var holder := ""
var face_up := false


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Turned to show [param up]: its front, or its back.
func show_face(up: bool) -> void:
	face_up = up
	queue_redraw()


func _draw() -> void:
	var card := StyleBoxFlat.new()
	card.bg_color = CARD
	card.set_corner_radius_all(RADIUS)
	card.anti_aliasing = true
	card.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	card.shadow_size = 18
	card.shadow_offset = Vector2(0.0, 8.0)
	draw_style_box(card, Rect2(Vector2.ZERO, SIZE))
	_draw_edges()
	if face_up:
		_draw_front()
	else:
		_draw_back()


## The foil round the edge: a band, and a hairline inside it with a diamond at each corner.
func _draw_edges() -> void:
	var edge := StyleBoxFlat.new()
	edge.draw_center = false
	edge.set_border_width_all(3)
	edge.border_color = FOIL
	edge.set_corner_radius_all(RADIUS)
	edge.anti_aliasing = true
	draw_style_box(edge, Rect2(Vector2.ONE * 3.0, SIZE - Vector2.ONE * 6.0))
	var inner := Rect2(Vector2.ONE * 18.0, SIZE - Vector2.ONE * 36.0)
	draw_rect(inner, FOIL_FAINT, false, 1.0)
	for corner: Vector2 in [inner.position, Vector2(inner.end.x, inner.position.y), inner.end]:
		_diamond(corner, 6.0, FOIL)
	_diamond(Vector2(inner.position.x, inner.end.y), 6.0, FOIL)


func _diamond(at: Vector2, half: float, ink: Color) -> void:
	draw_colored_polygon(
		PackedVector2Array(
			[
				at + Vector2(0.0, -half),
				at + Vector2(half, 0.0),
				at + Vector2(0.0, half),
				at + Vector2(-half, 0.0),
			]
		),
		ink
	)


## The seal pressed into the card: each ring lit on its top left edge and shadowed on its bottom
## right, the way a blind embossing catches the light, a foil star in the middle.
func _draw_seal(middle: Vector2, gilded: bool) -> void:
	for ring: float in SEAL_RINGS:
		if gilded:
			draw_arc(middle, ring, 0.0, TAU, 64, FOIL, 2.0, true)
			continue
		draw_arc(middle + Vector2(-1.2, -1.2), ring, 0.0, TAU, 64, EMBOSS_HIGH, 2.4, true)
		draw_arc(middle + Vector2(1.2, 1.2), ring, 0.0, TAU, 64, EMBOSS_LOW, 2.4, true)
	var star := PackedVector2Array()
	for i: int in 10:
		var reach := 12.0 if i % 2 == 0 else 5.0
		star.append(middle + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * reach)
	draw_colored_polygon(star, FOIL)


func _draw_front() -> void:
	_draw_seal(SIZE * SEAL_AT, false)
	var middle := SIZE.x * 0.5
	var y := WORDS_TOP
	y = _centered(StoryLines.INVITE_FROM, NotePage.OLD, 24, FOIL, y, 6.0)
	y += 6.0
	for row: String in NotePage._rows(StoryLines.INVITE_LINE, NotePage.OLD, 27, WORDS_WIDE):
		y = _centered(row, NotePage.OLD, 27, CREAM, y)
	y += 4.0
	var title := StoryLines.FINAL_HAND
	var font := Type.mark_font()
	var wide := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 66).x
	var baseline := y + font.get_ascent(66)
	draw_string(
		font,
		Vector2(middle - wide * 0.5, baseline + 3.0),
		title,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		66,
		HouseTheme.FOIL_LOW.darkened(0.5)
	)
	draw_string(
		font, Vector2(middle - wide * 0.5, baseline), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 66, FOIL
	)
	y = baseline + font.get_descent(66) + 34.0
	# The name typed on a dotted line.
	var line_y := y + 30.0
	var dots := 70.0
	while dots < SIZE.x - 70.0:
		draw_circle(Vector2(dots, line_y), 1.2, FOIL_FAINT)
		dots += 7.0
	var typed := holder.to_upper()
	var name_wide := NotePage.TYPED.get_string_size(typed, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	draw_string(
		NotePage.TYPED,
		Vector2(middle - name_wide * 0.5, line_y - 8.0),
		typed,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		26,
		CREAM
	)
	y = line_y + 30.0
	for row: String in NotePage._rows(StoryLines.INVITE_TABLE, NotePage.TYPED, 13, WORDS_WIDE):
		y = _centered(row, NotePage.TYPED, 13, FOIL_FAINT, y)


## [param words] centered across the card at [param y], spaced out by [param spacing]; where the
## next line goes.
func _centered(
	words: String, font: Font, font_size: int, ink: Color, y: float, spacing := 0.0
) -> float:
	var shown := words
	if spacing > 0.0:
		shown = " ".join(words.split(""))
	var wide := font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(
		font,
		Vector2((SIZE.x - wide) * 0.5, y + font.get_ascent(font_size)),
		shown,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		ink
	)
	return y + font.get_height(font_size) * 1.05


## The House's back: a lattice in foil inside the edge and the seal in gold in the middle.
func _draw_back() -> void:
	var field := Rect2(Vector2.ONE * 30.0, SIZE - Vector2.ONE * 60.0)
	var step := 26.0
	var x := field.position.x - field.size.y
	while x < field.end.x:
		for way: float in [1.0, -1.0]:
			var from := Vector2(x, field.position.y)
			var to := from + Vector2(field.size.y * way, field.size.y)
			if way < 0.0:
				from.x += field.size.y
				to.x += field.size.y
			var clipped := _clip(from, to, field)
			if clipped.size() == 2:
				draw_line(clipped[0], clipped[1], Color(FOIL, 0.22), 1.0, true)
		x += step
	var middle := SIZE * 0.5
	draw_circle(middle, SEAL_RINGS[0] + 14.0, CARD)
	_draw_seal(middle, true)


## The part of the line from [param from] to [param to] inside [param box], or nothing.
static func _clip(from: Vector2, to: Vector2, box: Rect2) -> PackedVector2Array:
	var t0 := 0.0
	var t1 := 1.0
	var d := to - from
	for axis: int in 2:
		var low := box.position[axis]
		var high := box.end[axis]
		if absf(d[axis]) < 0.0001:
			if from[axis] < low or from[axis] > high:
				return PackedVector2Array()
			continue
		var a := (low - from[axis]) / d[axis]
		var b := (high - from[axis]) / d[axis]
		t0 = maxf(t0, minf(a, b))
		t1 = minf(t1, maxf(a, b))
	if t0 > t1:
		return PackedVector2Array()
	return PackedVector2Array([from + d * t0, from + d * t1])
