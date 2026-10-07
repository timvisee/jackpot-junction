class_name NoteOnPage
extends Control
## A note as Kit put it into the folder, STORY.md 7.2: laid on its page by hand, a little askew and
## off-center, and held there by whatever was to hand, a paper clip over its top left corner, a
## strip of tape across its top, a strip over each top corner, or a staple through its top left
## corner. Which and how far are the note's own, the same every time. This is what holds it, drawn
## over the note; [method lay] lays the note and puts it on.

## How far a note may lie turned, in radians, and off-center, in pixels of the page, and the room it
## keeps from the page's edge however it lies.
const ASKEW := 0.045
const SHIFT := 9.0
const EDGE := 4.0
const KINDS: Array[StringName] = [&"clip", &"tape", &"tapes", &"staple"]
## Tape: its color, how wide a strip is, and how long; a staple's steel.
const TAPE := Color(0.93, 0.9, 0.77, 0.72)
const TAPE_EDGE := Color(0.66, 0.63, 0.52, 0.45)
const TAPE_SHADOW := Color(0.0, 0.0, 0.0, 0.08)
const TAPE_WIDE := 17.0
const TAPE_LONG := 70.0
const STEEL := Color(0.6, 0.61, 0.65)

## What holds the note, one of [constant KINDS], and where its paper lies, before it is turned.
var kind := &"clip"
var rect := Rect2()


## Note [param page]'s note laid on it, a child of its own drawn as it lies there, and what holds
## it over it, both turned and moved the same.
static func lay(page: NotePage) -> void:
	var note := NotePage.make(page.number, page.profile)
	note.name = "Note"
	note.layer = &"lying"
	var paper := note.paper_rect()
	var rng := RandomNumberGenerator.new()
	rng.seed = page.number * 104729 + 17
	# Turned no further than leaves the page's edges clear, and moved within what is left.
	var room := (NotePage.SIZE.x - paper.size.x) * 0.5 - EDGE
	var most := clampf(room / (paper.size.y * 0.5), 0.0, ASKEW)
	var turn := rng.randf_range(-most, most)
	var spare := maxf(room - absf(sin(turn)) * paper.size.y * 0.5, 0.0)
	var shift := Vector2(
		clampf(rng.randf_range(-SHIFT, SHIFT), -spare, spare), rng.randf_range(-SHIFT, SHIFT) * 0.5
	)
	var held := NoteOnPage.new()
	held.name = "Held"
	held.kind = StringName(
		StoryNotes.NOTES.get(page.number, {}).get("held", KINDS[rng.randi() % 4])
	)
	held.rect = paper
	for part: Control in [note, held]:
		part.size = NotePage.SIZE
		part.mouse_filter = Control.MOUSE_FILTER_IGNORE
		part.pivot_offset = paper.get_center()
		part.rotation = turn
		part.position = shift
		page.add_child(part)


func _draw() -> void:
	match kind:
		&"tape":
			_tape(Vector2(rect.get_center().x, rect.position.y), TAPE_LONG, 0.04)
		&"tapes":
			_tape(rect.position + Vector2(8.0, 8.0), TAPE_LONG * 0.7, -PI * 0.25)
			_tape(Vector2(rect.end.x - 8.0, rect.position.y + 8.0), TAPE_LONG * 0.7, PI * 0.25)
		&"staple":
			_staple(rect.position + Vector2(18.0, 16.0), -PI * 0.25)
		_:
			NotePaper.draw_clip(self, rect)


## A strip of tape [param long] long across [param middle], turned by [param angle]: see-through,
## its ends torn rather than cut.
func _tape(middle: Vector2, long: float, angle: float) -> void:
	draw_set_transform(middle, angle, Vector2.ONE)
	var half := Vector2(long, TAPE_WIDE) * 0.5
	var outline := PackedVector2Array()
	var teeth := 5
	for i: int in teeth + 1:
		var y := -half.y + TAPE_WIDE * float(i) / float(teeth)
		outline.append(Vector2(-half.x + (2.0 if i % 2 == 0 else 0.0), y))
	for i: int in range(teeth, -1, -1):
		var y := -half.y + TAPE_WIDE * float(i) / float(teeth)
		outline.append(Vector2(half.x - (2.0 if i % 2 == 1 else 0.0), y))
	var under := PackedVector2Array()
	for point: Vector2 in outline:
		under.append(point + Vector2(0.8, 1.4))
	draw_colored_polygon(under, TAPE_SHADOW)
	draw_colored_polygon(outline, TAPE)
	draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), TAPE_EDGE, 1.0, true)
	draw_line(Vector2(-half.x, half.y), Vector2(half.x, half.y), TAPE_EDGE, 1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A staple through the paper at [param middle], turned by [param angle]: its crown over the paper,
## its legs going in at either end.
func _staple(middle: Vector2, angle: float) -> void:
	draw_set_transform(middle, angle, Vector2.ONE)
	var half := 9.0
	draw_line(Vector2(-half, 1.2), Vector2(half, 1.2), Color(0.0, 0.0, 0.0, 0.3), 2.6, true)
	draw_line(Vector2(-half, 0.0), Vector2(half, 0.0), STEEL, 2.2, true)
	draw_line(Vector2(-half, 0.0), Vector2(-half + 1.0, 1.0), STEEL.darkened(0.3), 1.6, true)
	draw_line(Vector2(half, 0.0), Vector2(half - 1.0, 1.0), STEEL.darkened(0.3), 1.6, true)
	draw_line(Vector2(-half + 2.5, -0.7), Vector2(half - 2.5, -0.7), STEEL.lightened(0.35), 0.8)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
