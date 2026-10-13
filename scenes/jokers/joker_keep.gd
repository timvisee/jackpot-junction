class_name JokerKeep
extends RefCounted
## The pick of which joker to keep, GAME.md 9.7, made as the next map of a Grand Prix starts.
##
## Under "pick one to keep" everybody used to choose on the podium of the map before, on a row of
## buttons that a player with a pad in their hands could not reach. Now the choosing is done where
## a card is always chosen: on the joker pick, with the jokers the player held at the whistle, on
## the grid of the next map. The lamps wait for it -- the karts are frozen and nobody is steering,
## so the stick can move the cursor -- for as long as [constant DEADLINE], after which anybody
## still choosing keeps one of their jokers at random.

## The longest the lamps wait for somebody to choose, in seconds.
const DEADLINE := 15.0


## Opens the pick for [param slot]: one of [param jokers] to keep for this map, or none, skipped,
## for a player who would rather start the map with an empty hand.
static func open(slot: PlayerSlot, jokers: Array[Joker]) -> void:
	var offer := JokerOffer.new(slot.kart, jokers)
	offer.keeping = true
	offer.keep_left = DEADLINE
	slot.offer = offer
	Events.joker_offered.emit(slot.index)


## Whether anybody at the table is still choosing.
static func pending(match_node: Match) -> bool:
	for slot: PlayerSlot in match_node.slots:
		if choosing(slot):
			return true
	return false


## Whether anybody at this machine is still choosing, and has the pick on their screen.
static func choosing_here(match_node: Match) -> bool:
	for slot: PlayerSlot in match_node.slots:
		var here := slot.is_local_human() or match_node.is_local_seat(slot.index)
		if here and choosing(slot):
			return true
	return false


static func choosing(slot: PlayerSlot) -> bool:
	return slot.offer != null and slot.offer.keeping and not slot.offer.is_done()


## Answers every open pick off its player's controls, and past [constant DEADLINE] for them.
## True once nobody is choosing. The karts are frozen on the grid, and a frozen kart polls its own
## controls, so they are read here rather than polled a second time.
static func step(match_node: Match, delta: float) -> bool:
	var done := true
	for slot: PlayerSlot in match_node.slots:
		var offer := slot.offer
		if offer == null or not offer.keeping:
			continue
		if not offer.is_done():
			# A client's player answers at the client, and the host is told by name, see
			# [JokerWire].
			if slot.is_human() and not slot.input is NetInput:
				offer.poll_input(slot.input)
			offer.keep_left -= delta
			if not offer.is_done() and offer.keep_left <= 0.0:
				offer.take(match_node.rng.randi_range(0, offer.choices.size() - 1))
		if offer.is_done():
			slot.offer = null
		else:
			done = false
	return done
