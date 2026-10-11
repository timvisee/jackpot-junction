class_name ShowroomView
extends CanvasLayer
## The close look at a kart on the Showroom's turntable, GAME.md 8.9, see [Showroom]: the bay itself
## and the kart on it, filmed, in a frame of the house's at the side of the screen, with what the
## kart is dressed in under it. The room's own camera has to keep the whole Garage in its shot, so
## this one is the bay's: a camera of its own in the room's world, cutting from shot to shot as a
## car advert does, each held a while and moving, pushing in, craning, tracking, going round, or
## closing in by the lens, the kart turning on the table doing the rest. Up while the kart stands
## on the turntable.

## The picture and its frame's layer: over the room, under the HUD's corners and the pause menu.
const PIXELS := Vector2i(560, 380)
const LAYER := 4
const TITLE := "THE SHOWROOM"
const SHOWN := Vector2(600.0, 520.0)
const RIGHT := 36.0
## How long each shot is held before the cut to the next, long enough to take it in, and how far
## the camera sees, no further than the bay and the Garage through its way in, so the rest of the
## room is not drawn twice.
const SHOT := 6.5
const FAR := 40.0
## What a kart wearing nothing but the plain of everything is said to be, as a dealer says it.
const STANDARD := "Standard trim"
## The shots: where the camera stands, from the middle of the table on the floor, the way in down
## the carpet toward +z and the bay's back wall close behind it, so none stands behind the table;
## how it moves over the shot, along by "drift", round the table by "orbit" from one angle to the
## other, or closer by its lens, from "fov" to "zoom"; and how high on the kart it looks. Every one
## looks at the kart wherever on the table it is and holds all of it, its driver's head too. They
## come in no set order, never the same twice running, the hero first.
const SHOTS: Array[Dictionary] = [
	# Low on a front corner of the table, pushing in.
	{"from": Vector3(3.2, 0.7, 3.2), "drift": Vector3(-0.5, 0.1, -0.5), "fov": 34.0, "at": 0.9},
	# Wide, from the Garage down the carpet through the way in, craning down.
	{"from": Vector3(0.0, 2.2, 7.0), "drift": Vector3(0.0, -0.5, -1.2), "fov": 32.0, "at": 0.6},
	# Side on and low, tracking along it.
	{"from": Vector3(-4.2, 0.8, 0.2), "drift": Vector3(0.0, 0.0, 1.4), "fov": 30.0, "at": 0.75},
	# Closer, at the table's edge, the plate, the hat and the nose going by as it turns.
	{"from": Vector3(1.8, 1.3, 3.2), "drift": Vector3(0.4, 0.0, 0.1), "fov": 30.0, "at": 0.95},
	# From high over the table, its stripes going round under the kart.
	{"from": Vector3(1.4, 5.0, 2.6), "drift": Vector3(-1.2, 0.0, 0.0), "fov": 34.0, "at": 0.3},
	# Round the front of the table the other way to its turning, the kart turning twice as fast.
	{"from": Vector3(0.0, 1.3, 3.8), "orbit": Vector2(0.7, -0.7), "fov": 34.0, "at": 0.75},
	# From the floor, looking up at it, rising.
	{"from": Vector3(-2.0, 0.15, 2.8), "drift": Vector3(0.0, 0.5, 0.0), "fov": 38.0, "at": 0.95},
	# Standing well back, the lens closing in on it.
	{"from": Vector3(4.6, 1.6, 4.2), "fov": 36.0, "zoom": 20.0, "at": 0.75},
]

var kart: Kart
## The turntable the kart stands on, which the shots are laid round.
var table: Node3D
## The shot up now, see [constant SHOTS], and how far into it.
var shot := 0
var _shot_time := 0.0
var _dice := RandomNumberGenerator.new()

var _camera: Camera3D
var _pane: PanelContainer


## The look at [param on_it], the kart on the turntable [param on_table].
static func of(on_it: Kart, on_table: Node3D) -> ShowroomView:
	var view := ShowroomView.new()
	view.name = "ShowroomView"
	view.kart = on_it
	view.table = on_table
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
	return "  ·  ".join(said) if not said.is_empty() else STANDARD


## The picture: the room's own world, the bay and the kart as they are, seen by a camera of its own.
func _sheet() -> SubViewport:
	var sheet := SubViewport.new()
	sheet.name = "Sheet"
	sheet.size = PIXELS
	sheet.msaa_3d = Viewport.MSAA_4X
	sheet.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sheet)
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.far = FAR
	# The room as it is, but for the hints hung in it, which are for the room's own camera.
	_camera.cull_mask = 0xFFFFF & ~InputHint.WORLD_LAYER
	sheet.add_child(_camera)
	_frame()
	return sheet


func _process(delta: float) -> void:
	_shot_time += delta
	if _shot_time >= SHOT:
		_shot_time = fmod(_shot_time, SHOT)
		shot = next_shot(shot, _dice)
	_frame()


## The shot cut to after [param now]: any of the others, drawn with [param dice].
static func next_shot(now: int, dice: RandomNumberGenerator) -> int:
	return (now + 1 + dice.randi_range(0, SHOTS.size() - 2)) % SHOTS.size()


## The camera where the shot up now has it, so far into the shot, eased, looking at the kart.
func _frame() -> void:
	if _camera == null or kart == null or table == null or not is_instance_valid(kart):
		return
	var pose := camera_at(shot, _shot_time / SHOT, table.global_position, _kart_at())
	_camera.fov = pose[2]
	_camera.look_at_from_position(pose[0], pose[1], Vector3.UP)


## Where the camera stands, what it looks at and how wide it sees for shot [param index],
## [param through] of the way through it, round a table whose middle is [param middle] with the kart
## at [param kart_at].
static func camera_at(index: int, through: float, middle: Vector3, kart_at: Vector3) -> Array:
	var taken: Dictionary = SHOTS[index]
	var moved := ease(clampf(through, 0.0, 1.0), -1.6)
	var from: Vector3 = taken["from"]
	from += (taken.get("drift", Vector3.ZERO) as Vector3) * moved
	var orbit: Vector2 = taken.get("orbit", Vector2.ZERO)
	from = from.rotated(Vector3.UP, lerpf(orbit.x, orbit.y, moved))
	var at := Vector3(kart_at.x, middle.y + float(taken["at"]), kart_at.z)
	var fov := lerpf(taken["fov"], taken.get("zoom", taken["fov"]), moved)
	return [middle + from, at, fov]


## Where the kart is drawn now, between the physics steps it moves on.
func _kart_at() -> Vector3:
	return kart.get_global_transform_interpolated().origin
