class_name CloseLook
extends CanvasLayer
## A close look at something in the room, put up at the side of the screen: the room's own world
## seen by a camera of its own, in a frame of the house's with a title over it and a line under it.
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

## The camera the picture is seen by, in the room's world, the title over the picture and the line
## under it.
var camera: Camera3D
var heading: Label
var under: Label
var pane: PanelContainer


## Builds the frame and the picture: [param title] over it, [param line] under it, the picture
## [param pixels] big, the frame [param shown] across and down, at the side [param left] says, and
## a camera that sees no further than [param far].
func _build(
	title: String, line: String, pixels: Vector2i, shown: Vector2, left: bool, far: float
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
	picture.texture = _sheet(pixels, far).get_texture()
	column.add_child(picture)
	under = MenuTheme.subtitle(line, Type.LABEL)
	under.name = "Under"
	column.add_child(under)
	MenuTheme.deal(pane)


## The picture: the room's own world as it is, seen by [member camera].
func _sheet(pixels: Vector2i, far: float) -> SubViewport:
	var sheet := SubViewport.new()
	sheet.name = "Sheet"
	sheet.size = pixels
	sheet.msaa_3d = Viewport.MSAA_4X
	sheet.render_target_update_mode = SubViewport.UPDATE_ALWAYS
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
