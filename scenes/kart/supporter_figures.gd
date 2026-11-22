class_name SupporterFigures
extends RefCounted
## The supporter pack's hats of character, GAME.md 10.8, built as the rest of its dress is, see
## [SupporterDress]: the House of cards, the Lucky cat and the Tip jar, each of many parts drawn
## in as few draws as can be, its cards and chips each one [MultiMesh] and the cat's body one mesh,
## see [method merged]; and what moves them, [HouseOfCards], [LuckyCat] and [TipJar].

## The cards the house is built of, its face and its back, and the cat's colors: its white, its ink,
## the pink of its ears and paws, its brass bell and its gold coin.
const CARD_FACE := preload("res://assets/textures/card_hearts.png")
const CARD_BACK := preload("res://assets/textures/card_back.png")
const CAT_WHITE := Color(0.97, 0.96, 0.93)
const CAT_INK := Color(0.12, 0.11, 0.12)
const CAT_PINK := Color(0.95, 0.58, 0.62)
const CAT_BRASS := Color(0.85, 0.66, 0.28)
const CAT_SIZE := 0.78
## The tip jar's glass, its tape and the word on it.
const JAR_GLASS := Color(0.75, 0.9, 0.95, 0.24)
const TAPE := Color(0.93, 0.86, 0.62)
const TIPS := "TIPS"

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
	cards.custom_aabb = HouseOfCards.bounds().grow(0.2)
	# Its cards are moved every drawn frame, not every physics step: none of the engine's smoothing
	# between steps, which warns of being stepped outside them.
	cards.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var paper := SupporterDress.flat(Color.WHITE)
	paper.albedo_texture = _card_sides()
	cards.material_override = paper
	worn.add_child(cards)
	var house := HouseOfCards.new()
	house.name = "Stand"
	house.cards = cards
	worn.add_child(house)


## The lucky cat on [param worn], its bib in [param color]: its body, head, ears, face, bib, bell
## and tail one mesh, see [method merged], and its two paws each a mesh of their own, moved by
## [LuckyCat].
static func lucky_cat(worn: Node3D, color: Color) -> void:
	var cat := Node3D.new()
	cat.name = "Cat"
	cat.scale = Vector3.ONE * CAT_SIZE
	worn.add_child(cat)
	var parts: Array = [
		[_ball(0.25, 1.05), Transform3D(Basis(), Vector3(0.0, 0.25, 0.02)), CAT_WHITE],
		[_ball(0.22), Transform3D(Basis(), Vector3(0.0, 0.62, -0.02)), CAT_WHITE],
		[_ball(0.022), Transform3D(Basis(), Vector3(0.0, 0.6, -0.225)), CAT_PINK],
		[_torus(0.13, 0.19), Transform3D(Basis(), Vector3(0.0, 0.43, 0.0)), color],
		[_ball(0.05), Transform3D(Basis(), Vector3(0.0, 0.39, -0.19)), CAT_BRASS],
		[
			_torus(0.16, 0.22),
			Transform3D(Basis(Vector3.UP, deg_to_rad(30.0)), Vector3(0.05, 0.1, 0.15)),
			CAT_WHITE
		],
	]
	for side: float in [-1.0, 1.0]:
		var tipped := Basis(Vector3.BACK, deg_to_rad(side * -18.0))
		parts.append(
			[
				_prism(Vector3(0.13, 0.14, 0.07)),
				Transform3D(tipped, Vector3(side * 0.13, 0.82, -0.02)),
				CAT_WHITE
			]
		)
		parts.append(
			[
				_prism(Vector3(0.07, 0.08, 0.02)),
				Transform3D(tipped, Vector3(side * 0.13, 0.81, -0.06)),
				CAT_PINK
			]
		)
		parts.append(
			[
				_box(Vector3(0.07, 0.016, 0.02)),
				Transform3D(
					Basis(Vector3.BACK, deg_to_rad(side * 12.0)), Vector3(side * 0.08, 0.66, -0.225)
				),
				CAT_INK
			]
		)
		parts.append(
			[_ball(0.03), Transform3D(Basis(), Vector3(side * 0.13, 0.58, -0.19)), CAT_PINK]
		)
		for whisker: int in 2:
			var turned := Basis.from_euler(
				Vector3(0.0, deg_to_rad(side * 20.0), deg_to_rad(side * (8.0 - whisker * 14.0)))
			)
			parts.append(
				[
					_box(Vector3(0.12, 0.008, 0.008)),
					Transform3D(turned, Vector3(side * 0.2, 0.58 - whisker * 0.03, -0.17)),
					CAT_INK
				]
			)
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = merged(parts)
	body.material_override = _painted()
	cat.add_child(body)
	var waving := Node3D.new()
	waving.name = "Waving"
	waving.position = Vector3(0.2, 0.42, -0.06)
	cat.add_child(waving)
	var arm := MeshInstance3D.new()
	arm.mesh = merged(
		[
			[_capsule(0.065, 0.3), Transform3D(Basis(), Vector3(0.0, 0.13, 0.0)), CAT_WHITE],
			[_ball(0.04), Transform3D(Basis(), Vector3(0.0, 0.27, -0.05)), CAT_PINK],
		]
	)
	arm.material_override = body.material_override
	waving.add_child(arm)
	var holding := Node3D.new()
	holding.name = "Holding"
	holding.position = Vector3(-0.17, 0.42, -0.06)
	cat.add_child(holding)
	var paw := MeshInstance3D.new()
	paw.mesh = merged(
		[
			[_ball(0.06), Transform3D(Basis(), Vector3(0.02, -0.15, -0.16)), CAT_WHITE],
			[
				_cylinder(0.1, 0.025),
				Transform3D(
					Basis.from_euler(Vector3(PI * 0.5, 0.0, 0.26)), Vector3(0.05, -0.12, -0.18)
				),
				CAT_BRASS
			],
		]
	)
	paw.material_override = body.material_override
	holding.add_child(paw)
	var moves := LuckyCat.new()
	moves.name = "Wave"
	moves.cat = cat
	moves.waving = waving
	moves.holding = holding
	worn.add_child(moves)


## The tip jar on [param worn]: a jar of glass with its rim, TIPS on masking tape, and up to
## [constant TipJar.MOST] chips in one [MultiMesh], filled and tipped out by [TipJar].
static func tip_jar(worn: Node3D) -> void:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = JAR_GLASS
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var jar := MeshInstance3D.new()
	jar.name = "Jar"
	jar.mesh = merged(
		[
			[_cylinder(0.3, 0.05), Transform3D(Basis(), Vector3(0.0, 0.085, 0.0)), Color.WHITE],
			[
				_cylinder(0.285, 0.58, false),
				Transform3D(Basis(), Vector3(0.0, 0.35, 0.0)),
				Color.WHITE
			],
			[_torus(0.25, 0.3), Transform3D(Basis(), Vector3(0.0, 0.64, 0.0)), Color.WHITE],
		]
	)
	glass.vertex_color_use_as_albedo = true
	jar.material_override = glass
	jar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	worn.add_child(jar)
	var tape := MeshInstance3D.new()
	tape.mesh = _box(Vector3(0.34, 0.13, 0.01))
	tape.material_override = SupporterDress.flat(TAPE)
	tape.position = Vector3(0.0, 0.36, -0.29)
	tape.rotation.z = deg_to_rad(-4.0)
	worn.add_child(tape)
	var word := Label3D.new()
	word.text = TIPS
	word.font = load("res://assets/fonts/PermanentMarker-Regular.ttf")
	word.font_size = 64
	# Small enough to leave the tape a margin round its word.
	word.pixel_size = 0.0016
	word.modulate = CAT_INK
	word.outline_size = 0
	word.position = Vector3(0.0, 0.0, -0.006)
	word.rotation.y = PI
	tape.add_child(word)
	var chips := MultiMeshInstance3D.new()
	chips.name = "Chips"
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.use_colors = true
	many.mesh = _cylinder(0.075, 0.024)
	many.instance_count = TipJar.MOST
	many.visible_instance_count = 0
	for i: int in TipJar.MOST:
		many.set_instance_color(i, TipJar.COLORS[i % TipJar.COLORS.size()])
	chips.multimesh = many
	chips.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	chips.material_override = _painted()
	worn.add_child(chips)
	var fills := TipJar.new()
	fills.name = "Fill"
	fills.chips = chips
	worn.add_child(fills)


## One mesh of many [param parts], each [mesh, transform, color]: each part's first surface placed
## as its transform says and painted in its color, carried in its corners, so a piece of many shapes
## is one draw in [method _painted].
static func merged(parts: Array) -> ArrayMesh:
	var cut := SurfaceTool.new()
	cut.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part: Array in parts:
		var shape: Mesh = part[0]
		var placed: Transform3D = part[1]
		var color: Color = part[2]
		var arrays := shape.surface_get_arrays(0)
		var corners: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var order: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var turn := placed.basis.inverse().transposed()
		if order.is_empty():
			order = PackedInt32Array(range(corners.size()))
		for at: int in order:
			cut.set_color(color)
			cut.set_normal((turn * normals[at]).normalized())
			cut.add_vertex(placed * corners[at])
	return cut.commit()


## The flat paint of a piece of many colors, each in its corners' colors, see [method merged].
static func _painted() -> StandardMaterial3D:
	var paint := SupporterDress.flat(Color.WHITE)
	paint.vertex_color_use_as_albedo = true
	return paint


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


static func _ball(radius: float, squash := 1.0) -> SphereMesh:
	var round_mesh := SphereMesh.new()
	round_mesh.radius = radius
	round_mesh.height = radius * 2.0 * squash
	round_mesh.radial_segments = 16
	round_mesh.rings = 8
	return round_mesh


static func _torus(inner: float, outer: float) -> TorusMesh:
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = inner
	ring_mesh.outer_radius = outer
	ring_mesh.rings = 20
	ring_mesh.ring_segments = 8
	return ring_mesh


static func _prism(size: Vector3) -> PrismMesh:
	var cut := PrismMesh.new()
	cut.size = size
	return cut


static func _box(size: Vector3) -> BoxMesh:
	var cut := BoxMesh.new()
	cut.size = size
	return cut


static func _capsule(radius: float, tall: float) -> CapsuleMesh:
	var cut := CapsuleMesh.new()
	cut.radius = radius
	cut.height = tall
	cut.radial_segments = 12
	cut.rings = 4
	return cut


static func _cylinder(radius: float, tall: float, capped := true) -> CylinderMesh:
	var cut := CylinderMesh.new()
	cut.top_radius = radius
	cut.bottom_radius = radius
	cut.height = tall
	cut.radial_segments = 20
	cut.rings = 1
	cut.cap_top = capped
	return cut
