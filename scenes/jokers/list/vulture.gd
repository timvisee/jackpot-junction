extends Joker
## Vulture: Chips dropped by other karts are worth 3 coins to you, and a coin more for every copy
## past the first.


static func worth(copies: int) -> int:
	return 2 + copies


func modify_coin_value(_kart: Kart, chip: Chip, value: int) -> int:
	var copies := stacked()
	return value * worth(copies) if copies > 0 and chip.dropped else value


func stack_values(copies: int) -> Dictionary:
	return {"coins": counted(worth(copies), "coin", "coins")}
