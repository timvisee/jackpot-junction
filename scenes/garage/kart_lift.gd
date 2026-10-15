class_name KartLift
extends Node3D
## The lift in the Garage, GAME.md 9.4 and 4.4: a bay on the open floor along the front wall,
## marked out in the room's yellow between the two red posts of a two-post lift, its arms folded
## in along the floor, YOUR KART and STOP HERE painted on its floor as a parking bay's words are.
## A player here who stops their kart in it has the kart dialog put up for their seat, see
## [KartDialog]: the Garage's way to the dress, where the lobby has its stalls. Only once a stop:
## the kart has to leave the bay before stopping in it puts the dialog up again.

## A player here has stopped [param slot]'s kart in the bay.
signal stopped(slot: PlayerSlot)

## How many cells of the room the bay takes, across and deep.
const CELLS := Vector2i(4, 2)
## How slow a kart has to be going to have stopped, and for how long.
const SLOW := 1.5
const HOLD := 0.5
## The posts: how tall and how thick, and how far outside the bay they stand.
const POST := Vector3(0.3, 1.8, 0.3)
const POST_OUT := 0.35
## How wide the painted lines round the bay are.
const LINE := 0.08
const POST_INK := Color("#b82e29")
const ARM_INK := Color("#5b5f66")
const LINE_INK := Color("#dbad33")
## The words painted in the bay, how tall their capitals are for its depth, and how much of its
## width they may take.
const WORDS := "YOUR KART"
const UNDER := "STOP HERE"
const WORDS_TALL := 0.24
const UNDER_TALL := 0.12
const WORDS_WIDE := 0.8
const PAINT_SIZE := 96

var match_node: Match
## The bay on the floor, across and deep, as the floor's x and z.
var area := Rect2()
## How long each slot's kart has been stopped in the bay, and those that have had the dialog for
## this stop, by the slot's index.
var _held: Dictionary[int, float] = {}
var _done: Dictionary[int, bool] = {}
var _lines: StandardMaterial3D
var _painted: Array[Label3D] = []


## The lift in [param in_match]'s room, the bay's top left cell [param corner].
static func add_to(in_match: Match, corner: Vector2i) -> KartLift:
	var lift := KartLift.new()
	lift.name = "KartLift"
	lift.match_node = in_match
	in_match.arena.add_child(lift)
	lift._build(corner)
	return lift


func _build(corner: Vector2i) -> void:
	var grid := match_node.arena.grid
	var near := grid.cell_center(corner)
	var far := grid.cell_center(corner + CELLS - Vector2i.ONE)
	var middle := (near + far) * 0.5
	var across := grid.cell_size * CELLS.x
	var deep := grid.cell_size * CELLS.y
	area = Rect2(middle.x - across * 0.5, middle.z - deep * 0.5, across, deep)
	_lines = StandardMaterial3D.new()
	_lines.albedo_color = LINE_INK
	_lines.emission_enabled = true
	_lines.emission = LINE_INK
	_lines.emission_energy_multiplier = 0.0
	for side: Array in [
		[Vector3(0.0, 0.0, -deep * 0.5), Vector3(across, 0.02, LINE)],
		[Vector3(0.0, 0.0, deep * 0.5), Vector3(across, 0.02, LINE)],
		[Vector3(-across * 0.5, 0.0, 0.0), Vector3(LINE, 0.02, deep)],
		[Vector3(across * 0.5, 0.0, 0.0), Vector3(LINE, 0.02, deep)],
	]:
		var line := _box(side[1], _lines)
		line.position = Vector3(middle.x, 0.012, middle.z) + side[0]
		add_child(line)
	var posts := StaticBody3D.new()
	posts.name = "Posts"
	posts.collision_layer = Layers.WORLD
	posts.collision_mask = 0
	add_child(posts)
	var red := _flat(POST_INK)
	var steel := _flat(ARM_INK)
	for x: float in [-1.0, 1.0]:
		var at := Vector3(middle.x + x * (across * 0.5 + POST_OUT), POST.y * 0.5, middle.z)
		var post := _box(POST, red)
		post.position = at
		add_child(post)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = POST
		shape.shape = box
		shape.position = at
		posts.add_child(shape)
		# Its two arms, folded in along the floor toward the middle of the bay.
		for z: float in [-1.0, 1.0]:
			var arm := _box(Vector3(across * 0.32, 0.08, 0.14), steel)
			arm.position = Vector3(at.x - x * across * 0.17, 0.05, middle.z + z * deep * 0.22)
			arm.rotation.y = z * x * 0.18
			add_child(arm)
	# Its words painted on its floor, read from the camera's side of it, the name over what to do.
	_paint(WORDS, Vector3(middle.x, 0.03, middle.z - deep * 0.02), deep * WORDS_TALL, across)
	_paint(UNDER, Vector3(middle.x, 0.03, middle.z + deep * 0.3), deep * UNDER_TALL, across)


## [param words] painted flat on the floor of the bay at [param at] in its lines' yellow, their
## capitals [param tall] high and no wider than the share of [param across] it allows.
func _paint(words: String, at: Vector3, tall: float, across: float) -> void:
	var label := Label3D.new()
	label.name = "Painted"
	label.text = words
	label.font = Type.mark_font()
	label.font_size = PAINT_SIZE
	label.outline_size = 0
	var wide := label.font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, PAINT_SIZE).x
	label.pixel_size = minf(
		tall / (PAINT_SIZE * Type.CAP_HEIGHT), across * WORDS_WIDE / maxf(wide, 1.0)
	)
	label.modulate = Color(LINE_INK, 0.9)
	label.rotation.x = -PI * 0.5
	label.position = at
	add_child(label)
	_painted.append(label)


static func _box(size: Vector3, skin: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var made := MeshInstance3D.new()
	made.mesh = mesh
	made.material_override = skin
	return made


static func _flat(ink: Color) -> StandardMaterial3D:
	var skin := StandardMaterial3D.new()
	skin.albedo_color = ink
	skin.roughness = 0.6
	return skin


## Whether [param kart] is in the bay, where its wheels stand.
func holds(kart: Kart) -> bool:
	return kart != null and area.has_point(Vector2(kart.global_position.x, kart.global_position.z))


func _physics_process(delta: float) -> void:
	var lit := Color.TRANSPARENT
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		var inside := kart != null and kart.alive and slot.is_local_human() and holds(kart)
		if not inside:
			_held.erase(slot.index)
			_done.erase(slot.index)
			continue
		lit = slot.color()
		if _done.has(slot.index):
			continue
		var going := Vector2(kart.velocity.x, kart.velocity.z).length()
		_held[slot.index] = 0.0 if going > SLOW else _held.get(slot.index, 0.0) + delta
		if _held[slot.index] >= HOLD:
			_done[slot.index] = true
			stopped.emit(slot)
	# The bay's lines and its words lit in the color of whoever is in it.
	_lines.emission = lit if lit.a > 0.0 else LINE_INK
	_lines.emission_energy_multiplier = 0.9 if lit.a > 0.0 else 0.0
	for label: Label3D in _painted:
		label.modulate = Color(lit, 0.95) if lit.a > 0.0 else Color(LINE_INK, 0.9)
