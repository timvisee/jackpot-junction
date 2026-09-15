class_name ShieldPowerUp
extends PowerUp
## Shield: absorbs one bullet or ram, then pops. Expires on its own after a while.

@export var duration := 10.0


func activate(kart: Kart) -> void:
	kart.add_effect(ShieldEffect.new(duration))


class ShieldEffect:
	extends KartEffect

	func _init(duration: float) -> void:
		super(&"shield", duration)

	func start(kart: Kart) -> void:
		kart.set_shielded(true)

	func end(kart: Kart) -> void:
		kart.set_shielded(false)
