class_name ItemBox
extends Pickup
## A power-up on the floor. From a pad it holds a whole table and decides the item when taken,
## like a roulette; dropped on death it holds one fixed item. Karts already holding an item
## cannot take it.

var table: PowerUpTable
var fixed_item: PowerUp
var rng: RandomNumberGenerator
var reveal_time := 0.5


func can_collect(kart: Kart) -> bool:
	return kart.held_item == null


func _build_visual(parent: Node3D) -> void:
	var cube := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * 0.55
	cube.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = fixed_item.color if fixed_item != null else Palette.NEON_MAGENTA
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 0.6
	cube.material_override = material
	cube.rotation_degrees = Vector3(20.0, 0.0, 20.0)
	parent.add_child(cube)
	var mark := Label3D.new()
	mark.text = "?" if fixed_item == null else fixed_item.display_name.left(1)
	mark.font_size = 64
	mark.pixel_size = 0.01
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.position = Vector3(0.0, 0.6, 0.0)
	parent.add_child(mark)
	parent.position.y = 0.5


func _apply(kart: Kart) -> void:
	var item := fixed_item if fixed_item != null else table.pick(rng)
	kart.hold_item(item, reveal_time if fixed_item == null else 0.0)
