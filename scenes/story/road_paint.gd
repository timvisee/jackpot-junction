class_name RoadPaint
extends MeshInstance3D
## The word the House paints on the road, in its box across one open lane, STORY.md 6.1: old road
## paint, flush with the floor, worn thin along the line the karts take and chipped at its edges,
## readable from close by. The box and the letters are drawn once into a picture of their own, and
## [code]road_paint.gdshader[/code] wears them where they lie.

const SHADER := preload("res://scenes/story/road_paint.gdshader")
## How finely the picture is drawn, in pixels to a meter.
const PER_METER := 96.0
## The box's line, in meters; how much taller than wide the letters are stretched, the way a road
## stretches them to read from a low angle; and how much of the box they fill.
const LINE := 0.09
const STRETCH := 1.7
const FILL := Vector2(0.86, 0.6)
const FONT_SIZE := 96

## The words painted, as filled in for the profile playing.
var text := ""
## The box, in meters across and deep.
var box := Vector2.ONE

var _canvas: Control


## The box [param size] meters across and deep with [param words] in it, in [param ink].
static func make(words: String, size: Vector2, ink: Color) -> RoadPaint:
	var painted := RoadPaint.new()
	painted.text = words
	painted.box = size
	var plane := PlaneMesh.new()
	plane.size = size
	painted.mesh = plane
	painted.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var viewport := SubViewport.new()
	viewport.name = "Paint"
	viewport.size = Vector2i((size * PER_METER).round())
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	painted.add_child(viewport)
	painted._canvas = Control.new()
	painted._canvas.size = Vector2(viewport.size)
	painted._canvas.draw.connect(painted._draw_paint)
	viewport.add_child(painted._canvas)
	painted.material_override = material(viewport.get_texture(), ink)
	return painted


## The worn paint's material for [param picture] in [param ink], for the box and for warming up.
static func material(picture: Texture2D, ink: Color) -> ShaderMaterial:
	var skin := ShaderMaterial.new()
	skin.shader = SHADER
	skin.set_shader_parameter(&"paint", picture)
	skin.set_shader_parameter(&"ink", ink)
	return skin


## The box's line round the edge and the words in the middle, white on nothing: the shader inks
## and wears them.
func _draw_paint() -> void:
	var area := _canvas.size
	var line := LINE * PER_METER
	var edge := Rect2(Vector2.ONE * line * 0.5, area - Vector2.ONE * line)
	_canvas.draw_rect(edge, Color.WHITE, false, line)
	var font := Type.display_font()
	var span := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	if span.x <= 0.0:
		return
	var room := area * FILL
	var by := minf(room.x / span.x, room.y / (STRETCH * font.get_height(FONT_SIZE)))
	var scale := Vector2(by, by * STRETCH)
	var middle := area * 0.5
	# The text's middle on the box's: half the width back, and the baseline half a line down from
	# the middle of the letters.
	var ascent := font.get_ascent(FONT_SIZE)
	var descent := font.get_descent(FONT_SIZE)
	var at := Vector2(-span.x * 0.5, (ascent - descent) * 0.5)
	_canvas.draw_set_transform(middle, 0.0, scale)
	_canvas.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
	_canvas.draw_set_transform(Vector2.ZERO)
