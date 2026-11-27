class_name KartBounds
extends Node
## A kart outside the room it plays in is respawned, GAME.md 3.6: off the room's grid, inside one
## of its walls, sunk well under its floor without falling into a pit, or up over it. Nothing in a
## match puts a kart there, but a client's karts go on as they last went while the host is silent,
## through walls and off the edge, and a map carried over to a new host starts from what that
## client saw, GAME.md 10.8; a hard enough knock might do it too. A kart found out there for
## [constant OUT_FOR] seconds is brought back the way one is after a death, where the match would
## bring it back, its pot and its jokers its own still. Looked at only where the match is run, the
## host's say online, never on a client's copy of it, every [constant EVERY] seconds.

## How often the karts are looked at, and how long one has to be out to be brought back, in
## seconds: long enough that a kart shoved against a wall for a frame is left alone.
const EVERY := 0.25
const OUT_FOR := 0.5
## How far under the floor a kart not falling into a pit is out of the room, and how far over it,
## in meters: a kart drives on the floor and never leaves it, and the walls stand 1 m.
const BELOW := -3.0
const ABOVE := 3.0

var _match: Match
var _next := 0.0
## How long each slot's kart has been out, by slot index.
var _out: Dictionary[int, float] = {}


## The one watching [param match_node]'s karts: a test driving them far out past the room on
## purpose, where nothing of the map is in the way of what it builds, turns it off.
static func of(match_node: Match) -> KartBounds:
	return match_node.get_node_or_null("KartBounds") as KartBounds


## Watches the karts of [param match_node].
static func add_to(match_node: Match) -> KartBounds:
	var bounds := KartBounds.new()
	bounds.name = "KartBounds"
	bounds._match = match_node
	match_node.add_child(bounds)
	return bounds


## Whether [param at] is out of the room [param grid] lays out: off its grid, inside a wall, or
## under or over its floor.
static func outside(grid: ArenaGrid, at: Vector3) -> bool:
	if at.y < BELOW or at.y > ABOVE:
		return true
	var cell := grid.cell_of(at)
	if cell.x < 0 or cell.y < 0 or cell.x >= grid.width or cell.y >= grid.height:
		return true
	return grid.is_wall(cell)


func _physics_process(delta: float) -> void:
	if _match.puppet or _match.arena == null or _match.arena.grid == null:
		_out.clear()
		return
	_next -= delta
	if _next > 0.0:
		return
	_next = EVERY
	for slot: PlayerSlot in _match.slots:
		var kart := slot.kart
		if kart == null or not kart.alive or kart.falling:
			_out.erase(slot.index)
			continue
		if not outside(_match.arena.grid, kart.global_position):
			_out.erase(slot.index)
			continue
		_out[slot.index] = _out.get(slot.index, 0.0) + EVERY
		if _out[slot.index] >= OUT_FOR:
			_out.erase(slot.index)
			_match._respawn(slot)
