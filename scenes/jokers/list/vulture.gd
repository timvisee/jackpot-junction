extends Joker
## Vulture: Chips dropped by other karts are worth 2 coins to you.


func modify_coin_value(_kart: Kart, chip: Chip, value: int) -> int:
	return value * 2 if chip.dropped else value
