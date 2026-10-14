class_name LoyaltyBinds
extends RefCounted
## The binds the loyalty program's dialog draws while keys or a pad are in hand, GAME.md 8.9: the
## sheets' turning, the ways the cursor is driven, and a key.


## The binds that turn the sheets, drawn without words at the tabs' end, which say what they do:
## for [param keys] its key, and on a pad the two shoulders.
static func sheets(keys: bool, ink: Color, size: int) -> Control:
	if keys:
		return InputHint.row(
			"%s", [InputGlyph.of_action(LoyaltyDialog.SHEET_ACTION, true, ink, size)], ink, size
		)
	var parts: Array = []
	for button: int in [LoyaltyDialog.SHEET_BACK, LoyaltyDialog.SHEET_ON]:
		var press := InputEventJoypadButton.new()
		press.button_index = button as JoyButton
		parts.append(InputGlyph.of_event(press, ink, size))
	return InputHint.row("%s %s", parts, ink, size)


## How the cursor is driven to another landmark, drawn for [param keys] or a pad: the four arrow
## keys, or the left stick pushed every way.
static func ways(keys: bool, ink: Color, size: int) -> Control:
	if not keys:
		var push := InputEventJoypadMotion.new()
		push.axis = JOY_AXIS_LEFT_X
		push.axis_value = 1.0
		var stick := InputGlyph.of_event(push, ink, size)
		stick.every_way = true
		return stick
	var arrows := HBoxContainer.new()
	arrows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrows.add_theme_constant_override("separation", 3)
	var drawn := {KEY_UP: "↑", KEY_LEFT: "←", KEY_DOWN: "↓", KEY_RIGHT: "→"}
	for each: Key in drawn:
		arrows.add_child(key(each, ink, size).written(drawn[each]))
	return arrows


## The key [param named] drawn in [param ink] at [param size].
static func key(named: Key, ink: Color, size: int) -> InputGlyph:
	var press := InputEventKey.new()
	press.keycode = named
	return InputGlyph.of_event(press, ink, size)
