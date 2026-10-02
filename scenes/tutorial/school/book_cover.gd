class_name BookCover
extends Control
## A cover of the driving school's theory book, GAME.md 9.4a: leather, tooled, with the spine
## down one edge; the front with the book's name in gilt, which the shut book shows as it comes
## up, and the back with what the publisher and the readers say of the book and a barcode, which
## it shows once shut at the end. See [SchoolTheory].

## Whether the spine runs down its left edge, as on a shut book lying on the right half, rather
## than its right, as on one shut onto the left; and whether this is the back cover, with what
## the publisher and the readers say of the book and a barcode, rather than the front, with
## the book's name in gilt.
var spine_left := false
var back := false


func _draw() -> void:
	var leather := StyleBoxFlat.new()
	leather.bg_color = SchoolTheory.COVER_INK
	leather.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	leather.shadow_size = 22
	_round_fore_edge(leather, 10)
	draw_style_box(leather, Rect2(Vector2.ZERO, size))
	var light := StyleBoxFlat.new()
	light.bg_color = SchoolTheory.COVER_LIGHT
	_round_fore_edge(light, 8)
	var inset := Vector2(0.0 if spine_left else 3.0, 3.0)
	draw_style_box(light, Rect2(inset, size - Vector2(3.0, 6.0)))
	var tooled := StyleBoxFlat.new()
	tooled.draw_center = false
	tooled.set_border_width_all(2)
	tooled.border_color = SchoolTheory.TOOLING
	_round_fore_edge(tooled, 6)
	draw_style_box(tooled, Rect2(Vector2(14.0, 14.0), size - Vector2(28.0, 28.0)))
	var spine := SchoolTheory.GUTTER * 0.5 + 4.0
	draw_rect(
		Rect2(Vector2(0.0 if spine_left else size.x - spine, 0.0), Vector2(spine, size.y)),
		SchoolTheory.SPINE_INK
	)
	if back:
		_draw_back(spine)
		return
	var font := Type.display_font()
	var lines := SchoolTheory.COVER_TITLE.split("\n")
	var font_size := 30
	var top := size.y * 0.3
	for i: int in lines.size():
		var baseline := top + float(i) * 38.0 + font.get_ascent(font_size)
		draw_string(
			font,
			Vector2(0.0, baseline),
			lines[i],
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x,
			font_size,
			SchoolTheory.GILT
		)
	draw_line(
		Vector2(size.x * 0.3, size.y * 0.3 - 18.0),
		Vector2(size.x * 0.7, size.y * 0.3 - 18.0),
		SchoolTheory.GILT,
		1.5
	)
	var foot := top + float(lines.size()) * 38.0 + 10.0
	draw_line(Vector2(size.x * 0.3, foot), Vector2(size.x * 0.7, foot), SchoolTheory.GILT, 1.5)
	draw_string(
		Type.STRONG,
		Vector2(0.0, foot + 26.0),
		"212TH EDITION",
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		12,
		SchoolTheory.GILT
	)


## The back cover: the publisher's word on the book, what three readers said of it, the
## price, and a barcode on a label, all inside the tooling and clear of the [param spine].
func _draw_back(spine: float) -> void:
	var left := 34.0 + (spine if spine_left else 0.0)
	var width := size.x - 68.0 - spine
	var y := size.y * 0.14
	var blurb_size := 15
	draw_multiline_string(
		Type.STRONG,
		Vector2(left, y),
		TheoryText.BLURB,
		HORIZONTAL_ALIGNMENT_CENTER,
		width,
		blurb_size,
		-1,
		SchoolTheory.GILT
	)
	var blurb := Type.STRONG.get_multiline_string_size(
		TheoryText.BLURB, HORIZONTAL_ALIGNMENT_CENTER, width, blurb_size
	)
	y += blurb.y + 4.0
	var middle := left + width * 0.5
	draw_line(Vector2(middle - 40.0, y), Vector2(middle + 40.0, y), SchoolTheory.GILT, 1.5)
	y += 34.0
	var said := Color(SchoolTheory.PAPER, 0.85)
	for quote: Array in TheoryText.QUOTES:
		draw_multiline_string(
			Type.TEXT, Vector2(left, y), quote[0], HORIZONTAL_ALIGNMENT_CENTER, width, 14, -1, said
		)
		var tall := Type.TEXT.get_multiline_string_size(
			quote[0], HORIZONTAL_ALIGNMENT_CENTER, width, 14
		)
		y += tall.y + 2.0
		draw_string(
			Type.STRONG,
			Vector2(left, y),
			"\u2014 " + str(quote[1]),
			HORIZONTAL_ALIGNMENT_CENTER,
			width,
			11,
			Color(SchoolTheory.GILT, 0.8)
		)
		y += 30.0
	# The barcode on its label toward the fore-edge at the foot, the price at the spine's side.
	var label := Rect2(Vector2(0.0, size.y - 108.0), Vector2(132.0, 62.0))
	label.position.x = left + width - label.size.x if spine_left else left
	var label_box := StyleBoxFlat.new()
	label_box.bg_color = SchoolTheory.PAPER
	label_box.set_corner_radius_all(3)
	draw_style_box(label_box, label)
	var x := label.position.x + 10.0
	var code := TheoryText.ISBN.to_utf8_buffer()
	for i: int in code.size():
		var wide := 1.0 + float(code[i] % 3)
		draw_rect(
			Rect2(Vector2(x, label.position.y + 8.0), Vector2(wide, label.size.y - 28.0)),
			SchoolTheory.SPINE_INK
		)
		x += wide + 1.8
		if x > label.end.x - 12.0:
			break
	draw_string(
		Type.STRONG,
		Vector2(label.position.x, label.end.y - 7.0),
		TheoryText.ISBN,
		HORIZONTAL_ALIGNMENT_CENTER,
		label.size.x,
		9,
		SchoolTheory.SPINE_INK
	)
	var price_x := left if spine_left else left + width - 120.0
	var price_align := HORIZONTAL_ALIGNMENT_LEFT if spine_left else HORIZONTAL_ALIGNMENT_RIGHT
	draw_string(
		Type.STRONG,
		Vector2(price_x, size.y - 50.0),
		TheoryText.PRICE,
		price_align,
		120.0,
		13,
		SchoolTheory.GILT
	)


## Rounds the fore-edge's corners of [param box], the ones away from the spine.
func _round_fore_edge(box: StyleBoxFlat, radius: int) -> void:
	if spine_left:
		box.corner_radius_top_right = radius
		box.corner_radius_bottom_right = radius
	else:
		box.corner_radius_top_left = radius
		box.corner_radius_bottom_left = radius
