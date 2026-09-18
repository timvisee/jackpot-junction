extends Joker
## Vulture: Chips dropped by other karts are worth 3 coins to you.


func modify_coin_value(_kart: Kart, chip: Chip, value: int) -> int:
	return value * 3 if chip.dropped else value
