class_name InputActions
extends RefCounted
## Names and default bindings of every input action.
##
## Actions are registered into the InputMap at startup by [method register_defaults] instead of
## living in project.godot, so the same table drives the rebinding UI and the local multiplayer
## input router later. Bindings follow GAME.md section 4.2.

const STEER_LEFT := &"steer_left"
const STEER_RIGHT := &"steer_right"
## Up and down the screen, for simple driving, GAME.md 4.2, where steering left and right is left
## and right on the screen and these are the other two ways to go.
const DRIVE_UP := &"drive_up"
const DRIVE_DOWN := &"drive_down"
const THROTTLE := &"throttle"
const BRAKE := &"brake"
const FIRE := &"fire"
const HANDBRAKE := &"handbrake"
const NITRO := &"nitro"
const USE_ITEM := &"use_item"
const JOKER_MENU := &"joker_menu"
const JOKER_PREV := &"joker_prev"
const JOKER_NEXT := &"joker_next"
const JOKER_SELECT_1 := &"joker_select_1"
const JOKER_SELECT_2 := &"joker_select_2"
const JOKER_SELECT_3 := &"joker_select_3"
const JOKER_SELECT_4 := &"joker_select_4"
const JOKER_SELECT_5 := &"joker_select_5"
## The five in card order, for anything that walks the hand: one list rather than one per
## reader, since a sixth slot would otherwise have to be remembered in several places.
const JOKER_SELECTS: Array[StringName] = [
	JOKER_SELECT_1, JOKER_SELECT_2, JOKER_SELECT_3, JOKER_SELECT_4, JOKER_SELECT_5
]
const JOKER_DROP := &"joker_drop"
const JOKER_DESTROY := &"joker_destroy"
const AIM_LEFT := &"aim_left"
const AIM_RIGHT := &"aim_right"
const AIM_UP := &"aim_up"
const AIM_DOWN := &"aim_down"
## The four emotes, GAME.md 3.8, on keys of their own; on a pad they are a flick of the right
## stick, see [method PlayerInput.poll].
const EMOTE_1 := &"emote_1"
const EMOTE_2 := &"emote_2"
const EMOTE_3 := &"emote_3"
const EMOTE_4 := &"emote_4"
const EMOTES: Array[StringName] = [EMOTE_1, EMOTE_2, EMOTE_3, EMOTE_4]
## Opens the emote wheel on a keyboard, and the four ways pick from it, see [EmoteWheel].
const EMOTE_WHEEL := &"emote_wheel"
## The four ways that pick an emote from the wheel, in [constant EMOTES] order: up, right, down,
## left.
const WHEEL_WAYS: Array[StringName] = [DRIVE_UP, STEER_RIGHT, DRIVE_DOWN, STEER_LEFT]
const PAUSE := &"pause"
## Claims a device for a player in the lobby or joins a running match.
const JOIN := &"join"
## The device id the input map reads as every device at once.
const ALL_PADS := -1
## Toggles the music bus at once.
const MUTE_MUSIC := &"mute_music"

## The menu actions Godot owns, and the gamepad buttons this project adds to them. A player who
## has been driving with a pad should not have to reach for the keyboard to press a button on a
## menu, GAME.md 4.2, and project.godot defines these two with keys only. Added to rather than
## replaced, so Enter and Escape go on working.
const UI_EXTRAS: Dictionary[StringName, Array] = {
	&"ui_accept": [{"button": JOY_BUTTON_A}],
	&"ui_cancel": [{"button": JOY_BUTTON_B}],
}

const DEFAULT_DEADZONE := 0.2
const STICK_DEADZONE := 0.15
## Punctuation keys shown as the character itself instead of Godot's long key name.
const KEY_SYMBOLS: Dictionary[String, String] = {
	"BracketLeft": "[",
	"BracketRight": "]",
	"Comma": ",",
	"Period": ".",
	"Slash": "/",
	"Semicolon": ";",
	"Apostrophe": "'",
	"Minus": "-",
	"Equal": "=",
	"BackSlash": "\\",
	"QuoteLeft": "`",
}

## Default events per action. A descriptor is one of
## {"key": Key}, {"button": JoyButton} or {"axis": JoyAxis, "value": float}.
##
## On a gamepad the two things a player does with their thumb are firing and using an item, so
## they take the two buttons under it: A fires, X uses. The joker screens borrow the same two,
## A to drop and B to destroy, because destroy shares a screen with taking a joker and the two
## cannot be the same button: the pick reads take first, and skip would never be heard.
const DEFAULTS: Dictionary[StringName, Array] = {
	STEER_LEFT: [{"key": KEY_A}, {"key": KEY_LEFT}, {"axis": JOY_AXIS_LEFT_X, "value": -1.0}],
	STEER_RIGHT: [{"key": KEY_D}, {"key": KEY_RIGHT}, {"axis": JOY_AXIS_LEFT_X, "value": 1.0}],
	DRIVE_UP: [{"key": KEY_W}, {"key": KEY_UP}, {"axis": JOY_AXIS_LEFT_Y, "value": -1.0}],
	DRIVE_DOWN: [{"key": KEY_S}, {"key": KEY_DOWN}, {"axis": JOY_AXIS_LEFT_Y, "value": 1.0}],
	THROTTLE: [{"key": KEY_W}, {"key": KEY_UP}, {"axis": JOY_AXIS_TRIGGER_RIGHT, "value": 1.0}],
	BRAKE: [{"key": KEY_S}, {"key": KEY_DOWN}, {"axis": JOY_AXIS_TRIGGER_LEFT, "value": 1.0}],
	FIRE: [{"key": KEY_SPACE}, {"button": JOY_BUTTON_A}],
	HANDBRAKE: [{"key": KEY_SHIFT}, {"button": JOY_BUTTON_LEFT_SHOULDER}],
	NITRO: [{"key": KEY_CTRL}, {"button": JOY_BUTTON_RIGHT_SHOULDER}],
	USE_ITEM: [{"key": KEY_E}, {"button": JOY_BUTTON_X}],
	JOKER_MENU: [{"key": KEY_TAB}, {"button": JOY_BUTTON_Y}],
	JOKER_PREV: [{"key": KEY_BRACKETLEFT}, {"button": JOY_BUTTON_DPAD_LEFT}],
	JOKER_NEXT: [{"key": KEY_BRACKETRIGHT}, {"button": JOY_BUTTON_DPAD_RIGHT}],
	JOKER_SELECT_1: [{"key": KEY_1}],
	JOKER_SELECT_2: [{"key": KEY_2}],
	JOKER_SELECT_3: [{"key": KEY_3}],
	JOKER_SELECT_4: [{"key": KEY_4}],
	JOKER_SELECT_5: [{"key": KEY_5}],
	JOKER_DROP: [{"key": KEY_E}, {"button": JOY_BUTTON_A}],
	JOKER_DESTROY: [{"key": KEY_Q}, {"button": JOY_BUTTON_B}],
	AIM_LEFT: [{"axis": JOY_AXIS_RIGHT_X, "value": -1.0}],
	AIM_RIGHT: [{"axis": JOY_AXIS_RIGHT_X, "value": 1.0}],
	AIM_UP: [{"axis": JOY_AXIS_RIGHT_Y, "value": -1.0}],
	AIM_DOWN: [{"axis": JOY_AXIS_RIGHT_Y, "value": 1.0}],
	EMOTE_1: [{"key": KEY_7}],
	EMOTE_2: [{"key": KEY_8}],
	EMOTE_3: [{"key": KEY_9}],
	EMOTE_4: [{"key": KEY_0}],
	EMOTE_WHEEL: [{"key": KEY_V}],
	PAUSE: [{"key": KEY_ESCAPE}, {"button": JOY_BUTTON_START}],
	JOIN: [{"key": KEY_J}, {"button": JOY_BUTTON_START}],
	MUTE_MUSIC: [{"key": KEY_M}],
}

## Actions driven by an analog stick get a smaller deadzone.
const STICK_ACTIONS: Array[StringName] = [
	STEER_LEFT, STEER_RIGHT, DRIVE_UP, DRIVE_DOWN, AIM_LEFT, AIM_RIGHT, AIM_UP, AIM_DOWN
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
	_add_ui_buttons()


## Puts a pad on Godot's own menu actions. Left alone otherwise: these are not in the rebinding
## table and nothing here erases what the keyboard already has on them.
static func _add_ui_buttons() -> void:
	for action: StringName in UI_EXTRAS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, DEFAULT_DEADZONE)
		for descriptor: Dictionary in UI_EXTRAS[action]:
			var event := make_event(descriptor)
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)


## Builds an InputEvent from a binding descriptor. A pad's binding is for every pad: an event
## made in code belongs to the first pad unless told otherwise, and then only the first pad in
## the room could take a seat, pause or work a menu. Which pad is whose is the players' business,
## see [DeviceInput]; the bindings only say which button.
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
		button.device = ALL_PADS
		return button
	var motion := InputEventJoypadMotion.new()
	motion.axis = descriptor["axis"]
	motion.axis_value = descriptor["value"]
	motion.device = ALL_PADS
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


## The first event bound to an action for one device kind, or null when there is nothing bound
## to it there. What a hint draws a picture of, GAME.md 8.3: one binding, because a hint has room
## for one.
static func first_event(action: StringName, keyboard: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event: InputEvent in InputMap.action_get_events(action):
		if is_keyboard_descriptor(descriptor_from_event(event)) == keyboard:
			return event
	return null


## Human-readable bindings of an action for one device kind.
## Just the first binding, for hints with no room for a list.
static func short_binding_text(action: StringName, keyboard: bool) -> String:
	return binding_text(action, keyboard).split(", ")[0]


## The name of the stick both actions read, or an empty string when they are not two ends of the
## same one, which is what a rebinding to the D-pad or to buttons leaves them as. What tells
## [InputHint] whether two actions are one picture of a stick or two pictures of buttons.
static func shared_stick(left: StringName, right: StringName) -> String:
	var axis := _axis_of(left)
	if axis < 0 or axis != _axis_of(right):
		return ""
	if axis == JOY_AXIS_LEFT_X or axis == JOY_AXIS_LEFT_Y:
		return "Left stick"
	if axis == JOY_AXIS_RIGHT_X or axis == JOY_AXIS_RIGHT_Y:
		return "Right stick"
	return ""


static func _axis_of(action: StringName) -> int:
	if not InputMap.has_action(action):
		return -1
	for event: InputEvent in InputMap.action_get_events(action):
		var motion := event as InputEventJoypadMotion
		if motion != null:
			return motion.axis
	return -1


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
		var key := text.replace(" - Physical", "")
		return KEY_SYMBOLS.get(key, key)
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
