class_name Dyno
extends Node3D
## The Garage's rolling road, GAME.md 9.4: a bay against the right wall with a cradle of steel
## rollers set in its floor. A kart driven onto them nose first toward the wall is held there, its
## wheels turning the rollers rather than the kart going anywhere, and whatever speed its motor
## reaches with the throttle held, nitro and jokers and all, is the dyno's, for the test bench's
## dial to show, see [TestBench]. Backing off the rollers lets it go, and it is not taken onto them
## again until it has left the bay.
##
## The kart drives as it always does and is put back on the rollers after it has moved, each
## physics tick, so its motor keeps the speed it would have had on the open floor: the dyno reads
## that rather than working one out of its own.

## Given as a kart is taken onto the rollers, and as it is let go with the best it reached.
signal held_kart(slot: PlayerSlot)
signal let_go(slot: PlayerSlot, best: float)

## How many cells of the room the bay takes, along the wall's normal and along the wall.
const CELLS := Vector2i(3, 2)
## Which way a kart on the rollers faces: into the wall the bay is against.
const FACING := Vector3.RIGHT
## How far from the bay's open end a kart is held, in cells: over the rollers, its nose short of
## the wall.
const HOLD := 1.6
## How square to the wall a kart has to come in to be taken onto the rollers, in radians either
## way, and how fast it may be going, in meters a second: driven on, not flung on.
const SQUARE := 0.9
## Backing off at more than this, in meters a second, lets the kart go.
const BACKING := 0.3
## The cradle: two rollers side by side under the kart's back wheels, how thick and how long, and
## how far apart; the bars on each that show it turning.
const ROLLER := 0.2
const ROLLER_LONG := 1.9
const ROLLERS_APART := 0.48
const ROLLER_BARS := 6
## How far behind the kart's middle its back wheels stand, where the cradle is.
const REAR := 0.32
const STEEL := Color(0.42, 0.44, 0.48)
const DARK_STEEL := Color(0.16, 0.17, 0.19)
const PLATE := Color(0.27, 0.28, 0.31)
const WORDS := "DYNO"
const WORDS_TALL := 0.26
const WORDS_SIZE := 96

var match_node: Match
## The bay on the floor, in world X and Z.
var area: Rect2
## The kart on the rollers, its slot, and how fast its motor is turning them, in meters a second.
var held: Kart
var held_slot: PlayerSlot
var speed := 0.0
## The best any kart reached on the rollers this visit, and whose.
var best := 0.0
var best_slot: PlayerSlot

var _hold := Vector3.ZERO
## The karts let go that have not yet left the bay, by slot.
var _leaving: Dictionary[int, bool] = {}
var _rollers: Array[Node3D] = []
## How far round the rollers have turned, in radians.
var _turned := 0.0


## The rolling road in [param in_match]'s room, the bay's corner cell nearest the room's middle
## and its back [param corner].
static func add_to(in_match: Match, corner: Vector2i) -> Dyno:
	var dyno := Dyno.new()
	dyno.name = "Dyno"
	dyno.match_node = in_match
	in_match.arena.add_child(dyno)
	dyno._build(corner)
	return dyno


func _ready() -> void:
	# After the karts have moved, so a kart on the rollers is put back where it is held.
	process_physics_priority = 10


func _build(corner: Vector2i) -> void:
	var arena := match_node.arena
	var grid := arena.grid
	var cell := grid.cell_size
	var near := grid.cell_center(corner)
	var far := grid.cell_center(corner + CELLS - Vector2i.ONE)
	var middle := (near + far) * 0.5
	var long := cell * CELLS.x
	var wide := cell * CELLS.y
	area = Rect2(middle.x - long * 0.5, middle.z - wide * 0.5, long, wide)
	_hold = Vector3(area.position.x + cell * HOLD, 0.0, middle.z)
	var plate := _box(Vector3(long, 0.02, wide), arena.surfaces.marking(PLATE))
	plate.position = Vector3(middle.x, 0.006, middle.z)
	var lines := arena.surfaces.marking(KartLift.LINE_INK)
	for side: float in [-1.0, 1.0]:
		var line := _box(Vector3(long, 0.02, KartLift.LINE), lines)
		line.position = Vector3(middle.x, 0.012, middle.z + side * wide * 0.5)
		add_child(line)
	var cradle := _hold.x - REAR
	var pit := _box(Vector3(ROLLERS_APART + ROLLER * 2.6, 0.02, ROLLER_LONG + 0.1), null)
	pit.material_override = arena.surfaces.marking(DARK_STEEL)
	pit.position = Vector3(cradle, 0.014, middle.z)
	add_child(pit)
	for side: float in [-1.0, 1.0]:
		_rollers.append(_roller(Vector3(cradle + side * ROLLERS_APART * 0.5, 0.0, middle.z)))
	_words(Vector3(area.position.x + cell * 0.45, 0.03, middle.z))
	add_child(plate)


## A roller lying across the bay, sunk to its axle with its top showing, and the bars along it
## that show it going round.
func _roller(at: Vector3) -> Node3D:
	var arena := match_node.arena
	var axle := Node3D.new()
	axle.position = at
	add_child(axle)
	var drum := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = ROLLER
	mesh.bottom_radius = ROLLER
	mesh.height = ROLLER_LONG
	mesh.radial_segments = 16
	mesh.rings = 1
	drum.mesh = mesh
	drum.material_override = arena.surfaces.metal(STEEL)
	drum.rotation.x = PI * 0.5
	axle.add_child(drum)
	var bars := arena.surfaces.metal(DARK_STEEL)
	for i: int in ROLLER_BARS:
		var turn := TAU * float(i) / ROLLER_BARS
		var bar := _box(Vector3(0.05, 0.03, ROLLER_LONG * 0.98), bars)
		bar.position = Vector3(sin(turn), cos(turn), 0.0) * ROLLER
		bar.rotation.z = -turn
		axle.add_child(bar)
	return axle


func _words(at: Vector3) -> void:
	var label := Label3D.new()
	label.name = "Painted"
	label.text = WORDS
	label.font = Type.mark_font()
	label.font_size = WORDS_SIZE
	label.outline_size = 0
	label.pixel_size = WORDS_TALL / (WORDS_SIZE * Type.CAP_HEIGHT)
	label.modulate = Color(KartLift.LINE_INK, 0.9)
	# Read from the camera's side of it, as the lift's are.
	label.rotation.x = -PI * 0.5
	label.position = at
	add_child(label)


func _physics_process(delta: float) -> void:
	if held != null:
		_keep(delta)
	else:
		speed = move_toward(speed, 0.0, delta * 12.0)
		_take()
	for slot: int in _leaving.keys():
		var kart := match_node.kart_of(slot)
		if kart == null or not holds(kart):
			_leaving.erase(slot)
	_turned = fmod(_turned + speed / ROLLER * delta, TAU)
	for roller: Node3D in _rollers:
		roller.rotation.z = -_turned


## Puts the kart on the rollers back where it is held and reads its motor, or lets it go once it
## backs off them or is gone.
func _keep(_delta: float) -> void:
	if not is_instance_valid(held) or not held.alive or held.motor.forward_speed < -BACKING:
		_release()
		return
	held.global_position = Vector3(_hold.x, held.global_position.y, _hold.z)
	var heading := atan2(-FACING.x, -FACING.z)
	held.motor.heading = heading
	held.rotation = Vector3(0.0, heading, 0.0)
	held.motor.velocity = FACING * held.motor.forward_speed
	speed = maxf(held.motor.forward_speed, 0.0)
	if speed > best:
		best = speed
		best_slot = held_slot


## Takes onto the rollers the first kart driven into the bay nose first toward the wall.
func _take() -> void:
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if kart == null or not kart.alive or slot.is_dummy() or _leaving.has(slot.index):
			continue
		if not holds(kart) or kart.motor.forward_speed <= 0.0:
			continue
		if absf(angle_difference(kart.motor.heading, atan2(-FACING.x, -FACING.z))) > SQUARE:
			continue
		held = kart
		held_slot = slot
		held_kart.emit(slot)
		return


func _release() -> void:
	var slot := held_slot
	if slot != null:
		_leaving[slot.index] = true
	held = null
	held_slot = null
	if slot != null:
		let_go.emit(slot, best)


## Whether [param kart] is in the bay, where its wheels stand.
func holds(kart: Kart) -> bool:
	return kart != null and area.has_point(Vector2(kart.global_position.x, kart.global_position.z))


static func _box(size: Vector3, skin: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var made := MeshInstance3D.new()
	made.mesh = mesh
	made.material_override = skin
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return made
