class_name KeyTag
extends Control
## A tab of the kart dialog, GAME.md 4.4, for whose kart it dresses, see [KartOwner]: a seat's key
## on the bay's key board, a plastic fob in its color with the seat over its name, or a profile
## nobody is playing as on a manila tag on a string. The one the dialog is on hangs straight and
## lit, the others swung on their hooks. Hung on the dialog's [KeyRail], which takes the pointer for
## it: pressed, the dialog turns to it; the page keys do the same, so it never takes the cursor.
## Drawn once a run each way it can look and kept, see [BayArt], and faded toward the rail's ends.

const GROUP := &"key_tags"
## How wide a seat's key and a profile's tag are, and how far round them their kept pictures
## reach, for the swing and the shadow.
const KEY_WIDE := BayArt.KEY_WIDE
const PROFILE_WIDE := BayArt.TAG_WIDE
const TALL := 78.0
const AROUND := 18.0

var heading := ""
var named := ""
var color := Color.WHITE
## Whether it is a seat's key rather than a profile's tag, and whether the dialog is on it.
var seat_key := true
var here := false
## How far it hangs swung, left or right, while it is not the one.
var swing := 0.05
## Whether the pointer is on it; how much of it is seen across it, faded toward the ends of its
## rail: at each of the places along it, in its own x, where the fade turns, from its left edge to
## its right, see [method _draw_faded], all of it with none; and how much of it is seen at its
## middle.
var pointed := false:
	set(on):
		pointed = on
		queue_redraw()
var fades := PackedVector2Array():
	set(along):
		fades = along
		queue_redraw()
var seen := 1.0
## The picture it showed last, shown on while a new one is drawn.
var _art: Texture2D


static func make(owner: KartOwner, number: int) -> KeyTag:
	var tag := KeyTag.new()
	tag.name = "Key%d" % number
	tag.seat_key = owner.seat >= 0
	tag.swing = 0.06 if number % 2 == 0 else -0.05
	tag.size = Vector2(KEY_WIDE if tag.seat_key else PROFILE_WIDE, TALL)
	tag.say(owner)
	return tag


func _ready() -> void:
	add_to_group(GROUP)
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Says what [param owner] is called and what color it is in now.
func say(owner: KartOwner) -> void:
	heading = owner.heading()
	named = owner.display_name()
	var picked := owner.color()
	color = Palette.player_color(picked) if picked >= 0 else HouseTheme.QUIET
	queue_redraw()


func set_here(on: bool) -> void:
	here = on
	queue_redraw()


func _draw() -> void:
	# Its size as it was made: moved along its rail, it drifts in its last places, and drawn by that
	# its picture was looked for anew, missing for a frame while it was drawn again.
	var tag := size.round()
	var whole := Rect2(Vector2(-AROUND, 0.0), tag + Vector2(AROUND * 2.0, AROUND))
	var hook := Vector2(14.0, 0.0) if seat_key else Vector2(tag.x * 0.5 - 4.0, 0.0)
	# The mouse on one the dialog is not on picks it out, see [method BayArt.draw_key]: a picture of
	# its own.
	var lit := pointed and not here
	var key := (
		"key:%s:%s:%s:%s:%s:%s:%.2f:%s"
		% [seat_key, heading, named, color.to_html(), here, tag, swing, lit]
	)
	var shown_key := seat_key
	var on_hook := hook + Vector2(AROUND, 0.0)
	var shown := [heading, named, color, here, swing, lit]
	var art := BayArt.kept(
		self,
		key,
		whole.size,
		func(on: CanvasItem) -> void: _paint(on, shown_key, on_hook, shown),
		GROUP
	)
	# Until a new picture is drawn, the last one, never nothing.
	if art != null:
		_art = art
	if _art != null:
		_draw_faded(_art, whole)
	elif fades.is_empty():
		_paint(self, seat_key, hook, shown)


## Its picture [param art] over [param whole], in slices between the places its fade turns, each
## fading straight from one to the next, so it fades as the rail does all the way across: one
## stretch of triangles, one draw.
func _draw_faded(art: Texture2D, whole: Rect2) -> void:
	var along := fades
	if along.is_empty():
		along = PackedVector2Array([Vector2(whole.position.x, 1.0), Vector2(whole.end.x, 1.0)])
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i: int in along.size():
		var x := along[i].x
		var u := (x - whole.position.x) / whole.size.x
		var tint := Color(1, 1, 1, along[i].y)
		points.append_array([Vector2(x, whole.position.y), Vector2(x, whole.end.y)])
		colors.append_array([tint, tint])
		uvs.append_array([Vector2(u, 0.0), Vector2(u, 1.0)])
		if i > 0:
			var k := i * 2
			indices.append_array([k - 2, k, k + 1, k - 2, k + 1, k - 1])
	RenderingServer.canvas_item_add_triangle_array(
		get_canvas_item(),
		indices,
		points,
		colors,
		uvs,
		PackedInt32Array(),
		PackedFloat32Array(),
		art.get_rid()
	)


static func _paint(on: CanvasItem, is_key: bool, hook: Vector2, shown: Array) -> void:
	if is_key:
		BayArt.draw_key(on, hook, shown[2], shown[0], shown[1], shown[3], shown[4], shown[5])
	else:
		BayArt.draw_profile_tag(on, hook, shown[1], shown[3], shown[4], shown[5])
