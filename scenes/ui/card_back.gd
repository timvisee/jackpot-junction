class_name CardBack
extends Panel
## A card lying face down, GAME.md 8.8: a joker or an item the profile has never taken, in the
## catalog. The size and the round corners of a [JokerCard], so it holds the same place in the
## grid, but in the house's gray rather than any kind's color, an engraved rosette over all its
## face and a question mark in the middle, saying neither what it is, what kind nor how rare.
## Under the cursor it lights up as a card does.

const INK := Color(0.42, 0.42, 0.48)
## How strongly the engraving shows, and the question mark and how big it is.
const ENGRAVED := 0.22
const MARK := "?"
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
		CardBack.draw_mark(self, JokerCard.SIZE * 0.5, MARK_SIZE, INK)


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


## The question mark of a card face down, [param font_size] big in [param ink], with the middle
## of the mark itself on [param middle] rather than the middle of its line, which would put the mark
## low and a little to one side in the rings round it: across by its own width, and up and down by
## the height of the capitals it stands as tall as, see [constant Type.CAP_HEIGHT].
static func draw_mark(on: CanvasItem, middle: Vector2, font_size: int, ink: Color) -> void:
	var font := Type.display_font()
	var wide := font.get_string_size(MARK, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var base := middle.y + Type.CAP_HEIGHT * float(font_size) * 0.5
	on.draw_string(
		font,
		Vector2(middle.x - wide * 0.5, base),
		MARK,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		ink
	)


## Lights the card up as the one under the cursor, as [method JokerCard.set_highlighted] does.
func set_highlighted(on: bool) -> void:
	add_theme_stylebox_override("panel", _chosen if on else _normal)
