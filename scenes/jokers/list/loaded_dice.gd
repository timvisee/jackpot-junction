extends Joker
## Loaded Dice: Every chip has a 25% chance to count as a gold chip. A stack rolls once for every
## copy: two are 44%, three 58%.

const CHANCE := 0.25


static func chance(copies: int) -> float:
	return 1.0 - (1.0 - CHANCE) ** copies


func modify_coin_value(kart: Kart, chip: Chip, value: int) -> int:
	var copies := stacked()
	if copies > 0 and not chip.gold and kart.rng.randf() < chance(copies):
		return kart.rules.gold_chip_value
	return value


func stack_values(copies: int) -> Dictionary:
	return {"chance": "%d%%" % roundi(chance(copies) * 100.0)}
