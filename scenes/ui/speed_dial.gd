class_name SpeedDial
extends Range
## The speedometer of a corner block, GAME.md 8.3 and 8.1a: a small dial, three quarters of a ring
## open at the foot, filling clockwise from the bottom left with the kart's speed. Its face is a
## gauge's: a foil rim, a tick every so far round, longer every third, the track foil past the
## kart's own top speed where only nitro takes it and red at the end of that, and the unit written
## in the gap at the foot. Over the fill a pointer swings onto the speed on a spring,
## overshooting a little and settling, and a small foil mark holds the highest speed of the last
## moment before it falls back. The number itself is a label laid over the middle of it by whoever
## builds the block, so it is set in the same type as the rest of the corner, and the pointer stays
## out on the ring, clear of it.
##
## Cheap to have up, GAME.md 10.7: the face is drawn once into a picture and shown from then on,
## the pointer and the peak mark are drawn once each and only turned, and a frame of driving
## redraws the fill alone, one arc. Drawn in white and foil, so the block can light the whole gauge
## the nitro's color by its modulate.

## Where the ring starts and ends, in radians clockwise from east with y down: the bottom left
## round over the top to the bottom right.
const FROM := PI * 0.75
const TO := PI * 2.25
## How thick the ring is, as a share of the dial's radius, and how many ticks go round it.
const RING := 0.16
const TICKS := 12
const TRACK := Color(0.0, 0.0, 0.0, 0.5)
const TICK_INK := Color(0.66, 0.65, 0.71, 0.8)
const FACE := Color(0.06, 0.06, 0.08, 0.55)
const BOOST_TRACK := Color(0.45, 0.33, 0.1, 0.6)
const RED_TRACK := Color(0.55, 0.12, 0.1, 0.75)
## Where on the ring the kart's own top speed falls, past which only nitro takes it, see
## [constant MatchHud.SPEED_FULL], and where the red starts.
const BOOST_FROM := 1.0 / MatchHud.SPEED_FULL
const RED_FROM := 0.88
## The pointer: from how far out it starts to how far it reaches, as shares of the radius, how wide
## its foot is, and its spring, how stiff and how damped, which overshoots a new speed a little.
const POINTER_IN := 0.5
const POINTER_OUT := 1.06
const POINTER_FOOT := 0.11
const STIFF := 220.0
const DAMP := 19.0
## The peak mark: how long it holds the highest speed before it falls, and how fast it falls, as a
## share of the ring a second.
const PEAK_HOLD := 1.1
const PEAK_FALL := 0.45
## What of a pointer at full stretch trembles on the nitro, in radians.
const TREMBLE := 0.025
## The group a face's picture is waited on in, see [KeptPictures].
const FACES := &"speed_dial_faces"

## What is written in the gap at the foot, the unit the number is in, see [SpeedUnits].
var unit := SpeedUnits.KMH_WORD:
	set = _set_unit

var _pointer: Node2D
var _peak: Node2D
## Where the pointer stands, as a share of the ring, and how fast it is going there.
var _shown := 0.0
var _swing := 0.0
var _peak_share := 0.0
var _peak_left := 0.0
var _clock := 0.0


func _init() -> void:
	min_value = 0.0
	max_value = 100.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_changed.connect(func(_to: float) -> void: queue_redraw())


func _ready() -> void:
	add_to_group(FACES)
	_peak = _turning(_draw_peak)
	_pointer = _turning(_draw_pointer)
	resized.connect(_place)
	_place()


func _process(delta: float) -> void:
	var share := _share()
	# A spring onto the speed: it overshoots a sudden change a little, and settles.
	var pull := (share - _shown) * STIFF - _swing * DAMP
	_swing += pull * minf(delta, 0.05)
	_shown = clampf(_shown + _swing * minf(delta, 0.05), -0.02, 1.04)
	_clock += delta
	if share >= _peak_share:
		_peak_share = share
		_peak_left = PEAK_HOLD
	elif _peak_left > 0.0:
		_peak_left -= delta
	else:
		_peak_share = maxf(_peak_share - PEAK_FALL * delta, share)
	var tremble := 0.0
	if _shown > BOOST_FROM:
		tremble = sin(_clock * 53.0) * TREMBLE * (_shown - BOOST_FROM) / (1.0 - BOOST_FROM)
	_pointer.rotation = _angle(_shown) + tremble
	_peak.rotation = _angle(_peak_share)
	_peak.visible = _peak_share > share + 0.02


func _draw() -> void:
	var pixels := KeptPictures.scale_of(self) * size
	var step := Vector2i(KeptPictures.step_up(pixels.x, 8), KeptPictures.step_up(pixels.y, 8))
	var key := "speed_dial|" + unit
	var face := KeptPictures.of(self, key, step, _face_picture.bind(step), FACES)
	if face != null:
		draw_texture_rect(face, Rect2(Vector2.ZERO, size), false)
	else:
		_draw_face(self, size, unit)
	var share := _share()
	if share > 0.0:
		draw_arc(
			size * 0.5,
			_radius(size),
			FROM,
			lerpf(FROM, TO, share),
			48,
			Color.WHITE,
			_thick(size),
			true
		)


## The face, drawn on [param on] at [param across]: the disc, the track, the boost and the red
## stretches, the ticks, the rim and the unit.
static func _draw_face(on: CanvasItem, across: Vector2, written: String) -> void:
	var side := minf(across.x, across.y)
	var middle := across * 0.5
	var thick := _thick(across)
	var radius := _radius(across)
	on.draw_circle(middle, side * 0.5 - 0.5, FACE)
	# The track, dark up to the kart's own top speed, the foil's past it where only nitro takes it,
	# and red at the end of that.
	var boost := lerpf(FROM, TO, BOOST_FROM)
	var red := lerpf(FROM, TO, RED_FROM)
	on.draw_arc(middle, radius, FROM, boost, 32, TRACK, thick, true)
	on.draw_arc(middle, radius, boost, red, 24, BOOST_TRACK, thick, true)
	on.draw_arc(middle, radius, red, TO, 12, RED_TRACK, thick, true)
	for i: int in TICKS + 1:
		var angle := lerpf(FROM, TO, float(i) / float(TICKS))
		var toward := Vector2.from_angle(angle)
		var long := i % 3 == 0
		var inner := radius - thick * (2.6 if long else 1.9)
		var ink := HouseTheme.STAMP_RED if float(i) / TICKS >= RED_FROM else TICK_INK
		on.draw_line(
			middle + toward * (radius - thick * 1.1),
			middle + toward * inner,
			ink,
			1.6 if long else 1.0,
			true
		)
	# The rim, foil, round the whole of it.
	on.draw_arc(middle, side * 0.5 - 1.0, 0.0, TAU, 64, Color(HouseTheme.FOIL, 0.7), 1.2, true)
	var font := Type.STRONG
	var unit_size := maxi(int(side * 0.11), 8)
	var wide := font.get_string_size(written, HORIZONTAL_ALIGNMENT_LEFT, -1, unit_size).x
	on.draw_string(
		font,
		Vector2(middle.x - wide * 0.5, middle.y + radius * 0.92),
		written,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		unit_size,
		TICK_INK
	)


## The face at [param pixels], for its picture, see [KeptPictures].
func _face_picture(pixels: Vector2i) -> Control:
	var drawn := Control.new()
	drawn.size = Vector2(pixels)
	var written := unit
	drawn.draw.connect(func() -> void: _draw_face(drawn, Vector2(pixels), written))
	return drawn


## A node over the middle of the dial drawn once by [param draw], which is only ever turned.
func _turning(draw: Callable) -> Node2D:
	var node := Node2D.new()
	node.draw.connect(draw.bind(node))
	add_child(node)
	return node


## The pointer, along +x from the middle, as [method _place] has it: a slim wedge out on the ring,
## clear of the number in the middle, foil along its back, and a dot of light at its tip.
func _draw_pointer(on: Node2D) -> void:
	var radius := _radius(size)
	var foot := radius * POINTER_FOOT
	var from := radius * POINTER_IN
	var to := radius * POINTER_OUT
	var wedge := PackedVector2Array(
		[
			Vector2(from, -foot),
			Vector2(to, -foot * 0.25),
			Vector2(to, foot * 0.25),
			Vector2(from, foot)
		]
	)
	on.draw_colored_polygon(wedge, Color(1.0, 0.36, 0.28))
	on.draw_line(Vector2(from, 0.0), Vector2(to, 0.0), Color(1.0, 0.9, 0.85, 0.9), 1.0, true)
	on.draw_circle(Vector2(from, 0.0), foot, HouseTheme.FOIL)


## The peak mark: a foil bar across the track, where the speed last stood highest.
func _draw_peak(on: Node2D) -> void:
	var radius := _radius(size)
	var half := _thick(size) * 0.75
	on.draw_line(
		Vector2(radius - half, 0.0), Vector2(radius + half, 0.0), HouseTheme.FOIL, 2.5, true
	)


## The pointer and the mark over the middle, drawn again for the dial's size.
func _place() -> void:
	for node: Node2D in [_peak, _pointer]:
		if node != null:
			node.position = size * 0.5
			node.queue_redraw()
	queue_redraw()


func _share() -> float:
	return clampf((value - min_value) / maxf(max_value - min_value, 0.001), 0.0, 1.0)


static func _angle(share: float) -> float:
	return lerpf(FROM, TO, share)


static func _thick(across: Vector2) -> float:
	return minf(across.x, across.y) * 0.5 * RING


static func _radius(across: Vector2) -> float:
	return minf(across.x, across.y) * 0.5 - _thick(across) * 0.5 - 1.0


func _set_unit(value: String) -> void:
	if value == unit:
		return
	unit = value
	queue_redraw()
