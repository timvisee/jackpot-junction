class_name LostTag
extends Control
## The Department's manila tag for a thing of Lost Property lying in this map, GAME.md 8.9 and
## STORY.md 6.6b, hung on its string off the left of the clock's board as Kit's note's scrap hangs
## off the right, see [NoteMark], for as long as the thing lies on the floor: filled in by hand,
## FOUND, the room and what it is, UNCLAIMED, and from the story's second stage a line under it.
## Taken, it is stamped CLAIMED in red and goes. This machine's alone, as the thing is, see
## [LostProperty].

const SIZE := Vector2(184.0, 64.0)
const GAP := 14.0
const LEAN := -0.08
const MANILA := Color("#d8b77e")
const MANILA_DARK := Color("#a98a52")
const INK := Color(0.2, 0.17, 0.12)
const STRING := Color(0.9, 0.88, 0.8)
const DROP := 0.32
const CLAIMED_FOR := 1.6
const FADE := 0.4

var landmark: LoyaltyLandmark
var claimed := false
var _stamp := 0.0


## The tag for [param lost] hung beside [param clock], the HUD's clock board.
static func hang_on(clock: Control, lost: LoyaltyLandmark) -> LostTag:
	var tag := LostTag.new()
	tag.name = "LostTag"
	tag.landmark = lost
	tag.size = SIZE
	tag.pivot_offset = Vector2(SIZE.x, SIZE.y * 0.5)
	tag.position = Vector2(-GAP - SIZE.x, (ClockBoard.TALL - SIZE.y) * 0.5)
	tag.rotation = LEAN
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock.add_child(tag)
	return tag


## What the tag says, its lines in order: FOUND and the room and the thing, UNCLAIMED, and from
## the story's second stage its own line, STORY.md 6.6b.
static func lines_for(lost: LoyaltyLandmark, stage: int) -> PackedStringArray:
	var said := PackedStringArray()
	said.append(StoryLines.LOST_FOUND)
	said.append(str(StoryLines.LOST_WHERE.get(lost.id, lost.title)).to_upper())
	said.append(StoryLines.LOST_UNCLAIMED)
	if stage >= Story.Stage.PARTICIPANT:
		var line: String = StoryLines.LOST_LINES.get(lost.id, "")
		if not line.is_empty():
			said.append(line)
	return said


func _ready() -> void:
	scale = Vector2.ONE * 1.5
	modulate.a = 0.0
	var drop := create_tween().set_parallel()
	drop.tween_property(self, "scale", Vector2.ONE, DROP).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	drop.tween_property(self, "modulate:a", 1.0, DROP * 0.5)


## The thing taken: stamped CLAIMED, and gone a moment after.
func claim() -> void:
	if claimed:
		return
	claimed = true
	var going := create_tween()
	going.tween_method(
		func(by: float) -> void:
			_stamp = by
			queue_redraw(),
		0.0,
		1.0,
		0.15
	)
	going.tween_interval(CLAIMED_FOR)
	going.tween_property(self, "modulate:a", 0.0, FADE)
	going.tween_callback(queue_free)


func _draw() -> void:
	# The tag: its end cut to a point at the string's side, a ring for the string's hole.
	var cut := 16.0
	var shape := PackedVector2Array(
		[
			Vector2(0.0, 0.0),
			Vector2(SIZE.x - cut, 0.0),
			Vector2(SIZE.x, cut),
			Vector2(SIZE.x, SIZE.y - cut),
			Vector2(SIZE.x - cut, SIZE.y),
			Vector2(0.0, SIZE.y),
		]
	)
	var shadow := PackedVector2Array()
	for point: Vector2 in shape:
		shadow.append(point + Vector2(3.0, 4.0))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.4))
	draw_colored_polygon(shape, MANILA)
	var hole := Vector2(SIZE.x - 12.0, SIZE.y * 0.5)
	draw_circle(hole, 6.0, MANILA_DARK)
	draw_circle(hole, 3.0, Color(0.1, 0.1, 0.1, 0.9))
	draw_line(hole, hole + Vector2(GAP + 6.0, -4.0), STRING, 1.6, true)
	var lines := lines_for(landmark, Story.stage_here())
	var hand := NotePage.HAND
	for i: int in mini(lines.size(), 4):
		var size_of := 15 if i < 3 else 11
		var at := Vector2(8.0, 16.0 + i * 14.0)
		draw_string(hand, at, lines[i], HORIZONTAL_ALIGNMENT_LEFT, SIZE.x - 28.0, size_of, INK)
	if _stamp > 0.0:
		draw_set_transform(SIZE * 0.45, -0.18, Vector2.ONE * lerpf(1.4, 1.0, _stamp))
		var box := Rect2(Vector2(-56.0, -15.0), Vector2(112.0, 30.0))
		draw_rect(box, Color(HouseTheme.STAMP_RED, 0.9 * _stamp), false, 2.4)
		draw_string(
			Type.display_font(),
			Vector2(-56.0, 9.0),
			StoryLines.LOST_CLAIMED,
			HORIZONTAL_ALIGNMENT_CENTER,
			112.0,
			22,
			Color(HouseTheme.STAMP_RED, 0.9 * _stamp)
		)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
