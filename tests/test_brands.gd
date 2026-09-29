extends GdUnitTestSuite
## What the things on the floor wear to say what they are, GAME.md 8.3a: pictures drawn on them
## rather than letters over them.


## A joker on the floor is a card printed on both sides with the joker's own picture, with no
## initials hung over it.
func test_a_floor_joker_is_printed_with_its_picture() -> void:
	var card: FloorJoker = auto_free(FloorJoker.new())
	card.joker = load("res://data/jokers/tight_grip.tres")
	add_child(card)
	var visual := card._visual
	assert_array(visual.find_children("*", "Label3D", true, false)).is_empty()
	var render: SubViewport = visual.get_node("Drawn")
	var printed: FloorJoker.Face = render.get_child(0)
	assert_object(printed.joker).is_same(card.joker)
	var faces := visual.find_children("Face*", "MeshInstance3D", true, false)
	assert_int(faces.size()).is_equal(2)
	var ink: StandardMaterial3D = (faces[0] as MeshInstance3D).material_override
	assert_object(ink.albedo_texture).is_same(render.get_texture())
	# One on each side of the card, facing away from each other.
	var front: Vector3 = (faces[0] as Node3D).global_basis.z
	var back: Vector3 = (faces[1] as Node3D).global_basis.z
	assert_float(front.dot(back)).is_less(-0.99)
