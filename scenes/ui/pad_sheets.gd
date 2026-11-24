class_name PadSheets
extends RefCounted
## What each sheet of Show controls' blueprint says, GAME.md 8.3b, see [PadLeaflet] and
## [KeyboardDiagram]: the actions each page names with their words and red-pen notes, what it says
## at each button of a pad as the actions are bound, and several things on one button as one line.


## What each page names, in order: the actions, the words for them, and a note in red pen.
static func entries(on_page: int, simple_driving: bool) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	match on_page:
		0:
			list.append(_entry([InputActions.THROTTLE], "Gas", "squeeze, don't stab"))
			list.append(_entry([InputActions.BRAKE], "Brake"))
			if simple_driving:
				var ways: Array[StringName] = [
					InputActions.STEER_LEFT,
					InputActions.STEER_RIGHT,
					InputActions.DRIVE_UP,
					InputActions.DRIVE_DOWN,
				]
				list.append(_entry(ways, "Drive"))
			else:
				list.append(_entry([InputActions.STEER_LEFT, InputActions.STEER_RIGHT], "Steer"))
			list.append(_entry([InputActions.HANDBRAKE], "Drift"))
			list.append(_entry([InputActions.NITRO], "Nitro"))
			list.append(_entry([InputActions.FIRE], "Fire"))
			list.append(_entry([InputActions.USE_ITEM], "Use item"))
			list.append(_entry([InputActions.JOKER_MENU], "Joker hand"))
			var aim: Array[StringName] = [
				InputActions.AIM_LEFT,
				InputActions.AIM_RIGHT,
				InputActions.AIM_UP,
				InputActions.AIM_DOWN
			]
			list.append(_entry(aim, "Aim"))
			list.append(_entry([InputActions.PAUSE], "Pause"))
			list.append(_entry([InputActions.JOIN], "Join"))
			list.append(_entry([InputActions.EMOTE_WHEEL], "Emotes"))
		1:
			list.append(_entry([InputActions.STEER_LEFT, InputActions.STEER_RIGHT], "Cycle"))
			var flip: Array[StringName] = [InputActions.JOKER_PREV, InputActions.JOKER_NEXT]
			list.append(_entry(flip, "Previous / next joker", "flip through your hand"))
			list.append(_entry([InputActions.JOKER_DROP], "Drop"))
			list.append(_entry([InputActions.FIRE], "Take"))
			list.append(_entry([InputActions.JOKER_DESTROY], "Destroy or skip", "no take-backs"))
			list.append(_entry([InputActions.JOKER_MENU], "Open or close the hand"))
			list.append(_entry([InputActions.DETAILS], "Details"))
			list.append(_entry([InputActions.NITRO], "Reroll"))
		_:
			var moves: Array[StringName] = [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]
			list.append(_entry(moves, "Move"))
			list.append(_entry([&"ui_accept"], "Choose"))
			list.append(_entry([&"ui_cancel"], "Back", "always a way out"))
			list.append(_entry([InputActions.MENU_PAGE_PREV], "Previous page"))
			list.append(_entry([InputActions.MENU_PAGE_NEXT], "Next page"))
			list.append(_entry([InputActions.MENU_VIEW], "Change the view"))
			list.append(_entry([InputActions.MENU_OPTION], "Option"))
			# The keyboard's sheet keeps to what a menu is mostly worked with: the rest are named on
			# the buttons they press, and a keyboard has keys enough to crowd it.
			list.append(_entry([InputActions.MENU_FILTER], "Filter", "", false))
			list.append(_entry([InputActions.MENU_SORT], "Sort", "", false))
			list.append(_entry([InputActions.MENU_HELP], "How it works", "", false))
			list.append(_entry([InputActions.MENU_NEXT_NEW], "Next new", "", false))
			list.append(_entry([InputActions.MATCH_SETTINGS], "Match settings"))
	return list


## An entry of [method entries]: [param keys] false for one the keyboard's sheet leaves out.
static func _entry(
	actions: Array[StringName], words: String, note := "", keys := true
) -> Dictionary:
	return {"actions": actions, "words": words, "note": note, "keys": keys}


## What the page [param on_page] says at each button [param drawn] shows, as the actions are bound
## now: by button, the words of everything bound to it there, once each, and the first note.
static func labels(
	on_page: int, simple_driving: bool, drawn: PadDiagram
) -> Dictionary[StringName, Dictionary]:
	var said: Dictionary[StringName, Dictionary] = {}
	for each: Dictionary in entries(on_page, simple_driving):
		var actions: Array[StringName] = each["actions"]
		for action: StringName in actions:
			if not InputMap.has_action(action):
				continue
			for event: InputEvent in InputMap.action_get_events(action):
				var spot := PadDiagram.spot_of(event)
				if spot.is_empty() or not drawn.shows(spot):
					continue
				if not said.has(spot):
					said[spot] = {"words": [] as Array[String], "note": ""}
				var words: Array[String] = said[spot]["words"]
				if not words.has(each["words"]):
					words.append(each["words"])
				if said[spot]["note"] == "":
					said[spot]["note"] = each["note"]
	return said


## Several things one button does, as one line: "Pause · join".
static func joined(words: Array[String]) -> String:
	var parts: PackedStringArray = []
	for i: int in words.size():
		var one := words[i]
		parts.append(one if i == 0 else one.left(1).to_lower() + one.substr(1))
	return "  ·  ".join(parts)
