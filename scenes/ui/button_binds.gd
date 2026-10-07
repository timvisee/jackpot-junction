class_name ButtonBinds
extends RefCounted
## The key or pad button that does what a button does, hung on the middle of its bottom edge,
## GAME.md 8.3:
## for the screens whose buttons are there for the mouse and never take the cursor, Kit's folder,
## the closer look at a note and the license, STORY.md 7.2. Drawn while keys or a pad are in hand,
## gone while the mouse is, and never on a touch screen, where the buttons are pressed.

const INK := Color(0.78, 0.78, 0.84)
const FONT_SIZE := 12
## How much room to leave under a row of buttons for the binds hung on them.
const ROOM := 12.0


## Marks [param button] as doing what [param action] does: drawn as the action's own key or pad
## button, or as [param key] on a keyboard and [param pad] on a pad where they are given.
static func mark(
	button: Button, action: StringName, key: Key = KEY_NONE, pad: JoyButton = JOY_BUTTON_INVALID
) -> void:
	button.set_meta(&"bind_action", action)
	button.set_meta(&"bind_key", key)
	button.set_meta(&"bind_pad", pad)


## An arrow with nowhere to go that way out of sight, keeping its room so the buttons beside it do
## not move, or back in sight as [param shown] says; out of sight, it is out of the mouse's way too.
static func show_arrow(button: Button, shown: bool) -> void:
	button.disabled = not shown
	button.modulate.a = 1.0 if shown else 0.0
	button.mouse_filter = Control.MOUSE_FILTER_STOP if shown else Control.MOUSE_FILTER_IGNORE


## Each of [param buttons]' binds drawn for a keyboard or a pad as [param keyboard] says, or none
## while [param shown] is false; none on a button that is disabled, which there is nothing to press
## for.
static func show(buttons: Array[Button], keyboard: bool, shown: bool) -> void:
	for button: Button in buttons:
		var old := button.get_node_or_null("Bind")
		if old != null:
			button.remove_child(old)
			old.queue_free()
		if (
			not shown
			or TouchInput.enabled
			or button.disabled
			or not button.has_meta(&"bind_action")
		):
			continue
		var glyph := _glyph_of(button, keyboard)
		if glyph == null:
			continue
		glyph.name = "Bind"
		glyph.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		var wanted := glyph.custom_minimum_size
		glyph.offset_left = -wanted.x * 0.5
		glyph.offset_right = wanted.x * 0.5
		glyph.offset_top = -wanted.y * 0.35
		glyph.offset_bottom = wanted.y * 0.65
		button.add_child(glyph)


static func _glyph_of(button: Button, keyboard: bool) -> InputGlyph:
	var key: Key = button.get_meta(&"bind_key")
	var pad: JoyButton = button.get_meta(&"bind_pad")
	if keyboard and key != KEY_NONE:
		var press := InputEventKey.new()
		press.keycode = key
		return InputGlyph.of_event(press, INK, FONT_SIZE)
	if not keyboard and pad != JOY_BUTTON_INVALID:
		var push := InputEventJoypadButton.new()
		push.button_index = pad
		return InputGlyph.of_event(push, INK, FONT_SIZE)
	return InputGlyph.of_action(button.get_meta(&"bind_action"), keyboard, INK, FONT_SIZE)


## Whether the mouse is in hand after [param event] rather than keys or a pad: a click or a real
## move of the mouse says it is, a key, a pad's button or a real push of its stick that it is not;
## anything else leaves it as [param was].
static func pointer_after(event: InputEvent, was: bool) -> bool:
	var click := event as InputEventMouseButton
	if click != null and click.pressed:
		return true
	var motion := event as InputEventMouseMotion
	if motion != null and motion.relative.length() > 3.0:
		return true
	if event is InputEventKey or event is InputEventJoypadButton:
		return false
	var stick := event as InputEventJoypadMotion
	if stick != null and absf(stick.axis_value) > 0.5:
		return false
	return was
