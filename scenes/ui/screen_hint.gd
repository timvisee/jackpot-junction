class_name ScreenHint
extends Node3D
## A hint hung over a kart, GAME.md 8.3: a row of drawn buttons and words, see [InputHint], facing
## the camera from over the kart and the same size on the screen however far off the camera is, the
## way the HUD's own words are. Sized in the world, the drive and fire hint of 3.8 and a stall's
## hint of 4.4 were a different size in every room and every shot, and the stall's was drawn at
## twice the size of the other to make up for a room seen from further off.

## How big the words and buttons are drawn at a UI scale of 100%, and shown a pixel of the drawing
## to a pixel of the screen: the size the HUD's own words are at this size.
const FONT_SIZE := 20
## How high over the kart the foot of a hint hangs, clear of the tallest hat.
const HEIGHT := 2.0

var _face: Sprite3D


## A hint of [param row], drawn at [method drawn_size], hung over [param kart] and named
## [param named].
static func hang(kart: Node3D, row: Control, named: String) -> ScreenHint:
	var hint := ScreenHint.new()
	hint.name = named
	hint.position = Vector3(0.0, HEIGHT, 0.0)
	var held := InputHint.billboard(InputHint.card(row), 0.001)
	hint.add_child(held)
	hint._face = held.get_node("Face")
	hint._face.fixed_size = true
	kart.add_child(hint)
	hint._fit()
	return hint


## [constant FONT_SIZE] at the UI scale the screen has now: drawn bigger with the rest of the UI,
## GAME.md 8.5, rather than stretched to it, so it stays sharp.
static func drawn_size(tree: SceneTree) -> int:
	return roundi(FONT_SIZE * (tree.root.content_scale_factor if tree != null else 1.0))


func _process(_delta: float) -> void:
	_fit()


## A pixel of the drawing to a pixel of the screen, for the camera there is now, and the foot of it
## where the hint hangs rather than its middle, so it clears the kart however big the kart is on the
## screen. A fixed size sprite is drawn as big as it would be a meter from the camera.
func _fit() -> void:
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera == null or _face.texture == null:
		return
	var tall := get_viewport().get_visible_rect().size.y * get_tree().root.content_scale_factor
	_face.pixel_size = 2.0 * tan(deg_to_rad(camera.fov) * 0.5) / maxf(tall, 1.0)
	_face.offset = Vector2(0.0, _face.texture.get_height() * 0.5)
