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


## A Royal Flush pad wears a crown on its plate rather than a card letter, in its holder's color,
## and back in nobody's once the claim is gone.
func test_a_flush_pad_wears_a_crown_in_its_holders_color() -> void:
	var pad: FlushPad = auto_free(FlushPad.new())
	add_child(pad)
	assert_array(pad.find_children("*", "Label3D", true, false)).is_empty()
	var crown: MeshInstance3D = pad.get_node("Crown")
	var ink: StandardMaterial3D = crown.material_override
	assert_object(ink.albedo_texture).is_same((pad.get_node("Drawn") as SubViewport).get_texture())
	assert_object(ink.albedo_color).is_equal(FlushPad.NEUTRAL)
	# Flat on the plate, facing up at the camera.
	assert_float(crown.global_basis.z.dot(Vector3.UP)).is_greater(0.99)
	pad.claim(2, Color.RED)
	assert_object(ink.albedo_color).is_equal(Color.RED)
	pad.claim(-1, FlushPad.NEUTRAL)
	assert_object(ink.albedo_color).is_equal(FlushPad.NEUTRAL)
