class_name FloorJoker
extends Pickup
## A joker lying on the floor after a drop. Anyone with a free slot can take it before it fades.

var joker: Joker


func can_collect(kart: Kart) -> bool:
	return not kart.jokers.is_full() and not kart.is_decoy()


func _build_visual(parent: Node3D) -> void:
	var card := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.5, 0.7, 0.06)
	card.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Palette.CHIP_WHITE
	card.material_override = material
	card.rotation_degrees = Vector3(-20.0, 0.0, 0.0)
	parent.add_child(card)
	var mark := Label3D.new()
	mark.text = joker.initials() if joker != null else "J"
	mark.font_size = 56
	mark.pixel_size = 0.01
	mark.modulate = Palette.NEON_MAGENTA
	mark.outline_size = 8
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.position = Vector3(0.0, 0.75, 0.0)
	parent.add_child(mark)
	parent.position.y = 0.5


func _apply(kart: Kart) -> void:
	kart.jokers.add(joker)
	Events.joker_taken.emit(kart.slot, joker.id)
