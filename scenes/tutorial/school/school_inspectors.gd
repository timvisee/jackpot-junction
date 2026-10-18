class_name SchoolInspectors
extends RoomBuild
## The inspectors of the driving test, GAME.md 9.4a: four people from the Department of Karts in
## gray suits and hi-vis vests, each with a clipboard, standing where a kart does not go, on the
## tops of the lot's walls. They turn to keep their eyes on the learner's kart wherever it is,
## and now and then one looks down at the clipboard and writes something, which is never good
## news and never said.
## Built the way the crowd's people are, 8.1, a body and a head, a little bigger so a vest reads
## at the distance the camera of the test keeps; scenery, colliding with nothing.

## Where they stand, by cell, and whether on a wall top or on the table outside: on the lot's
## walls, north, east, west and south, each over a lesson of its own.
const POSTS: Array[Array] = [
	[Vector2i(7, 0), true],
	[Vector2i(31, 3), true],
	[Vector2i(0, 10), true],
	[Vector2i(22, 17), true],
]
## How much bigger than one of the crowd an inspector is.
const SIZE := 1.35
## How fast one turns after the kart, the share of the way a second.
const TURN_RATE := 3.0
## How long between two notes, the shortest and the longest, and how long writing one takes.
const NOTE_EVERY := Vector2(3.5, 9.0)
const NOTE_TIME := 1.6
## How far the head bows to read the clipboard, and how fast the pen goes over it.
const BOW := 0.45
const SCRIBBLE := 22.0
const SUIT := Color(0.4, 0.41, 0.45)
const VEST := Color(0.82, 1.0, 0.12)
const STRIPE := Color(0.86, 0.87, 0.9)
const SKINS: Array[Color] = [
	Color(0.94, 0.78, 0.66), Color(0.8, 0.6, 0.46), Color(0.58, 0.4, 0.29), Color(0.38, 0.26, 0.19)
]
const HAIR: Array[Color] = [
	Color(0.15, 0.12, 0.1), Color(0.45, 0.32, 0.2), Color(0.7, 0.7, 0.72), Color(0.82, 0.68, 0.4)
]
const BOARD := Color(0.56, 0.4, 0.24)
const PAPER := Color(0.95, 0.94, 0.9)

## The kart they watch.
var watched: Kart
## Each inspector: the figure turning as a whole, its head, its pen and what it is up to.
var people: Array[Dictionary] = []


## Puts the inspectors up over [param for_arena], watching [param kart].
static func add_to(for_arena: Arena, kart: Kart) -> SchoolInspectors:
	var inspectors := SchoolInspectors.new()
	inspectors._stand_in(for_arena, "SchoolInspectors")
	inspectors.watched = kart
	inspectors._build()
	return inspectors


func _build() -> void:
	var grid := arena.grid
	for i: int in POSTS.size():
		var cell: Vector2i = POSTS[i][0]
		var on_wall: bool = POSTS[i][1]
		var foot := grid.cell_center(cell)
		foot.y = SchoolProps.WALL_TOP if on_wall else Crowd.TABLE_TOP
		people.append(_inspector(foot, i))
	_rng.seed = hash("inspectors")
	for each: Dictionary in people:
		each["next_note"] = _rng.randf_range(NOTE_EVERY.x, NOTE_EVERY.y)


## One of them, standing at [param foot]: a gray suit with a hi-vis vest over it, a head with
## hair on it, and a clipboard held in front with a pen over it.
func _inspector(foot: Vector3, index: int) -> Dictionary:
	var figure := Node3D.new()
	figure.name = "Inspector%d" % index
	figure.position = foot
	figure.scale = Vector3.ONE * SIZE
	add_child(figure)
	var body := Crowd.BODY
	var suit := CapsuleMesh.new()
	suit.radius = 0.15
	suit.height = body
	_part(figure, suit, surfaces.painted(SUIT), Vector3(0.0, body * 0.5, 0.0))
	# The vest over the chest, a little wider than the suit, with a pale band round it.
	var vest := CylinderMesh.new()
	vest.top_radius = 0.158
	vest.bottom_radius = 0.162
	vest.height = body * 0.42
	vest.radial_segments = 12
	_part(figure, vest, surfaces.neon(VEST, 0.25), Vector3(0.0, body * 0.58, 0.0))
	var stripe := CylinderMesh.new()
	stripe.top_radius = 0.164
	stripe.bottom_radius = 0.164
	stripe.height = 0.025
	stripe.radial_segments = 12
	_part(figure, stripe, surfaces.metal(STRIPE), Vector3(0.0, body * 0.5, 0.0))
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0.0, body + Crowd.HEAD * 0.15, 0.0)
	figure.add_child(head)
	# Where the crowd's heads are, bowing from the neck rather than from the middle of the head.
	var middle := Vector3(0.0, Crowd.HEAD * 0.55, 0.0)
	var face := SphereMesh.new()
	face.radius = Crowd.HEAD
	face.height = Crowd.HEAD * 2.0
	_part(head, face, surfaces.painted(SKINS[index % SKINS.size()]), middle)
	# The hair a flattened cap over the top and back of it, the forehead left bare, and tall enough
	# to stand a little proud of the crown: any flatter and the top of the head came through it.
	var hair := SphereMesh.new()
	hair.radius = Crowd.HEAD * 1.03
	hair.height = Crowd.HEAD * 2.06
	var cap := _part(
		head,
		hair,
		surfaces.painted(HAIR[index % HAIR.size()]),
		middle + Vector3(0.0, Crowd.HEAD * 0.42, -Crowd.HEAD * 0.14)
	)
	cap.scale = Vector3(1.0, 0.62, 1.0)
	# The clipboard, held at the chest and tipped up toward the face, the paper on it, the clip.
	var held := Node3D.new()
	held.name = "Clipboard"
	held.position = Vector3(0.0, body * 0.62, 0.2)
	held.rotation.x = -0.9
	figure.add_child(held)
	var board := BoxMesh.new()
	board.size = Vector3(0.2, 0.012, 0.27)
	_part(held, board, surfaces.painted(BOARD), Vector3.ZERO)
	var paper := BoxMesh.new()
	paper.size = Vector3(0.17, 0.004, 0.22)
	_part(held, paper, surfaces.painted(PAPER), Vector3(0.0, 0.008, 0.015))
	var clip := BoxMesh.new()
	clip.size = Vector3(0.08, 0.02, 0.03)
	_part(held, clip, surfaces.metal(STRIPE), Vector3(0.0, 0.012, -0.12))
	var pen := CylinderMesh.new()
	pen.top_radius = 0.006
	pen.bottom_radius = 0.006
	pen.height = 0.11
	pen.radial_segments = 6
	var nib := _part(held, pen, surfaces.painted(Color(0.12, 0.2, 0.55)), Vector3(0.04, 0.05, 0.0))
	nib.rotation.z = 0.5
	return {"figure": figure, "head": head, "pen": nib, "writing": 0.0, "next_note": 0.0}


func _part(parent: Node3D, mesh: Mesh, skin: Material, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	parent.add_child(node)
	return node


func _process(delta: float) -> void:
	var looking := is_instance_valid(watched)
	for each: Dictionary in people:
		var figure: Node3D = each["figure"]
		if looking:
			var toward := watched.global_position - figure.global_position
			if Vector2(toward.x, toward.z).length() > 0.1:
				var wanted := atan2(toward.x, toward.z)
				figure.rotation.y = lerp_angle(
					figure.rotation.y, wanted, minf(TURN_RATE * delta, 1.0)
				)
		_step_note(each, delta)


## Now and then a note: the head goes down to the clipboard and the pen runs over the paper for a
## moment, then it is back to watching.
func _step_note(each: Dictionary, delta: float) -> void:
	var writing: float = each["writing"]
	if writing > 0.0:
		writing = maxf(writing - delta, 0.0)
	else:
		each["next_note"] = float(each["next_note"]) - delta
		if float(each["next_note"]) <= 0.0:
			writing = NOTE_TIME
			each["next_note"] = _rng.randf_range(NOTE_EVERY.x, NOTE_EVERY.y)
	each["writing"] = writing
	# Bowed over the board for the whole note, easing in and out of it.
	var bowed := sin(clampf(writing / NOTE_TIME, 0.0, 1.0) * PI)
	(each["head"] as Node3D).rotation.x = BOW * minf(bowed * 2.0, 1.0)
	var pen: Node3D = each["pen"]
	var scribble := sin(writing * SCRIBBLE) * 0.035 if writing > 0.0 else 0.0
	pen.position = Vector3(0.04 + scribble, 0.05 - 0.035 * minf(bowed * 2.0, 1.0), 0.0)


## Whether [param index] is writing a note just now.
func writing(index: int) -> bool:
	return float(people[index]["writing"]) > 0.0
