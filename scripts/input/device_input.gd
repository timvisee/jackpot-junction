class_name DeviceInput
extends RefCounted
## Reads input actions for one specific device, so several local players can share one set of
## action names. [constant KEYBOARD] reads keys and mouse buttons, a joypad id reads that joypad
## only, and [constant ANY] reads every device like the plain Input singleton does.

const ANY := -2
const KEYBOARD := -1


static func strength(action: StringName, device: int) -> float:
	if device == ANY:
		return Input.get_action_strength(action)
	var deadzone := InputMap.action_get_deadzone(action)
	var best := 0.0
	for event: InputEvent in InputMap.action_get_events(action):
		best = maxf(best, _event_strength(event, device, deadzone))
	return best


static func pressed(action: StringName, device: int) -> bool:
	if device == ANY:
		return Input.is_action_pressed(action)
	return strength(action, device) > 0.5


static func _event_strength(event: InputEvent, device: int, deadzone: float) -> float:
	var key := event as InputEventKey
	if key != null:
		if device != KEYBOARD:
			return 0.0
		if key.physical_keycode != KEY_NONE:
			return 1.0 if Input.is_physical_key_pressed(key.physical_keycode) else 0.0
		return 1.0 if Input.is_key_pressed(key.keycode) else 0.0
	var mouse := event as InputEventMouseButton
	if mouse != null:
		if device != KEYBOARD:
			return 0.0
		return 1.0 if Input.is_mouse_button_pressed(mouse.button_index) else 0.0
	if device < 0:
		return 0.0
	var button := event as InputEventJoypadButton
	if button != null:
		return 1.0 if Input.is_joy_button_pressed(device, button.button_index) else 0.0
	var motion := event as InputEventJoypadMotion
	if motion != null:
		var value := Input.get_joy_axis(device, motion.axis)
		if signf(value) != signf(motion.axis_value):
			return 0.0
		var magnitude := absf(value)
		if magnitude < deadzone:
			return 0.0
		return clampf((magnitude - deadzone) / (1.0 - deadzone), 0.0, 1.0)
	return 0.0
