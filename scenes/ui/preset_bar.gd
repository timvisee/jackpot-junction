class_name PresetBar
extends HBoxContainer
## The row of presets between the match settings' two big buttons and their columns, GAME.md 9.6:
## a chip for each of [constant MatchPresets.PRESETS] and Custom after them, each a poker chip of
## its own color, its name and a line of what it sets. The one the rows are set to is lit in gold,
## the way the chosen kind of game is; Custom where they are set to none of them.

## A chip was pressed: preset [param index] of [constant MatchPresets.PRESETS], or -1 for Custom.
signal picked(index: int)

const HEIGHT := 64.0
## How big the poker chip on each is, and how much room is left round it.
const CHIP := 15.0
const CHIP_ROOM := 6.0
## How much room a chip's words and picture keep from its sides.
const ROOM := 18.0
const LINE_INK := Color(0.66, 0.66, 0.72)

var _buttons: Array[Button] = []
var _names: Array[Label] = []
var _lit := -2


static func make() -> PresetBar:
	var bar := PresetBar.new()
	bar.add_theme_constant_override("separation", 10)
	for preset: Dictionary in MatchPresets.PRESETS:
		bar._add(preset)
	bar._add(MatchPresets.CUSTOM)
	return bar


## The button for preset [param index], or Custom for -1.
func button(index: int) -> Button:
	return _buttons[index if index >= 0 else _buttons.size() - 1]


## Every chip, Custom last.
func buttons() -> Array[Button]:
	return _buttons


## Lights the chip of preset [param index], or Custom for -1, and puts out the rest.
func light(index: int) -> void:
	_lit = index
	var custom := _buttons.size() - 1
	for i: int in _buttons.size():
		var on := i == (index if index >= 0 else custom)
		_buttons[i].set_pressed_no_signal(on)
		_names[i].add_theme_color_override(
			"font_color", HouseTheme.FOIL if on else HouseTheme.WORDS
		)


## The chip lit, by [method light]: a preset's index, -1 for Custom, -2 before any is.
func lit() -> int:
	return _lit


## The next chip along from the one lit, Custom after the presets and the first after Custom, as
## the presets' key goes round them, GAME.md 9.6.
func next_along() -> Button:
	var at := _lit if _lit >= 0 else _buttons.size() - 1
	return _buttons[(at + 1) % _buttons.size()]


## Whether any of them can be pressed: not at the Final Hand, STORY.md 8.1.
func lock() -> void:
	for pressable: Button in _buttons:
		pressable.disabled = true


func _add(preset: Dictionary) -> void:
	var index := _buttons.size() if _buttons.size() < MatchPresets.PRESETS.size() else -1
	var pressable := MenuTheme.button("", Type.BODY)
	pressable.toggle_mode = true
	pressable.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pressable.custom_minimum_size = Vector2(0.0, HEIGHT)
	pressable.name = String(preset["name"]).replace(" ", "")
	ScreenReader.name(pressable, preset["name"], preset["line"])
	var inside := HBoxContainer.new()
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.alignment = BoxContainer.ALIGNMENT_CENTER
	inside.add_theme_constant_override("separation", 10)
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pressable.add_child(inside)
	var chip := PresetChip.new()
	chip.face = preset["face"]
	chip.custom_minimum_size = Vector2.ONE * (CHIP + CHIP_ROOM) * 2.0
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# The mouse and a finger go through to the button: a control takes them for itself otherwise,
	# and over the chip the button was neither lit nor pressed.
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.add_child(chip)
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	inside.add_child(words)
	var named := Label.new()
	named.text = preset["name"]
	named.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(named, Type.STRONG, Type.BODY)
	words.add_child(named)
	var line := Label.new()
	line.text = preset["line"]
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_color_override("font_color", LINE_INK)
	Type.set_font(line, Type.TEXT, Type.SMALL)
	words.add_child(line)
	pressable.pressed.connect(
		func() -> void:
			# A toggle lets go of itself on a second press: it stays lit until the rows say otherwise.
			light(_lit)
			picked.emit(index)
	)
	# As wide as its words and its chip, which the button's own size knows nothing of, once they
	# have the fonts to be measured in.
	inside.minimum_size_changed.connect(
		func() -> void:
			pressable.custom_minimum_size.x = inside.get_combined_minimum_size().x + ROOM * 2.0
	)
	add_child(pressable)
	_buttons.append(pressable)
	_names.append(named)


## The poker chip on a preset: one of the kept chips, a picture drawn once a run, GAME.md 10.7.
class PresetChip:
	extends Control

	var face := Color.WHITE

	func _draw() -> void:
		ChipArt.kept_chip(self, size * 0.5, PresetBar.CHIP, face)
