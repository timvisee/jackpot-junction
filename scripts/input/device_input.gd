class_name DeviceInput
extends RefCounted
## Reads input actions for one specific device, so several local players can share one set of
## action names. [constant KEYBOARD] reads keys and mouse buttons, a joypad id reads that joypad
## only, and [constant ANY] reads every device like the plain Input singleton does.

const ANY := -2
const KEYBOARD := -1

## The devices input came from, the most recent first, each once, in the menus as much as in a
## match, see [method touched]: what a player reading every device was holding before somebody
## else picked up a pad, GAME.md 9.2, when they have not driven yet to say so themselves.
static var recent: Array[int] = []


## [param device] was just used: the keyboard and mouse as [constant KEYBOARD], or a pad's id.
static func touched(device: int) -> void:
	if not recent.is_empty() and recent[0] == device:
		return
	recent.erase(device)
	recent.push_front(device)


## The device used most recently other than [param besides], or [constant ANY] for none.
static func last_besides(besides: int) -> int:
	for device: int in recent:
		if device != besides:
			return device
	return ANY


## Whether hints for this device should name keys or gamepad buttons. A player pinned to one
## device gets that device's; one reading every device follows whatever was last touched.
static func uses_keyboard(device: int) -> bool:
	if device == KEYBOARD:
		return true
	if device == ANY:
		return Game.last_input_keyboard
	return false


static func strength(action: StringName, device: int) -> float:
	if device == ANY:
		return Input.get_action_strength(action)
	var deadzone := InputMap.action_get_deadzone(action)
	var best := 0.0
	for event: InputEvent in InputMap.action_get_events(action):
		best = maxf(best, _event_strength(event, device, deadzone))
	return best


## How far [param action] is pushed on a gamepad alone, its keys and mouse buttons left out: on the
## pad [param device] is, on any pad for [constant ANY], and not at all for the keyboard.
static func pad_strength(action: StringName, device: int) -> float:
	if device == KEYBOARD:
		return 0.0
	var pads: Array[int] = []
	if device == ANY:
		pads.assign(Input.get_connected_joypads())
	else:
		pads.append(device)
	var deadzone := InputMap.action_get_deadzone(action)
	var best := 0.0
	for event: InputEvent in InputMap.action_get_events(action):
		if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
			continue
		for pad: int in pads:
			best = maxf(best, _event_strength(event, pad, deadzone))
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
