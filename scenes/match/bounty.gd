class_name Bounty
extends RefCounted
## The price on the leader's head, GAME.md 3.10: now and then one goes up, and whoever takes them
## out collects it. It lapses on its own if nobody manages it.
##
## Kept out of [Match] the way [KartDeath] and [JokerTick] are. The state stays on the match,
## because a snapshot carries it and half the HUD reads it; only the rule for putting one up and
## taking it down lives here.

## Seconds before looking again when there was nobody worth putting a bounty on. Short, so a
## match that has just found a leader does not sit out a whole interval before noticing.
const RETRY := 5.0


## One tick of the rule: runs the clock on a bounty that is up, or looks for somebody to put one
## on when none is.
static func step(match_node: Match, delta: float) -> void:
	if match_node.bounty_slot >= 0:
		match_node.bounty_left -= delta
		var kart := match_node.kart_of(match_node.bounty_slot)
		if match_node.bounty_left <= 0.0 or kart == null or not kart.alive:
			clear(match_node, true)
		return
	match_node._bounty_wait -= delta
	if match_node._bounty_wait > 0.0:
		return
	# Nobody worth calling on yet: look again shortly rather than sitting out a whole interval.
	match_node._bounty_wait = RETRY
	var rules := match_node.rules
	var ranked := match_node.standings()
	if ranked.size() < 2:
		return
	var leader := ranked[0]
	# Only worth calling on a clear leader who is actually out there to be caught.
	if leader.banked - ranked[1].banked < rules.bounty_min_lead:
		return
	if leader.kart == null or not leader.kart.alive:
		return
	match_node._bounty_wait = match_node.rng.randf_range(
		rules.bounty_interval_min, rules.bounty_interval_max
	)
	match_node.bounty_slot = leader.index
	match_node.bounty_left = rules.bounty_duration
	leader.kart.set_bounty(true)
	Events.bounty_called.emit(match_node.bounty_slot)


## Takes the price off, whether it was collected or ran out.
static func clear(match_node: Match, lapsed: bool) -> void:
	var was := match_node.bounty_slot
	match_node.bounty_slot = -1
	match_node.bounty_left = 0.0
	var kart := match_node.kart_of(was) if was >= 0 else null
	if kart != null:
		kart.set_bounty(false)
	if lapsed and was >= 0:
		Events.bounty_lapsed.emit(was)
