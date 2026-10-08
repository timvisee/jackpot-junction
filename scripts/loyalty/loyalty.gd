class_name Loyalty
extends RefCounted
## The rules of the loyalty program, GAME.md 8.9: when a landmark of its map is open, when its bet
## is met, and settling, which wins whatever is both. Everything counts all along, from a profile's
## first map, so a bet met while its landmark is closed is won the moment a road opens it. Settling
## is the one place anything is won: after a profile's statistics are written, as the program opens
## and as its card is activated.

## How a landmark stands on a profile's map, GAME.md 8.9: printed pale with only what it pays,
## printed in full with its bet and how far that has come, or stamped.
enum Standing { CLOSED, OPEN, WON }

## The program's map, GAME.md 8.9, The first map.
const MAP_PATH := "res://data/loyalty/map.tres"
## The power-ups of the later set, which the program adds to a table, GAME.md 7.1.
const LATER_SET := "res://data/powerups/later_set.tres"
## The most names a machine is heard to say it has added, of either kind: more than the game has.
const MOST_NAMES := 64
## The statistics and feats whose counts are distances in meters, and times in seconds, for
## [method count_text].
const METERS: Array[StringName] = [&"driven", &"drifted"]
const SECONDS: Array[StringName] = [&"nitro", &"no_deaths", &"no_shots"]

static var _map: LoyaltyMap


## The debug build's arguments for the loyalty program, GAME.md 8.9: `++ --loyalty-all` welcomes the
## profile playing in [param settings] and wins it every landmark, and `++ --loyalty-won=<ids>`
## welcomes it and wins the landmarks named, a comma between them; kept. Nothing in a released game.
static func read_arguments(args: PackedStringArray, settings: Settings) -> void:
	if not OS.is_debug_build():
		return
	var named := PackedStringArray()
	var all := "--loyalty-all" in args
	for arg: String in args:
		if arg.begins_with("--loyalty-won="):
			named.append_array(arg.get_slice("=", 1).split(",", false))
	if not all and named.is_empty():
		return
	var state := settings.profile.loyalty
	state.welcomed = true
	for each: LoyaltyLandmark in map().landmarks:
		if all or String(each.id) in named:
			state.win(each.id)
	settings.save_to_disk()


## The program's map, read once.
static func map() -> LoyaltyMap:
	if _map == null:
		_map = load(MAP_PATH) as LoyaltyMap if ResourceLoader.exists(MAP_PATH) else null
		if _map == null:
			_map = LoyaltyMap.new()
	return _map


## What [param profile]'s program has added, GAME.md 8.9: the jokers beyond those every deck
## starts with and the power-ups of the later set, for a table it deals, by name; and the dress it
## has won, by part and name, "hat:Fedora", see [method KartStyle.won_name]. Its machine tells a
## host all of it, see [method HostControls.tell_unlocks].
static func unlocks_of(profile: Profile) -> Dictionary:
	var jokers := PackedStringArray()
	var items := PackedStringArray()
	var dress := PackedStringArray()
	for each: LoyaltyLandmark in map().landmarks:
		if not profile.loyalty.has_won(each.id):
			continue
		for id: StringName in each.jokers:
			jokers.append(String(id))
		for id: StringName in each.items:
			items.append(String(id))
		if each.dress_part != &"":
			dress.append("%s:%s" % [each.dress_part, each.dress])
		dress.append_array(each.also)
	return {"jokers": jokers, "items": items, "dress": dress}


## What the owner of [param slot] has won to wear, GAME.md 8.9, by [method KartStyle.won_name]: a
## seat here its profile's, a guest's the profile playing's, and at a host a client's seat what that
## client told it, see [member NetDoor.unlocks]; nothing for anybody else.
static func dress_of(slot: PlayerSlot) -> PackedStringArray:
	var player := slot.input as PlayerInput
	if player != null and player.seat >= 0:
		var profile := MatchRecord.profile_of(slot)
		return unlocks_of(profile if profile != null else Game.settings.profile)["dress"]
	var session := Net.session
	if session == null or not session.is_host:
		return PackedStringArray()
	var told: Dictionary = session.door.unlocks.get(session._peer_slots.peer_at(slot.index), {})
	return _names(told.get("dress"))


## What the table at this machine deals beyond every table, GAME.md 8.9: the profile playing's
## program's, or at a dedicated server's game the program of whoever has the host's say there, as
## their machine said it, see [member NetDoor.unlocks]; nothing at a server nobody has the say of.
static func table_unlocks(dedicated: bool) -> Dictionary:
	if not dedicated:
		return unlocks_of(Game.settings.profile)
	var session := Net.session
	if session == null or session.host_controls == null or session.door == null:
		return {}
	return session.door.unlocks.get(session.host_controls.peer, {})


## Sets [param match_node]'s table as the loyalty program has it, GAME.md 8.9, before the match
## starts: [param items] as far as the table has the later set's, and the jokers of its deck, every
## joker still known by name. [param dedicated] for a dedicated server's game, which deals what the
## host's say has.
static func deal_table(match_node: Match, items: PowerUpTable, dedicated: bool) -> void:
	var table := table_unlocks(dedicated)
	match_node.power_ups = items_from(table, items)
	var catalog: JokerCatalog = match_node.joker_catalog
	if catalog == null:
		catalog = load("res://data/jokers/catalog.tres")
	match_node.joker_catalog = catalog.dealing(deck_from(table, catalog))


## Tells the host this machine is a client of what its program has added, after a settling that
## may have won more, see [method HostControls.tell_unlocks].
static func tell_host() -> void:
	if Net.session != null and Net.session.host_controls != null:
		Net.session.host_controls.tell_unlocks()


## [param unlocks] cleaned as they come off the wire: names, as many as there could be, and nothing
## else.
static func clean_unlocks(unlocks: Variant) -> Dictionary:
	var said: Dictionary = unlocks if unlocks is Dictionary else {}
	return {
		"jokers": _names(said.get("jokers")),
		"items": _names(said.get("items")),
		"dress": _names(said.get("dress")),
	}


## The jokers a table with [param unlocks] deals out of [param catalog]: those every deck starts
## with, and those added. A name the catalog does not know is no card.
static func deck_from(unlocks: Dictionary, catalog: JokerCatalog) -> Array[StringName]:
	var added := _names(unlocks.get("jokers"))
	var deck: Array[StringName] = []
	for joker: Joker in catalog.jokers:
		if joker.starting_deck or String(joker.id) in added:
			deck.append(joker.id)
	return deck


## [param table] as a table with [param unlocks] has it: the later set's power-ups only as far as
## they were added, GAME.md 7.1.
static func items_from(unlocks: Dictionary, table: PowerUpTable) -> PowerUpTable:
	var added := _names(unlocks.get("items"))
	var later := later_ids()
	var dealt := PowerUpTable.new()
	for entry: PowerUp in table.entries:
		if entry.id not in later or String(entry.id) in added:
			dealt.entries.append(entry)
	return dealt


## The ids of the later set's power-ups.
static func later_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: PowerUp in (load(LATER_SET) as PowerUpTable).entries:
		ids.append(entry.id)
	return ids


## Whether [param profile]'s own deck holds the joker [param joker], GAME.md 8.9.
static func in_deck(profile: Profile, joker: Joker) -> bool:
	return joker.starting_deck or String(joker.id) in _names(unlocks_of(profile)["jokers"])


## The landmark whose bet adds the joker or the power-up [param id], or null for one every table
## deals or no landmark pays.
static func adder_of(id: StringName) -> LoyaltyLandmark:
	for each: LoyaltyLandmark in map().landmarks:
		if id in each.jokers or id in each.items:
			return each
	return null


## What [param landmark]'s bet asks, its count as the map shows it, GAME.md 8.9.
static func bet_of(landmark: LoyaltyLandmark) -> String:
	return landmark.bet.replace("{count}", count_text(landmark))


## [param landmark]'s count as the map shows it: a distance in kilometers, a time in minutes, a
## share of shots in percent, and otherwise a number with its thousands marked.
static func count_text(landmark: LoyaltyLandmark) -> String:
	if landmark.stat in METERS:
		return "%s km" % _figure(landmark.count / 1000.0)
	if landmark.stat in SECONDS:
		var minutes := landmark.count / 60.0
		var many := "" if is_equal_approx(minutes, 1.0) else "s"
		return "%s minute%s" % [_figure(minutes), many]
	if landmark.stat == &"accuracy":
		return "%d%%" % roundi(landmark.count)
	return thousands(roundi(landmark.count))


## [param number] with a comma between its thousands, 5,000.
static func thousands(number: int) -> String:
	var figures := str(absi(number))
	var marked := ""
	while figures.length() > 3:
		marked = "," + figures.right(3) + marked
		figures = figures.left(figures.length() - 3)
	return ("-" if number < 0 else "") + figures + marked


## How [param landmark] stands on [param profile]'s map, see [enum Standing].
static func standing(profile: Profile, landmark: LoyaltyLandmark) -> Standing:
	if profile.loyalty.has_won(landmark.id):
		return Standing.WON
	return Standing.OPEN if is_open(profile, landmark, map()) else Standing.CLOSED


## Whether [param landmark] is drawn on [param profile]'s map at all: off the books is not, with
## the story off or no note found yet, and nothing shows where it would be.
static func is_drawn(profile: Profile, landmark: LoyaltyLandmark) -> bool:
	return district_open(profile, landmark.district)


## How far [param profile] has come with [param landmark]'s bet and out of how much, for its bar:
## a statistic, the notes found, the rooms won in for the Department's keystone. Nothing, (0, 0),
## for a bet that is done in one go, a feat of one map or a thing found.
static func progress(profile: Profile, landmark: LoyaltyLandmark) -> Vector2:
	var have := -1.0
	match landmark.kind:
		LoyaltyLandmark.Kind.STAT:
			have = maxf(LifetimeStats.value_of(profile, landmark.stat), 0.0)
		LoyaltyLandmark.Kind.NOTES:
			have = float(profile.story.notes.size()) if profile.story.on else 0.0
		LoyaltyLandmark.Kind.FEAT when landmark.stat == &"every_room":
			have = float(profile.loyalty.rooms.size())
	if have < 0.0:
		return Vector2.ZERO
	return Vector2(minf(have, landmark.count), landmark.count)


## [param landmark]'s bar in words, 312 / 500 km, or none for a bet with no bar, see
## [method progress].
static func progress_text(profile: Profile, landmark: LoyaltyLandmark) -> String:
	var come := progress(profile, landmark)
	if come.y <= 0.0:
		return ""
	return "%s / %s" % [_amount(landmark, come.x), count_text(landmark)]


## How near [param landmark]'s bet is to done, from 0 to 1, for the list of open bets: a bet done
## in one go is as far off as one not started.
static func nearness(profile: Profile, landmark: LoyaltyLandmark) -> float:
	var come := progress(profile, landmark)
	return come.x / come.y if come.y > 0.0 else 0.0


## Whether a landmark won on [param profile]'s map has not been shown under its cursor yet, so the
## title's Extras and the program's button wear a NEW tag, GAME.md 8.9. Only what is drawn.
static func has_fresh(profile: Profile) -> bool:
	for id: String in profile.loyalty.fresh:
		var landmark := map().landmark(StringName(id))
		if landmark != null and is_drawn(profile, landmark):
			return true
	return false


## [param value] of [param landmark]'s statistic as its count is shown, without the unit: 3.1 of
## 10 km, 1.5 of 3 minutes.
static func _amount(landmark: LoyaltyLandmark, value: float) -> String:
	if landmark.stat in METERS:
		return _figure(floorf(value / 100.0) / 10.0)
	if landmark.stat in SECONDS:
		return _figure(floorf(value / 6.0) / 10.0)
	return thousands(floori(value))


## [param value] to a tenth, without one for a whole number: 10, 2.5.
static func _figure(value: float) -> String:
	var tenths := roundi(value * 10.0)
	return str(roundi(tenths / 10.0)) if tenths % 10 == 0 else String.num(tenths / 10.0, 1)


static func _names(value: Variant) -> PackedStringArray:
	var names := PackedStringArray()
	if not (value is Array or value is PackedStringArray):
		return names
	for name: Variant in value:
		if names.size() >= MOST_NAMES:
			break
		if (name is String or name is StringName) and str(name) not in names:
			names.append(str(name))
	return names


## The landmarks of the program's map whose bets ask for the feat [param stat], GAME.md 8.9.
static func feats(stat: StringName) -> Array[LoyaltyLandmark]:
	var asking: Array[LoyaltyLandmark] = []
	for each: LoyaltyLandmark in map().landmarks:
		if each.kind == LoyaltyLandmark.Kind.FEAT and each.stat == stat:
			asking.append(each)
	return asking


## Wins every landmark of [param profile]'s program that is open and whose bet is met, on [param on]
## or the program's map, again and again while one won opens another already met. Returns those won,
## in the order they were.
static func settle(profile: Profile, on: LoyaltyMap = null) -> Array[LoyaltyLandmark]:
	var drawn := on if on != null else map()
	var won: Array[LoyaltyLandmark] = []
	var more := true
	while more:
		more = false
		for each: LoyaltyLandmark in drawn.landmarks:
			if profile.loyalty.has_won(each.id):
				continue
			if is_open(profile, each, drawn) and is_met(profile, each):
				profile.loyalty.win(each.id)
				won.append(each)
				more = true
	return won


## Whether [param district] is on [param profile]'s map: off the books only with the story on and
## a note of it found, STORY.md 6.6b; the rest always.
static func district_open(profile: Profile, district: LoyaltyLandmark.District) -> bool:
	if district == LoyaltyLandmark.District.OFF_THE_BOOKS:
		return profile.story.on and not profile.story.notes.is_empty()
	return true


## Whether [param landmark] is open on [param profile]'s map [param drawn]: its district open, and
## either open from the start of it or a road into it won, every road for a keystone. A road from a
## district that is not on the map opens nothing and holds no keystone shut.
static func is_open(profile: Profile, landmark: LoyaltyLandmark, drawn: LoyaltyMap) -> bool:
	if not district_open(profile, landmark.district):
		return false
	if landmark.entry:
		return true
	var through := false
	for id: StringName in drawn.roads_of(landmark.id):
		var other := drawn.landmark(id)
		if other == null or not district_open(profile, other.district):
			continue
		if profile.loyalty.has_won(id):
			through = true
		elif landmark.keystone:
			return false
	return through


## Whether [param profile] has done what [param landmark]'s bet asks, open or not.
static func is_met(profile: Profile, landmark: LoyaltyLandmark) -> bool:
	var state := profile.loyalty
	match landmark.kind:
		LoyaltyLandmark.Kind.CARD:
			return state.welcomed
		LoyaltyLandmark.Kind.STAT:
			return LifetimeStats.value_of(profile, landmark.stat) >= landmark.count
		LoyaltyLandmark.Kind.FEAT:
			return state.has_feat(landmark.id)
		LoyaltyLandmark.Kind.FIND:
			return state.has_found(landmark.id)
		LoyaltyLandmark.Kind.NOTES:
			return profile.story.on and profile.story.notes.size() >= int(landmark.count)
	return false
