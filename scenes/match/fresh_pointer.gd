class_name FreshPointer
extends Node
## Points the player at the table's new card once, GAME.md 8.9a: the first time a match puts a card
## the House has opened and the profile playing has not played yet on the table, the driving test's
## arrow, 9.4a, lies ahead of the first seat's kart as the lamps go out, pointing at the nearest of
## the card's pieces with a ring round it, until the kart gets there or a few seconds have gone. A
## card with nothing on the floor to point at, Jokers, Bounty or Suits & hands, is said by the
## loading screen and the coupon alone. Only for a player at this machine, never in the demo.

## How long it points, at most, in seconds.
const SECONDS := 9.0
## The ring round a piece of one cell, and round a Jackpot or a run of cells.
const RING := 1.1
const RING_WIDE := 2.0

var match_node: Match
var _arrow: GuideArrow
var _card := -1
var _left := 0.0


## Points the player at the new card in [param in_match], should it have one on the floor.
static func add_to(in_match: Match) -> void:
	var fresh := Game.settings.profile.table.fresh & in_match.rules.table
	for card: int in TableCards.cards_of(fresh):
		if card in [TableCards.Card.JOKERS, TableCards.Card.BOUNTY, TableCards.Card.SUITS]:
			continue
		var pointer := FreshPointer.new()
		pointer.name = "FreshPointer"
		pointer.match_node = in_match
		pointer._card = card
		in_match.add_child(pointer)
		return


func _ready() -> void:
	Events.match_state_changed.connect(_on_state)


func _on_state(state: int) -> void:
	if state != Match.State.PLAYING or _arrow != null or match_node.slots.is_empty():
		return
	var kart := match_node.kart_of(0)
	var spot := target(match_node, _card, kart.global_position)
	if not spot.is_finite():
		queue_free()
		return
	_arrow = GuideArrow.add_to(match_node)
	_arrow.kart = kart
	var wide := _card == TableCards.Card.JACKPOT or _card == TableCards.Card.TRICKS
	_arrow.point_at(spot, RING_WIDE if wide else RING)
	_left = SECONDS


func _process(delta: float) -> void:
	if _arrow == null:
		return
	_left -= delta
	var kart := _arrow.kart
	var there := (
		is_instance_valid(kart)
		and (
			Vector2(kart.global_position.x, kart.global_position.z).distance_to(
				Vector2(_arrow.target.x, _arrow.target.z)
			)
			< GuideArrow.NEAR * 0.5
		)
	)
	if _left <= 0.0 or there:
		_arrow.queue_free()
		queue_free()


## Where the nearest of [param card]'s pieces is in [param in_match] from [param from], or not
## finite for none.
static func target(in_match: Match, card: int, from: Vector3) -> Vector3:
	var arena := in_match.arena
	var spots: Array[Vector3] = []
	match card:
		TableCards.Card.ITEMS:
			for pad: Node3D in arena.power_pads:
				spots.append(pad.global_position)
		TableCards.Card.JACKPOT:
			# The pile filling, the one worth driving to.
			for zone: JackpotZone in arena.jackpot_zones:
				if zone.active:
					spots.append(zone.global_position)
		TableCards.Card.FLUSH:
			for pad: Node3D in arena.flush_pads:
				spots.append(pad.global_position)
		TableCards.Card.SLOTS:
			for pad: Node in arena.find_children("SlotPad*", "SlotPad", false, false):
				spots.append((pad as Node3D).global_position)
		TableCards.Card.TRICKS:
			var grid := arena.grid
			for cell: Vector2i in grid.bumpers + grid.magnets:
				spots.append(arena.to_global(grid.cell_center(cell)))
			for rect: Rect2i in grid.cabinets + grid.belts + grid.seams + grid.toys + grid.lasers:
				spots.append(arena.to_global(grid.rect_center(rect)))
	var best := Vector3.INF
	for spot: Vector3 in spots:
		if not best.is_finite() or spot.distance_to(from) < best.distance_to(from):
			best = spot
	return best
