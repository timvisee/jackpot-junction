extends Joker
## Loaded Dice: Every chip has a 25% chance to count as a gold chip.


func modify_coin_value(kart: Kart, chip: Chip, value: int) -> int:
	if not chip.gold and kart.rng.randf() < 0.25:
		return kart.rules.gold_chip_value
	return value
