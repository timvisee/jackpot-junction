class_name TrafficLight
extends Node3D
## A traffic light beside a target in the tutorial's gallery, GAME.md 9.4a: red until the target
## has been hit and counted, green after, so the five that are still to do can be told from the
## ones that are done at a glance from across the room.

const POST_HEIGHT := 1.0
const POST_SIDE := 0.1
const HOUSING := Vector3(0.28, 0.76, 0.24)
const LAMP_RADIUS := 0.085
const RED := Color("#FF3B30")
const AMBER := Palette.CHIP_GOLD
const GREEN := Color(0.3, 1.0, 0.45)
## How bright a lamp that is off still is, so the three can be seen to be three.
const OFF := 0.08
const ON := 1.5

var green := false

var _lamps: Array[StandardMaterial3D] = []


static func add_to(parent: Node, at: Vector3) -> TrafficLight:
	var light := TrafficLight.new()
	light.name = "TrafficLight"
	light.position = at
	parent.add_child(light)
	return light


func _ready() -> void:
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.13, 0.13, 0.16)
	dark.metallic = 0.4
	dark.roughness = 0.5
	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(POST_SIDE, POST_HEIGHT, POST_SIDE)
	post.mesh = post_mesh
	post.material_override = dark
	post.position = Vector3(0.0, POST_HEIGHT * 0.5, 0.0)
	add_child(post)
	var housing := MeshInstance3D.new()
	var housing_mesh := BoxMesh.new()
	housing_mesh.size = HOUSING
	housing.mesh = housing_mesh
	housing.material_override = dark
	housing.position = Vector3(0.0, POST_HEIGHT + HOUSING.y * 0.5, 0.0)
	add_child(housing)
	# Three lamps down the front, the front being the side the camera looks at, +Z.
	var colors: Array[Color] = [RED, AMBER, GREEN]
	for i: int in colors.size():
		var lamp := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = LAMP_RADIUS
		ball.height = LAMP_RADIUS * 2.0
		ball.radial_segments = 12
		ball.rings = 6
		lamp.mesh = ball
		var material := StandardMaterial3D.new()
		material.albedo_color = colors[i]
		material.emission_enabled = true
		material.emission = colors[i]
		lamp.material_override = material
		var y := POST_HEIGHT + HOUSING.y - 0.14 - i * 0.24
		lamp.position = Vector3(0.0, y, HOUSING.z * 0.5)
		add_child(lamp)
		_lamps.append(material)
	_paint()


## The target beside it has been counted.
func set_green() -> void:
	green = true
	_paint()


func _paint() -> void:
	var lit: Array[bool] = [not green, false, green]
	for i: int in _lamps.size():
		_lamps[i].emission_energy_multiplier = ON if lit[i] else OFF
