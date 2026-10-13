class_name AchievementRecord
extends Node
## Hears the moments of a map that are achievements, GAME.md 8.10, see [Achievements], and earns
## them for the profile of the seat that had them as they happen: a bullet off two walls, a pit, a
## bounty survived at the Junction, a hand of nine. The wins a whole map makes are earned as the
## map is written down, see [method map_played]; and every short while each profile here is
## settled, so what its records show, a joker found or a note picked up, is earned there and then
## too. Whose they are is found as [MatchRecord] finds it: the first seat's for the profile playing,
## a seat another profile sits in for that one, a guest's, a bot's or a player's elsewhere for
## nobody. Every machine hears its own seats out of what it hears anyway, a client from its host;
## the one thing only a host sees, two bullets meeting, it says, see [signal Events.bullets_met]. A
## machine watching an online game earns Front Row for its profile playing. Only the room the game
## is in keeps anything, and never headless.

## The counts the moments are earned at, GAME.md 8.10: kills without dying, bullets shot down in a
## life, pits in a map, paybacks in a map, kills to one turret, seconds after coming back a payback
## is in, the distance of a long shot, the hand of A Real Handful, cursed cards held, a pot under a
## bounty, a Jackpot's pile, a pot down a pit, the target score times over, and a win's margin.
const UNTOUCHABLE := 8
const HITS := 10
const PARRIES := 5
const PITS := 3
const PAYBACKS := 3
const TURRET_KILLS := 2
const PAYBACK_WITHIN := 10.0
const LONG_SHOT := 25.0
const HANDFUL := 9
const CURSED := 3
const WANTED_BANK := 1000
const JACKPOT_PILE := 100
const PIT_POT := 1000
const LUCK := 3
const NOSE := 50
## How many walls a Bank Shot bounced off, how many karts make a full table and a crowded win, and
## how many maps a Clean Sweep's Grand Prix has at the least.
const BANKS := 2
const FULL_TABLE := 8
const OTHERS := 3
const SWEEP_MAPS := 3
## How many physics ticks apart two kills are still one bomb's blast, a chain of bombs set off by it
## among them.
const ONE_BLAST := 6
## How far past a Junction's edge a kart has to be to have driven off it, as [LoyaltyRecord] has it.
const OFF_THE_PAD := 0.3
## The target a room with none is given, see [method MatchConfig.rules]: nothing to win.
const NO_TARGET := 1 << 30
## How often each profile here is settled, in seconds.
const SETTLE_EVERY := 0.5

## For a test: moments are heard wherever the room is, headless or not.
static var anywhere := false

var match_node: Match
## Whether the moments of a map are heard here: not in the Garage, which only settles, GAME.md 8.10.
var moments := true

## The room's own clock, which stops while the room is paused, for how long after coming back a
## payback is.
var _clock := 0.0
var _settled := 0.0
## By slot: kills since the last death, bullets shot down in this life, and whether a life was lost
## in this map, for Untouchable, Parry and Flawless.
var _streak: Dictionary[int, int] = {}
var _parried: Dictionary[int, int] = {}
var _hurt: Dictionary[int, bool] = {}
## By slot: hits taken in this life and lived through, a life lost or a shield popped, for Tough as
## Nails.
var _hits: Dictionary[int, int] = {}
## By slot: who took it out last, and when it came back, for Payback, and the paybacks in this map.
var _killed_by: Dictionary[int, int] = {}
var _back_at: Dictionary[int, float] = {}
var _paybacks: Dictionary[int, int] = {}
## By slot: karts knocked into pits in this map, the physics tick of the last bomb kill, the kills
## of the turret put down last, and the cash-outs begun in this map.
var _pits: Dictionary[int, int] = {}
var _bombed_at: Dictionary[int, int] = {}
var _turret_kills: Dictionary[int, int] = {}
var _cash_outs: Dictionary[int, int] = {}
## By slot: whether a bounty is on its head, the pot's worth as last seen, and whether the pot would
## win the map and the kart was cashing out as last seen, for Point of Sale.
var _wanted: Dictionary[int, bool] = {}
var _worth: Dictionary[int, int] = {}
var _winning: Dictionary[int, bool] = {}
var _cashing: Dictionary[int, bool] = {}
## The last kill's bullet as the host told it, by its victim: whether a decoy fired it and how many
## walls it bounced off.
var _detail: Dictionary[int, Array] = {}
## Who has been collecting the Jackpot's pile, and how much of it, since anybody else last did.
var _jar_slot := -1
var _jar_chips := 0
## How many karts were still in it as sudden death began, 0 before it.
var _overtime_field := 0
## For somebody watching: whether the flag was seen dropping, and an emote sent since.
var _flagged := false
var _watch_emoted := false


static func add_to(in_match: Match, hears_moments := true) -> AchievementRecord:
	var record := AchievementRecord.new()
	record.name = "AchievementRecord"
	record.match_node = in_match
	record.moments = hears_moments
	in_match.add_child(record)
	return record


func _ready() -> void:
	# The dress worn is a record, earned the moment a stall changes it, here or in the Garage.
	Events.kart_dressed.connect(_on_kart_dressed)
	if not moments:
		return
	for pair: Array in _listens():
		(pair[0] as Signal).connect(pair[1])


func _exit_tree() -> void:
	if Events.kart_dressed.is_connected(_on_kart_dressed):
		Events.kart_dressed.disconnect(_on_kart_dressed)
	for pair: Array in _listens():
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])


func _listens() -> Array[Array]:
	return [
		[Events.kart_killed, _on_kart_killed],
		[Events.kill_detailed, _on_kill_detailed],
		[Events.kart_wounded, _on_kart_wounded],
		[Events.shield_popped, _on_shield_popped],
		[Events.kart_respawned, _on_kart_respawned],
		[Events.kart_fell, _on_kart_fell],
		[Events.bullets_met, _on_bullets_met],
		[Events.bank_started, _on_bank_started],
		[Events.bank_completed, _on_bank_completed],
		[Events.bounty_called, _on_bounty_called],
		[Events.bounty_claimed, _on_bounty_claimed],
		[Events.bounty_lapsed, _on_bounty_lapsed],
		[Events.jackpot_collected, _on_jackpot_collected],
		[Events.jackpot_emptied, _on_jackpot_emptied],
		[Events.item_used, _on_item_used],
		[Events.player_joined, _on_player_joined],
		[Events.countdown_done, _on_countdown_done],
		[Events.match_state_changed, _on_state],
		[Events.watched_emote, _on_watched_emote],
	]


func _process(delta: float) -> void:
	if not _keeps():
		return
	_clock += delta
	_settled += delta
	var settle := _settled >= SETTLE_EVERY
	if settle:
		_settled = 0.0
	for slot: PlayerSlot in match_node.slots:
		var profile := MatchRecord.profile_of(slot)
		if profile == null:
			continue
		if settle:
			Achievements.arrive(profile, slot.index)
		if moments and slot.kart != null and is_instance_valid(slot.kart):
			_watch(slot, profile)


## What no event says, read off [param slot]'s kart: the hand it holds, the pot it carries and
## whether that pot has just come to win the map in the middle of a cash-out.
func _watch(slot: PlayerSlot, profile: Profile) -> void:
	var kart := slot.kart
	if kart.jokers != null:
		if kart.jokers.count() >= HANDFUL:
			_earn(profile, &"a_real_handful", slot.index)
		if _full_stacks(kart) >= 2:
			_earn(profile, &"stacked", slot.index)
	if not kart.alive:
		_winning[slot.index] = false
		_cashing[slot.index] = false
		return
	var worth := kart.pot.value()
	_worth[slot.index] = worth
	var target := _target()
	if target > 0 and worth >= LUCK * target:
		_earn(profile, &"push_your_luck", slot.index)
	var winning := match_node.would_win(slot)
	var cashing := not kart.pot.is_empty() and _on_a_junction(kart)
	if winning and not _winning.get(slot.index, true) and cashing:
		if _cashing.get(slot.index, false):
			_earn(profile, &"point_of_sale", slot.index)
	_winning[slot.index] = winning
	_cashing[slot.index] = cashing


## How many jokers [param kart] holds at the most their stacks go to, GAME.md 7.3.
static func _full_stacks(kart: Kart) -> int:
	var counted: Array[StringName] = []
	var full := 0
	var ids := kart.jokers.ids()
	for joker: Joker in kart.jokers.jokers:
		if joker.id in counted or not joker.stackable or joker.most <= 0:
			continue
		counted.append(joker.id)
		if ids.count(joker.id) >= joker.most:
			full += 1
	return full


## The cursed jokers [param kart] holds, GAME.md 7.3.
static func _cursed(kart: Kart) -> int:
	var count := 0
	if kart == null or kart.jokers == null:
		return count
	for joker: Joker in kart.jokers.jokers:
		if joker.kind == Joker.Kind.CURSED:
			count += 1
	return count


## The target score that wins the map, or 0 for a room with none.
func _target() -> int:
	var target := match_node.win_at if match_node.win_at > 0 else match_node.rules.target_score
	return target if target > 0 and target < NO_TARGET else 0


func _on_a_junction(kart: Kart) -> bool:
	if match_node.arena == null:
		return false
	var at := Vector2(kart.global_position.x, kart.global_position.z)
	for pad: JunctionPad in match_node.arena.junctions:
		var middle := Vector2(pad.global_position.x, pad.global_position.z)
		if at.distance_to(middle) <= pad.radius + OFF_THE_PAD:
			return true
	return false


func _on_kill_detailed(victim: int, by_decoy: bool, bounces: int) -> void:
	_detail[victim] = [by_decoy, bounces]


func _on_kart_killed(victim: int, killer: int, cause: StringName) -> void:
	_lost_life(victim)
	_streak[victim] = 0
	_parried[victim] = 0
	_hits[victim] = 0
	_wanted.erase(victim)
	var detail: Array = _detail.get(victim, [false, 0])
	_detail.erase(victim)
	if killer < 0 or killer == victim:
		return
	var payback: bool = _killed_by.get(killer, -1) == victim
	_killed_by[victim] = killer
	var profile := _profile_at(killer)
	if profile == null:
		return
	_streak[killer] = _streak.get(killer, 0) + 1
	if _streak[killer] >= UNTOUCHABLE:
		_earn(profile, &"untouchable", killer)
	var by_decoy: bool = detail[0]
	var bounces: int = detail[1]
	match cause:
		&"pit":
			_pits[killer] = _pits.get(killer, 0) + 1
			if _pits[killer] >= PITS:
				_earn(profile, &"push_comes_to_shove", killer)
		&"bomb":
			var tick := Engine.get_physics_frames()
			if tick - _bombed_at.get(killer, -ONE_BLAST - 1) <= ONE_BLAST:
				_earn(profile, &"two_birds", killer)
			_bombed_at[killer] = tick
		&"turret":
			_turret_kills[killer] = _turret_kills.get(killer, 0) + 1
			if _turret_kills[killer] >= TURRET_KILLS:
				_earn(profile, &"set_and_forget", killer)
		&"bullet":
			if not by_decoy and _apart(killer, victim) >= LONG_SHOT:
				_earn(profile, &"long_shot", killer)
	if cause in [&"bullet", &"turret"] and not by_decoy and bounces >= BANKS:
		_earn(profile, &"bank_shot", killer)
	if payback and _clock - _back_at.get(killer, -INF) <= PAYBACK_WITHIN:
		_killed_by.erase(killer)
		_paybacks[killer] = _paybacks.get(killer, 0) + 1
		if _paybacks[killer] >= PAYBACKS:
			_earn(profile, &"payback", killer)


## How far apart the karts of [param a] and [param b] are, in meters across the floor.
func _apart(a: int, b: int) -> float:
	var one := match_node.slots[a].kart if a < match_node.slots.size() else null
	var two := match_node.slots[b].kart if b < match_node.slots.size() else null
	if one == null or two == null or not is_instance_valid(one) or not is_instance_valid(two):
		return 0.0
	var from := Vector2(one.global_position.x, one.global_position.z)
	return from.distance_to(Vector2(two.global_position.x, two.global_position.z))


func _on_kart_wounded(victim: int, _by: int, _cause: StringName) -> void:
	_lost_life(victim)
	_took_hit(victim)


func _on_shield_popped(slot: int) -> void:
	_took_hit(slot)


## [param slot] took a hit and lived: ten in a life is Tough as Nails.
func _took_hit(slot: int) -> void:
	_hits[slot] = _hits.get(slot, 0) + 1
	if _hits[slot] >= HITS:
		_earn(_profile_at(slot), &"tough_as_nails", slot)


## [param index]'s kart has been dressed on a stall: the dress it wears is settled once the stall
## has kept it, see [method StyleStalls.keep], for Dressed to the Nines there and then.
func _on_kart_dressed(index: int, _part: int, _style: PackedInt32Array) -> void:
	_settle_seat.call_deferred(index)


func _settle_seat(index: int) -> void:
	var profile := _profile_at(index)
	if profile != null:
		Achievements.arrive(profile, index)


func _lost_life(slot: int) -> void:
	_hurt[slot] = true


func _on_kart_respawned(slot: int, _at: Vector3) -> void:
	_back_at[slot] = _clock


## [param slot] went over the edge of a pit, with the pot it had a moment before.
func _on_kart_fell(slot: int) -> void:
	if _worth.get(slot, 0) >= PIT_POT:
		_earn(_profile_at(slot), &"a_pit_do_not", slot)


func _on_bullets_met(slot_a: int, slot_b: int) -> void:
	if slot_a == slot_b:
		return
	for slot: int in [slot_a, slot_b]:
		_parried[slot] = _parried.get(slot, 0) + 1
		if _parried[slot] >= PARRIES:
			_earn(_profile_at(slot), &"parry", slot)


func _on_bank_started(slot: int) -> void:
	_cash_outs[slot] = _cash_outs.get(slot, 0) + 1


func _on_bank_completed(slot: int, _coins: int, _mult: float, total: int) -> void:
	if _wanted.get(slot, false) and total >= WANTED_BANK:
		_earn(_profile_at(slot), &"most_wanted", slot)


func _on_bounty_called(slot: int) -> void:
	_wanted[slot] = true


func _on_bounty_claimed(_killer: int, victim: int, _amount: int) -> void:
	_wanted.erase(victim)


func _on_bounty_lapsed(slot: int) -> void:
	_wanted.erase(slot)


func _on_jackpot_collected(slot: int, chips: int) -> void:
	if slot != _jar_slot:
		_jar_slot = slot
		_jar_chips = 0
	_jar_chips += chips


## The pile is gone: Hit the Jackpot for whoever took all of it with nobody else taking any.
func _on_jackpot_emptied(_zone: int) -> void:
	if _jar_slot >= 0 and _jar_chips >= JACKPOT_PILE:
		_earn(_profile_at(_jar_slot), &"hit_the_jackpot", _jar_slot)
	_jar_slot = -1
	_jar_chips = 0


func _on_item_used(slot: int, item: StringName) -> void:
	if item == &"turret":
		_turret_kills[slot] = 0


## Somebody sat down at [param slot]: what was done there before was somebody else's.
func _on_player_joined(slot: int) -> void:
	for kept: Dictionary in [
		_streak,
		_parried,
		_hurt,
		_hits,
		_killed_by,
		_back_at,
		_paybacks,
		_pits,
		_bombed_at,
		_turret_kills,
		_cash_outs,
		_wanted,
		_worth,
		_winning,
		_cashing,
	]:
		kept.erase(slot)


func _on_countdown_done() -> void:
	_flagged = true


func _on_watched_emote(_emote: int) -> void:
	_watch_emoted = true


func _on_state(state: int) -> void:
	if not is_instance_valid(match_node):
		return
	if state == Match.State.OVERTIME and _overtime_field == 0:
		_overtime_field = _alive().size()
	elif state == Match.State.RESULTS:
		_last_standing()
		_front_row()


## Sudden death played out to one kart, which three or more others were in as it began.
func _last_standing() -> void:
	var left := _alive()
	if _overtime_field < OTHERS + 1 or left.size() != 1:
		return
	_earn(_profile_at(left[0].index), &"last_kart_standing", left[0].index)


## Somebody watching an online map from its flag to its whistle, who sent an emote while they did.
func _front_row() -> void:
	var session := Net.session
	if session == null or not session.watching or not _flagged or not _watch_emoted:
		return
	if _keeps():
		Achievements.earn(Game.settings.profile, &"front_row")


func _alive() -> Array[PlayerSlot]:
	var alive: Array[PlayerSlot] = []
	for slot: PlayerSlot in match_node.slots:
		if slot.kart != null and is_instance_valid(slot.kart) and slot.kart.alive:
			alive.append(slot)
	return alive


## [param slot] of [param in_match] played a map to its whistle for [param profile], GAME.md 8.10,
## and [param won] it or not: the achievements of a whole map, the wins and the company kept.
static func map_played(in_match: Match, slot: PlayerSlot, profile: Profile, won: bool) -> void:
	var record := in_match.get_node_or_null("AchievementRecord") as AchievementRecord
	if record == null or not record.moments:
		return
	record._map_played(slot, profile, won)


func _map_played(slot: PlayerSlot, profile: Profile, won: bool) -> void:
	var at := slot.index
	var others := 0
	var bots := 0
	var here := 0
	var elsewhere := 0
	for each: PlayerSlot in match_node.slots:
		if each.kart == null or each.is_dummy():
			continue
		if each.is_local_human():
			here += 1
		elif each.bot_trait == null and _online():
			elsewhere += 1
		if each.bot_trait != null:
			bots += 1
		if each != slot:
			others += 1
	if here >= 2:
		_earn(profile, &"plus_one", at)
	if elsewhere >= 1:
		_earn(profile, &"long_distance", at)
	if _online() and others + 1 >= FULL_TABLE:
		_earn(profile, &"full_table", at)
	if not won or others < 1:
		return
	if _cursed(slot.kart) >= CURSED:
		_earn(profile, &"asking_for_trouble", at)
	var hard := match_node.bot_difficulty != null and match_node.bot_difficulty.id == &"hard"
	if hard and bots >= OTHERS:
		_earn(profile, &"beat_the_house", at)
	if others < OTHERS:
		return
	if not _hurt.get(at, false):
		_earn(profile, &"flawless", at)
	if _cash_outs.get(at, 0) == 1:
		_earn(profile, &"all_in", at)
	var ranked := match_node.standings()
	if ranked.size() >= 2 and ranked[0].banked - ranked[1].banked <= NOSE:
		_earn(profile, &"by_a_nose", at)
	var run := Game.grand_prix
	if run != null and run.is_last() and run.playlist.size() >= SWEEP_MAPS:
		var wins := run.wins(at)
		if run.scored_round < run.round:
			wins += 1
		if wins >= run.playlist.size():
			_earn(profile, &"clean_sweep", at)


func _online() -> bool:
	return Net.online()


## Every profile in [param written] settled after [param in_match] was written down, GAME.md 8.10:
## what a map adds to the records, a shift, a district won, earned beside the seat it sat at.
static func settled(in_match: Match, written: Array[Profile]) -> void:
	for profile: Profile in written:
		var at := -1
		for slot: PlayerSlot in in_match.slots:
			if MatchRecord.profile_of(slot) == profile:
				at = slot.index
				break
		Achievements.settle(profile, at)


func _earn(profile: Profile, id: StringName, slot: int) -> void:
	if profile != null and _keeps():
		Achievements.earn(profile, id, slot)


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
