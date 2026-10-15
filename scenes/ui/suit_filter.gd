class_name SuitFilter
extends HBoxContainer
## Which of the jokers a page of the catalog shows by suit, GAME.md 8.8: all of them, one of the
## four suits, or the wild cards, as a row of little cards of the House's paper, the one shown full
## and edged in gold. Left to the mouse and a finger: keys and a pad step through them with their
## bind, see [method next], drawn in the row of tabs. Drawn as one picture, kept for the run, see
## [KeptPictures]: six cards of a few shapes each would be a draw call or more apiece every frame.

signal chosen(suit: int)

## Every suit, and the order the chips stand in and a bind steps through them.
const ALL := -1
const ORDER: Array[int] = [
	ALL,
	Joker.Suit.SPADES,
	Joker.Suit.HEARTS,
	Joker.Suit.DIAMONDS,
	Joker.Suit.CLUBS,
	Joker.Suit.WILD
]
## How big a chip is and how far apart, how far in its suit is drawn, how faded one not shown is,
## and what the chip for every suit says.
const CHIP := Vector2(24.0, 30.0)
const GAP := 3
const INSET := 4.0
const FADED := 0.55
const ALL_WORD := "All"
const ALL_SIZE := 13
const PICTURES := &"suit_filter_pictures"

var _chips: Array[Button] = []
## The chip under the pointer, by its suit, or none.
var _over := -2


## The row as a picture, for [KeptPictures].
class RowPicture:
	extends Control

	var shown := SuitFilter.ALL
	var over := -2
	var scale_by := 1.0

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * scale_by)
		SuitFilter.paint(self, shown, over)


func _init(shown_suit: int = ALL) -> void:
	add_to_group(PICTURES)
	add_theme_constant_override("separation", GAP)
	var group := ButtonGroup.new()
	for suit: int in ORDER:
		var chip := Button.new()
		chip.name = "All" if suit == ALL else JokerSuits.name_of(suit)
		chip.toggle_mode = true
		chip.button_group = group
		chip.focus_mode = Control.FOCUS_NONE
		chip.custom_minimum_size = CHIP
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# Drawn by the row, see [method paint].
		for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"focus"]:
			chip.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		chip.set_pressed_no_signal(suit == shown_suit)
		chip.pressed.connect(func() -> void: chosen.emit(suit))
		chip.toggled.connect(func(_on: bool) -> void: queue_redraw())
		chip.mouse_entered.connect(_point.bind(suit))
		chip.mouse_exited.connect(_point.bind(-2))
		add_child(chip)
		_chips.append(chip)


## The suit after [param suit] in the row, round to every suit again after the last.
static func next(suit: int) -> int:
	return ORDER[(ORDER.find(suit) + 1) % ORDER.size()]


## The chip of [param suit] pressed in, without saying so.
func choose(suit: int) -> void:
	for i: int in _chips.size():
		_chips[i].set_pressed_no_signal(ORDER[i] == suit)
	queue_redraw()


## The suit pressed in.
func shown() -> int:
	for i: int in _chips.size():
		if _chips[i].button_pressed:
			return ORDER[i]
	return ALL


func _point(suit: int) -> void:
	_over = suit
	queue_redraw()


## The row on [param on] from its origin, [param shown_suit] full and edged in gold, and the chip
## [param over] under the pointer full as well.
static func paint(on: CanvasItem, shown_suit: int, over: int) -> void:
	for i: int in ORDER.size():
		var suit := ORDER[i]
		var box := Rect2(Vector2(i * (CHIP.x + GAP), 0.0), CHIP).grow(-1.0)
		var pressed := suit == shown_suit
		var fade := 1.0 if pressed or suit == over else FADED
		var face := StyleBoxFlat.new()
		face.set_corner_radius_all(4)
		face.anti_aliasing = true
		face.bg_color = HouseTheme.PAPER.lerp(ProofArt.MAT, 1.0 - fade)
		face.set_border_width_all(2 if pressed else 1)
		face.border_color = Palette.CHIP_GOLD if pressed else Color(0.0, 0.0, 0.0, 0.5)
		on.draw_style_box(face, box)
		# A chip not shown is the mat's color showing through it, and its ink as far gone.
		var ink := HouseTheme.INK.lerp(face.bg_color, 1.0 - fade)
		if suit != ALL:
			var side := minf(box.size.x, box.size.y) - INSET * 2.0
			var mark := Rect2(box.get_center() - Vector2.ONE * side * 0.5, Vector2.ONE * side)
			JokerSuits.draw_mark(on, mark, suit, true)
			if fade < 1.0:
				on.draw_rect(mark.grow(1.0), Color(face.bg_color, 1.0 - fade))
			continue
		var font := Type.STRONG
		var wide := font.get_string_size(ALL_WORD, 0, -1, ALL_SIZE).x
		var at := box.position + Vector2(box.size.x - wide, box.size.y + ALL_SIZE * 0.72) * 0.5
		on.draw_string(font, at, ALL_WORD, 0, -1, ALL_SIZE, ink)


func _draw() -> void:
	var shown_suit := shown()
	var scale_by := maxf(KeptPictures.scale_of(self), 0.25)
	var pixels := Vector2i((size * scale_by).ceil())
	var picture := KeptPictures.of(
		self,
		"suit_filter|%d|%d" % [shown_suit, _over],
		pixels,
		func() -> Control:
			var drawing := RowPicture.new()
			drawing.shown = shown_suit
			drawing.over = _over
			drawing.scale_by = scale_by
			return drawing,
		PICTURES
	)
	if picture == null:
		paint(self, shown_suit, _over)
		return
	draw_texture_rect(picture, Rect2(Vector2.ZERO, size), false)
