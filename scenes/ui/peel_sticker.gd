class_name PeelSticker
extends Control
## A room's sticker on the loading screen, GAME.md 8.6, there from the moment the screen is: the
## room's emblem itself, see [RoomEmblem], die-cut as it is drawn, stuck down a little askew in the
## corner of the screen with one edge peeled up and folded back over it, its plain back showing,
## and a soft shadow under the lot, so it reads as a real sticker rather than a picture.
##
## Drawn, not a picture of its own: the emblem cut along the crease, the part past it turned over
## the crease in the emblem's own outline, and the shadows the same outline in black.

## How big it is, in pixels of the 1080 lines the UI is laid out on, so it grows and shrinks with
## the window and the UI scale as every menu does, 8.5; where the crease runs, as how far along the
## diagonal from the top left corner it cuts, in shares of the picture's side, x and y added up;
## how far the shadow falls.
const SIDE := 128.0
const CREASE := 1.45
const SHADOW_OFF := Vector2(3.0, 5.0)
## The sticker's back where it is folded over, and its shadows.
const BACK := Color("#E4DED2")
const SHADOW := Color(0.0, 0.0, 0.0, 0.55)
const FLAP_SHADOW := Color(0.0, 0.0, 0.0, 0.28)

## Each emblem's outline in one color, for the back and the shadows, made once a run.
static var _outlines: Dictionary[Texture2D, Texture2D] = {}

var emblem: Texture2D
var _outline: Texture2D


func _init(texture: Texture2D = null) -> void:
	name = "PeelSticker"
	emblem = texture
	custom_minimum_size = Vector2.ONE * SIDE
	size = custom_minimum_size
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if emblem != null:
		_outline = outline_of(emblem)


## [param texture]'s outline: every pixel white at the alpha it has, so a color drawn with it is
## the sticker's shape in that color.
static func outline_of(texture: Texture2D) -> Texture2D:
	if _outlines.has(texture):
		return _outlines[texture]
	var image := texture.get_image()
	if image == null:
		return texture
	image = image.duplicate() as Image
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	for y: int in image.get_height():
		for x: int in image.get_width():
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, image.get_pixel(x, y).a))
	var made := ImageTexture.create_from_image(image)
	_outlines[texture] = made
	return made


## The part of the picture this side of the crease, in shares of its side.
static func kept() -> PackedVector2Array:
	var cut := Geometry2D.clip_polygons(_square(), _past())
	return cut[0] if not cut.is_empty() else _square()


## The part past the crease, which is folded over, in shares of its side, where it lay.
static func folded() -> PackedVector2Array:
	var cut := Geometry2D.intersect_polygons(_square(), _past())
	return cut[0] if not cut.is_empty() else PackedVector2Array()


## [param point] turned over the crease.
static func over(point: Vector2) -> Vector2:
	return point - Vector2.ONE * (point.x + point.y - CREASE)


func _draw() -> void:
	if emblem == null:
		return
	var kept_part := kept()
	var flap := folded()
	var turned := PackedVector2Array()
	for point: Vector2 in flap:
		turned.append(over(point))
	_draw_part(kept_part, kept_part, _outline, SHADOW, SHADOW_OFF)
	_draw_part(kept_part, kept_part, emblem, Color.WHITE)
	_draw_part(turned, flap, _outline, FLAP_SHADOW, SHADOW_OFF * 0.5)
	_draw_part(turned, flap, _outline, BACK)


## The picture's [param from] part, in shares of its side, drawn at [param at] in [param color]
## through [param texture], moved by [param shift] pixels.
func _draw_part(
	at: PackedVector2Array,
	from: PackedVector2Array,
	texture: Texture2D,
	color: Color,
	shift := Vector2.ZERO
) -> void:
	if at.size() < 3:
		return
	var points := PackedVector2Array()
	for point: Vector2 in at:
		points.append(point * SIDE + shift)
	draw_polygon(points, PackedColorArray([color]), from, texture)


static func _square() -> PackedVector2Array:
	return PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN])


static func _past() -> PackedVector2Array:
	return PackedVector2Array(
		[
			Vector2(CREASE, 0.0),
			Vector2(2.0, 0.0),
			Vector2(2.0, 2.0),
			Vector2(0.0, 2.0),
			Vector2(0.0, CREASE)
		]
	)
