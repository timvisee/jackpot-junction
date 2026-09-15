class_name Chip
extends Pickup
## A poker chip worth [member value] coins. Gold chips are worth more; dropped chips come from
## deaths, vanish after a while and count differently for some jokers.

var value := 1
var gold := false
var dropped := false


func _build_visual(parent: Node3D) -> void:
	var disc := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.34 if gold else 0.28
	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.1
	disc.mesh = mesh
	disc.material_override = _unshaded(Palette.CHIP_GOLD if gold else Palette.CHIP_RED)
	disc.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	parent.add_child(disc)
	var stripe := MeshInstance3D.new()
	var stripe_mesh := CylinderMesh.new()
	stripe_mesh.top_radius = mesh.top_radius * 0.55
	stripe_mesh.bottom_radius = stripe_mesh.top_radius
	stripe_mesh.height = 0.11
	stripe.mesh = stripe_mesh
	stripe.material_override = _unshaded(Palette.CHIP_WHITE)
	stripe.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	parent.add_child(stripe)
	parent.position.y = 0.35


func _apply(kart: Kart) -> void:
	kart.collect_coins(value, self)
