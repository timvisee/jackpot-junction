class_name ModePad
extends Area3D
## The pad beside the way into the steering room of the tutorial, GAME.md 9.4a: a big lit disc with
## the way the player drives now drawn on it, the picture the title's question draws, its name under
## the picture on the face, a ring round it and a run of lamps chasing round that. Driving onto it
## does not switch anything on the spot, which a kart wandered onto a pad could do by accident;
## instead it puts up the same question the title asks, see [DriveChoice], to choose from, 4.2. The
## pad stays for the rest of the tutorial: there is no reason to take it away.

## The kart has driven onto the pad, for the way of driving to be chosen; fired once until the kart
## leaves and comes back, so sitting on it does not ask over and over.
signal stepped

const RADIUS := 1.5
const RING := 0.14
const LIT := Palette.NEON_CYAN
## The face: how many pixels it is drawn at, how many meters it spans, and where on it the
## picture and the name go.
const PICTURE_PIXELS := 256
const PICTURE_SPAN := 2.0
const ICON_SIDE := 140.0
const ICON_TOP := 22.0
const WORD_TOP := 172.0
## The lamps round the ring: how many, how big, and how fast the lit one runs round.
const LAMPS := 10
const LAMP_RADIUS := 0.09
const CHASE := 0.5

var _disc: StandardMaterial3D
var _ring: StandardMaterial3D
var _picture: StandardMaterial3D
var _lamps: Array[StandardMaterial3D] = []
var _viewport: SubViewport
var _label: Label
var _icon: Control
## Which way of driving the face shows now, to redraw it when the player changes it; and whether the
## kart is off the pad, so stepping on asks once rather than every frame it sits there.
var _shown := ""
var _armed := true
var _time := 0.0


static func add_to(parent: Node, at: Vector3) -> ModePad:
	var pad := ModePad.new()
	pad.name = "ModePad"
	pad.position = at
	parent.add_child(pad)
	return pad


## The way the player drives now, which the pad shows and the question it puts up starts on.
func mode() -> String:
	return Game.settings.drive_mode(0)


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
	body_exited.connect(_on_body_exited)
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
	_paint()


## The face's viewport and the name on it, drawn by a viewport of its own; the picture of the way
## of driving is laid on in [method _draw_face], once now and again whenever the player changes it.
func _add_picture() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "Picture"
	_viewport.transparent_bg = true
	_viewport.disable_3d = true
	_viewport.gui_disable_input = true
	_viewport.size = Vector2i(PICTURE_PIXELS, PICTURE_PIXELS)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_viewport)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(0.0, WORD_TOP)
	_label.size = Vector2(PICTURE_PIXELS, PICTURE_PIXELS - WORD_TOP)
	Type.strong(_label, 40, Palette.CHIP_WHITE)
	_viewport.add_child(_label)
	_draw_face()
	var face := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * PICTURE_SPAN
	face.mesh = quad
	_picture = StandardMaterial3D.new()
	_picture.albedo_texture = _viewport.get_texture()
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


## The picture of the way of driving now laid on the face, its name under it, the one shown before
## cleared off; the viewport drawn again to take it.
func _draw_face() -> void:
	_shown = mode()
	if _icon != null and is_instance_valid(_icon):
		_icon.queue_free()
	_icon = DriveArt.picture(_shown, Palette.CHIP_WHITE, ICON_SIDE)
	_icon.position = Vector2((PICTURE_PIXELS - ICON_SIDE) * 0.5, ICON_TOP)
	_viewport.add_child(_icon)
	_label.text = DrivePicker.WORDS[_shown].to_upper()
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## Always lit cyan, the one control it is: the disc and ring glow, the lamps chase, the name is in
## white; the face redrawn when the player has changed the way they drive.
func _paint() -> void:
	_disc.albedo_color = LIT.darkened(0.55)
	_disc.emission = LIT
	_disc.emission_energy_multiplier = 0.5
	_ring.albedo_color = LIT
	_ring.emission = LIT
	_ring.emission_energy_multiplier = 1.4
	_picture.albedo_color = Color.WHITE
	if _shown != mode():
		_draw_face()
	var head := fmod(_time * CHASE, 1.0) * LAMPS
	for i: int in _lamps.size():
		var behind := fmod(head - i + LAMPS, LAMPS)
		var glow := clampf(1.0 - behind / 3.0, 0.0, 1.0)
		_lamps[i].albedo_color = LIT.darkened(0.6)
		_lamps[i].emission = LIT
		_lamps[i].emission_energy_multiplier = 0.2 + 2.2 * glow


## The kart onto the pad: the way of driving is chosen, see [signal stepped], once until it leaves,
## not switched on the spot, so a kart that wandered on does not change it by itself.
func _on_body_entered(body: Node3D) -> void:
	if not _armed or (body as Kart) == null:
		return
	_armed = false
	Audio.play_sfx(&"ready", -6.0, 0.0)
	stepped.emit()


## Off the pad: driving back onto it may ask again.
func _on_body_exited(body: Node3D) -> void:
	if (body as Kart) != null:
		_armed = true
