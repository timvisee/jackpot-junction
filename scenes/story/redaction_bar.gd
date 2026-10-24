class_name RedactionBar
extends Control
## A black marker bar drawn over a setting's value at the Final Hand, STORY.md 8.1: the settings
## are there, and the player is not to know what they are. Swiped on from the left after
## [member delay], its edges a little uneven and soft where the ink bled into the paper, and its end
## ragged where the marker lifted, the same every time for the same bar: solid black through, as a
## marker leaves it. The strokes it once showed faintly along it read as gray lines through the
## black. It covers what holds it and takes no clicks.

const INK := Color(0.025, 0.024, 0.03)
## The ink bled a little past the bar's edges, and how far.
const BLEED := Color(0.025, 0.024, 0.03, 0.3)
const BLEED_BY := 1.4
## How long a swipe takes, and how far past what it covers the bar runs.
const SWIPE := 0.2
const OVER := Vector2(6.0, 3.0)

## How long it waits before it is swiped on.
var delay := 0.0
var _drawn := 0.0


## A bar over [param what], swiped on after [param wait].
static func over(what: Control, wait: float) -> RedactionBar:
	var bar := RedactionBar.new()
	bar.name = "Redacted"
	bar.delay = wait
	what.add_child(bar)
	return bar


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = -OVER.x
	offset_right = OVER.x
	offset_top = -OVER.y
	offset_bottom = OVER.y


func _process(delta: float) -> void:
	if delay > 0.0:
		delay -= delta
		return
	_drawn = minf(_drawn + delta / SWIPE, 1.0)
	queue_redraw()
	if _drawn >= 1.0:
		set_process(false)


## Whether it is all the way across.
func done() -> bool:
	return _drawn >= 1.0


func _draw() -> void:
	if _drawn <= 0.0:
		return
	mark(self, Rect2(Vector2.ZERO, Vector2(size.x * _drawn, size.y)), hash(get_parent().name))


## A marker bar filling [param rect] on [param canvas], its edges a little uneven and bled and its
## right end ragged where the marker lifted, the same each time for the same [param grain]: the look
## of a line struck out by hand in heavy ink, drawn solid rather than swiped on, see [NoteCharts].
static func mark(canvas: CanvasItem, rect: Rect2, grain: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = grain
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	var steps := maxi(int(rect.size.x / 18.0), 2)
	for i: int in steps + 1:
		var x := rect.position.x + rect.size.x * float(i) / float(steps)
		top.append(Vector2(x, rect.position.y + rng.randf_range(0.0, 3.0)))
		bottom.append(Vector2(x, rect.end.y - rng.randf_range(0.0, 3.0)))
	# The ragged end, where the marker came off the paper.
	var shape := top
	shape.append(Vector2(rect.end.x + 4.0, rect.position.y + rect.size.y * 0.3))
	shape.append(Vector2(rect.end.x - 2.0, rect.position.y + rect.size.y * 0.55))
	shape.append(Vector2(rect.end.x + 3.0, rect.position.y + rect.size.y * 0.8))
	bottom.reverse()
	shape.append_array(bottom)
	# Its edges soft, where the ink bled into the paper either side of the stroke.
	for by: Vector2 in [Vector2(0.0, -BLEED_BY), Vector2(0.0, BLEED_BY), Vector2(BLEED_BY, 0.0)]:
		canvas.draw_colored_polygon(Transform2D(0.0, by) * shape, BLEED)
	canvas.draw_colored_polygon(shape, INK)
