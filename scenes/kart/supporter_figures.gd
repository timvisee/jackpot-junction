class_name SupporterFigures
extends RefCounted
## The supporter pack's hats of character, GAME.md 10.8, built as the rest of its dress is, see
## [SupporterDress]: the House of cards, its cards drawn in one [MultiMesh], and what moves it,
## [HouseOfCards].

## The cards the house is built of, its face and its back.
const CARD_FACE := preload("res://assets/textures/card_hearts.png")
const CARD_BACK := preload("res://assets/textures/card_back.png")

## A card's face and its back side by side, made once, see [method _card_sides].
static var _sides: ImageTexture


## The house of cards on [param worn]: up to [constant HouseOfCards.MOST_CARDS] cards in one
## [MultiMesh], each its face one side and the house's back the other, stood in storeys by
## [HouseOfCards].
static func house_of_cards(worn: Node3D) -> void:
	var cards := MultiMeshInstance3D.new()
	cards.name = "Cards"
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = _card()
	many.instance_count = HouseOfCards.MOST_CARDS
	many.visible_instance_count = 0
	cards.multimesh = many
	var paper := SupporterDress.flat(Color.WHITE)
	paper.albedo_texture = _card_sides()
	cards.material_override = paper
	worn.add_child(cards)
	var house := HouseOfCards.new()
	house.name = "Stand"
	house.cards = cards
	worn.add_child(house)


## A playing card, [constant HouseOfCards.CARD] big: its face one side and its back the other, each
## half of the picture [method _card_sides] makes.
static func _card() -> ArrayMesh:
	var half := HouseOfCards.CARD * 0.5
	var cut := SurfaceTool.new()
	cut.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in [1.0, -1.0]:
		var u0 := 0.0 if side > 0.0 else 0.5
		var corners := [
			[Vector3(-half.x * side, -half.y, 0.0), Vector2(u0, 1.0)],
			[Vector3(half.x * side, -half.y, 0.0), Vector2(u0 + 0.5, 1.0)],
			[Vector3(half.x * side, half.y, 0.0), Vector2(u0 + 0.5, 0.0)],
			[Vector3(-half.x * side, half.y, 0.0), Vector2(u0, 0.0)],
		]
		for at: int in [0, 1, 2, 0, 2, 3]:
			cut.set_normal(Vector3(0.0, 0.0, side))
			cut.set_uv(corners[at][1])
			cut.add_vertex(corners[at][0] + Vector3(0.0, 0.0, side * 0.002))
	return cut.commit()


## A card's face and its back side by side in one picture, made once.
static func _card_sides() -> ImageTexture:
	if _sides != null:
		return _sides
	var face := CARD_FACE.get_image()
	var back := CARD_BACK.get_image()
	for picture: Image in [face, back]:
		if picture.is_compressed():
			picture.decompress()
		picture.convert(Image.FORMAT_RGBA8)
	back.resize(face.get_width(), face.get_height())
	var both := Image.create(face.get_width() * 2, face.get_height(), false, Image.FORMAT_RGBA8)
	both.blit_rect(face, Rect2i(Vector2i.ZERO, face.get_size()), Vector2i.ZERO)
	both.blit_rect(back, Rect2i(Vector2i.ZERO, back.get_size()), Vector2i(face.get_width(), 0))
	both.generate_mipmaps()
	_sides = ImageTexture.create_from_image(both)
	return _sides
