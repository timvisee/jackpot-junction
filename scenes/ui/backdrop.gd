class_name Backdrop
extends Control
## What is behind a menu screen, GAME.md 8.1a: the house's stock, a band of banknote waves across
## the head of it dying away down the screen, and the license's long arcs rising off its foot, all
## at a whisper. Worked out for the screen's size and drawn as lines, so nothing in it is a picture
## stretched to fit and nothing in it moves.

## How far down the waves reach, as a share of the screen's height, and how they are laid.
const WAVE_SHARE := 0.42
const WAVE_GAP := 12.0
const WAVE_HEIGHT := 6.0
const WAVE_LENGTH := 240.0
const WAVE_STEP := 12.0
## The arcs off the foot, as on the license, GAME.md 9.4a: how many, where the first is centered
## and how big it is as shares of the screen, and how far each next one moves along and grows.
const ARCS := 16
const ARC_MIDDLE := Vector2(0.62, 2.3)
const ARC_RADIUS := 1.85
const ARC_SHIFT := Vector2(0.022, 0.009)
const ARC_FROM := PI * 1.12
const ARC_TO := PI * 1.88

var _lines: Array[PackedVector2Array] = []
var _inks: Array[PackedColorArray] = []


## A backdrop over the whole of [param parent], behind everything already in it.
static func behind(parent: Control) -> Backdrop:
	var back := Backdrop.new()
	back.name = "Backdrop"
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(back)
	parent.move_child(back, 0)
	return back


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_lay)
	_lay()


func _lay() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	var ink := Color(HouseTheme.FOIL, Engraving.ON_STOCK * 0.8)
	var band := size.y * WAVE_SHARE
	var waves := Engraving.waves(
		Rect2(0.0, WAVE_GAP, size.x, band), WAVE_GAP, WAVE_HEIGHT, WAVE_LENGTH, 0.42, WAVE_STEP
	)
	_lines = waves
	_inks = Engraving.faded(waves, ink, 0.0, band)
	var arcs := Engraving.arcs(
		size * ARC_MIDDLE,
		size.y * ARC_RADIUS,
		ARCS,
		Vector2(size.x * ARC_SHIFT.x, size.y * ARC_SHIFT.y),
		ARC_FROM,
		ARC_TO,
		96
	)
	_lines.append_array(arcs)
	for arc: PackedVector2Array in arcs:
		_inks.append(PackedColorArray([ink]))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), HouseTheme.STOCK)
	Engraving.draw(get_canvas_item(), _lines, Color.WHITE, _inks)
