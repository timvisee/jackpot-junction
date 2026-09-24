class_name GameModePicker
extends HBoxContainer
## The two kinds of game side by side at the top of the match settings, GAME.md 9.7: a Grand Prix
## and a quick match, each a big button with its picture and what it is on it, and the one chosen
## lit in the house's gold, the way the ways to drive are picked. Pressing the other chooses it.

signal chosen(grand_prix: bool)

## What each is called, and the line under that says what it is.
const WORDS: Array[String] = ["Grand Prix", "Quick match"]
const LINES: Array[String] = ["Several maps, one trophy", "One map"]
const ICON := 56.0
const INK := Color(0.88, 0.88, 0.92)
const LINE_INK := Color(0.66, 0.66, 0.72)

## Whether a Grand Prix is chosen rather than a quick match.
var grand_prix := true:
	set(value):
		grand_prix = value
		_refresh()

var _buttons: Array[Button] = []
var _pictures: Array[GameModeArt.Picture] = []


static func make(selected_grand_prix: bool) -> GameModePicker:
	var picker := GameModePicker.new()
	picker.add_theme_constant_override("separation", 12)
	for each: bool in [true, false]:
		picker._add(each)
	picker.grand_prix = selected_grand_prix
	return picker


## The button for a Grand Prix or for a quick match, for giving it the focus or pressing it.
func button(for_grand_prix: bool) -> Button:
	return _buttons[0 if for_grand_prix else 1]


func _add(for_grand_prix: bool) -> void:
	var which := 0 if for_grand_prix else 1
	var pressable := MenuTheme.button("", Type.BODY)
	pressable.toggle_mode = true
	pressable.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pressable.custom_minimum_size = Vector2(210.0, 132.0)
	var inside := VBoxContainer.new()
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.alignment = BoxContainer.ALIGNMENT_CENTER
	inside.add_theme_constant_override("separation", 4)
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var picture := GameModeArt.picture(for_grand_prix, INK, ICON)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inside.add_child(picture)
	var word := Label.new()
	word.text = WORDS[which]
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(word, Type.STRONG, Type.BODY)
	inside.add_child(word)
	var line := Label.new()
	line.text = LINES[which]
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_color_override("font_color", LINE_INK)
	Type.set_font(line, Type.TEXT, Type.LABEL)
	inside.add_child(line)
	pressable.add_child(inside)
	pressable.pressed.connect(_press.bind(for_grand_prix))
	add_child(pressable)
	_buttons.append(pressable)
	_pictures.append(picture)


func _press(for_grand_prix: bool) -> void:
	grand_prix = for_grand_prix
	chosen.emit(for_grand_prix)


## The chosen one pressed and in gold, the other not.
func _refresh() -> void:
	for i: int in _buttons.size():
		var on := (i == 0) == grand_prix
		_buttons[i].set_pressed_no_signal(on)
		_pictures[i].ink = Palette.CHIP_GOLD if on else INK
