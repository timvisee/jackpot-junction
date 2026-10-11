class_name LoyaltyRecord
extends Node
## Keeps the feats the players at this machine do for their loyalty programs, GAME.md 8.9, see
## [Loyalty]: the ones done in a moment, a cash-out at a mult, a pot of seven chips, a full hand, a
## rare card burned, a pot driven off the Junction, as they happen; and the ones a whole map makes,
## a map without dying or without a shot, a share of shots landed, a map won without ever taking a
## joker or from behind at Last Call, every pick turned down, a map won in each room, as the map is
## written down, see [method map_played]. Whose they are is found as [MatchRecord] finds it: the
## first seat's go to the profile playing, a seat another profile sits in to that one, and a
## guest's, a bot's or a player's elsewhere to nobody. Every machine hears its own seats' cash-outs
## and hands anyway, a client from its host, and its own picks and menus where they are answered, so
## nothing of it goes over the wire. A feat off the books counts only with the story on. Kept in the
## profiles as it happens and written as the room is left, in [constant MatchRecord.GROUP]. Only the
## room the game is in keeps anything, and never headless.
##
## A bet met in a room is known there and then, GAME.md 8.9: a feat as it is done, a count as the
## room's own statistics take it past the bet's, see [method Loyalty.is_met_live], and BET WON goes
## to the player's corner, see [LoyaltyStamp], though it is won as the room is written down. And
## once it is, what each profile at this machine won in it and came nearer to is reported for the
## payout slip's page of the program, see [signal reported].

## The map has been written down and settled: [param report], a dictionary each for every profile
## at this machine that won a bet or came nearer one, see [method settled].
signal reported(report: Array[Dictionary])
## A bet of [param landmark]'s met in the room by the player in slot [param slot], there and then.
signal bet_won(slot: int, landmark: LoyaltyLandmark)

## The rooms a map has to be won in, one each, for the Department's keystone, GAME.md 8.9.
const ROOMS: Array[StringName] = [&"workbench", &"after_hours", &"the_yard"]
## How many shots a map's share of them landed is counted over at the least, GAME.md 8.9.
const AIMED_SHOTS := 30
## How far past a Junction's edge a kart has to be to have driven off it, in meters: a kart on the
## rim is still on it.
const OFF_THE_PAD := 0.3
## How often the counts are looked at for a bet met, in seconds, and how many of the bets come
## nearest to the slip's page names for each profile.
const CHECK := 0.25
const NEAREST := 3

## For a test: feats are kept wherever the room is, headless or not.
static var anywhere := false

var match_node: Match
## What the room's settling reported, once it has been written down.
var report: Array[Dictionary] = []

## Whether anything was kept since the profiles were last written, and whose.
var _kept: Array[Profile] = []
## By slot, the respawn picks turned down and taken from in this map, see [method _on_answered].
var _skipped: Dictionary[int, int] = {}
var _picked: Dictionary[int, int] = {}
## Each slot's jokers dropped on the floor in this map, and power-ups picked up in it.
var _dropped: Dictionary[int, int] = {}
var _items: Dictionary[int, int] = {}
## The slots that have had a joker in hand at all in this map, taken in it or kept from the last.
var _had_jokers: Dictionary[int, bool] = {}
## Whether Last Call has begun, and the slots that were leading as it did.
var _last_call := false
var _leading: Array[int] = []
## The slots in the middle of a cash-out, which have not yet been paid it or driven off.
var _banking: Dictionary[int, bool] = {}
## Each profile's program as the room found it, by the profile: what it had won and how near each
## open bet was, for the slip's page; and the bets already stamped BET WON here, by the profile's
## and the landmark's ids.
var _before: Dictionary[Profile, Dictionary] = {}
var _announced: Dictionary[String, bool] = {}
var _checked := 0.0


static func add_to(in_match: Match) -> LoyaltyRecord:
	var record := LoyaltyRecord.new()
	record.name = "LoyaltyRecord"
	record.match_node = in_match
	in_match.add_child(record)
	return record


func _ready() -> void:
	add_to_group(MatchRecord.GROUP)
	for pair: Array in _listens():
		(pair[0] as Signal).connect(pair[1])


func _exit_tree() -> void:
	for pair: Array in _listens():
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])
	leave()


func _listens() -> Array[Array]:
	return [
		[Events.bank_started, _on_bank_started],
		[Events.bank_completed, _on_bank_completed],
		[Events.kart_killed, _on_kart_killed],
		[Events.joker_answered, _on_answered],
		[Events.joker_taken, _on_taken],
		[Events.joker_destroyed, _on_destroyed],
		[Events.joker_left, _on_left],
		[Events.item_picked, _on_item_picked],
		[Events.match_state_changed, _on_state],
		[Events.player_joined, _on_player_joined],
	]


## The room is being left: whatever was kept in it is settled and written down, once.
func leave() -> void:
	if _kept.is_empty():
		return
	for profile: Profile in _kept:
		Loyalty.settle(profile)
	_kept.clear()
	# Never headless: a test's room freed after the player's own settings are back would write them.
	if not Game.is_headless():
		Game.settings.save_to_disk()
	Loyalty.tell_host()


func _process(delta: float) -> void:
	if not _keeps():
		return
	_checked += delta
	var check := _checked >= CHECK
	if check:
		_checked = 0.0
	for slot: PlayerSlot in match_node.slots:
		var profile := MatchRecord.profile_of(slot)
		if profile != null:
			_found(profile)
			if check:
				_check_bets(slot, profile)
		var kart := slot.kart
		if kart == null or profile == null:
			continue
		if kart.jokers != null and kart.jokers.count() > 0:
			_had_jokers[slot.index] = true
			_held(slot.index, kart.jokers.count())
		if _banking.get(slot.index, false):
			_watch_banking(slot)


## A kart in the middle of a cash-out: once it is off every Junction alive, with chips still in the
## pot, it has driven off with them, GAME.md 8.9.
func _watch_banking(slot: PlayerSlot) -> void:
	var kart := slot.kart
	if not kart.alive or kart.pot.is_empty():
		_banking.erase(slot.index)
		return
	if _on_a_junction(kart):
		return
	_banking.erase(slot.index)
	for landmark: LoyaltyLandmark in Loyalty.feats(&"walk_away"):
		if kart.pot.coins >= landmark.count:
			_feat(MatchRecord.profile_of(slot), landmark)


func _on_a_junction(kart: Kart) -> bool:
	if match_node.arena == null:
		return false
	var at := Vector2(kart.global_position.x, kart.global_position.z)
	for pad: JunctionPad in match_node.arena.junctions:
		var middle := Vector2(pad.global_position.x, pad.global_position.z)
		if at.distance_to(middle) <= pad.radius + OFF_THE_PAD:
			return true
	return false


func _on_bank_started(slot: int) -> void:
	if _profile_at(slot) != null:
		_banking[slot] = true


func _on_bank_completed(slot: int, coins: int, mult: float, total: int) -> void:
	_banking.erase(slot)
	var profile := _profile_at(slot)
	if profile == null:
		return
	var kart := match_node.slots[slot].kart
	if kart != null and kart.jokers != null and kart.jokers.count() == 0:
		for landmark: LoyaltyLandmark in Loyalty.feats(&"empty_hand_bank"):
			if total >= roundi(landmark.count):
				_feat(profile, landmark)
	for landmark: LoyaltyLandmark in Loyalty.feats(&"cash_out_mult"):
		if mult >= landmark.count:
			_feat(profile, landmark)
	for landmark: LoyaltyLandmark in Loyalty.feats(&"exact_pot"):
		if coins == roundi(landmark.count):
			_feat(profile, landmark)


func _on_kart_killed(victim: int, _killer: int, _cause: StringName) -> void:
	_banking.erase(victim)


func _on_answered(slot: int, joker: StringName) -> void:
	var counts := _skipped if joker == &"" else _picked
	counts[slot] = counts.get(slot, 0) + 1
	if joker != &"":
		_had_jokers[slot] = true


## [param slot] took a joker, off a pad or off the floor: no map won without ever taking one.
func _on_taken(slot: int, _joker: StringName) -> void:
	_had_jokers[slot] = true


func _on_destroyed(slot: int, joker: StringName) -> void:
	var card := match_node.joker_catalog.by_id(joker) if match_node.joker_catalog != null else null
	if card != null and card.rarity == Joker.Rarity.RARE:
		_done(slot, &"destroy_rare")


func _on_state(state: int) -> void:
	if state != Match.State.LAST_CALL or _last_call or not is_instance_valid(match_node):
		return
	_last_call = true
	var ranked := match_node.standings()
	for slot: PlayerSlot in ranked:
		if slot.banked == ranked[0].banked:
			_leading.append(slot.index)


## Somebody sat down at [param slot]: the picks made there before were somebody else's.
func _on_player_joined(slot: int) -> void:
	_skipped.erase(slot)
	_picked.erase(slot)
	_dropped.erase(slot)
	_items.erase(slot)
	_had_jokers.erase(slot)


## [param slot] dropped a joker on the floor: Kit's bet of a full hand's worth left lying in one
## map, 8.9.
func _on_left(slot: int, _joker: StringName) -> void:
	_dropped[slot] = _dropped.get(slot, 0) + 1
	var profile := _profile_at(slot)
	if profile == null:
		return
	for landmark: LoyaltyLandmark in Loyalty.feats(&"jokers_dropped"):
		if _dropped[slot] >= roundi(landmark.count):
			_feat(profile, landmark)


func _on_item_picked(slot: int, _item: StringName) -> void:
	_items[slot] = _items.get(slot, 0) + 1


## [param profile]'s program as the room first finds it, kept for the slip's page.
func _found(profile: Profile) -> void:
	if _before.has(profile):
		return
	var near := {}
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		near[each.id] = Loyalty.nearness(profile, each)
	_before[profile] = {
		"won": profile.loyalty.won.duplicate(), "near": near, "laps": profile.loyalty.laps
	}


## Every open bet of [param profile]'s that [param slot] has met in the room by now: BET WON to its
## corner, once each.
func _check_bets(slot: PlayerSlot, profile: Profile) -> void:
	if not profile.loyalty.welcomed:
		return
	var since := MatchRecord.since_of(match_node, slot)
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		var key := "%d|%s" % [profile.get_instance_id(), each.id]
		if _announced.has(key) or profile.loyalty.has_won(each.id):
			continue
		if not Loyalty.is_drawn(profile, each):
			continue
		if Loyalty.standing(profile, each) != Loyalty.Standing.OPEN:
			continue
		if Loyalty.is_met_live(profile, each, slot, since):
			_announced[key] = true
			bet_won.emit(slot.index, each)
			if match_node.hud != null:
				LoyaltyStamp.show_beside(match_node.hud, slot.index, each)


## [param in_match] has been written down: its settling reported for every profile in
## [param written] that won a bet in it or came nearer one, see [signal reported]. A profile not
## welcomed to the program yet has nothing reported: nothing says there is one until then.
static func settled(in_match: Match, written: Array[Profile]) -> void:
	var record := in_match.get_node_or_null("LoyaltyRecord") as LoyaltyRecord if in_match else null
	if record == null:
		return
	record.report.clear()
	for profile: Profile in written:
		if not profile.loyalty.welcomed:
			continue
		var line := record.report_of(profile)
		var laps: int = line["laps"]
		if not (line["won"] as Array).is_empty() or not (line["kit"] as Array).is_empty():
			record.report.append(line)
		elif laps > 0:
			record.report.append(line)
		elif not (line["nearer"] as Array).is_empty():
			record.report.append(line)
	record.reported.emit(record.report)


## What [param profile] won in the room and came nearer to, against how the room found it: its
## `name`, the house's bets `won`, the bets won off the books, `kit`, and the open bets it came
## `nearer` to, nearest first, as many as [constant NEAREST].
func report_of(profile: Profile) -> Dictionary:
	_found(profile)
	var before: Dictionary = _before[profile]
	var had: PackedStringArray = before["won"]
	var near: Dictionary = before["near"]
	var won: Array[LoyaltyLandmark] = []
	var kit: Array[LoyaltyLandmark] = []
	var nearer: Array[LoyaltyLandmark] = []
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		if not Loyalty.is_drawn(profile, each):
			continue
		if profile.loyalty.has_won(each.id):
			if String(each.id) not in had:
				if each.district == LoyaltyLandmark.District.OFF_THE_BOOKS:
					kit.append(each)
				else:
					won.append(each)
		elif Loyalty.standing(profile, each) == Loyalty.Standing.OPEN:
			if Loyalty.nearness(profile, each) > float(near.get(each.id, 0.0)) + 0.0001:
				nearer.append(each)
	nearer.sort_custom(
		func(a: LoyaltyLandmark, b: LoyaltyLandmark) -> bool:
			return Loyalty.nearness(profile, a) > Loyalty.nearness(profile, b)
	)
	return {
		"profile": profile,
		"name": LoyaltyCard.holder_of(profile),
		"won": won,
		"kit": kit,
		"nearer": nearer.slice(0, NEAREST),
		"laps": profile.loyalty.laps - int(before.get("laps", profile.loyalty.laps)),
	}


## [param slot] holds [param held] jokers at once, a Deep Pockets one of them: every bet of a hand
## that big is met.
func _held(slot: int, held: int) -> void:
	var profile := _profile_at(slot)
	if profile == null:
		return
	for landmark: LoyaltyLandmark in Loyalty.feats(&"jokers_held"):
		if held >= roundi(landmark.count):
			_feat(profile, landmark)


## [param slot] did the feat [param stat]: every landmark asking for it is told.
func _done(slot: int, stat: StringName) -> void:
	var profile := _profile_at(slot)
	if profile == null:
		return
	for landmark: LoyaltyLandmark in Loyalty.feats(stat):
		_feat(profile, landmark)


## [param profile] did what [param landmark]'s bet asks, kept unless it is off the books with the
## story off, STORY.md 10.
func _feat(profile: Profile, landmark: LoyaltyLandmark) -> void:
	if landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS and not profile.story.on:
		return
	if profile.loyalty.do_feat(landmark.id) and profile not in _kept:
		_kept.append(profile)


## The profile [param slot] plays into, or null for nobody's or a room that keeps nothing.
func _profile_at(slot: int) -> Profile:
	if not _keeps() or slot < 0 or slot >= match_node.slots.size():
		return null
	return MatchRecord.profile_of(match_node.slots[slot])


## Whether this room keeps what is done in it: the room the game is in, never headless.
func _keeps() -> bool:
	if not is_instance_valid(match_node) or not is_inside_tree():
		return false
	var scene := get_tree().current_scene
	var here := scene != null and scene.is_ancestor_of(self) and not Game.is_headless()
	return here or anywhere


## [param slot] of [param in_match] played a map to its whistle for [param profile], GAME.md 8.9:
## for [param seconds] of it, counting from [param since] as [LifetimeStats.share_of] has it, and
## [param won] it or not. The feats a whole map makes are kept; [MatchRecord] settles and writes.
static func map_played(
	in_match: Match,
	slot: PlayerSlot,
	profile: Profile,
	seconds: float,
	since: Dictionary,
	won: bool
) -> void:
	var record := in_match.get_node_or_null("LoyaltyRecord") as LoyaltyRecord
	if record == null:
		return
	var deaths := slot.stats.value(&"deaths") - float(since.get(&"deaths", 0.0))
	var shots := slot.stats.value(&"bullets") - float(since.get(&"bullets", 0.0))
	var hits := slot.stats.value(&"hits") - float(since.get(&"hits", 0.0))
	for landmark: LoyaltyLandmark in Loyalty.feats(&"no_deaths"):
		if seconds >= landmark.count and deaths <= 0.0:
			record._feat(profile, landmark)
	for landmark: LoyaltyLandmark in Loyalty.feats(&"no_shots"):
		if seconds >= landmark.count and shots <= 0.0:
			record._feat(profile, landmark)
	for landmark: LoyaltyLandmark in Loyalty.feats(&"accuracy"):
		if shots >= AIMED_SHOTS and hits * 100.0 >= landmark.count * shots:
			record._feat(profile, landmark)
	for landmark: LoyaltyLandmark in Loyalty.feats(&"skip_all"):
		var skipped: int = record._skipped.get(slot.index, 0)
		if skipped >= landmark.count and record._picked.get(slot.index, 0) == 0:
			record._feat(profile, landmark)
	if not won:
		return
	var holds := slot.kart != null and slot.kart.jokers != null and slot.kart.jokers.count() > 0
	if not holds and not record._had_jokers.get(slot.index, false):
		for landmark: LoyaltyLandmark in Loyalty.feats(&"jokerless_win"):
			record._feat(profile, landmark)
	if record._items.get(slot.index, 0) == 0:
		for landmark: LoyaltyLandmark in Loyalty.feats(&"no_pickups_win"):
			record._feat(profile, landmark)
	if record._last_call and slot.index not in record._leading:
		for landmark: LoyaltyLandmark in Loyalty.feats(&"last_call_comeback"):
			record._feat(profile, landmark)
	var room := in_match.arena.room if in_match.arena != null else null
	if room != null and room.id in ROOMS:
		profile.loyalty.win_in(room.id)
	var everywhere := true
	for id: StringName in ROOMS:
		everywhere = everywhere and String(id) in profile.loyalty.rooms
	if everywhere:
		for landmark: LoyaltyLandmark in Loyalty.feats(&"every_room"):
			record._feat(profile, landmark)
