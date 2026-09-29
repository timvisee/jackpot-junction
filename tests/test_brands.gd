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


## A Royal Flush pad wears a card suit of its own on its plate, GAME.md 3.9, one of the four a
## flush collects, in its holder's color, and back in nobody's once the claim is gone.
func test_each_flush_pad_wears_a_suit_of_its_own() -> void:
	var suits: Array[int] = []
	for index: int in 4:
		var pad: FlushPad = auto_free(FlushPad.new())
		pad.index = index
		add_child(pad)
		assert_array(pad.find_children("*", "Label3D", true, false)).is_empty()
		var render: SubViewport = pad.get_node("Drawn")
		suits.append((render.get_child(0) as FlushPad.Mark).suit)
		var mark: MeshInstance3D = pad.get_node("Suit")
		var ink: StandardMaterial3D = mark.material_override
		assert_object(ink.albedo_texture).is_same(render.get_texture())
		assert_object(ink.albedo_color).is_equal(FlushPad.NEUTRAL)
		# Flat on the plate, facing up at the camera.
		assert_float(mark.global_basis.z.dot(Vector3.UP)).is_greater(0.99)
		pad.claim(2, Color.RED)
		assert_object(ink.albedo_color).is_equal(Color.RED)
		pad.claim(-1, FlushPad.NEUTRAL)
		assert_object(ink.albedo_color).is_equal(FlushPad.NEUTRAL)
	assert_array(suits).is_equal(
		[SuitArt.Suit.SPADE, SuitArt.Suit.HEART, SuitArt.Suit.DIAMOND, SuitArt.Suit.CLUB]
	)


## Each suit is one shape, its pieces merged, so one drawn see-through, as a suit nobody holds is
## under the clock, shows no piece's edge through another, GAME.md 8.3.
func test_every_suit_is_one_shape() -> void:
	for suit: int in SuitArt.Suit.size():
		var outline := SuitArt.outline(suit)
		assert_int(outline.size()).is_greater(3)
		assert_array(Geometry2D.triangulate_polygon(outline)).is_not_empty()
		for point: Vector2 in outline:
			assert_bool(Rect2(0.0, 0.0, 1.0, 1.0).has_point(point)).is_true()
