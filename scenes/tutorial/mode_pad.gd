class_name ModePad
extends Area3D
## One of the two pads either side of the way into the steering room of the tutorial, GAME.md
## 9.4a: SIMPLE or ADVANCED, a big lit disc with the way of driving's own picture on it, the one
## the title's question draws, a ring round it and a run of lamps chasing round that, and its name
## over it, lit cyan for the way the player drives now and plainly off, gray and unlit, for the
## other, so there is no mistaking which is on. Driving onto the other switches to it on the spot,
## the same change the pause menu's switch makes, 4.2. The pads stay for the rest of the tutorial:
## there is no reason to take them away.

signal switched(mode: String)

const RADIUS := 1.5
const RING := 0.14
const LIT := Palette.NEON_CYAN
const OFF := Color(0.46, 0.47, 0.52)
const OFF_PICTURE := Color(0.62, 0.63, 0.68)
const LABEL_HEIGHT := 2.2
## The picture on the face: how many pixels it is drawn at and how many meters it spans.
const PICTURE_PIXELS := 256
const PICTURE_SPAN := 2.1
## The lamps round the ring: how many, how big, and how fast the lit one runs round.
const LAMPS := 10
const LAMP_RADIUS := 0.09
const CHASE := 0.5

var mode := Settings.DRIVE_SIMPLE

var _disc: StandardMaterial3D
var _ring: StandardMaterial3D
var _picture: StandardMaterial3D
var _lamps: Array[StandardMaterial3D] = []
var _label: Label3D
var _time := 0.0


static func add_to(parent: Node, at: Vector3, for_mode: String) -> ModePad:
	var pad := ModePad.new()
	pad.name = "ModePad_%s" % for_mode
	pad.mode = for_mode
	pad.position = at
	parent.add_child(pad)
	return pad


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.KART | Layers.PROTECTED
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = RADIUS * 0.8
	cylinder.height = 2.0
	shape.shape = cylinder
	shape.position = Vector3(0.0, 1.0, 0.0)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	var disc := MeshInstance3D.new()
	var plate := CylinderMesh.new()
	plate.top_radius = RADIUS
	plate.bottom_radius = RADIUS
	plate.height = 0.08
	plate.radial_segments = 32
	disc.mesh = plate
	_disc = StandardMaterial3D.new()
	_disc.emission_enabled = true
	disc.material_override = _disc
	disc.position = Vector3(0.0, 0.04, 0.0)
	add_child(disc)
	var ring := MeshInstance3D.new()
	var band := TorusMesh.new()
	band.inner_radius = RADIUS + 0.04
	band.outer_radius = RADIUS + 0.04 + RING
	band.rings = 32
	band.ring_segments = 8
	ring.mesh = band
	_ring = StandardMaterial3D.new()
	_ring.emission_enabled = true
	ring.material_override = _ring
	ring.position = Vector3(0.0, 0.06, 0.0)
	add_child(ring)
	_add_picture()
	_add_lamps()
	_label = Label3D.new()
	_label.text = DrivePicker.WORDS[mode].to_upper()
	_label.font_size = 72
	_label.outline_size = 16
	_label.outline_modulate = Color(0.04, 0.04, 0.05, 0.9)
	_label.pixel_size = 0.009
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.position = Vector3(0.0, LABEL_HEIGHT, 0.0)
	add_child(_label)
	_paint()


## The way of driving's own picture, drawn once by a viewport of its own and laid on the face.
func _add_picture() -> void:
	var viewport := SubViewport.new()
	viewport.name = "Picture"
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.gui_disable_input = true
	viewport.size = Vector2i(PICTURE_PIXELS, PICTURE_PIXELS)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var drawn := DriveArt.picture(mode, Palette.CHIP_WHITE, PICTURE_PIXELS * 0.8)
	drawn.position = Vector2.ONE * PICTURE_PIXELS * 0.1
	viewport.add_child(drawn)
	var face := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * PICTURE_SPAN
	face.mesh = quad
	_picture = StandardMaterial3D.new()
	_picture.albedo_texture = viewport.get_texture()
	_picture.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_picture.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_picture.cull_mode = BaseMaterial3D.CULL_DISABLED
	face.material_override = _picture
	face.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	face.position = Vector3(0.0, 0.09, 0.0)
	add_child(face)


## Lamps round the ring, one lit at a time running round it.
func _add_lamps() -> void:
	for i: int in LAMPS:
		var lamp := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = LAMP_RADIUS
		ball.height = LAMP_RADIUS * 2.0
		ball.radial_segments = 10
		ball.rings = 5
		lamp.mesh = ball
		var material := StandardMaterial3D.new()
		material.emission_enabled = true
		lamp.material_override = material
		var angle := TAU * i / LAMPS
		var out := RADIUS + 0.04 + RING * 0.5
		lamp.position = Vector3(cos(angle) * out, 0.12, sin(angle) * out)
		add_child(lamp)
		_lamps.append(material)


func _process(delta: float) -> void:
	_time += delta
	_paint()


func is_lit() -> bool:
	return Game.settings.drive_mode(0) == mode


## Lit: the disc and ring glow cyan, the lamps chase, the name is cyan. Off: gray, no glow, the
## lamps dark and still, the name gray.
func _paint() -> void:
	var lit := is_lit()
	var color := LIT if lit else OFF
	_disc.albedo_color = color.darkened(0.55 if lit else 0.35)
	_disc.emission = color
	_disc.emission_energy_multiplier = 0.5 if lit else 0.0
	_ring.albedo_color = color
	_ring.emission = color
	_ring.emission_energy_multiplier = 1.4 if lit else 0.0
	_picture.albedo_color = Color.WHITE if lit else OFF_PICTURE
	_label.modulate = LIT if lit else OFF
	var head := fmod(_time * CHASE, 1.0) * LAMPS
	for i: int in _lamps.size():
		var behind := fmod(head - i + LAMPS, LAMPS)
		var glow := clampf(1.0 - behind / 3.0, 0.0, 1.0) if lit else 0.0
		_lamps[i].albedo_color = color.darkened(0.6)
		_lamps[i].emission = color
		_lamps[i].emission_energy_multiplier = 0.2 + 2.2 * glow if lit else 0.0


func _on_body_entered(body: Node3D) -> void:
	var kart := body as Kart
	if kart == null or is_lit():
		return
	Game.settings.drive_modes[0] = mode
	Game.settings.save_to_disk()
	Audio.play_sfx(&"ready", -6.0, 0.0)
	FloatingText.spawn(
		get_parent(),
		kart.global_position,
		"%s DRIVING" % DrivePicker.WORDS[mode].to_upper(),
		LIT,
		44,
		1.4
	)
	switched.emit(mode)
