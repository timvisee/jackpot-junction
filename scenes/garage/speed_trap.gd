class_name SpeedTrap
extends Node3D
## The speed trap across the Garage's front straight, GAME.md 9.4: a checkered timing strip painted
## across the lane between two timing posts with a beam between their lamps. A kart driven over the
## strip either way has its speed taken there, shown over the strip as it goes through and kept on
## the test bench as the last and the best, see [TestBench], and the posts' lamps flash.
##
## Scenery that watches: the posts are thin and stand clear of the lane, nothing stops a kart.

## Given for each kart timed through the trap, with its speed in meters a second.
signal timed(slot: PlayerSlot, speed: float)

## How far either way of the lane's middle the posts stand, in cells, and how wide the strip is
## along the lane, in meters.
const REACH := 1.6
const STRIP := 0.5
## The strip's checks: how many across the lane and how many along it.
const CHECKS := Vector2i(12, 2)
const WHITE := Color(0.92, 0.91, 0.86)
const BLACK := Color(0.08, 0.08, 0.09)
## The posts: how tall and how thick, the lamp on each, and the beam between them at a kart's
## height.
const POST := Vector2(1.05, 0.09)
const LAMP := Vector3(0.18, 0.14, 0.14)
const BEAM_HIGH := 0.45
const BEAM := 0.025
const POST_INK := Color(0.85, 0.66, 0.16)
const LAMP_INK := Color(1.0, 0.25, 0.2)
## How long the lamps flash for a kart through, and how bright.
const FLASH := 0.6
const FLASH_GLOW := 3.0
## The speed said over the strip: how big and in what.
const SAID := Color(1.0, 0.86, 0.35)
const SAID_SIZE := 44
## Slower than this through the strip, in meters a second, is not worth timing.
const SLOWEST := 2.0

var match_node: Match
## The last speed taken and the best this visit, in meters a second, and whose the best is.
var last := 0.0
var best := 0.0
var best_slot: PlayerSlot

## The line across the lane, in world X, and the lane's middle and reach in Z.
var _line := 0.0
var _middle := 0.0
var _reach := 0.0
## Where each kart was last tick, by slot, to see it cross the line.
var _was: Dictionary[int, float] = {}
var _lamps: StandardMaterial3D
var _flash := 0.0


## The trap across [param in_match]'s lane at [param cell], the strip down the middle of that
## cell across the lane.
static func add_to(in_match: Match, cell: Vector2i) -> SpeedTrap:
	var trap := SpeedTrap.new()
	trap.name = "SpeedTrap"
	trap.match_node = in_match
	in_match.arena.add_child(trap)
	trap._build(cell)
	return trap


func _build(cell: Vector2i) -> void:
	var arena := match_node.arena
	var at := arena.grid.cell_center(cell)
	_line = at.x
	_middle = at.z
	_reach = arena.grid.cell_size * REACH
	var white := arena.surfaces.marking(WHITE)
	var black := arena.surfaces.marking(BLACK)
	var check := Vector2(STRIP / CHECKS.y, _reach * 2.0 / CHECKS.x)
	for i: int in CHECKS.x:
		for j: int in CHECKS.y:
			var square := _box(
				Vector3(check.x, 0.02, check.y), white if (i + j) % 2 == 0 else black
			)
			var x := _line - STRIP * 0.5 + check.x * (j + 0.5)
			var z := _middle - _reach + check.y * (i + 0.5)
			square.position = Vector3(x, 0.008, z)
			add_child(square)
	var post_skin := arena.surfaces.painted(POST_INK)
	_lamps = arena.surfaces.neon(LAMP_INK, 0.0).duplicate()
	for side: float in [-1.0, 1.0]:
		var z := _middle + side * _reach
		var post := _box(Vector3(POST.y, POST.x, POST.y), post_skin)
		post.position = Vector3(_line, POST.x * 0.5, z)
		add_child(post)
		var lamp := _box(LAMP, _lamps)
		lamp.position = Vector3(_line, BEAM_HIGH, z - side * (POST.y + LAMP.z) * 0.5)
		add_child(lamp)
	var beam := _box(Vector3(BEAM, BEAM, _reach * 2.0 - LAMP.z * 2.0), _lamps)
	beam.position = Vector3(_line, BEAM_HIGH, _middle)
	add_child(beam)
	if arena.bake_scenery:
		# The strip never changes: one mesh for each of its two inks.
		var strip := Node3D.new()
		add_child(strip)
		for child: Node in get_children():
			if child is MeshInstance3D and child.position.y < 0.05:
				child.reparent(strip)
		Bake.merge(strip)


func _physics_process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	var glow := FLASH_GLOW * _flash / FLASH
	_lamps.emission_energy_multiplier = 0.4 + glow
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if kart == null or not kart.alive or slot.is_dummy():
			_was.erase(slot.index)
			continue
		var x := kart.global_position.x
		var inside := absf(kart.global_position.z - _middle) <= _reach
		if inside and _was.has(slot.index) and signf(_was[slot.index] - _line) != signf(x - _line):
			_time(slot, kart)
		_was[slot.index] = x


func _time(slot: PlayerSlot, kart: Kart) -> void:
	var speed := kart.motor.speed()
	if speed < SLOWEST:
		return
	last = speed
	if speed > best:
		best = speed
		best_slot = slot
	_flash = FLASH
	var shown := TestBench.speed_text(speed)
	FloatingText.spawn(match_node, Vector3(_line, 0.4, _middle), shown, SAID, SAID_SIZE, 1.1)
	timed.emit(slot, speed)


static func _box(size: Vector3, skin: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var made := MeshInstance3D.new()
	made.mesh = mesh
	made.material_override = skin
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return made
