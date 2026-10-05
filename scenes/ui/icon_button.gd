class_name IconButton
extends RefCounted
## A menu button with a picture on it rather than a word, GAME.md 8.3, for what is pressed beside a
## row of a list over and over: Remove as a trash can, Watch as an eye, Edit as a pencil, and Move
## up and Move down as arrows. The word is its tooltip, for a mouse that hovers to ask. Drawn
## rather than loaded, like every other picture of the menus.

enum Kind { TRASH, EYE, PENCIL, UP, DOWN }

## How big a button is, an arrow's narrower, and how much of its height the picture takes.
const SIZE := Vector2(64.0, 52.0)
const ARROW_WIDE := 48.0
const PICTURE := 0.56
const INK := Color(0.92, 0.92, 0.95)
## What is cut out of the picture, a can's ribs and an eye's iris: the button's own dark.
const CUT := MenuTheme.BUTTON_BG


## The picture on a button, drawn in the button's ink, faded while it cannot be pressed.
class Picture:
	extends Control

	var kind := Kind.TRASH

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var button := get_parent() as BaseButton
		if button != null:
			button.draw.connect(queue_redraw)

	func _draw() -> void:
		var button := get_parent() as BaseButton
		var ink := INK
		if button != null and button.disabled:
			ink = Color(INK, 0.3)
		var side := size.y * PICTURE
		var box := Rect2(size * 0.5 - Vector2(side, side) * 0.5, Vector2(side, side))
		match kind:
			Kind.EYE:
				IconButton.eye(self, box, ink)
			Kind.PENCIL:
				IconButton.pencil(self, box, ink)
			Kind.UP, Kind.DOWN:
				IconButton.arrow(self, box, ink, kind == Kind.UP)
			_:
				IconButton.trash(self, box, ink)


## A button wearing the picture of [param kind], with [param word] for its tooltip.
static func of(kind: Kind, word: String) -> Button:
	var button := MenuTheme.button("", Type.BODY)
	button.custom_minimum_size = SIZE
	if kind == Kind.UP or kind == Kind.DOWN:
		button.custom_minimum_size.x = ARROW_WIDE
	button.tooltip_text = word
	# As tall as the row it stands beside, a server's name over its address making one taller.
	button.size_flags_vertical = Control.SIZE_FILL
	var picture := Picture.new()
	picture.name = "Picture"
	picture.kind = kind
	button.add_child(picture)
	return button


## A trash can in [param box]: the lid with its handle, and the body tapering to its foot with
## three ribs down it.
static func trash(on: CanvasItem, box: Rect2, ink: Color) -> void:
	IconShapes.bar(on, box, 0.38, 0.02, 0.24, 0.1, ink)
	IconShapes.bar(on, box, 0.1, 0.12, 0.8, 0.12, ink)
	var body := PackedVector2Array(
		[
			IconShapes.at(box, 0.18, 0.3),
			IconShapes.at(box, 0.82, 0.3),
			IconShapes.at(box, 0.74, 0.98),
			IconShapes.at(box, 0.26, 0.98),
		]
	)
	on.draw_colored_polygon(body, ink)
	var rib := Color(CUT, 1.0)
	for x: float in [0.36, 0.5, 0.64]:
		on.draw_line(
			IconShapes.at(box, x, 0.42),
			IconShapes.at(box, x, 0.86),
			rib,
			IconShapes.width(box),
			true
		)


## An eye in [param box]: the almond of its lids and the iris in the middle with a glint in it.
static func eye(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var lids := PackedVector2Array()
	var steps := 16
	for i: int in steps + 1:
		var t := float(i) / steps
		lids.append(IconShapes.at(box, t, 0.5 - 0.34 * sin(t * PI)))
	for i: int in range(steps - 1, 0, -1):
		var t := float(i) / steps
		lids.append(IconShapes.at(box, t, 0.5 + 0.34 * sin(t * PI)))
	on.draw_colored_polygon(lids, ink)
	IconShapes.disc(on, box, 0.5, 0.5, 0.22, Color(CUT, 1.0))
	IconShapes.disc(on, box, 0.5, 0.5, 0.12, ink)
	IconShapes.disc(on, box, 0.56, 0.44, 0.04, Color(CUT, 1.0))


## A pencil in [param box], lying from the bottom left up to the top right: its point, its body,
## and the eraser at its end, with a band between them cut out.
static func pencil(on: CanvasItem, box: Rect2, ink: Color) -> void:
	var along := (IconShapes.at(box, 0.86, 0.14) - IconShapes.at(box, 0.14, 0.86)).normalized()
	var side := Vector2(-along.y, along.x) * IconShapes.span(box, 0.13)
	var tip := IconShapes.at(box, 0.1, 0.9)
	var wood := tip + along * IconShapes.span(box, 0.26)
	var end := IconShapes.at(box, 0.88, 0.12)
	on.draw_colored_polygon(PackedVector2Array([tip, wood + side, wood - side]), ink)
	on.draw_colored_polygon(
		PackedVector2Array([wood + side, end + side, end - side, wood - side]), ink
	)
	var band := end - along * IconShapes.span(box, 0.2)
	on.draw_line(band + side, band - side, Color(CUT, 1.0), IconShapes.width(box), true)


## An arrow in [param box], pointing up when [param up] and down otherwise: a head over a shaft.
static func arrow(on: CanvasItem, box: Rect2, ink: Color, up: bool) -> void:
	var flip := func(y: float) -> float: return y if up else 1.0 - y
	(
		on
		. draw_colored_polygon(
			PackedVector2Array(
				[
					IconShapes.at(box, 0.5, flip.call(0.08)),
					IconShapes.at(box, 0.9, flip.call(0.52)),
					IconShapes.at(box, 0.1, flip.call(0.52)),
				]
			),
			ink
		)
	)
	var top: float = minf(flip.call(0.5), flip.call(0.94))
	IconShapes.bar(on, box, 0.37, top, 0.26, 0.44, ink)
