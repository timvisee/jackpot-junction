class_name CountKit
extends RefCounted
## The Count Room's furniture, STORY.md 3.9 and GAME.md 8.1, for [RoomKit] to build where another
## room builds its own: walls as server racks with their capping strip lit, the breakable boxes as
## stacks of drives, the Junction as a processor seen from above, the pits as floor tiles lifted
## out with cable at the bottom, no two runs of it alike, the Jackpot tiles as memory banks, the
## turbo pads as cooling vents, and red patch cables looped over some of the racks. Looks only:
## every one of them plays as it does in any room. Everything is square to the grid, since nobody
## has ever been in here to knock anything; only cable lies as cable does.

const LEDS: Shader = preload("res://scenes/story/count_leds.gdshader")
const MONITOR: Shader = preload("res://scenes/story/count_monitor.gdshader")
const RACK := Color(0.17, 0.19, 0.19)
const DRIVE := Color(0.36, 0.38, 0.41)
const PCB := Color(0.05, 0.2, 0.1)
const PIN := Color(0.86, 0.68, 0.3)
const DIE := Color(0.06, 0.06, 0.07)
const CABLES: Array[Color] = [
	Color(0.12, 0.12, 0.13),
	Color(0.2, 0.55, 0.3),
	Color(0.75, 0.62, 0.15),
	Color(0.2, 0.3, 0.6),
	Color(0.72, 0.13, 0.1),
	Color(0.62, 0.64, 0.66),
]
## A patch cable's red, and how thick it is.
const PATCH := Color(0.78, 0.12, 0.1)
const PATCH_THICK := 0.036
## How tall the lit strip along a rack's top is, and how much of its width.
const CAP := 0.08
const CAP_SHARE := 0.16

## The racks' winking material for the room's green, made once.
static var _leds: ShaderMaterial


## The material of a rack's lit faces in [param room]'s green.
static func leds(room: RoomLook) -> ShaderMaterial:
	if _leds == null:
		_leds = ShaderMaterial.new()
		_leds.shader = LEDS
		_leds.set_shader_parameter(&"body", RACK)
	_leds.set_shader_parameter(&"light", room.trim)
	return _leds


## A monitor's scrolling screen, starting its scroll at [param offset].
static func screen(room: RoomLook, offset: float) -> ShaderMaterial:
	var lit := ShaderMaterial.new()
	lit.shader = MONITOR
	lit.set_shader_parameter(&"ink", room.trim)
	lit.set_shader_parameter(&"offset", offset)
	return lit


## A wall as a rack of [param size]: its body, lights winking down its faces, and a strip of the
## room's green capping it, all inside the box the collider is.
static func rack(into: Node3D, size: Vector3, surfaces: Surfaces, room: RoomLook) -> void:
	var body := Vector3(size.x, size.y - CAP, size.z)
	_box(into, body, leds(room), Vector3(0.0, -CAP * 0.5, 0.0))
	var long_x := size.x >= size.z
	var strip := (
		Vector3(size.x - 0.06, CAP, size.z * CAP_SHARE)
		if long_x
		else Vector3(size.x * CAP_SHARE, CAP, size.z - 0.06)
	)
	_box(
		into,
		Vector3(size.x, CAP * 0.5, size.z),
		surfaces.painted(RACK),
		_y(size.y * 0.5 - CAP * 0.75)
	)
	_box(into, strip, surfaces.neon(room.trim, 0.25), _y(size.y * 0.5 - CAP * 0.5))


## A breakable box as a stack of drives, each with its light on the front.
static func drives(into: Node3D, size: Vector3, surfaces: Surfaces, room: RoomLook) -> void:
	var count := 4
	var tall := size.y / float(count)
	var metal := surfaces.metal(DRIVE)
	var light := surfaces.neon(room.trim, 0.6)
	for i: int in count:
		var y := -size.y * 0.5 + tall * (float(i) + 0.5)
		_box(into, Vector3(size.x * 0.92, tall * 0.86, size.z * 0.92), metal, _y(y))
		for face: float in [-1.0, 1.0]:
			_box(
				into,
				Vector3(0.06, 0.04, 0.02),
				light,
				Vector3(size.x * 0.32, y, face * size.z * 0.47)
			)


## A pit as floor tiles lifted out of the raised floor: no spikes, the cables that run under the
## floor at the bottom of it, in bundles, and one of its tiles stood on edge against one of its
## sides. Each pit's own from [param rng]: how many cables to a bundle, their colors and
## thicknesses, the slant each bundle runs at and which side the tile leans on.
static func lifted_tiles(
	into: Node3D, size: Vector2, surfaces: Surfaces, rng: RandomNumberGenerator
) -> void:
	var bottom := -Arena.PIT_DEPTH
	var bundles := maxi(int(size.x / 0.5), 2)
	for i: int in bundles:
		var x := (
			(float(i) - float(bundles - 1) * 0.5) * size.x / float(bundles)
			+ rng.randf_range(-0.08, 0.08)
		)
		var lean := rng.randf_range(-0.2, 0.2)
		var count := rng.randi_range(2, 4)
		for j: int in count:
			var cable := CylinderMesh.new()
			var thick := rng.randf_range(0.045, 0.08)
			cable.top_radius = thick
			cable.bottom_radius = thick
			cable.height = size.y * 0.96
			cable.radial_segments = 8
			cable.rings = 1
			var run := MeshInstance3D.new()
			run.mesh = cable
			run.material_override = surfaces.painted(CABLES[rng.randi() % CABLES.size()])
			run.rotation = Vector3(PI * 0.5, lean, 0.0)
			run.position = Vector3(
				x + (float(j) - float(count - 1) * 0.5) * 0.14,
				bottom + 0.06 + rng.randf_range(0.0, 0.12),
				0.0
			)
			into.add_child(run)
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	var tile := _box(
		into,
		Vector3(minf(size.x, 1.2) * 0.9, 0.06, minf(size.y, 1.2) * 0.9),
		surfaces.painted(Color(0.3, 0.32, 0.32)),
		Vector3(rng.randf_range(-0.25, 0.25) * size.x, bottom * 0.5, side * (size.y * 0.5 - 0.1))
	)
	tile.rotation.x = 1.2 * side


## The Junction as a processor seen from above: the green of its board, a square of gold pins
## round the edge and the die in the middle. The ring that blinks is every room's, [RoomKit]'s.
static func processor(into: Node3D, radius: float, surfaces: Surfaces) -> void:
	var lift := 0.04
	var side := radius * 1.25
	_box(into, Vector3(side, 0.02, side), surfaces.marking(PCB), _y(lift))
	var gold := surfaces.metal(PIN)
	var pins := 12
	var edge := side * 0.42
	for i: int in pins:
		var along := (float(i) - float(pins - 1) * 0.5) * (side * 0.8) / float(pins)
		for toward: float in [-1.0, 1.0]:
			_box(
				into, Vector3(0.05, 0.012, 0.16), gold, Vector3(along, lift + 0.016, toward * edge)
			)
			_box(
				into, Vector3(0.16, 0.012, 0.05), gold, Vector3(toward * edge, lift + 0.016, along)
			)
	_box(into, Vector3(side * 0.5, 0.03, side * 0.5), surfaces.painted(DIE), _y(lift + 0.025))
	_box(into, Vector3(side * 0.2, 0.032, side * 0.2), gold, _y(lift + 0.03))


## A Jackpot's tile as a bank of memory: modules standing in a row across it, a chip or two on
## each, in the room's green at the edge.
static func memory(into: Node3D, size: Vector2, surfaces: Surfaces, room: RoomLook) -> void:
	var count := maxi(int(size.x / 0.42), 3)
	var board := surfaces.marking(PCB)
	var chip := surfaces.painted(DIE)
	var edge := surfaces.neon(room.trim, 0.4)
	for i: int in count:
		var x := (float(i) - float(count - 1) * 0.5) * size.x / float(count)
		_box(into, Vector3(0.06, 0.12, size.y * 0.78), board, Vector3(x, 0.14, 0.0))
		_box(into, Vector3(0.07, 0.05, size.y * 0.2), chip, Vector3(x, 0.15, -size.y * 0.18))
		_box(into, Vector3(0.07, 0.05, size.y * 0.2), chip, Vector3(x, 0.15, size.y * 0.18))
		_box(into, Vector3(0.065, 0.02, size.y * 0.78), edge, Vector3(x, 0.21, 0.0))


## A turbo pad's cell as a cooling vent: slats across its lit plate, the light coming up between.
static func vent(into: Node3D, at: Vector3, cell: float, surfaces: Surfaces) -> void:
	var slats := 5
	var metal := surfaces.metal(Color(0.32, 0.34, 0.36))
	for i: int in slats:
		var z := (float(i) - float(slats - 1) * 0.5) * cell * 0.7 / float(slats)
		_box(into, Vector3(cell * 0.78, 0.03, 0.05), metal, at + Vector3(0.0, 0.09, z))


## A red patch cable looped over a rack of [param size]: off its top edge, hanging down the face
## toward one side in a sag, and back up onto the top a little further along, where [param rng]
## says.
static func patch_cable(
	into: Node3D, size: Vector3, surfaces: Surfaces, rng: RandomNumberGenerator
) -> void:
	var long_x := size.x >= size.z
	var length := maxf(size.x, size.z)
	var depth := minf(size.x, size.z)
	var span := rng.randf_range(0.7, 1.3)
	var from := rng.randf_range(-length * 0.45, length * 0.45 - span)
	var sag := rng.randf_range(0.35, 0.6) * size.y
	var out := (1.0 if rng.randf() < 0.5 else -1.0) * (depth * 0.5 + PATCH_THICK)
	var points: Array[Vector3] = []
	for i: int in 11:
		var t := float(i) / 10.0
		var along := from + span * t
		var y := size.y * 0.5 - sag * sin(PI * t)
		points.append(Vector3(along, y, out) if long_x else Vector3(out, y, along))
	_tube(into, points, PATCH_THICK, surfaces.painted(PATCH))


## A cable left on the floor along the foot of a rack of [param size]: out of the rack low down,
## looping out across the floor and back in a little further along, in one of the room's cable
## colors, where [param rng] says. Lying flat, nothing a kart feels.
static func floor_cable(
	into: Node3D, size: Vector3, surfaces: Surfaces, rng: RandomNumberGenerator
) -> void:
	var long_x := size.x >= size.z
	var length := maxf(size.x, size.z)
	var depth := minf(size.x, size.z)
	var span := rng.randf_range(1.2, 2.2)
	var from := rng.randf_range(-length * 0.45, length * 0.45 - span)
	var reach := rng.randf_range(0.35, 0.7)
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	var thick := PATCH_THICK * 1.3
	var lying := -size.y * 0.5 + thick
	var wave := rng.randf_range(0.0, TAU)
	var points: Array[Vector3] = []
	for i: int in 15:
		var t := float(i) / 14.0
		var along := from + span * t
		# Out from the rack's foot and back, a little wandering, as a cable dropped there lies.
		var out := depth * 0.5 + thick + reach * sin(PI * t) + 0.06 * sin(wave + t * 9.0)
		var y := lying + (0.12 if i == 0 or i == 14 else 0.0)
		points.append(Vector3(along, y, out * side) if long_x else Vector3(out * side, y, along))
	var ink := CABLES[rng.randi_range(1, CABLES.size() - 1)]
	_tube(into, points, thick, surfaces.painted(ink))


## A tube through [param points], [param radius] thick: a short cylinder along each stretch.
static func _tube(into: Node3D, points: Array[Vector3], radius: float, skin: Material) -> void:
	for i: int in points.size() - 1:
		var from := points[i]
		var to := points[i + 1]
		var along := to - from
		if along.length() < 0.001:
			continue
		var piece := CylinderMesh.new()
		piece.top_radius = radius
		piece.bottom_radius = radius
		piece.height = along.length() + radius
		piece.radial_segments = 6
		piece.rings = 1
		var node := MeshInstance3D.new()
		node.mesh = piece
		node.material_override = skin
		var up := along.normalized()
		var helper := Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
		var across := up.cross(helper).normalized()
		node.transform = Transform3D(Basis(across, up, across.cross(up)), (from + to) * 0.5)
		into.add_child(node)


static func _y(lift: float) -> Vector3:
	return Vector3(0.0, lift, 0.0)


static func _box(into: Node3D, size: Vector3, skin: Material, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)
	return node
