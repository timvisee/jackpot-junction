class_name MultDie
extends Pickup
## A die that adds to the mult when picked up, GAME.md 3.3.

var amount := 1.0


func _build_visual(parent: Node3D) -> void:
	var cube := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * 0.4
	cube.mesh = mesh
	cube.material_override = _unshaded(Palette.CHIP_WHITE)
	cube.rotation_degrees = Vector3(35.0, 0.0, 45.0)
	parent.add_child(cube)
	var dot := MeshInstance3D.new()
	var dot_mesh := SphereMesh.new()
	dot_mesh.radius = 0.07
	dot_mesh.height = 0.14
	dot.mesh = dot_mesh
	dot.material_override = _unshaded(Color(0.1, 0.1, 0.12))
	dot.position = Vector3(0.0, 0.3, 0.0)
	parent.add_child(dot)
	hover = 0.45


func _apply(kart: Kart) -> void:
	kart.gain_mult(amount, &"die")
