class_name GuideDots
extends Node3D
## A dotted line on the floor, GAME.md 9.4a: the path a bank shot takes, from where to stand,
## through the window, off the wall and onto the target, so the Ricochet lesson is lining the kart
## up with the dots rather than finding the angle by trial. The dots pulse together.

const COLOR := Palette.NEON_CYAN
const RADIUS := 0.11
const LIFT := 0.03
const SPACING := 0.6
const PULSE := 0.9

var _material: StandardMaterial3D
var _time := 0.0


## Dots along [param points], a corner at each, [constant SPACING] apart.
static func lay(parent: Node, points: Array[Vector3]) -> GuideDots:
	var dots := GuideDots.new()
	dots.name = "GuideDots"
	parent.add_child(dots)
	dots._build(points)
	return dots


func _build(points: Array[Vector3]) -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = COLOR
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var disc := CylinderMesh.new()
	disc.top_radius = RADIUS
	disc.bottom_radius = RADIUS
	disc.height = LIFT
	disc.radial_segments = 10
	disc.rings = 1
	for i: int in range(1, points.size()):
		var from := Vector3(points[i - 1].x, LIFT * 0.5, points[i - 1].z)
		var to := Vector3(points[i].x, LIFT * 0.5, points[i].z)
		var length := from.distance_to(to)
		var count := maxi(1, roundi(length / SPACING))
		for j: int in count + 1:
			if i > 1 and j == 0:
				continue
			var dot := MeshInstance3D.new()
			dot.mesh = disc
			dot.material_override = _material
			dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(dot)
			dot.global_position = from.lerp(to, float(j) / count)


func _process(delta: float) -> void:
	_time += delta
	var pulse := 0.5 + 0.5 * sin(_time * TAU * PULSE)
	_material.albedo_color = Color(COLOR, 0.45 + 0.5 * pulse)
