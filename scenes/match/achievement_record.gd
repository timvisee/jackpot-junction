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
const TURRET_KILLS := 3
const PAYBACK_WITHIN := 10.0
const LONG_SHOT := 25.0
const HANDFUL := 9
const CURSED := 3
const WANTED_BANK := 1000
const JACKPOT_PILE := 120
const PIT_POT := 1000
const LUCK := 3
const NOSE := 50
## How many walls a Bank Shot bounced off, how many karts make a full table and a crowded win, how
## many others a Flawless or a By a Nose win is against, and how many maps a Clean Sweep's Grand
## Prix has at the least.
const BANKS := 2
const FULL_TABLE := 8
const OTHERS := 3
const FEWER_OTHERS := 2
const SWEEP_MAPS := 3
## How many physics ticks apart two kills are still one bomb's blast, a chain of bombs set off by it
## among them.
const ONE_BLAST := 6
## How far past a Junction's edge a kart has to be to have driven off it, as [LoyaltyRecord] has it.
const OFF_THE_PAD := 0.3
## The target a room with none is given, see [method MatchConfig.rules]: nothing to win.
const NO_TARGET := 1 << 30
## A Buzzer Beater's last seconds of the clock; how long after a Boost is used a ram's kill is
## still its, its three seconds and a little, and how many one Boost takes out for Road Hog; how
## many karts one slick spins out for Slick Operator; how many Royal Flushes in a map are a Full
## House; and how lately a kart still collects a Jackpot after its last chip, for Snatch and Grab.
const BUZZER := 5.0
const BOOST_WINDOW := 3.5
const ROAD_HOG := 2
const SLICK := 3
const FLUSHES := 3
const COLLECTING := 1.0
## How long one drift is held for Long Way Round, in seconds.
const LONG_DRIFT := 15.0
## How often each profile here is settled, in seconds.
const SETTLE_EVERY := 0.5

## For a test: moments are heard wherever the room is, headless or not.
static var anywhere := false

var match_node: Match
## Whether the moments of a map are heard here: not in the Garage, which only settles, GAME.md 8.10.
var moments := true
## Whether each profile here is settled every short while: not in the driving test, whose license
## is earned as it is stamped, see [method LicenseScreen._on_stamped].
var settles := true

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
## By seat: a cash-out in the last seconds that took the lead; when a Boost was last used and the
## karts taken out with it; the Royal Flushes made; when a chip of a Jackpot last came in; and a
## kart taken out while collecting one, the pile still to be emptied. By slick: the karts it spun.
var _buzzer: Dictionary[int, bool] = {}
## By seat, in team play, GAME.md 3.14: a cash-out on the Junction while a teammate was cashing out
## on one too, for Partners in Crime, and the cash-out that took the team to its target, for All In.
var _partnered: Dictionary[int, bool] = {}
var _closed_it: Dictionary[int, bool] = {}
var _boost_at: Dictionary[int, float] = {}
var _boost_kills: Dictionary[int, int] = {}
var _flushes: Dictionary[int, int] = {}
## By slot: whether the pull on its reels was bet at match point.
var _riding: Dictionary[int, bool] = {}
## By slot, every kart's, not only those of a profile here: whether it was cashing out at match
## point as last seen, for Payment Interrupted, its pot gone by the time its death is heard.
var _closing: Dictionary[int, bool] = {}
var _collected_at: Dictionary[int, float] = {}
var _snatched: Dictionary[int, bool] = {}
var _spun: Dictionary[int, Dictionary] = {}
## How many karts were still in it as sudden death began, 0 before it, and which.
var _overtime_field := 0
var _overtime_slots: Array[PlayerSlot] = []
## For somebody watching: whether the flag was seen dropping, and an emote sent since.
var _flagged := false
var _watch_emoted := false


static func add_to(in_match: Match, hears_moments := true, settling := true) -> AchievementRecord:
	var record := AchievementRecord.new()
	record.name = "AchievementRecord"
	record.match_node = in_match
	record.moments = hears_moments
	record.settles = settling
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
		[Events.oil_hit, _on_oil_hit],
		[Events.flush_completed, _on_flush_completed],
		[Events.slot_spun, _on_slot_spun],
		[Events.slot_paid, _on_slot_paid],
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
	var settle := settles and _settled >= SETTLE_EVERY
	if settle:
		_settled = 0.0
	if moments:
		_watch_the_cash_outs()
	for slot: PlayerSlot in match_node.slots:
		var profile := MatchRecord.profile_of(slot)
		if profile == null:
			continue
		if settle:
			Achievements.arrive(profile, slot.index)
		if moments and slot.kart != null and is_instance_valid(slot.kart):
			_watch(slot, profile)


## What no event says, read off [param slot]'s kart: the hand it holds, the drift it is in, the
## crates broken so far, the pot it carries and whether that pot has just come to win the map in
## the middle of a cash-out.
func _watch(slot: PlayerSlot, profile: Profile) -> void:
	var kart := slot.kart
	if kart.jokers != null:
		if kart.jokers.count() >= HANDFUL:
			_earn(profile, &"a_real_handful", slot.index)
		if _full_stacks(kart) >= 2:
			_earn(profile, &"stacked", slot.index)
	if not profile.achievements.has(&"property_damage"):
		var since := MatchRecord.since_of(match_node, slot)
		if LifetimeStats.live_value(profile, slot, &"crates", since) >= Achievements.CRATES:
			_earn(profile, &"property_damage", slot.index)
	# Every hand made and Suited in every suit, the moment the last of them comes, GAME.md 8.10.
	if not profile.achievements.has(&"suit_yourself"):
		var fields := Achievements.HAND_FIELDS + Achievements.SUIT_FIELDS
		if _all_done(profile, slot, fields):
			_earn(profile, &"suit_yourself", slot.index)
	if not kart.alive:
		_winning[slot.index] = false
		_cashing[slot.index] = false
		return
	# A crash starts a drift's count again, as it spoils its boost, GAME.md 4.1.
	if kart.motor.drifting and kart.motor.drift_time >= LONG_DRIFT:
		_earn(profile, &"long_way_round", slot.index)
	var worth := kart.pot.value()
	_worth[slot.index] = worth
	var target := _target()
	if target > 0 and worth >= LUCK * target:
		_earn(profile, &"push_your_luck", slot.index)
	var winning := match_node.would_win(slot)
	var cashing := _cashing_out(kart)
	if cashing and _mate_cashing(slot):
		_partnered[slot.index] = true
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


## The target score the map was set to be won at, or 0 for a room with none: the lobby, the
## Garage, the driving test, or a map played with no target. Not a goal a lesson sets for itself,
## which is no target score set.
func _target() -> int:
	var target := match_node.rules.target_score
	return target if target > 0 and target < NO_TARGET else 0


## Whether [param kart] is cashing out: on a Junction with a pot to bank.
func _cashing_out(kart: Kart) -> bool:
	return kart != null and kart.alive and not kart.pot.is_empty() and _on_a_junction(kart)


## Who is cashing out at match point, see [member _closing], on a map with a target to reach.
func _watch_the_cash_outs() -> void:
	var target := _target()
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		var closing := target > 0 and is_instance_valid(kart) and _cashing_out(kart)
		_closing[slot.index] = closing and match_node.would_win(slot)


## Whether seats [param a] and [param b] are on one team, GAME.md 3.14.
func _teammates(a: int, b: int) -> bool:
	var slots := match_node.slots
	return a < slots.size() and b < slots.size() and Teams.teammates(slots[a], slots[b])


## Whether a teammate of [param slot]'s is cashing out as well, GAME.md 3.14.
func _mate_cashing(slot: PlayerSlot) -> bool:
	for other: PlayerSlot in match_node.slots:
		if Teams.teammates(other, slot) and is_instance_valid(other.kart):
			if _cashing_out(other.kart):
				return true
	return false


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
	# Taken out while collecting a Jackpot: its pile is the killer's to empty for Snatch and Grab.
	if _clock - _collected_at.get(victim, -INF) <= COLLECTING:
		_snatched[killer] = true
	var payback: bool = _killed_by.get(killer, -1) == victim
	_killed_by[victim] = killer
	var closing: bool = _closing.get(victim, false)
	_closing[victim] = false
	var profile := _profile_at(killer)
	if profile == null:
		return
	# Taken out cashing out at match point, by anybody but a teammate: the match it was winning is
	# still on, GAME.md 8.10.
	if closing and not _teammates(killer, victim):
		_earn(profile, &"payment_interrupted", killer)
	_streak[killer] = _streak.get(killer, 0) + 1
	if _streak[killer] >= UNTOUCHABLE:
		_earn(profile, &"untouchable", killer)
	var by_decoy: bool = detail[0]
	var bounces: int = detail[1]
	if by_decoy:
		_earn(profile, &"dead_ringer", killer)
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
		&"ram":
			if _clock - _boost_at.get(killer, -INF) <= BOOST_WINDOW:
				_boost_kills[killer] = _boost_kills.get(killer, 0) + 1
				if _boost_kills[killer] >= ROAD_HOG:
					_earn(profile, &"road_hog", killer)
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
	if slot_a == slot_b or _mates(slot_a, slot_b):
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
	# In the clock's last seconds, from not ahead to ahead: a Buzzer Beater, if the map is won.
	var playing := match_node.state in [Match.State.PLAYING, Match.State.LAST_CALL]
	var slots := match_node.slots
	if slot >= slots.size():
		return
	# In team play, the team's bank against the other teams', GAME.md 3.14.
	var after := Teams.score_of(slots, slots[slot])
	if slots[slot].team >= 0 and after >= match_node.rules.team_target():
		_closed_it[slot] = true
	if playing and match_node.time_left <= BUZZER:
		var best := 0
		for other: PlayerSlot in slots:
			if other.index != slot and not _mates(other.index, slot):
				best = maxi(best, Teams.score_of(slots, other))
		if after - total <= best and after > best:
			_buzzer[slot] = true


func _on_bounty_called(slot: int) -> void:
	_wanted[slot] = true


func _on_bounty_claimed(_killer: int, victim: int, _amount: int) -> void:
	_wanted.erase(victim)


func _on_bounty_lapsed(slot: int) -> void:
	_wanted.erase(slot)


func _on_jackpot_collected(slot: int, chips: int) -> void:
	_collected_at[slot] = _clock
	if slot != _jar_slot:
		_jar_slot = slot
		_jar_chips = 0
	_jar_chips += chips


## The pile is gone: Hit the Jackpot for whoever took all of it with nobody else taking any, and
## Snatch and Grab for whoever emptied it after taking out a kart that was collecting it.
func _on_jackpot_emptied(_zone: int) -> void:
	if _jar_slot >= 0 and _jar_chips >= JACKPOT_PILE:
		_earn(_profile_at(_jar_slot), &"hit_the_jackpot", _jar_slot)
	if _jar_slot >= 0 and _snatched.get(_jar_slot, false):
		_earn(_profile_at(_jar_slot), &"snatch_and_grab", _jar_slot)
	_snatched.clear()
	_jar_slot = -1
	_jar_chips = 0


func _on_item_used(slot: int, item: StringName) -> void:
	if item == &"turret":
		_turret_kills[slot] = 0
	elif item == &"boost":
		_boost_at[slot] = _clock
		_boost_kills[slot] = 0


## A kart spun out on oil: a spin for whoever laid the slick it is on, unless it is their own kart,
## and Slick Operator for three karts on one slick.
func _on_oil_hit(victim: int) -> void:
	if victim < 0 or victim >= match_node.slots.size() or match_node.slots[victim].kart == null:
		return
	var kart := match_node.slots[victim].kart
	for node: Node in get_tree().get_nodes_in_group(&"oil_stains"):
		var slick := node as OilStain
		if slick == null or slick.owner_slot < 0 or slick.owner_slot == victim:
			continue
		var off := kart.global_position - slick.global_position
		if Vector2(off.x, off.z).length() > OilStain.RADIUS * 1.5:
			continue
		var spun: Dictionary = _spun.get(slick.get_instance_id(), {})
		spun[victim] = true
		_spun[slick.get_instance_id()] = spun
		if spun.size() >= SLICK:
			_earn(_profile_at(slick.owner_slot), &"slick_operator", slick.owner_slot)
		return


## Whether [param profile] and what [param slot] has done this map have each of [param fields] at
## least once.
func _all_done(profile: Profile, slot: PlayerSlot, fields: Array) -> bool:
	var since := MatchRecord.since_of(match_node, slot)
	for field: StringName in fields:
		if LifetimeStats.live_value(profile, slot, field, since) < 1.0:
			return false
	return true


## A pull on a slot machine bet at match point that comes up three of a kind, three sevens among
## them, is ridden, GAME.md 8.10, Let It Ride: a pair, half of all pulls, is too common for it.
func _on_slot_spun(slot: int, _pad: int, _bet: int, faces: PackedByteArray) -> void:
	if slot < 0 or slot >= match_node.slots.size():
		return
	var three := SlotPad.winning(faces) == Vector3.ONE
	_riding[slot] = three and match_node.would_win(match_node.slots[slot])


## And paid: a pull ridden that paid is Let It Ride.
func _on_slot_paid(slot: int, _pad: int, won: int) -> void:
	if won > 0 and _riding.get(slot, false):
		_earn(_profile_at(slot), &"let_it_ride", slot)
	_riding.erase(slot)


func _on_flush_completed(slot: int) -> void:
	_flushes[slot] = _flushes.get(slot, 0) + 1
	if _flushes[slot] >= FLUSHES:
		_earn(_profile_at(slot), &"full_house", slot)


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
		_riding,
		_partnered,
		_closed_it,
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
		_overtime_slots = _alive()
		_overtime_field = _overtime_slots.size()
	elif state == Match.State.RESULTS:
		_last_standing()
		_front_row()


## Sudden death played out to one kart, which three or more others were in as it began; in team
## play the very last kart, three or more of the other teams in it as it began, GAME.md 8.10.
func _last_standing() -> void:
	var left := _alive()
	if left.size() != 1:
		return
	var others := 0
	for slot: PlayerSlot in _overtime_slots:
		if slot != left[0] and not Teams.teammates(slot, left[0]):
			others += 1
	if others < OTHERS:
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
	var table := 0
	for each: PlayerSlot in match_node.slots:
		if each.kart == null or each.is_dummy():
			continue
		table += 1
		if each.is_local_human():
			here += 1
		elif each.bot_trait == null and _online():
			elsewhere += 1
		# Against counts the other teams alone in team play, GAME.md 8.10.
		if each == slot or Teams.teammates(each, slot):
			continue
		others += 1
		if each.bot_trait != null:
			bots += 1
	if here >= 2:
		_earn(profile, &"plus_one", at)
	if elsewhere >= 1:
		_earn(profile, &"long_distance", at)
	if _online() and table >= FULL_TABLE:
		_earn(profile, &"full_table", at)
	if not won or others < 1:
		return
	if _cursed(slot.kart) >= CURSED:
		_earn(profile, &"asking_for_trouble", at)
	if _buzzer.get(at, false):
		_earn(profile, &"buzzer_beater", at)
	var hard := match_node.bot_difficulty != null and match_node.bot_difficulty.id == &"hard"
	if hard and bots >= OTHERS:
		_earn(profile, &"beat_the_house", at)
	if others < FEWER_OTHERS:
		return
	if not _hurt.get(at, false):
		_earn(profile, &"flawless", at)
	if _partnered.get(at, false):
		_earn(profile, &"partners_in_crime", at)
	if _margin() <= NOSE:
		_earn(profile, &"by_a_nose", at)
	if others < OTHERS:
		return
	var alone: bool = slot.team < 0 or _closed_it.get(at, false)
	if _cash_outs.get(at, 0) == 1 and alone:
		_earn(profile, &"all_in", at)
	var run := Game.grand_prix
	if run != null and run.is_last() and run.playlist.size() >= SWEEP_MAPS:
		var wins := run.wins(at)
		if run.scored_round < run.round:
			wins += 1
		if wins >= run.playlist.size():
			_earn(profile, &"clean_sweep", at)


func _online() -> bool:
	return Net.online()


## What the map was won by over second place: in team play the winning team's bank over the next
## team's, GAME.md 8.10; nothing to win by with nobody second.
func _margin() -> int:
	var slots := match_node.slots
	if match_node.rules.teams > 0:
		var teams := Teams.standings(slots)
		return (
			Teams.bank(slots, teams[0]) - Teams.bank(slots, teams[1])
			if teams.size() >= 2
			else 1 << 30
		)
	var ranked := match_node.standings()
	return ranked[0].banked - ranked[1].banked if ranked.size() >= 2 else 1 << 30


## Whether [param a] and [param b] are teammates, GAME.md 3.14.
func _mates(a: int, b: int) -> bool:
	var slots := match_node.slots
	return (
		a >= 0
		and b >= 0
		and a < slots.size()
		and b < slots.size()
		and Teams.teammates(slots[a], slots[b])
	)


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
	# At the whistle the store hears whatever it is still to, GAME.md 10.8.
	Store.flush()


## [param slot] won the run [param in_match] was the showdown of, GAME.md 9.7a and 8.10, for
## [param profile]: Winner Takes All, the one thing a showdown counts toward.
static func showdown_won(in_match: Match, slot: PlayerSlot, profile: Profile) -> void:
	var record := in_match.get_node_or_null("AchievementRecord") as AchievementRecord
	if record != null:
		record._earn(profile, &"winner_takes_all", slot.index)


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
