class_name LoyaltyState
extends RefCounted
## One profile's loyalty program, GAME.md 8.9: whether the house has welcomed it, its member number,
## the landmarks it has won and which of them the map has not shown it yet, the dress they paid that
## the kart dialog has not shown it yet, the feats of one map it has done and the things of Lost
## Property it has found, kept in a section of its own in the profile's file. Nothing in it goes
## over the wire. See [Loyalty] for what is won when.
##
## Kept by id. An id this version does not know, a landmark taken off the map or one a newer version
## has, is kept as it is and counts for nothing, so no landmark won is lost to a version.

const SECTION := "loyalty"

## Whether the house's welcome has been shown and its card activated, GAME.md 8.9.
var welcomed := false
## Whether the House has shown it round its map, the first look of GAME.md 8.9, to its end or
## skipped, so it does not come again by itself.
var toured := false
## The number on the program's card, the invitation's where it had one, STORY.md 6.6b.
var member := ""
## The landmarks won, by id.
var won := PackedStringArray()
## The landmarks won that the map has not shown under its cursor yet, which wear a NEW tag.
var fresh := PackedStringArray()
## The pieces of dress won, or moved up a finish, that the kart dialog has not shown under its
## cursor yet, by name, "hat:Fedora", which wear a NEW tag there, GAME.md 4.4a. None in a file
## from before there were, so a profile's dress from then is never all new at once.
var dress_fresh := PackedStringArray()
## The feats of one map ever done, by the id of the landmark whose bet asked for it.
var feats := PackedStringArray()
## The things of Lost Property found, by the id of the landmark they were lost for.
var found := PackedStringArray()
## The rooms of the maps won one after another, by the room's id, the latest last and each once,
## for the Department's keystone: a map lost or walked out of ends the run, see [method end_run].
var run := PackedStringArray()
## Which of [constant CardBack.STYLES] the cards this machine draws wear, GAME.md 8.9, as far as it
## has been won, see [method CardBack.worn].
var card_back := 0
## The laps of the roundabout won, GAME.md 8.9, printed on the card and the license.
var laps := 0
## How many maps in a row each thing of Lost Property could have lain in and did not, by its
## landmark's id: certain once it has missed two, GAME.md 8.9.
var lost_waits: Dictionary = {}
## The roundabout's ring of bets as it was last dealt, GAME.md 8.9: a dictionary each, the
## `stat` it reads, the `count` it asks and where the statistic was, `from`, as it was dealt.
var ring: Array[Dictionary] = []
## Each piece of dress moved up a finish, by its name, "hat:Fedora", to its finish, 1 to 3; and
## how many laps have paid an edition not yet chosen.
var editions: Dictionary = {}
var owed := 0
## The landmark pinned, to be kept in sight in the pause menu and beside a match's clock, GAME.md
## 8.9; or the roundabout; none for nothing pinned.
var pinned := &""


func read(file: ConfigFile) -> void:
	welcomed = bool(file.get_value(SECTION, "welcomed", false))
	toured = bool(file.get_value(SECTION, "toured", false))
	member = str(file.get_value(SECTION, "member", ""))
	won = _ids(file.get_value(SECTION, "won", PackedStringArray()))
	feats = _ids(file.get_value(SECTION, "feats", PackedStringArray()))
	found = _ids(file.get_value(SECTION, "found", PackedStringArray()))
	run = _ids(file.get_value(SECTION, "run", PackedStringArray()))
	card_back = maxi(int(file.get_value(SECTION, "card_back", 0)), 0)
	laps = maxi(int(file.get_value(SECTION, "laps", 0)), 0)
	ring.clear()
	var dealt: Variant = file.get_value(SECTION, "ring", [])
	if dealt is Array:
		for bet: Variant in dealt:
			if bet is Dictionary and bet.has("stat") and bet.has("count") and bet.has("from"):
				(
					ring
					. append(
						{
							"stat": str(bet["stat"]),
							"count": maxf(float(bet["count"]), 1.0),
							"from": float(bet["from"]),
						}
					)
				)
	editions = {}
	var finished: Variant = file.get_value(SECTION, "editions", {})
	if finished is Dictionary:
		for piece: Variant in finished:
			if piece is String and (finished[piece] is int or finished[piece] is float):
				editions[piece] = clampi(int(finished[piece]), 0, Loyalty.FINISHES.size())
	owed = maxi(int(file.get_value(SECTION, "owed", 0)), 0)
	pinned = StringName(str(file.get_value(SECTION, "pinned", "")))
	lost_waits = {}
	var waits: Variant = file.get_value(SECTION, "lost_waits", {})
	if waits is Dictionary:
		for id: Variant in waits:
			if id is String and (waits[id] is int or waits[id] is float):
				lost_waits[id] = clampi(int(waits[id]), 0, 99)
	dress_fresh = _ids(file.get_value(SECTION, "dress_fresh", PackedStringArray()))
	fresh = PackedStringArray()
	# Only what is won can be new.
	for id: String in _ids(file.get_value(SECTION, "fresh", PackedStringArray())):
		if id in won:
			fresh.append(id)


func write(file: ConfigFile) -> void:
	file.set_value(SECTION, "welcomed", welcomed)
	file.set_value(SECTION, "toured", toured)
	file.set_value(SECTION, "member", member)
	file.set_value(SECTION, "won", won)
	file.set_value(SECTION, "fresh", fresh)
	file.set_value(SECTION, "dress_fresh", dress_fresh)
	file.set_value(SECTION, "feats", feats)
	file.set_value(SECTION, "found", found)
	file.set_value(SECTION, "run", run)
	file.set_value(SECTION, "card_back", card_back)
	file.set_value(SECTION, "laps", laps)
	file.set_value(SECTION, "lost_waits", lost_waits)
	file.set_value(SECTION, "ring", ring)
	file.set_value(SECTION, "editions", editions)
	file.set_value(SECTION, "owed", owed)
	file.set_value(SECTION, "pinned", String(pinned))


## Whether the landmark [param id] has been won.
func has_won(id: StringName) -> bool:
	return String(id) in won


## The landmark [param id] is won, and new until the map has shown it, and the dress it pays new
## until the kart dialog has, but for a piece another landmark won paid already. True the first
## time.
func win(id: StringName) -> bool:
	if id == &"" or has_won(id):
		return false
	var had := Loyalty.dress_won(self)
	won.append(String(id))
	fresh.append(String(id))
	for piece: String in Loyalty.dress_won(self):
		if piece not in had:
			dress_new(piece)
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


## The piece of dress [param piece], "hat:Fedora", is new until the kart dialog has shown it under
## its cursor, GAME.md 4.4a: won, or moved up a finish.
func dress_new(piece: String) -> void:
	if piece not in dress_fresh:
		dress_fresh.append(piece)


## The kart dialog has shown [param piece] under its cursor. True if it was new until now.
func look_at_dress(piece: String) -> bool:
	var at := dress_fresh.find(piece)
	if at < 0:
		return false
	dress_fresh.remove_at(at)
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


## A map was won in the room [param id]: on the end of the run, which then goes back no further than
## the map won there before it, if it holds one, so it holds each room once.
func win_in(id: StringName) -> void:
	if id == &"":
		return
	var before := run.find(String(id))
	if before >= 0:
		run = run.slice(before + 1)
	run.append(String(id))


## A map was lost, or walked out of before its whistle: the run of maps won is over.
func end_run() -> void:
	run.clear()


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
