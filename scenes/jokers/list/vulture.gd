extends Joker
## Vulture: Chips dropped by other karts are worth 3 coins to you, and a coin more for every copy
## past the first. In team play the other karts are the other teams', GAME.md 3.14.


static func worth(copies: int) -> int:
	return 2 + copies


func modify_coin_value(kart: Kart, chip: Chip, value: int) -> int:
	var copies := stacked()
	var theirs := chip.dropped and not Teams.same(chip.dropped_team, kart.team)
	return value * worth(copies) if copies > 0 and theirs else value


func stack_values(copies: int) -> Dictionary:
	return {"coins": counted(worth(copies), "chip", "chips")}
