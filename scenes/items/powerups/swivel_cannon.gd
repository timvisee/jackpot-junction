class_name SwivelCannonPowerUp
extends PowerUp
## Swivel Cannon: free aim with the right stick or the mouse for a while, without aim assist.

@export var duration := 12.0


func activate(kart: Kart) -> void:
	kart.add_effect(SwivelEffect.new(duration))


class SwivelEffect:
	extends KartEffect

	func _init(duration: float) -> void:
		super(&"swivel", duration)

	func start(kart: Kart) -> void:
		var stats: CannonStats = kart.cannon_stats.duplicate()
		stats.free_aim = true
		stats.aim_assist = false
		kart.cannon.set_override(stats, 1 << 20)
		kart.aim_arrow_visible = true

	func end(kart: Kart) -> void:
		kart.cannon.clear_override()
		kart.aim_arrow_visible = false
