class_name StickyBombPowerUp
extends PowerUp
## Sticky Bomb, GAME.md 5.3: the next few shots latch onto the first kart they hit and burst a
## moment later, see [method Bullet._stick_to], so the blast is sure to land -- the counter is to
## ram it into somebody else before it goes off. Mild homing helps it find a kart.

@export var shots := 4
@export var speed := 16.0
@export var cooldown := 0.7
@export var blast_radius := 2.2
@export var lifetime := 3.0
@export var turn_deg := 90.0
@export var cone_deg := 40.0
@export var homing_range := 18.0


func facts() -> Array[PackedStringArray]:
	return [
		fact("Shots", str(shots)),
		fact("Blast", meters(blast_radius)),
		fact("On hit", "sticks"),
	]


func activate(kart: Kart) -> void:
	var stats: CannonStats = kart.cannon_stats.duplicate()
	stats.kind = &"sticky"
	stats.sticky = true
	stats.blast_radius = blast_radius
	stats.explode_on_expire = true
	stats.lifetime = lifetime
	stats.bullet_speed = speed
	stats.fire_cooldown = cooldown
	stats.bullet_radius = 0.2
	stats.aim_assist = true
	stats.aim_assist_turn_rate_deg = turn_deg
	stats.aim_assist_cone_deg = cone_deg
	stats.aim_assist_range = homing_range
	stats.max_live_bullets = maxi(kart.cannon_stats.max_live_bullets, 2)
	kart.cannon.set_override(stats, shots)
