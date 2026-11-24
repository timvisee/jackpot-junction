class_name DeviceInput
extends RefCounted
## Reads input actions for one specific device, so several local players can share one set of
## action names. [constant KEYBOARD] reads keys and mouse buttons, a joypad id reads that joypad
## only, and [constant ANY] reads every device like the plain Input singleton does.

const ANY := -2
const KEYBOARD := -1
## How far a pad's light bends its weaker channels down, see [method led]: between none and a
## screen's own 2.2, an LED's light growing with its value where a screen's barely does at first.
const LED_CURVE := 1.6
## Below this saturation a color is a gray, and a pad is lit in it as it is.
const LED_GRAY := 0.1

## The devices input came from, the most recent first, each once, in the menus as much as in a
## match, see [method touched]: what a player reading every device was holding before somebody
## else picked up a pad, GAME.md 9.2, when they have not driven yet to say so themselves.
static var recent: Array[int] = []
## The pads Steam Input reads for the game, GAME.md 10.8, each by the id the game knows it by and
## its [enum PadFamily.Family]: they are no pads of the engine's, which never sees them, see
## [SteamPads]. Empty with no Steam Input.
static var steam_pads: Dictionary[int, int] = {}
## Knocks one of [member steam_pads], as [method rumble] is asked: the pad, how hard its light
## motor and its heavy one go, and for how long. Set by [SteamPads]; nothing without it.
static var steam_rumble := Callable()
## Lights one of [member steam_pads] in a color, or with null puts the player's own back, as
## [method light] and [method unlight] are asked. Set by [SteamPads]; nothing without it.
static var steam_light := Callable()
## Where Steam has an action bound on one of [member steam_pads], for a hint to draw, see
## [method SteamPads.place]. Set by [SteamPads]; nothing without it.
static var steam_place := Callable()


## Every pad there is: the engine's, then Steam Input's, see [member steam_pads].
static func pads() -> Array[int]:
	var all: Array[int] = []
	all.assign(Input.get_connected_joypads())
	all.append_array(steam_pads.keys())
	return all


## The pads plugged in, in the order the menus number them, Gamepad 1 first: the engine's by their
## ids, then Steam Input's by theirs.
static func numbered() -> Array[int]:
	var engine: Array[int] = []
	engine.assign(Input.get_connected_joypads())
	engine.sort()
	var steam: Array[int] = []
	steam.assign(steam_pads.keys())
	steam.sort()
	engine.append_array(steam)
	return engine


## Which gamepad [param device] is, from 1, as the menus say it, see [method numbered]; 0 for one
## not plugged in.
static func number_of(device: int) -> int:
	return numbered().find(device) + 1


## Knocks the pad [param pad], its light motor [param weak] and its heavy one [param strong], 0 to
## 1, for [param seconds], GAME.md 4.2: through Steam for a pad of Steam Input's.
static func rumble(pad: int, weak: float, strong: float, seconds: float) -> void:
	if steam_pads.has(pad):
		if steam_rumble.is_valid():
			steam_rumble.call(pad, weak, strong, seconds)
		return
	Input.start_joy_vibration(pad, weak, strong, seconds)


## Lights the pad [param pad] in [param color], its seat's, see [PadLights]: through Steam for a pad
## of Steam Input's, and on a pad the engine reads where it has a light. Lit as [method led] has it.
static func light(pad: int, color: Color) -> void:
	var lit := led(color)
	if steam_pads.has(pad):
		if steam_light.is_valid():
			steam_light.call(pad, lit)
		return
	if Input.get_connected_joypads().has(pad) and Input.has_joy_light(pad):
		Input.set_joy_light(pad, lit)


## [param color] as a pad's light is to show it, GAME.md 10.8: its hue at full strength and with no
## white in it, its weaker channel bent down by [constant LED_CURVE]. Lit as a screen draws it, the
## white under every player color made a light bar glow nearly white whatever the color. A gray
## stays as it is.
static func led(color: Color) -> Color:
	if color.s < LED_GRAY:
		return color
	var full := Color.from_hsv(color.h, 1.0, 1.0)
	return Color(pow(full.r, LED_CURVE), pow(full.g, LED_CURVE), pow(full.b, LED_CURVE))


## Gives the pad [param pad] its own light back after [method light]: the player's color in Steam
## for a pad of Steam Input's. One the engine reads keeps the last, the engine having no way back.
static func unlight(pad: int) -> void:
	if steam_pads.has(pad) and steam_light.is_valid():
		steam_light.call(pad, null)


## How a hint draws [param action] for [param pad] as Steam has it bound, GAME.md 10.8, see
## [method SteamPads.place]; empty for a pad the game binds itself, not one of [member steam_pads].
static func steam_bound(action: StringName, pad: int) -> Dictionary:
	if not steam_pads.has(pad) or not steam_place.is_valid():
		return {}
	return steam_place.call(action, pad)


## [param device] was just used: the keyboard and mouse as [constant KEYBOARD], or a pad's id.
static func touched(device: int) -> void:
	PadFamily.touched(device)
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
		pads.assign(pads())
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
