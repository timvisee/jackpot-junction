class_name TipJar
extends DressMoments
## The supporter pack's Tip jar, GAME.md 10.8: a dealer's tip jar on the helmet with TIPS on masking
## tape, filling with chips as the pot grows, a few in it even with none, full at a full pot. At a
## cash-out its chips leap out and up, tipped into the Junction, and it fills again; at a death they
## spill out over the side and fall, and it is empty until the respawn. The supporter's in-joke:
## you tipped. Its chips are one [MultiMesh], so all of them are one draw.

## How many chips it holds at most and at least, the jar's inside, where its bottom is and how high
## each chip stacks on the last.
const MOST := 36
const LEAST := 4
const INSIDE := 0.19
const BOTTOM := 0.11
const STACK := 0.0088
## A chip's colors, the table's, a few of each.
const COLORS: Array[Color] = [
	Color("#C4453C"),
	Color(0.2, 0.35, 0.75),
	Color(0.15, 0.15, 0.17),
	Color(0.25, 0.6, 0.35),
	Color("#F7F3EA"),
]
## How long its chips are in the air at a cash-out or a death, and how hard they are thrown.
const FLY := 0.7
const LEAP := 2.4
const SPILL := 1.4
const GRAVITY := 6.0

## Its chips, and how many it holds now.
var chips: MultiMeshInstance3D
var held := 0
var _flying := false
var _time := 0.0
var _velocities: Array[Vector3] = []
var _spins: Array[Vector3] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	super()
	_rng.seed = 11
	fill(wanted())


## How many chips the pot asks for.
func wanted() -> int:
	return LEAST + roundi(share() * float(MOST - LEAST))


## Holds [param count] chips, settled in the jar.
func fill(count: int) -> void:
	held = clampi(count, 0, MOST)
	_flying = false
	if chips == null:
		return
	chips.multimesh.visible_instance_count = held
	for i: int in held:
		chips.multimesh.set_instance_transform(i, resting(i))


## Where chip [param index] lies in the jar: round the middle, a little askew, each a little higher
## than the last.
static func resting(index: int) -> Transform3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31 + index
	var round_by := float(index) * 2.39996
	var out := sqrt(rng.randf()) * INSIDE
	var tilt := Basis.from_euler(
		Vector3(rng.randf_range(-0.6, 0.6), rng.randf() * TAU, rng.randf_range(-0.6, 0.6))
	)
	return Transform3D(
		tilt, Vector3(cos(round_by) * out, BOTTOM + float(index) * STACK, sin(round_by) * out)
	)


func _cashed() -> void:
	_throw(LEAP, 0.4)


func _died() -> void:
	_throw(SPILL, 1.0)


func _respawned() -> void:
	fill(wanted())


## Its chips thrown out of it, up as hard as [param hard] and out as far as [param out] of that.
func _throw(hard: float, out: float) -> void:
	if chips == null:
		return
	_flying = true
	_time = 0.0
	_velocities.clear()
	_spins.clear()
	for i: int in held:
		var way := (
			Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0)).normalized()
		)
		_velocities.append((Vector3.UP * _rng.randf_range(0.7, 1.2) + way * out) * hard)
		_spins.append(Vector3(_rng.randf_range(-12.0, 12.0), 0.0, _rng.randf_range(-12.0, 12.0)))


func tick(delta: float) -> void:
	if chips == null:
		return
	if not _flying:
		if alive and not cashing and wanted() != held:
			fill(wanted())
		return
	_time += delta
	var gone := minf(_time, FLY)
	for i: int in held:
		var lying := resting(i)
		var moved := _velocities[i] * gone + Vector3.DOWN * GRAVITY * 0.5 * gone * gone
		chips.multimesh.set_instance_transform(
			i, Transform3D(Basis.from_euler(_spins[i] * gone) * lying.basis, lying.origin + moved)
		)
	if _time >= FLY:
		_flying = false
		if alive:
			fill(LEAST)
		else:
			held = 0
			chips.multimesh.visible_instance_count = 0
