class_name Backdrop
extends Control
## What is behind a menu screen, GAME.md 8.1a: the house's stock, a band of banknote waves across
## the head of it dying away down the screen, and the license's long arcs rising off its foot, all
## at a whisper. Worked out for the screen's size and drawn as lines, so nothing in it is a picture
## stretched to fit and nothing in it moves; and drawn so once a run, into a picture at the size of
## the screen and shown from then on, GAME.md 10.7, since its lines are a draw call each, some two
## hundred a frame behind every menu.

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

## The group a backdrop waiting on its picture is in, see [KeptPictures].
const KEPT := &"backdrop_kept"

## Whether it is drawn as its lines every time rather than from its picture: the copy drawn for the
## picture.
var live := false
var _lines: Array[PackedVector2Array] = []
var _inks: Array[PackedColorArray] = []
var _kept := {}
var _finish: Array = [Surface.Kind.NONE, 0.0, 0.0]


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
	_finish = Surface.finish("backdrop")
	_kept = {}
	queue_redraw()


func _draw() -> void:
	if not live:
		var pixels := KeptPictures.scale_of(self) * size
		var step := Vector2i(KeptPictures.step_up(pixels.x, 64), KeptPictures.step_up(pixels.y, 64))
		var key := "backdrop|%d|%s" % [int(_finish[0]), str(_finish[1])]
		if not is_in_group(KEPT):
			add_to_group(KEPT)
		var picture := KeptPictures.of(self, key, step, _picture.bind(step), KEPT)
		if picture != null:
			draw_texture_rect(picture, Rect2(Vector2.ZERO, size), false)
			return
	draw_rect(Rect2(Vector2.ZERO, size), HouseTheme.STOCK)
	var whole := PackedVector2Array(
		[Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)]
	)
	Surface.draw(
		get_canvas_item(), _kept, whole, size, _finish[0] as Surface.Kind, float(_finish[1])
	)
	Engraving.draw(get_canvas_item(), _lines, Color.WHITE, _inks)


## A backdrop at [param pixels], drawn as its lines, for its picture.
func _picture(pixels: Vector2i) -> Control:
	var drawn := Backdrop.new()
	drawn.live = true
	drawn.size = Vector2(pixels)
	return drawn
