class_name LoyaltyRecord
extends Node
## Keeps the feats the players at this machine do for their loyalty programs, GAME.md 8.9, see
## [Loyalty]: the ones done in a moment, a cash-out at a mult, a pot of seven chips, a full hand, a
## rare card burned, a pot driven off the Junction, as they happen; and the ones a whole map makes,
## a map without dying or without a shot, a share of shots landed, a map won with an empty hand or
## from behind at Last Call, every pick turned down, a map won in each room, as the map is written
## down, see [method map_played]. Whose they are is found as [MatchRecord] finds it: the first
## seat's go to the profile playing, a seat another profile sits in to that one, and a guest's, a
## bot's or a player's elsewhere to nobody. Every machine hears its own seats' cash-outs and hands
## anyway, a client from its host, and its own picks and menus where they are answered, so nothing
## of it goes over the wire. A feat off the books counts only with the story on. Kept in the
## profiles as it happens and written as the room is left, in [constant MatchRecord.GROUP]. Only
## the room the game is in keeps anything, and never headless.

## The rooms a map has to be won in, one each, for the Department's keystone, GAME.md 8.9.
const ROOMS: Array[StringName] = [&"workbench", &"after_hours", &"the_yard"]
## How many shots a map's share of them landed is counted over at the least, GAME.md 8.9.
const AIMED_SHOTS := 30
## How far past a Junction's edge a kart has to be to have driven off it, in meters: a kart on the
## rim is still on it.
const OFF_THE_PAD := 0.3

## For a test: feats are kept wherever the room is, headless or not.
static var anywhere := false

var match_node: Match

## Whether anything was kept since the profiles were last written, and whose.
var _kept: Array[Profile] = []
## By slot, the respawn picks turned down and taken from in this map, see [method _on_answered].
var _skipped: Dictionary[int, int] = {}
var _picked: Dictionary[int, int] = {}
## Whether Last Call has begun, and the slots that were leading as it did.
var _last_call := false
var _leading: Array[int] = []
## The slots in the middle of a cash-out, which have not yet been paid it or driven off.
var _banking: Dictionary[int, bool] = {}


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
		[Events.joker_destroyed, _on_destroyed],
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
	Game.settings.save_to_disk()


func _process(_delta: float) -> void:
	if not _keeps():
		return
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if kart == null or MatchRecord.profile_of(slot) == null:
			continue
		if kart.jokers != null and kart.jokers.count() > 0 and kart.jokers.is_full():
			_done(slot.index, &"full_hand")
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


func _on_bank_completed(slot: int, coins: int, mult: float, _total: int) -> void:
	_banking.erase(slot)
	var profile := _profile_at(slot)
	if profile == null:
		return
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
	if slot.kart != null and slot.kart.jokers != null and slot.kart.jokers.count() == 0:
		for landmark: LoyaltyLandmark in Loyalty.feats(&"empty_hand_win"):
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
