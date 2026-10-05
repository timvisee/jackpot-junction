class_name Barcode
extends RefCounted
## A number as a barcode, GAME.md 9.4a and 8.1a: each digit a run of four bars, wide for a one and
## narrow for a zero in its bits, with the number written under them, centered under the bars. On
## the back of the license and at the foot of the payout slip.

## How tall the number under the bars is set, and how far apart the bars stand.
const DIGITS := 11
const BAR_GAP := 2.5


## Draws [param number] onto [param canvas] in [param box] in [param ink]: the bars across its top,
## the number along its foot.
static func draw(canvas: CanvasItem, box: Rect2, number: String, ink: Color) -> void:
	var x := box.position.x
	var top := box.position.y
	var tall := box.size.y - 16.0
	for character: String in number:
		if not character.is_valid_int():
			x += 6.0
			continue
		var digit := character.to_int()
		for bit: int in 4:
			var wide := 4.0 if (digit >> bit) & 1 else 2.0
			canvas.draw_rect(Rect2(Vector2(x, top), Vector2(wide, tall)), ink)
			x += wide + BAR_GAP
		x += 3.0
	var bars := x - 5.5 - box.position.x
	var font := Type.numbers_text_font()
	var baseline := Vector2(box.position.x, top + tall + 3.0 + font.get_ascent(DIGITS))
	canvas.draw_string(font, baseline, number, HORIZONTAL_ALIGNMENT_CENTER, bars, DIGITS, ink)


## How wide [param number]'s bars come to, for whoever has to make room for them.
static func width_of(number: String) -> float:
	var wide := 0.0
	for character: String in number:
		if not character.is_valid_int():
			wide += 6.0
			continue
		var digit := character.to_int()
		for bit: int in 4:
			wide += (4.0 if (digit >> bit) & 1 else 2.0) + BAR_GAP
		wide += 3.0
	return wide - 5.5
