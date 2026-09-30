extends Joker
## Getaway Driver: Junction drain ramps twice as fast, and as fast again for every copy past the
## first.


static func factor(copies: int) -> int:
	return 1 + copies


func modify_bank_doubling(_kart: Kart, doubling: float) -> float:
	var copies := stacked()
	return doubling / factor(copies) if copies > 0 else doubling


func stack_values(copies: int) -> Dictionary:
	return {"times": times(factor(copies))}
