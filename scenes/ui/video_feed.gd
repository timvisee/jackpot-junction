class_name VideoFeed
extends Control
## A close look's picture made a feed off a camera on the floor, GAME.md 8.9 and 9.4, see
## [CloseLook]: drawn through video_feed.gdshader, scanlines, grain, darker corners and a tear now
## and then, and laid over with a viewfinder's marks, white brackets in its corners, a red dot by
## REC blinking in one, the time it has been running in another and which camera it is in a third.
## A cut to another shot is the picture tearing for a moment and the camera's number changing.
##
## Laid over the picture as a child of it, the whole of it.

const SHADER: Shader = preload("res://scenes/ui/video_feed.gdshader")
## The brackets: how far in from the picture's edges, how long each arm, how thick, and their ink.
const INSET := 14.0
const ARM := 22.0
const THICK := 2.5
const INK := Color(1.0, 1.0, 1.0, 0.85)
## The dot: how big, its red, and how long it is lit and dark in each blink.
const DOT := 6.0
const DOT_INK := Color(0.95, 0.15, 0.12)
const LIT_FOR := 0.6
const DARK_FOR := 0.4
## The words' size, and how far in from the brackets' corners they stand.
const WORDS := Type.SMALL
const WORDS_IN := Vector2(14.0, 10.0)
## How many frames a second the time counts, as a camera's does.
const FRAMES := 30
## A tear now and then: how many seconds apart at the least and most, and how long one lasts at
## the least and most. A cut tears it at full strength for [constant CUT_TEAR] seconds.
const TEARS := Vector2(3.5, 8.0)
const TEAR_FOR := Vector2(0.08, 0.22)
const TEAR_STRENGTH := Vector2(0.35, 0.8)
const CUT_TEAR := 0.18

## How long the feed has been running, and the camera it is off.
var running := 0.0
var camera := 1

var _look: ShaderMaterial
var _rec: Label
var _time: Label
var _cam: Label
var _dice := RandomNumberGenerator.new()
var _next_tear := 0.0
var _tear_left := 0.0
var _tear_strength := 0.0


## The feed over [param picture], drawing the picture through its look.
static func over(picture: TextureRect) -> VideoFeed:
	var feed := VideoFeed.new()
	feed.name = "Feed"
	feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feed.set_anchors_preset(Control.PRESET_FULL_RECT)
	feed._look = look()
	picture.material = feed._look
	picture.add_child(feed)
	return feed


## The look a feed's picture is drawn through.
static func look() -> ShaderMaterial:
	var made := ShaderMaterial.new()
	made.shader = SHADER
	return made


func _ready() -> void:
	_dice.randomize()
	_next_tear = _dice.randf_range(TEARS.x, TEARS.y)
	_rec = _words("REC", HORIZONTAL_ALIGNMENT_LEFT)
	_rec.position = Vector2(INSET, INSET) + WORDS_IN + Vector2(DOT * 2.0 + 6.0, -2.0)
	_time = _words("", HORIZONTAL_ALIGNMENT_RIGHT)
	_cam = _words("", HORIZONTAL_ALIGNMENT_LEFT)
	_say()


## A cut to another shot, off camera [param number]: the picture torn for a moment.
func cut(number: int) -> void:
	camera = number
	_tear(1.0, CUT_TEAR)
	_say()


func _process(delta: float) -> void:
	running += delta
	_next_tear -= delta
	if _next_tear <= 0.0:
		_next_tear = _dice.randf_range(TEARS.x, TEARS.y)
		var strength := _dice.randf_range(TEAR_STRENGTH.x, TEAR_STRENGTH.y)
		_tear(strength, _dice.randf_range(TEAR_FOR.x, TEAR_FOR.y))
	_tear_left = maxf(_tear_left - delta, 0.0)
	_look.set_shader_parameter(&"tear", _tear_strength if _tear_left > 0.0 else 0.0)
	_say()
	queue_redraw()


func _tear(strength: float, lasting: float) -> void:
	_tear_strength = strength
	_tear_left = lasting
	_look.set_shader_parameter(&"tear_at", _dice.randf_range(0.1, 0.9))


## The words in their corners: the time running at the top right, the camera at the foot.
func _say() -> void:
	if _time == null:
		return
	var seconds := floori(running)
	var frame := int(running * FRAMES) % FRAMES
	_time.text = (
		"%02d:%02d:%02d:%02d"
		% [floori(seconds / 3600.0), floori(seconds / 60.0) % 60, seconds % 60, frame]
	)
	_time.position = Vector2(size.x - INSET - WORDS_IN.x - _time.size.x, INSET + WORDS_IN.y - 2.0)
	_cam.text = "CAM %d" % camera
	_cam.position = Vector2(INSET + WORDS_IN.x, size.y - INSET - WORDS_IN.y - _cam.size.y)


func _words(text: String, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.numbers(label, WORDS, INK)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.6))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	return label


## The brackets in the corners, and the dot while it is lit.
func _draw() -> void:
	var box := Rect2(Vector2.ONE * INSET, size - Vector2.ONE * INSET * 2.0)
	for corner: Vector2 in [
		box.position,
		Vector2(box.end.x, box.position.y),
		box.end,
		Vector2(box.position.x, box.end.y)
	]:
		var inward := (box.get_center() - corner).sign()
		draw_line(corner, corner + Vector2(inward.x * ARM, 0.0), INK, THICK)
		draw_line(corner, corner + Vector2(0.0, inward.y * ARM), INK, THICK)
	if fmod(running, LIT_FOR + DARK_FOR) < LIT_FOR:
		var at := box.position + WORDS_IN + Vector2(DOT, DOT + 2.0)
		draw_circle(at, DOT, DOT_INK)
