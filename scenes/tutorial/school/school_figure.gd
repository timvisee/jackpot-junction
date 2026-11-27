class_name SchoolFigure
extends Control
## The pictures of the driving school, GAME.md 9.4a: the figures in the theory book, the faces of
## the road signs standing about the driving test, the endorsements on the license. A sign is drawn
## in code, in its own colors, the red ring and the blue disc a road knows, sharp at any size as a
## face in the room; a figure of the book is a drawing of GAME.md 8.3a printed flat in [member ink]
## alone on the page, the game's own drawing of the thing where it has one, and an endorsement in
## whatever the card hands it.

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
## Each figure's drawing of GAME.md 8.3a: the game's own drawing of the thing where it has one,
## so the book and the game show one jackpot, one flush, one target, the book's own otherwise.
const FIGURES: Dictionary[Kind, StringName] = {
	Kind.JACKPOT: &"table_jackpot",
	Kind.JUNCTION: &"book_junction",
	Kind.DRIFT: &"tailslide",
	Kind.PIT: &"book_pit",
	Kind.FLUSH: &"table_royal_flush",
	Kind.DIE: &"book_die",
	Kind.CARD: &"dress_card_back",
	Kind.KO: &"book_ko",
	Kind.TARGET: &"landmark_marksman",
	Kind.ARROW: &"book_arrow",
}
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
		_:
			IconPress.draw(on, box, FIGURES[of], ink, IconPress.Ground.PAPER)


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
