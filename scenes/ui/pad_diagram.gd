class_name PadDiagram
extends RefCounted
## A pad drawn whole for the blueprint of GAME.md 8.3b, see [PadLeaflet]: which drawing each family
## of pad is shown as, see [PadFamily], where its buttons are on it, and which of them a binding is.
##
## The drawings are Xelu's free controller prompts, public domain, see THIRD_PARTY.md: line art in
## white, so it is printed in whatever ink it is drawn in, in their plain cut with no maker's logo
## and nothing on the four buttons under the thumb, which are printed over them as each family has
## them. A Nintendo pad has an Xbox pad's layout, and no free drawing of its own, so it is drawn as
## one with its own letters; a generic pad is drawn as an Xbox pad, the layout most pads copy. A
## Steam Deck is drawn from Valve's own drawings, its top over its front to show its shoulders, in a
## Steam build, which has them, see tools/steam_deck_art, its screen broken out of the middle as a
## long drawing is; as an Xbox pad elsewhere.

const XBOX_ART: Texture2D = preload("res://assets/controllers/xbox_series.png")
const PS5_ART: Texture2D = preload("res://assets/controllers/playstation_5.png")
const PS4_ART: Texture2D = preload("res://assets/controllers/playstation_4.png")
## How big a button under the thumb is on Xelu's drawings, in their own pixels.
const FACE_RADIUS := 44.0
## The Steam Deck's drawings, there in a Steam build alone; its width in its own units, which each
## drawing is laid out over, the top view being drawn wider than the front; how many of the
## drawing's pixels each unit is, drawn about as big as the other pads; the part of its top view
## shown, in its units, turned over so its front faces the front view under it, and the room
## between the two.
const DECK_FRONT := "res://addons/godotsteam/steamdeck/front.svg"
const DECK_TOP := "res://addons/godotsteam/steamdeck/top.svg"
const DECK_WIDE := 1024.0
const DECK_UNIT := 1.7
const DECK_TOP_PART := Rect2(0.0, 30.0, 1024.0, 185.0)
const DECK_GAP := 15.0
const DECK_FACE_RADIUS := 15.0
## The middle of it, which is the screen and has no buttons, left out of both views so the Deck is
## drawn less wide and so bigger, from and to, in its units; the room left at the break; how far
## down each view its body runs at the break, top and bottom, the top view's turned over, for the
## break lines drawn there; and how far a break line's zigzag reaches out and up.
const DECK_CUT := Vector2(352.0, 672.0)
const DECK_CUT_GAP := 28.0
const DECK_TOP_BODY := Vector2(68.0, 139.0)
const DECK_FRONT_BODY := Vector2(4.0, 410.0)
const DECK_ZIG := Vector2(7.0, 10.0)
## Where its buttons are, in its units, the top view's shoulders over the front view's rest. The
## top view being turned over, a trigger is the scoop at its top, its bumper the bar under it.
const DECK_SPOTS: Dictionary[StringName, Vector2] = {
	&"lt": Vector2(60, 43),
	&"lb": Vector2(72, 94),
	&"rt": Vector2(964, 43),
	&"rb": Vector2(952, 94),
	&"ls": Vector2(163, 290),
	&"rs": Vector2(860, 290),
	&"dpad": Vector2(40, 273),
	&"view": Vector2(121, 233),
	&"menu": Vector2(902, 233),
	&"north": Vector2(958, 244),
	&"east": Vector2(989, 274),
	&"west": Vector2(929, 274),
	&"south": Vector2(958, 304),
}
## Where each button is on each drawing, in its own pixels: a trigger, a shoulder button, a stick,
## the D-pad by its left arm, the middle two, the touchpad, and the four under the thumb by where
## they are, north the one at the top.
const XBOX_SPOTS: Dictionary[StringName, Vector2] = {
	&"lt": Vector2(352, 72),
	&"lb": Vector2(300, 150),
	&"rt": Vector2(1100, 72),
	&"rb": Vector2(1152, 150),
	&"ls": Vector2(375, 420),
	&"rs": Vector2(915, 622),
	&"dpad": Vector2(480, 618),
	&"view": Vector2(630, 410),
	&"menu": Vector2(830, 410),
	&"north": Vector2(1093, 318),
	&"east": Vector2(1185, 400),
	&"west": Vector2(995, 408),
	&"south": Vector2(1088, 492),
}
const PS5_SPOTS: Dictionary[StringName, Vector2] = {
	&"lt": Vector2(310, 88),
	&"lb": Vector2(300, 218),
	&"rt": Vector2(1142, 88),
	&"rb": Vector2(1152, 218),
	&"ls": Vector2(520, 640),
	&"rs": Vector2(937, 640),
	&"dpad": Vector2(240, 445),
	&"view": Vector2(410, 312),
	&"menu": Vector2(1047, 312),
	&"touch": Vector2(727, 340),
	&"north": Vector2(1153, 357),
	&"east": Vector2(1255, 445),
	&"west": Vector2(1052, 448),
	&"south": Vector2(1153, 530),
}
const PS4_SPOTS: Dictionary[StringName, Vector2] = {
	&"lt": Vector2(325, 100),
	&"lb": Vector2(325, 165),
	&"rt": Vector2(1125, 100),
	&"rb": Vector2(1130, 165),
	&"ls": Vector2(522, 615),
	&"rs": Vector2(938, 615),
	&"dpad": Vector2(240, 407),
	&"view": Vector2(462, 277),
	&"menu": Vector2(997, 277),
	&"touch": Vector2(727, 310),
	&"north": Vector2(1138, 318),
	&"east": Vector2(1232, 405),
	&"west": Vector2(1045, 405),
	&"south": Vector2(1138, 490),
}
## The four under the thumb, by where they are, and the button the engine calls each.
const FACES: Dictionary[StringName, JoyButton] = {
	&"north": JOY_BUTTON_Y,
	&"east": JOY_BUTTON_B,
	&"west": JOY_BUTTON_X,
	&"south": JOY_BUTTON_A,
}
## Which button on the drawing each of the engine's buttons and axes is.
const BUTTONS: Dictionary[JoyButton, StringName] = {
	JOY_BUTTON_A: &"south",
	JOY_BUTTON_B: &"east",
	JOY_BUTTON_X: &"west",
	JOY_BUTTON_Y: &"north",
	JOY_BUTTON_LEFT_SHOULDER: &"lb",
	JOY_BUTTON_RIGHT_SHOULDER: &"rb",
	JOY_BUTTON_LEFT_STICK: &"ls",
	JOY_BUTTON_RIGHT_STICK: &"rs",
	JOY_BUTTON_BACK: &"view",
	JOY_BUTTON_START: &"menu",
	JOY_BUTTON_DPAD_UP: &"dpad",
	JOY_BUTTON_DPAD_DOWN: &"dpad",
	JOY_BUTTON_DPAD_LEFT: &"dpad",
	JOY_BUTTON_DPAD_RIGHT: &"dpad",
	JOY_BUTTON_TOUCHPAD: &"touch",
}
const AXES: Dictionary[JoyAxis, StringName] = {
	JOY_AXIS_LEFT_X: &"ls",
	JOY_AXIS_LEFT_Y: &"ls",
	JOY_AXIS_RIGHT_X: &"rs",
	JOY_AXIS_RIGHT_Y: &"rs",
	JOY_AXIS_TRIGGER_LEFT: &"lt",
	JOY_AXIS_TRIGGER_RIGHT: &"rt",
}
## What an Xbox pad calls each button, which [method PadFamily.word] says as each family does.
## NO_TRANSLATE: the names pads print, as keys' names are.
const XBOX_NAMES: Dictionary[StringName, String] = {
	&"lt": "LT",
	&"lb": "LB",
	&"rt": "RT",
	&"rb": "RB",
	&"view": "View",
	&"menu": "Menu",
	&"north": "Y",
	&"east": "B",
	&"west": "X",
	&"south": "A",
}
## What the ones every family calls the same are called, shown through tr().
const PLAIN_NAMES: Dictionary[StringName, String] = {
	&"ls": "Left stick",
	&"rs": "Right stick",
	&"dpad": "D-pad",
	&"touch": "Touchpad",
}
var family := PadFamily.Family.GENERIC
## The drawing, the first of its pictures; how big all of it is, and where its buttons are and how
## big the four under the thumb, in its pixels; and what it is drawn from, picture by picture: each
## one's texture, the part of it shown, where that goes and how big, and whether it is turned over.
var art: Texture2D
var size := Vector2.ZERO
var spots: Dictionary[StringName, Vector2]
var face_radius := FACE_RADIUS
var layers: Array[Dictionary] = []
## Where the drawing is broken off, the middle left out: a break line each, where it runs across
## and from where to where down, in its pixels.
var breaks: Array[Vector3] = []


## The drawing of a pad of [param family].
static func of(family: PadFamily.Family) -> PadDiagram:
	var diagram := PadDiagram.new()
	diagram.family = family
	match family:
		PadFamily.Family.PLAYSTATION:
			diagram._one(PS5_ART, PS5_SPOTS)
		PadFamily.Family.PLAYSTATION_4:
			diagram._one(PS4_ART, PS4_SPOTS)
		PadFamily.Family.STEAM_DECK when ResourceLoader.exists(DECK_FRONT):
			diagram._deck()
		_:
			diagram._one(XBOX_ART, XBOX_SPOTS)
	return diagram


## Drawn from the one picture [param picture], its buttons at [param at].
func _one(picture: Texture2D, at: Dictionary[StringName, Vector2]) -> void:
	art = picture
	size = Vector2(picture.get_size())
	spots = at
	layers = [
		{
			"texture": picture,
			"part": Rect2(Vector2.ZERO, size),
			"at": Vector2.ZERO,
			"size": size,
			"flip": false
		}
	]


## Drawn from Valve's two pictures of the Steam Deck, its top turned over above its front.
func _deck() -> void:
	var front: Texture2D = load(DECK_FRONT)
	var top: Texture2D = load(DECK_TOP)
	# The two drawings are not the same width: each is laid out over the Deck's width, and taken in
	# its own pixels.
	var below := DECK_TOP_PART.size.y + DECK_GAP
	var tall := front.get_height() / (front.get_width() / DECK_WIDE)
	# What the middle left out takes off its width, the room at the break kept.
	var gone := DECK_CUT.y - DECK_CUT.x - DECK_CUT_GAP
	art = front
	size = Vector2(DECK_WIDE - gone, below + tall) * DECK_UNIT
	face_radius = DECK_FACE_RADIUS * DECK_UNIT
	for spot: StringName in DECK_SPOTS:
		var at := DECK_SPOTS[spot]
		if at.x > DECK_CUT.y:
			at.x -= gone
		spots[spot] = at * DECK_UNIT
	layers = []
	var views: Array[Array] = [
		[top, DECK_TOP_PART, 0.0, true], [front, Rect2(0.0, 0.0, DECK_WIDE, tall), below, false]
	]
	for view: Array in views:
		var part: Rect2 = view[1]
		var pixels: float = (view[0] as Texture2D).get_width() / DECK_WIDE
		for piece: Vector3 in [
			Vector3(0.0, DECK_CUT.x, 0.0), Vector3(DECK_CUT.y, DECK_WIDE, DECK_CUT.y - gone)
		]:
			var shown := Rect2(piece.x, part.position.y, piece.y - piece.x, part.size.y)
			(
				layers
				. append(
					{
						"texture": view[0],
						"part": Rect2(shown.position * pixels, shown.size * pixels),
						"at": Vector2(piece.z, view[2]) * DECK_UNIT,
						"size": shown.size * DECK_UNIT,
						"flip": view[3],
					}
				)
			)
	breaks = []
	for edge: float in [DECK_CUT.x, DECK_CUT.x + DECK_CUT_GAP]:
		for body: Vector2 in [DECK_TOP_BODY, DECK_FRONT_BODY + Vector2(below, below)]:
			breaks.append(Vector3(edge, body.x, body.y) * DECK_UNIT)


## The drawing on [param canvas] with its top left corner at [param at], scaled by [param scale],
## in [param tint].
func draw(canvas: CanvasItem, at: Vector2, scale: float, tint: Color) -> void:
	for layer: Dictionary in layers:
		var place := Rect2(at + layer["at"] * scale, layer["size"] * scale)
		# A negative height is the same place turned over top to bottom.
		if layer["flip"]:
			place.size.y = -place.size.y
		canvas.draw_texture_rect_region(layer["texture"], place, layer["part"], tint)
	# A break line at each edge of the middle left out, as a drawing broken off has: straight, with a
	# sharp zigzag across its middle.
	var zig := DECK_ZIG * DECK_UNIT
	for line: Vector3 in breaks:
		var middle := (line.y + line.z) * 0.5
		var points := PackedVector2Array()
		for point: Vector2 in [
			Vector2(0.0, line.y),
			Vector2(0.0, middle - zig.y),
			Vector2(zig.x, middle - zig.y / 3.0),
			Vector2(-zig.x, middle + zig.y / 3.0),
			Vector2(0.0, middle + zig.y),
			Vector2(0.0, line.z),
		]:
			points.append(at + (Vector2(line.x, 0.0) + point) * scale)
		canvas.draw_polyline(points, tint, 1.8, true)


## Which button on the drawing [param event] is, or an empty name for a key, the mouse, or a pad's
## button the drawing does not show.
static func spot_of(event: InputEvent) -> StringName:
	var button := event as InputEventJoypadButton
	if button != null:
		return BUTTONS.get(button.button_index, &"")
	var motion := event as InputEventJoypadMotion
	if motion != null:
		return AXES.get(motion.axis, &"")
	return &""


## What the button at [param spot] is called on this family's pads.
func name_of(spot: StringName) -> String:
	if PLAIN_NAMES.has(spot):
		return tr(PLAIN_NAMES[spot])
	return PadFamily.word(XBOX_NAMES.get(spot, ""), family)


## Whether this drawing shows the button at [param spot].
func shows(spot: StringName) -> bool:
	return spots.has(spot)


## The four under the thumb printed on [param canvas] over the drawing laid at [param at] and
## scaled by [param scale], in [param ink], as this family has them: a PlayStation pad's shapes, and
## the letters of the rest where that family has them, in the one ink the drawing is in.
func print_faces(canvas: CanvasItem, at: Vector2, scale: float, ink: Color, font: Font) -> void:
	var radius := face_radius * scale
	var size := roundi(radius * 1.05)
	for spot: StringName in FACES:
		var middle := at + spots[spot] * scale
		if PadFamily.shapes(family):
			InputGlyph.draw_shape(canvas, FACES[spot], middle, radius * 0.5, ink)
			continue
		var letter := name_of(spot)
		var wide := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var foot := (font.get_ascent(size) - font.get_descent(size)) * 0.5
		canvas.draw_string(
			font,
			middle + Vector2(-wide * 0.5, foot),
			letter,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			size,
			ink
		)
