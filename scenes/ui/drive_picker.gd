class_name DrivePicker
extends HBoxContainer
## The two ways to drive side by side, GAME.md 4.2, each a button with its picture on it, and the
## one chosen lit in the house's gold. Pressing the other chooses it.

signal chosen(mode: String)

## What the two are called on their buttons.
const WORDS: Dictionary[String, String] = {
	Settings.DRIVE_SIMPLE: "Simple",
	Settings.DRIVE_ADVANCED: "Advanced",
}
const ICON := 34.0
const INK := Color(0.88, 0.88, 0.92)

## The way chosen.
var mode := Settings.DRIVE_ADVANCED:
	set(value):
		mode = value
		_refresh()

var _buttons: Dictionary[String, Button] = {}
var _pictures: Dictionary[String, DriveArt.Picture] = {}


## A picker with [param selected] chosen.
static func make(selected: String) -> DrivePicker:
	var picker := DrivePicker.new()
	picker.add_theme_constant_override("separation", 10)
	for each: String in Settings.DRIVE_MODES:
		picker._add(each)
	picker.mode = selected
	return picker


## The button for [param which], for giving it the focus.
func button(which: String) -> Button:
	return _buttons.get(which)


func _add(which: String) -> void:
	var pressable := MenuTheme.button("", Type.BODY)
	pressable.toggle_mode = true
	var inside := HBoxContainer.new()
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.alignment = BoxContainer.ALIGNMENT_CENTER
	inside.add_theme_constant_override("separation", 10)
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var picture := DriveArt.picture(which, INK, ICON)
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inside.add_child(picture)
	var word := Label.new()
	word.text = WORDS[which]
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(word, Type.STRONG, Type.BODY)
	inside.add_child(word)
	pressable.add_child(inside)
	pressable.custom_minimum_size = Vector2(190.0, 52.0)
	pressable.pressed.connect(_press.bind(which))
	add_child(pressable)
	_buttons[which] = pressable
	_pictures[which] = picture


func _press(which: String) -> void:
	mode = which
	chosen.emit(which)


## The chosen one pressed and in gold, the other not.
func _refresh() -> void:
	for which: String in _buttons:
		var on := which == mode
		_buttons[which].set_pressed_no_signal(on)
		_pictures[which].ink = Palette.CHIP_GOLD if on else INK
