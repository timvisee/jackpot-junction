class_name PlayerInput
extends KartInput
## Reads the input map for one device. [constant DeviceInput.ANY] lets every device drive the
## kart, which suits single-player; local multiplayer gives each slot its own device.

const SELECTS: Array[StringName] = [
	InputActions.JOKER_SELECT_1,
	InputActions.JOKER_SELECT_2,
	InputActions.JOKER_SELECT_3,
	InputActions.JOKER_SELECT_4,
	InputActions.JOKER_SELECT_5,
]

var device := DeviceInput.ANY

var _fire_was_down := false
var _use_was_down := false
var _was_down: Dictionary[StringName, bool] = {}


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
	aim = Vector2(
		(
			DeviceInput.strength(InputActions.AIM_RIGHT, device)
			- DeviceInput.strength(InputActions.AIM_LEFT, device)
		),
		(
			DeviceInput.strength(InputActions.AIM_DOWN, device)
			- DeviceInput.strength(InputActions.AIM_UP, device)
		)
	)
	fire = DeviceInput.pressed(InputActions.FIRE, device)
	fire_pressed = fire and not _fire_was_down
	_fire_was_down = fire
	var use_down := DeviceInput.pressed(InputActions.USE_ITEM, device)
	use_item_pressed = use_down and not _use_was_down
	_use_was_down = use_down
	joker_menu = DeviceInput.pressed(InputActions.JOKER_MENU, device)
	joker_prev_pressed = _just_pressed(InputActions.JOKER_PREV)
	joker_next_pressed = _just_pressed(InputActions.JOKER_NEXT)
	joker_drop_pressed = _just_pressed(InputActions.JOKER_DROP)
	joker_destroy_pressed = _just_pressed(InputActions.JOKER_DESTROY)
	joker_select = -1
	for i: int in SELECTS.size():
		if _just_pressed(SELECTS[i]):
			joker_select = i


func _just_pressed(action: StringName) -> bool:
	var down := DeviceInput.pressed(action, device)
	var was: bool = _was_down.get(action, false)
	_was_down[action] = down
	return down and not was
