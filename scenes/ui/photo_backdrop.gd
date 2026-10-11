class_name PhotoBackdrop
extends Control
## What the photo finish on the payout slip is taken against, GAME.md 3.8: a stage at night, dark
## at the top and warmer toward the floor, a sunburst of foil light turning slowly behind the
## winner's step, a glow of gold round it, and two spotlights crossing onto the podium from the
## top corners. Drawn under the podium's picture, which has no background of its own, in a
## handful of draws a frame, and only while the podium is drawn.

## The stage: its top and its floor's colors.
const TOP := Color(0.06, 0.06, 0.11)
const FLOOR := Color(0.2, 0.14, 0.25)
## The sunburst: how many beams, how much of its share of the turn each lights, how strong at the
## middle, how long a whole turn takes, and where it is centered, as a share of the picture,
## behind the winner's step.
const BEAMS := 28
const BEAM_SHARE := 0.42
const BEAM_LIGHT := Color(Palette.CHIP_GOLD, 0.11)
const TURN_SECONDS := 60.0
const MIDDLE := Vector2(0.5, 0.62)
## The glow round the middle: how strong at its heart and how far it reaches, as a share of the
## picture's width, and in how many rings it is laid.
const GLOW := Color(Palette.CHIP_GOLD, 0.16)
const GLOW_REACH := 0.36
const GLOW_RINGS := 12
## The spotlights: how wide each is where it lands, as a share of the picture's width, how strong
## at the lamp and where it lands, and where each sways round its mark, and how fast.
const SPOT_WIDE := 0.2
const SPOT_LIGHT := Color(1.0, 0.95, 0.8, 0.14)
const SPOT_SWAY := 0.05
const SPOT_SECONDS := 9.0

var _turn := 0.0
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_turn = fmod(_turn + TAU * delta / TURN_SECONDS, TAU)
	_time += delta
	queue_redraw()


func _draw() -> void:
	var wide := size.x
	var tall := size.y
	if wide <= 0.0 or tall <= 0.0:
		return
	# The stage, darker overhead.
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(wide, 0.0), size, Vector2(0.0, tall)]),
		PackedColorArray([TOP, TOP, FLOOR, FLOOR])
	)
	var middle := size * MIDDLE
	var reach := size.length()
	_draw_burst(middle, reach)
	_draw_glow(middle, wide * GLOW_REACH)
	for side: float in [-1.0, 1.0]:
		_draw_spot(side)


## The sunburst round [param middle], out to [param reach], fading as it goes.
func _draw_burst(middle: Vector2, reach: float) -> void:
	var share := TAU / float(BEAMS)
	for i: int in BEAMS:
		var from := _turn + share * float(i)
		var to := from + share * BEAM_SHARE
		var points := PackedVector2Array(
			[
				middle,
				middle + Vector2.from_angle(from) * reach,
				middle + Vector2.from_angle(to) * reach
			]
		)
		var faded := Color(BEAM_LIGHT, 0.0)
		draw_polygon(points, PackedColorArray([BEAM_LIGHT, faded, faded]))


## The glow round [param middle], [param reach] out, in rings each a little fainter.
func _draw_glow(middle: Vector2, reach: float) -> void:
	for ring: int in GLOW_RINGS:
		var out := 1.0 - float(ring) / float(GLOW_RINGS)
		draw_circle(middle, reach * out, Color(GLOW, GLOW.a / float(GLOW_RINGS)), true, -1.0, true)


## A spotlight from the top corner on [param side], -1 the left and 1 the right, across onto the
## podium, swaying a little round where it lands.
func _draw_spot(side: float) -> void:
	var lamp := Vector2(size.x * (0.5 + 0.5 * side), -size.y * 0.1)
	var sway := sin(_time * TAU / SPOT_SECONDS + side) * SPOT_SWAY
	var lands := Vector2(size.x * (0.5 - 0.18 * side + sway), size.y)
	var half := size.x * SPOT_WIDE * 0.5
	var points := PackedVector2Array([lamp, lands + Vector2(half, 0.0), lands - Vector2(half, 0.0)])
	var faded := Color(SPOT_LIGHT, SPOT_LIGHT.a * 0.35)
	draw_polygon(points, PackedColorArray([SPOT_LIGHT, faded, faded]))
