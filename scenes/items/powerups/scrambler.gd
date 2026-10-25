class_name ScramblerPowerUp
extends PowerUp
## Scrambler, GAME.md 5.3: the next few shots take no life but lock the cannon of the kart they hit
## for a few seconds, cutting off its fire, see [member Kart.cannon_locked_left]. Control, not kills
## -- best on a teammate's target or to break up a firefight. Mild homing to land it.

@export var shots := 4
@export var speed := 22.0
@export var cooldown := 0.6
@export var jam := 3.0
@export var turn_deg := 90.0
@export var cone_deg := 45.0
@export var homing_range := 20.0


func facts() -> Array[PackedStringArray]:
	return [
		fact("Shots", str(shots)),
		fact("Jams", seconds(jam)),
	]


func activate(kart: Kart) -> void:
	var stats: CannonStats = kart.cannon_stats.duplicate()
	stats.kind = &"emp"
	stats.jam = jam
	stats.hits = 0
	stats.bullet_speed = speed
	stats.fire_cooldown = cooldown
	stats.bullet_radius = 0.16
	stats.aim_assist = true
	stats.aim_assist_turn_rate_deg = turn_deg
	stats.aim_assist_cone_deg = cone_deg
	stats.aim_assist_range = homing_range
	stats.max_live_bullets = maxi(kart.cannon_stats.max_live_bullets, 2)
	kart.cannon.set_override(stats, shots)
