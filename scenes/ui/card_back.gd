class_name CardBack
extends Panel
## A card lying face down, GAME.md 8.8: a joker or an item the profile has never taken, in the
## catalog. The size and the round corners of a [JokerCard], so it holds the same place in the
## grid, but in the house's gray rather than any kind's color, an engraved rosette over all its
## face and a question mark in the middle, saying neither what it is, what kind nor how rare.
## Under the cursor it lights up as a card does.

const INK := Color(0.42, 0.42, 0.48)
## How strongly the engraving shows, and how big the question mark is.
const ENGRAVED := 0.22
const MARK_SIZE := 64


## What is engraved over the back: rings at its middle and waves across all of it.
class Face:
	extends Control

	var _lines: Array[PackedVector2Array] = []

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var size_of := JokerCard.SIZE
		var inset := JokerCard.INSET + 1.0
		var inner := Rect2(Vector2.ONE * inset, size_of - Vector2.ONE * inset * 2.0)
		var box := PackedVector2Array(
			[
				inner.position,
				Vector2(inner.end.x, inner.position.y),
				inner.end,
				Vector2(inner.position.x, inner.end.y),
			]
		)
		var lines := Engraving.rings(size_of * 0.5, size_of.x * 0.3, size_of.x * 0.04, 12, 10, 200)
		lines.append_array(Engraving.waves(inner, 7.0, 2.0, 30.0, 0.6, 4.0))
		_lines = Engraving.inside(lines, box)

	func _draw() -> void:
		var hairline := StyleBoxFlat.new()
		hairline.draw_center = false
		hairline.set_border_width_all(1)
		hairline.border_color = Color(INK, JokerCard.HAIRLINE)
		hairline.set_corner_radius_all(6)
		hairline.anti_aliasing = true
		var inset := Vector2.ONE * JokerCard.INSET
		draw_style_box(hairline, Rect2(inset, size - inset * 2.0))
		Engraving.draw_on(self, _lines, Color(INK, ENGRAVED), 0.8)


var _normal: StyleBoxFlat
var _chosen: StyleBoxFlat


func _init() -> void:
	size = JokerCard.SIZE
	pivot_offset = Vector2(JokerCard.SIZE.x * 0.5, JokerCard.SIZE.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_normal = StyleBoxFlat.new()
	_normal.bg_color = Color(0.09, 0.09, 0.11, 0.96)
	_normal.set_corner_radius_all(10)
	_normal.set_border_width_all(3)
	_normal.border_color = INK
	_normal.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	_normal.shadow_size = 6
	_chosen = _normal.duplicate()
	_chosen.set_border_width_all(5)
	_chosen.border_color = Palette.CHIP_WHITE
	_chosen.shadow_color = Color(Palette.CHIP_GOLD, 0.6)
	_chosen.shadow_size = 18
	add_theme_stylebox_override("panel", _normal)
	var face := Face.new()
	face.name = "Face"
	add_child(face)
	var mark := Label.new()
	mark.name = "Mark"
	mark.text = "?"
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Type.display(mark, MARK_SIZE, INK)
	add_child(mark)


## Lights the card up as the one under the cursor, as [method JokerCard.set_highlighted] does.
func set_highlighted(on: bool) -> void:
	add_theme_stylebox_override("panel", _chosen if on else _normal)
