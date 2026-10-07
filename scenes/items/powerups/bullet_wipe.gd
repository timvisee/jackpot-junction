class_name BulletWipePowerUp
extends PowerUp
## Bullet Wipe: erases every bullet near the kart.

@export var radius := 8.0


func facts() -> Array[PackedStringArray]:
	return [fact("Reach", meters(radius))]


func activate(kart: Kart) -> void:
	if kart.bullet_system == null:
		return
	for bullet: Bullet in kart.bullet_system.bullets.duplicate():
		if bullet.global_position.distance_to(kart.global_position) <= radius:
			bullet.destroy()
