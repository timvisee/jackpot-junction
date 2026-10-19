class_name ToyParts
extends RefCounted
## The parts the House's toy rooms are put together from, GAME.md 8.1c: the Arcade's playfield,
## the Playroom's molded set and the Sewing Table's felt. Primitives cut to the segment counts of
## GAME.md 10.7, a few shapes the rooms share (a block with its edges rounded, a puffed cushion, a
## stack of chips), and the dealing of a room's own clutter round its table, with the patch of
## table each of its kinds asks for, by the rules of 8.1 that [RoomProps] keeps for the kit's.
##
## Everything here is a [MeshInstance3D] put straight under the node it is built into, so a wall,
## a box and a room's clutter are baked by [Bake] as they always were.

## What one of a style's own kinds of prop asks of the table, as [constant RoomBuild.PATCH] has it
## for the kit's: the patch it covers in its own frame and how it is turned.
const PATCH := 0
const TURNED := 1
const BUILD := 2


static func box(into: Node3D, size: Vector3, skin: Material, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return put(into, mesh, skin, at)


## An upright cylinder, or a cone cut short when [param top] differs from [param bottom].
static func taper(
	into: Node3D, bottom: float, top: float, height: float, skin: Material, at: Vector3, sides := 12
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	return put(into, mesh, skin, at)


static func cylinder(
	into: Node3D, radius: float, height: float, skin: Material, at: Vector3, sides := 12
) -> MeshInstance3D:
	return taper(into, radius, radius, height, skin, at, sides)


## A flat disc [param radius] across, its middle [param lift] over its holder's floor.
static func disc(
	into: Node3D, radius: float, skin: Material, lift: float, thick := 0.01, sides := 24
) -> MeshInstance3D:
	return cylinder(into, radius, thick, skin, Vector3(0.0, lift, 0.0), sides)


static func ball(
	into: Node3D, radius: float, skin: Material, at: Vector3, sides := 12
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = sides
	mesh.rings = maxi(sides / 2, 3)
	return put(into, mesh, skin, at)


## The top half of a ball, flattened to [param tall]: a dome, a cushion's crown.
static func dome(
	into: Node3D, radius: float, tall: float, skin: Material, at: Vector3, sides := 16
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius
	mesh.is_hemisphere = true
	mesh.radial_segments = sides
	mesh.rings = maxi(sides / 4, 3)
	var node := put(into, mesh, skin, at)
	node.scale = Vector3(1.0, tall / radius, 1.0)
	return node


## A flat ring lying on its holder's floor, from [param inner] to [param outer] out.
static func ring(
	into: Node3D, inner: float, outer: float, skin: Material, at: Vector3, rings := 32, sides := 6
) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = rings
	mesh.ring_segments = sides
	return put(into, mesh, skin, at)


## A block of [param size] with its four upright edges rounded to [param round]: two boxes
## crossed and a cylinder down each corner, which is the shape a molded part is from above. The
## corners wear [param edges] where one is given, for a skin printed for flat faces only.
static func rounded(
	into: Node3D,
	size: Vector3,
	round: float,
	skin: Material,
	at: Vector3,
	sides := 8,
	edges: Material = null
) -> void:
	var r := minf(round, minf(size.x, size.z) * 0.5)
	box(into, Vector3(size.x - r * 2.0, size.y, size.z), skin, at)
	box(into, Vector3(size.x, size.y, size.z - r * 2.0), skin, at)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var off := Vector3((size.x * 0.5 - r) * corner.x, 0.0, (size.z * 0.5 - r) * corner.y)
		cylinder(into, r, size.y, edges if edges != null else skin, at + off, sides)


## A block of [param size] with its top edges rolled to [param round] as well as its upright
## ones: a cushion, a stuffed block, a molded die. The rolled edges are cylinders along the top
## and a quarter ball at each top corner, cut low, so it is a dozen pieces rather than a mesh.
## The top may wear [param crown] and the rolled edges [param edges], for a skin printed for
## flat faces, a stitch or an applique, that would only smear round a curve.
static func puffed(
	into: Node3D,
	size: Vector3,
	round: float,
	skin: Material,
	at: Vector3,
	sides := 8,
	crown: Material = null,
	edges: Material = null
) -> void:
	var r := minf(round, minf(minf(size.x, size.z) * 0.5, size.y * 0.5))
	var rim := edges if edges != null else skin
	var low := Vector3(size.x, size.y - r, size.z)
	rounded(into, low, r, skin, at - Vector3(0.0, r * 0.5, 0.0), sides, rim)
	var top := at + Vector3(0.0, size.y * 0.5 - r * 0.5, 0.0)
	box(into, Vector3(size.x - r * 2.0, r, size.z - r * 2.0), crown if crown != null else skin, top)
	var edge := at.y + size.y * 0.5 - r
	for side: float in [-1.0, 1.0]:
		var along_x := cylinder(
			into,
			r,
			size.x - r * 2.0,
			rim,
			Vector3(at.x, edge, at.z + side * (size.z * 0.5 - r)),
			sides
		)
		along_x.rotation.z = PI * 0.5
		var along_z := cylinder(
			into,
			r,
			size.z - r * 2.0,
			rim,
			Vector3(at.x + side * (size.x * 0.5 - r), edge, at.z),
			sides
		)
		along_z.rotation.x = PI * 0.5
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var off := Vector3((size.x * 0.5 - r) * corner.x, 0.0, (size.z * 0.5 - r) * corner.y)
		ball(into, r, rim, Vector3(at.x, edge, at.z) + off, sides)


## A short stack of [param count] chips [param radius] across and [param thick] each, standing at
## [param at] on its foot, in [param skin].
static func chips(
	into: Node3D, radius: float, thick: float, count: int, skin: Material, at: Vector3
) -> MeshInstance3D:
	return cylinder(
		into, radius, thick * float(count), skin, at + Vector3(0.0, thick * count * 0.5, 0.0), 12
	)


## A slab [param tall] high whose outline from above is [param outline], a convex polygon in its
## own x and z, standing on its foot at [param at]: a flipper's bat, a slingshot. Its top and its
## sides, and no bottom, since it stands on something.
static func slab(
	into: Node3D, outline: PackedVector2Array, tall: float, skin: Material, at: Vector3
) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array[Vector3] = []
	for point: Vector2 in outline:
		corners.append(Vector3(point.x, 0.0, point.y))
	var count := corners.size()
	var lift := Vector3(0.0, tall, 0.0)
	for i: int in range(1, count - 1):
		_face(tool, [corners[0] + lift, corners[i] + lift, corners[i + 1] + lift], Vector3.UP)
	var middle := Vector3.ZERO
	for corner: Vector3 in corners:
		middle += corner / float(count)
	for i: int in count:
		var a := corners[i]
		var b := corners[(i + 1) % count]
		var out := Vector3(b.z - a.z, 0.0, a.x - b.x).normalized()
		if out.dot((a + b) * 0.5 - middle) < 0.0:
			out = -out
		_face(tool, [a, b, b + lift], out)
		_face(tool, [a, b + lift, a + lift], out)
	# Indexed, as the engine's own primitives are: [method Bake.merge] appends a piece's indices
	# to the ones before it, and a piece without any is left out of what it is merged with.
	tool.index()
	return put(into, tool.commit(), skin, at)


## A flat face [param size] across, x by z, lying face up at [param at] and wearing the part
## [param uv] of its skin's picture, for a print several faces share as one sheet.
static func quad(
	into: Node3D, size: Vector2, uv: Rect2, skin: Material, at: Vector3
) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size * 0.5
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var along := (corner + Vector2.ONE) * 0.5
		tool.set_normal(Vector3.UP)
		tool.set_uv(uv.position + uv.size * along)
		tool.add_vertex(Vector3(corner.x * half.x, 0.0, corner.y * half.y))
	for index: int in [0, 1, 2, 0, 2, 3]:
		tool.add_index(index)
	return put(into, tool.commit(), skin, at)


## The outline of a flipper's bat from above: round at [param from], [param wide] across, and
## round again and [param narrow] across at [param to], in [param sides] a round end.
static func bat(
	from: Vector2, to: Vector2, wide: float, narrow: float, sides := 10
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in sides:
		var turn := TAU * float(i) / float(sides)
		points.append(from + Vector2.from_angle(turn) * wide)
		points.append(to + Vector2.from_angle(turn) * narrow)
	var hull := Geometry2D.convex_hull(points)
	hull.remove_at(hull.size() - 1)
	return hull


## One triangle of [param corners] facing [param out], whichever way round they were given:
## Godot draws a face whose corners run clockwise from the side it is seen from.
static func _face(tool: SurfaceTool, corners: Array[Vector3], out: Vector3) -> void:
	var turn := (corners[1] - corners[0]).cross(corners[2] - corners[0])
	if turn.dot(out) > 0.0:
		corners = [corners[0], corners[2], corners[1]]
	for corner: Vector3 in corners:
		tool.set_normal(out)
		tool.add_vertex(corner)


static func put(into: Node3D, mesh: Mesh, skin: Material, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)
	return node


## Casts no shadow: paint on the floor, a lit insert, a thing a few pixels across, GAME.md 10.7.
static func flat(node: MeshInstance3D) -> MeshInstance3D:
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


# --- the room's clutter --------------------------------------------------------


## Puts a prop of [param kind] down at [param at] under [param props], as [method RoomProps._lay]
## puts the kit's, with the patch and the turn a style gives it in [param what], [constant PATCH],
## [constant TURNED] and [constant BUILD]: checked against everything already on the table unless
## [param by_hand], and kept in [member RoomProps.laid_out] so the rules of 8.1 can be checked.
static func lay(
	props: RoomProps, kind: StringName, what: Array, at: Vector3, by_hand := false
) -> bool:
	var turn: float = props._turn_of(what[TURNED], at)
	var box_on: Rect2 = props._ground(what[PATCH], at, turn)
	if not by_hand and not props._free(box_on):
		return false
	var from := props.get_child_count()
	(what[BUILD] as Callable).call(at, turn)
	props._taken.append(box_on)
	props.laid_out.append(
		{"kind": kind, "box": box_on, "from": from, "to": props.get_child_count(), "turn": turn}
	)
	return true


## Deals [param count] of a style's own props round the far side and the flanks of the table,
## the way [method RoomProps._ring] deals the kit's: [param near] are the small things that may
## stand close to the crowd and [param far] the big ones that keep their distance, each a kind
## and what [method lay] wants of it.
static func deal_round(props: RoomProps, count: int, near: Dictionary, far: Dictionary) -> void:
	var half := props.arena.world_size() * 0.5
	var near_deal := props._deal(near.size(), count)
	var far_deal := props._deal(far.size(), count)
	var near_next := 0
	var far_next := 0
	for i: int in count:
		var behind := i % 5 < 3
		var big := not behind and i % 2 == 1
		var kinds := far if big else near
		var kind: StringName = kinds.keys()[far_deal[far_next] if big else near_deal[near_next]]
		if big:
			far_next += 1
		else:
			near_next += 1
		for attempt: int in RoomProps.TRIES:
			if lay(props, kind, kinds[kind], props._spot(half, i, big)):
				break


## [param count] of a style's flat things on the near apron, as [method RoomProps._apron] puts the
## kit's: nothing that stands up, since that is the side the camera looks across.
static func deal_apron(props: RoomProps, count: int, kinds: Dictionary) -> void:
	var half := props.arena.world_size() * 0.5
	var deal := props._deal(kinds.size(), count)
	var from := props.clutter_from + RoomProps.APRON_CLEAR
	for i: int in count:
		var kind: StringName = kinds.keys()[deal[i]]
		for attempt: int in RoomProps.TRIES:
			var along := props._lined(props._rng.randf_range(-1.0, 1.0) * (half.x + RoomBuild.FAR))
			var away := from + (RoomBuild.FAR - from) * pow(props._rng.randf(), RoomProps.CROWDING)
			var spot := Vector3(along, RoomBuild.TOP, half.y + props._lined(away))
			if lay(props, kind, kinds[kind], spot):
				break
