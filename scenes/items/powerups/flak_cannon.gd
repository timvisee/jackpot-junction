class_name FlakCannonPowerUp
extends PowerUp
## Flak Cannon, GAME.md 5.3: the next few shots fly out and airburst into a spray of pellets over a
## short fuse, or where they land, see [method Bullet._spawn_pellets]. Area at range; up close the
## pellets have no room to fan, so it rewards keeping your distance.

@export var shots := 5
@export var speed := 20.0
@export var cooldown := 0.6
@export var fuse := 0.55
@export var pellets := 8


func facts() -> Array[PackedStringArray]:
	return [
		fact("Shots", str(shots)),
		fact("Pellets", str(pellets)),
		fact("Burst", seconds(fuse)),
	]


func activate(kart: Kart) -> void:
	var stats: CannonStats = kart.cannon_stats.duplicate()
	stats.kind = &"flak"
	stats.cluster = pellets
	stats.explode_on_expire = true
	stats.lifetime = fuse
	stats.bullet_speed = speed
	stats.fire_cooldown = cooldown
	stats.bullet_radius = 0.18
	stats.aim_assist = false
	stats.max_live_bullets = maxi(kart.cannon_stats.max_live_bullets, 2)
	kart.cannon.set_override(stats, shots)
