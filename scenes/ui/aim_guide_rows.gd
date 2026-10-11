class_name AimGuideRows
extends VBoxContainer
## How the aim guide is drawn, GAME.md 8.5, on the Accessibility page under its switch: the guide
## as it is set on the first seat's kart, see [AimGuidePreview]; how far it runs out in dots, how
## big they are, how solid, and in what color; and a button beside them that puts all four back as
## they were at first, there to press only while one of them is not. Changed over a room, the guide
## changes at once.

## The four have been put back as they were at first, see [method Settings.reset_aim_guide].
signal reset

## What Reset says to the mouse.
const RESET_TIP := "Put the aim guide's length, size, opacity and color back as they were"

var settings: Settings
var length: HSlider
var size_slider: HSlider
var opacity: HSlider
var style: OptionButton
var reset_button: Button


static func make(for_settings: Settings) -> AimGuideRows:
	var rows := AimGuideRows.new()
	rows.name = "AimGuideRows"
	rows.settings = for_settings
	return rows


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var preview := AimGuidePreview.new()
	preview.name = "AimGuidePreview"
	add_child(MenuTheme.row("", preview))
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	length = _slider(AimGuide.FEWEST, AimGuide.MOST, 1.0, settings.aim_guide_length)
	length.name = "AimGuideLength"
	rows.add_child(MenuTheme.row("Aim guide length", length))
	size_slider = _slider(AimGuide.SMALLEST, AimGuide.BIGGEST, 0.1, settings.aim_guide_size)
	size_slider.name = "AimGuideSize"
	rows.add_child(MenuTheme.row("Aim guide size", size_slider))
	opacity = _slider(AimGuide.FAINTEST, 1.0, 0.05, settings.aim_guide_opacity)
	opacity.name = "AimGuideOpacity"
	rows.add_child(MenuTheme.row("Aim guide opacity", opacity))
	style = MenuTheme.option(AimGuide.STYLES, settings.aim_guide_style)
	style.name = "AimGuideStyle"
	rows.add_child(MenuTheme.row("Aim guide color", style))
	reset_button = MenuTheme.button("Reset", Type.BODY)
	reset_button.name = "AimGuideReset"
	reset_button.tooltip_text = RESET_TIP
	reset_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reset_button.pressed.connect(_reset)
	var beside := HBoxContainer.new()
	beside.add_theme_constant_override("separation", 24)
	beside.add_child(rows)
	beside.add_child(reset_button)
	add_child(beside)
	length.value_changed.connect(
		func(v: float) -> void:
			settings.aim_guide_length = roundi(v)
			_mark()
	)
	size_slider.value_changed.connect(
		func(v: float) -> void:
			settings.aim_guide_size = v
			_mark()
	)
	opacity.value_changed.connect(
		func(v: float) -> void:
			settings.aim_guide_opacity = v
			_mark()
	)
	style.item_selected.connect(
		func(index: int) -> void:
			settings.aim_guide_style = index
			_mark()
	)
	_mark()


## Nothing to put back while it is as it was at first.
func _mark() -> void:
	reset_button.disabled = settings.aim_guide_as_at_first()


## All four put back as they were at first, and shown so; the cursor, which was on Reset, to the
## first of them, Reset being of no more use.
func _reset() -> void:
	settings.reset_aim_guide()
	length.set_value_no_signal(settings.aim_guide_length)
	size_slider.set_value_no_signal(settings.aim_guide_size)
	opacity.set_value_no_signal(settings.aim_guide_opacity)
	style.select(settings.aim_guide_style)
	_mark()
	length.grab_focus()
	reset.emit()


## A slider from [param least] to [param most] in steps of [param step], at [param value], as wide
## as the page's sliders are.
static func _slider(least: float, most: float, step: float, value: float) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = least
	slider.max_value = most
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(320.0, 0.0)
	return slider
