class_name TrafficLight
extends Node3D
## A lamp on a pole beside a target in the tutorial's gallery, GAME.md 9.4a, the pole the Jackpot
## zones of 3.5 wear: dark until the target has been hit and counted, and green after, so the
## targets still to do can be told from the ones done at a glance from across the room.

const POLE_HEIGHT := 1.5
const POLE_RADIUS := 0.05
const LAMP_RADIUS := 0.17
const GREEN := Color(0.2, 0.9, 0.35)
## How bright the lamp is off and on.
const OFF := 0.05
const ON := 2.2

var green := false

var _lamp: StandardMaterial3D


static func add_to(parent: Node, at: Vector3) -> TrafficLight:
	var light := TrafficLight.new()
	light.name = "TrafficLight"
	light.position = at
	parent.add_child(light)
	return light


func _ready() -> void:
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = POLE_RADIUS
	pole_mesh.bottom_radius = POLE_RADIUS
	pole_mesh.height = POLE_HEIGHT
	pole_mesh.radial_segments = 8
	pole_mesh.rings = 1
	pole.mesh = pole_mesh
	var pole_material := StandardMaterial3D.new()
	pole_material.albedo_color = Color(0.2, 0.2, 0.22)
	pole.material_override = pole_material
	pole.position = Vector3(0.0, POLE_HEIGHT * 0.5, 0.0)
	add_child(pole)
	var lamp := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = LAMP_RADIUS
	sphere.height = LAMP_RADIUS * 2.0
	# A bulb the size of a fist: twelve segments round it, not sixty-four, GAME.md 10.7.
	sphere.radial_segments = 12
	sphere.rings = 6
	lamp.mesh = sphere
	_lamp = StandardMaterial3D.new()
	_lamp.emission_enabled = true
	_lamp.emission = GREEN
	_lamp.albedo_color = GREEN.darkened(0.7)
	lamp.material_override = _lamp
	lamp.position = Vector3(0.0, POLE_HEIGHT + LAMP_RADIUS * 0.6, 0.0)
	add_child(lamp)
	_paint()


## The target beside it has been counted.
func set_green() -> void:
	green = true
	_paint()


func _paint() -> void:
	_lamp.emission_energy_multiplier = ON if green else OFF
	_lamp.albedo_color = GREEN.darkened(0.2) if green else GREEN.darkened(0.7)
