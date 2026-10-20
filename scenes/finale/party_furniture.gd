class_name PartyFurniture
extends RefCounted
## What the House sets out for its party at the end of a Grand Prix, GAME.md 9.7, among the crowd
## either side of the stage: a bar on the left, its counter of what the steps are built of under a
## top of the House's lit stock edged in foil, bottles on the shelves behind it and the House's
## chips and coupes on it, which were stacked beside the podium on the floor until 2026-10-20 and
## stood too close to the karts; the House's table on the right, under a cloth of its stock hemmed
## in foil, a champagne tower in the middle of it and the three trophies at its end, in foil, each
## on a plinth banded in its place's color; and balloons in the top three's colors tied to the feet
## of the rigging. The crowd stands round each, so the people are at the party rather than on a bare
## floor. Two groups and the balloons, composed rather than scattered, so the podium stays the thing
## the party is about.
##
## Everything plain is baked into a mesh of plain paint and one of metal with its colors on its
## vertices, and the hall bakes the rest with its own, GAME.md 10.7.

## Where the bar and the House's table stand, either side of the stage between it and the rigging's
## back towers, and how big their counters are; how far behind its counter the bar's shelves stand
## and how big they are.
const AT := Vector2(9.7, -11.0)
const COUNTER := Vector3(5.6, 0.75, 0.8)
const SHELVES_BACK := 1.15
const SHELVES := Vector3(5.6, 1.7, 0.4)
## How far round each the crowd keeps clear.
const CLEARANCE := 0.5
## A bottle on the bar's shelves, how big and how far apart, and the glass they come in.
const BOTTLE := Vector2(0.09, 0.4)
const BOTTLE_GAP := 0.46
const GLASSES: Array[Color] = [
	Color("#24402E"), Color("#6A4520"), Color("#24402E"), Color("#4A1A24")
]
## A coupe of champagne: how tall, how wide its bowl, and the glass and the wine.
const COUPE := Vector2(0.21, 0.115)
const GLASS := Color("#C9D2D8")
## The bucket a bottle stands on ice in on the bar.
const ICE_BUCKET := Color("#B9BEC6")
const WINE := Color("#D9B866")
## The tower's tiers, coupes along a side of the topmost first.
const TIERS := 4
## The trophies, the 1st's first: how tall each is, and the plinth under it.
const TROPHIES: Array[float] = [0.95, 0.75, 0.6]
const PLINTH := 0.34
## The balloons at each foot of the rigging: how many, how big, and how high they float.
const BALLOONS := 5
const BALLOON := 0.32
const FLOAT := Vector2(2.3, 3.8)
## The House's chips set out on the bar and the table, how big, and in High Limit the sealed deck
## that stands in for a stack of them.
const CHIP := Vector2(0.16, 0.04)
const DECK := Vector3(0.3, 0.16, 0.22)

var finale: GrandPrixFinale
var dress: PartyDress
var surfaces: Surfaces
var crowd: Crowd
var colors: Array[Color] = []

var _root: Node3D
var _bits: Node3D
var _paints: Dictionary[String, StandardMaterial3D] = {}
var _rng := RandomNumberGenerator.new()


func _init(
	for_finale: GrandPrixFinale,
	party_dress: PartyDress,
	room_surfaces: Surfaces,
	party_crowd: Crowd,
	top_three: Array[Color]
) -> void:
	finale = for_finale
	dress = party_dress
	surfaces = room_surfaces
	crowd = party_crowd
	colors = top_three
	_rng.seed = 7


## Sets it all out in [param hall], whose baking bakes it.
func set_out(hall: Node3D) -> void:
	_root = Node3D.new()
	_root.name = "Furniture"
	hall.add_child(_root)
	_bits = Node3D.new()
	_bits.name = "Bits"
	_root.add_child(_bits)
	var foot := Crowd.TABLE_TOP
	_bar(Vector3(-AT.x, foot, AT.y))
	_house_table(Vector3(AT.x, foot, AT.y))
	for z: float in [PartyHall.RIG_BACK, PartyHall.RIG_FRONT]:
		for side: float in [-1.0, 1.0]:
			_balloons(Vector3(side * PartyHall.RIG.x, foot, z), side)
	Bake.tint(_bits)


## The bar: its counter, the shelves of bottles behind it, and on it the House's chips, coupes and
## a bottle on ice.
func _bar(at: Vector3) -> void:
	var top := at.y + COUNTER.y
	_box(_root, COUNTER, dress.body, at + Vector3.UP * COUNTER.y * 0.5)
	_counter_top(at, COUNTER)
	var shelves := at + Vector3(0.0, 0.0, -SHELVES_BACK)
	_box(_root, SHELVES, dress.base, shelves + Vector3.UP * SHELVES.y * 0.5)
	for shelf: float in [0.75, 1.3]:
		var board := Vector3(SHELVES.x - 0.2, 0.04, 0.3)
		var on := shelves + Vector3(0.0, shelf, SHELVES.z * 0.5 + 0.12)
		_box(_bits, board, _paint(HouseTheme.STOCK_LIT), on)
		var count := floori((SHELVES.x - 0.5) / BOTTLE_GAP)
		for i: int in count:
			var x := (float(i) - float(count - 1) * 0.5) * BOTTLE_GAP
			_bottle(on + Vector3(x, 0.02, 0.0), GLASSES[(i + roundi(shelf * 3.0)) % GLASSES.size()])
	for i: int in 4:
		_coupe(Vector3(at.x - 1.6 + 0.32 * i, top + 0.03, at.z + 0.1))
	_cylinder(
		_bits, 0.17, 0.26, _paint(ICE_BUCKET, 0.35, 0.7), Vector3(at.x + 0.6, top + 0.16, at.z)
	)
	_bottle(Vector3(at.x + 0.6, top + 0.14, at.z), GLASSES[0])
	for i: int in colors.size():
		_money(Vector3(at.x + 1.4 + 0.38 * i, top + 0.03, at.z + 0.05), colors[i], 6 + 3 * i)
	_keep_clear(at, Vector2(COUNTER.x, COUNTER.z + SHELVES_BACK + SHELVES.z))


## The House's table: a cloth of its stock hemmed in foil, the champagne tower in its middle, the
## trophies at its stage end and stacks of the House's chips at the other.
func _house_table(at: Vector3) -> void:
	var cloth := _paint(HouseTheme.STOCK_RAISED)
	_box(_bits, COUNTER, cloth, at + Vector3.UP * COUNTER.y * 0.5)
	_box(
		_bits,
		Vector3(COUNTER.x + 0.02, 0.06, COUNTER.z + 0.02),
		HousePieces.foil(),
		at + Vector3.UP * 0.12
	)
	var top := at.y + COUNTER.y
	_tower(Vector3(at.x + 0.4, top, at.z))
	for place: int in TROPHIES.size():
		var x := at.x - COUNTER.x * 0.5 + 0.5 + 0.62 * place
		var ink := colors[place] if place < colors.size() else HousePieces.FOIL
		_trophy(Vector3(x, top, at.z - 0.05 + 0.1 * place), TROPHIES[place], ink)
	for i: int in colors.size():
		var stack := Vector3(at.x + 2.0 + 0.36 * (i % 2), top, at.z - 0.15 + 0.3 * (i / 2))
		_money(stack, colors[i], 9 - 2 * i)
	_keep_clear(at, Vector2(COUNTER.x, COUNTER.z))


## The counter's top: the House's lit stock a little over the counter all round, a foil line along
## its front edge.
func _counter_top(at: Vector3, counter: Vector3) -> void:
	var top := at + Vector3.UP * (counter.y + 0.03)
	_box(
		_bits, Vector3(counter.x + 0.12, 0.06, counter.z + 0.12), _paint(HouseTheme.STOCK_LIT), top
	)
	var edge := Vector3(counter.x + 0.12, 0.02, 0.03)
	_box(_bits, edge, HousePieces.foil(), top + Vector3(0.0, 0.0, counter.z * 0.5 + 0.06))


## A champagne tower on [param foot]: coupes stacked in square tiers, the widest at the foot.
func _tower(foot: Vector3) -> void:
	for tier: int in TIERS:
		var across := TIERS - tier
		var y := foot.y + float(tier) * COUPE.x * 0.92
		for a: int in across:
			for b: int in across:
				var x := (float(a) - float(across - 1) * 0.5) * COUPE.y * 2.05
				var z := (float(b) - float(across - 1) * 0.5) * COUPE.y * 2.05
				_coupe(Vector3(foot.x + x, y, foot.z + z))


## A coupe standing on [param foot]: a stem, and a shallow bowl with the wine in it.
func _coupe(foot: Vector3) -> void:
	var glass := _paint(GLASS, 0.2)
	_cylinder(_bits, 0.012, COUPE.x * 0.6, glass, foot + Vector3.UP * COUPE.x * 0.3, COUPE.y * 0.6)
	var bowl := foot + Vector3.UP * COUPE.x * 0.8
	_cylinder(_bits, COUPE.y, COUPE.x * 0.4, _paint(WINE, 0.3), bowl, COUPE.y * 0.25)


## A bottle on [param foot] of [param glass]: a body and a neck.
func _bottle(foot: Vector3, glass: Color) -> void:
	var paint := _paint(glass, 0.25)
	_cylinder(_bits, BOTTLE.x, BOTTLE.y * 0.7, paint, foot + Vector3.UP * BOTTLE.y * 0.35)
	var neck := foot + Vector3.UP * BOTTLE.y * 0.85
	_cylinder(_bits, BOTTLE.x * 0.4, BOTTLE.y * 0.3, paint, neck, BOTTLE.x)


## A trophy [param tall] on [param foot]: a plinth of the House's stock banded in [param ink], and
## the cup in foil on its stem over it.
func _trophy(foot: Vector3, tall: float, ink: Color) -> void:
	var plinth := Vector3(PLINTH, PLINTH * 0.7, PLINTH)
	_box(_bits, plinth, _paint(HouseTheme.STOCK), foot + Vector3.UP * plinth.y * 0.5)
	var band := Vector3(PLINTH + 0.01, 0.05, PLINTH + 0.01)
	_box(_bits, band, _paint(ink), foot + Vector3.UP * plinth.y * 0.55)
	var foil := HousePieces.foil()
	var rest := tall - plinth.y
	var stem := foot + Vector3.UP * (plinth.y + rest * 0.25)
	_cylinder(_bits, 0.035, rest * 0.5, foil, stem, 0.09)
	var cup := foot + Vector3.UP * (plinth.y + rest * 0.72)
	_cylinder(_bits, tall * 0.2, rest * 0.48, foil, cup, tall * 0.08)


## A stack of [param count] of the House's chips in [param ink] on [param foot]; in High Limit,
## where no money is ever on the table, GAME.md 8.1c, a sealed deck or two of the House's instead.
func _money(foot: Vector3, ink: Color, count: int) -> void:
	var decks := surfaces.style as HighLimitStyle
	if decks != null:
		for i: int in maxi(count / 4, 1):
			decks.carton(_root, DECK, foot + Vector3.UP * DECK.y * 0.82 * i)
		return
	var paint := _paint(ink, 0.45)
	for i: int in count:
		var at := foot + Vector3(_rng.randf_range(-0.01, 0.01), CHIP.y * (float(i) + 0.5), 0.0)
		_cylinder(_bits, CHIP.x, CHIP.y, paint, at)


## A bunch of balloons in the top three's colors tied to a foot of the rigging at [param foot],
## floating out a little toward [param side]'s wall.
func _balloons(foot: Vector3, side: float) -> void:
	var cord := _paint(Color("#26252B"))
	var knot := foot + Vector3(0.0, 1.0, 0.0)
	for i: int in BALLOONS:
		var turn := TAU * float(i) / float(BALLOONS) + _rng.randf_range(-0.3, 0.3)
		var out := Vector3(cos(turn), 0.0, sin(turn)) * _rng.randf_range(0.25, 0.55)
		out.x += side * 0.2
		var high := lerpf(FLOAT.x, FLOAT.y, float(i) / float(BALLOONS - 1))
		var at := foot + out + Vector3.UP * high
		var ink := colors[i % colors.size()] if not colors.is_empty() else HousePieces.FOIL
		var ball := SphereMesh.new()
		ball.radius = BALLOON
		ball.height = BALLOON * 2.3
		ball.radial_segments = 10
		ball.rings = 5
		var node := MeshInstance3D.new()
		node.mesh = ball
		node.material_override = _paint(ink, 0.35)
		node.position = at
		_bits.add_child(node)
		_rod(knot, at - Vector3.UP * BALLOON, 0.012, cord)


## The crowd keeps a patch [param size] round [param middle] clear, and a little more.
func _keep_clear(middle: Vector3, size: Vector2) -> void:
	var grown := size + Vector2.ONE * CLEARANCE * 2.0
	crowd.keep_clear(Rect2(Vector2(middle.x, middle.z) - grown * 0.5, grown))


# --- the parts ---------------------------------------------------------------


func _box(into: Node3D, size: Vector3, skin: Material, at: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)
	return node


## An upright cylinder [param height] tall with its middle at [param at], [param radius] round at
## its top and [param bottom] at its foot where that is given.
func _cylinder(
	into: Node3D, radius: float, height: float, skin: Material, at: Vector3, bottom := -1.0
) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius if bottom < 0.0 else bottom
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 1
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.position = at
	into.add_child(node)


func _rod(a: Vector3, b: Vector3, thick: float, skin: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(thick, thick, a.distance_to(b))
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = skin
	node.transform = Transform3D(Basis.looking_at(b - a, Vector3.RIGHT), (a + b) * 0.5)
	_bits.add_child(node)


## Plain paint, one for each color and finish, so the lot bakes into a mesh or two.
func _paint(color: Color, roughness := PartyDress.SATIN, metallic := 0.0) -> StandardMaterial3D:
	var key := "%s:%.2f:%.2f" % [color.to_html(false), roughness, metallic]
	if not _paints.has(key):
		var paint := PartyDress.plain(color, roughness)
		paint.metallic = metallic
		_paints[key] = paint
	return _paints[key]
