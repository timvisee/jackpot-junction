class_name ShowdownCards
extends Node3D
## A showdown's row on the table in the place of the score tanks, GAME.md 9.7a and 8.1: there is no
## score in it to fill a tank with, only who is still in. A playing card stands up for every kart in
## the fight, faced in its color, and folds when the kart goes out: it falls forward face down, its
## back to the room, the way a hand is folded at a table.
##
## Scenery, like the tanks: no collision, nothing decided here. Read off the slots every frame, so
## it is right on a client filling up from snapshots as much as on the host.

## How big a card is and how far apart they stand, in meters, and how far back it leans.
const CARD := Vector2(1.0, 1.4)
const THICK := 0.03
const SPACING := 1.5
const LEAN := -12.0
## The cream of its face inside the border in the kart's color, and the pip in the middle.
const FACE_INSET := 0.12
const PIP := 0.2
## The back it shows once it has folded, and the dark of its stand.
const BACK := Color(0.42, 0.08, 0.1)
const STAND := Color(0.11, 0.11, 0.14)
## How long a card takes to fall.
const FALL := 0.45

var match_node: Match

## Seat to its card's pivot, and the seats whose cards have folded.
var _cards: Dictionary[int, Node3D] = {}
var _folded: Dictionary[int, bool] = {}
var _built := -1


## Stands a row of cards up on [param for_match]'s table when it is a showdown.
static func add_to(for_match: Match) -> ShowdownCards:
	if for_match.rules == null or not for_match.rules.showdown():
		return null
	var cards := ShowdownCards.new()
	cards.name = "ShowdownCards"
	cards.match_node = for_match
	for_match.add_child(cards)
	return cards


func _process(_delta: float) -> void:
	var fighting := _fighting()
	if fighting.size() != _built:
		_rebuild(fighting)
	for slot: PlayerSlot in fighting:
		if slot.out_at >= 0 and not _folded.has(slot.index) and _cards.has(slot.index):
			_fold(slot.index)


## The seats in the fight, in seat order.
func _fighting() -> Array[PlayerSlot]:
	var fighting: Array[PlayerSlot] = []
	for slot: PlayerSlot in match_node.slots:
		if not slot.benched:
			fighting.append(slot)
	return fighting


## A card for each of [param fighting], in a row where the tanks stand, see [ScoreTanks].
func _rebuild(fighting: Array[PlayerSlot]) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_cards.clear()
	_folded.clear()
	_built = fighting.size()
	if fighting.is_empty():
		return
	var size := match_node.arena.world_size() if match_node.arena != null else Vector2(35.0, 20.0)
	var row := -(size.y * 0.5 + ScoreTanks.STANDOFF + ScoreTanks.RADIUS)
	var along := -size.x * ScoreTanks.OFFSET * 0.5
	for i: int in fighting.size():
		var at := Vector3(along + (i - (fighting.size() - 1) * 0.5) * SPACING, 0.0, row)
		_cards[fighting[i].index] = _card(at, fighting[i].color())
	if match_node.arena != null and match_node.arena.crowd != null:
		var run := fighting.size() * SPACING + CARD.x
		match_node.arena.crowd.keep_clear(Rect2(along - run * 0.5, row - 2.6, run, 4.0))


## One card on its stand at [param at]: a pivot at its foot, leaning back, with the card's face to
## the room in [param color] and its back behind.
func _card(at: Vector3, color: Color) -> Node3D:
	var stand := MeshInstance3D.new()
	var foot := BoxMesh.new()
	foot.size = Vector3(CARD.x * 0.7, 0.08, 0.36)
	stand.mesh = foot
	stand.material_override = _paint(STAND)
	stand.position = at + Vector3(0.0, 0.04, -0.1)
	add_child(stand)
	var pivot := Node3D.new()
	pivot.name = "Card"
	pivot.position = at + Vector3(0.0, 0.08, 0.0)
	pivot.rotation_degrees.x = LEAN
	add_child(pivot)
	var body := MeshInstance3D.new()
	var card := BoxMesh.new()
	card.size = Vector3(CARD.x, CARD.y, THICK)
	body.mesh = card
	body.material_override = _paint(BACK)
	body.position = Vector3(0.0, CARD.y * 0.5, 0.0)
	pivot.add_child(body)
	var border := _quad(CARD, _glowing(color))
	border.position = Vector3(0.0, CARD.y * 0.5, THICK * 0.5 + 0.002)
	pivot.add_child(border)
	var face := _quad(CARD - Vector2.ONE * FACE_INSET * 2.0, _paint(HouseTheme.PAPER))
	face.position = Vector3(0.0, CARD.y * 0.5, THICK * 0.5 + 0.004)
	pivot.add_child(face)
	var pip := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = PIP
	disc.bottom_radius = PIP
	disc.height = 0.01
	pip.mesh = disc
	pip.material_override = _glowing(color)
	pip.rotation_degrees.x = 90.0
	pip.position = Vector3(0.0, CARD.y * 0.5, THICK * 0.5 + 0.01)
	pivot.add_child(pip)
	return pivot


## Folds [param seat]'s card: it falls forward onto its face, its back up.
func _fold(seat: int) -> void:
	_folded[seat] = true
	var pivot := _cards[seat]
	var tween := create_tween()
	(
		tween
		. tween_property(pivot, "rotation_degrees:x", 90.0, FALL)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)


## Whether [param seat]'s card has folded, for a test.
func folded(seat: int) -> bool:
	return _folded.has(seat)


static func _quad(size: Vector2, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	node.mesh = quad
	node.material_override = material
	return node


static func _paint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material


## The kart's color, glowing a little on its own as the tanks' fluid does, so a card reads at a
## glance rather than only when the lights are on it.
static func _glowing(color: Color) -> StandardMaterial3D:
	var material := _paint(color)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.55
	return material
