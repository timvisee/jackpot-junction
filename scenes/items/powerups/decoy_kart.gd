class_name DecoyKartPowerUp
extends PowerUp
## Decoy Kart: a bot-driven copy of your kart in your colour. Its kills and coins credit you; it
## lives a while or until it takes one hit, and it can hit you.

@export var lifetime := 20.0
@export var placement_distance := 2.2


func activate(kart: Kart) -> void:
	var match_node := kart.get_parent() as Match
	if match_node == null:
		return
	var decoy: Kart = Match.KART_SCENE.instantiate()
	decoy.name = "Decoy%d_%d" % [kart.slot, Time.get_ticks_msec()]
	decoy.slot = kart.slot
	decoy.color_index = kart.color_index
	decoy.rules = kart.rules
	decoy.rng = kart.rng
	decoy.bullet_system = kart.bullet_system
	decoy.decoy_owner = kart
	decoy.lifetime = lifetime
	decoy.input = BotInput.new()
	var behind := kart.global_position + kart.global_basis.z * placement_distance
	decoy.position = Vector3(behind.x, 0.0, behind.z)
	match_node.add_child(decoy)
	decoy.lives = 1
	decoy.face(-kart.global_basis.z)
	var brain := BotBrain.new()
	brain.name = "Brain"
	brain.setup(
		decoy, match_node, match_node.bot_traits.pick(kart.rng), match_node.bot_difficulty, kart.rng
	)
	decoy.add_child(brain)
