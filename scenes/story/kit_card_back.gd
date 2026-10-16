class_name KitCardBack
extends Control
## The back of one of Kit's cards in the folder, STORY.md 7.2: painted over as its face was, Kit's
## graph paper's squares showing through, and a longer line of Kit's on it in pencil, as a note's
## back has one. Drawn at a card's size, see [JokerCard].

const ROOM := 9.0
const TYPE := 13

var card: Joker


## The back of [param of_card].
static func of(of_card: Joker) -> KitCardBack:
	var back := KitCardBack.new()
	back.card = of_card
	back.size = JokerCard.SIZE
	back.custom_minimum_size = JokerCard.SIZE
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return back


func _draw() -> void:
	var paint := StyleBoxFlat.new()
	paint.bg_color = KitCards.PAINTED
	paint.set_corner_radius_all(10)
	paint.set_border_width_all(2)
	paint.border_color = KitCards.PENCIL
	draw_style_box(paint, Rect2(Vector2.ZERO, size))
	var step := 9.0
	var x := 5.0 + step
	while x < size.x - 5.0:
		draw_line(Vector2(x, 5.0), Vector2(x, size.y - 5.0), KitCards.SQUARES, 1.0)
		x += step
	var y := 5.0 + step
	while y < size.y - 5.0:
		draw_line(Vector2(5.0, y), Vector2(size.x - 5.0, y), KitCards.SQUARES, 1.0)
		y += step
	if card == null:
		return
	var font := NotePage.HAND
	var rows := LoyaltyArt.lines_of(font, card.kit_back, TYPE, size.x - ROOM * 2.0, 12)
	var line := float(TYPE) * 1.05
	var top := (size.y - line * float(rows.size())) * 0.5 + float(TYPE) * 0.8
	for i: int in rows.size():
		draw_string(
			font,
			Vector2(ROOM, top + line * float(i)),
			rows[i],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			TYPE,
			KitCards.PENCIL
		)
