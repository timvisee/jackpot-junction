class_name CoinPad
extends Node3D
## Spawns a chip, a gold chip or a mult die and respawns one a few seconds after pickup,
## GAME.md 3.2. Inert until [method start] hands it the rules and the match's random generator.

var rules: MatchRules
var rng: RandomNumberGenerator
var pickup_parent: Node
var current: Pickup

var _respawn_left := 0.0


func start(match_rules: MatchRules, random: RandomNumberGenerator, parent: Node) -> void:
	rules = match_rules
	rng = random
	pickup_parent = parent
	_spawn()


func _physics_process(delta: float) -> void:
	if rules == null or current != null:
		return
	_respawn_left -= delta
	if _respawn_left <= 0.0:
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
	pickup.position = global_position
	pickup.collected.connect(_on_collected)
	pickup_parent.add_child(pickup)
	current = pickup


func _on_collected(_pickup: Pickup, _kart: Kart) -> void:
	current = null
	_respawn_left = rules.coin_pad_respawn
