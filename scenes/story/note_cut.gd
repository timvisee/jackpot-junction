class_name NoteCut
extends Control
## A hole cut in a note's picture so what is behind shows through rather than paper, STORY.md 7.3:
## a dog-ear's folded-away corner, see [method NoteWear.dogear]. A child drawn after the note, its
## shader writing nothing but transparency where its polygon is, so the picture is left see-through
## there instead of painted over -- a plain draw can only add, never take paper away.

## Shared by every cut: it turns blending off and writes a clear pixel, which replaces the paper.
static var _shader: Shader

## The hole, in the note's own coordinates.
var hole := PackedVector2Array()


## A hole over [param note] at [param shape], in the note's coordinates. Added last so it is drawn
## over everything the note drew.
static func over(note: Control, shape: PackedVector2Array) -> NoteCut:
	var cut := NoteCut.new()
	cut.name = "Cut"
	cut.hole = shape
	cut.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cut.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _shader == null:
		_shader = Shader.new()
		_shader.code = (
			"shader_type canvas_item;\nrender_mode blend_disabled;\n"
			+ "void fragment() {\n\tCOLOR = vec4(0.0);\n}\n"
		)
	var material := ShaderMaterial.new()
	material.shader = _shader
	cut.material = material
	note.add_child(cut)
	return cut


func _draw() -> void:
	if hole.size() >= 3:
		draw_colored_polygon(hole, Color.WHITE)
