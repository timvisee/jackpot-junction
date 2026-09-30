extends Joker
## Slipstream: Grazes give +1.5 mult instead of +0.5, and half a point more for every copy past
## the first.

const MULT := 1.5
const MORE_MULT := 0.5


static func graze_mult(copies: int) -> float:
	return MULT + MORE_MULT * (copies - 1)


func modify_graze_mult(_kart: Kart, amount: float) -> float:
	var copies := stacked()
	return graze_mult(copies) if copies > 0 and amount > 0.0 else amount


func stack_values(copies: int) -> Dictionary:
	return {"mult": "+" + figure(graze_mult(copies))}
