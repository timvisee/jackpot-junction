class_name RedactionBar
extends Control
## A black marker bar drawn over a setting's value at the Final Hand, STORY.md 8.1: the settings
## are there, and the player is not to know what they are. Swiped on from the left after
## [member delay], its edges a little uneven and its end ragged where the marker lifted, the same
## every time for the same bar. It covers what holds it and takes no clicks.

const INK := Color(0.025, 0.024, 0.03)
const STREAK := Color(1.0, 1.0, 1.0, 0.035)
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
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(get_parent().name)
	var wide := size.x * _drawn
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	var steps := maxi(int(wide / 18.0), 2)
	for i: int in steps + 1:
		var x := wide * float(i) / float(steps)
		top.append(Vector2(x, rng.randf_range(0.0, 3.0)))
		bottom.append(Vector2(x, size.y - rng.randf_range(0.0, 3.0)))
	# The ragged end, where the marker came off the paper.
	var shape := top
	shape.append(Vector2(wide + 4.0, size.y * 0.3))
	shape.append(Vector2(wide - 2.0, size.y * 0.55))
	shape.append(Vector2(wide + 3.0, size.y * 0.8))
	bottom.reverse()
	shape.append_array(bottom)
	draw_colored_polygon(shape, INK)
	# The marker's strokes showing faintly along it.
	for i: int in 3:
		var y := size.y * (0.25 + 0.25 * float(i))
		draw_line(Vector2(4.0, y), Vector2(maxf(wide - 8.0, 4.0), y + 1.0), STREAK, 2.0)
