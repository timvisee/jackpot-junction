class_name CloseLook
extends CanvasLayer
## A close look at something in the room, put up at the side of the screen: the room's own world
## seen by a camera of its own, shown as the feed off a camera on the floor, see [VideoFeed], in a
## frame of the house's with a title over it and a line under it.
## The room's camera keeps every kart in its shot, so a thing worth seeing up close has a camera
## of its own: the kart on the Showroom's turntable, GAME.md 8.9, see [ShowroomView], and the
## Garage's test bench, GAME.md 9.4, see [BenchView]. What it is filmed from is the one using it's
## to say, by moving [member camera].
##
## Its frame is something laid over the room, so the room's camera keeps the karts out from under
## it the way it does the HUD's, see [HudCovers].

## The group every close look's frame is in, for the room's camera to keep the karts out from
## under, see [HudCovers].
const GROUP := &"close_looks"
## Its layer: over the room, under the HUD's corners and the pause menu.
const LAYER := 4
## How far in from the edge of the screen it stands, in the HUD's units.
const INSET := 36.0
## The bezel the picture is set in, a monitor's: how far it stands out round the picture, its edge's
## width, how round its corners are, its colors and the shadow it throws on the frame, in the HUD's
## units.
const BEZEL := 7.0
const BEZEL_EDGE := 2
const BEZEL_ROUND := 11
const BEZEL_INK := Color(0.09, 0.09, 0.11)
const BEZEL_EDGE_INK := Color(0.26, 0.26, 0.3)
const BEZEL_SHADOW := Color(0.0, 0.0, 0.0, 0.45)
const BEZEL_SHADOW_SIZE := 6
## How long it takes to slide in from its side of the screen and back out, in seconds, and how far
## past the edge it starts and ends.
const SLIDE_IN := 0.38
const SLIDE_OUT := 0.26
const SLIDE_PAST := 40.0
## How smooth the picture is filmed, whatever the screen is: a pipeline of its own for every
## material in the room, which the shader warm-up films too, see [ShaderWarmup].
const SHEET_MSAA := Viewport.MSAA_4X

## The camera the picture is seen by, in the room's world, the title over the picture and the line
## under it, and the feed the picture is shown as, see [VideoFeed].
var camera: Camera3D
var heading: Label
var under: Label
var pane: PanelContainer
var feed: VideoFeed
## Whether it is on its way out, see [method close].
var closing := false

## How far the frame moves to slide off its side of the screen, and where it rests on it.
var _away := 0.0
var _rest := Vector2.ZERO


## Slides it off its side of the screen and frees it.
func close() -> void:
	if closing:
		return
	closing = true
	if pane == null:
		queue_free()
		return
	var slide := create_tween().set_parallel()
	slide.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	slide.tween_property(pane, "offset_left", _rest.x + _away, SLIDE_OUT)
	slide.tween_property(pane, "offset_right", _rest.y + _away, SLIDE_OUT)
	slide.chain().tween_callback(queue_free)


## Builds the frame and the picture: [param title] over it, [param line] under it, the picture
## [param pixels] big, the frame [param shown] across and down, at the side [param left] says, a
## camera that sees no further than [param far], and the feed a security camera's for
## [param security]. It slides in from its side.
func _build(
	title: String,
	line: String,
	pixels: Vector2i,
	shown: Vector2,
	left: bool,
	far: float,
	security := false
) -> void:
	layer = LAYER
	pane = MenuTheme.pane()
	pane.name = "Pane"
	pane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pane.add_to_group(GROUP)
	if left:
		pane.set_anchors_preset(Control.PRESET_CENTER_LEFT)
		pane.grow_horizontal = Control.GROW_DIRECTION_END
		pane.offset_left = INSET
		pane.offset_right = INSET + shown.x
	else:
		pane.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		pane.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		pane.offset_right = -INSET
		pane.offset_left = -INSET - shown.x
	pane.grow_vertical = Control.GROW_DIRECTION_BOTH
	pane.offset_top = -shown.y * 0.5
	pane.offset_bottom = shown.y * 0.5
	add_child(pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pane.add_child(column)
	heading = MenuTheme.title(title, Type.HEADING)
	column.add_child(heading)
	var picture := TextureRect.new()
	picture.name = "Picture"
	picture.custom_minimum_size = Vector2(pixels)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sheet := _sheet(pixels, far)
	picture.texture = sheet.get_texture()
	var bezel := _bezel()
	bezel.add_child(picture)
	column.add_child(bezel)
	# Off a camera on the floor rather than a window onto the room.
	feed = VideoFeed.over(picture, sheet, security)
	under = MenuTheme.subtitle(line, Type.LABEL)
	under.name = "Under"
	column.add_child(under)
	_slide_in(left, shown)


## The bezel the picture is set in, a monitor's, so it does not stand against the frame with a
## hard edge: dark, round at its corners, a lighter edge round it, a shadow under it.
func _bezel() -> PanelContainer:
	var bezel := PanelContainer.new()
	bezel.name = "Bezel"
	bezel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var look := StyleBoxFlat.new()
	look.bg_color = BEZEL_INK
	look.border_color = BEZEL_EDGE_INK
	look.set_border_width_all(BEZEL_EDGE)
	look.set_corner_radius_all(BEZEL_ROUND)
	look.set_content_margin_all(BEZEL)
	look.shadow_color = BEZEL_SHADOW
	look.shadow_size = BEZEL_SHADOW_SIZE
	look.anti_aliasing = true
	bezel.add_theme_stylebox_override("panel", look)
	return bezel


## Slides the frame in from off its side of the screen, [param left] or right, [param shown] wide.
func _slide_in(left: bool, shown: Vector2) -> void:
	_rest = Vector2(pane.offset_left, pane.offset_right)
	_away = -(INSET + shown.x + SLIDE_PAST) if left else INSET + shown.x + SLIDE_PAST
	pane.offset_left = _rest.x + _away
	pane.offset_right = _rest.y + _away
	var slide := create_tween().set_parallel()
	slide.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide.tween_property(pane, "offset_left", _rest.x, SLIDE_IN)
	slide.tween_property(pane, "offset_right", _rest.y, SLIDE_IN)


## The picture: the room's own world as it is, seen by [member camera].
func _sheet(pixels: Vector2i, far: float) -> SubViewport:
	var sheet := SubViewport.new()
	sheet.name = "Sheet"
	sheet.size = pixels
	sheet.msaa_3d = SHEET_MSAA
	# Filmed once now and then at the feed's own rate, see [VideoFeed].
	sheet.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(sheet)
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.far = far
	# Moved every frame by the look, not by the physics, so not smoothed between physics steps.
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	# The room as it is, but for the hints hung in it, which are for the room's own camera.
	camera.cull_mask = 0xFFFFF & ~InputHint.WORLD_LAYER
	sheet.add_child(camera)
	return sheet
