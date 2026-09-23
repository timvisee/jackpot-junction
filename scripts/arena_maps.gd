class_name ArenaMaps
extends RefCounted
## The arenas a match can be played on, GAME.md 6.3. Three of them, all the same size and all
## holding the same furniture; what differs is the shape of the room around it.
##
## Named here rather than looked up off disk so that the lobby, the wire and the saved settings
## all mean the same thing by a map, and so that a map a machine has never heard of falls back to
## the first rather than to no arena at all.

const IDS: Array[StringName] = [&"lucky_crossing", &"vault", &"crossfire"]
const NAMES: Array[String] = ["Lucky Crossing", "The Vault", "Crossfire"]


## The layout for a map, or the first map for anything unrecognized.
static func layout(id: StringName) -> ArenaLayout:
	return load("res://data/maps/%s.tres" % String(IDS[index_of(id)]))


## Where a map sits in the list, or 0 for one this build does not have.
static func index_of(id: StringName) -> int:
	return maxi(IDS.find(id), 0)


static func id_at(index: int) -> StringName:
	return IDS[clampi(index, 0, IDS.size() - 1)]
