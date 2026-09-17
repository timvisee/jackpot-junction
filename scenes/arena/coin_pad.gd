class_name CoinPad
extends SpawningPad
## Spawns a chip, a gold chip or a mult die and respawns one a few seconds after pickup,
## GAME.md 3.2. Inert until [method start] hands it the rules and the match's random generator.


func start(match_rules: MatchRules, random: RandomNumberGenerator, parent: Node) -> void:
	rules = match_rules
	rng = random
	pickup_parent = parent
	_spawn()


func _spawn() -> void:
	var roll := rng.randf()
	var pickup: Pickup
	if roll < rules.pad_mult_die_chance:
		var die := MultDie.new()
		die.amount = rules.mult_die_mult
		pickup = die
	else:
		var chip := Chip.new()
		chip.gold = roll < rules.pad_mult_die_chance + rules.pad_gold_chance
		chip.value = rules.gold_chip_value if chip.gold else rules.chip_value
		pickup = chip
	_place(pickup)


func _respawn_delay() -> float:
	return rules.coin_pad_respawn
