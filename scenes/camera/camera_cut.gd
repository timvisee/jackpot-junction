class_name CameraCut
extends CanvasLayer
## A cut rather than a swoop, GAME.md 8.2: the one kart driven here coming back out of the picture
## used to take the camera across the arena after it in one long glide, about a second of the whole
## floor sliding by. Now the picture dips to dark over [constant DARKEN] seconds, the camera is put
## where it is going, and the picture comes back over [constant LIGHTEN]. Under the HUD, which
## stays: the clock and the standings do not go anywhere.
##
## Only for a lone kart driven here. With two or more on one screen, the others are being driven
## through it, and a moment of dark is a moment of not seeing where they are going.

## How long the picture takes to go dark and to come back, in seconds.
const DARKEN := 0.1
const LIGHTEN := 0.22
## How far in from the edge of the screen a kart has to come back to count as in the picture, as a
## share of the screen: one at the very edge would take most of a swoop to get to the middle.
const INSIDE := 0.1
## What the picture dips to: the House's ink rather than black, as the menus' shade is.
const DARK := Color(0.05, 0.04, 0.07)

## How dark the picture is just now, 0 to 1.
var dark := 0.0

## Where each kart driven here was last frame, by its instance id: one further from that than any
## kart drives in a frame has come back somewhere else, see [constant FramedSpots.JUMP].
var _last: Dictionary[int, Vector3] = {}
var _darkening := false
var _lightening := false
var _veil: ColorRect


func _ready() -> void:
	# Over the room, under the HUD's layer, see [MatchHud].
	layer = 4
	_veil = ColorRect.new()
	_veil.color = DARK
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.visible = false
	add_child(_veil)


## Steps the cut on by [param delta] seconds, watching [param here], the karts driven here, against
## what [param camera] shows; true on the one frame the picture is dark, when the camera is to be
## put where it is going rather than eased there. [param watching] false, nothing starts a cut.
func follow(here: Array[Node3D], camera: Camera3D, delta: float, watching: bool) -> bool:
	var cut := false
	if _darkening:
		dark = minf(dark + delta / DARKEN, 1.0)
		if dark >= 1.0:
			_darkening = false
			_lightening = true
			cut = true
	elif _lightening:
		dark = maxf(dark - delta / LIGHTEN, 0.0)
		_lightening = dark > 0.0
	var kept: Dictionary[int, Vector3] = {}
	for kart: Node3D in here:
		var id := kart.get_instance_id()
		var at := kart.global_position
		if watching and here.size() == 1 and _last.has(id) and not (_darkening or _lightening):
			var jumped := at.distance_squared_to(_last[id]) > FramedSpots.JUMP * FramedSpots.JUMP
			if jumped and not _in_picture(camera, at):
				_darkening = true
		kept[id] = at
	_last = kept
	_veil.visible = dark > 0.0
	_veil.color.a = dark * dark * (3.0 - 2.0 * dark)
	return cut


## Whether [param at] is in what [param camera] shows, [constant INSIDE] in from its edges.
static func _in_picture(camera: Camera3D, at: Vector3) -> bool:
	if camera == null or camera.is_position_behind(at):
		return false
	var size := camera.get_viewport().get_visible_rect().size
	var inner := Rect2(size * INSIDE, size * (1.0 - INSIDE * 2.0))
	return inner.has_point(camera.unproject_position(at))
