class_name BotSlots
extends RefCounted
## A bot at the slot machines, GAME.md 3.15 and 9.1: now and then, with chips enough in its pot, it
## makes up its mind to go and pull one, the nearest that will take its bet, more often for a
## greedy bot and seldom for a cautious one, see [member BotTrait.slot_appetite]. Asked at every
## decision; once it has pulled it leaves the machines be for a while.

## How often a bot thinks about a pull, in seconds, and the chance each time for an appetite of one;
## how long it keeps going for a machine once it has made up its mind; and what a pull is worth to
## it against a pickup or a pad, see [BotGoals].
const EVERY := 20.0
const CHANCE := 0.3
const KEEN_FOR := 12.0
const VALUE := 12.0

var _until_thought := EVERY * 0.5
var _keen_left := 0.0


## The machine [param kart] goes to pull now, or null, [param delta] seconds on from the last time
## it was asked: none while its pot is too small, it is not keen, or no machine will take its bet.
func wanted(kart: Kart, appetite: float, rng: RandomNumberGenerator, delta: float) -> SlotPad:
	_until_thought -= delta
	_keen_left = maxf(_keen_left - delta, 0.0)
	var pads: Array[SlotPad] = []
	for node: Node in kart.get_tree().get_nodes_in_group(SlotPad.GROUP):
		if node is SlotPad:
			pads.append(node as SlotPad)
	for pad: SlotPad in pads:
		if pad.bettor() == kart.slot:
			# Pulled it: done with the machines for a while.
			_keen_left = 0.0
			_until_thought = EVERY
			return null
	if kart.is_decoy() or kart.pot.coins < SlotPad.LEAST_COINS:
		_keen_left = 0.0
		return null
	if _keen_left <= 0.0 and _until_thought <= 0.0:
		_until_thought = EVERY
		if rng != null and rng.randf() < CHANCE * appetite:
			_keen_left = KEEN_FOR
	if _keen_left <= 0.0:
		return null
	var best: SlotPad = null
	var best_distance := INF
	for pad: SlotPad in pads:
		if pad.is_spinning() or not pad.may_pull(kart):
			continue
		var distance := kart.global_position.distance_to(pad.global_position)
		if distance < best_distance:
			best_distance = distance
			best = pad
	return best
