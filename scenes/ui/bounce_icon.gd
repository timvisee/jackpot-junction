class_name BounceIcon
extends RefCounted
## The mark the kill feed puts after a kill by a bullet that came off a wall first, GAME.md 8.3: a
## wall on the right, and the bullet's path coming in to it from the lower left and going off it
## to the upper left, with the bullet at its end. Drawn once into a small picture and shared by
## every line that has one, in the feed's own gray.

## How many pixels it is drawn at, how thick its lines are, and where its parts are, as shares of
## its side.
const PIXELS := 48
const LINE := 0.075
const WALL := 0.8
const PATH: Array[Vector2] = [Vector2(0.12, 0.86), Vector2(0.68, 0.5), Vector2(0.18, 0.16)]
const BULLET := 0.1

static var _drawn: Dictionary[Color, ImageTexture] = {}


## The mark in [param ink], drawn the first time it is asked for.
static func texture(ink: Color) -> ImageTexture:
	if not _drawn.has(ink):
		_drawn[ink] = ImageTexture.create_from_image(draw(ink))
	return _drawn[ink]


static func draw(ink: Color) -> Image:
	var image := Image.create_empty(PIXELS, PIXELS, false, Image.FORMAT_RGBA8)
	image.fill(Color(ink, 0.0))
	var side := float(PIXELS)
	var half := LINE * side * 0.5
	var lines: Array[Array] = [
		[Vector2(WALL, 0.08) * side, Vector2(WALL, 0.92) * side, half * 1.4],
		[PATH[0] * side, PATH[1] * side, half],
		[PATH[1] * side, PATH[2] * side, half],
	]
	var tip := PATH[2] * side
	for y: int in PIXELS:
		for x: int in PIXELS:
			var at := Vector2(x + 0.5, y + 0.5)
			var cover := clampf(BULLET * side + 0.5 - at.distance_to(tip), 0.0, 1.0)
			for line: Array in lines:
				var near := Geometry2D.get_closest_point_to_segment(at, line[0], line[1])
				cover = maxf(cover, clampf(float(line[2]) + 0.5 - at.distance_to(near), 0.0, 1.0))
			if cover > 0.0:
				image.set_pixel(x, y, Color(ink, cover))
	return image
