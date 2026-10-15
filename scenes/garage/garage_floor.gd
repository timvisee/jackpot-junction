class_name GarageFloor
extends Node3D
## The paint on the Garage's floor, GAME.md 9.4, which says what each part of the room is for now
## that nothing in it has a sign over it: two rings round the Junction to drift round, the outer one
## through the four Royal Flush pads so a lap of it takes them all, with the old marks of laps karts
## have driven round them, which never fade; a lane for each target at the back with a firing line
## across their foot; a numbered bay for each kart parked in here, the dummies; and hazard stripes
## round the pit. The lift's bay is the lift's own, see [KartLift].
##
## All of it is found from the arena's own furniture rather than from the map's text, so moving a
## thing in the layout moves its paint with it, and it is drawn as one mesh for each ink, GAME.md
## 10.7: the rings in the room's marking white, the lanes, bays and stripes in the lift's yellow and
## the marks in the karts' own look for them, see [TireMarks].

## How high the paint lies: on the floor, under the pads and the lift's lines.
const HEIGHT := 0.008
## How high the old marks lie: over the paint, under the marks a kart lays now.
const MARKS_HEIGHT := 0.012
## The rings: how wide the outer one is painted, the inner one's radius and width, how many dashes
## the inner one is broken into, and how many pieces a ring is drawn in.
const OUTER_WIDE := 0.2
const INNER := 4.5
const INNER_WIDE := 0.16
const DASHES := 28
const SEGMENTS := 112
## The outer ring with no Royal Flush pads to run through.
const OUTER := 8.0
## The lines of the lanes and the bays, as wide as the lift's, and the firing line a little wider.
const LINE := 0.08
const FIRING_LINE := 0.14
## How deep the lanes run out from the back wall, and how wide a lane is with only one target, in
## cells; how wide and deep a bay is, in cells.
const LANE_CELLS := 4.0
const LANE_WIDE := 3.0
const BAY_CELLS := Vector2(3.0, 3.0)
## Where a bay's number is painted, in cells in front of the kart in it.
const NUMBER_AT := 1.05
## The words: the firing line's, how tall its capitals and the bays' numbers stand, and the size of
## the font they are drawn from.
const FIRING_WORDS := "FIRING LINE"
const WORDS_TALL := 0.26
const NUMBER_TALL := 0.6
const WORDS_SIZE := 96
## The hazard stripes round a pit: how far out they reach, in cells, how wide a stripe is and how
## far it is from one to the next, in meters.
const STRIPES_OUT := 0.75
const STRIPE := 0.24
const STRIPE_EVERY := 0.6
## The old marks of laps driven round the rings, each [where between the rings, 0 the inner and 1
## the outer, from and to, in degrees round from +X toward the front of the room, how dark]. Each is
## a kart's two rear wheels, [constant WHEELS] apart, fading in and out over [constant TAPER] of it,
## wandering in and out by up to [constant WANDER] meters as a drift does.
const MARKS: Array[Array] = [
	[0.4, 200.0, 300.0, 0.34],
	[0.2, 15.0, 130.0, 0.3],
	[0.55, 140.0, 178.0, 0.24],
	[0.75, 318.0, 352.0, 0.22],
]
const WHEELS := 0.55
const TAPER := 0.18
const WANDER := 0.3
## When an old mark was laid, as far as the marks' look is concerned: so far off that it never
## fades, see tire_marks.gdshader.
const NEVER := 1.0e9

## The rings' radii, in meters.
var inner := INNER
var outer := OUTER
## The meshes, by what they are of, for a test to look at.
var rings: MeshInstance3D
var lines: MeshInstance3D
var marks: MeshInstance3D

var _arena: Arena


## Paints the floor of [param in_match]'s room, a bay under each kart in [member Match.parked].
static func add_to(in_match: Match) -> GarageFloor:
	var paint := GarageFloor.new()
	paint.name = "GarageFloor"
	paint._arena = in_match.arena
	in_match.arena.add_child(paint)
	var bays: Array[Vector3] = []
	for slot: int in in_match.parked:
		bays.append(in_match.parked[slot].origin)
	paint._paint(bays)
	return paint


func _paint(bays: Array[Vector3]) -> void:
	var middle := _arena.junction_position
	if not _arena.flush_pads.is_empty():
		var reach := 0.0
		for pad: FlushPad in _arena.flush_pads:
			reach += _flat(pad.global_position - middle).length()
		outer = reach / _arena.flush_pads.size()
	var white := PackedVector3Array()
	_ring(white, middle, outer, OUTER_WIDE, 0)
	_ring(white, middle, inner, INNER_WIDE, DASHES)
	rings = _mesh(white, _arena.surfaces.marking(_arena.room.marking), "Rings")
	var yellow := PackedVector3Array()
	_lanes(yellow)
	for i: int in bays.size():
		_bay(yellow, bays[i], i + 1)
	for pit: Rect2i in _arena.grid.pits:
		_stripes(yellow, pit)
	lines = _mesh(yellow, _arena.surfaces.marking(KartLift.LINE_INK), "Lines")
	marks = _old_marks(middle)


## A ring of [param wide] round [param middle] at [param radius], broken into [param dashes] dashes
## with a gap as long as each between them, or whole for none.
func _ring(
	tris: PackedVector3Array, middle: Vector3, radius: float, wide: float, dashes: int
) -> void:
	var steps := SEGMENTS if dashes <= 0 else dashes * 4
	for i: int in steps:
		# A dash is two pieces long and so is the gap after it.
		if dashes > 0 and i % 4 >= 2:
			continue
		var from := TAU * float(i) / steps
		var to := TAU * float(i + 1) / steps
		var a := Vector3(cos(from), 0.0, sin(from))
		var b := Vector3(cos(to), 0.0, sin(to))
		var near := radius - wide * 0.5
		var far := radius + wide * 0.5
		_quad(tris, middle + a * near, middle + b * near, middle + b * far, middle + a * far)


## A lane up to each target from the firing line across their foot, and the firing line's words
## under it: the targets stand against the back wall, see [Target], and are shot at from in front.
func _lanes(tris: PackedVector3Array) -> void:
	var targets := _arena.targets
	if targets.is_empty():
		return
	var cell := _arena.grid.cell_size
	var xs: Array[float] = []
	for target: Target in targets:
		xs.append(target.global_position.x)
	xs.sort()
	var wide := cell * LANE_WIDE
	if xs.size() > 1:
		wide = (xs[-1] - xs[0]) / (xs.size() - 1)
	var top := targets[0].global_position.z - cell * 0.5
	var foot := top + cell * LANE_CELLS
	var left := xs[0] - wide * 0.5
	for i: int in xs.size() + 1:
		var x := left + wide * i
		_line(tris, Vector3(x, 0.0, top), Vector3(x, 0.0, foot), LINE)
	var right := left + wide * xs.size()
	_line(tris, Vector3(left, 0.0, foot), Vector3(right, 0.0, foot), FIRING_LINE)
	_words(FIRING_WORDS, Vector3((left + right) * 0.5, 0.0, foot + WORDS_TALL * 1.4), WORDS_TALL)


## The bay a kart is parked in at [param at], backed against the wall behind it: a line down either
## side and its [param number] on the floor in front of the kart.
func _bay(tris: PackedVector3Array, at: Vector3, number: int) -> void:
	var cell := _arena.grid.cell_size
	var half := BAY_CELLS * cell * 0.5
	for side: float in [-1.0, 1.0]:
		var x := at.x + side * half.x
		_line(tris, Vector3(x, 0.0, at.z - half.y), Vector3(x, 0.0, at.z + half.y), LINE)
	_words(str(number), Vector3(at.x, 0.0, at.z + cell * NUMBER_AT), NUMBER_TALL)


## Stripes at a slant all round [param pit], a cell wide, the way a hole in a workshop floor is
## painted round.
func _stripes(tris: PackedVector3Array, pit: Rect2i) -> void:
	var grid := _arena.grid
	var middle := grid.rect_center(pit)
	var size := grid.rect_size(pit)
	var hole := _square(Vector2(middle.x, middle.z), size * 0.5)
	var around := _square(
		Vector2(middle.x, middle.z), size * 0.5 + Vector2.ONE * grid.cell_size * STRIPES_OUT
	)
	var reach := size.x + size.y + grid.cell_size * STRIPES_OUT * 4.0
	var from := middle.x - reach
	while from < middle.x + reach:
		# One stripe: a band running at 45 degrees, long enough to cross the whole frame.
		var band := PackedVector2Array(
			[
				Vector2(from, middle.z - reach),
				Vector2(from + STRIPE, middle.z - reach),
				Vector2(from + STRIPE + reach * 2.0, middle.z + reach),
				Vector2(from + reach * 2.0, middle.z + reach),
			]
		)
		band = _shift(band, Vector2(-reach, 0.0))
		for inside: PackedVector2Array in Geometry2D.intersect_polygons(band, around):
			for piece: PackedVector2Array in Geometry2D.clip_polygons(inside, hole):
				_polygon(tris, piece)
		from += STRIPE_EVERY


## The old marks round the rings, in the look a kart's plain marks are drawn with, never fading.
func _old_marks(middle: Vector3) -> MeshInstance3D:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for mark: Array in MARKS:
		var radius := lerpf(inner, outer, float(mark[0]))
		for wheel: float in [-0.5, 0.5]:
			_arc(mesh, middle, radius + wheel * WHEELS, mark)
	mesh.surface_end()
	var made := MeshInstance3D.new()
	made.name = "Marks"
	made.mesh = mesh
	made.material_override = TireMarks.look()
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(made)
	return made


## One wheel's mark along [param radius] round [param middle], from and to as [param mark] has them.
func _arc(mesh: ImmediateMesh, middle: Vector3, radius: float, mark: Array) -> void:
	var from := deg_to_rad(float(mark[1]))
	var to := deg_to_rad(float(mark[2]))
	var steps := maxi(4, int(absf(to - from) * radius / 0.3))
	var half := TireMarks.TRACK_WIDTH * 0.5
	for i: int in steps:
		var pieces: Array[Array] = []
		for end: int in 2:
			var share := float(i + end) / steps
			var angle := lerpf(from, to, share)
			var out := Vector3(cos(angle), 0.0, sin(angle))
			# Out wide through the middle of the slide and back in at its ends, a little unevenly.
			var wander := WANDER * (0.8 * sin(share * PI) + 0.2 * sin(share * TAU + from))
			var at := middle + out * (radius + wander) + Vector3.UP * MARKS_HEIGHT
			var fade := minf(minf(share, 1.0 - share) / TAPER, 1.0)
			pieces.append([at - out * half, at + out * half, float(mark[3]) * fade])
		var near: Array = pieces[0]
		var far: Array = pieces[1]
		for corner: Array in [
			[near[0], 0.0, near[2]],
			[far[0], 0.0, far[2]],
			[far[1], 1.0, far[2]],
			[near[0], 0.0, near[2]],
			[far[1], 1.0, far[2]],
			[near[1], 1.0, near[2]],
		]:
			mesh.surface_set_color(Color(float(corner[1]), TireMarks.TRACK_WIDTH * 2.0, 0.0))
			mesh.surface_set_uv(Vector2(NEVER, 0.0))
			mesh.surface_set_uv2(Vector2(float(corner[2]), 0.0))
			mesh.surface_add_vertex(corner[0])


## [param words] painted flat on the floor at [param at] in the lift's yellow, read from the
## camera's side, their capitals [param tall] high, in the lift's own lettering.
func _words(words: String, at: Vector3, tall: float) -> void:
	var label := Label3D.new()
	label.name = "Painted"
	label.text = words
	label.font = Type.mark_font()
	label.font_size = WORDS_SIZE
	label.outline_size = 0
	label.pixel_size = tall / (WORDS_SIZE * Type.CAP_HEIGHT)
	label.modulate = Color(KartLift.LINE_INK, 0.9)
	label.rotation.x = -PI * 0.5
	label.position = Vector3(at.x, HEIGHT + 0.004, at.z)
	add_child(label)


func _line(tris: PackedVector3Array, from: Vector3, to: Vector3, wide: float) -> void:
	var along := (to - from).normalized()
	var side := Vector3(-along.z, 0.0, along.x) * wide * 0.5
	# Squared off past each end by half its width, so lines meeting at a corner close it.
	var a := from - along * wide * 0.5
	var b := to + along * wide * 0.5
	_quad(tris, a - side, b - side, b + side, a + side)


func _quad(tris: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_triangle(tris, a, b, c)
	_triangle(tris, a, c, d)


## A triangle of paint facing up, whichever way round its corners come.
func _triangle(tris: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	var up := Vector3.UP * HEIGHT
	a = Vector3(a.x, 0.0, a.z) + up
	b = Vector3(b.x, 0.0, b.z) + up
	c = Vector3(c.x, 0.0, c.z) + up
	if (b - a).cross(c - a).y < 0.0:
		tris.append_array([a, b, c])
	else:
		tris.append_array([a, c, b])


func _polygon(tris: PackedVector3Array, piece: PackedVector2Array) -> void:
	var corners := Geometry2D.triangulate_polygon(piece)
	for i: int in range(0, corners.size(), 3):
		var a := piece[corners[i]]
		var b := piece[corners[i + 1]]
		var c := piece[corners[i + 2]]
		_triangle(tris, Vector3(a.x, 0.0, a.y), Vector3(b.x, 0.0, b.y), Vector3(c.x, 0.0, c.y))


func _mesh(tris: PackedVector3Array, skin: Material, called: String) -> MeshInstance3D:
	var made := MeshInstance3D.new()
	made.name = called
	if not tris.is_empty():
		var normals := PackedVector3Array()
		normals.resize(tris.size())
		normals.fill(Vector3.UP)
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = tris
		arrays[Mesh.ARRAY_NORMAL] = normals
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		made.mesh = mesh
	made.material_override = skin
	# Paint on the floor casts nothing.
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(made)
	return made


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


static func _square(middle: Vector2, half: Vector2) -> PackedVector2Array:
	return PackedVector2Array(
		[
			middle + Vector2(-half.x, -half.y),
			middle + Vector2(half.x, -half.y),
			middle + Vector2(half.x, half.y),
			middle + Vector2(-half.x, half.y),
		]
	)


static func _shift(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var moved := PackedVector2Array()
	for point: Vector2 in points:
		moved.append(point + by)
	return moved
