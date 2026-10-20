class_name RoomStyle
extends RefCounted
## What makes one room look like no other, GAME.md 8.1c: a script a room names, [member
## RoomLook.style], that builds its walls, its boxes, its pits, the face of its Junction, its
## floor and the room round the table. Every hook answers whether it built the thing: one that
## answers no, as all of these do, leaves it to the room's kit as it always was, so a style says
## only what it changes.
##
## What a style does not decide is the same in every room, and is what makes them one game: the
## shapes the play is in (a wall is the block it was, a box the cube, a pad the disc), the House's
## rail round the arena, the Junction's neon ring, the House's layout on the floor in the room's
## inks, the paper crowd in the room's wardrobe, and the colors' jobs of 8.1a.
##
## A style is made once a room is built, with the room, its surfaces and a generator seeded off
## the room, so a room is furnished the same way every time.

## How far toward the floor's own color the inks of what lies on it are taken, see [method
## dropped]: a room's red or ivory lying on the floor is that red or ivory in the felt's shade, a
## thing found once looked for rather than a speck the eye goes to.
const LITTER_MUTE := 0.5

var room: RoomLook
var surfaces: Surfaces
var rng := RandomNumberGenerator.new()


func _init(for_room: RoomLook, for_surfaces: Surfaces) -> void:
	room = for_room
	surfaces = for_surfaces
	rng.seed = hash(room.id) + 7


## An inner wall of [param size], the collider's box, built under [param holder] with its foot at
## -size.y / 2; [param index] counts the walls, for dressing every few. Whether it was built.
func wall(_holder: Node3D, _size: Vector3, _index: int) -> bool:
	return false


## The breakable box of [param size], built under [param holder] round its middle and inside its
## cube. Whether it was built.
func crate(_holder: Node3D, _size: Vector3) -> bool:
	return false


## The pop bumper of GAME.md 6.2, built under [param holder] on the floor at its middle and inside
## the cylinder [param radius] round and [param height] tall its collider is. Whatever is named
## `Lamp` the bumper lights when it fires, see [Bumper]. Whether it was built.
func bumper(_holder: Node3D, _radius: float, _height: float) -> bool:
	return false


## What waits at the bottom of a pit of [param size] across, under [param into], below the floor.
## Whether it was built.
func pit(_into: Node3D, _size: Vector2) -> bool:
	return false


## The face of the cash-out pad out to [param radius], flat on the floor under [param into]. The
## neon ring round it is not the style's: every room has the same one. Whether it was built.
func junction(_into: Node3D, _radius: float) -> bool:
	return false


## Whatever stands on a Jackpot's tile of [param size], under [param into]. Its chips are built
## under the stacks of [method JackpotPile.on], so they show what the Jackpot holds, GAME.md 3.5.
## Whether it was built.
func jackpot(_into: Node3D, _size: Vector2) -> bool:
	return false


## Whatever lies over a turbo pad's cell at [param at], [param cell] across, under [param into].
## Whether it was built.
func turbo(_into: Node3D, _at: Vector3, _cell: float) -> bool:
	return false


## The material of the floor the karts drive on, or null for the room's felt or concrete.
func floor_top() -> StandardMaterial3D:
	return null


## The material of the table round the arena, where the crowd stands, or null for the room's own.
func surround() -> StandardMaterial3D:
	return null


## The room round the table, built through [param props] and its [member RoomProps.shell]: the
## walls of the room, what hangs on them and what lies about. Whether it was built; a style that
## builds none leaves the room the Workbench's.
func room_round(_props: RoomProps) -> bool:
	return false


## Where this room says the House's word, STORY.md 6.1: off the table, in the room's own medium,
## where the shot a match opens on sees it, GAME.md 8.2, laid there with [method HouseWord.lay]
## once [param arena]'s room is built. Whether it was; one that answers no has the word painted on
## the near apron, [method HouseWord.on_the_apron].
func house_word(_word: HouseWord, _arena: Arena) -> bool:
	return false


## The inks the House's layout is printed in on this floor, GAME.md 8.1b, as [lines, words], or
## an empty array for the room's trim and marking.
func layout_inks() -> Array[Color]:
	return []


## What this floor has printed on it under the House's layout, GAME.md 8.1c, drawn with
## [param on]'s own draw calls before the House's marks, in its pixels, [constant
## LayoutPrint.CELL_PIXELS] to a cell. Nothing for a floor that is the felt alone.
func print_under(_on: LayoutPrint) -> void:
	pass


## What this room leaves lying on the floor the karts drive on, GAME.md 8.1c: piece [param which]
## of the few the kit drops, built under [param into] round its origin. The kit has put that on
## open floor, clear of every pad, lane, pit and Junction and of the other pieces, and turned it at
## random, so a piece lies flat about it, a hand or two across ([constant RoomKit.LITTER_REACH]
## at the most) and lower than [constant RoomKit.LITTER], built of [method dropped]'s parts.
## [param dice] is the litter's own generator, so what a room drops moves nothing else it builds.
## Whether it was built; one that answers no leaves it the kit's washers and screws.
func litter(_into: Node3D, _which: int, _dice: RandomNumberGenerator) -> bool:
	return false


## How far toward the floor's own color this room takes its litter's inks, see [method dropped]:
## [constant LITTER_MUTE] unless the room's floor would swallow it, as a felt does a thread.
func litter_mute() -> float:
	return LITTER_MUTE


## One part of a piece of litter, see [method litter]: [param mesh] at [param at] under
## [param into], turned by [param tilt] and sized by [param size], in [param ink] taken
## [method litter_mute] of the way to the floor's own color, so a thing lying on the floor is
## never brighter than the room it is in, and in plain paint or, for [param metal], metal. Its
## color is on its vertices, so all the litter on a table bakes into a mesh or two in shaders the
## warm-up has compiled, see [method Bake.tinted].
func dropped(
	into: Node3D,
	mesh: Mesh,
	ink: Color,
	at: Vector3,
	tilt := Vector3.ZERO,
	metal := false,
	size := Vector3.ONE
) -> MeshInstance3D:
	return lay(into, mesh, ink.lerp(room.felt, litter_mute()), at, tilt, metal, size)


## [param mesh] in [param color] as it is, the way [method dropped] lays a part: for the kit's own
## litter, which has no style to mute it. The place is baked into the mesh, so the part is a
## mesh at the origin of [param into] whatever its size.
static func lay(
	into: Node3D,
	mesh: Mesh,
	color: Color,
	at: Vector3,
	tilt := Vector3.ZERO,
	metal := false,
	size := Vector3.ONE
) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var place := Transform3D(Basis.from_euler(tilt) * Basis.from_scale(size), at)
	node.mesh = Bake.tinted([[mesh, place, color]])
	node.material_override = Bake.tinted_look(metal)
	into.add_child(node)
	return node


## The shapes litter is made of, few-sided so a table's worth is a few hundred triangles: a flat
## [param size] of card or paper; a [param radius] round rod [param length] long and [param sides]
## round, upright until it is tilted, tapering to [param tip] when that is given; a bead
## [param sides] round; a ring lying flat, a curl of shaving or a washer squashed; and a shape cut
## out of card or felt, see [method cutout].
static func slab(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func rod(radius: float, length: float, sides := 6, tip := -1.0) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if tip < 0.0 else tip
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = sides
	mesh.rings = 1
	return mesh


static func bead(radius: float, sides := 8) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = sides
	mesh.rings = sides / 2
	return mesh


static func curl(radius: float, thick: float) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thick
	mesh.outer_radius = radius + thick
	mesh.rings = 10
	mesh.ring_segments = 4
	return mesh


## A flat shape [param thick] thick, its foot on the floor, round [param outline] in meters across
## the floor, any way round and any shape that does not cross itself: a leaf, a pinked snip of
## felt, a star. No underside, since it lies on the floor.
static func cutout(outline: PackedVector2Array, thick: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var high: Array[Vector3] = []
	for point: Vector2 in outline:
		high.append(Vector3(point.x, thick, point.y))
	var corners := Geometry2D.triangulate_polygon(outline)
	for i: int in range(0, corners.size(), 3):
		_facet(tool, [high[corners[i]], high[corners[i + 1]], high[corners[i + 2]]], Vector3.UP)
	# Which way out is from an edge, by which way round the outline goes: twice its area, signed.
	var area := 0.0
	for i: int in outline.size():
		area += outline[i].cross(outline[(i + 1) % outline.size()])
	for i: int in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var out := Vector3(b.y - a.y, 0.0, a.x - b.x).normalized() * signf(area)
		var low_a := Vector3(a.x, 0.0, a.y)
		var low_b := Vector3(b.x, 0.0, b.y)
		var high_b := low_b + Vector3.UP * thick
		_facet(tool, [low_a, low_b, high_b], out)
		_facet(tool, [low_a, high_b, low_a + Vector3.UP * thick], out)
	return tool.commit()


## One triangle of [param corners] facing [param facing], wound the way the engine draws a face
## it sees from the front, whichever way the corners came.
static func _facet(tool: SurfaceTool, corners: Array[Vector3], facing: Vector3) -> void:
	var turn := (corners[1] - corners[0]).cross(corners[2] - corners[0])
	var flip := turn.dot(facing) > 0.0
	tool.set_normal(facing)
	tool.add_vertex(corners[0])
	tool.add_vertex(corners[2] if flip else corners[1])
	tool.add_vertex(corners[1] if flip else corners[2])
