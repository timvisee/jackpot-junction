class_name TutorialNotice
extends PanelContainer
## The tutorial's word at the top of the screen, GAME.md 9.4a: a line or two about the thing in
## front of the player, the two ways to drive, what an item is, what a joker is, what the pot and
## the bank are, at the top edge, under the fight's bar while that is up, the panel no wider than
## its words. A line may name a control, drawn in for the device in hand the way the hint over
## the kart draws it, a key, a pad button, a touch button, or the menu button of a touch screen.
## Each lesson says its piece by a key of its own and clears only that, so one lesson's word
## never wipes another's; a lesson ending clears whatever is up. An information mark stands in
## front of every word, so the panel reads as a note and not as something to answer.

signal changed

const INK := Palette.CHIP_WHITE
const FADE := 0.25
const INFO_SIDE := 22.0
const TOP := 16.0

## Whether the player's device is a keyboard, for the controls drawn into a line.
var keyboard := true

var _lines: VBoxContainer
var _info: Control
var _key := &""
var _said := ""


## The information mark in front of a word: a ring with an i in it.
class Info:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(INFO_SIDE, INFO_SIDE)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var middle := Vector2(INFO_SIDE, INFO_SIDE) * 0.5
		draw_arc(middle, INFO_SIDE * 0.5 - 1.5, 0.0, TAU, 32, Palette.NEON_CYAN, 2.0, true)
		draw_circle(middle + Vector2(0.0, -5.0), 1.6, Palette.NEON_CYAN)
		draw_rect(Rect2(middle + Vector2(-1.4, -2.0), Vector2(2.8, 8.0)), Palette.NEON_CYAN)


## The menu button of a touch screen, as a line names it: a round button with three bars.
class MenuMark:
	extends Control

	const SIDE := 26.0

	func _init() -> void:
		custom_minimum_size = Vector2(SIDE, SIDE)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var middle := Vector2(SIDE, SIDE) * 0.5
		draw_circle(middle, SIDE * 0.5, Color(0.0, 0.0, 0.0, 0.5))
		draw_arc(middle, SIDE * 0.5 - 1.0, 0.0, TAU, 32, INK, 1.5, true)
		for i: int in 3:
			var y := middle.y - 5.0 + 5.0 * i
			draw_rect(Rect2(Vector2(middle.x - 6.0, y - 1.0), Vector2(12.0, 2.0)), INK)


static func add_to(layer: CanvasLayer) -> TutorialNotice:
	var notice := TutorialNotice.new()
	notice.name = "Notice"
	layer.add_child(notice)
	return notice


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", HudBlock.scrim())
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	set_top(TOP)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	_info = Info.new()
	_info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_info)
	_lines = VBoxContainer.new()
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lines.add_theme_constant_override("separation", 2)
	_lines.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_lines)
	visible = false


## Says [param text], as [param key], in place of whatever was up, a line per line of it, each
## gap in it filled with the control of the next of [param actions] for the device in hand.
func say(key: StringName, text: String, actions: Array[StringName] = []) -> void:
	_key = key
	_said = Terms.plain(text)
	for old: Node in _lines.get_children():
		old.queue_free()
	var left := actions.duplicate()
	for line: String in text.split("\n"):
		var parts: Array = []
		for i: int in line.count("%s"):
			parts.append(_part(left.pop_front() if not left.is_empty() else &""))
		var row := InputHint.row(line, parts, INK, Type.BODY)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		_lines.add_child(row)
	if not visible:
		visible = true
		modulate.a = 0.0
		var fade := create_tween()
		fade.tween_property(self, "modulate:a", 1.0, FADE)
	changed.emit()


## Takes the word down: the one said as [param key], or whatever is up for no key.
func clear(key := &"") -> void:
	if not visible or (key != &"" and key != _key):
		return
	visible = false
	_key = &""
	_said = ""
	changed.emit()


func is_saying(key: StringName) -> bool:
	return visible and _key == key


## The words up just now, as they were given, or nothing.
func said() -> String:
	return _said if visible else ""


## Where it hangs from the top of the screen.
func set_top(top: float) -> void:
	offset_top = top
	offset_bottom = top


## Where the screen is clear again under it, from the top, for what else hangs there; where it
## hangs from while it is down.
func below() -> float:
	if not visible:
		return offset_top
	return offset_top + get_combined_minimum_size().y + 10.0


## The control [param action] is on the device in hand: on a touch screen the menu button for
## the pause, which has no button of its own among the screen's, and the screen's button for the
## rest; a key or a pad button otherwise. A word for one nothing is bound to, so it is not a gap.
func _part(action: StringName) -> Control:
	if action == &"":
		return _word("?")
	if TouchInput.enabled and action == InputActions.PAUSE:
		return MenuMark.new()
	var glyph := InputHint.glyph(action, keyboard, INK, Type.BODY)
	return glyph if glyph != null else _word(InputActions.short_binding_text(action, keyboard))


func _word(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.text(label, Type.BODY, INK)
	return label
