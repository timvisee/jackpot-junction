class_name CountKit
extends RefCounted
## The Count Room's furniture, STORY.md 3.9 and GAME.md 8.1, for [RoomKit] to build where another
## room builds its own: walls as server racks with their capping strip lit, the breakable boxes as
## stacks of drives, the Junction as a processor seen from above, the pits as floor tiles lifted
## out with cable at the bottom, the Jackpot tiles as memory banks and the turbo pads as cooling
## vents. Looks only: every one of them plays as it does in any room. Everything is square to the
## grid and nothing is a degree off, since nobody has ever been in here to knock anything.

const LEDS: Shader = preload("res://scenes/story/count_leds.gdshader")
const MONITOR: Shader = preload("res://scenes/story/count_monitor.gdshader")
const RACK := Color(0.17, 0.19, 0.19)
const DRIVE := Color(0.36, 0.38, 0.41)
const PCB := Color(0.05, 0.2, 0.1)
const PIN := Color(0.86, 0.68, 0.3)
const DIE := Color(0.06, 0.06, 0.07)
const CABLES: Array[Color] = [
	Color(0.12, 0.12, 0.13), Color(0.2, 0.55, 0.3), Color(0.75, 0.62, 0.15), Color(0.2, 0.3, 0.6)
]
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
## floor at the bottom of it, in bundles, and one of its tiles stood on edge against its side.
static func lifted_tiles(into: Node3D, size: Vector2, surfaces: Surfaces) -> void:
	var bottom := -Arena.PIT_DEPTH
	var bundles := maxi(int(size.x / 0.5), 2)
	for i: int in bundles:
		var x := (float(i) - float(bundles - 1) * 0.5) * size.x / float(bundles)
		for j: int in 3:
			var cable := CylinderMesh.new()
			cable.top_radius = 0.07
			cable.bottom_radius = 0.07
			cable.height = size.y * 0.96
			cable.radial_segments = 8
			cable.rings = 1
			var run := MeshInstance3D.new()
			run.mesh = cable
			run.material_override = surfaces.painted(CABLES[(i + j) % CABLES.size()])
			run.rotation.x = PI * 0.5
			run.position = Vector3(
				x + (float(j) - 1.0) * 0.15, bottom + 0.08 + float(j % 2) * 0.1, 0.0
			)
			into.add_child(run)
	var tile := _box(
		into,
		Vector3(minf(size.x, 1.2) * 0.9, 0.06, minf(size.y, 1.2) * 0.9),
		surfaces.painted(Color(0.3, 0.32, 0.32)),
		Vector3(0.0, bottom * 0.5, -size.y * 0.5 + 0.1)
	)
	tile.rotation.x = -1.2


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
