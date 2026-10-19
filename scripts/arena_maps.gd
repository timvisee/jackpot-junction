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
	&"lucky_crossing",
	&"vault",
	&"crossfire",
	&"lucky_crossing_xl",
	&"vault_xl",
	&"crossfire_xl",
	&"house_rules",
	&"showdown",
]
const NAMES: Array[String] = [
	"Lucky Crossing",
	"The Vault",
	"Crossfire",
	"Loose Threads",
	"Pin Alley",
	"Toy Box",
	"House Rules",
	"Showdown",
]
## The maps the story opens, STORY.md 10: on every machine, so a client loads one when its host
## picks it, but in no Grand Prix's deal and in a quick match's list only for a profile the story
## has brought there, see [method offered].
const STORY_ONLY: Array[StringName] = [&"house_rules"]
## The tie-breaker's map, GAME.md 6.3 and 9.7a: a showdown is played on it, and a match on it is
## one.
const SHOWDOWN := &"showdown"
## The maps no Grand Prix deals, though a quick match's list offers them, see [method offered]: the
## showdown's, which is a tie-breaker rather than a map of a run, GAME.md 6.3.
const NEVER_DEALT: Array[StringName] = [SHOWDOWN]
## What an XL map's id ends in, after the id of the map it is the XL of.
const XL := "_xl"


## The layout for a map, or the first map for anything unrecognized.
static func layout(id: StringName) -> ArenaLayout:
	return load("res://data/maps/%s.tres" % String(IDS[index_of(id)]))


## The layout [param rules] are played on: their map's, dressed as the room they name when that is
## not its own, as a showdown is dressed as the room its run ended in, GAME.md 6.3.
static func layout_for(rules: MatchRules) -> ArenaLayout:
	var own := layout(rules.map)
	var path := "res://data/rooms/%s.tres" % String(rules.room)
	if rules.room == &"" or not ResourceLoader.exists(path):
		return own
	var dressed: ArenaLayout = own.duplicate()
	dressed.room = load(path)
	return dressed


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
## Never none: asked for neither, it deals from all of them. Never a map of the story's, nor the
## showdown's, which is played after a run rather than dealt in one.
static func pool(normal: bool, xl: bool) -> Array[StringName]:
	var chosen: Array[StringName] = []
	var every: Array[StringName] = []
	for id: StringName in IDS:
		if id in STORY_ONLY or id in NEVER_DEALT:
			continue
		every.append(id)
		var wanted := xl if is_xl(id) else normal
		if wanted:
			chosen.append(id)
	return chosen if not chosen.is_empty() else every


## The maps a quick match's list offers [param profile], in the order of [constant IDS]: every
## one, the showdown's last, GAME.md 6.3, but the story's until it has played the Final Hand with
## its story on, STORY.md 10.
static func offered(profile: Profile) -> Array[StringName]:
	var story := profile != null and Story.shown_of(profile) == Story.Stage.OPERATOR
	var listed: Array[StringName] = []
	for id: StringName in IDS:
		if id in STORY_ONLY and not story:
			continue
		listed.append(id)
	return listed
