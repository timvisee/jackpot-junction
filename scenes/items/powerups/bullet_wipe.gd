class_name BulletWipePowerUp
extends PowerUp
## Bullet Wipe: erases every bullet near the kart that could hurt it, so not a teammate's with
## friendly fire off, GAME.md 3.14.

@export var radius := 8.0


func facts() -> Array[PackedStringArray]:
	return [fact("Reach", meters(radius))]


func activate(kart: Kart) -> void:
	if kart.bullet_system == null:
		return
	for bullet: Bullet in kart.bullet_system.bullets.duplicate():
		var friendly := bullet.spares_team and bullet.owner_slot != kart.slot
		if friendly and Teams.same(bullet.owner_team, kart.team):
			continue
		if bullet.global_position.distance_to(kart.global_position) <= radius:
			bullet.destroy()
