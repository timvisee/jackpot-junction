class_name MultDie
extends Pickup
## A die that adds to the mult when picked up, GAME.md 3.3: a real one, white with black pips,
## one to six with each two opposite faces adding up to seven.
##
## Its faces are one small picture drawn once and shared by every die, laid out the way a box mesh
## lays its six faces over a texture, three across and two down, see [constant FACES]. A die is
## the cube and nothing else: a pip each as a mesh of its own was twenty-one more things to draw
## for every die on the floor.

const SIDE := 0.4
## How many pips are on each cell of the texture, in the order a box mesh maps its faces to them:
## the front, the right and the back along the top, the left, the top and the bottom under them.
## The front and the back, the right and the left, the top and the bottom are opposite faces.
const FACES: Array[int] = [1, 2, 6, 5, 3, 4]
## How many pixels a face is drawn at, how big a pip is and how far in from the edge the pips
## stand, as shares of a face, and the faint shade along each edge that rounds the corners off.
const FACE_PIXELS := 128
const PIP_RADIUS := 0.1
const PIP_INSET := 0.25
const EDGE_SHADE := 0.06
## Black rather than the mult's red, which read less clearly on the white at a distance.
const PIP_INK := Color(0.06, 0.06, 0.07)

## The faces, drawn once, and the look every die wears.
static var _look: StandardMaterial3D

var amount := 1.0


func _build_visual(parent: Node3D) -> void:
	var cube := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * SIDE
	cube.mesh = mesh
	cube.material_override = look()
	cube.rotation_degrees = Vector3(35.0, 0.0, 45.0)
	parent.add_child(cube)
	hover = 0.45


func _apply(kart: Kart) -> void:
	kart.gain_mult(amount, &"die")


func heard_as(kart: Kart) -> Array:
	return [&"mult_gained", [kart.slot, amount, &"die"]]


## What every die is made of: the molded white of the chips, wearing its six faces.
static func look() -> StandardMaterial3D:
	if _look == null:
		_look = _paint(Color.WHITE)
		_look.albedo_texture = ImageTexture.create_from_image(faces())
	return _look


## The six faces, three across and two down, see [constant FACES].
static func faces() -> Image:
	var image := Image.create_empty(FACE_PIXELS * 3, FACE_PIXELS * 2, false, Image.FORMAT_RGBA8)
	var body := Palette.CHIP_WHITE
	image.fill(body.darkened(0.12))
	var shade := roundi(FACE_PIXELS * EDGE_SHADE)
	for cell: int in FACES.size():
		var corner := Vector2i(cell % 3, cell / 3) * FACE_PIXELS
		var inner := Rect2i(corner + Vector2i.ONE * shade, Vector2i.ONE * (FACE_PIXELS - shade * 2))
		image.fill_rect(inner, body)
		for pip: Vector2 in pips(FACES[cell]):
			_disc(image, Vector2(corner) + pip * FACE_PIXELS, PIP_RADIUS * FACE_PIXELS, PIP_INK)
	image.generate_mipmaps()
	return image


## Where the pips of [param count] stand on a face, in shares of it, as on any die.
static func pips(count: int) -> Array[Vector2]:
	var low := PIP_INSET
	var high := 1.0 - PIP_INSET
	var middle := Vector2(0.5, 0.5)
	var corners: Array[Vector2] = [
		Vector2(low, low), Vector2(high, high), Vector2(high, low), Vector2(low, high)
	]
	match count:
		1:
			return [middle]
		2:
			return corners.slice(0, 2)
		3:
			return corners.slice(0, 2) + [middle]
		4:
			return corners
		5:
			return corners + [middle]
	return corners + [Vector2(low, 0.5), Vector2(high, 0.5)]


## A filled disc, its rim softened over a pixel so it does not stair-step.
static func _disc(image: Image, at: Vector2, radius: float, ink: Color) -> void:
	var reach := ceili(radius + 1.0)
	for y: int in range(floori(at.y) - reach, floori(at.y) + reach + 1):
		for x: int in range(floori(at.x) - reach, floori(at.x) + reach + 1):
			var off := Vector2(x + 0.5, y + 0.5).distance_to(at)
			var cover := clampf(radius + 0.5 - off, 0.0, 1.0)
			if cover > 0.0:
				image.set_pixel(x, y, image.get_pixel(x, y).lerp(ink, cover))
