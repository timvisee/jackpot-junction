class_name Magnet
extends StaticBody3D
## A big magnet, GAME.md 6.2: an `M` on a map, a horseshoe magnet off Kit's bench standing on the
## table, solid as a bumper, that switches on now and then and pulls every kart within
## [constant REACH] in toward it, the harder the nearer, see [FloorCarry]. Off for [constant OFF]
## seconds from the flag, then on for [constant ON], and round again, on the match's clock, see
## [method LiveCabinet.clock], so every machine has it on together with nothing on the wire. Its
## tips glow while it is on, and rings of the pull close in on it across the floor; for a moment
## before it comes on its tips warm up.

## How far it pulls, in meters from its middle, and how hard at its foot and at that edge, in meters
## a second; how near a kart may come before it pulls no more, being against it.
const REACH := 7.0
const PULL := 4.2
const TOUCH := 1.1
## Its cycle, in seconds: off, then on; and how long before it comes on its tips warm up.
const OFF := 8.0
const ON := 4.0
const WARM := 1.0
## Its collider and its look.
const RADIUS := 0.55
const HEIGHT := 1.2
const RED := Color("#C8362E")
const STEEL := Color("#C9CDD4")
const GLOW := Color("#9FD8FF")
## The rings closing in while it is on: how many at once and how long one takes to close in.
const RINGS := 3
const RING_TIME := 0.9

var _match: Match
var _played := 0.0
## What the tests put its clock on by, see [method run_to].
var _shift := 0.0
var _tips: StandardMaterial3D
var _rings: Array[MeshInstance3D] = []
var _ring_glow: StandardMaterial3D


## A magnet for every `M` of [param arena]'s grid.
static func add_to(arena: Arena) -> void:
	var grid := arena.grid
	if grid.magnets.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "Magnets"
	arena.add_child(holder)
	for i: int in grid.magnets.size():
		var magnet := Magnet.new()
		magnet.name = "Magnet%d" % i
		magnet.position = grid.cell_center(grid.magnets[i])
		# Its open end toward the middle of the room, the way it pulls from.
		var toward := -magnet.position
		toward.y = 0.0
		if toward.length() > 0.1:
			magnet.rotation.y = atan2(toward.x, toward.z)
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = RADIUS
		cylinder.height = HEIGHT
		shape.shape = cylinder
		shape.position = Vector3.UP * HEIGHT * 0.5
		magnet.add_child(shape)
		magnet._dress(arena.surfaces, arena.bake_scenery)
		holder.add_child(magnet)


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	add_to_group(FloorCarry.GROUP)
	var node := get_parent()
	while node != null and not node is Match:
		node = node.get_parent()
	_match = node as Match


## Whether it is pulling just now.
func on() -> bool:
	return fmod(_played + _shift, OFF + ON) >= OFF


## How far into its warming up it is, 0 to 1, or 1 while it is on.
func warmth() -> float:
	var at := fmod(_played + _shift, OFF + ON)
	if at >= OFF:
		return 1.0
	return clampf((at - (OFF - WARM)) / WARM, 0.0, 1.0)


## Runs its clock to [param seconds] of play, for the tests.
func run_to(seconds: float) -> void:
	_shift = seconds - _played


## How fast it pulls [param kart] in, see [FloorCarry]: toward it while it is on and the kart is
## within reach, harder the nearer, and not at all against it or for a kart of another match.
func carry_at(kart: Kart) -> Vector3:
	if not on() or (_match != null and not _match.is_ancestor_of(kart)):
		return Vector3.ZERO
	var toward := global_position - kart.global_position
	toward.y = 0.0
	var far := toward.length()
	if far >= REACH or far <= TOUCH:
		return Vector3.ZERO
	return toward / far * PULL * (1.0 - far / REACH)


func _physics_process(delta: float) -> void:
	_played = LiveCabinet.clock(_match, _played, delta)


func _process(_delta: float) -> void:
	if _tips == null:
		return
	_tips.emission_energy_multiplier = 0.2 + 2.6 * warmth()
	var pulling := on()
	for i: int in _rings.size():
		var ring := _rings[i]
		ring.visible = pulling
		if not pulling:
			continue
		var t := fmod(_played / RING_TIME + float(i) / float(_rings.size()), 1.0)
		var radius := lerpf(REACH, TOUCH, t)
		ring.scale = Vector3(radius, 1.0, radius)
		ring.transparency = 1.0 - sin(t * PI) * 0.8


## The horseshoe: two red legs and a red bend over them, the steel tips at the legs' feet lit while
## it is on, and the rings it pulls with.
func _dress(surfaces: Surfaces, bake: bool) -> void:
	var look := Node3D.new()
	look.name = "Look"
	add_child(look)
	var red := surfaces.sheet(RED)
	var legs := 0.36
	for side: float in [-1.0, 1.0]:
		ToyParts.box(look, Vector3(0.26, 0.5, 0.26), red, Vector3(side * legs, 0.55, -0.05))
	var bend := 7
	for i: int in bend:
		var turn := PI * float(i) / float(bend - 1)
		var at := Vector3(-cos(turn) * legs, 0.8 + sin(turn) * legs, -0.05)
		var piece := ToyParts.box(look, Vector3(0.26, 0.2, 0.26), red, at)
		piece.rotation.z = -turn + PI * 0.5
	_tips = surfaces.neon(GLOW, 0.2).duplicate() as StandardMaterial3D
	for side: float in [-1.0, 1.0]:
		ToyParts.box(
			look, Vector3(0.28, 0.3, 0.28), surfaces.metal(STEEL), Vector3(side * legs, 0.15, -0.05)
		)
		var tip := ToyParts.box(
			look, Vector3(0.29, 0.06, 0.29), _tips, Vector3(side * legs, 0.3, -0.05)
		)
		tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if bake:
		Bake.merge(look)
	_ring_glow = SpawnRing.glow(GLOW, 0.5)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.97
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 3
	for i: int in RINGS:
		var ring := MeshInstance3D.new()
		ring.name = "Ring%d" % i
		ring.mesh = torus
		ring.material_override = _ring_glow
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.position = Vector3.UP * 0.03
		ring.visible = false
		add_child(ring)
		_rings.append(ring)
