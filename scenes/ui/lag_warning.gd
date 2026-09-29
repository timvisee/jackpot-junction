class_name LagWarning
extends HBoxContainer
## A line to the host too slow to play on without being told, GAME.md 10.3: an amber warning sign,
## and how many milliseconds a message takes there and back, beside the player's name in their
## corner of the HUD, and the sign alone beside their name in the running order. Hidden while the
## line is quick enough, see [constant NetPing.SLOW].

const INK := Color(1.0, 0.72, 0.18)
const MARK := Color(0.08, 0.06, 0.02)

var _sign: Sign
var _time: Label


## A warning a [param side] square, with the time written after it when [param timed].
static func make(side: float, timed: bool) -> LagWarning:
	var warning := LagWarning.new()
	warning.name = "Lag"
	warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warning.add_theme_constant_override("separation", 5)
	warning._sign = Sign.new()
	warning._sign.custom_minimum_size = Vector2.ONE * side
	warning._sign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	warning._sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warning.add_child(warning._sign)
	if timed:
		warning._time = Label.new()
		warning._time.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Type.set_font(warning._time, Type.numbers_text_font(), Type.SMALL)
		warning._time.add_theme_color_override("font_color", INK)
		HudText.shadowed(warning._time, 1)
		warning.add_child(warning._time)
	warning.visible = false
	return warning


## Up while [param milliseconds] there and back is too slow, saying how slow.
func show_trip(milliseconds: float) -> void:
	visible = milliseconds > NetPing.SLOW
	if visible and _time != null:
		_time.text = "%d ms" % roundi(milliseconds)


func is_up() -> bool:
	return visible


## The sign: an amber triangle with a dark rim and an exclamation mark.
class Sign:
	extends Control

	func _draw() -> void:
		var s := size.x
		var corners := PackedVector2Array(
			[Vector2(s * 0.5, s * 0.06), Vector2(s * 0.97, s * 0.92), Vector2(s * 0.03, s * 0.92)]
		)
		var rim := corners.duplicate()
		rim.append(corners[0])
		draw_polyline(rim, LagWarning.MARK, maxf(s * 0.1, 1.5), true)
		draw_colored_polygon(corners, LagWarning.INK)
		draw_line(Vector2(s * 0.5, s * 0.34), Vector2(s * 0.5, s * 0.62), LagWarning.MARK, s * 0.12)
		draw_circle(Vector2(s * 0.5, s * 0.77), s * 0.065, LagWarning.MARK)
