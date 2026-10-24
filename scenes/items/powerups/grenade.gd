class_name GrenadePowerUp
extends PowerUp
## Grenade, GAME.md 5.3: the next few shots bounce off walls and burst a moment later on a short
## fuse, or at once on a kart, see [Blast]. No homing and a bounce or three, so it is thrown round a
## corner to flush a kart out of cover rather than aimed straight at one.

@export var shots := 5
@export var speed := 13.0
@export var cooldown := 0.6
@export var blast_radius := 2.0
@export var fuse := 1.4
@export var bounces := 3


func facts() -> Array[PackedStringArray]:
	return [
		fact("Shots", str(shots)),
		fact("Fuse", seconds(fuse)),
		fact("Blast", meters(blast_radius)),
		fact("Bounces", str(bounces)),
	]


func activate(kart: Kart) -> void:
	var stats: CannonStats = kart.cannon_stats.duplicate()
	stats.kind = &"grenade"
	stats.blast_radius = blast_radius
	stats.explode_on_expire = true
	stats.bounces = bounces
	stats.lifetime = fuse
	stats.bullet_speed = speed
	stats.fire_cooldown = cooldown
	stats.bullet_radius = 0.22
	stats.aim_assist = false
	stats.max_live_bullets = maxi(kart.cannon_stats.max_live_bullets, 3)
	kart.cannon.set_override(stats, shots)
