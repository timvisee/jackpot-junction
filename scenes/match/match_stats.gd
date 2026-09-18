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
