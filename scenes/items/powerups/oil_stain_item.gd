class_name OilStainPowerUp
extends PowerUp
## Oil Stain: leaves a slick behind the kart. Anyone who drives over it, the dropper included,
## spins out and skids. It costs control rather than a life.

@export var stain_lifetime := 25.0
@export var placement_distance := 1.8


func activate(kart: Kart) -> void:
	var stain := OilStain.new()
	stain.name = "OilStain%d_%d" % [kart.slot, Time.get_ticks_msec()]
	stain.owner_slot = kart.slot
	stain.lifetime = stain_lifetime
	var behind := kart.global_position + kart.global_basis.z * placement_distance
	var match_node := kart.get_parent() as Match
	if match_node != null and match_node.arena != null:
		behind = match_node.arena.clamp_to_floor(behind)
	kart.bullet_system.get_parent().add_child(stain)
	stain.global_position = Vector3(behind.x, 0.0, behind.z)
