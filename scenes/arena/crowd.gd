class_name Crowd
extends Node3D
## The people who came to watch, GAME.md 8.1: a row of small figures standing on the table all
## the way round the arena, and a DJ booth along the top edge of it.
##
## They bob along while the room is quiet. Once the excitement meter of 8.4 reaches the top two
## levels they are on their feet, and a kill sets them jumping for a couple of seconds whatever
## the meter says, so the loudest thing in a match is answered by the room rather than only by
## the HUD. The booth's speakers pulse on the beat with them.
##
## Everything here is scenery: no collision, nothing to drive into, nothing that decides
## anything. A client runs its own crowd off the same events, GAME.md 10.3.

## Metres between two figures, and how far outside the wall they stand.
const SPACING := 1.9
const STANDOFF := 1.35
## The table top, which is where they stand: the felt is a slab of this thickness on top of it.
const TABLE_TOP := -Arena.FLOOR_THICKNESS
const BODY := 0.42
const HEAD := 0.17
## The excitement level at which the room is on its feet, GAME.md 8.4.
const DANCING_LEVEL := 5
## How high a jump goes, and how long a kill keeps them jumping.
const JUMP := 0.4
const CHEER := 1.8
## The colours the crowd comes in: the room's own, plus enough others to look like people.
const SHIRTS: Array[Color] = [
	Color("#E23D3D"),
	Color("#3D6FE2"),
	Color("#F2D23D"),
	Color("#43C463"),
	Color("#9B4FE2"),
	Color("#F28C3D"),
	Color("#3DD9E2"),
	Color("#F26BB8"),
	Color("#E8D8A0"),
]

## The excitement level of the match, 0 to 6. The match keeps it up to date.
var level := 0
## Scenery can be switched off: the Garage in 9.4 is not a party, GAME.md 8.1.
var enabled := true

var _figures: Array[Node3D] = []
var _phases: PackedFloat32Array = []
var _speakers: Array[Node3D] = []
## Whoever is behind the decks, who dances in the booth's own space rather than on the table.
var _dj: Node3D
var _cheer := 0.0
var _now := 0.0
var _rng := RandomNumberGenerator.new()


## Fills the table around an arena of [param size] metres with onlookers.
static func add_to(parent: Node3D, size: Vector2) -> Crowd:
	var crowd := Crowd.new()
	crowd.name = "Crowd"
	parent.add_child(crowd)
	crowd._build(size)
	return crowd


func _ready() -> void:
	Events.kart_killed.connect(_on_kart_killed)


func _exit_tree() -> void:
	if Events.kart_killed.is_connected(_on_kart_killed):
		Events.kart_killed.disconnect(_on_kart_killed)


func _process(delta: float) -> void:
	visible = enabled
	if not enabled:
		return
	_now += delta
	_cheer = maxf(_cheer - delta, 0.0)
	var dancing := level >= DANCING_LEVEL or _cheer > 0.0
	var rate := 7.0 if dancing else 1.7
	var height := JUMP if dancing else 0.045
	var sway := 0.55 if dancing else 0.12
	for i: int in _figures.size():
		var beat := _now * rate + _phases[i]
		_figures[i].position.y = TABLE_TOP + absf(sin(beat)) * height
		_figures[i].rotation.y = sin(beat * 0.5) * sway
	if _dj != null:
		_dj.position.y = absf(sin(_now * rate)) * height
		_dj.rotation.y = sin(_now * rate * 0.5) * sway
	var thump := 1.0 + (0.22 if dancing else 0.06) * (1.0 - Audio.music_beat())
	for speaker: Node3D in _speakers:
		speaker.scale = Vector3(thump, thump, thump)


## Somebody went down, GAME.md 3.6. Worth getting up for whatever the meter says.
func _on_kart_killed(_victim: int, _killer: int, _cause: StringName) -> void:
	_cheer = CHEER


func _build(size: Vector2) -> void:
	_rng.seed = hash(size)
	var half := size * 0.5 + Vector2.ONE * STANDOFF
	var across := maxi(int(size.x / SPACING), 2)
	var down := maxi(int(size.y / SPACING), 2)
	for i: int in across:
		var x := lerpf(-half.x, half.x, float(i) / float(across - 1))
		_figure(Vector3(x, 0.0, -half.y))
		_figure(Vector3(x, 0.0, half.y))
	for i: int in down:
		var z := lerpf(-half.y, half.y, float(i) / float(down - 1))
		_figure(Vector3(-half.x, 0.0, z))
		_figure(Vector3(half.x, 0.0, z))
	_booth(Vector3(0.0, TABLE_TOP, -half.y - 2.6))


## One onlooker: a body and a head, facing roughly at the arena.
func _figure(at: Vector3) -> void:
	var figure := Node3D.new()
	figure.position = Vector3(at.x, TABLE_TOP, at.z)
	var color := SHIRTS[_rng.randi_range(0, SHIRTS.size() - 1)]
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.15
	capsule.height = BODY
	body.mesh = capsule
	body.material_override = _paint(color)
	body.position = Vector3(0.0, BODY * 0.5, 0.0)
	figure.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = HEAD
	sphere.height = HEAD * 2.0
	head.mesh = sphere
	head.material_override = _paint(Palette.CHIP_WHITE.darkened(_rng.randf_range(0.0, 0.45)))
	head.position = Vector3(0.0, BODY + HEAD * 0.7, 0.0)
	figure.add_child(head)
	add_child(figure)
	_figures.append(figure)
	_phases.append(_rng.randf_range(0.0, TAU))


## The booth at the top: a desk, a pair of speakers that pulse on the beat, and somebody behind
## it who never stops dancing.
func _booth(at: Vector3) -> void:
	var booth := Node3D.new()
	booth.name = "DjBooth"
	booth.position = at
	add_child(booth)
	var desk := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(3.4, 0.9, 1.0)
	desk.mesh = box
	desk.material_override = _paint(Color(0.14, 0.14, 0.18))
	desk.position = Vector3(0.0, 0.45, 0.0)
	booth.add_child(desk)
	var deck := MeshInstance3D.new()
	var plate := BoxMesh.new()
	plate.size = Vector3(2.6, 0.08, 0.7)
	deck.mesh = plate
	deck.material_override = _paint(Palette.NEON_MAGENTA)
	deck.position = Vector3(0.0, 0.94, 0.0)
	booth.add_child(deck)
	for side: int in [-1, 1]:
		var speaker := Node3D.new()
		speaker.position = Vector3(side * 2.6, 0.0, 0.0)
		var cabinet := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(1.0, 1.7, 1.0)
		cabinet.mesh = shape
		cabinet.material_override = _paint(Color(0.1, 0.1, 0.13))
		cabinet.position = Vector3(0.0, 0.85, 0.0)
		speaker.add_child(cabinet)
		var cone := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.3
		disc.bottom_radius = 0.3
		disc.height = 0.08
		cone.mesh = disc
		cone.material_override = _glow(Palette.NEON_CYAN)
		cone.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		cone.position = Vector3(0.0, 1.0, 0.54)
		speaker.add_child(cone)
		booth.add_child(speaker)
		_speakers.append(speaker)
	var dj := Node3D.new()
	dj.position = Vector3(0.0, 0.0, -0.9)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.2
	capsule.height = 0.7
	body.mesh = capsule
	body.material_override = _paint(Palette.CHIP_GOLD)
	body.position = Vector3(0.0, 0.7, 0.0)
	dj.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	head.mesh = sphere
	head.material_override = _paint(Palette.CHIP_WHITE)
	head.position = Vector3(0.0, 1.25, 0.0)
	dj.add_child(head)
	booth.add_child(dj)
	_dj = dj


func _paint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material


func _glow(color: Color) -> StandardMaterial3D:
	var material := _paint(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.4
	return material
