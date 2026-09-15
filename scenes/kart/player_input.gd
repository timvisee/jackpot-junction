class_name PlayerInput
extends KartInput
## Reads the input map for one device. [constant DeviceInput.ANY] lets every device drive the
## kart, which suits single-player; local multiplayer gives each slot its own device.

var device := DeviceInput.ANY

var _fire_was_down := false
var _use_was_down := false


func _init(input_device: int = DeviceInput.ANY) -> void:
	device = input_device


func poll(_delta: float) -> void:
	steer = (
		DeviceInput.strength(InputActions.STEER_RIGHT, device)
		- DeviceInput.strength(InputActions.STEER_LEFT, device)
	)
	throttle = DeviceInput.strength(InputActions.THROTTLE, device)
	brake = DeviceInput.strength(InputActions.BRAKE, device)
	handbrake = DeviceInput.pressed(InputActions.HANDBRAKE, device)
	fire = DeviceInput.pressed(InputActions.FIRE, device)
	fire_pressed = fire and not _fire_was_down
	_fire_was_down = fire
	var use_down := DeviceInput.pressed(InputActions.USE_ITEM, device)
	use_item_pressed = use_down and not _use_was_down
	_use_was_down = use_down
