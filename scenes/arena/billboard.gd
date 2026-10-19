class_name Billboard
extends Node3D
## A hoarding standing over the crowd, GAME.md 8.1: the kind of board a real arena sells to
## whoever will pay for it. Two of them carry the house's own advertising and a third carries
## the clock, see [LedClock].
##
## Scenery, like the crowd and the tanks: no collision, nothing decided here. The board is built
## facing +Z, and [method add_to] turns it to look at the middle of the table.

## What a board is held up by, GAME.md 8.1. A hall puts its signs up the way the hall is built:
## the workshop bolts them to scaffolding, the card room hangs them, the yard braces them against
## the wind. Every board in a room uses the same one, the clock included.
enum Mount { POSTS, SCAFFOLD, HANGING, BRACED }

## The face, and how far above the table its bottom edge sits: over the heads of a crowd four
## rows deep and up a tier, so a board is read rather than glimpsed between shoulders.
const WIDTH := 5.6
const HEIGHT := 2.25
const LIFT := 1.9
## The legs it stands on and the frame around the face.
const POST := 0.18
const FRAME := 0.15
const DEPTH := 0.15
const STEEL := Color(0.17, 0.17, 0.2)
const FACE := Color(0.07, 0.07, 0.09)
## Text is drawn at this size and scaled down to meters, and kept this far clear of the frame.
const FONT_SIZE := 64
const MARGIN := 0.35

## What the boards say: a headline, the line under it, and the color both are in. Two are
## drawn at random as the room goes up, GAME.md 8.1, so a run of matches is not the same two
## posters over and over. Written the way the hoardings in a real hall are: a trade nobody in
## the room needs, sold in a voice nobody in the room believes.
const ADS: Array[Array] = [
	["JACKPOT", "JUNCTION", Palette.CHIP_GOLD],
	["NITRO", "DRINK IT FAST", Palette.NEON_CYAN],
	["ALL IN", "INSURANCE SOLD SEPARATELY", Palette.NEON_MAGENTA],
	["SNAKE EYES", "BRAKE PADS THAT BITE", Palette.CHIP_GOLD],
	["FULL HOUSE", "ENGINE OIL BY THE BARREL", Palette.NEON_CYAN],
	["ROYAL FLUSH", "PLUMBING, DAY OR NIGHT", Palette.NEON_MAGENTA],
	["PIT STOP", "OPEN ALL NIGHT", Palette.CHIP_GOLD],
	["DOUBLE DOWN", "TWICE THE TIRE", Palette.NEON_CYAN],
	["LUCKY SEVEN", "SPARK PLUGS AND SIDE BETS", Palette.CHIP_GOLD],
	["HIGH ROLLER", "SUSPENSION KITS", Palette.NEON_MAGENTA],
	["CASH OUT", "WHILE YOU STILL CAN", Palette.CHIP_GOLD],
	["ONE MORE LAP", "WHAT COULD GO WRONG", Palette.NEON_CYAN],
	["BET THE FARM", "TRACTOR SOLD SEPARATELY", Palette.NEON_MAGENTA],
	["DRIFT SCHOOL", "SIDEWAYS SINCE 1972", Palette.NEON_CYAN],
	["JOKERS WILD", "DEALT NIGHTLY", Palette.NEON_MAGENTA],
	["HOUSE ODDS", "GENEROUS AS EVER", Palette.CHIP_GOLD],
]

## The middle of the face, in board space: x to the right of it, y up, and +z out of it. Ads and
## the clock hang off this rather than off the board, so neither has to know about the legs.
var face: Node3D
## The room the board is standing in, GAME.md 8.1. A hall that turns its lights down does not
## turn its signs off, so how hard this one is lit comes from the room rather than from here.
var room: RoomLook
## What holds it up, which the room decides, see [method mount_for].
var mount := Mount.POSTS

## The legs, the tower or the rods, whichever the room asked for: baked into one mesh, since none
## of it moves and all of it is the same steel.
var _mount: Node3D
var _paints: Dictionary[String, StandardMaterial3D] = {}


## How a room holds its signs up.
static func mount_for(in_room: RoomLook) -> Mount:
	if in_room == null:
		return Mount.POSTS
	match in_room.id:
		&"after_hours":
			return Mount.HANGING
		&"the_yard":
			return Mount.BRACED
		_:
			return Mount.SCAFFOLD


## Stands a board at [param at] with its face turned toward [param toward], and returns it.
static func add_to(
	parent: Node3D, at: Vector3, toward: Vector3, in_room: RoomLook = null
) -> Billboard:
	var board := Billboard.new()
	board.name = "Billboard"
	board.room = in_room if in_room != null else RoomLook.fallback()
	board.mount = mount_for(board.room)
	parent.add_child(board)
	board.global_position = at
	var away := Vector3(toward.x - at.x, 0.0, toward.z - at.z)
	if away.length() > 0.01:
		board.rotation.y = atan2(away.x, away.z)
	board._build()
	return board


## The patch of table the board stands on, square with the table, for the crowd to keep clear of
## it: the face's width and a meter and a half either side of it, turned the way the board is. A
## patch laid along the table whichever way the board faced kept the crowd off the wrong ground
## under a board turned to face the table, and its legs stood in people.
func footprint() -> Rect2:
	var across := global_basis.x * (WIDTH * 0.5)
	var out := global_basis.z * 1.6
	var at := Vector2(global_position.x, global_position.z)
	var box := Rect2(at, Vector2.ZERO)
	for corner: Vector3 in [across + out, across - out, out - across, -across - out]:
		box = box.expand(at + Vector2(corner.x, corner.z))
	return box


## A panel of color across the face, for an ad to be built out of. [param at] and [param size]
## are in meters from the middle of the face.
func panel(at: Vector2, size: Vector2, color: Color, lit := false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, size.y, 0.04)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _paint(color, lit)
	node.position = Vector3(at.x, at.y, 0.03)
	face.add_child(node)
	return node


## Words across the face, lying flat on it rather than turning to the camera: a board is part of
## the room, and a sign that swings round to face you is a label. [param size] is the height the
## line asks for; a long one is brought down from it so every ad fits its board rather than only
## the ones that were written short.
func words(text: String, at: Vector2, size: float, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = FONT_SIZE
	label.pixel_size = fitted(text, size) / float(FONT_SIZE)
	# Signs are lit, GAME.md 8.1: in a dark room the words carry their own light, and in a
	# bright one this is the color it was asked for.
	label.modulate = color * (0.85 + 0.35 * room.neon)
	label.outline_size = 10
	label.outline_modulate = Color(0.03, 0.03, 0.04, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.double_sided = false
	label.position = Vector3(at.x, at.y, 0.06)
	face.add_child(label)
	return label


## The height a line can be drawn at and still fit between the frames, measured off the font
## rather than guessed at from how many letters there are. Public because a board that changes
## what it says, such as the clock in [LedClock], has to ask again for the new words.
func fitted(text: String, size: float) -> float:
	var span := (
		ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	)
	if span <= 0.0:
		return size
	return minf(size, (WIDTH - MARGIN * 2.0) * FONT_SIZE / span)


func _build() -> void:
	var stand := LIFT + HEIGHT * 0.5
	_mount = Node3D.new()
	_mount.name = "Mount"
	add_child(_mount)
	match mount:
		Mount.SCAFFOLD:
			_scaffold(stand)
		Mount.HANGING:
			_hanging(stand)
		Mount.BRACED:
			_braced(stand)
		_:
			_posts(stand)
	var frame := _box(Vector3(WIDTH + FRAME * 2.0, HEIGHT + FRAME * 2.0, DEPTH), STEEL)
	frame.position = Vector3(0.0, stand, 0.0)
	_mount.add_child(frame)
	# What holds a board up never moves and is all one color, so it is one mesh, GAME.md 8.1.
	# A tower of scaffold is fifteen boxes otherwise, and every board in the room has one.
	Bake.merge(_mount)
	face = Node3D.new()
	face.name = "Face"
	face.position = Vector3(0.0, stand, DEPTH * 0.5)
	add_child(face)
	var board := _box(Vector3(WIDTH, HEIGHT, 0.02), FACE)
	board.position = Vector3(0.0, 0.0, 0.01)
	face.add_child(board)


## A pair of legs, which is what a board stands on where nothing else is going on.
func _posts(stand: float) -> void:
	for side: float in [-1.0, 1.0]:
		var leg := _box(Vector3(POST, LIFT + HEIGHT * 0.5, POST), STEEL)
		leg.position = Vector3(side * (WIDTH * 0.5 - POST), stand * 0.5 - HEIGHT * 0.5, 0.0)
		_mount.add_child(leg)


## Bolted to a tower of scaffold: four uprights, lifts across them and a diagonal in each bay.
## A workshop puts a sign up out of what it has in the yard.
func _scaffold(stand: float) -> void:
	var tall := stand - HEIGHT * 0.5
	var deep := 0.7
	for side: float in [-1.0, 1.0]:
		for back: float in [-1.0, 1.0]:
			var leg := _box(Vector3(POST, tall, POST), STEEL)
			leg.position = Vector3(side * (WIDTH * 0.5 - POST), tall * 0.5, back * deep * 0.5)
			_mount.add_child(leg)
		for lift: float in [0.34, 0.72]:
			var rail := _box(Vector3(POST, POST, deep), STEEL)
			rail.position = Vector3(side * (WIDTH * 0.5 - POST), tall * lift, 0.0)
			_mount.add_child(rail)
	for lift: float in [0.34, 0.72]:
		var across := _box(Vector3(WIDTH - POST, POST, POST), STEEL)
		across.position = Vector3(0.0, tall * lift, -deep * 0.5)
		_mount.add_child(across)
	var run := WIDTH - POST * 2.0
	var rise := tall * 0.38
	var brace := _box(Vector3(sqrt(run * run + rise * rise), POST, POST), STEEL)
	brace.position = Vector3(0.0, tall * 0.53, -deep * 0.5)
	brace.rotation.z = atan2(rise, run)
	_mount.add_child(brace)


## Hung from a rod that goes up out of the light, the way a sign hangs over a bar. A card room
## has a ceiling somewhere; what it has down here is the sign and the dark above it.
func _hanging(stand: float) -> void:
	var top := stand + HEIGHT * 0.5 + FRAME
	for side: float in [-1.0, 1.0]:
		var rod := _box(Vector3(POST * 0.5, 14.0, POST * 0.5), STEEL)
		rod.position = Vector3(side * (WIDTH * 0.5 - POST * 2.0), top + 7.0, 0.0)
		_mount.add_child(rod)
		var eye := _box(Vector3(POST * 1.6, POST * 1.6, POST * 1.6), STEEL)
		eye.position = Vector3(side * (WIDTH * 0.5 - POST * 2.0), top, 0.0)
		_mount.add_child(eye)


## Two legs with a raking brace behind each and a plate under it, which is how a board stands in
## a yard with nothing to bolt to and weather coming across it.
func _braced(stand: float) -> void:
	var tall := stand - HEIGHT * 0.5
	for side: float in [-1.0, 1.0]:
		var x := side * (WIDTH * 0.5 - POST)
		var leg := _box(Vector3(POST * 1.3, tall, POST * 1.3), STEEL)
		leg.position = Vector3(x, tall * 0.5, 0.0)
		_mount.add_child(leg)
		var rake := tall * 0.8
		var brace := _box(Vector3(POST, sqrt(rake * rake + 1.6), POST), STEEL)
		brace.position = Vector3(x, rake * 0.5, -0.6)
		brace.rotation.x = atan2(1.2, rake)
		_mount.add_child(brace)
		var plate := _box(Vector3(0.9, 0.12, 1.8), STEEL)
		plate.position = Vector3(x, 0.06, -0.4)
		_mount.add_child(plate)


func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _paint(color, false)
	return node


## A coat of paint, one instance per color rather than one per box. Two boxes wearing the same
## color can be baked into one mesh, and a board's mount is fifteen of them.
func _paint(color: Color, lit: bool) -> StandardMaterial3D:
	var key := "%s%d" % [color.to_html(), 1 if lit else 0]
	if _paints.has(key):
		return _paints[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if lit:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.7 * room.neon
	_paints[key] = material
	return material
