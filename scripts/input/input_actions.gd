class_name InputActions
extends RefCounted
## Names and default bindings of every input action.
##
## Actions are registered into the InputMap at startup by [method register_defaults] instead of
## living in project.godot, so the same table drives the rebinding UI and the local multiplayer
## input router later. Bindings follow GAME.md section 4.2.

const STEER_LEFT := &"steer_left"
const STEER_RIGHT := &"steer_right"
const THROTTLE := &"throttle"
const BRAKE := &"brake"
const FIRE := &"fire"
const HANDBRAKE := &"handbrake"
const USE_ITEM := &"use_item"
const JOKER_MENU := &"joker_menu"
const JOKER_PREV := &"joker_prev"
const JOKER_NEXT := &"joker_next"
const JOKER_SELECT_1 := &"joker_select_1"
const JOKER_SELECT_2 := &"joker_select_2"
const JOKER_SELECT_3 := &"joker_select_3"
const JOKER_SELECT_4 := &"joker_select_4"
const JOKER_SELECT_5 := &"joker_select_5"
const JOKER_DROP := &"joker_drop"
const JOKER_DESTROY := &"joker_destroy"
const AIM_LEFT := &"aim_left"
const AIM_RIGHT := &"aim_right"
const AIM_UP := &"aim_up"
const AIM_DOWN := &"aim_down"
const PAUSE := &"pause"

const DEFAULT_DEADZONE := 0.2
const STICK_DEADZONE := 0.15

## Default events per action. A descriptor is one of
## {"key": Key}, {"button": JoyButton} or {"axis": JoyAxis, "value": float}.
const DEFAULTS: Dictionary[StringName, Array] = {
	STEER_LEFT: [{"key": KEY_A}, {"key": KEY_LEFT}, {"axis": JOY_AXIS_LEFT_X, "value": -1.0}],
	STEER_RIGHT: [{"key": KEY_D}, {"key": KEY_RIGHT}, {"axis": JOY_AXIS_LEFT_X, "value": 1.0}],
	THROTTLE: [{"key": KEY_W}, {"key": KEY_UP}, {"axis": JOY_AXIS_TRIGGER_RIGHT, "value": 1.0}],
	BRAKE: [{"key": KEY_S}, {"key": KEY_DOWN}, {"axis": JOY_AXIS_TRIGGER_LEFT, "value": 1.0}],
	FIRE: [{"key": KEY_SPACE}, {"button": JOY_BUTTON_RIGHT_SHOULDER}],
	HANDBRAKE: [{"key": KEY_SHIFT}, {"button": JOY_BUTTON_LEFT_SHOULDER}],
	USE_ITEM: [{"key": KEY_E}, {"button": JOY_BUTTON_A}],
	JOKER_MENU: [{"key": KEY_TAB}, {"button": JOY_BUTTON_Y}],
	JOKER_PREV: [{"key": KEY_BRACKETLEFT}, {"button": JOY_BUTTON_DPAD_LEFT}],
	JOKER_NEXT: [{"key": KEY_BRACKETRIGHT}, {"button": JOY_BUTTON_DPAD_RIGHT}],
	JOKER_SELECT_1: [{"key": KEY_1}],
	JOKER_SELECT_2: [{"key": KEY_2}],
	JOKER_SELECT_3: [{"key": KEY_3}],
	JOKER_SELECT_4: [{"key": KEY_4}],
	JOKER_SELECT_5: [{"key": KEY_5}],
	JOKER_DROP: [{"key": KEY_E}, {"button": JOY_BUTTON_A}],
	JOKER_DESTROY: [{"key": KEY_Q}, {"button": JOY_BUTTON_X}],
	AIM_LEFT: [{"axis": JOY_AXIS_RIGHT_X, "value": -1.0}],
	AIM_RIGHT: [{"axis": JOY_AXIS_RIGHT_X, "value": 1.0}],
	AIM_UP: [{"axis": JOY_AXIS_RIGHT_Y, "value": -1.0}],
	AIM_DOWN: [{"axis": JOY_AXIS_RIGHT_Y, "value": 1.0}],
	PAUSE: [{"key": KEY_ESCAPE}, {"button": JOY_BUTTON_START}],
}

## Actions driven by an analog stick get a smaller deadzone.
const STICK_ACTIONS: Array[StringName] = [
	STEER_LEFT, STEER_RIGHT, AIM_LEFT, AIM_RIGHT, AIM_UP, AIM_DOWN
]


## Every action name, in a stable order.
static func all() -> Array[StringName]:
	var names: Array[StringName] = []
	names.assign(DEFAULTS.keys())
	return names


## Registers every action with its default events. Safe to call more than once: existing events
## are replaced, so it also serves as "reset to defaults".
static func register_defaults() -> void:
	for action: StringName in DEFAULTS:
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			var deadzone := STICK_DEADZONE if action in STICK_ACTIONS else DEFAULT_DEADZONE
			InputMap.add_action(action, deadzone)
		for descriptor: Dictionary in DEFAULTS[action]:
			InputMap.action_add_event(action, make_event(descriptor))


## Builds an InputEvent from a binding descriptor.
static func make_event(descriptor: Dictionary) -> InputEvent:
	if descriptor.has("key"):
		var key := InputEventKey.new()
		key.physical_keycode = descriptor["key"]
		return key
	if descriptor.has("mouse"):
		var mouse := InputEventMouseButton.new()
		mouse.button_index = descriptor["mouse"]
		return mouse
	if descriptor.has("button"):
		var button := InputEventJoypadButton.new()
		button.button_index = descriptor["button"]
		return button
	var motion := InputEventJoypadMotion.new()
	motion.axis = descriptor["axis"]
	motion.axis_value = descriptor["value"]
	return motion


## The descriptor for an event a player pressed while rebinding, or empty when unsupported.
static func descriptor_from_event(event: InputEvent) -> Dictionary:
	var key := event as InputEventKey
	if key != null:
		return {"key": key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode}
	var mouse := event as InputEventMouseButton
	if mouse != null:
		return {"mouse": mouse.button_index}
	var button := event as InputEventJoypadButton
	if button != null:
		return {"button": button.button_index}
	var motion := event as InputEventJoypadMotion
	if motion != null:
		return {"axis": motion.axis, "value": signf(motion.axis_value)}
	return {}


## Whether a descriptor belongs to the keyboard and mouse rather than a gamepad.
static func is_keyboard_descriptor(descriptor: Dictionary) -> bool:
	return descriptor.has("key") or descriptor.has("mouse")


## Replaces the bindings of one device kind for an action with a single descriptor.
static func rebind(action: StringName, descriptor: Dictionary) -> void:
	var keyboard := is_keyboard_descriptor(descriptor)
	for event: InputEvent in InputMap.action_get_events(action):
		var existing := descriptor_from_event(event)
		if is_keyboard_descriptor(existing) == keyboard:
			InputMap.action_erase_event(action, event)
	InputMap.action_add_event(action, make_event(descriptor))


## The current descriptors of an action, for saving.
static func descriptors(action: StringName) -> Array:
	var result: Array = []
	for event: InputEvent in InputMap.action_get_events(action):
		var descriptor := descriptor_from_event(event)
		if not descriptor.is_empty():
			result.append(descriptor)
	return result


## Human-readable bindings of an action for one device kind.
static func binding_text(action: StringName, keyboard: bool) -> String:
	var parts: PackedStringArray = []
	for event: InputEvent in InputMap.action_get_events(action):
		if is_keyboard_descriptor(descriptor_from_event(event)) == keyboard:
			parts.append(event_text(event))
	return ", ".join(parts) if not parts.is_empty() else "-"


## A short name for an event: the key, or the Xbox-style name of a gamepad button or axis.
static func event_text(event: InputEvent) -> String:
	var text := event.as_text()
	if event is InputEventKey:
		return text.replace(" - Physical", "")
	var motion := event as InputEventJoypadMotion
	if event is InputEventJoypadButton or motion != null:
		var open := text.find("(")
		var close := text.find(")")
		var inner := text.substr(open + 1, close - open - 1) if open >= 0 and close > open else text
		var names := inner.split(", ")
		var chosen := names[0]
		for name: String in names:
			if name.begins_with("Xbox "):
				chosen = name.trim_prefix("Xbox ")
		if motion != null and not chosen.contains("Trigger") and chosen.length() > 2:
			chosen += " +" if motion.axis_value > 0.0 else " -"
		return chosen
	return text
