class_name PowerUpPad
extends SpawningPad
## Spawns an item box and respawns one a while after pickup, GAME.md 7.1.

var table: PowerUpTable


func start(
	match_rules: MatchRules, random: RandomNumberGenerator, parent: Node, item_table: PowerUpTable
) -> void:
	rules = match_rules
	rng = random
	pickup_parent = parent
	table = item_table
	_spawn()


func _spawn() -> void:
	var box := ItemBox.new()
	box.table = table
	box.rng = rng
	box.reveal_time = rules.item_reveal_time
	_place(box)


func _respawn_delay() -> float:
	return rules.power_pad_respawn
