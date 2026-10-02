class_name SchoolFigure
extends Control
## The pictures of the driving school, GAME.md 9.4a: the figures in the theory book, the faces of
## the road signs standing about the driving test, the endorsements on the license. Drawn out of
## the palette, as every picture in the game is, 8.3a, so they come out sharp at any size: a sign
## face in the room, a figure in the book and a chip on the card are one recipe each.
##
## A sign wears its own colors, the red ring and the blue disc a road knows; a figure of the book
## is drawn in [member ink] alone on the page, and an endorsement in whatever the card hands it.

enum Kind {
	SPEED,
	WARNING,
	ROUNDABOUT,
	NO_ENTRY,
	PARKING,
	LEARNER,
	JACKPOT,
	JUNCTION,
	DRIFT,
	PIT,
	FLUSH,
	DIE,
	CARD,
	KO,
	TARGET,
	ARROW,
}

## The colors a road sign is painted in.
const SIGN_RED := Color("#C8362E")
const SIGN_BLUE := Color("#2B63B8")
const SIGN_WHITE := Color("#F6F3EC")
const SIGN_INK := Color("#17171A")
## What a figure of the book is drawn in, the ink of a printed page.
const BOOK_INK := Color(0.16, 0.15, 0.14)
## The signs, as against the figures: the ones with their own colors.
const SIGNS: Array[Kind] = [
	Kind.SPEED, Kind.WARNING, Kind.ROUNDABOUT, Kind.NO_ENTRY, Kind.PARKING, Kind.LEARNER
]

@export var kind := Kind.LEARNER
@export var ink := BOOK_INK


## A figure of [param of], [param side] pixels square, in [param in_ink] where the kind takes one.
static func of(of: Kind, side: float, in_ink: Color = BOOK_INK) -> SchoolFigure:
	var figure := SchoolFigure.new()
	figure.kind = of
	figure.ink = in_ink
	figure.custom_minimum_size = Vector2(side, side)
	figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return figure


func _draw() -> void:
	draw_into(self, Rect2(Vector2.ZERO, size), kind, ink)


## Draws [param of] into [param box] on [param on], a sign in its own colors and a figure in
## [param ink].
static func draw_into(on: CanvasItem, box: Rect2, of: Kind, ink: Color) -> void:
	match of:
		Kind.SPEED:
			_speed(on, box)
		Kind.WARNING:
			_warning(on, box)
		Kind.ROUNDABOUT:
			_roundabout(on, box)
		Kind.NO_ENTRY:
			_no_entry(on, box)
		Kind.PARKING:
			_square(on, box, SIGN_BLUE, "P", SIGN_WHITE)
		Kind.LEARNER:
			_square(on, box, SIGN_WHITE, "L", SIGN_RED, SIGN_INK)
		Kind.JACKPOT:
			_jackpot(on, box, ink)
		Kind.JUNCTION:
			_junction(on, box, ink)
		Kind.DRIFT:
			_drift(on, box, ink)
		Kind.PIT:
			_pit(on, box, ink)
		Kind.FLUSH:
			_flush(on, box, ink)
		Kind.DIE:
			_die(on, box, ink)
		Kind.CARD:
			_card(on, box, ink)
		Kind.KO:
			IconShapes.burst(on, box, 0.5, 0.5, 0.9, ink)
		Kind.TARGET:
			_target(on, box, ink)
		Kind.ARROW:
			_arrow(on, box, ink)


## The speed limit: a white disc with a thick red ring and the number in the middle.
static func _speed(on: CanvasItem, box: Rect2) -> void:
	IconShapes.disc(on, box, 0.5, 0.5, 0.48, SIGN_RED)
	IconShapes.disc(on, box, 0.5, 0.5, 0.36, SIGN_WHITE)
	_word(on, box, "30", 0.42, SIGN_INK)


## Karts crossing: a red-edged triangle with a kart on it.
static func _warning(on: CanvasItem, box: Rect2) -> void:
	# The white inside on the same middle as the red, so the border is as wide along the foot as
	# up the sides rather than worn to a sliver there.
	IconShapes.tri(on, box, 0.5, 0.56, 1.02, 0.0, SIGN_RED)
	IconShapes.tri(on, box, 0.5, 0.56, 0.76, 0.0, SIGN_WHITE)
	# A kart from the side: a low body, a bump of a driver, and two wheels.
	IconShapes.bar(on, box, 0.33, 0.52, 0.34, 0.1, SIGN_INK)
	IconShapes.bar(on, box, 0.4, 0.44, 0.14, 0.1, SIGN_INK)
	IconShapes.disc(on, box, 0.47, 0.42, 0.045, SIGN_INK)
	IconShapes.disc(on, box, 0.38, 0.65, 0.055, SIGN_INK)
	IconShapes.disc(on, box, 0.62, 0.65, 0.055, SIGN_INK)


## The roundabout: a blue disc with three white arrows chasing each other round it.
static func _roundabout(on: CanvasItem, box: Rect2) -> void:
	IconShapes.disc(on, box, 0.5, 0.5, 0.48, SIGN_BLUE)
	var middle := IconShapes.at(box, 0.5, 0.5)
	var radius := IconShapes.span(box, 0.27)
	var width := IconShapes.span(box, 0.07)
	for i: int in 3:
		var from := TAU * float(i) / 3.0 - PI * 0.5
		on.draw_arc(middle, radius, from, from + TAU / 3.0 - 0.55, 16, SIGN_WHITE, width, true)
		var tip := from + TAU / 3.0 - 0.55
		var at := middle + Vector2(cos(tip), sin(tip)) * radius
		var head := PackedVector2Array()
		var out := Vector2(cos(tip + PI * 0.5), sin(tip + PI * 0.5))
		var side := Vector2(cos(tip), sin(tip))
		head.append(at + out * width * 2.2)
		head.append(at + side * width * 1.5)
		head.append(at - side * width * 1.5)
		on.draw_colored_polygon(head, SIGN_WHITE)


## No entry: a red disc with a white bar across it.
static func _no_entry(on: CanvasItem, box: Rect2) -> void:
	IconShapes.disc(on, box, 0.5, 0.5, 0.48, SIGN_RED)
	IconShapes.bar(on, box, 0.18, 0.42, 0.64, 0.16, SIGN_WHITE)


## A square sign with one letter on it, with an edge where it wants one.
static func _square(
	on: CanvasItem,
	box: Rect2,
	fill: Color,
	letter: String,
	letter_ink: Color,
	edge: Color = Color.TRANSPARENT
) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(roundi(IconShapes.span(box, 0.08)))
	if edge.a > 0.0:
		style.set_border_width_all(maxi(roundi(IconShapes.span(box, 0.04)), 1))
		style.border_color = edge
	on.draw_style_box(style, Rect2(IconShapes.at(box, 0.04, 0.04), box.size * 0.92))
	_word(on, box, letter, 0.62, letter_ink)


## The Jackpot: a pad with a pile of coins on it, three deep.
static func _jackpot(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var faint := IconShapes.behind(ink)
	IconShapes.bar(on, box, 0.1, 0.68, 0.8, 0.14, faint)
	for coin: Array in [[0.36, 0.56], [0.62, 0.56], [0.49, 0.42]]:
		IconShapes.disc(on, box, coin[0], coin[1], 0.15, ink)
		IconShapes.disc(on, box, coin[0], coin[1], 0.1, faint)
	IconShapes.star(on, box, 0.8, 0.28, 0.18, ink)
	IconShapes.star(on, box, 0.2, 0.3, 0.12, ink)


## The Junction: a disc with the crossroads through it, the game's own mark in one ink.
static func _junction(on: CanvasItem, box: Rect2, ink: Color) -> void:
	IconShapes.ring(on, box, 0.5, 0.5, 0.44, ink)
	IconShapes.bar(on, box, 0.1, 0.42, 0.8, 0.16, ink)
	IconShapes.bar(on, box, 0.42, 0.1, 0.16, 0.8, ink)
	IconShapes.disc(on, box, 0.5, 0.5, 0.11, IconShapes.behind(ink))


## A drift: a curved arrow with two skid marks under it.
static func _drift(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var middle := IconShapes.at(box, 0.5, 0.62)
	var radius := IconShapes.span(box, 0.34)
	var width := IconShapes.width(box) * 1.6
	on.draw_arc(middle, radius, PI, PI * 1.78, 24, ink, width, true)
	var tip := PI * 1.78
	var at := middle + Vector2(cos(tip), sin(tip)) * radius
	var head := PackedVector2Array()
	head.append(at + Vector2(width * 2.4, width * 1.4))
	head.append(at + Vector2(-width * 1.6, -width * 1.2))
	head.append(at + Vector2(-width * 0.6, width * 2.4))
	on.draw_colored_polygon(head, ink)
	var faint := IconShapes.behind(ink)
	on.draw_arc(
		middle + Vector2(0.0, width * 2.4),
		radius * 0.78,
		PI * 1.08,
		PI * 1.6,
		16,
		faint,
		width * 0.8,
		true
	)
	on.draw_arc(
		middle + Vector2(0.0, width * 4.2),
		radius * 0.62,
		PI * 1.12,
		PI * 1.55,
		16,
		faint,
		width * 0.8,
		true
	)


## The pit: a grate, a rounded square with bars down it.
static func _pit(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.set_border_width_all(maxi(roundi(IconShapes.width(box) * 1.4), 2))
	style.border_color = ink
	style.set_corner_radius_all(roundi(IconShapes.span(box, 0.1)))
	on.draw_style_box(style, Rect2(IconShapes.at(box, 0.1, 0.1), box.size * 0.8))
	for i: int in 4:
		IconShapes.bar(on, box, 0.22 + 0.15 * float(i), 0.2, 0.07, 0.6, ink)


## The Royal Flush: the four suits in a square.
static func _flush(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var half := box.size * 0.46
	for suit: int in 4:
		var corner := IconShapes.at(
			box, 0.04 + 0.46 * float(suit % 2), 0.04 + 0.46 * floorf(suit * 0.5)
		)
		SuitArt.draw_into(on, Rect2(corner, half), suit, ink)


## A mult die: a rounded square with five pips.
static func _die(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = ink
	style.set_corner_radius_all(roundi(IconShapes.span(box, 0.14)))
	on.draw_style_box(style, Rect2(IconShapes.at(box, 0.1, 0.1), box.size * 0.8))
	var hole := IconShapes.behind(ink)
	hole.a = 1.0
	hole = hole.lerp(Color.WHITE, 0.8)
	for pip: Vector2 in [
		Vector2(0.3, 0.3),
		Vector2(0.7, 0.3),
		Vector2(0.5, 0.5),
		Vector2(0.3, 0.7),
		Vector2(0.7, 0.7)
	]:
		IconShapes.disc(on, box, pip.x, pip.y, 0.07, hole)


## A joker card: a card with a star on it.
static func _card(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.set_border_width_all(maxi(roundi(IconShapes.width(box) * 1.4), 2))
	style.border_color = ink
	style.set_corner_radius_all(roundi(IconShapes.span(box, 0.08)))
	on.draw_style_box(style, Rect2(IconShapes.at(box, 0.2, 0.06), box.size * Vector2(0.6, 0.88)))
	IconShapes.star(on, box, 0.5, 0.5, 0.42, ink)


## A target: rings round a bull.
static func _target(on: CanvasItem, box: Rect2, ink: Color) -> void:
	IconShapes.ring(on, box, 0.5, 0.5, 0.44, ink)
	IconShapes.ring(on, box, 0.5, 0.5, 0.28, ink)
	IconShapes.disc(on, box, 0.5, 0.5, 0.12, ink)


## An arrow pointing right, for a direction plate.
static func _arrow(on: CanvasItem, box: Rect2, ink: Color) -> void:
	IconShapes.bar(on, box, 0.1, 0.42, 0.5, 0.16, ink)
	IconShapes.tri(on, box, 0.7, 0.5, 0.6, 90.0, ink)


## [param text] in the middle of [param box], [param share] of its height tall.
static func _word(on: CanvasItem, box: Rect2, text: String, share: float, color: Color) -> void:
	var font := Type.display_font()
	var font_size := maxi(roundi(box.size.y * share), 6)
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	var baseline := box.position.y + (box.size.y + ascent - descent) * 0.5
	on.draw_string(
		font,
		Vector2(box.position.x, baseline),
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		box.size.x,
		font_size,
		color
	)
