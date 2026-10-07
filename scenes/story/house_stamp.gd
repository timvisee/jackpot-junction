class_name HouseStamp
extends Control
## A word of the House's stamped across what holds it, STORY.md 8.1: in a box, in the House's gold,
## a little askew and a little short of solid, as rubber stamps come out. Over the match settings
## of the Final Hand it reads SET BY THE HOUSE. It takes no clicks.

const INK := Color(HouseTheme.FOIL, 0.82)
const TILT := -0.09
const SIZE := 34

var word := ""
## Where on what holds it the stamp's middle comes down, as a share of its size.
var at := Vector2(0.5, 0.5)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	var font := Type.display_font()
	var wide := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
	var tall := font.get_ascent(SIZE)
	draw_set_transform(size * at, TILT, Vector2.ONE)
	var box := Rect2(
		Vector2(-wide * 0.5 - 18.0, -tall * 0.5 - 14.0), Vector2(wide + 36.0, tall + 28.0)
	)
	draw_rect(box, INK, false, 4.0)
	draw_rect(box.grow(-7.0), Color(INK, 0.5), false, 1.5)
	draw_string(
		font, Vector2(-wide * 0.5, tall * 0.5), word, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, INK
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
