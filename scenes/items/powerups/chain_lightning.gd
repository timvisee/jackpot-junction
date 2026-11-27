class_name ChainLightningPowerUp
extends PowerUp
## Chain Lightning, GAME.md 5.3: the next few shots leap from the first thing they strike to the
## next nearby and on again -- karts, turrets and crates alike, see [member CannonStats.chain] -- so
## one shot clears a cluttered corner of the arena in a crackling arc.

@export var shots := 5
@export var speed := 22.0
@export var cooldown := 0.6
@export var chain := 3
@export var leap_range := 11.0
@export var lifetime := 2.5


func facts() -> Array[PackedStringArray]:
	# TRANSLATORS: In the catalog, how many karts a bolt leaps on to: "Leaps 3".
	var leaps := tr("Leaps")
	# TRANSLATORS: In the catalog, how far one leap of a bolt reaches: "Leap 6 m".
	var leap := tr("Leap")
	return [
		fact(tr("Shots"), str(shots)),
		fact(leaps, str(chain)),
		fact(leap, meters(leap_range)),
	]


func activate(kart: Kart) -> void:
	var stats: CannonStats = kart.cannon_stats.duplicate()
	stats.kind = &"lightning"
	stats.chain = chain
	stats.bullet_speed = speed
	stats.fire_cooldown = cooldown
	stats.bullet_radius = 0.14
	stats.lifetime = lifetime
	stats.aim_assist = false
	# The leap reaches as far as the assist would look; the bullet reads it from there, see
	# [method Bullet._nearest_unhit].
	stats.aim_assist_range = leap_range
	stats.max_live_bullets = maxi(kart.cannon_stats.max_live_bullets, 3)
	kart.cannon.set_override(stats, shots)
