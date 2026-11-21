class_name PinwheelSpin
extends Node
## Turns the supporter pack's pinwheel, GAME.md 10.8: the faster the kart goes, the faster its
## wheel turns, and past a speed the six colors run together into a pale disc, as a color wheel's
## do, coming back apart as it slows; still when the kart is. Worked out from how far the wheel has
## moved since the last frame, so it turns wherever it is, on a kart in a match, a kart driving its
## laps in the kart dialog or a kart a client only sees; the look alone.

## How many turns a second it makes for each meter a second the kart goes.
const TURNS_PER_METER := 0.5
## Between which speeds, in meters a second, its vanes run together into the disc.
const BLUR_FROM := 3.5
const BLUR_TO := 6.5
## How quickly the speed it turns at follows the kart's, one over the seconds it takes to come most
## of the way, and the fastest it is taken to move, so a kart put back on the floor at a respawn
## does not set it whirling.
const EASE := 4.0
const MOST_SPEED := 30.0
## The disc's rings, from the hub out: how many, and how pale and how strong each is.
const RINGS := 6
const SEGMENTS := 40

## What turns, the vanes on it, and the disc they run together into.
var wheel: Node3D
var vanes: Array[MeshInstance3D] = []
var blur: MeshInstance3D
## The speed it turns at, eased, in meters a second.
var speed := 0.0
var _last := Vector3.ZERO
var _primed := false
## The vanes' paint, each its own, and the disc's.
var _vane_paints: Array[StandardMaterial3D] = []
var _blur_paint: StandardMaterial3D


func _ready() -> void:
	for vane: MeshInstance3D in vanes:
		var own := vane.material_override.duplicate() as StandardMaterial3D
		vane.material_override = own
		_vane_paints.append(own)
	if blur != null:
		_blur_paint = blur.material_override.duplicate() as StandardMaterial3D
		blur.material_override = _blur_paint


func _process(delta: float) -> void:
	if delta <= 0.0 or wheel == null or not wheel.is_inside_tree():
		return
	var at := wheel.global_position
	var moved := 0.0
	if _primed:
		moved = minf(at.distance_to(_last) / delta, MOST_SPEED)
	_last = at
	_primed = true
	step(delta, moved)


## One frame of [param delta] seconds with the wheel going [param moved] meters a second: turned,
## and its vanes faded into the disc as far as the speed says.
func step(delta: float, moved: float) -> void:
	speed = lerpf(speed, moved, 1.0 - exp(-EASE * delta))
	if wheel != null:
		wheel.rotation.z = wrapf(wheel.rotation.z + speed * TURNS_PER_METER * TAU * delta, 0.0, TAU)
	var run := smoothstep(BLUR_FROM, BLUR_TO, speed)
	for paint: StandardMaterial3D in _vane_paints:
		paint.albedo_color.a = 1.0 - run
	if _blur_paint != null:
		_blur_paint.albedo_color.a = run
	for vane: MeshInstance3D in vanes:
		vane.visible = run < 0.99
	if blur != null:
		blur.visible = run > 0.01


## The disc the vanes run together into, [param radius] out: rings from the hub out, each the colors
## of the vanes gone pale, the outer ones paler and fainter, carried in its corners' colors.
static func blur_mesh(radius: float) -> ArrayMesh:
	var cut := SurfaceTool.new()
	cut.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring: int in RINGS:
		var inner := radius * (0.15 + 0.85 * float(ring) / float(RINGS))
		var outer := radius * (0.15 + 0.85 * float(ring + 1) / float(RINGS))
		var tint := Color.from_hsv(float(ring) / float(RINGS), 0.25 + 0.05 * float(ring), 1.0)
		tint.a = 0.85 - 0.06 * float(ring)
		for segment: int in SEGMENTS:
			var from := TAU * float(segment) / float(SEGMENTS)
			var to := TAU * float(segment + 1) / float(SEGMENTS)
			for corner: Vector2 in [
				Vector2(inner, from),
				Vector2(outer, from),
				Vector2(outer, to),
				Vector2(inner, from),
				Vector2(outer, to),
				Vector2(inner, to),
			]:
				cut.set_color(tint)
				cut.add_vertex(Vector3(cos(corner.y) * corner.x, sin(corner.y) * corner.x, 0.0))
	return cut.commit()
