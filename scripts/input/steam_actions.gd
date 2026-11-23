class_name SteamActions
extends RefCounted
## The game's actions as Steam Input knows them, GAME.md 10.8 "Steam Input": the one action set,
## its two sticks and two triggers, every button action under its own name, and the layouts Steam
## starts each kind of controller on. Steam reads them from `data/steam/input/`, which
## `make steam-input` writes from here and `make steam-export` puts beside the game as
## `steam_input/`; a test keeps the two the same.
##
## A button action's name on Steam is the game's own, so Steam's word for an action is the action
## the game hears. The four ways of a dialog's cursor on WASD (`menu_up` and the rest) are left out:
## they are the keyboard's second set of arrows, and a controller has Steam's Menu up to Menu right,
## the menus' own `ui_up` to `ui_right`. So are the four ways to aim, which are the aim stick.

## The one action set: everything is in it, as everything is on a pad, since the game's menus and
## its driving share a screen too often to tell Steam which is up.
const SET := "Play"
const SET_TITLE := "Play"
## The sticks, Steam's joysticks, by Steam's name: what Steam calls it, and the actions its right
## and its down are, the stick of the game's whose axes it moves, see [SteamPads].
const STICKS: Dictionary[String, Array] = {
	"steer_stick": ["Steer and drive", InputActions.STEER_RIGHT, InputActions.DRIVE_DOWN],
	"aim_stick": ["Aim, emote and scroll", InputActions.AIM_RIGHT, InputActions.AIM_DOWN],
}
## The triggers, Steam's analog triggers: what Steam calls each, and the action it is.
const TRIGGERS: Dictionary[String, Array] = {
	"throttle_trigger": ["Throttle", InputActions.THROTTLE],
	"brake_trigger": ["Brake and reverse", InputActions.BRAKE],
}
## Every button action, by the game's name, which is Steam's too, in the order Steam lists them,
## with what Steam calls it: driving, the jokers, the emotes, the room, and the menus.
const BUTTONS: Dictionary[StringName, String] = {
	InputActions.FIRE: "Fire",
	InputActions.USE_ITEM: "Use power-up",
	InputActions.NITRO: "Nitro",
	InputActions.HANDBRAKE: "Handbrake and drift",
	InputActions.THROTTLE: "Throttle (button)",
	InputActions.BRAKE: "Brake and reverse (button)",
	InputActions.STEER_LEFT: "Steer left",
	InputActions.STEER_RIGHT: "Steer right",
	InputActions.DRIVE_UP: "Drive up (simple driving)",
	InputActions.DRIVE_DOWN: "Drive down (simple driving)",
	InputActions.JOKER_MENU: "Joker menu",
	InputActions.JOKER_PREV: "Joker menu: previous card",
	InputActions.JOKER_NEXT: "Joker menu: next card",
	InputActions.JOKER_DROP: "Joker menu: drop",
	InputActions.JOKER_DESTROY: "Joker menu: destroy",
	InputActions.JOKER_SELECT_1: "Joker card 1",
	InputActions.JOKER_SELECT_2: "Joker card 2",
	InputActions.JOKER_SELECT_3: "Joker card 3",
	InputActions.JOKER_SELECT_4: "Joker card 4",
	InputActions.JOKER_SELECT_5: "Joker card 5",
	InputActions.DETAILS: "Joker card: details",
	InputActions.EMOTE_1: "Emote 1",
	InputActions.EMOTE_2: "Emote 2",
	InputActions.EMOTE_3: "Emote 3",
	InputActions.EMOTE_4: "Emote 4",
	InputActions.EMOTE_WHEEL: "Emote wheel",
	InputActions.PAUSE: "Pause",
	InputActions.JOIN: "Join",
	InputActions.MATCH_SETTINGS: "Lobby: match settings",
	InputActions.MUTE_MUSIC: "Mute music",
	&"ui_accept": "Menu: press",
	&"ui_cancel": "Menu: back",
	&"ui_up": "Menu: up",
	&"ui_down": "Menu: down",
	&"ui_left": "Menu: left",
	&"ui_right": "Menu: right",
	InputActions.MENU_PAGE_PREV: "Menu: previous page",
	InputActions.MENU_PAGE_NEXT: "Menu: next page",
	InputActions.MENU_VIEW: "Menu: view",
	InputActions.MENU_OPTION: "Menu: option",
	InputActions.MENU_FILTER: "Menu: filter",
	InputActions.MENU_SORT: "Menu: sort",
	InputActions.MENU_NEXT_NEW: "Menu: next new",
	InputActions.MENU_HELP: "Menu: help",
}
## The menus' own buttons on a pad, Godot's, which [constant InputActions.DEFAULTS] has no part in:
## the A and B of [constant InputActions.UI_EXTRAS] and the D-pad's four ways.
const MENU_PAD: Dictionary[StringName, int] = {
	&"ui_accept": JOY_BUTTON_A,
	&"ui_cancel": JOY_BUTTON_B,
	&"ui_up": JOY_BUTTON_DPAD_UP,
	&"ui_down": JOY_BUTTON_DPAD_DOWN,
	&"ui_left": JOY_BUTTON_DPAD_LEFT,
	&"ui_right": JOY_BUTTON_DPAD_RIGHT,
}
## Where each of a pad's buttons is on Steam's layouts: its group's source and the input in it.
const SOURCES: Dictionary[int, Array] = {
	JOY_BUTTON_A: ["button_diamond", "button_a"],
	JOY_BUTTON_B: ["button_diamond", "button_b"],
	JOY_BUTTON_X: ["button_diamond", "button_x"],
	JOY_BUTTON_Y: ["button_diamond", "button_y"],
	JOY_BUTTON_START: ["switch", "button_escape"],
	JOY_BUTTON_BACK: ["switch", "button_menu"],
	JOY_BUTTON_LEFT_SHOULDER: ["switch", "left_bumper"],
	JOY_BUTTON_RIGHT_SHOULDER: ["switch", "right_bumper"],
	JOY_BUTTON_DPAD_UP: ["dpad", "dpad_north"],
	JOY_BUTTON_DPAD_DOWN: ["dpad", "dpad_south"],
	JOY_BUTTON_DPAD_RIGHT: ["dpad", "dpad_east"],
	JOY_BUTTON_DPAD_LEFT: ["dpad", "dpad_west"],
	JOY_BUTTON_LEFT_STICK: ["joystick", "click"],
	JOY_BUTTON_RIGHT_STICK: ["right_joystick", "click"],
}
## Where each stick and trigger is: its source, by the axis of the game's it moves.
const AXIS_SOURCES: Dictionary[int, String] = {
	JOY_AXIS_LEFT_X: "joystick",
	JOY_AXIS_RIGHT_X: "right_joystick",
	JOY_AXIS_TRIGGER_LEFT: "left_trigger",
	JOY_AXIS_TRIGGER_RIGHT: "right_trigger",
}
## Each group's mode on Steam's layouts, by its source.
const MODES: Dictionary[String, String] = {
	"button_diamond": "four_buttons",
	"switch": "switches",
	"dpad": "dpad",
	"joystick": "joystick_move",
	"right_joystick": "joystick_move",
	"left_trigger": "trigger",
	"right_trigger": "trigger",
}
## The kinds of controller a layout is written for, Steam's names, in the manifest's order: an Xbox
## pad's covers the Xbox 360's too. The original Steam Controller has no right stick and no D-pad:
## its right trackpad is the right stick and its left trackpad the D-pad, see [constant STAND_INS].
const CONTROLLERS: Array[String] = [
	"controller_xboxone",
	"controller_ps4",
	"controller_ps5",
	"controller_switch_pro",
	"controller_neptune",
	"controller_triton",
	"controller_steamcontroller_gordon",
	"controller_generic",
]
## A source a kind of controller lacks, and the one standing in for it there.
const STAND_INS: Dictionary[String, Dictionary] = {
	"controller_steamcontroller_gordon":
	{
		"right_joystick": "right_trackpad",
		"dpad": "left_trackpad",
	},
}
## What each layout is called on Steam, and what it says it is.
const LAYOUT_TITLE := "Jackpot Junction"
const LAYOUT_SAYS := "The game's own layout: every button where the game's own pad has it."
## The manifest's file, and where Steam's files are kept in the project.
const MANIFEST := "action_manifest.vdf"
const FOLDER := "res://data/steam/input"


## Every action Steam is told of, the game's names of the sticks' and triggers' actions among them.
static func actions() -> Array[StringName]:
	var all: Array[StringName] = []
	all.assign(BUTTONS.keys())
	for stick: String in STICKS:
		all.append_array([STICKS[stick][1], STICKS[stick][2]] as Array[StringName])
	for trigger: String in TRIGGERS:
		all.append(TRIGGERS[trigger][1] as StringName)
	return all


## The pad's buttons [param action] is on as the game starts, of the defaults, the dialogs' binds
## and the menus', see [constant MENU_PAD]; none for one only on a stick, a trigger or the keys.
static func pad_buttons(action: StringName) -> Array[int]:
	var buttons: Array[int] = []
	if MENU_PAD.has(action):
		buttons.append(MENU_PAD[action])
	for table: Dictionary[StringName, Array] in [InputActions.DEFAULTS, InputActions.MENU]:
		for descriptor: Dictionary in table.get(action, []):
			if descriptor.has("button"):
				buttons.append(int(descriptor["button"]))
	return buttons


## The axis of the game's [param action] moves as the game starts, a stick's or a trigger's.
static func pad_axis(action: StringName) -> int:
	for descriptor: Dictionary in InputActions.DEFAULTS.get(action, []):
		if descriptor.has("axis"):
			return int(descriptor["axis"])
	return -1


## The action manifest, GAME.md 10.8: the action set with its actions, the layout of each kind of
## controller, and the words for each, which Steam shows in its controller settings.
static func manifest() -> String:
	var configurations: Array = []
	for controller: String in CONTROLLERS:
		configurations.append([controller, [["0", [["path", controller + ".vdf"]]]]])
	return vdf(
		[
			[
				"Action Manifest",
				[
					["configurations", configurations],
					["actions", _actions(false)],
					["localization", [["english", _words(false)]]],
				]
			]
		]
	)


## The layout [param controller], one of [constant CONTROLLERS], starts on: every button of the
## game's pad bound to the actions it is bound to as the game starts, which on a pad's own button
## Steam presses all at once, the left stick steering, the right one aiming and the triggers the
## pedals, as on the game's own pad.
static func layout(controller: String) -> String:
	var groups: Array = []
	var bound: Dictionary[String, int] = {}
	var inputs := _inputs()
	for source: String in MODES:
		var actions_of: Array = []
		for input: String in inputs.get(source, {}):
			var bindings: Array = []
			for action: StringName in inputs[source][input]:
				bindings.append(
					["binding", "game_action %s %s, %s" % [SET, action, BUTTONS[action]]]
				)
			var activators := [["Full_Press", [["bindings", bindings]]]]
			actions_of.append([input, [["activators", activators]]])
		var analog := _analog_on(source)
		var group: Array = [
			["id", str(groups.size())],
			["mode", MODES[source]],
			["name", ""],
			["description", ""],
			["inputs", actions_of],
		]
		if not analog.is_empty():
			group.append(["gameactions", [[SET, analog]]])
		bound[_source_on(controller, source)] = groups.size()
		groups.append(["group", group])
	var sources: Array = []
	for here: String in bound:
		sources.append([str(bound[here]), "%s active" % here])
	var body: Array = [
		["version", "3"],
		["revision", "1"],
		["title", "#Title"],
		["description", "#Description"],
		["controller_type", controller],
		["major_revision", "0"],
		["minor_revision", "0"],
		["actions", _actions(true)],
		["localization", [["english", _words(true)]]],
	]
	body.append_array(groups)
	body.append(["preset", [["id", "0"], ["name", SET], ["group_source_bindings", sources]]])
	body.append(["settings", [["left_trackpad_mode", "0"], ["right_trackpad_mode", "0"]]])
	return vdf([["controller_mappings", body]])


## Every file of Steam's, by its name in [constant FOLDER]: the manifest and each layout.
static func files() -> Dictionary[String, String]:
	var all: Dictionary[String, String] = {MANIFEST: manifest()}
	for controller: String in CONTROLLERS:
		all[controller + ".vdf"] = layout(controller)
	return all


## The buttons bound on a layout, by source and input, each with the actions it is bound to.
static func _inputs() -> Dictionary[String, Dictionary]:
	var inputs: Dictionary[String, Dictionary] = {}
	for action: StringName in BUTTONS:
		for button: int in pad_buttons(action):
			var at: Array = SOURCES[button]
			if not inputs.has(at[0]):
				inputs[at[0]] = {}
			var on: Dictionary = inputs[at[0]]
			if not on.has(at[1]):
				on[at[1]] = [] as Array[StringName]
			(on[at[1]] as Array[StringName]).append(action)
	return inputs


## The stick or trigger action [param source] is, or empty.
static func _analog_on(source: String) -> String:
	for stick: String in STICKS:
		if AXIS_SOURCES.get(pad_axis(STICKS[stick][1]), "") == source:
			return stick
	for trigger: String in TRIGGERS:
		if AXIS_SOURCES.get(pad_axis(TRIGGERS[trigger][1]), "") == source:
			return trigger
	return ""


## The source [param controller] has in [param source]'s place, see [constant STAND_INS].
static func _source_on(controller: String, source: String) -> String:
	return STAND_INS.get(controller, {}).get(source, source)


## The action set, as the manifest has it, and as a layout does, with `legacy_set` beside it.
static func _actions(in_layout: bool) -> Array:
	var play: Array = [["title", "#Set_" + SET]]
	if in_layout:
		play.append(["legacy_set", "0"])
	var sticks: Array = []
	for stick: String in STICKS:
		sticks.append([stick, [["title", "#Action_" + stick], ["input_mode", "joystick_move"]]])
	var triggers: Array = []
	for trigger: String in TRIGGERS:
		triggers.append([trigger, "#Action_" + trigger])
	var buttons: Array = []
	for action: StringName in BUTTONS:
		buttons.append([String(action), "#Action_" + action])
	play.append_array([["StickPadGyro", sticks], ["AnalogTrigger", triggers], ["Button", buttons]])
	return [[SET, play]]


## The words in English: the set's and every action's, and a layout's own title and description.
static func _words(in_layout: bool) -> Array:
	var words: Array = []
	if in_layout:
		words.append_array([["Title", LAYOUT_TITLE], ["Description", LAYOUT_SAYS]])
	words.append(["Set_" + SET, SET_TITLE])
	for stick: String in STICKS:
		words.append(["Action_" + stick, STICKS[stick][0]])
	for trigger: String in TRIGGERS:
		words.append(["Action_" + trigger, TRIGGERS[trigger][0]])
	for action: StringName in BUTTONS:
		words.append(["Action_" + action, BUTTONS[action]])
	return words


## [param pairs], each a key and either its words or the pairs inside it, in Valve's KeyValues
## text as Steam writes it: tabs, every key and value quoted, a key free to come more than once.
## Nothing here has a quote or a backslash in it to escape.
static func vdf(pairs: Array, depth := 0) -> String:
	var lines := ""
	var indent := "\t".repeat(depth)
	for pair: Array in pairs:
		var value: Variant = pair[1]
		if value is Array:
			lines += '%s"%s"\n%s{\n' % [indent, pair[0], indent]
			lines += vdf(value, depth + 1)
			lines += "%s}\n" % indent
		else:
			lines += '%s"%s"\t\t"%s"\n' % [indent, pair[0], value]
	return lines
