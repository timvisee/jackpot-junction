class_name MatchStats
extends RefCounted
## Counting what each player did, GAME.md 3.8, so the results screen has awards to hand out. Kept
## apart from [Match] so that file stays about running a match rather than about tallying one, the
## same way [MatchSnapshot] keeps the wire out of it.
##
## Everything here is host-only. A client is told what every player's figures are in the snapshot,
## and a client that also counted for itself would count the relayed events twice.


## The figures that accrue while driving rather than arriving as events.
static func step(match_node: Match, delta: float) -> void:
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if kart == null or not kart.is_active():
			continue
		var distance := kart.motor.speed() * delta
		slot.stats.add(&"driven", distance)
		if kart.motor.drifting:
			slot.stats.add(&"drifted", distance)
		if kart.nitro_active:
			slot.stats.add(&"nitro", delta)
		slot.stats.peak(&"max_mult", kart.pot.mult)


## One more of something for one player, if there is such a player and this machine is the one
## keeping score.
static func count(match_node: Match, slot: int, field: StringName, amount: float = 1.0) -> void:
	if match_node.puppet or slot < 0 or slot >= match_node.slots.size():
		return
	match_node.slots[slot].stats.add(field, amount)


## Hears the events a match counts, for [param match_node], see [Listener].
static func listen(match_node: Match) -> Listener:
	var listener := Listener.new()
	listener.match_node = match_node
	for heard: Array in listener.heard():
		var event: Signal = heard[0]
		if not event.is_connected(heard[1]):
			event.connect(heard[1])
	return listener


## What a match counts off [Events] and its arena rather than off its own karts, heard by one of
## these per match and let go of when the match goes: the events outlive every match they are
## raised in, and a match still connected after it had gone would be counting for nobody.
class Listener:
	extends RefCounted

	var match_node: Match

	func heard() -> Array[Array]:
		return [
			[Events.joker_taken, on_joker],
			[Events.life_restored, on_life],
			[Events.jackpot_collected, on_jackpot],
			[Events.drift_boosted, on_drift_boost],
			[Events.oil_hit, on_oil],
			[Events.kart_shot, on_hit],
		]

	func stop() -> void:
		for heard_one: Array in heard():
			var event: Signal = heard_one[0]
			if event.is_connected(heard_one[1]):
				event.disconnect(heard_one[1])

	## A shot on somebody else is a hit, for the shooter's accuracy.
	func on_hit(victim_slot: int, by_slot: int) -> void:
		if by_slot != victim_slot:
			MatchStats.count(match_node, by_slot, &"hits")

	func on_crate(by_slot: int) -> void:
		MatchStats.count(match_node, by_slot, &"crates")

	func on_joker(slot: int, _joker: StringName) -> void:
		MatchStats.count(match_node, slot, &"jokers")

	func on_life(slot: int) -> void:
		MatchStats.count(match_node, slot, &"lives_restored")

	func on_jackpot(slot: int, chips: int) -> void:
		MatchStats.count(match_node, slot, &"jackpot_chips", chips)

	func on_drift_boost(slot: int) -> void:
		MatchStats.count(match_node, slot, &"drift_boosts")

	func on_oil(slot: int) -> void:
		MatchStats.count(match_node, slot, &"oil_spins")
