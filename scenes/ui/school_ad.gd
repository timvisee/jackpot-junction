class_name SchoolAd
extends Control
## The driving school advertised on the title, GAME.md 3.8, until the license is earned: a flyer
## pointing at the Driving School button, the learner's L on it, NOW ENROLLING blinking over
## "Earn your very own license here.", nudging toward the button now and then so it is not a box
## of words standing still. A click or a tap on it is the button's, see [signal chosen].

signal chosen

## The pointer on its left toward the button, how far it nudges that way and how often, how long a
## blink of the headline takes, and how much bigger it grows under the cursor.
const POINTER := 14.0
const NUDGE := 8.0
const NUDGE_EVERY := 1.6
const BLINK := 0.55
const HOVER := 1.04
const HEADLINE := "NOW ENROLLING"
const LINE := "Earn your very own license here."
const SMALL := "No experience required."
## Opaque, so the pointer laid over the flyer's edge hides the border under it entirely.
const FILL := Color(0.1, 0.1, 0.13)
## How far into the flyer the pointer's base reaches, past its border and the border's soft edge.
const OVERLAP := 4.0
const EDGE := Palette.CHIP_GOLD
const LEARNER_SIDE := 54.0
## The room round the words on the flyer, the gap between the L and them, and the narrowest the
## words may be wrapped to before the flyer gives them up and is the L with its pointer alone.
const MARGIN_LEFT := 14.0
const MARGIN_RIGHT := 18.0
const GAP := 12.0
const WORDS_NARROWEST := 150.0


## The pointer, drawn over the flyer's edge so the two read as one.
class Arrow:
	extends Control

	func _draw() -> void:
		var middle := size.y * 0.5
		var tip := Vector2(0.0, middle)
		# The two edges meet the flyer's border where it is, and the fill runs on past it, so no
		# line of the border shows across the pointer's base.
		var top := Vector2(POINTER, middle - POINTER)
		var foot := Vector2(POINTER, middle + POINTER)
		var reach := POINTER + OVERLAP
		var fill := PackedVector2Array(
			[tip, top, Vector2(reach, middle - POINTER), Vector2(reach, middle + POINTER), foot]
		)
		draw_colored_polygon(fill, FILL)
		draw_line(tip, top, EDGE, 2.0, true)
		draw_line(tip, foot, EDGE, 2.0, true)


## Whether it points at the button beside it, or stands alone in a corner with no room beside it.
var pointing := true:
	set = _set_pointing
## The blinking headline.
var headline: Label

var _body: Control
var _panel: PanelContainer
var _arrow: Arrow
var _words: VBoxContainer
var _wrapped: Array[Label] = []
var _room := -1.0


func _ready() -> void:
	name = "SchoolAd"
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	_body = Control.new()
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = FILL
	style.set_border_width_all(2)
	style.border_color = EDGE
	style.set_corner_radius_all(12)
	style.content_margin_left = MARGIN_LEFT
	style.content_margin_right = MARGIN_RIGHT
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	style.shadow_size = 10
	_panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(GAP))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var learner := SchoolFigure.of(SchoolFigure.Kind.LEARNER, LEARNER_SIDE)
	learner.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(learner)
	_words = VBoxContainer.new()
	_words.add_theme_constant_override("separation", 1)
	_words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	headline = _label(HEADLINE, Type.STRONG, Type.SMALL, EDGE)
	_words.add_child(headline)
	_wrapped = [
		_label(LINE, Type.STRONG, Type.LABEL, Color(0.95, 0.95, 0.97)),
		_label(SMALL, Type.TEXT, Type.SMALL, Color(0.68, 0.68, 0.74)),
	]
	for label: Label in _wrapped:
		_words.add_child(label)
	_words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_words)
	_panel.add_child(row)
	_body.add_child(_panel)
	_arrow = Arrow.new()
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(_arrow)
	_panel.minimum_size_changed.connect(_fit)
	_fit()
	var blink := create_tween().set_loops()
	blink.tween_property(headline, "modulate:a", 0.3, BLINK)
	blink.tween_property(headline, "modulate:a", 1.0, BLINK)
	var nudge := create_tween().set_loops()
	nudge.tween_interval(NUDGE_EVERY)
	nudge.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	nudge.tween_property(_body, "position:x", -NUDGE, 0.18)
	nudge.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	nudge.tween_property(_body, "position:x", 0.0, 0.28)
	gui_input.connect(_on_input)
	mouse_entered.connect(func() -> void: scale = Vector2.ONE * HOVER)
	mouse_exited.connect(func() -> void: scale = Vector2.ONE)


func _label(text: String, font: Font, font_size: int, ink: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(label, font, font_size)
	label.add_theme_color_override("font_color", ink)
	return label


## Its size is the flyer's and the pointer's.
func _fit() -> void:
	var wanted := _panel.get_combined_minimum_size()
	_panel.size = wanted
	_panel.position = Vector2(POINTER, 0.0)
	_arrow.position = Vector2.ZERO
	_arrow.size = Vector2(POINTER + OVERLAP + 1.0, wanted.y)
	custom_minimum_size = wanted + Vector2(POINTER, 0.0)
	size = custom_minimum_size
	pivot_offset = size * 0.5


## Fits the flyer into [param room] pixels across, its pointer and all: as it is, with its words
## wrapped narrower, or the L with its pointer alone, as a small screen or a big UI scale has
## room for, GAME.md 8.5. False when not even that fits.
func fit_into(room: float) -> bool:
	if is_equal_approx(room, _room):
		return _room >= _least()
	_room = room
	var around := POINTER + MARGIN_LEFT + MARGIN_RIGHT + LEARNER_SIDE + GAP
	var natural := around + _natural_words()
	var words := room - around
	_words.visible = room >= natural or words >= maxf(WORDS_NARROWEST, _headline_width())
	for label: Label in _wrapped:
		var wrap := _words.visible and room < natural
		label.autowrap_mode = (TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF)
		label.custom_minimum_size.x = words if wrap else 0.0
	_fit()
	return room >= _least()


## The narrowest it can be: the L with its pointer.
func _least() -> float:
	return POINTER + MARGIN_LEFT + MARGIN_RIGHT + LEARNER_SIDE


## How wide the words are on one line each.
func _natural_words() -> float:
	var widest := _headline_width()
	for label: Label in _wrapped:
		var font := label.get_theme_font("font")
		var font_size := label.get_theme_font_size("font_size")
		widest = maxf(
			widest, font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		)
	return widest


func _headline_width() -> float:
	var font := headline.get_theme_font("font")
	var font_size := headline.get_theme_font_size("font_size")
	return font.get_string_size(headline.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _set_pointing(beside: bool) -> void:
	pointing = beside
	if _arrow != null:
		_arrow.visible = beside


## A click or a tap on it goes to the school.
func _on_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (
		(click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT)
		or (touch != null and touch.pressed)
	):
		get_viewport().set_input_as_handled()
		chosen.emit()
