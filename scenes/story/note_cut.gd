class_name NoteCut
extends Control
## A hole cut in a note's picture so what is behind shows through rather than paper, STORY.md 7.3:
## a dog-ear's folded-away corner, see [method NoteWear.dogear], or the sprocket holes of
## continuous-form paper, see [method NoteCharts.feed_holes]. A child drawn after the note, its
## shader writing nothing but transparency where it draws, so the picture is left see-through there
## instead of painted over -- a plain draw can only add, never take paper away.

## Shared by every cut: it turns blending off and writes a clear pixel, which replaces the paper.
const SHADER: Shader = preload("res://scenes/story/note_cut.gdshader")

## A polygon to cut, in the note's own coordinates, or empty.
var hole := PackedVector2Array()
## Round holes to cut, their centres in the note's own coordinates, each [member dot_radius] across.
var dots := PackedVector2Array()
var dot_radius := 0.0


## A polygon hole over [param note] at [param shape], in the note's coordinates. Added last so it is
## drawn over everything the note drew.
static func over(note: Control, shape: PackedVector2Array) -> NoteCut:
	var cut := _new_cut()
	cut.hole = shape
	note.add_child(cut)
	return cut


## Round holes over [param note], one of [param radius] at each of [param centers], in the note's
## coordinates; added last so they are cut over everything the note drew.
static func holes(note: Control, centers: PackedVector2Array, radius: float) -> NoteCut:
	var cut := _new_cut()
	cut.dots = centers
	cut.dot_radius = radius
	note.add_child(cut)
	return cut


## A cutter ready to add to a note: set up with the erase shader, nothing to cut yet.
static func _new_cut() -> NoteCut:
	var cut := NoteCut.new()
	cut.name = "Cut"
	cut.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cut.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var material := ShaderMaterial.new()
	material.shader = SHADER
	cut.material = material
	return cut


func _draw() -> void:
	if hole.size() >= 3:
		draw_colored_polygon(hole, Color.WHITE)
	for dot: Vector2 in dots:
		draw_circle(dot, dot_radius, Color.WHITE)
