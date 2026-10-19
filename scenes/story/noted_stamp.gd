class_name NotedStamp
extends Control
## The House's note of the strip torn off its evaluation at the Final Hand, STORY.md 8.4: a filing
## clerk's rubber stamp in the slip's ink, a box round EVALUATION DECLINED and under it, smaller,
## NOTED. THE HOUSE WILL ASK AGAIN., askew and a little short of solid, slammed down over the foot
## of what is left of the evaluation once the strip has gone. Over the paper rather than on a line
## of its own, so the slip does not grow for it.

const INK := Color(0.16, 0.16, 0.2, 0.74)
const TILT := -0.06
## How big its two lines are set, and the room inside its box.
const BIG := 30
const SMALL := 14
const ROOM := Vector2(22.0, 12.0)
## How long it takes to come down, and how much bigger it is as it starts to.
const LAND := 0.16
const GROW := 1.5

## Its two lines, the big one and the one under it.
var big := ""
var small := ""

var _age := 0.0
## The page it lies over, and the line it comes down on.
var _over: Control
var _line: Control


## Slammed down on [param line] of [param page], the last left on it, across the page's middle:
## put in the line's dotted leader, which lays nothing out, so it moves with the line.
static func down_on(page: Control, line: Control) -> NotedStamp:
	var stamp := NotedStamp.new()
	stamp.name = "Declined"
	var parts := StoryLines.EVALUATION_DECLINED.split("  ·  ", false, 1)
	stamp.big = parts[0]
	stamp.small = parts[1] if parts.size() > 1 else ""
	stamp._over = page
	stamp._line = line
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Over the line's own words, which come after the leader.
	stamp.z_index = 1
	var host := line.get_child(1) as Control if line.get_child_count() > 1 else line
	host.add_child(stamp)
	return stamp


## What it says, as a screen reader is told it.
func said() -> String:
	return "%s  ·  %s" % [big, small] if not small.is_empty() else big


func _ready() -> void:
	var display := Type.display_font()
	var typed := Type.numbers_text_font()
	var wide := maxf(
		display.get_string_size(big, HORIZONTAL_ALIGNMENT_LEFT, -1, BIG).x,
		typed.get_string_size(small, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL).x
	)
	size = Vector2(wide, float(BIG) * 0.95 + float(SMALL) * 1.4) + ROOM * 2.0
	pivot_offset = size * 0.5
	rotation = TILT
	Audio.play_sfx(&"stamp", -4.0, 0.05)
	ScreenReader.say(self, said())
	_place()


func _process(delta: float) -> void:
	_age += delta
	_place()
	var landed := clampf(_age / LAND, 0.0, 1.0)
	scale = Vector2.ONE * lerpf(GROW, 1.0, ease(landed, 0.5))
	modulate.a = landed
	if landed >= 1.0:
		set_process(false)


## Across the middle of the page, a little over the line it comes down on.
func _place() -> void:
	if _over == null or not is_instance_valid(_over) or not is_instance_valid(_line):
		return
	var line := _line.get_global_rect()
	var middle := Vector2(_over.get_global_rect().get_center().x, line.get_center().y - 16.0)
	global_position = middle - size * 0.5


func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	draw_rect(box, Color(INK, INK.a * 0.08))
	draw_rect(box, INK, false, 3.0)
	draw_rect(box.grow(-5.0), INK, false, 1.2)
	var display := Type.display_font()
	var typed := Type.numbers_text_font()
	var big_wide := display.get_string_size(big, HORIZONTAL_ALIGNMENT_LEFT, -1, BIG).x
	var top := ROOM.y + float(BIG) * 0.82
	draw_string(
		display,
		Vector2((size.x - big_wide) * 0.5, top),
		big,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		BIG,
		INK
	)
	var small_wide := typed.get_string_size(small, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL).x
	draw_string(
		typed,
		Vector2((size.x - small_wide) * 0.5, top + float(SMALL) * 1.45),
		small,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		SMALL,
		INK
	)
