class_name ItemFlight
extends Node3D
## The taken item box arcing and shrinking into the kart that picked it up, GAME.md 8.3, so it
## is obvious who got the item. Follows the kart while it flies, then vanishes as the roulette
## flicker takes over on the HUD.

const DURATION := 0.4
const ARC := 1.3

var _kart: Kart
var _from := Vector3.ZERO
var _age := 0.0
var _visual: Node3D


static func spawn(parent: Node, from: Vector3, kart: Kart, color: Color) -> ItemFlight:
	var flight := ItemFlight.new()
	flight.name = "ItemFlight"
	flight._kart = kart
	flight._from = Vector3(from.x, 0.65, from.z)
	parent.add_child(flight)
	flight.global_position = flight._from
	flight._build(color)
	return flight


func _ready() -> void:
	add_to_group(&"item_flights")


func _process(delta: float) -> void:
	_age += delta
	var t := clampf(_age / DURATION, 0.0, 1.0)
	var target := _from
	if is_instance_valid(_kart):
		target = _kart.global_position + Vector3(0.0, 0.9, 0.0)
	var glide := 1.0 - pow(1.0 - t, 2.0)
	global_position = _from.lerp(target, glide) + Vector3(0.0, sin(t * PI) * ARC, 0.0)
	scale = Vector3.ONE * (1.0 - 0.7 * t)
	_visual.rotation.y += 9.0 * delta
	if t >= 1.0:
		queue_free()


func _build(color: Color) -> void:
	_visual = Node3D.new()
	_visual.rotation_degrees = Vector3(20.0, 0.0, 20.0)
	add_child(_visual)
	var cube := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * 0.5
	cube.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.4
	cube.material_override = material
	cube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(cube)
	var mark := Label3D.new()
	mark.text = "?"
	mark.font_size = 96
	mark.outline_size = 16
	mark.modulate = Palette.CHIP_WHITE
	mark.outline_modulate = Color(0.05, 0.05, 0.06)
	mark.pixel_size = 0.01
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.no_depth_test = true
	mark.position = Vector3(0.0, 0.45, 0.0)
	add_child(mark)
