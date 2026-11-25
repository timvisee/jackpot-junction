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
## Held to read more on a joker's card, GAME.md 8.3: how far it stacks, and beside each number a
## stack has changed, what one copy says.
const DETAILS := &"details"
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
## The large dialogs' own binds, GAME.md 8.5, the same in the loyalty program, the catalog and the
## achievements: the page before and after, the view, the second option, and WASD beside the arrows
## for the cursor. Fixed, and none of them the kart's or the hand's, which a player may move: a
## dialog's keys are where its hints say, whatever was rebound for driving. See [constant MENU].
const MENU_PAGE_PREV := &"menu_page_prev"
const MENU_PAGE_NEXT := &"menu_page_next"
const MENU_VIEW := &"menu_view"
const MENU_OPTION := &"menu_option"
## And the catalog's two more, GAME.md 8.8: the suit its jokers are shown for, and their order.
const MENU_FILTER := &"menu_filter"
const MENU_SORT := &"menu_sort"
## The cursor to the next thing wearing NEW, in all three, see [NextNew]: N, and a pad's View, the
## button left of its middle, which nothing else in the game is on.
const MENU_NEXT_NEW := &"menu_next_new"
## And the loyalty program's, GAME.md 8.9: How it works, the House's first look shown again,
## H and a pad's left stick pressed in, which nothing else in a dialog is on.
const MENU_HELP := &"menu_help"
## The match settings in the lobby, GAME.md 9.6, for whoever chooses the match there: E, which
## nothing in the lobby uses, there being no items in it, and a pad's View, which nothing in a room
## is on. Fixed, as a dialog's binds are, see [constant MENU].
const MATCH_SETTINGS := &"match_settings"
const MENU_UP := &"menu_up"
const MENU_DOWN := &"menu_down"
const MENU_LEFT := &"menu_left"
const MENU_RIGHT := &"menu_right"
## Which way each of WASD moves a dialog's cursor.
const MENU_MOVES: Dictionary[StringName, Vector2i] = {
	MENU_UP: Vector2i.UP,
	MENU_DOWN: Vector2i.DOWN,
	MENU_LEFT: Vector2i.LEFT,
	MENU_RIGHT: Vector2i.RIGHT
}
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
## The first of the buttons no pad has, which a controller of Steam Input's presses for a few
## actions at once where no button of the pad's own does just those, see [method chord]: past
## every button the engine names, and below the most it reads, 128.
const CHORD_FROM := 64
const CHORD_TO := 128

## A pad's buttons by the names today's pads print on them where the engine's are an older pad's:
## the button left of the middle is Back to the engine, after the Xbox 360's, which beside a
## dialog's own Back button reads as that one; today's Xbox calls it View, as the engine already
## calls Start by today's Menu.
## A PlayStation pad's touchpad is "PS4/5 Touchpad" to the engine, which is the pads it is on.
const PAD_NAMES: Dictionary[String, String] = {"Back": "View", "PS4/5 Touchpad": "Touchpad"}

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
	DETAILS: [{"key": KEY_ALT}, {"button": JOY_BUTTON_RIGHT_STICK}],
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
## The dialogs' binds, see [constant MENU_VIEW]: registered with the defaults, never rebound or
## kept in the settings.
const MENU: Dictionary[StringName, Array] = {
	MENU_PAGE_PREV: [{"key": KEY_Q}, {"button": JOY_BUTTON_LEFT_SHOULDER}],
	MENU_PAGE_NEXT: [{"key": KEY_E}, {"button": JOY_BUTTON_RIGHT_SHOULDER}],
	MENU_VIEW: [{"key": KEY_TAB}, {"button": JOY_BUTTON_Y}],
	MENU_OPTION: [{"key": KEY_F}, {"button": JOY_BUTTON_X}],
	MENU_FILTER: [{"key": KEY_R}, {"axis": JOY_AXIS_TRIGGER_RIGHT, "value": 1.0}],
	MENU_SORT: [{"key": KEY_T}, {"axis": JOY_AXIS_TRIGGER_LEFT, "value": 1.0}],
	MENU_NEXT_NEW: [{"key": KEY_N}, {"button": JOY_BUTTON_BACK}],
	MENU_HELP: [{"key": KEY_H}, {"button": JOY_BUTTON_LEFT_STICK}],
	MATCH_SETTINGS: [{"key": KEY_E}, {"button": JOY_BUTTON_BACK}],
	MENU_UP: [{"key": KEY_W}],
	MENU_DOWN: [{"key": KEY_S}],
	MENU_LEFT: [{"key": KEY_A}],
	MENU_RIGHT: [{"key": KEY_D}],
}

## Actions driven by an analog stick get a smaller deadzone.
const STICK_ACTIONS: Array[StringName] = [
	STEER_LEFT, STEER_RIGHT, DRIVE_UP, DRIVE_DOWN, AIM_LEFT, AIM_RIGHT, AIM_UP, AIM_DOWN
]

## The key printed on the player's own keyboard at a key's place, GAME.md 8.3: keys are bound by
## where they are, so an AZERTY keyboard's Z is the key a QWERTY one calls W, and it is named Z.
## The system's word on it, which a test stands in for; none where nothing is shown, the headless
## server's and the tests', which cannot say and complain at every key asked.
static var label_of := (
	Callable()
	if DisplayServer.get_name() == "headless"
	else Callable(DisplayServer, &"keyboard_get_label_from_physical")
)
## The chords handed out so far, see [method chord]: the button of each set of actions, by the
## actions' names joined.
static var _chords: Dictionary[String, int] = {}


## Every action name, in a stable order.
static func all() -> Array[StringName]:
	var names: Array[StringName] = []
	names.assign(DEFAULTS.keys())
	return names


## Registers every action with its default events. Safe to call more than once: existing events
## are replaced, so it also serves as "reset to defaults".
static func register_defaults() -> void:
	for table: Dictionary[StringName, Array] in [DEFAULTS, MENU]:
		for action: StringName in table:
			if InputMap.has_action(action):
				InputMap.action_erase_events(action)
			else:
				var deadzone := STICK_DEADZONE if action in STICK_ACTIONS else DEFAULT_DEADZONE
				InputMap.add_action(action, deadzone)
			for descriptor: Dictionary in table[action]:
				InputMap.action_add_event(action, make_event(descriptor))
	_add_ui_buttons()


## The player's own bindings, [param bindings] (action names to descriptors, as the settings keep
## them), put over the defaults, and [param deadzone] on the sticks, GAME.md 4.2.
static func apply(bindings: Dictionary, deadzone: float) -> void:
	register_defaults()
	for action: String in bindings:
		var descriptors: Array = bindings[action]
		var name := StringName(action)
		if not InputMap.has_action(name):
			continue
		InputMap.action_erase_events(name)
		for descriptor: Dictionary in descriptors:
			InputMap.action_add_event(name, make_event(descriptor))
	for action: StringName in STICK_ACTIONS:
		InputMap.action_set_deadzone(action, deadzone)


## The button no pad has that stands for [param actions] all at once, GAME.md 10.8, bound to each
## of them and to nothing else, or -1 once every one is taken. A controller of Steam Input's
## presses it where one of its buttons is bound to these actions in Steam and no button of the
## pad's own is bound to just these here: one press, as a pad's own is, which every one of them
## hears and nothing else does. A screen that takes a press of one action over another's, as the
## joker pick takes A as the pick before the drop, then hears it once, as it would a pad's own A.
## Bound again if the bindings were put back since, as [method apply] does.
static func chord(actions: Array[StringName]) -> int:
	var names: PackedStringArray = []
	for action: StringName in actions:
		names.append(action)
	names.sort()
	var key := ",".join(names)
	if not _chords.has(key):
		if CHORD_FROM + _chords.size() >= CHORD_TO:
			return -1
		_chords[key] = CHORD_FROM + _chords.size()
	var event := make_event({"button": _chords[key]})
	for action: StringName in actions:
		if InputMap.has_action(action) and not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)
	return _chords[key]


## Every chord taken off the actions again, see [method chord], as Steam Input stops.
static func forget_chords() -> void:
	for action: StringName in InputMap.get_actions():
		for event: InputEvent in InputMap.action_get_events(action):
			if is_chord(event):
				InputMap.action_erase_event(action, event)
	_chords.clear()


## Whether [param event] is one of the buttons no pad has, see [method chord].
static func is_chord(event: InputEvent) -> bool:
	var button := event as InputEventJoypadButton
	return button != null and button.button_index >= CHORD_FROM


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


## The descriptor for an event a player pressed while rebinding, or empty when unsupported, as a
## chord is, which is Steam Input's and never kept, see [method chord].
static func descriptor_from_event(event: InputEvent) -> Dictionary:
	if is_chord(event):
		return {}
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
		if not existing.is_empty() and is_keyboard_descriptor(existing) == keyboard:
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
		var descriptor := descriptor_from_event(event)
		if not descriptor.is_empty() and is_keyboard_descriptor(descriptor) == keyboard:
			return event
	return null


## Human-readable bindings of an action for one device kind.
## Just the first binding, for hints with no room for a list. A pad's buttons are named as
## [param family] has them, see [PadFamily]; for -1, the family of the pad touched last.
static func short_binding_text(action: StringName, keyboard: bool, family: int = -1) -> String:
	return binding_text(action, keyboard, family).split(", ")[0]


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


static func binding_text(action: StringName, keyboard: bool, family: int = -1) -> String:
	var parts: PackedStringArray = []
	for event: InputEvent in InputMap.action_get_events(action):
		var descriptor := descriptor_from_event(event)
		if not descriptor.is_empty() and is_keyboard_descriptor(descriptor) == keyboard:
			parts.append(event_text(event, family))
	return ", ".join(parts) if not parts.is_empty() else "-"


## A short name for an event: the key, or the name of a gamepad button or axis as [param family]
## prints it, see [PadFamily], and for -1 as the pad touched last does.
static func event_text(event: InputEvent, family: int = -1) -> String:
	var text := event.as_text()
	var pressed := event as InputEventKey
	if pressed != null:
		var printed := _printed(pressed)
		if not printed.is_empty():
			return printed
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
		# A stick's click is "R/RS" to Godot, the stick and its click: the click is the button. A name
		# of words with a slash in it is one name, "PS4/5 Touchpad", which cut there was "5 Touchpad".
		if not chosen.contains(" "):
			chosen = chosen.get_slice("/", chosen.get_slice_count("/") - 1)
		if motion != null and not chosen.contains("Trigger") and chosen.length() > 2:
			chosen += " +" if motion.axis_value > 0.0 else " -"
		return PadFamily.word(PAD_NAMES.get(chosen, chosen) if motion == null else chosen, family)
	return text


## What the player's own keyboard prints on the key [param pressed] is bound to by its place, see
## [member label_of], where that is a letter or a sign other than the one the engine names it by;
## empty where it is the same, for a key with a name rather than a sign, Space or Ctrl, and where
## the system does not say.
static func _printed(pressed: InputEventKey) -> String:
	if pressed.physical_keycode == KEY_NONE or not label_of.is_valid():
		return ""
	var label := int(label_of.call(pressed.physical_keycode))
	if label == pressed.physical_keycode or label <= KEY_SPACE or label >= KEY_SPECIAL:
		return ""
	return String.chr(label).to_upper()
