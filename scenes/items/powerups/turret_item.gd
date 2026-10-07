class_name TurretPowerUp
extends PowerUp
## Turret: deploys a turret behind the kart. Its kills credit the owner; it can hit the owner too.

@export var lifetime := 20.0
@export var fire_interval := 1.0
@export var placement_distance := 1.6


func facts() -> Array[PackedStringArray]:
	return [
		fact("Lasts", seconds(lifetime) + ", or one hit"),
		fact("Fires", "every " + seconds(fire_interval)),
		fact("Reach", meters(Turret.RANGE))
	]


func activate(kart: Kart) -> void:
	var turret := Turret.new()
	turret.owner_slot = kart.slot
	turret.lifetime = lifetime
	turret.fire_interval = fire_interval
	turret.bullet_system = kart.bullet_system
	turret.color = Palette.player_color(kart.color_index)
	var behind := kart.global_position + kart.global_basis.z * placement_distance
	kart.bullet_system.get_parent().add_child(turret)
	turret.global_position = Vector3(behind.x, 0.0, behind.z)
	turret.rotation.y = kart.rotation.y
