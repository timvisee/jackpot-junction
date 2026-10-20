class_name WindUpToy
extends AnimatableBody3D
## A wind-up toy car, GAME.md 6.2: a ring of `W` on a map is the loop of floor the Playset's tin toy
## drives round, its key turning on its back, and a kart it runs into or that runs into it is
## thrown off as a pop bumper throws one, see [method KartMotor.throw_off]. Solid to shots, which
## come off it as off a wall. Where it is is the match's clock's, see [method LiveCabinet.clock], so
## every machine has it in the same place; the host throws the karts, and a client its own kart as
## it meets it, as a turbo pad shoves it, the rest in the snapshot.

## How fast it drives, in meters a second; how far round its corners turn, in meters; how near a
## kart's middle may come before it is thrown, and how long before the same kart can be thrown
## again, in seconds.
const SPEED := 2.2
const CORNER := 1.4
const REACH := 1.25
const AGAIN := 0.5
## Its look, and its collider.
const SIZE := Vector3(0.9, 0.62, 1.5)
const TIN := Color("#D2453A")
const CABIN := Color("#F2D16B")
const TIRE := Color("#26252B")
const KEY := Color("#C9A54A")
const CHROME := Color("#D5D8DE")
const GLASS := Color("#2E3B4A")

var _match: Match
var _played := 0.0
var _shift := 0.0
## Half the loop's size, x and z, between the middles of its cells, and its middle.
var _half := Vector2.ONE
var _middle := Vector3.ZERO
## How far round its loop it starts: half way for the twin on the right, so the pair keeps the
## room's point symmetry.
var _phase := 0.0
var _key: Node3D
var _thrown: Dictionary[int, float] = {}


## A toy for every ring of `W` of [param arena]'s grid.
static func add_to(arena: Arena) -> void:
	var grid := arena.grid
	if grid.toys.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "Toys"
	arena.add_child(holder)
	for i: int in grid.toys.size():
		var rect := grid.toys[i]
		var toy := WindUpToy.new()
		toy.name = "Toy%d" % i
		toy._middle = grid.rect_center(rect)
		toy._half = grid.rect_size(rect) * 0.5 - Vector2.ONE * grid.cell_size * 0.5
		toy._phase = toy.length() * 0.5 if toy._middle.x > 0.0 else 0.0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = SIZE
		shape.shape = box
		shape.position = Vector3.UP * SIZE.y * 0.5
		toy.add_child(shape)
		toy._dress(arena.surfaces)
		holder.add_child(toy)
		toy.position = toy.at(toy._phase)


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	sync_to_physics = false
	var node := get_parent()
	while node != null and not node is Match:
		node = node.get_parent()
	_match = node as Match


## Runs its clock to [param seconds] of play, for the tests.
func run_to(seconds: float) -> void:
	_shift = seconds - _played


## How long the loop is, in meters.
func length() -> float:
	var r := minf(CORNER, minf(_half.x, _half.y))
	return 4.0 * (_half.x - r) + 4.0 * (_half.y - r) + TAU * r


## Where it is [param along] meters round its loop, clockwise from above from the middle of its far
## side, in its holder's space.
func at(along: float) -> Vector3:
	var r := minf(CORNER, minf(_half.x, _half.y))
	var a := _half.x - r
	var b := _half.y - r
	var s := fposmod(along, length())
	# Straights and quarter turns in turn: along the far side toward +x, down the right toward +z,
	# back along the near side, up the left.
	var corners: Array[Vector2] = [Vector2(a, -b), Vector2(a, b), Vector2(-a, b), Vector2(-a, -b)]
	var starts: Array[Vector2] = [
		Vector2(-a, -b - r), Vector2(a + r, -b), Vector2(a, b + r), Vector2(-a - r, b)
	]
	var ways: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	for side: int in 4:
		var straight := a * 2.0 if side % 2 == 0 else b * 2.0
		if s <= straight:
			var p := starts[side] + ways[side] * s
			return _middle + Vector3(p.x, 0.0, p.y)
		s -= straight
		var turn := PI * 0.5 * r
		if s <= turn:
			var from := -PI * 0.5 + PI * 0.5 * float(side)
			var angle := from + s / r if r > 0.0 else from
			var p := corners[side] + Vector2(cos(angle), sin(angle)) * r
			return _middle + Vector3(p.x, 0.0, p.y)
		s -= turn
	return _middle + Vector3(-a, 0.0, -b - r)


func _physics_process(delta: float) -> void:
	_played = LiveCabinet.clock(_match, _played, delta)
	var along := (_played + _shift) * SPEED + _phase
	var here := at(along)
	var ahead := at(along + 0.3)
	position = here
	var way := ahead - here
	if way.length() > 0.001:
		rotation.y = atan2(way.x, way.z)
	for slot: int in _thrown.keys():
		_thrown[slot] -= delta
		if _thrown[slot] <= 0.0:
			_thrown.erase(slot)
	for node: Node in FrameGroups.of(get_tree(), &"karts"):
		var kart := node as Kart if is_instance_valid(node) else null
		if kart == null or (_match != null and not _match.is_ancestor_of(kart)):
			continue
		if kart.puppet and not kart.predicted:
			continue
		if _match != null and _match.puppet and not kart.predicted:
			continue
		var away := kart.global_position - global_position
		away.y = 0.0
		if away.length() > REACH or _thrown.has(kart.slot):
			continue
		if not kart.alive or kart.falling or kart.coasting or not kart.motor.kickable():
			continue
		_thrown[kart.slot] = AGAIN
		kart.motor.throw_off(away, way.normalized() * SPEED)
		kart.velocity = kart.motor.velocity


func _process(delta: float) -> void:
	if _key != null:
		_key.rotation.z += delta * 4.0


## The toy, a tin wind-up car in plain lacquered paint, so nothing printed slides over it as it
## drives: a rounded red body with a cream band round it, a cream cabin with dark windows, chrome
## bumpers and hubcaps, headlamps, a roundel on its hood, four black tires, and the key on its back.
## Its front is its +z, the way it drives.
func _dress(surfaces: Surfaces) -> void:
	var look := Node3D.new()
	look.name = "Look"
	add_child(look)
	var red := surfaces.sheet(TIN)
	var cream := surfaces.sheet(CABIN)
	var chrome := surfaces.sheet(CHROME)
	var glass := surfaces.sheet(GLASS)
	var tire := surfaces.sheet(TIRE)
	ToyParts.puffed(look, Vector3(SIZE.x, 0.34, SIZE.z), 0.16, red, Vector3.UP * 0.36, 10)
	ToyParts.rounded(
		look, Vector3(SIZE.x + 0.02, 0.06, SIZE.z + 0.02), 0.17, cream, Vector3.UP * 0.33, 10
	)
	ToyParts.puffed(
		look, Vector3(SIZE.x * 0.74, 0.28, SIZE.z * 0.42), 0.1, cream, Vector3(0.0, 0.66, -0.12), 10
	)
	# Windows: a windscreen, a back window and one down each side of the cabin.
	ToyParts.box(
		look, Vector3(SIZE.x * 0.6, 0.16, 0.02), glass, Vector3(0.0, 0.68, SIZE.z * 0.13 + 0.01)
	)
	ToyParts.box(
		look, Vector3(SIZE.x * 0.6, 0.16, 0.02), glass, Vector3(0.0, 0.68, -SIZE.z * 0.29 - 0.01)
	)
	for side: float in [-1.0, 1.0]:
		ToyParts.box(
			look,
			Vector3(0.02, 0.15, SIZE.z * 0.3),
			glass,
			Vector3(side * (SIZE.x * 0.37 + 0.012), 0.68, -0.12)
		)
	# The roundel on the hood, and the headlamps either side of the grille.
	ToyParts.disc(look, 0.15, cream, 0.535).position.z = SIZE.z * 0.3
	ToyParts.disc(look, 0.1, red, 0.545).position.z = SIZE.z * 0.3
	for side: float in [-1.0, 1.0]:
		ToyParts.ball(look, 0.07, chrome, Vector3(side * SIZE.x * 0.3, 0.42, SIZE.z * 0.5 - 0.01))
	for end: float in [-1.0, 1.0]:
		ToyParts.rounded(
			look,
			Vector3(SIZE.x * 0.9, 0.07, 0.08),
			0.04,
			chrome,
			Vector3(0.0, 0.22, end * (SIZE.z * 0.5 + 0.01)),
			6
		)
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			var at := Vector3(x * (SIZE.x * 0.5 - 0.02), 0.19, z * SIZE.z * 0.3)
			var wheel := ToyParts.cylinder(look, 0.19, 0.16, tire, at, 12)
			wheel.rotation.z = PI * 0.5
			var cap := ToyParts.cylinder(
				look, 0.09, 0.02, chrome, at + Vector3(x * 0.085, 0.0, 0.0), 10
			)
			cap.rotation.z = PI * 0.5
	_key = Node3D.new()
	_key.name = "Key"
	_key.position = Vector3(0.0, 0.42, -SIZE.z * 0.5 - 0.04)
	# On the toy rather than in its look, so the look bakes to a mesh a material and the key turns.
	add_child(_key)
	var brass := surfaces.sheet(KEY)
	var shaft := ToyParts.cylinder(_key, 0.03, 0.18, brass, Vector3(0.0, 0.0, -0.06), 8)
	shaft.rotation.x = PI * 0.5
	for side: float in [-1.0, 1.0]:
		var bow := ToyParts.cylinder(_key, 0.11, 0.035, brass, Vector3(side * 0.12, 0.0, -0.16), 12)
		bow.rotation.x = PI * 0.5
	Bake.merge(look)
	Bake.merge(_key)
