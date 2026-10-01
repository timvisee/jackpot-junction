class_name TutorialNitro
extends TutorialLesson
## Lesson 4, GAME.md 9.4a: burn a full tank of nitro down the long straight, the tank filled as
## the lesson starts. The nitro tank and the speedometer come into the corner with it.

var _burn: TutorialTask


func _init() -> void:
	title = "Nitro"
	gate_cell = Vector2i(80, 23)
	spawn_cell = Vector2i(50, 26)
	facing = Vector3(1.0, 0.0, 0.0)
	next_cell = Vector2i(81, 20)
	reveals = [[&"nitro", "Your nitro", [InputActions.NITRO]]]
	_burn = add_task("Burn a full tank of nitro", "Hold %s for nitro", [InputActions.NITRO], true)
	reveals[0][1] = "Your nitro, %s to burn it"


func _begin() -> void:
	kart().refill_nitro(1.0)


func step(_delta: float) -> void:
	var charge := kart().nitro_charge
	_burn.progress = clampf(1.0 - charge, 0.0, 1.0)
	if charge <= 0.001:
		_burn.complete()
