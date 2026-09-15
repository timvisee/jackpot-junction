class_name PowerUpPad
extends Node3D
## Spawns an item box and respawns one a while after pickup, GAME.md 7.1.

var rules: MatchRules
var rng: RandomNumberGenerator
var table: PowerUpTable
var pickup_parent: Node
var current: ItemBox

var _respawn_left := 0.0


func start(
	match_rules: MatchRules, random: RandomNumberGenerator, parent: Node, item_table: PowerUpTable
) -> void:
	rules = match_rules
	rng = random
	pickup_parent = parent
	table = item_table
	_spawn()


func _physics_process(delta: float) -> void:
	if rules == null or current != null:
		return
	_respawn_left -= delta
	if _respawn_left <= 0.0:
		_spawn()


func _spawn() -> void:
	var box := ItemBox.new()
	box.table = table
	box.rng = rng
	box.reveal_time = rules.item_reveal_time
	box.position = global_position
	box.collected.connect(_on_collected)
	pickup_parent.add_child(box)
	current = box


func _on_collected(_pickup: Pickup, _kart: Kart) -> void:
	current = null
	_respawn_left = rules.power_pad_respawn
