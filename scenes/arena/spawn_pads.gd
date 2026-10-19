class_name SpawnPads
extends Node3D
## The discs an arena's spawn points are painted with, GAME.md 6.3. The corners' are always on the
## floor. These, the ones past them, `s`, for the fifth kart on, are only there while the room has
## more karts than corners: in a match of four they are spawns nobody starts on, and a disc on the
## floor says somebody does. A client counts the karts it is told about, so every screen shows the
## same, and a room that fills up past four puts them down as the fifth kart arrives.

## How many karts the corners hold: past that these are in use, see [method Arena.spawns_for].
var corners := 0

var _match_node: Match


## Paints [param arena]'s spawn points on its floor, in two sets: the corners', and these, which
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
		var disc := ArenaPads.disc(arena, 0.5, arena.room.marking)
		disc.position = Vector3(0.0, Arena.PAD_HEIGHT * 0.5, 0.0)
		marker.add_child(disc)
	# Paint on the felt that never moves is baked: every disc of a set is one mesh with the rest.
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
