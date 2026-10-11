class_name PhotoBackdrop
extends Control
## What the photo finish on the payout slip is taken against, GAME.md 3.8: a stage at night, dark
## at the top and warmer toward the floor, lit as the House's invitation is, STORY.md 6.1a, by two
## lamps just off its top corners, their soft beams crossing onto the podium and a pool of their
## light on the floor under it; the light breathing slowly up and down, and nothing else moving.
## The beams and the pool are the invitation's own, see [method OpeningInvitation.draw_beams],
## drawn on a stage the invitation's width, scaled to the picture. Drawn under the podium's
## picture, which has no background of its own, once, and again only as it changes size; the
## light breathes by its layer's modulate, without drawing it again.

## The stage: its top and its floor's colors.
const TOP := Color(0.04, 0.04, 0.08)
const FLOOR := Color(0.17, 0.12, 0.21)
## The lamps and where they light, on a stage as wide as the invitation's, see [constant
## OpeningInvitation.STAGE], as tall as the picture is for it: just off the top, toward its
## corners, both on the winner's step, which stands in the middle a little below halfway.
const LAMPS: Array[Vector2] = [Vector2(300.0, -150.0), Vector2(1620.0, -150.0)]
const LIT := Vector2(0.5, 0.68)
## The pool of light on the floor round the podium, flattened as a pool on a floor seen from the
## front is: how wide and how tall a share of the invitation's it is.
const POOL_SQUASH := Vector2(0.85, 0.42)
## How the light breathes: from how bright to how bright, against the invitation's, which lights a
## darker room, and how long a breath takes.
const DIMMEST := 0.95
const BRIGHTEST := 1.4
const BREATH_SECONDS := 7.0

var _lights: Node2D
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lights = Node2D.new()
	_lights.name = "Lights"
	_lights.draw.connect(_draw_lights)
	_lights.modulate.a = DIMMEST
	add_child(_lights)
	resized.connect(
		func() -> void:
			queue_redraw()
			_lights.queue_redraw()
	)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	var breath := 0.5 - 0.5 * cos(_time * TAU / BREATH_SECONDS)
	_lights.modulate.a = lerpf(DIMMEST, BRIGHTEST, breath)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	# The stage, darker overhead.
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)]),
		PackedColorArray([TOP, TOP, FLOOR, FLOOR])
	)


## The beams, the lamps' glare and the pool, on a stage the invitation's width scaled down to the
## picture's.
func _draw_lights() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale := size.x / OpeningInvitation.STAGE.x
	var stage := Vector2(OpeningInvitation.STAGE.x, size.y / scale)
	var lit := stage * LIT
	_lights.draw_set_transform(lit * scale, 0.0, POOL_SQUASH * scale)
	OpeningInvitation.draw_pool(_lights)
	_lights.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * scale)
	OpeningInvitation.draw_beams(_lights, lit, LAMPS)
	_lights.draw_set_transform_matrix(Transform2D.IDENTITY)
