class_name FloorJoker
extends Pickup
## A joker lying on the floor after a drop. Anyone with a free slot can take it before it fades.
## The card is printed on both sides with the joker's own picture, GAME.md 8.3a, on a face like
## the one it has in the hand, so it is known on the floor by the shape it is known by there.

## The card, the face printed on it, how finely the face is drawn and how far back the card leans,
## in degrees: far enough that the camera over the table sees a face whichever way it has spun.
const CARD := Vector3(0.6, 0.84, 0.06)
const FACE := Vector2(0.53, 0.77)
const FACE_PIXELS := Vector2i(132, 192)
const FACE_INK := Color(0.11, 0.11, 0.14)
const LEAN := 40.0

var joker: Joker


func can_collect(kart: Kart) -> bool:
	return super(kart) and not kart.jokers.is_full() and not kart.is_decoy()


func _build_visual(parent: Node3D) -> void:
	var card := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = CARD
	card.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Palette.CHIP_WHITE
	card.material_override = material
	card.rotation_degrees = Vector3(-LEAN, 0.0, 0.0)
	parent.add_child(card)
	var printed := Face.new()
	printed.joker = joker
	var ink := DrawnTexture.decal(DrawnTexture.of(parent, printed, FACE_PIXELS))
	for side: int in 2:
		var face := DrawnTexture.face(FACE, ink)
		face.name = "Face%d" % side
		face.rotation.y = side * PI
		face.position = face.basis.z * (CARD.z * 0.5 + 0.002)
		card.add_child(face)
	hover = 0.55


func _apply(kart: Kart) -> void:
	kart.jokers.add(joker)
	Events.joker_taken.emit(kart.slot, joker.id)


## The face printed on the card: the joker's picture in its kind's color on the dark of a card in
## the hand, edged in the same color.
class Face:
	extends Control

	var joker: Joker

	func _draw() -> void:
		var color := JokerCard.kind_color(joker) if joker != null else Palette.CHIP_GOLD
		var panel := StyleBoxFlat.new()
		panel.bg_color = FloorJoker.FACE_INK
		panel.set_corner_radius_all(roundi(size.x * 0.1))
		panel.set_border_width_all(roundi(size.x * 0.04))
		panel.border_color = color
		draw_style_box(panel, Rect2(Vector2.ZERO, size))
		var side := size.x * 0.86
		var box := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
		JokerArt.draw_into(self, box, joker.id if joker != null else &"", color)
