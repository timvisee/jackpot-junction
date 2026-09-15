extends Node3D
## Development harness: a bare table with a light and a camera to load work in progress into.

const TABLE_SIZE := Vector2(40.0, 22.5)


func _ready() -> void:
	_add_table()
	_add_light()
	_add_camera()


func _add_table() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = TABLE_SIZE
	var material := StandardMaterial3D.new()
	material.albedo_color = Palette.FELT
	mesh.material = material
	var table := MeshInstance3D.new()
	table.name = "Table"
	table.mesh = mesh
	add_child(table)


func _add_light() -> void:
	var light := DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	light.shadow_enabled = true
	add_child(light)


func _add_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.fov = 35.0
	camera.position = Vector3(0.0, 28.0, 20.0)
	camera.look_at_from_position(camera.position, Vector3.ZERO, Vector3.UP)
	add_child(camera)
	camera.make_current()
