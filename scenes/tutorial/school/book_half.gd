class_name BookHalf
extends Control
## One half of the leather round the pages of the driving school's theory book, GAME.md 9.4a,
## [member side] 0 for the left: the cover with the spine along its inner edge, the edges of the
## leaves showing along the outside of the block, and, drawn over the page by [member over_page],
## the shade the page falls into at the spine. See [SchoolTheory].

var side := 0
var over_page := false


func _draw() -> void:
	var inner := side == 0
	var width := size.x
	if over_page:
		_draw_gutter(inner, width)
		return
	var leather := StyleBoxFlat.new()
	leather.bg_color = SchoolTheory.COVER_INK
	leather.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	leather.shadow_size = 18
	_outer_corners(leather, inner, 10)
	draw_style_box(leather, Rect2(Vector2.ZERO, size))
	var light := StyleBoxFlat.new()
	light.bg_color = SchoolTheory.COVER_LIGHT
	_outer_corners(light, inner, 8)
	var inset := Rect2(Vector2(3.0, 3.0), size - Vector2(6.0, 6.0))
	if inner:
		inset.size.x += 3.0
	else:
		inset.position.x -= 3.0
		inset.size.x += 3.0
	draw_style_box(light, inset)
	var tooled := StyleBoxFlat.new()
	tooled.draw_center = false
	tooled.set_border_width_all(1)
	tooled.border_color = SchoolTheory.TOOLING
	_outer_corners(tooled, inner, 6)
	draw_style_box(tooled, Rect2(Vector2(8.0, 8.0), size - Vector2(16.0, 16.0)))
	# The spine, along the inner edge.
	var spine_x := width - SchoolTheory.GUTTER * 0.5 - 4.0 if inner else 0.0
	draw_rect(
		Rect2(Vector2(spine_x, 0.0), Vector2(SchoolTheory.GUTTER * 0.5 + 4.0, size.y)),
		SchoolTheory.SPINE_INK
	)
	# The leaves under the page, stepped out toward the fore-edge and the foot.
	var away := -1.0 if inner else 1.0
	var page_at := Vector2(
		SchoolTheory.COVER if inner else SchoolTheory.GUTTER * 0.5, SchoolTheory.COVER
	)
	for i: int in SchoolTheory.LEAVES:
		var step := float(SchoolTheory.LEAVES - i) * 1.5
		var rect := Rect2(page_at + Vector2(away * step, step), SchoolTheory.PAGE)
		draw_rect(rect, SchoolTheory.LEAF.darkened(0.05 * float(i)))
		draw_rect(rect, SchoolTheory.PAPER_EDGE, false, 1.0)


## Rounded on the outer corners alone: the inner edge is the spine, and square.
static func _outer_corners(style: StyleBoxFlat, inner: bool, radius: int) -> void:
	style.corner_radius_top_left = radius if inner else 0
	style.corner_radius_bottom_left = radius if inner else 0
	style.corner_radius_top_right = 0 if inner else radius
	style.corner_radius_bottom_right = 0 if inner else radius


func _draw_gutter(inner: bool, width: float) -> void:
	for i: int in 8:
		var reach := 4.0 + float(i) * 3.0
		var shade := Color(0.0, 0.0, 0.0, 0.07 - float(i) * 0.008)
		var x := (
			width - SchoolTheory.GUTTER * 0.5 - reach
			if inner
			else SchoolTheory.GUTTER * 0.5 + reach - 3.0
		)
		draw_rect(Rect2(Vector2(x, SchoolTheory.COVER), Vector2(3.0, SchoolTheory.PAGE.y)), shade)
