class_name Showroom
extends Node3D
## The Showroom, GAME.md 8.9: a bay off the Garage of 9.4, behind a roller door in its back wall
## that stays shut until the Department's keystone is won, see [method Loyalty.showroom_open]. Shut,
## the Garage is as it always was, with the door down across the middle of its back wall, MEMBERS
## ONLY. Open, the Garage is laid out with the bay behind it, see [constant LAYOUT], the door rolled
## up into its housing over the way in, and in the middle of the bay a turntable under its own
## lamp: a kart of this machine's driven onto it and left to stand is turned slowly round, and a
## close look at it is put up beside it, see [ShowroomView], for seeing it from all round, its
## plate and its dress, up close, as the arena's camera never does. The stalls are the Garage's
## own, along its front wall, as the lobby has.

## The Garage with the bay behind it, and the rows and the opening it adds to the Garage's grid.
const LAYOUT: ArenaLayout = preload("res://data/maps/garage_showroom.tres")
const BAY := 6
const OPENING := Vector2i(14, 20)
## The turntable: how far round, how fast it turns, and how slowly a kart must be going on it to
## be turned; the door's height and its corrugations.
const TURNTABLE := 2.4
const TURN := 0.55
const SLOW := 2.0
const DOOR_TALL := 1.9
const CARPET := Color(0.5, 0.08, 0.1)
const DOOR_STEEL := Color(0.58, 0.6, 0.62)
const HOUSING := Color(0.3, 0.31, 0.34)
## How wide the frame round the door is.
const FRAME := 0.16
const PLATE := Color(0.08, 0.08, 0.1)
const WORDS := "SHOWROOM"
const UNDER := "MEMBERS ONLY  ·  DEPT. OF KARTS"

var match_node: Match
var open := false
## The turntable's disc while the bay is open, and the kart on it now.
var turntable: Node3D
var on_it: Kart
var view: ShowroomView

var _disc: Node3D


## The Showroom in [param garage], open or shut as [param is_open] says.
static func add_to(garage: Match, is_open: bool) -> Showroom:
	var showroom := Showroom.new()
	showroom.name = "Showroom"
	showroom.match_node = garage
	showroom.open = is_open
	garage.arena.add_child(showroom)
	return showroom


func _ready() -> void:
	var grid := match_node.arena.grid
	# Where the opening is: its middle on the wall the door stands in, the Garage's back wall shut
	# or the partition of the bay open.
	var row := BAY if open else 0
	var left := grid.cell_center(Vector2i(OPENING.x, row))
	var right := grid.cell_center(Vector2i(OPENING.y - 1, row))
	var middle := (left + right) * 0.5
	var wide := right.x - left.x + grid.cell_size
	if open:
		_housing(middle, wide, grid.cell_size)
		var stand := grid.cell_center(Vector2i(OPENING.x + 2, BAY / 2 - 1))
		stand.x = middle.x
		_turntable(stand)
		_carpet(middle, stand, grid.cell_size)
	else:
		_door(middle + Vector3(0.0, 0.0, grid.cell_size * 0.5), wide)


## The table turned a physics step's worth, and the kart standing on it carried round with it, on
## the steps the karts move on, so the two go round together however the frames come.
func _physics_process(delta: float) -> void:
	if not open or _disc == null:
		return
	var turn := TURN * delta
	_disc.rotation.y += turn
	var standing: Kart = null
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if not slot.is_local_human() or kart == null or not kart.alive:
			continue
		var apart := kart.global_position - turntable.global_position
		if Vector2(apart.x, apart.z).length() <= TURNTABLE and kart.velocity.length() <= SLOW:
			standing = kart
			carry(kart, turn)
			break
	if standing != on_it:
		on_it = standing
		_show(standing)


## [param kart] carried round with the table by [param turn] radians, as anything standing on a
## turning disc is: round the disc's middle, wherever on it the kart stands, and turned as far, so
## it keeps its place on the disc rather than spinning where it stands while the disc goes round
## under it. Its heading is the one its motor sets it to every step.
func carry(kart: Kart, turn: float) -> void:
	var apart := kart.global_position - turntable.global_position
	apart.y = 0.0
	kart.global_position += apart.rotated(Vector3.UP, turn) - apart
	kart.motor.heading = wrapf(kart.motor.heading + turn, -PI, PI)
	kart.rotation.y = kart.motor.heading


## The close look at the kart on the turntable put up, or taken down with none.
func _show(kart: Kart) -> void:
	if view != null and is_instance_valid(view):
		view.queue_free()
		view = null
	if kart == null:
		return
	view = ShowroomView.of(kart, turntable)
	add_child(view)


## The roller door down across the opening, corrugated steel with a hazard band along its foot,
## in a frame of steel, a post either side and a lintel over it, and the sign over that.
func _door(at: Vector3, wide: float) -> void:
	var door := _box(Vector3(wide, DOOR_TALL, 0.12), DOOR_STEEL)
	door.position = at + Vector3(0.0, DOOR_TALL * 0.5, 0.0)
	add_child(door)
	for side: float in [-1.0, 1.0]:
		var post := _box(Vector3(FRAME, DOOR_TALL + FRAME, 0.26), HOUSING)
		post.position = at + Vector3(side * (wide + FRAME) * 0.5, (DOOR_TALL + FRAME) * 0.5, 0.03)
		add_child(post)
	var lintel := _box(Vector3(wide + FRAME * 2.0, FRAME, 0.26), HOUSING)
	lintel.position = at + Vector3(0.0, DOOR_TALL + FRAME * 0.5, 0.03)
	add_child(lintel)
	# Its corrugations, on the door alone: none above its top.
	var groove_at := 0.28
	while groove_at < DOOR_TALL - 0.1:
		var groove := _box(Vector3(wide, 0.05, 0.03), DOOR_STEEL.darkened(0.25))
		groove.position = at + Vector3(0.0, groove_at, 0.07)
		add_child(groove)
		groove_at += 0.27
	var band := _box(Vector3(wide, 0.16, 0.03), HouseTheme.FOIL)
	band.position = at + Vector3(0.0, 0.1, 0.08)
	add_child(band)
	_sign(at + Vector3(0.0, DOOR_TALL + 0.45, 0.1), wide)


## The door rolled up into its housing over the opening, and the sign over that.
func _housing(at: Vector3, wide: float, cell: float) -> void:
	var housing := _box(Vector3(wide + 0.3, 0.5, 0.5), HOUSING)
	housing.position = at + Vector3(0.0, DOOR_TALL + 0.25, cell * 0.5)
	add_child(housing)
	for side: float in [-1.0, 1.0]:
		var post := _box(Vector3(0.18, DOOR_TALL, 0.18), HOUSING)
		post.position = at + Vector3(side * (wide * 0.5 + 0.09), DOOR_TALL * 0.5, cell * 0.5)
		add_child(post)
	_sign(at + Vector3(0.0, DOOR_TALL + 0.95, cell * 0.5 + 0.26), wide)


func _sign(at: Vector3, wide: float) -> void:
	var board := _box(Vector3(wide * 0.8, 0.62, 0.06), PLATE)
	board.position = at
	add_child(board)
	var words := Label3D.new()
	words.text = WORDS
	words.font_size = 72
	words.pixel_size = 0.006
	words.modulate = HouseTheme.FOIL
	words.position = at + Vector3(0.0, 0.08, 0.04)
	add_child(words)
	var under := Label3D.new()
	under.text = UNDER
	under.font_size = 28
	under.pixel_size = 0.006
	under.modulate = Color(0.85, 0.85, 0.88)
	under.position = at + Vector3(0.0, -0.18, 0.04)
	add_child(under)


## A red carpet from the way in at [param from] to the turntable at [param to], the way a car is
## shown off.
func _carpet(from: Vector3, to: Vector3, cell: float) -> void:
	var long := absf(from.z - to.z) + cell * 0.5
	var carpet := _box(Vector3(TURNTABLE * 1.1, 0.01, long), CARPET)
	carpet.position = Vector3(to.x, 0.006, (from.z + to.z) * 0.5 + cell * 0.25)
	add_child(carpet)
	for side: float in [-1.0, 1.0]:
		var edge := _box(Vector3(0.06, 0.012, long), HouseTheme.FOIL)
		edge.position = carpet.position + Vector3(side * TURNTABLE * 0.55, 0.0, 0.0)
		add_child(edge)


## The turntable at [param at]: a dark disc a little off the floor with a gold rim and stripes to
## show it turning, under a lamp of its own.
func _turntable(at: Vector3) -> void:
	turntable = Node3D.new()
	turntable.name = "Turntable"
	turntable.position = at
	add_child(turntable)
	_disc = Node3D.new()
	turntable.add_child(_disc)
	var disc := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = TURNTABLE
	cylinder.bottom_radius = TURNTABLE
	cylinder.height = 0.06
	disc.mesh = cylinder
	disc.material_override = _paint(Color(0.14, 0.14, 0.17))
	disc.position.y = 0.03
	_disc.add_child(disc)
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = TURNTABLE - 0.12
	torus.outer_radius = TURNTABLE
	rim.mesh = torus
	rim.material_override = _paint(HouseTheme.FOIL)
	rim.scale = Vector3(1.0, 0.4, 1.0)
	rim.position.y = 0.06
	_disc.add_child(rim)
	for i: int in 3:
		var stripe := _box(Vector3(TURNTABLE * 1.9, 0.01, 0.08), Color(0.3, 0.3, 0.34))
		stripe.position.y = 0.065
		stripe.rotation.y = PI * i / 3.0
		_disc.add_child(stripe)
	var lamp := SpotLight3D.new()
	lamp.position = Vector3(0.0, 6.0, 0.0)
	lamp.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	lamp.spot_range = 9.0
	lamp.spot_angle = 30.0
	lamp.light_energy = 3.0
	lamp.light_color = Color(1.0, 0.94, 0.82)
	turntable.add_child(lamp)


static func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _paint(color)
	return mesh


static func _paint(color: Color) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	paint.roughness = 0.5
	paint.metallic = 0.3
	return paint
