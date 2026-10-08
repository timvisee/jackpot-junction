class_name LoyaltyState
extends RefCounted
## One profile's loyalty program, GAME.md 8.9: whether the house has welcomed it, its member number,
## the landmarks it has won and which of them the map has not shown it yet, the feats of one map it
## has done and the things of Lost Property it has found, kept in a section of its own in the
## profile's file. Nothing in it goes over the wire. See [Loyalty] for what is won when.
##
## Kept by id. An id this version does not know, a landmark taken off the map or one a newer version
## has, is kept as it is and counts for nothing, so no landmark won is lost to a version.

const SECTION := "loyalty"

## Whether the house's welcome has been shown and its card activated, GAME.md 8.9.
var welcomed := false
## The number on the program's card, the invitation's where it had one, STORY.md 6.6b.
var member := ""
## The landmarks won, by id.
var won := PackedStringArray()
## The landmarks won that the map has not shown under its cursor yet, which wear a NEW tag.
var fresh := PackedStringArray()
## The feats of one map ever done, by the id of the landmark whose bet asked for it.
var feats := PackedStringArray()
## The things of Lost Property found, by the id of the landmark they were lost for.
var found := PackedStringArray()
## The rooms a map has been won in, by the room's id, for the Department's keystone.
var rooms := PackedStringArray()
## Which of [constant CardBack.STYLES] the cards this machine draws wear, GAME.md 8.9, as far as it
## has been won, see [method CardBack.worn].
var card_back := 0
## The laps of the roundabout won, GAME.md 8.9, printed on the card and the license.
var laps := 0
## How many maps in a row each thing of Lost Property could have lain in and did not, by its
## landmark's id: certain once it has missed two, GAME.md 8.9.
var lost_waits: Dictionary = {}


func read(file: ConfigFile) -> void:
	welcomed = bool(file.get_value(SECTION, "welcomed", false))
	member = str(file.get_value(SECTION, "member", ""))
	won = _ids(file.get_value(SECTION, "won", PackedStringArray()))
	feats = _ids(file.get_value(SECTION, "feats", PackedStringArray()))
	found = _ids(file.get_value(SECTION, "found", PackedStringArray()))
	rooms = _ids(file.get_value(SECTION, "rooms", PackedStringArray()))
	card_back = maxi(int(file.get_value(SECTION, "card_back", 0)), 0)
	laps = maxi(int(file.get_value(SECTION, "laps", 0)), 0)
	lost_waits = {}
	var waits: Variant = file.get_value(SECTION, "lost_waits", {})
	if waits is Dictionary:
		for id: Variant in waits:
			if id is String and (waits[id] is int or waits[id] is float):
				lost_waits[id] = clampi(int(waits[id]), 0, 99)
	fresh = PackedStringArray()
	# Only what is won can be new.
	for id: String in _ids(file.get_value(SECTION, "fresh", PackedStringArray())):
		if id in won:
			fresh.append(id)


func write(file: ConfigFile) -> void:
	file.set_value(SECTION, "welcomed", welcomed)
	file.set_value(SECTION, "member", member)
	file.set_value(SECTION, "won", won)
	file.set_value(SECTION, "fresh", fresh)
	file.set_value(SECTION, "feats", feats)
	file.set_value(SECTION, "found", found)
	file.set_value(SECTION, "rooms", rooms)
	file.set_value(SECTION, "card_back", card_back)
	file.set_value(SECTION, "laps", laps)
	file.set_value(SECTION, "lost_waits", lost_waits)


## Whether the landmark [param id] has been won.
func has_won(id: StringName) -> bool:
	return String(id) in won


## The landmark [param id] is won, and new until the map has shown it. True the first time.
func win(id: StringName) -> bool:
	if id == &"" or has_won(id):
		return false
	won.append(String(id))
	fresh.append(String(id))
	return true


## Whether the landmark [param id] was won since the map last showed it.
func is_fresh(id: StringName) -> bool:
	return String(id) in fresh


## The map has shown [param id] under its cursor. True if it was new until now.
func look_at(id: StringName) -> bool:
	var at := fresh.find(String(id))
	if at < 0:
		return false
	fresh.remove_at(at)
	return true


## The feat [param id] was done in a map. True the first time.
func do_feat(id: StringName) -> bool:
	if id == &"" or has_feat(id):
		return false
	feats.append(String(id))
	return true


## Whether the feat [param id] was ever done.
func has_feat(id: StringName) -> bool:
	return String(id) in feats


## The thing of Lost Property lost for the landmark [param id] was found. True the first time.
func find(id: StringName) -> bool:
	if id == &"" or has_found(id):
		return false
	found.append(String(id))
	return true


## A map was won in the room [param id]. True the first time.
func win_in(id: StringName) -> bool:
	if id == &"" or String(id) in rooms:
		return false
	rooms.append(String(id))
	return true


## Whether the thing lost for the landmark [param id] has been found.
func has_found(id: StringName) -> bool:
	return String(id) in found


## The ids out of whatever the file held: names, each once, nothing else.
static func _ids(value: Variant) -> PackedStringArray:
	var ids := PackedStringArray()
	if not (value is PackedStringArray or value is Array):
		return ids
	for id: Variant in value:
		if (id is String or id is StringName) and not str(id).is_empty() and str(id) not in ids:
			ids.append(str(id))
	return ids
