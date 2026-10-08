class_name CardBack
extends Panel
## A card lying face down, GAME.md 8.8: a joker or an item the profile has never taken, in the
## catalog, and a card of the respawn pick before it is turned over, 3.7. The size and the round
## corners of a [JokerCard], so it holds the same place in the grid, but in the house's gray rather
## than any kind's color, an engraved rosette over all its face and a question mark in the middle,
## saying neither what it is, what kind nor how rare. Under the cursor it lights up as a card does.
##
## Its back is the profile playing's choice of [constant STYLES], GAME.md 8.9, and this machine's
## alone: the house's, gilt, or drawn in pencil, see [method worn].

const INK := Color(0.42, 0.42, 0.48)
## How strongly the engraving shows, and the question mark and how big it is.
const ENGRAVED := 0.22
const MARK := "?"
const MARK_SIZE := 64
## The backs a card may wear, the first everybody's and the rest won in the loyalty program, by
## the names its landmarks pay them under.
const STYLES: Array[String] = ["The house's", "Gilt", "Hand-drawn"]
## Each back's ink, the paper or board under it, and how strongly its lines show: the house's gray
## on black, gold leaf on black, and pencil on cream paper.
const INKS: Array[Color] = [INK, Color(0.87, 0.68, 0.22), Color(0.3, 0.29, 0.28)]
const BOARDS: Array[Color] = [
	Color(0.09, 0.09, 0.11, 0.96), Color(0.07, 0.06, 0.05, 0.97), Color(0.92, 0.89, 0.8, 0.98)
]
const LINES: Array[float] = [ENGRAVED, 0.34, 0.42]


## What is engraved over the back: rings at its middle and waves across all of it.
class Face:
	extends Control

	var ink := INK
	var lines := ENGRAVED
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
		var drawn := Engraving.rings(size_of * 0.5, size_of.x * 0.3, size_of.x * 0.04, 12, 10, 200)
		drawn.append_array(Engraving.waves(inner, 7.0, 2.0, 30.0, 0.6, 4.0))
		_lines = Engraving.inside(drawn, box)

	func _draw() -> void:
		var hairline := StyleBoxFlat.new()
		hairline.draw_center = false
		hairline.set_border_width_all(1)
		hairline.border_color = Color(ink, JokerCard.HAIRLINE)
		hairline.set_corner_radius_all(6)
		hairline.anti_aliasing = true
		var inset := Vector2.ONE * JokerCard.INSET
		draw_style_box(hairline, Rect2(inset, size - inset * 2.0))
		Engraving.draw_on(self, _lines, Color(ink, lines), 0.8)
		CardBack.draw_mark(self, JokerCard.SIZE * 0.5, MARK_SIZE, ink)


var _normal: StyleBoxFlat
var _chosen: StyleBoxFlat


func _init(style := -1) -> void:
	var back := worn() if style < 0 else clampi(style, 0, STYLES.size() - 1)
	size = JokerCard.SIZE
	pivot_offset = Vector2(JokerCard.SIZE.x * 0.5, JokerCard.SIZE.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_normal = StyleBoxFlat.new()
	_normal.bg_color = BOARDS[back]
	_normal.set_corner_radius_all(10)
	_normal.set_border_width_all(3)
	_normal.border_color = INKS[back]
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
	face.ink = INKS[back]
	face.lines = LINES[back]
	add_child(face)


## The back the profile playing has chosen, as far as it has won it, GAME.md 8.9: the house's
## otherwise.
static func worn() -> int:
	var profile := Game.settings.profile if Game.settings != null else null
	if profile == null:
		return 0
	var chosen := profile.loyalty.card_back
	if chosen <= 0 or chosen >= STYLES.size():
		return 0
	var dress: PackedStringArray = Loyalty.unlocks_of(profile)["dress"]
	return chosen if "card_back:%s" % STYLES[chosen] in dress else 0


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
