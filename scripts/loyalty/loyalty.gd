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

## The roundabout's ring, GAME.md 8.9: how many bets a lap, what each lap's are as much again of,
## and the bets they are dealt from, the counts of the Strip and the Department, each the statistic
## it reads, its count on the first lap and how it reads, "{count}" its count.
const RING_BETS := 7
const RING_GROWTH := 1.5
const RING_POOL: Array[Array] = [
	[&"banks", 20.0, "Cash out {count} times"],
	[&"coins", 4000.0, "Pick up {count} chips"],
	[&"jokers", 40.0, "Take {count} jokers"],
	[&"driven", 15000.0, "Drive {count}"],
	[&"drifted", 3000.0, "Drift {count}"],
	[&"turbo_pads", 80.0, "{count} turbo pads"],
	[&"items", 40.0, "Use {count} power-ups"],
	[&"kills", 30.0, "Knock out {count} karts"],
	[&"flushes", 6.0, "{count} Royal Flushes"],
	[&"jackpot_chips", 800.0, "{count} chips out of the Jackpot"],
	[&"drift_boosts", 60.0, "{count} drift boosts"],
	[&"rams", 20.0, "Ram {count} karts"],
	[&"maps_won", 8.0, "Win {count} maps"],
	[&"nitro", 120.0, "Burn {count} of nitro"],
]
## The roundabout's place among the landmarks, for the cursor and the pane.
const ROUNDABOUT := &"roundabout"
## Where every profile's map starts, its one bet won by activating the card, GAME.md 8.9.
const SLIP_ROAD := &"slip_road"
## The finishes an edition moves a piece of dress up through, GAME.md 8.9, each over the last.
const FINISHES: Array[String] = ["Foil", "Holographic", "Polychrome"]

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
## profile playing in [param settings], its card numbered as the welcome would, and wins it every
## landmark, and `++ --loyalty-won=<ids>` welcomes it and wins the landmarks named, a comma between
## them; kept. `++ --loyalty-lap=<n>` wins it every landmark too and puts it on lap n of the
## roundabout, an edition owed for each lap and the ring dealt for that lap; kept.
## `++ --loyalty-near` welcomes it and puts every open bet of a statistic, and the ring's, a step
## short of its count, so the next map wins them, and `++ --loyalty-lost` makes every open thing of
## Lost Property certain in the next map of its room; kept. `++ --loyalty-pin=<id>` welcomes it and
## pins the landmark named where it can be pinned; kept. `++ --loyalty-welcome` puts the welcome up
## at the title whether or not it is due. Nothing in a released game.
static func read_arguments(args: PackedStringArray, settings: Settings) -> void:
	if not OS.is_debug_build():
		return
	if "--loyalty-welcome" in args:
		LoyaltyWelcome.again = true
	var named := PackedStringArray()
	var all := "--loyalty-all" in args
	var near := "--loyalty-near" in args
	var lost := "--loyalty-lost" in args
	var lap := -1
	var pin := &""
	for arg: String in args:
		if arg.begins_with("--loyalty-pin="):
			pin = StringName(arg.get_slice("=", 1))
		elif arg.begins_with("--loyalty-won="):
			named.append_array(arg.get_slice("=", 1).split(",", false))
		elif arg.begins_with("--loyalty-lap="):
			lap = maxi(0, arg.get_slice("=", 1).to_int())
			all = true
	if not all and named.is_empty() and not near and not lost and pin == &"":
		return
	var state := settings.profile.loyalty
	state.welcomed = true
	LoyaltyWelcome.number_for(settings.profile)
	for each: LoyaltyLandmark in map().landmarks:
		if all or String(each.id) in named:
			state.win(each.id)
	if lap >= 0:
		state.laps = lap
		state.owed = lap
		deal_ring(settings.profile)
	settle(settings.profile)
	if near:
		near_everything(settings.profile)
	if lost:
		lost_certain(settings.profile)
	if pin != &"" and can_pin(settings.profile, pin):
		state.pinned = pin
	settings.save_to_disk()


## Every open thing of Lost Property of [param profile]'s certain in the next map of its room, for a
## debug build, see [method read_arguments].
static func lost_certain(profile: Profile) -> void:
	for each: LoyaltyLandmark in map().landmarks:
		if each.kind == LoyaltyLandmark.Kind.FIND:
			profile.loyalty.lost_waits[String(each.id)] = LostProperty.CERTAIN_AFTER


## [param profile] on its next lap of the roundabout at once, an edition owed for it and its ring
## dealt again, for a debug build, see [StoryDebugTab].
static func next_lap(profile: Profile) -> void:
	profile.loyalty.laps += 1
	profile.loyalty.owed += 1
	deal_ring(profile)


## Every open bet of a statistic of [param profile]'s, and every bet of its ring, a step short of
## its count: a meter or so of driving, a second or two, or one, for a debug build; see
## [method read_arguments].
static func near_everything(profile: Profile) -> void:
	for each: LoyaltyLandmark in map().landmarks:
		if each.kind == LoyaltyLandmark.Kind.STAT and standing(profile, each) == Standing.OPEN:
			profile.stats[each.stat] = maxf(each.count - _step_of(each.stat), 0.0)
	for bet: Dictionary in profile.loyalty.ring:
		var stat := StringName(bet["stat"])
		var short := maxf(float(bet["count"]) - _step_of(stat), 0.0)
		profile.stats[stat] = float(bet["from"]) + short


static func _step_of(stat: StringName) -> float:
	if stat in METERS:
		return 30.0
	if stat in SECONDS:
		return 2.0
	return 1.0


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
	var editions := PackedStringArray()
	for piece: Variant in profile.loyalty.editions:
		editions.append("%s=%d" % [piece, int(profile.loyalty.editions[piece])])
	return {
		"jokers": jokers,
		"items": items,
		"dress": dress,
		"editions": editions,
		"kit": KitCards.flag_of(profile),
	}


## The dress the landmarks [param state] has won pay, GAME.md 8.9, by part and name, "hat:Fedora",
## see [method KartStyle.won_name], in the map's order, as [method unlocks_of] has it.
static func dress_won(state: LoyaltyState) -> PackedStringArray:
	var dress := PackedStringArray()
	for each: LoyaltyLandmark in map().landmarks:
		if not state.has_won(each.id):
			continue
		if each.dress_part != &"":
			dress.append("%s:%s" % [each.dress_part, each.dress])
		dress.append_array(each.also)
	return dress


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


## The finish the owner of [param slot] has moved the piece [param piece] up to, as
## [method dress_of] finds whose it is: a seat here its profile's, a guest's the profile playing's,
## and at a host a client's seat as that client said; none for anybody else.
static func finish_for(slot: PlayerSlot, piece: String) -> int:
	var player := slot.input as PlayerInput
	if player != null and player.seat >= 0:
		var profile := MatchRecord.profile_of(slot)
		return finish_of(profile if profile != null else Game.settings.profile, piece)
	var session := Net.session
	if session == null or not session.is_host:
		return 0
	var told: Dictionary = session.door.unlocks.get(session._peer_slots.peer_at(slot.index), {})
	for said: String in _names(told.get("editions")):
		if said.get_slice("=", 0) == piece:
			return clampi(said.get_slice("=", 1).to_int(), 0, FINISHES.size())
	return 0


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
		"editions": _names(said.get("editions")),
		"kit": _names(said.get("kit")),
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


## How far [param profile] has come with [param landmark]'s bet and out of how much, for its bar: a
## statistic, the notes found, the maps won in a row for the Department's keystone. Nothing, (0, 0),
## for a bet that is done in one go, a feat of one map or a thing found.
static func progress(profile: Profile, landmark: LoyaltyLandmark) -> Vector2:
	var have := -1.0
	match landmark.kind:
		LoyaltyLandmark.Kind.STAT:
			have = maxf(LifetimeStats.value_of(profile, landmark.stat), 0.0)
		LoyaltyLandmark.Kind.NOTES:
			have = float(profile.story.story_notes()) if profile.story.on else 0.0
		LoyaltyLandmark.Kind.FEAT when landmark.stat == &"rooms_in_a_row":
			have = float(profile.loyalty.run.size())
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
## title's Clubhouse and the program's button wear a NEW tag, GAME.md 8.9. Only what is drawn.
static func has_fresh(profile: Profile) -> bool:
	for id: String in profile.loyalty.fresh:
		var landmark := map().landmark(StringName(id))
		if landmark != null and is_drawn(profile, landmark):
			return true
	return false


## What [param landmark]'s reward says as it is paid at [param stage], STORY.md 6.6b: cards added to
## the deck, items added to the tables, or dress and the rest issued.
static func reward_words(landmark: LoyaltyLandmark, stage: int) -> String:
	if not landmark.jokers.is_empty():
		return str(StoryLines.at(StoryLines.REWARD_CARDS, stage))
	if not landmark.items.is_empty():
		return str(StoryLines.at(StoryLines.REWARD_ITEMS, stage))
	return str(StoryLines.at(StoryLines.REWARD_DRESS, stage))


## Whether the Showroom off the Garage is open for [param profile], GAME.md 8.9: the landmark that
## opens it won.
static func showroom_open(profile: Profile) -> bool:
	for each: LoyaltyLandmark in map().landmarks:
		if each.showroom and profile.loyalty.has_won(each.id):
			return true
	return false


## The endorsements [param profile]'s program has stamped on its license, GAME.md 8.9, in the map's
## order.
static func endorsements_of(profile: Profile) -> PackedStringArray:
	var stamped := PackedStringArray()
	for each: LoyaltyLandmark in map().landmarks:
		if not each.endorsement.is_empty() and profile.loyalty.has_won(each.id):
			stamped.append(each.endorsement)
	return stamped


## Whether [param landmark]'s bet is met for [param profile] as it stands now in a room, its
## statistic counted with what [param slot] has done in it since [param since]: so a count reached
## in the middle of a map is known there and then, GAME.md 8.9, though it is won as the map is
## written down.
static func is_met_live(
	profile: Profile, landmark: LoyaltyLandmark, slot: PlayerSlot, since: Dictionary
) -> bool:
	if landmark.kind != LoyaltyLandmark.Kind.STAT or slot == null:
		return is_met(profile, landmark)
	return LifetimeStats.live_value(profile, slot, landmark.stat, since) >= landmark.count


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
	if on == null:
		settle_ring(profile)
	# A bet pinned and won is done with: nothing is pinned until another is.
	if profile.loyalty.pinned != &"" and profile.loyalty.has_won(profile.loyalty.pinned):
		profile.loyalty.pinned = &""
	return won


## The open bet nearest the slip road on [param profile]'s map, GAME.md 8.9, off the books left
## out: the fewest roads from it, and of those the one come furthest; none with nothing open.
static func nearest_open(profile: Profile) -> StringName:
	var drawn := map()
	var seen := {SLIP_ROAD: true}
	var ring: Array[StringName] = [SLIP_ROAD]
	while not ring.is_empty():
		var best := &""
		var nearest := -1.0
		var next: Array[StringName] = []
		for id: StringName in ring:
			var landmark := drawn.landmark(id)
			if (
				landmark != null
				and landmark.district != LoyaltyLandmark.District.OFF_THE_BOOKS
				and standing(profile, landmark) == Standing.OPEN
				and nearness(profile, landmark) > nearest
			):
				best = id
				nearest = nearness(profile, landmark)
			for other: StringName in drawn.roads_of(id):
				if not seen.has(other):
					seen[other] = true
					next.append(other)
		if best != &"":
			return best
		ring = next
	return &""


## What [param profile] has pinned, GAME.md 8.9, while it is still to be had: an open landmark on
## its map, or the roundabout once it is open; none otherwise.
static func pinned_of(profile: Profile) -> StringName:
	var id := profile.loyalty.pinned
	if id == ROUNDABOUT:
		return id if ring_open(profile) else &""
	var landmark := map().landmark(id)
	if landmark == null or not is_drawn(profile, landmark):
		return &""
	return id if standing(profile, landmark) == Standing.OPEN else &""


## Whether [param id] may be pinned on [param profile]'s map: an open landmark, or the open
## roundabout.
static func can_pin(profile: Profile, id: StringName) -> bool:
	if id == ROUNDABOUT:
		return ring_open(profile)
	var landmark := map().landmark(id)
	return (
		landmark != null
		and is_drawn(profile, landmark)
		and standing(profile, landmark) == Standing.OPEN
	)


## How far what [param profile] has pinned has come, counted live for [param slot] of a map being
## played, from [param since]: the roundabout's ring by its bets met; zero with nothing pinned.
static func pinned_progress(profile: Profile, slot: PlayerSlot = null, since := {}) -> Vector2:
	var id := pinned_of(profile)
	if id == ROUNDABOUT:
		var met := 0
		for bet: Dictionary in profile.loyalty.ring:
			var come := ring_progress(profile, bet)
			met += 1 if come.x >= come.y else 0
		return Vector2(met, profile.loyalty.ring.size())
	var landmark := map().landmark(id)
	if landmark == null:
		return Vector2.ZERO
	return progress_live(profile, landmark, slot, since)


## What what [param profile] has pinned asks, in words; none with nothing pinned.
static func pinned_bet(profile: Profile) -> String:
	var id := pinned_of(profile)
	if id == ROUNDABOUT:
		return LoyaltyPane.RING_ASKS
	var landmark := map().landmark(id)
	return bet_of(landmark) if landmark != null else ""


## What is pinned, in words: its name and how far it has come, counted live for [param slot] of a
## map being played, from [param since], see [method LifetimeStats.live_value]; none with nothing
## pinned.
static func pinned_words(profile: Profile, slot: PlayerSlot = null, since := {}) -> Array[String]:
	return words_of(profile, pinned_of(profile), slot, since)


## [param id] in words as a pin says it, its name and how far it has come, counted live as
## [method pinned_words] counts it, whether it is pinned or not; none for none.
static func words_of(
	profile: Profile, id: StringName, slot: PlayerSlot = null, since := {}
) -> Array[String]:
	if id == &"":
		return []
	if id == ROUNDABOUT:
		var met := 0
		for bet: Dictionary in profile.loyalty.ring:
			var come := ring_progress(profile, bet)
			met += 1 if come.x >= come.y else 0
		return [LoyaltyPane.ROUNDABOUT, LoyaltyPane.RING_COME % [met, profile.loyalty.ring.size()]]
	var landmark := map().landmark(id)
	var come := progress_live(profile, landmark, slot, since)
	var said := bet_of(landmark)
	if come.y > 0.0:
		said = "%s / %s" % [_amount(landmark, come.x), count_text(landmark)]
	return [landmark.title, said]


## How far [param landmark]'s bet has come as [method progress] has it, a statistic's counted live
## for [param slot] of a map being played, from [param since].
static func progress_live(
	profile: Profile, landmark: LoyaltyLandmark, slot: PlayerSlot, since: Dictionary
) -> Vector2:
	var come := progress(profile, landmark)
	if slot == null or landmark.kind != LoyaltyLandmark.Kind.STAT or come.y <= 0.0:
		return come
	var live := LifetimeStats.live_value(profile, slot, landmark.stat, since)
	return Vector2(minf(maxf(live, 0.0), landmark.count), landmark.count)


## Whether the roundabout is open for [param profile], GAME.md 8.9: every keystone of the house's
## on a road into it won.
static func ring_open(profile: Profile) -> bool:
	var keystones := 0
	for each: LoyaltyLandmark in map().landmarks:
		if each.keystone and map().reaches_roundabout(each.id):
			keystones += 1
			if not profile.loyalty.has_won(each.id):
				return false
	return keystones > 0


## Settles [param profile]'s ring, GAME.md 8.9: dealt as the roundabout opens; every bet of it met
## is a lap, printed on the card and the license and paying an edition, and the ring dealt again,
## each bet half as much again as the last lap's of its kind. Nothing is ever taken back. Returns
## the laps won.
static func settle_ring(profile: Profile) -> int:
	if not ring_open(profile):
		return 0
	var state := profile.loyalty
	if state.ring.is_empty():
		deal_ring(profile)
	var laps := 0
	while not state.ring.is_empty() and _ring_met(profile):
		state.laps += 1
		state.owed += 1
		laps += 1
		deal_ring(profile)
	return laps


## A new ring for [param profile] at its lap now: [constant RING_BETS] bets drawn from the pool, the
## same for the same member and lap, each counted from where its statistic is now.
static func deal_ring(profile: Profile) -> void:
	var state := profile.loyalty
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d" % [state.member, state.laps])
	var pool := range(RING_POOL.size())
	var ring: Array[Dictionary] = []
	for i: int in mini(RING_BETS, pool.size()):
		var pick: int = pool.pop_at(rng.randi_range(0, pool.size() - 1))
		var kind: Array = RING_POOL[pick]
		(
			ring
			. append(
				{
					"stat": String(kind[0]),
					"count": _round_count(float(kind[1]) * pow(RING_GROWTH, state.laps)),
					"from": LifetimeStats.value_of(profile, kind[0]),
				}
			)
		)
	state.ring = ring


## How far [param profile] has come with the ring's bet [param bet], and out of how much.
static func ring_progress(profile: Profile, bet: Dictionary) -> Vector2:
	var have := LifetimeStats.value_of(profile, StringName(bet["stat"])) - float(bet["from"])
	return Vector2(clampf(have, 0.0, float(bet["count"])), float(bet["count"]))


## The ring's bet [param bet] in words, its count as the map shows one.
static func ring_bet_of(bet: Dictionary) -> String:
	var asks := _ring_landmark(bet)
	for kind: Array in RING_POOL:
		if String(kind[0]) == String(bet["stat"]):
			return str(kind[2]).replace("{count}", count_text(asks))
	return String(bet["stat"])


## The ring's bet [param bet]'s bar in words, 312 / 500 km.
static func ring_progress_text(profile: Profile, bet: Dictionary) -> String:
	var come := ring_progress(profile, bet)
	return "%s / %s" % [_amount(_ring_landmark(bet), come.x), count_text(_ring_landmark(bet))]


## A landmark standing for the ring's bet [param bet], for the words of its count.
static func _ring_landmark(bet: Dictionary) -> LoyaltyLandmark:
	var asks := LoyaltyLandmark.new()
	asks.stat = StringName(bet["stat"])
	asks.count = float(bet["count"])
	return asks


static func _ring_met(profile: Profile) -> bool:
	for bet: Dictionary in profile.loyalty.ring:
		var come := ring_progress(profile, bet)
		if come.x < come.y:
			return false
	return true


## [param value] to two figures, so a lap's counts read as round numbers: 30, 45, 67, 100, 150.
static func _round_count(value: float) -> float:
	if value < 10.0:
		return roundf(value)
	var figures := pow(10.0, floorf(log(value) / log(10.0)) - 1.0)
	return roundf(value / figures) * figures


## The finish [param profile] has moved the piece of dress [param piece] up to, "hat:Fedora", 0 for
## none.
static func finish_of(profile: Profile, piece: String) -> int:
	return int(profile.loyalty.editions.get(piece, 0))


## [param profile] spends an edition on [param piece]: it moves up a finish, as far as the last,
## and is new in the kart dialog until it has been seen there in it, GAME.md 4.4a. False with none
## owed, or for a piece not won or already at its last finish.
static func spend_edition(profile: Profile, piece: String) -> bool:
	var state := profile.loyalty
	if state.owed <= 0 or piece not in _names(unlocks_of(profile)["dress"]):
		return false
	var finish := finish_of(profile, piece)
	if finish >= FINISHES.size():
		return false
	state.editions[piece] = finish + 1
	state.owed -= 1
	state.dress_new(piece)
	return true


## [param style], numbers as a seat keeps them, with the finishes [param profile] has moved its
## pieces up to after them, as a kart wears them on every screen, GAME.md 8.9.
static func with_finishes(profile: Profile, style: PackedInt32Array) -> PackedInt32Array:
	var dressed := KartStyle.from_array(style)
	var choices := dressed.to_array()
	for part: int in KartStyle.CHOICES.size():
		var index := choices[part]
		dressed.finishes[part] = (
			finish_of(profile, KartStyle.won_name(part, index))
			if index > 0 and profile != null
			else 0
		)
	return dressed.to_array()


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
			return profile.story.on and profile.story.story_notes() >= int(landmark.count)
	return false
