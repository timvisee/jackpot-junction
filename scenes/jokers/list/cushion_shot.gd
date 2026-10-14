extends Joker
## Cushion Shot: a chip into the pot every time one of the holder's bullets bounces off a wall, its
## turret's and its decoy's among them, and one more for every copy past the first, GAME.md 7.3: a
## shooting hand's way into chips. Paid as coins rather than as chips, as Payday's are, so nothing
## that bends what a chip is worth touches them.


func on_shot_bounced(kart: Kart) -> void:
	var copies := stacked()
	if copies > 0 and kart.alive:
		kart.collect_coins(copies, null)


func stack_values(copies: int) -> Dictionary:
	return {"coins": counted(copies, "chip", "chips")}
