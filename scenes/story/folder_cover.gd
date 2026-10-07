class_name FolderCover
extends RefCounted
## The front of Kit's folder, STORY.md 7.2: plain manila with nothing of the House's on it, DO NOT
## FILE written across it in black marker, an eye drawn in pen and crossed out over it, and a pencil
## K. in the corner. Drawn the same on the folder peeking in from the title's edge and on the cover
## that swings open, at whatever size it is given; laid out for the open folder's cover, see
## [constant WIDE], and scaled from it.

## The cover these are laid out for, across; anything else is drawn in proportion.
const WIDE := 460.0
const MARKER_INK := Color(0.07, 0.07, 0.08, 0.9)
const MARKER_SIZE := 58
## The most of the cover's width the marker's words may take.
const MARKER_SHARE := 0.86
const TILT := -0.07
## The eye: where on the cover, how wide, how thick its pen.
const EYE_AT := Vector2(0.74, 0.22)
const EYE_HALF := 36.0
const PEN_WIDTH := 2.4
const K_SIZE := 44


## The cover's front in [param rect] of [param canvas]: the marker, the eye and the K.
static func draw_front(canvas: CanvasItem, rect: Rect2) -> void:
	var unit := rect.size.x / WIDE
	var size := maxi(roundi(MARKER_SIZE * unit), 6)
	var font := NotePage.MARKER
	var words := StoryLines.FOLDER_FRONT
	var wide := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	# Written as big as fits across the cover with a margin either side.
	while size > 6 and wide > rect.size.x * MARKER_SHARE:
		size -= 1
		wide = font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var middle := rect.position + rect.size * Vector2(0.5, 0.56)
	canvas.draw_set_transform(middle, TILT, Vector2.ONE)
	canvas.draw_string(
		font,
		Vector2(-wide * 0.5, size * 0.35),
		words,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		MARKER_INK
	)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_eye(canvas, rect.position + rect.size * EYE_AT, EYE_HALF * unit, unit)
	canvas.draw_string(
		NotePage.HAND,
		rect.end - Vector2(64.0, 22.0) * unit,
		"K.",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		maxi(roundi(K_SIZE * unit), 6),
		NotePage.PENCIL
	)


## An eye in pen, [param half] wide each way from [param at], and two strokes through it.
static func _draw_eye(canvas: CanvasItem, at: Vector2, half: float, unit: float) -> void:
	var width := maxf(PEN_WIDTH * unit, 1.0)
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for i: int in 17:
		var t := float(i) / 16.0
		var x := -half + 2.0 * half * t
		upper.append(at + Vector2(x, -sin(t * PI) * half * 0.55))
		lower.append(at + Vector2(x, sin(t * PI) * half * 0.42))
	canvas.draw_polyline(upper, NotePage.PEN_INK, width, true)
	canvas.draw_polyline(lower, NotePage.PEN_INK, width, true)
	canvas.draw_arc(at, half * 0.34, 0.0, TAU, 24, NotePage.PEN_INK, width, true)
	canvas.draw_circle(at, half * 0.15, NotePage.PEN_INK)
	for side: float in [-1.0, 1.0]:
		canvas.draw_line(
			at + Vector2(-half * 1.15, -half * 0.8 * side),
			at + Vector2(half * 1.15, half * 0.8 * side),
			NotePage.PEN_INK,
			width * 1.3,
			true
		)
