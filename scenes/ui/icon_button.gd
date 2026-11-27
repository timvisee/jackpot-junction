class_name IconButton
extends RefCounted
## A menu button with a picture on it rather than a word, GAME.md 8.3, for what is pressed beside a
## row of a list over and over: Remove as a trash can, Watch as an eye, Edit as a pencil, Switch as
## two arrows trading places, and the grip a row is moved by as six dots, which turn into an arrow
## up and down while it is picked up.
## The word is its tooltip, for a mouse that hovers to ask. Each picture is a drawing of GAME.md
## 8.3a printed flat in the button's ink, its light parts left bare so the button shows through.

enum Kind { TRASH, EYE, PENCIL, GRIP, MOVE, SWAP }

## How big a button is, a grip's narrower, and how much of its height the picture takes.
const SIZE := Vector2(64.0, 52.0)
const GRIP_WIDE := 44.0
const PICTURE := 0.56
const INK := Color(0.92, 0.92, 0.95)
## Each kind's drawing, in [enum Kind] order.
const PICTURES: Array[StringName] = [
	&"ui_trash", &"ui_eye", &"ui_pencil", &"ui_grip", &"ui_move", &"ui_swap"
]


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
		IconPress.draw(self, box, PICTURES[kind], ink, IconPress.Ground.PAPER)


## A button wearing the picture of [param kind], with [param word] for its tooltip.
static func of(kind: Kind, word: String) -> Button:
	var button := MenuTheme.button("", Type.BODY)
	button.custom_minimum_size = SIZE
	if kind == Kind.GRIP or kind == Kind.MOVE:
		button.custom_minimum_size.x = GRIP_WIDE
	button.tooltip_text = word
	# As tall as the row it stands beside, a server's name over its address making one taller.
	button.size_flags_vertical = Control.SIZE_FILL
	var picture := Picture.new()
	picture.name = "Picture"
	picture.kind = kind
	button.add_child(picture)
	return button
