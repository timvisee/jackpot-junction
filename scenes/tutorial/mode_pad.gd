class_name ModePad
extends Area3D
## One of the two pads either side of the way into the steering room of the tutorial, GAME.md
## 9.4a: SIMPLE or ADVANCED, a big lit disc with a ring round it and its name over it, cyan for
## the way the player drives now and magenta for the other, and driving onto the other switches
## to it on the spot, the same change the pause menu's switch makes, 4.2.

signal switched(mode: String)

const RADIUS := 1.5
const RING := 0.16
const LIT := Palette.NEON_CYAN
const OTHER := Palette.NEON_MAGENTA
const LABEL_HEIGHT := 2.2

var mode := Settings.DRIVE_SIMPLE

var _disc: StandardMaterial3D
var _ring: StandardMaterial3D


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
	var label := Label3D.new()
	label.text = DrivePicker.WORDS[mode].to_upper()
	label.font_size = 72
	label.outline_size = 16
	label.outline_modulate = Color(0.04, 0.04, 0.05, 0.9)
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0.0, LABEL_HEIGHT, 0.0)
	add_child(label)
	_paint()


func _process(_delta: float) -> void:
	_paint()


func is_lit() -> bool:
	return Game.settings.drive_mode(0) == mode


func _paint() -> void:
	var color := LIT if is_lit() else OTHER
	_disc.albedo_color = color.darkened(0.35)
	_disc.emission = color
	_disc.emission_energy_multiplier = 0.8 if is_lit() else 0.35
	_ring.albedo_color = color
	_ring.emission = color
	_ring.emission_energy_multiplier = 1.4 if is_lit() else 0.7


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
