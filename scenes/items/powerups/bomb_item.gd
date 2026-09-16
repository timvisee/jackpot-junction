class_name BombPowerUp
extends PowerUp
## Bomb: drops a bomb behind the kart. It arms after a moment and blows up when any kart, the
## owner included, drives over it, when a bullet hits it or when its fuse runs out. Kills credit
## the owner.

@export var fuse := 30.0
@export var placement_distance := 1.8


func activate(kart: Kart) -> void:
	var bomb := Bomb.new()
	bomb.name = "Bomb%d_%d" % [kart.slot, Time.get_ticks_msec()]
	bomb.owner_slot = kart.slot
	bomb.fuse = fuse
	bomb.color = Palette.player_color(kart.color_index)
	var behind := kart.global_position + kart.global_basis.z * placement_distance
	var match_node := kart.get_parent() as Match
	if match_node != null and match_node.arena != null:
		behind = match_node.arena.clamp_to_floor(behind)
	kart.bullet_system.get_parent().add_child(bomb)
	bomb.global_position = Vector3(behind.x, 0.0, behind.z)
