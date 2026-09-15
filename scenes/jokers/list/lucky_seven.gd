extends Joker
## Lucky Seven: Every 7th chip you collect gives +1 mult.

var _count := 0


func on_chip_collected(kart: Kart, _chip: Chip) -> void:
	_count += 1
	if _count % 7 == 0:
		kart.gain_mult(1.0, &"lucky_seven")
