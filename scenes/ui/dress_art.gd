class_name DressArt
extends RefCounted
## A picture for each of the things a kart is dressed in at the stalls, GAME.md 4.4, drawn from
## the same shapes as the other pictures of 8.3a: a paint roller, a top hat, a flag on its pole,
## the puffs of a trail, a plate, two tire marks, a kart seen from its side for its body, and a
## card. On a touch screen they are what the
## fire button shows while the kart stands on a stall, since the button there changes that thing
## rather than firing, and the hint over the kart shows the same, see [method button].

## How much of the button a picture takes up, and how big the round chip the hint draws it on is
## beside the words, as a share of the line's font size.
const ON_BUTTON := 1.1
const CHIP_SIZE := 1.6


## A control that draws the picture of one of the four, square and centered in whatever room it
## is given, on a round chip with a rim, the way the button on the screen looks.
class Badge:
	extends Control

	var part := 0
	var ink := Color.WHITE

	func _draw() -> void:
		var side := minf(size.x, size.y)
		var middle := size * 0.5
		draw_circle(middle, side * 0.5, InputGlyph.CHIP)
		draw_arc(middle, side * 0.5 - 1.0, 0.0, TAU, 32, ink, InputGlyph.EDGE_WIDTH, true)
		var inner := side * 0.62
		DressArt.draw_into(
			self, Rect2(middle - Vector2.ONE * inner * 0.5, Vector2.ONE * inner), part, ink
		)


## Part [param part] of a [KartStyle] drawn as the touch screen's button for it, for a hint in a
## line of [param font_size] text.
static func button(part: int, ink: Color, font_size: int) -> Badge:
	var chip := Badge.new()
	chip.part = part
	chip.ink = ink
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var side := roundf(font_size * CHIP_SIZE)
	chip.custom_minimum_size = Vector2(side, side)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return chip


## Part [param part] of a [KartStyle], in [constant KartStyle.CHOICES] order, and the card back
## after them, drawn into [param box].
static func draw_into(on: CanvasItem, box: Rect2, part: int, ink: Color) -> void:
	match part:
		0:
			_roller(on, box, ink)
		1:
			_hat(on, box, ink)
		2:
			_flag(on, box, ink)
		4:
			_plate(on, box, ink)
		5:
			_marks(on, box, ink)
		6:
			_body(on, box, ink)
		7:
			_card(on, box, ink)
		_:
			_trail(on, box, ink)


## A kart seen from its side: its driver's head over the cockpit, the shell, and a wheel at either
## end, the back one bigger, each with a gap round it and its hub.
static func _body(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var hole := IconShapes.behind(ink)
	IconShapes.disc(on, box, 0.5, 0.3, 0.13, ink)
	IconShapes.bar(on, box, 0.08, 0.44, 0.84, 0.22, ink)
	for wheel: Vector3 in [Vector3(0.24, 0.68, 0.13), Vector3(0.74, 0.66, 0.15)]:
		IconShapes.disc(on, box, wheel.x, wheel.y, wheel.z + 0.05, hole)
		IconShapes.disc(on, box, wheel.x, wheel.y, wheel.z, ink)
		IconShapes.disc(on, box, wheel.x, wheel.y, wheel.z * 0.4, hole)


## A license plate: a bar with a bolt in each top corner, and a stroke of letters on it.
static func _plate(on: CanvasItem, box: Rect2, ink: Color) -> void:
	IconShapes.bar(on, box, 0.08, 0.32, 0.84, 0.36, ink)
	var hole := IconShapes.behind(ink)
	IconShapes.disc(on, box, 0.18, 0.4, 0.04, hole)
	IconShapes.disc(on, box, 0.82, 0.4, 0.04, hole)
	IconShapes.bar(on, box, 0.3, 0.46, 0.4, 0.1, hole)


## Two tire marks running off at a slant, broken into dashes.
static func _marks(on: CanvasItem, box: Rect2, ink: Color) -> void:
	for lane: float in [0.0, 0.3]:
		for dash: int in 3:
			var from := 0.14 + dash * 0.26
			var x := 0.2 + lane + from * 0.3
			IconShapes.line(on, box, x, 0.86 - from, x + 0.048, 0.7 - from, ink)


## A card standing up, a ring at its middle.
static func _card(on: CanvasItem, box: Rect2, ink: Color) -> void:
	IconShapes.bar(on, box, 0.24, 0.1, 0.52, 0.8, ink)
	IconShapes.disc(on, box, 0.5, 0.5, 0.14, IconShapes.behind(ink))
	IconShapes.disc(on, box, 0.5, 0.5, 0.08, ink)


## A paint roller: the roller along the top, its frame round to the handle under it.
static func _roller(on: CanvasItem, box: Rect2, ink: Color) -> void:
	IconShapes.bar(on, box, 0.14, 0.14, 0.62, 0.24, ink)
	IconShapes.line(on, box, 0.76, 0.26, 0.88, 0.26, ink)
	IconShapes.line(on, box, 0.88, 0.26, 0.88, 0.5, ink)
	IconShapes.line(on, box, 0.88, 0.5, 0.5, 0.5, ink)
	IconShapes.line(on, box, 0.5, 0.5, 0.5, 0.6, ink)
	IconShapes.bar(on, box, 0.42, 0.58, 0.16, 0.32, ink)


## A top hat: the crown, a band round it and the brim.
static func _hat(on: CanvasItem, box: Rect2, ink: Color) -> void:
	IconShapes.bar(on, box, 0.3, 0.16, 0.4, 0.52, ink)
	IconShapes.bar(on, box, 0.3, 0.54, 0.4, 0.08, IconShapes.behind(ink))
	IconShapes.bar(on, box, 0.12, 0.66, 0.76, 0.14, ink)


## A pennant flying from the top of its pole.
static func _flag(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var points := PackedVector2Array(
		[IconShapes.at(box, 0.3, 0.12), IconShapes.at(box, 0.86, 0.3), IconShapes.at(box, 0.3, 0.5)]
	)
	on.draw_colored_polygon(points, ink)
	IconShapes.bar(on, box, 0.2, 0.08, 0.1, 0.84, ink)


## The trail left behind: puffs getting smaller and fainter the further back they are.
static func _trail(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var puffs: Array[Array] = [
		[0.7, 0.3, 0.19, 1.0],
		[0.44, 0.52, 0.14, 0.75],
		[0.26, 0.7, 0.1, 0.55],
		[0.14, 0.86, 0.07, 0.4]
	]
	for puff: Array in puffs:
		IconShapes.disc(on, box, puff[0], puff[1], puff[2], Color(ink, ink.a * puff[3]))
