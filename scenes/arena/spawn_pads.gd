class_name SpawnPads
extends Node3D
## The rings an arena's spawn points are marked with, GAME.md 6.3 and 8.1c. The corners' are always
## on the floor. These, the ones past them, `s`, for the fifth kart on, are only there while the
## room has more karts than corners: in a match of four they are spawns nobody starts on, and a
## ring on the floor says somebody does. A client counts the karts it is told about, so every
## screen shows the same, and a room that fills up past four puts them down as the fifth kart
## arrives.

## How many karts the corners hold: past that these are in use, see [method Arena.spawns_for].
var corners := 0

var _match_node: Match


## Marks [param arena]'s spawn points on its floor, in two sets: the corners', and these, which
## come and go. Each set is baked into a mesh of its own, GAME.md 10.7, so these can be put away
## whole. Returns these.
static func add_to(arena: Arena) -> SpawnPads:
	var always := Node3D.new()
	always.name = "Spawns"
	arena.add_child(always)
	var extra := SpawnPads.new()
	extra.name = "ExtraSpawns"
	extra.corners = arena.grid.corner_spawns
	extra.visible = false
	arena.add_child(extra)
	for i: int in arena.grid.spawns.size():
		var position := arena.grid.cell_center(arena.grid.spawns[i])
		arena.spawn_points.append(position)
		var marker := Marker3D.new()
		marker.name = "Spawn%d" % i
		marker.position = position
		(always if i < extra.corners else extra).add_child(marker)
		ArenaPads.seat(arena, marker)
	# Paint on the felt that never moves is baked: every ring of a set is one mesh with the rest.
	if arena.bake_scenery:
		Bake.merge(always)
		Bake.merge(extra)
	return extra


func _ready() -> void:
	# Under the arena, which is under the match it is the room of.
	_match_node = get_parent().get_parent() as Match


func _process(_delta: float) -> void:
	var karts := _match_node.slots.size() if _match_node != null else 0
	visible = karts > corners
