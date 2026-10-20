class_name Tripwire
extends Node3D
## A laser tripwire, GAME.md 6.2: a run of `L` on a map is a red beam across a lane of the vault
## After Hours, between two emitters, on for [constant ON] seconds and off for [constant OFF], and
## flickering for a moment before it comes on. A kart through it while it is on sets the alarm off,
## and the House puts a bounty on it there and then if none is up, see [method Bounty.call_on]: the
## room's way of making a thief of you. When it is on is the match's clock's, see
## [method LiveCabinet.clock], so every machine shows it together; who set it off is the host's to
## say, and the bounty is in the snapshot like any other.

## Its cycle, in seconds: off, then on; and how long it flickers before it comes on.
const OFF := 3.5
const ON := 3.0
const WARN := 0.7
## How near the beam a kart's middle must be to be through it, in meters.
const CATCH := 0.45
## Its look: how high the beam runs, how thick it is, and its colors.
const HIGH := 0.42
const THICK := 0.05
const RED := Color("#FF2A3A")
const CASING := Color("#2B2D33")

var _match: Match
var _played := 0.0
var _shift := 0.0
## The beam's ends, in its own space, along x or z.
var _half := 1.0
var _along_x := true
var _beam: MeshInstance3D
var _beam_glow: StandardMaterial3D
var _tripped := -1


## A tripwire for every run of `L` of [param arena]'s grid.
static func add_to(arena: Arena) -> void:
	var grid := arena.grid
	if grid.lasers.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "Tripwires"
	arena.add_child(holder)
	for i: int in grid.lasers.size():
		var rect := grid.lasers[i]
		var wire := Tripwire.new()
		wire.name = "Tripwire%d" % i
		wire.position = grid.rect_center(rect)
		var size := grid.rect_size(rect)
		wire._along_x = size.x > size.y
		wire._half = (size.x if wire._along_x else size.y) * 0.5
		wire._dress(arena.surfaces)
		holder.add_child(wire)


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


## Whether the beam is on just now.
func on() -> bool:
	return fmod(_now(), OFF + ON) >= OFF


## Whether [param kart]'s middle is through the beam.
func crossing(kart: Kart) -> bool:
	var local := to_local(kart.global_position)
	var along := local.x if _along_x else local.z
	var across := local.z if _along_x else local.x
	return absf(along) <= _half and absf(across) <= CATCH


func _physics_process(delta: float) -> void:
	_played = LiveCabinet.clock(_match, _played, delta)
	if _match == null or _match.puppet or not on():
		return
	var shift := floori(_now() / (OFF + ON))
	if shift == _tripped:
		return
	for node: Node in FrameGroups.of(get_tree(), &"karts"):
		var kart := node as Kart if is_instance_valid(node) else null
		if kart == null or not _match.is_ancestor_of(kart) or not kart.alive or kart.is_decoy():
			continue
		if crossing(kart):
			_tripped = shift
			Bounty.call_on(_match, kart)
			return


func _process(_delta: float) -> void:
	if _beam == null:
		return
	var at := fmod(_now(), OFF + ON)
	var steady := Game.settings != null and Game.settings.flash_reduction
	var warning := at >= OFF - WARN and at < OFF
	_beam.visible = at >= OFF or (warning and (steady or fmod(at * 12.0, 1.0) < 0.5))
	_beam_glow.albedo_color.a = 0.9 if at >= OFF else 0.35


## Two emitters at the beam's ends, and the beam between them, in the spawn flare's glowing look so
## it compiles nothing of its own.
func _dress(surfaces: Surfaces) -> void:
	var casing := surfaces.sheet(CASING)
	var lens := surfaces.neon(RED, 1.2)
	var way := Vector3.RIGHT if _along_x else Vector3.BACK
	for side: float in [-1.0, 1.0]:
		var end := way * side * (_half - 0.12)
		ToyParts.box(self, Vector3(0.22, 0.6, 0.22), casing, end + Vector3.UP * 0.3)
		ToyParts.box(
			self, Vector3(0.1, 0.1, 0.1), lens, end - way * side * 0.11 + Vector3.UP * HIGH
		)
	_beam_glow = SpawnRing.glow(RED, 0.9)
	_beam = MeshInstance3D.new()
	_beam.name = "Beam"
	var bar := BoxMesh.new()
	var length := _half * 2.0 - 0.24
	bar.size = Vector3(length, THICK, THICK) if _along_x else Vector3(THICK, THICK, length)
	_beam.mesh = bar
	_beam.material_override = _beam_glow
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam.position = Vector3.UP * HIGH
	_beam.visible = false
	add_child(_beam)
