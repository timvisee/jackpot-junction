class_name HandFan
extends Control
## A hand of jokers' cards and everything held with them, see [JokerHand]: the words over a card,
## the count and its sign, the table of hands and the soft dark behind them all. All but the
## description of a lifted card, which stands over the room on its own. Kept apart so the HUD can
## go see-through over a kart a piece at a time, GAME.md 8.2, see [HudCovers]: the cards when a kart
## is under the cards, the description when one is under the description.

## The soft dark dome behind the cards, see [method pieces].
var shade: Control


## A fan filling [param hand], which holds it.
static func add_to(hand: Control) -> HandFan:
	var fan := HandFan.new()
	fan.name = "Fan"
	fan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand.add_child(fan)
	fan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return fan


## What of it stands over the room: everything but [member shade], which a kart shows through
## anyway, and which reaches well past the cards, above them and to either side.
func pieces() -> Array[Control]:
	var out: Array[Control] = []
	for child: Node in get_children():
		var piece := child as Control
		if piece != null and piece != shade:
			out.append(piece)
	return out
