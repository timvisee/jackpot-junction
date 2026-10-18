class_name KitPencil
extends Control
## Kit's pencil on the House's page at the Final Hand, STORY.md 8.4: the one mark on it that is not
## the House's, under its line on how to bring the stamp down, a line of Kit's hand and an arrow
## round under the stamp to the tab the page tears off by, see [TearTab]. Laid out as a row of the
## page, see [HouseEvaluation], it draws past its own edges as pencil does.

const SIZE := 28
const TALL := 34.0
const TILT := -0.03
const ARROW_HEAD := 11.0

## Where the line ends on the right, and where the arrow points, both in its own coordinates;
## nothing drawn while [member points_to] is not finite.
var right_end := 0.0:
	set = _set_right_end
var points_to := Vector2.INF:
	set = _set_points_to


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, TALL)


func _set_right_end(value: float) -> void:
	if not is_equal_approx(value, right_end):
		right_end = value
		queue_redraw()


func _set_points_to(value: Vector2) -> void:
	if value != points_to:
		points_to = value
		queue_redraw()


func _draw() -> void:
	if not points_to.is_finite():
		return
	var font := NotePage.HAND
	var said := StoryLines.KIT_TEAR
	var wide := font.get_string_size(said, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
	var at := Vector2(right_end - wide, TALL * 0.72)
	draw_set_transform(at, TILT, Vector2.ONE)
	draw_string(font, Vector2.ZERO, said, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, KitCards.PENCIL)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Round under the stamp from the line's end to the tab, a hand's curve rather than a rule's.
	var from := Vector2(right_end + 8.0, TALL * 0.5)
	var bend := Vector2(lerpf(from.x, points_to.x, 0.5), TALL * 1.45)
	var points := PackedVector2Array()
	for i: int in 17:
		var t := float(i) / 16.0
		points.append(from.lerp(bend, t).lerp(bend.lerp(points_to, t), t))
	var ink := Color(KitCards.PENCIL, 0.85)
	draw_polyline(points, ink, 2.0, true)
	var going := (points_to - points[points.size() - 2]).normalized()
	var side := Vector2(-going.y, going.x)
	for way: float in [1.0, -1.0]:
		draw_line(points_to, points_to - going * ARROW_HEAD + side * way * 6.0, ink, 2.0, true)
