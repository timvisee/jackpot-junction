class_name RocketPowerUp
extends PowerUp
## Rocket, GAME.md 5.3: the next few shots are slow, hard-homing rockets that burst where they land,
## see [Blast]. A direct hit takes two lives, an outright kill on a kart at full life; the blast
## catches anyone else nearby for one. Slow and few, so it is a committed shot, not a spray.

@export var shots := 4
@export var speed := 7.5
@export var cooldown := 0.75
@export var blast_radius := 2.2
@export var lifetime := 4.5
## The homing that keeps a slow rocket on a moving kart: how fast it turns, how wide it looks and
## how far.
@export var turn_deg := 130.0
@export var cone_deg := 55.0
@export var homing_range := 24.0


func facts() -> Array[PackedStringArray]:
	return [
		fact("Shots", str(shots)),
		fact("Direct hit", "2 lives"),
		fact("Blast", meters(blast_radius)),
	]


func activate(kart: Kart) -> void:
	var stats: CannonStats = kart.cannon_stats.duplicate()
	stats.kind = &"rocket"
	stats.hits = 2
	stats.blast_radius = blast_radius
	stats.explode_on_expire = true
	stats.bullet_speed = speed
	stats.fire_cooldown = cooldown
	stats.bullet_radius = 0.2
	stats.lifetime = lifetime
	stats.max_live_bullets = maxi(kart.cannon_stats.max_live_bullets, 2)
	stats.aim_assist = true
	stats.aim_assist_turn_rate_deg = turn_deg
	stats.aim_assist_cone_deg = cone_deg
	stats.aim_assist_range = homing_range
	stats.assist_after_bounce = true
	kart.cannon.set_override(stats, shots)
