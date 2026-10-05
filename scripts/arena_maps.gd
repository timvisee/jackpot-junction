class_name ArenaMaps
extends RefCounted
## The arenas a match can be played on, GAME.md 6.3. Three of them at the usual size, all holding
## the same furniture, where what differs is the shape of the room around it; and an XL map of
## each, wider and deeper, with more room to drive round the pits and the Junction.
##
## Named here rather than looked up off disk so that the lobby, the wire and the saved settings
## all mean the same thing by a map, and so that a map a machine has never heard of falls back to
## the first rather than to no arena at all. New maps go on the end, so a map keeps its place in
## the list and a lobby's remembered pick stays the pick it was.

const IDS: Array[StringName] = [
	&"lucky_crossing", &"vault", &"crossfire", &"lucky_crossing_xl", &"vault_xl", &"crossfire_xl"
]
const NAMES: Array[String] = [
	"Lucky Crossing", "The Vault", "Crossfire", "Lucky Crossing XL", "The Vault XL", "Crossfire XL"
]
## What an XL map's id ends in, after the id of the map it is the XL of.
const XL := "_xl"


## The layout for a map, or the first map for anything unrecognized.
static func layout(id: StringName) -> ArenaLayout:
	return load("res://data/maps/%s.tres" % String(IDS[index_of(id)]))


## Where a map sits in the list, or 0 for one this build does not have.
static func index_of(id: StringName) -> int:
	return maxi(IDS.find(id), 0)


static func id_at(index: int) -> StringName:
	return IDS[clampi(index, 0, IDS.size() - 1)]


## Whether [param id] is one of the XL maps.
static func is_xl(id: StringName) -> bool:
	return String(id).ends_with(XL)


## The map [param id] is a size of: the same for a map and its XL, which are the same room.
static func family(id: StringName) -> StringName:
	return StringName(String(id).trim_suffix(XL))


## The XL of [param id], or [param id] itself for a map that is XL already or has none.
static func xl_of(id: StringName) -> StringName:
	var xl := StringName(String(family(id)) + XL)
	return xl if xl in IDS else id


## The maps a Grand Prix may deal, GAME.md 9.7: the ones at the usual size, the XL ones, or both.
## Never none: asked for neither, it deals from all of them.
static func pool(normal: bool, xl: bool) -> Array[StringName]:
	var chosen: Array[StringName] = []
	for id: StringName in IDS:
		var wanted := xl if is_xl(id) else normal
		if wanted:
			chosen.append(id)
	return chosen if not chosen.is_empty() else IDS.duplicate()
