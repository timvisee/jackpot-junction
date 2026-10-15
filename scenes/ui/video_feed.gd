class_name VideoFeed
extends Control
## A close look's picture made a feed off a camera on the floor, GAME.md 8.9 and 9.4, see
## [CloseLook]: drawn through video_feed.gdshader, scanlines, grain, darker corners and a tear now
## and then, and laid over with a viewfinder's marks, white brackets in its corners, a red dot by
## REC blinking in one, the time it has been running in another and which camera it is in a third.
## It comes on in a burst of snow and a flash, its focus hunting, and a cut to another shot is a
## shorter burst and the camera's number changing. A feed may be a security camera's, tinted green.
##
## Laid over the picture as a child of it, the whole of it. It runs at a camera's thirty frames a
## second, see [constant FRAMES]: the picture under it is filmed again only that often, half the
## cost of filming it every frame of a sixty, GAME.md 10.7.

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
## A tear now and then: how many seconds apart at the least and most, how long one lasts at the
## least and most, how strong a light one is, and how often one is a strong one instead, and how
## strong; a jolt, for something worth it, is the strongest and longest.
const TEARS := Vector2(3.5, 8.0)
const TEAR_FOR := Vector2(0.08, 0.2)
const TEAR_LIGHT := Vector2(0.2, 0.42)
const STRONG_CHANCE := 0.15
const TEAR_STRONG := 0.8
const JOLT := 1.0
const JOLT_FOR := 0.35
## Coming on: how long the snow takes to clear and how bright the flash is, and the focus hunting,
## in and out of focus at these times, in seconds, to sharp. A cut is a shorter burst of snow.
const ON_SNOW := 0.4
const ON_FLASH := 0.55
const FLASH_FOR := 0.16
const HUNT: Array[Vector2] = [
	Vector2(0.0, 1.0), Vector2(0.25, 0.15), Vector2(0.4, 0.55), Vector2(0.65, 0.0)
]
const CUT_SNOW := 0.7
const CUT_SNOW_FOR := 0.14
const CUT_FLASH := 0.3
## A security camera's tint, how much of it.
const SECURITY := 0.18
## How round the picture's corners are, in its pixels, for the bezel round it to show.
const CORNER := 7.0

## How long the feed has been running, and the camera it is off.
var running := 0.0
var camera := 1

var _look: ShaderMaterial
var _sheet: SubViewport
## How long since the picture was last filmed.
var _since_filmed := 0.0
var _rec: Label
var _time: Label
var _cam: Label
var _dice := RandomNumberGenerator.new()
var _next_tear := 0.0
var _tear_left := 0.0
var _tear_strength := 0.0
var _snow_left := 0.0
var _snow_for := 1.0
var _snow := 0.0
var _flash_left := 0.0
var _flash := 0.0


## The feed over [param picture], drawing the picture through its look, tinted as a security
## camera's for [param security], and filming [param sheet], the picture's, at its own rate.
static func over(picture: TextureRect, sheet: SubViewport, security := false) -> VideoFeed:
	var feed := VideoFeed.new()
	feed._sheet = sheet
	feed.name = "Feed"
	feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feed.set_anchors_preset(Control.PRESET_FULL_RECT)
	feed._look = look()
	feed._look.set_shader_parameter(&"tint", SECURITY if security else 0.0)
	feed._look.set_shader_parameter(&"corner", CORNER)
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
	# Coming on: snow clearing, a flash, the focus hunting.
	_burst(1.0, ON_SNOW, ON_FLASH)
	_step(0.0)


## A cut to another shot, off camera [param number]: a moment's snow and the picture torn.
func cut(number: int) -> void:
	camera = number
	_tear(TEAR_STRONG, CUT_SNOW_FOR)
	_burst(CUT_SNOW, CUT_SNOW_FOR, CUT_FLASH)
	_say()


## Something worth it seen, a new best: the picture torn hard for a moment.
func jolt() -> void:
	_tear(JOLT, JOLT_FOR)


func _process(delta: float) -> void:
	_step(delta)


func _step(delta: float) -> void:
	running += delta
	_film(delta)
	_next_tear -= delta
	if _next_tear <= 0.0:
		_next_tear = _dice.randf_range(TEARS.x, TEARS.y)
		var strong := _dice.randf() < STRONG_CHANCE
		var strength := TEAR_STRONG if strong else _dice.randf_range(TEAR_LIGHT.x, TEAR_LIGHT.y)
		_tear(strength, _dice.randf_range(TEAR_FOR.x, TEAR_FOR.y))
	_tear_left = maxf(_tear_left - delta, 0.0)
	_snow_left = maxf(_snow_left - delta, 0.0)
	_flash_left = maxf(_flash_left - delta, 0.0)
	_look.set_shader_parameter(&"tear", _tear_strength if _tear_left > 0.0 else 0.0)
	_look.set_shader_parameter(&"snow", _snow * _snow_left / _snow_for)
	_look.set_shader_parameter(&"flash", _flash * _flash_left / FLASH_FOR)
	_look.set_shader_parameter(&"blur", focus(running))
	var picture := get_parent() as Control
	if picture != null:
		_look.set_shader_parameter(&"pixels", picture.size)
	_say()
	queue_redraw()


## Has the picture filmed again once a camera's frame has gone by since it last was.
func _film(delta: float) -> void:
	if _sheet == null:
		return
	_since_filmed += delta
	if _since_filmed < 1.0 / FRAMES:
		return
	_since_filmed = fmod(_since_filmed, 1.0 / FRAMES)
	_sheet.render_target_update_mode = SubViewport.UPDATE_ONCE


## How far out of focus the feed is [param at] seconds after it came on, the focus hunting in and
## out before it settles sharp.
static func focus(at: float) -> float:
	for i: int in range(1, HUNT.size()):
		if at < HUNT[i].x:
			var from: Vector2 = HUNT[i - 1]
			var to: Vector2 = HUNT[i]
			return lerpf(from.y, to.y, smoothstep(from.x, to.x, at))
	return 0.0


func _tear(strength: float, lasting: float) -> void:
	_tear_strength = strength
	_tear_left = lasting
	_look.set_shader_parameter(&"tear_at", _dice.randf_range(0.1, 0.9))


func _burst(snow: float, lasting: float, flash: float) -> void:
	_snow = snow
	_snow_left = lasting
	_snow_for = lasting
	_flash = flash
	_flash_left = FLASH_FOR


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
