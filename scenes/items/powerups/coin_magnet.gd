class_name CoinMagnetPowerUp
extends PowerUp
## Chip Magnet: a much wider pickup radius, and chips inside it drift toward the kart.

@export var duration := 8.0
@export var radius_multiplier := 3.0
@export var pull_speed := 6.0


func facts() -> Array[PackedStringArray]:
	return [
		fact("Lasts", seconds(duration)),
		fact("Reach", "×" + Joker.figure(radius_multiplier)),
		fact("Pull", meters(pull_speed) + "/s")
	]


func activate(kart: Kart) -> void:
	kart.add_effect(MagnetEffect.new(duration, radius_multiplier, pull_speed))


class MagnetEffect:
	extends KartEffect

	var radius := 3.0
	var pull := 6.0

	func _init(duration: float, radius_multiplier: float, pull_speed: float) -> void:
		super(&"magnet", duration)
		radius = radius_multiplier
		pull = pull_speed

	func start(kart: Kart) -> void:
		kart.pickup_radius_bonus = radius
		kart.refresh_pickup_radius()

	func step(kart: Kart, delta: float) -> void:
		for pickup: Pickup in kart.overlapping_pickups():
			if pickup is Chip:
				var target := Vector3(
					kart.global_position.x, pickup.global_position.y, kart.global_position.z
				)
				pickup.global_position = pickup.global_position.move_toward(target, pull * delta)

	func end(kart: Kart) -> void:
		kart.pickup_radius_bonus = 1.0
		kart.refresh_pickup_radius()
