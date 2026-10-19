class_name Inlay
extends RefCounted
## Paint let into the floor, GAME.md 8.1c: the flat shapes the House's pads are inked in, a chip,
## a ticket, a plate and its arrow, built into one mesh with their colors on its vertices, so every
## pad in a room is one material and a few dozen triangles, GAME.md 10.7. Everything of one inlay
## lies flat at one height and no shape of it over another, so nothing in it fights over a pixel.
##
## Shapes are laid out in the floor's own plane, x across and z down it, in meters round the
## mesh's middle; the colors are given as the room's are, and stored as the engine shades them.

## How many pieces a whole circle is cut into.
const SEGMENTS := 32

var _tool := SurfaceTool.new()
var _lift := 0.0


func _init(lift: float) -> void:
	_lift = lift
	_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tool.set_normal(Vector3.UP)


## The inlay as a mesh, worn in [param ink], see [method Surfaces.inlaid].
func node(ink: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = _tool.commit()
	mesh.material_override = ink
	# Paint on the floor throws no shadow, GAME.md 10.7.
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh


## A disc of [param color] out to [param radius] round [param at].
func disc(at: Vector2, radius: float, color: Color) -> void:
	for i: int in SEGMENTS:
		_triangle(at, at + _round(i, radius), at + _round(i + 1, radius), color)


## A ring of [param color] from [param inner] out to [param outer] round [param at]. With
## [param notches] it is cut into that many spots of [param notch] with runs of [param color]
## between, as the edge of a chip is.
func ring(
	at: Vector2, inner: float, outer: float, color: Color, notches := 0, notch := Color.BLACK
) -> void:
	var every := SEGMENTS / notches if notches > 0 else 0
	for i: int in SEGMENTS:
		var ink := notch if every > 0 and i % every == 0 else color
		_quad(
			at + _round(i, inner),
			at + _round(i, outer),
			at + _round(i + 1, outer),
			at + _round(i + 1, inner),
			ink
		)


## A shape of [param color] inside [param outline], which may be concave.
func fill(outline: PackedVector2Array, color: Color) -> void:
	var corners := Geometry2D.triangulate_polygon(outline)
	for k: int in range(0, corners.size(), 3):
		_triangle(outline[corners[k]], outline[corners[k + 1]], outline[corners[k + 2]], color)


## The band of [param color] between two outlines of as many points, [param outer] round
## [param inner], each point of one the other's across the band.
func band(outer: PackedVector2Array, inner: PackedVector2Array, color: Color) -> void:
	var count := outer.size()
	for i: int in count:
		var j := (i + 1) % count
		_quad(outer[i], outer[j], inner[j], inner[i], color)


## A rectangle of [param color].
func rect(area: Rect2, color: Color) -> void:
	var a := area.position
	var b := area.end
	_quad(a, Vector2(b.x, a.y), b, Vector2(a.x, b.y), color)


## A frame of [param color] [param wide] across inside the edge of [param area], as wide on every
## side whatever the area's size.
func frame(area: Rect2, wide: float, color: Color) -> void:
	var outer := _corners(area)
	var inner := _corners(area.grow(-wide))
	band(outer, inner, color)


## An arrow of [param color] pointing along [param way], [param length] long and [param wide]
## across its head, round [param at]: a head and a short shaft behind it.
func arrow(at: Vector2, way: Vector2, length: float, wide: float, color: Color) -> void:
	var along := way.normalized()
	var across := Vector2(-along.y, along.x)
	var tip := at + along * length * 0.5
	var base := at + along * (length * 0.5 - length * 0.62)
	_triangle(tip, base + across * wide * 0.5, base - across * wide * 0.5, color)
	var tail := at - along * length * 0.5
	var shaft := wide * 0.3
	_quad(
		base + across * shaft * 0.5,
		tail + across * shaft * 0.5,
		tail - across * shaft * 0.5,
		base - across * shaft * 0.5,
		color
	)


## The outline of a ticket with its corners at [param corner] and minus it round its middle,
## each corner bitten in by a quarter circle of [param notch] round it, as the House's tickets
## are, GAME.md 8.1a, and taken in by [param inset] all round: the inside edge of a band that
## wide. Outlines of one [param steps] are point for point, so two of them make a band, see
## [method band], as wide all the way round whatever the ticket's size.
static func ticket(corner: Vector2, notch: float, inset := 0.0, steps := 4) -> PackedVector2Array:
	var points := PackedVector2Array()
	var corners: Array[Vector2] = [Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]
	# Where each corner's bite starts, coming round clockwise, and how much of it the inset edges
	# cut off at either end.
	var starts: Array[float] = [PI, -PI * 0.5, 0.0, PI * 0.5]
	var radius := notch + inset
	var cut := asin(inset / radius) if radius > 0.0 else 0.0
	for k: int in 4:
		var middle := corner * corners[k]
		for s: int in steps + 1:
			var turn := lerpf(starts[k] - cut, starts[k] - PI * 0.5 + cut, float(s) / float(steps))
			points.append(middle + Vector2.from_angle(turn) * radius)
	return points


## The corners of [param area], clockwise from its top left as the floor is seen from above.
static func _corners(area: Rect2) -> PackedVector2Array:
	var a := area.position
	var b := area.end
	return PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)])


## A point [param radius] out at the [param i]th of [constant SEGMENTS] steps round a circle,
## clockwise as the floor is seen from above.
func _round(i: int, radius: float) -> Vector2:
	return Vector2.from_angle(TAU * float(i) / float(SEGMENTS)) * radius


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
	_triangle(a, b, c, color)
	_triangle(a, c, d, color)


## One triangle, wound the way the engine draws a face it is looking at, clockwise from above.
func _triangle(a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	if (b - a).cross(c - a) < 0.0:
		var swap := b
		b = c
		c = swap
	_tool.set_color(color.srgb_to_linear())
	for point: Vector2 in [a, b, c]:
		_tool.add_vertex(Vector3(point.x, _lift, point.y))
