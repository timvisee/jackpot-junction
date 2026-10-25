class_name ProximityMinePowerUp
extends PowerUp
## Proximity Mine, GAME.md 5.3: the next few shots are lobbed onto the floor, where they lie as
## traps and burst the moment an enemy drives within reach, or on a long fuse, see [method
## Bullet._grenade_tick]. Thrown short of a chokepoint to deny it rather than aimed at a kart.

@export var shots := 4
@export var speed := 10.0
@export var cooldown := 0.7
@export var blast_radius := 2.0
@export var arm_radius := 3.0
@export var fuse := 8.0


func facts() -> Array[PackedStringArray]:
	return [
		fact("Shots", str(shots)),
		fact("Blast", meters(blast_radius)),
		fact("Trips", meters(arm_radius)),
	]


func activate(kart: Kart) -> void:
	var stats: CannonStats = kart.cannon_stats.duplicate()
	stats.kind = &"mine"
	stats.blast_radius = blast_radius
	stats.arm_radius = arm_radius
	stats.explode_on_expire = true
	stats.lifetime = fuse
	stats.bullet_speed = speed
	stats.fire_cooldown = cooldown
	stats.bullet_radius = 0.22
	stats.aim_assist = false
	stats.max_live_bullets = maxi(kart.cannon_stats.max_live_bullets, 3)
	kart.cannon.set_override(stats, shots)
