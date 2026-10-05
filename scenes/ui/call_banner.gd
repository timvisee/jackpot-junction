class_name CallBanner
extends Control
## The announcer's call, GAME.md 3.12 and 8.1a: the player's name and what they just did, under the
## middle of the screen where the eye already is, on a plate of the house's stock framed in their
## color, the name in it and the call in the house's foil capitals. It holds and then goes.
##
## The call that matters most, a player whose next cash-out would win the match, GAME.md 3.4, is
## run out on hazard tape behind the plate, a little askew, the way the moments that matter are.

## How long a call holds, all told, and how much of that is the fade.
const HOLD := 2.2
const FADE := 0.6
## How big the call is set.
const SIZE := 44
## The tape: how far it reaches past the plate either side and above and below, how wide its
## stripes are, how far it leans, and its two colors.
const TAPE_REACH := Vector2(44.0, 12.0)
const STRIPE := 16.0
const TAPE_TURN := -0.045
const TAPE_YELLOW := Color("#f6c42e")
const TAPE_BLACK := Color("#16151a")

var _plate: PanelContainer
var _look: TicketStyle
var _who: Label
var _what: Label
var _tape: Control
var _left := 0.0
var _urgent := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_tape = Control.new()
	_tape.name = "Tape"
	_tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tape.draw.connect(_draw_tape)
	add_child(_tape)
	_plate = PanelContainer.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_look = TicketStyle.cut(Color(HouseTheme.STOCK, 0.92), 10.0, 26.0, 12.0)
	_look.frame_inset = 5.0
	_look.shadow = 12.0
	_plate.add_theme_stylebox_override("panel", _look)
	add_child(_plate)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 16)
	_plate.add_child(line)
	_who = Label.new()
	Type.set_font(_who, Type.display_font(), SIZE)
	HudText.shadowed(_who, 2)
	_who.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(_who)
	_what = MenuTheme.title("", SIZE)
	_what.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(_what)
	_plate.resized.connect(_lay)


## Calls out [param call] for [param who], in [param color]; [param urgent] runs it out on tape.
func show_call(who: String, call: String, color: Color, urgent: bool) -> void:
	_who.text = who
	_who.visible = not who.is_empty()
	_who.add_theme_color_override("font_color", color)
	_what.text = call
	_look.frame = Color(HouseTheme.FOIL if urgent else color, 0.7)
	_urgent = urgent
	_tape.visible = urgent
	_left = HOLD
	modulate.a = 1.0
	visible = true
	_plate.reset_size()
	_lay()


## What the call says just now: the name and the call, two spaces apart.
func said() -> String:
	return _what.text if _who.text.is_empty() else "%s  %s" % [_who.text, _what.text]


## Takes the call down before its time.
func put_away() -> void:
	_left = 0.0
	visible = false


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(_left - delta, 0.0)
	modulate.a = clampf(_left / FADE, 0.0, 1.0)
	visible = _left > 0.0


## The plate in the middle of the banner, and the tape round it.
func _lay() -> void:
	var plate := _plate.get_combined_minimum_size()
	_plate.size = plate
	_plate.position = -plate * 0.5
	var tape := plate + TAPE_REACH * 2.0
	_tape.size = tape
	_tape.position = -tape * 0.5
	_tape.pivot_offset = tape * 0.5
	_tape.rotation = TAPE_TURN
	_tape.queue_redraw()


## Hazard tape: black stripes leaning across yellow.
func _draw_tape() -> void:
	var size_of := _tape.size
	_tape.draw_rect(Rect2(Vector2.ZERO, size_of), TAPE_YELLOW)
	var band := PackedVector2Array(
		[Vector2.ZERO, Vector2(size_of.x, 0.0), size_of, Vector2(0.0, size_of.y)]
	)
	var x := -size_of.y
	while x < size_of.x:
		var stripe := PackedVector2Array(
			[
				Vector2(x, size_of.y),
				Vector2(x + size_of.y, 0.0),
				Vector2(x + size_of.y + STRIPE, 0.0),
				Vector2(x + STRIPE, size_of.y),
			]
		)
		for part: PackedVector2Array in Geometry2D.intersect_polygons(stripe, band):
			_tape.draw_colored_polygon(part, TAPE_BLACK)
		x += STRIPE * 2.0
