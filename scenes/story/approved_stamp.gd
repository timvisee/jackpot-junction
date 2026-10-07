class_name ApprovedStamp
extends Control
## The House's stamp as it comes down, STORY.md 8.4 and 8.6: two gold rings with APPROVED across
## them, THE HOUSE over the word and the date under it, askew and a little short of solid, as a
## rubber stamp comes out. On the evaluation over STATUS, on the license over its lower left corner,
## and on Terms Accepted's card. [method draw_on] draws it on any canvas.

const INK := Color(0.86, 0.66, 0.24, 0.88)
const TILT := -0.18

## When it came down, under the word.
var date := ""
## How big across it is.
var radius := 46.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2.ONE * radius * 2.2


func _draw() -> void:
	draw_on(self, size * 0.5, radius, date, TILT)


## The stamp on [param canvas], its middle at [param middle], [param across] its outer radius,
## dated [param when], turned by [param tilt].
static func draw_on(
	canvas: CanvasItem, middle: Vector2, across: float, when: String, tilt: float
) -> void:
	var font := Type.display_font()
	canvas.draw_set_transform(middle, tilt, Vector2.ONE)
	canvas.draw_arc(Vector2.ZERO, across, 0.0, TAU, 64, INK, across * 0.07, true)
	canvas.draw_arc(Vector2.ZERO, across * 0.8, 0.0, TAU, 64, INK, across * 0.035, true)
	var band := Rect2(
		Vector2(-across * 1.12, -across * 0.24), Vector2(across * 2.24, across * 0.48)
	)
	canvas.draw_rect(band, Color(INK, 0.16))
	canvas.draw_rect(band, INK, false, across * 0.035)
	_centered(canvas, font, StoryLines.STAMP_WORD, Vector2(0.0, across * 0.15), across * 0.42)
	_centered(canvas, font, StoryLines.STAMP_OVER, Vector2(0.0, -across * 0.42), across * 0.2)
	if not when.is_empty():
		_centered(canvas, font, when, Vector2(0.0, across * 0.58), across * 0.18)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _centered(
	canvas: CanvasItem, font: Font, text: String, at: Vector2, tall: float
) -> void:
	var font_size := maxi(roundi(tall), 6)
	var wide := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	canvas.draw_string(
		font, at - Vector2(wide * 0.5, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK
	)
