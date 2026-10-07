class_name BoostPowerUp
extends PowerUp
## Boost: faster for a few seconds with heavier steering, and ramming kills.

@export var duration := 3.0
@export var speed_multiplier := 1.5
@export var steer_multiplier := 0.8


func facts() -> Array[PackedStringArray]:
	return [
		fact("Lasts", seconds(duration)),
		fact("Top speed", percent(speed_multiplier)),
		fact("Steering", percent(steer_multiplier))
	]


func activate(kart: Kart) -> void:
	kart.add_effect(BoostEffect.new(duration, speed_multiplier, steer_multiplier))


class BoostEffect:
	extends KartEffect

	var speed := 1.5
	var steer := 0.8

	func _init(duration: float, speed_multiplier: float, steer_multiplier: float) -> void:
		super(&"boost", duration)
		speed = speed_multiplier
		steer = steer_multiplier

	func start(kart: Kart) -> void:
		kart.motor.speed_bonus = speed
		kart.motor.steer_multiplier = steer
		kart.ramming = true

	func end(kart: Kart) -> void:
		kart.motor.speed_bonus = 1.0
		kart.motor.steer_multiplier = 1.0
		kart.ramming = false
