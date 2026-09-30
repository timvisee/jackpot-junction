extends Joker
## Lucky Seven: Every 7th chip you collect gives +1 mult, and one more for every copy past the
## first, all at once.

var _count := 0


func on_chip_collected(kart: Kart, _chip: Chip) -> void:
	var copies := stacked()
	if copies <= 0:
		return
	_count += 1
	if _count % 7 == 0:
		kart.gain_mult(float(copies), &"lucky_seven")


func stack_values(copies: int) -> Dictionary:
	return {"mult": "+%d" % copies}
