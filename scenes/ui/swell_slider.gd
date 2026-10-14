class_name SwellSlider
extends VBoxContainer
## The Intense music slider of the audio settings, GAME.md 8.5: how much louder the music gets at
## the hottest the room gets, see [MusicSwell]. The setting is written beside it, Off or how much
## louder, and under it are its four marks, Off, Gentle, Normal and Strong, each a tick at its
## place on the slider with its name under it, so the swell it starts at can be found again.

## The slider moved: [param swell] is the new setting.
signal changed(swell: float)

## As wide as the volume sliders over it, so they line up.
const WIDTH := 320.0
const MARK_INK := Color(0.62, 0.62, 0.68)
const TICK_HEIGHT := 7.0
const MARKS_HEIGHT := 30.0

var slider: HSlider

var _value: Label
var _marks: Control


static func make(swell: float) -> SwellSlider:
	var made := SwellSlider.new()
	made._build(swell)
	return made


func _build(swell: float) -> void:
	add_theme_constant_override("separation", 2)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	slider = HSlider.new()
	slider.min_value = MusicSwell.OFF
	slider.max_value = MusicSwell.MOST
	slider.step = 0.01
	slider.value = swell
	slider.custom_minimum_size = Vector2(WIDTH, 0.0)
	slider.value_changed.connect(_on_moved)
	row.add_child(slider)
	_value = Label.new()
	_value.custom_minimum_size = Vector2(72.0, 0.0)
	Type.text(_value, Type.BODY, Color(0.86, 0.86, 0.9))
	row.add_child(_value)
	_marks = Control.new()
	_marks.custom_minimum_size = Vector2(WIDTH, MARKS_HEIGHT)
	_marks.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marks.draw.connect(_draw_marks)
	add_child(_marks)
	slider.resized.connect(_marks.queue_redraw)
	_show(swell)


func _on_moved(swell: float) -> void:
	_show(swell)
	changed.emit(swell)


func _show(swell: float) -> void:
	_value.text = MusicSwell.words(swell)


## Where on the slider's track [param swell] sits, across the marks under it: the grabber's middle
## travels from half a grabber in from one end to half a grabber in from the other.
func mark_x(swell: float) -> float:
	var grabber := slider.get_theme_icon("grabber")
	var half := grabber.get_width() * 0.5 if grabber != null else 0.0
	var share := (swell - slider.min_value) / (slider.max_value - slider.min_value)
	return half + (slider.size.x - half * 2.0) * share


func _draw_marks() -> void:
	var font := Type.TEXT
	var size := Type.SMALL
	for named: String in MusicSwell.MARKS:
		var x := mark_x(MusicSwell.MARKS[named])
		_marks.draw_line(Vector2(x, 0.0), Vector2(x, TICK_HEIGHT), MARK_INK, 2.0)
		var wide := font.get_string_size(named, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var left := clampf(x - wide * 0.5, 0.0, _marks.size.x - wide)
		_marks.draw_string(
			font,
			Vector2(left, TICK_HEIGHT + size + 2.0),
			named,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			size,
			MARK_INK
		)
