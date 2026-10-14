class_name LoyaltyBinds
extends RefCounted
## The binds the loyalty program's dialog draws while keys or a pad are in hand, GAME.md 8.9: the
## ways the cursor is driven, and a key. The sheets' page keys are the dialogs' own, see
## [DialogBinds].


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
