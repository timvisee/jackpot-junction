extends Joker
## Pickpocket: Kills move 50% of the victim's coins into your pot; the victim drops none.


func on_victim_death(killer: Kart, victim: Kart, death: DeathOutcome) -> void:
	death.steal_fraction = 0.5
	death.drop_fraction = 0.0
	# What it takes, as the death will work it out: none from a pot Tight Grip holds shut.
	if not death.sealed and killer.alive and floori(victim.pot.coins * death.steal_fraction) > 0:
		went_off(killer, "STOLEN")
