extends Joker
## Lucky Seven: every seven chips collected give +1 mult, and one more for every copy past the
## first, all at once. Chips are counted by what they are worth, GAME.md 7.3, so a gold chip is five
## of them, and Loaded Dice and Vulture feed it.

## How many chips' worth one mult takes.
const PER_MULT := 7

var _count := 0


func on_chip_collected(kart: Kart, _chip: Chip, worth: int) -> void:
	var copies := stacked()
	if copies <= 0 or worth <= 0:
		return
	_count += worth
	var times := 0
	while _count >= PER_MULT:
		_count -= PER_MULT
		times += 1
	if times > 0:
		kart.jokers.pay_mult(self, float(copies * times), &"lucky_seven")


func stack_values(copies: int) -> Dictionary:
	return {"mult": "+%d" % copies}
