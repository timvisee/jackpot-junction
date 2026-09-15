class_name PlayerInput
extends KartInput
## Reads the input map. Per-device routing for local multiplayer arrives in M5; until then every
## connected device drives this input.

var _fire_was_down := false
var _use_was_down := false


func poll(_delta: float) -> void:
	steer = (
		Input.get_action_strength(InputActions.STEER_RIGHT)
		- Input.get_action_strength(InputActions.STEER_LEFT)
	)
	throttle = Input.get_action_strength(InputActions.THROTTLE)
	brake = Input.get_action_strength(InputActions.BRAKE)
	handbrake = Input.is_action_pressed(InputActions.HANDBRAKE)
	fire = Input.is_action_pressed(InputActions.FIRE)
	fire_pressed = fire and not _fire_was_down
	_fire_was_down = fire
	var use_down := Input.is_action_pressed(InputActions.USE_ITEM)
	use_item_pressed = use_down and not _use_was_down
	_use_was_down = use_down
