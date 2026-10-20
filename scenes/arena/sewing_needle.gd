class_name SewingNeedle
extends Node3D
## A sewing machine's needle, GAME.md 6.2: a run of `N` on a map is a seam stitched across the
## Stitch's floor, and a sewing machine's head runs up and down it over the karts, its needle
## coming down every [constant STAMP] seconds. A kart under the needle as it comes down spins out,
## as on oil. Its shadow on the floor darkens and closes in as the needle comes down, so it is seen
## coming. Where the head is and when the needle comes down are the match's clock's, see
## [method LiveCabinet.clock], so every machine has it in the same place; whether it caught a kart
## is the host's to say, and the kart's spin is in the snapshot like any other.

## How fast the head runs along the seam, in meters a second; how long between stitches, how long
## the needle is down, and how near the needle a kart's middle must be to be caught, in meters.
const SPEED := 2.4
const STAMP := 1.1
const DOWN := 0.14
const CATCH := 0.75
## How high the head runs over the floor, and its look.
const HEAD_HIGH := 1.5
const CREAM := Color("#EDE3CC")
const STRIPE := Color("#B83B3B")
const STEEL := Color("#C9CDD4")
const THREAD := Color("#C23B5A")
const SHADOW := Color.BLACK

var _match: Match
var _played := 0.0
var _shift := 0.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _head: Node3D
var _needle: Node3D
var _shadow: MeshInstance3D
var _shade: StandardMaterial3D
var _stitched := -1


## A needle for every run of `N` of [param arena]'s grid.
static func add_to(arena: Arena) -> void:
	var grid := arena.grid
	if grid.seams.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "Needles"
	arena.add_child(holder)
	for i: int in grid.seams.size():
		var rect := grid.seams[i]
		var needle := SewingNeedle.new()
		needle.name = "Needle%d" % i
		var middle := grid.rect_center(rect)
		var half := grid.rect_size(rect) * 0.5
		var along := Vector3(half.x - grid.cell_size * 0.5, 0.0, 0.0)
		if rect.size.y > rect.size.x:
			along = Vector3(0.0, 0.0, half.y - grid.cell_size * 0.5)
		# The twin runs the other way, so the pair keeps the room's point symmetry.
		var flip := middle.z > 0.0 or (is_zero_approx(middle.z) and middle.x > 0.0)
		needle._from = middle + (along if flip else -along)
		needle._to = middle + (-along if flip else along)
		needle._dress(arena.surfaces, grid.rect_size(rect), middle, arena.bake_scenery)
		holder.add_child(needle)


func _ready() -> void:
	var node := get_parent()
	while node != null and not node is Match:
		node = node.get_parent()
	_match = node as Match


func _now() -> float:
	return _played + _shift


## Runs its clock to [param seconds] of play, for the tests.
func run_to(seconds: float) -> void:
	_shift = seconds - _played


## Where the needle is over the floor just now, in the arena's space.
func foot() -> Vector3:
	var length := _from.distance_to(_to)
	if length < 0.01:
		return _from
	return _from.lerp(_to, pingpong(_now() * SPEED, length) / length)


## Whether the needle is down just now.
func down() -> bool:
	return fmod(_now(), STAMP) < DOWN


func _physics_process(delta: float) -> void:
	_played = LiveCabinet.clock(_match, _played, delta)
	if _match == null or _match.puppet or not down():
		return
	var stitch := floori(_now() / STAMP)
	if stitch == _stitched:
		return
	_stitched = stitch
	var at := to_global(foot())
	for node: Node in FrameGroups.of(get_tree(), &"karts"):
		var kart := node as Kart if is_instance_valid(node) else null
		if kart == null or not _match.is_ancestor_of(kart):
			continue
		var flat := kart.global_position - at
		flat.y = 0.0
		if flat.length() <= CATCH:
			catch(kart)


## [param kart] under the needle as it came down: it spins out, as on oil, the way it is going.
func catch(kart: Kart) -> void:
	if not kart.alive or kart.falling or kart.coasting or kart.frozen or kart.motor.spinning():
		return
	kart.input.deny_claim(NetInput.CLAIM_DENIED)
	kart.motor.apply_spin_out(1.0 if kart.slot % 2 == 0 else -1.0)


func _process(_delta: float) -> void:
	if _head == null:
		return
	var at := foot()
	_head.position = at + Vector3.UP * HEAD_HIGH
	var phase := fmod(_now(), STAMP) / STAMP
	# Down at the start of each stitch, then up, coming down again over the last third.
	var drop := 0.0 if down() else clampf((phase - 0.66) / 0.34, 0.0, 1.0)
	if down():
		drop = 1.0
	_needle.position.y = lerpf(-0.25, -HEAD_HIGH + 0.45, drop)
	_shadow.position = at + Vector3.UP * 0.02
	var size := lerpf(1.3, 0.55, drop)
	_shadow.scale = Vector3(size, 1.0, size)
	_shade.albedo_color.a = lerpf(0.2, 0.8, drop)


## The seam stitched across the floor, the head over it with its stripe, the needle under it and
## the shadow on the floor.
func _dress(surfaces: Surfaces, size: Vector2, middle: Vector3, bake: bool) -> void:
	var seam := Node3D.new()
	seam.name = "Seam"
	add_child(seam)
	var thread := surfaces.sheet(THREAD)
	var along_x := size.x >= size.y
	var length := size.x if along_x else size.y
	var count := floori(length / 0.5)
	for i: int in count:
		var t := (float(i) + 0.5) / float(count) - 0.5
		var dash := Vector3(0.3, 0.012, 0.06) if along_x else Vector3(0.06, 0.012, 0.3)
		var at := (
			middle
			+ (Vector3(t * length, 0.006, 0.0) if along_x else Vector3(0.0, 0.006, t * length))
		)
		ToyParts.box(seam, dash, thread, at)
	if bake:
		Bake.merge(seam)
	_head = Node3D.new()
	_head.name = "Head"
	add_child(_head)
	var cream := surfaces.sheet(CREAM)
	ToyParts.box(_head, Vector3(0.9, 0.36, 0.5), cream, Vector3.ZERO)
	ToyParts.box(_head, Vector3(0.92, 0.08, 0.52), surfaces.sheet(STRIPE), Vector3(0.0, 0.06, 0.0))
	ToyParts.box(_head, Vector3(0.3, 0.3, 0.3), cream, Vector3(0.0, -0.3, 0.0))
	_needle = Node3D.new()
	_needle.name = "Needle"
	_head.add_child(_needle)
	ToyParts.cylinder(_needle, 0.025, 0.9, surfaces.metal(STEEL), Vector3.ZERO, 6)
	ToyParts.box(_needle, Vector3(0.36, 0.03, 0.2), surfaces.metal(STEEL), Vector3(0.0, -0.4, 0.0))
	# The shadow in a scorch's own look, so it compiles nothing of its own.
	_shadow = MeshInstance3D.new()
	_shadow.name = "Shadow"
	var quad := PlaneMesh.new()
	quad.size = Vector2.ONE * 1.3
	_shadow.mesh = quad
	_shade = StandardMaterial3D.new()
	_shade.albedo_texture = Scorch.blot()
	_shade.albedo_color = Color(SHADOW, 0.0)
	_shade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shade.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shade.emission_enabled = true
	_shade.emission = Color.BLACK
	_shade.emission_energy_multiplier = 0.5
	_shadow.material_override = _shade
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_shadow)
