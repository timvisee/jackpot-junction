class_name ReadyStand
extends Node3D
## The board in the waiting room that says how many players are ready, GAME.md 9.6.
##
## A room that has a clock hangs it on a hoarding over the crowd, and that is the right height for
## a clock: it is glanced at from anywhere on the floor while a match is being played. The ready
## count is not glanced at. It is the one thing in the room worth reading, in a room with no crowd
## to look over and a camera holding the whole floor, and a hoarding put it so far back and so far
## up that it sat outside the shot.
##
## So it is a pavement sign instead: a panel on short legs standing on the concrete at the top of
## the room, tilted back so the face turns up toward a camera looking down at it. The kind of
## board a garage stands out front, which is what the room is dressed as anyway.
##
## It is solid, like the drum and the wheels of 9.6 and unlike scenery everywhere else, because a
## kart driving through the room's own sign is worse than one bouncing off it. It stands against
## the back wall, so there is no getting stuck behind it.

## The panel, how far its bottom edge sits off the floor, and how far back it leans. The lean is
## what makes it readable: a board stood upright is seen edge-on by a camera pitched down at it.
## It is a letterbox rather than a poster, because one line across it is all it ever says: a
## taller face only gets the same line drawn the same size with empty board above and below it.
const FACE := Vector2(5.2, 0.9)
const LIFT := 0.66
const TILT := 16.0
## The frame round the face, how thick the panel is, and the legs and foot holding it up.
const FRAME := 0.09
const DEPTH := 0.08
const LEG := 0.12
const FOOT := Vector3(3.4, 0.14, 0.66)
## Text is drawn at this size and scaled down to metres, and kept this far clear of the frame.
const FONT_SIZE := 64
const MARGIN := 0.2
const STEEL := Color(0.17, 0.17, 0.2)
const PANEL := Color(0.07, 0.07, 0.09)

## The middle of the face, leaning with it: the words hang off this rather than off the stand, so
## they do not have to know about the lean or the legs.
var face: Node3D
## The room it is standing in, which is what says how hard its face is lit.
var room: RoomLook

var _words: Label3D


## Stands a sign at [param at] with its face turned toward [param toward].
static func add_to(parent: Node3D, at: Vector3, toward: Vector3, in_room: RoomLook) -> ReadyStand:
	var stand := ReadyStand.new()
	stand.name = "ReadyStand"
	stand.room = in_room if in_room != null else RoomLook.fallback()
	parent.add_child(stand)
	stand.global_position = at
	var away := Vector3(toward.x - at.x, 0.0, toward.z - at.z)
	if away.length() > 0.01:
		stand.rotation.y = atan2(away.x, away.z)
	stand._build()
	return stand


## What the sign says. Refitted each time, since the count is what changes and a longer line has
## to come down to stay inside the frame.
func say(text: String) -> void:
	_words.text = text
	_words.pixel_size = _fitted(text) / float(FONT_SIZE)


func _build() -> void:
	var middle := LIFT + FACE.y * 0.5
	_box(FOOT, Vector3(0.0, FOOT.y * 0.5, 0.0), STEEL)
	for side: float in [-1.0, 1.0]:
		var along := side * (FACE.x * 0.5 - 0.55)
		_box(Vector3(LEG, middle, LEG), Vector3(along, middle * 0.5, 0.0), STEEL)
	face = Node3D.new()
	face.name = "Face"
	face.position = Vector3(0.0, middle, 0.0)
	face.rotation.x = deg_to_rad(TILT)
	add_child(face)
	var panel := _slab(Vector3(FACE.x, FACE.y, DEPTH), PANEL)
	face.add_child(panel)
	_frame()
	_words = Label3D.new()
	_words.font_size = FONT_SIZE
	_words.modulate = Color(0.26, 0.86, 0.42) * (0.85 + 0.35 * room.neon)
	_words.outline_size = 10
	_words.outline_modulate = Color(0.03, 0.03, 0.04, 0.9)
	_words.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_words.double_sided = false
	_words.position = Vector3(0.0, 0.0, DEPTH * 0.5 + 0.03)
	face.add_child(_words)
	_stand_on_the_floor(middle)
	say("")


## What a kart hits: one upright box around the whole sign rather than a shape per part, since
## what it has to do is keep a kart off it rather than describe it.
func _stand_on_the_floor(middle: float) -> void:
	var body := StaticBody3D.new()
	body.name = "Solid"
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(FACE.x + FRAME * 2.0, middle + FACE.y * 0.5, FOOT.z)
	shape.shape = box
	shape.position = Vector3(0.0, box.size.y * 0.5, 0.0)
	body.add_child(shape)
	add_child(body)


## The steel round the face: two rails and two posts, so the panel is held rather than floating.
func _frame() -> void:
	var out := DEPTH * 0.5 + FRAME * 0.25
	for side: float in [-1.0, 1.0]:
		_on_face(
			Vector3(FACE.x + FRAME * 2.0, FRAME, FRAME),
			Vector3(0.0, side * (FACE.y + FRAME) * 0.5, out)
		)
		_on_face(Vector3(FRAME, FACE.y, FRAME), Vector3(side * (FACE.x + FRAME) * 0.5, 0.0, out))


## A box on the stand itself, for the parts that stand on the floor.
func _box(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var node := _slab(size, color)
	node.position = at
	add_child(node)
	return node


## And one on the face, which leans with it.
func _on_face(size: Vector3, at: Vector3) -> void:
	var node := _slab(size, STEEL)
	node.position = at
	face.add_child(node)


func _slab(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	node.material_override = paint
	return node


## The height a line can be drawn at and still fit between the frames, measured off the font
## rather than guessed at from how many letters there are.
func _fitted(text: String) -> float:
	var span := (
		ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	)
	if span <= 0.0:
		return FACE.y - MARGIN
	return minf(FACE.y - MARGIN, (FACE.x - MARGIN * 2.0) * FONT_SIZE / span)
