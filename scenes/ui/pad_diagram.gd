class_name PadDiagram
extends RefCounted
## A pad drawn whole for the leaflet of GAME.md 8.3b, see [PadLeaflet]: which drawing each family
## of pad is shown as, see [PadFamily], where its buttons are on it, and which of them a binding is.
##
## The drawings are Xelu's free controller prompts, public domain, see THIRD_PARTY.md: line art in
## white, so it is printed in whatever ink it is drawn in, in their plain cut with no maker's logo
## and nothing on the four buttons under the thumb, which are printed over them as each family has
## them. A Nintendo pad has an Xbox pad's layout, and no free drawing of its own, so it is drawn as
## one with its own letters; a generic pad is drawn as an Xbox pad, the layout most pads copy.

const XBOX_ART: Texture2D = preload("res://assets/controllers/xbox_series.png")
const PS5_ART: Texture2D = preload("res://assets/controllers/playstation_5.png")
const PS4_ART: Texture2D = preload("res://assets/controllers/playstation_4.png")
## How big a button under the thumb is on each drawing, in its own pixels.
const FACE_RADIUS := 44.0
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
## What an Xbox pad calls each button, which [method PadFamily.word] says as each family does, and
## what the ones every family calls the same are called.
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
const PLAIN_NAMES: Dictionary[StringName, String] = {
	&"ls": "Left stick",
	&"rs": "Right stick",
	&"dpad": "D-pad",
	&"touch": "Touchpad",
}
## The four printed on the paper: an Xbox pad's in its colors, a little deeper than on a screen, and
## a PlayStation pad's shapes the same.
const PRINTED_FACES: Dictionary[JoyButton, Color] = {
	JOY_BUTTON_A: Color("#5aae5a"),
	JOY_BUTTON_B: Color("#cf4f4b"),
	JOY_BUTTON_X: Color("#4777c8"),
	JOY_BUTTON_Y: Color("#dcb434"),
}
const PRINTED_SHAPES: Dictionary[JoyButton, Color] = {
	JOY_BUTTON_A: Color("#4d78d6"),
	JOY_BUTTON_B: Color("#d0464b"),
	JOY_BUTTON_X: Color("#cf6fb4"),
	JOY_BUTTON_Y: Color("#2f9e78"),
}

var family := PadFamily.Family.GENERIC
var art: Texture2D
var spots: Dictionary[StringName, Vector2]


## The drawing of a pad of [param family].
static func of(family: PadFamily.Family) -> PadDiagram:
	var diagram := PadDiagram.new()
	diagram.family = family
	match family:
		PadFamily.Family.PLAYSTATION:
			diagram.art = PS5_ART
			diagram.spots = PS5_SPOTS
		PadFamily.Family.PLAYSTATION_4:
			diagram.art = PS4_ART
			diagram.spots = PS4_SPOTS
		_:
			diagram.art = XBOX_ART
			diagram.spots = XBOX_SPOTS
	return diagram


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
		return PLAIN_NAMES[spot]
	return PadFamily.word(XBOX_NAMES.get(spot, ""), family)


## Whether this drawing shows the button at [param spot].
func shows(spot: StringName) -> bool:
	return spots.has(spot)


## The four under the thumb printed on [param canvas] over the drawing laid at [param at] and
## scaled by [param scale], in [param ink], as this family has them: an Xbox pad's lettered in
## their colors, a PlayStation pad's shapes in theirs, a Nintendo pad's letters alone.
func print_faces(canvas: CanvasItem, at: Vector2, scale: float, ink: Color, font: Font) -> void:
	var radius := FACE_RADIUS * scale
	var size := roundi(radius * 1.05)
	for spot: StringName in FACES:
		var middle := at + spots[spot] * scale
		var face := FACES[spot]
		if PadFamily.shapes(family):
			InputGlyph.draw_shape(canvas, face, middle, radius * 0.5, PRINTED_SHAPES[face])
			continue
		if PadFamily.lettered(family):
			canvas.draw_circle(middle, radius - 3.0, Color(PRINTED_FACES[face], 0.85))
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
