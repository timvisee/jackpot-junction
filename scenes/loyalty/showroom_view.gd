class_name ShowroomView
extends CanvasLayer
## The close look at a kart on the Showroom's turntable, GAME.md 8.9, see [Showroom]: the kart in
## its color, its dress and its plate, turning slowly round under the Showroom's lamp in a frame of
## the house's at the side of the screen, as the license's photo is drawn, with what it is dressed
## in under it. Up while the kart stands on the turntable.

## The picture, how long the kart takes to turn once, and its frame's layer: over the room, under
## the HUD's corners and the pause menu.
const PIXELS := Vector2i(560, 380)
const SPIN := 9.0
const LAYER := 4
const TITLE := "THE SHOWROOM"
const SHOWN := Vector2(600.0, 520.0)
const RIGHT := 36.0

var kart: Kart

var _model: Node3D
var _pane: PanelContainer


## The look at [param on_it], the kart on the turntable.
static func of(on_it: Kart) -> ShowroomView:
	var view := ShowroomView.new()
	view.name = "ShowroomView"
	view.kart = on_it
	return view


func _ready() -> void:
	layer = LAYER
	_pane = MenuTheme.pane()
	_pane.name = "Pane"
	_pane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pane.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_pane.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_pane.grow_vertical = Control.GROW_DIRECTION_BOTH
	_pane.offset_right = -RIGHT
	_pane.offset_left = -RIGHT - SHOWN.x
	_pane.offset_top = -SHOWN.y * 0.5
	_pane.offset_bottom = SHOWN.y * 0.5
	add_child(_pane)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pane.add_child(column)
	var title := MenuTheme.title(TITLE, Type.HEADING)
	column.add_child(title)
	var picture := TextureRect.new()
	picture.name = "Picture"
	picture.custom_minimum_size = Vector2(PIXELS)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.texture = _sheet().get_texture()
	column.add_child(picture)
	var worn := MenuTheme.subtitle(worn_words(kart.style), Type.LABEL)
	worn.name = "Worn"
	column.add_child(worn)
	MenuTheme.deal(_pane)


## What [param style] dresses a kart in, a part each, the plain parts left out: the paint, the hat,
## the flag, the trail, the plate and the tire marks.
static func worn_words(style: KartStyle) -> String:
	var said := PackedStringArray()
	var chosen: Array[int] = [
		style.paint, style.hat, style.flag, style.trail, style.frame, style.marks
	]
	for part: int in chosen.size():
		if chosen[part] > 0:
			said.append(str(KartStyle.CHOICES[part][chosen[part]]))
	return "  ·  ".join(said) if not said.is_empty() else "As it came off the line"


## The picture's own world: the kart in it, its plate on, a lamp and the camera close in.
func _sheet() -> SubViewport:
	var sheet := SubViewport.new()
	sheet.name = "Sheet"
	sheet.size = PIXELS
	sheet.own_world_3d = true
	sheet.msaa_3d = Viewport.MSAA_4X
	sheet.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var world := World3D.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = LicenseCard.PHOTO_BACK
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.62, 0.7)
	world.environment = environment
	sheet.world_3d = world
	add_child(sheet)
	_model = KartVisuals.display_model(kart.color_index, kart.style)
	_model.position.y = -0.3
	sheet.add_child(_model)
	var player := kart.input as PlayerInput
	var plate := Game.settings.seat_plate(player.seat) if player != null else ""
	KartVisuals.plate_like(_model, plate if not plate.is_empty() else "L")
	var camera := Camera3D.new()
	camera.fov = 32.0
	camera.look_at_from_position(Vector3(0.0, 1.6, 3.6), Vector3(0.0, 0.75, 0.0), Vector3.UP)
	sheet.add_child(camera)
	var light := DirectionalLight3D.new()
	light.light_energy = 1.2
	light.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	sheet.add_child(light)
	return sheet


func _process(delta: float) -> void:
	if _model != null:
		_model.rotation.y += TAU / SPIN * delta
