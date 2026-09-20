class_name Portal
extends Area3D
## A way out of one practice room and into the other, GAME.md 9.4. Driving onto it takes the kart
## through; what is on the other side is the room's business rather than the pad's, so it says
## who drove in and leaves it there.
##
## A ring standing on a lit disc, turning slowly, in the cyan the game uses for anything that
## helps rather than scores. It only answers a kart being driven on this machine: the Garage is
## a room for one player and their friends at the same keyboard, and nothing about it is online.

signal entered(kart: Kart)

const RADIUS := 1.15
const RING_HEIGHT := 1.2
const SPIN_SECONDS := 6.0
## Seconds before the same pad may take anybody through again, so arriving on one does not send
## a kart straight back where it came from.
const COOLDOWN := 1.5

var color := Palette.NEON_CYAN

var _wait := COOLDOWN
var _ring: Node3D


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.KART | Layers.PROTECTED
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = RADIUS * 0.7
	cylinder.height = 2.0
	shape.shape = cylinder
	shape.position = Vector3(0.0, 1.0, 0.0)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	_build()


func _process(delta: float) -> void:
	_wait = maxf(_wait - delta, 0.0)
	_ring.rotate_y(TAU * delta / SPIN_SECONDS)


func _on_body_entered(body: Node3D) -> void:
	var kart := body as Kart
	if kart == null or _wait > 0.0 or not kart.is_active():
		return
	_wait = COOLDOWN
	entered.emit(kart)


func _build() -> void:
	var disc := MeshInstance3D.new()
	var plate := CylinderMesh.new()
	plate.top_radius = RADIUS
	plate.bottom_radius = RADIUS
	plate.height = 0.08
	disc.mesh = plate
	disc.material_override = _glow(0.45)
	disc.position = Vector3(0.0, 0.05, 0.0)
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)
	_ring = Node3D.new()
	_ring.name = "Ring"
	add_child(_ring)
	for i: int in 3:
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.16, RING_HEIGHT, 0.16)
		bar.mesh = box
		bar.material_override = _glow(0.9)
		var angle := TAU * i / 3.0
		bar.position = Vector3(
			cos(angle) * RADIUS * 0.8, RING_HEIGHT * 0.5, sin(angle) * RADIUS * 0.8
		)
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ring.add_child(bar)
	var cap := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS * 0.68
	torus.outer_radius = RADIUS * 0.88
	cap.mesh = torus
	cap.material_override = _glow(0.8)
	cap.position = Vector3(0.0, RING_HEIGHT, 0.0)
	cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.add_child(cap)


func _glow(alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, alpha)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material
