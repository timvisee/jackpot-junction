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
## So it is a small sign standing on top of the back wall, on short legs, leaning back so the face
## turns up toward a camera looking down at it. On the wall rather than on the floor, since the
## floor is the karts', and rather than behind it, where it had to compete with the benches and
## chests the garage keeps along its walls. Up there nothing can drive into it, so it is scenery,
## like every other sign in the game.

## The panel, how far its bottom edge sits above whatever it stands on, and how far back it leans.
## The lean is what makes it readable: a board stood upright is seen edge-on by a camera pitched
## down at it, and its words come out squashed flat.
const FACE := Vector2(4.2, 1.5)
const LIFT := 0.22
const TILT := 30.0
## The two lines it says, as heights asked for in meters: the count, which is the news, and what
## is being counted under it. One long line across a letterbox was all width and no height.
const COUNT_SIZE := 0.78
const WORDS_SIZE := 0.34
const COUNT_AT := 0.2
const WORDS_AT := -0.43
## The frame round the face, how thick the panel is, and the legs and foot holding it up.
const FRAME := 0.09
const DEPTH := 0.08
const LEG := 0.12
const FOOT := Vector3(3.0, 0.1, 0.6)
## Text is drawn at this size and scaled down to meters, and kept this far clear of the frame.
const FONT_SIZE := 64
const MARGIN := 0.24
const STEEL := Color(0.17, 0.17, 0.2)
const PANEL := Color(0.07, 0.07, 0.09)
const INK := Color(0.26, 0.86, 0.42)

## The middle of the face, leaning with it: the words hang off this rather than off the stand, so
## they do not have to know about the lean or the legs.
var face: Node3D
## The room it is standing in, which is what says how hard its face is lit.
var room: RoomLook

var _count: Label3D
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


## What the sign says: the count on top and what it counts under it. Each line is refitted when it
## changes, since a longer one has to come down to stay inside the frame.
func say(count: String, words: String) -> void:
	_count.text = count
	_count.pixel_size = _fitted(count, COUNT_SIZE) / float(FONT_SIZE)
	_words.text = words
	_words.pixel_size = _fitted(words, WORDS_SIZE) / float(FONT_SIZE)


## How far the top of the face stands above whatever the sign is standing on.
static func height() -> float:
	return LIFT + FACE.y * 0.5 * (1.0 + cos(deg_to_rad(TILT)))


func _build() -> void:
	var middle := LIFT + FACE.y * 0.5
	_box(FOOT, Vector3(0.0, FOOT.y * 0.5, 0.0), STEEL)
	# The legs stand just behind the panel and meet it at its middle, where the lean puts the back
	# of the panel. Level with it, a leg's top pokes out through the front of a leaning face.
	var behind := -(DEPTH + LEG) * 0.5 - 0.01
	for side: float in [-1.0, 1.0]:
		var along := side * (FACE.x * 0.5 - 0.5)
		_box(Vector3(LEG, middle, LEG), Vector3(along, middle * 0.5, behind), STEEL)
	face = Node3D.new()
	face.name = "Face"
	face.position = Vector3(0.0, middle, 0.0)
	# Back, away from the way it faces. The other way tips the face down at the floor, away from
	# a camera looking down at it, and that is what squashed the lettering flat.
	face.rotation.x = -deg_to_rad(TILT)
	add_child(face)
	face.add_child(_slab(Vector3(FACE.x, FACE.y, DEPTH), PANEL))
	_frame()
	_count = _line(COUNT_AT)
	_words = _line(WORDS_AT)
	say("", "")


## One line of lettering across the face, lit the way signs are, GAME.md 8.1.
func _line(at: float) -> Label3D:
	var label := Label3D.new()
	label.font_size = FONT_SIZE
	label.modulate = INK * (0.85 + 0.35 * room.neon)
	label.outline_size = 10
	label.outline_modulate = Color(0.03, 0.03, 0.04, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.double_sided = false
	label.position = Vector3(0.0, at, DEPTH * 0.5 + 0.03)
	face.add_child(label)
	return label


## The steel round the face: two rails and two posts, so the panel is held rather than floating.
func _frame() -> void:
	var out := DEPTH * 0.5 + FRAME * 0.25
	for side: float in [-1.0, 1.0]:
		_on_face(
			Vector3(FACE.x + FRAME * 2.0, FRAME, FRAME),
			Vector3(0.0, side * (FACE.y + FRAME) * 0.5, out)
		)
		_on_face(Vector3(FRAME, FACE.y, FRAME), Vector3(side * (FACE.x + FRAME) * 0.5, 0.0, out))


## A box on the stand itself, for the parts that stand on the wall.
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
func _fitted(text: String, size: float) -> float:
	var span := (
		ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	)
	if span <= 0.0:
		return size
	return minf(size, (FACE.x - MARGIN * 2.0) * FONT_SIZE / span)
