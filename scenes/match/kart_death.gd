class_name KartDeath
extends RefCounted
## What happens when a kart dies, GAME.md 3.6: a share of the pot is banked, coins and maybe a
## joker or the item hit the floor, whoever did it is paid in mult, nitro and a life back, and a
## respawn is set running with a joker pick to make while it waits. Jokers bend every part of
## it, which is what [DeathOutcome] is for.
##
## Kept out of [Match] the way [MatchStats] and [MatchSnapshot] are, so that file stays about
## running a match rather than about the longest single thing that happens during one.


## One death, start to finish. [param slot] is who died, [param killer_slot] who gets the credit,
## -1 for a pit or a wall.
static func resolve(
	match_node: Match, cause: StringName, killer_slot: int, slot: PlayerSlot
) -> void:
	var kart := slot.kart
	# After the whistle the scores are final, GAME.md 3.13: a bomb already in the air or a fall
	# already begun still ends in a wreck, but banks nothing, pays nobody and counts for nothing.
	if match_node.state == Match.State.RESULTS:
		kart.pot.reset()
		return
	slot.stats.add(&"deaths")
	slot.stats.add(&"coins_lost", kart.pot.coins)
	if cause == &"pit":
		slot.stats.add(&"pit_deaths")
	if killer_slot == slot.index:
		slot.stats.add(&"self_kills")
	var death := DeathOutcome.from_rules(match_node.rules)
	for joker: Joker in kart.jokers.jokers:
		joker.modify_death(kart, death)
		joker.on_death(kart)
	var killer: PlayerSlot = null
	if killer_slot >= 0 and killer_slot != slot.index and killer_slot < match_node.slots.size():
		killer = match_node.slots[killer_slot]
		for joker: Joker in killer.kart.jokers.jokers:
			joker.on_victim_death(killer.kart, kart, death)
	# Read before the death moves any money, so that afterwards the two can be compared.
	var behind := _behind(match_node, slot, killer)
	var banked := Scoring.death_bank(kart.pot.coins, kart.pot.mult, death.bank_fraction)
	var worth := Scoring.pot_value(kart.pot.coins, kart.pot.mult)
	slot.banked += banked
	if worth > 0:
		Events.death_banked.emit(slot.index, banked, worth - banked)
	_scatter(match_node, slot, killer, death)
	_collect_bounty(match_node, slot, killer)
	_pay_killer(match_node, cause, killer)
	kart.pot.reset()
	slot.deaths += 1
	slot.respawn_left = match_node.rules.respawn_delay
	# Nobody comes back out of sudden death, so there is nothing to pick a joker for; nor out of
	# the results, which a death after the whistle never gets this far into. Some rooms turn the
	# pick off outright, see offer_jokers.
	var over := match_node.state == Match.State.OVERTIME
	var picking := match_node.rules.offer_jokers and not over
	slot.offer = _offer(match_node, slot) if picking else null
	Events.kart_killed.emit(slot.index, killer_slot, cause)
	if behind:
		_announce_overtake(match_node, slot, killer)
	if match_node.camera_rig != null:
		# A kill in a hot match hits harder than the first one of the round.
		match_node.camera_rig.shake(0.2 + 0.5 * match_node.intensity.share())
	match_node.check_target()


## What the kart leaves on the floor where it died, and what the killer takes off it first.
static func _scatter(
	match_node: Match, slot: PlayerSlot, killer: PlayerSlot, death: DeathOutcome
) -> void:
	var kart := slot.kart
	var rules := match_node.rules
	var rng := match_node.rng
	var position := kart.global_position
	var stolen := 0
	if killer != null and death.steal_fraction > 0.0 and killer.kart.alive:
		stolen = floori(kart.pot.coins * death.steal_fraction)
		killer.kart.collect_coins(stolen, null)
	var drop := Scoring.death_drop(kart.pot.coins - stolen, death.drop_fraction, death.drop_max)
	if drop > 0:
		match_node.arena.spawn_chips(position, drop, rules.dropped_chip_lifetime, 0.0, true)
	for i: int in death.joker_drop_count:
		if kart.jokers.count() > 0 and rng.randf() < death.joker_drop_chance:
			var dropped := kart.jokers.remove_at(rng.randi_range(0, kart.jokers.count() - 1))
			match_node.arena.spawn_floor_joker(position, dropped, rules.floor_item_lifetime)
	if kart.held_item != null:
		if rng.randf() < death.item_drop_chance:
			match_node.arena.spawn_floor_item(position, kart.held_item, rules.floor_item_lifetime)
		kart.held_item = null


## The price on a head, GAME.md 3.10: paid to whoever took it, and off the board either way.
static func _collect_bounty(match_node: Match, slot: PlayerSlot, killer: PlayerSlot) -> void:
	if slot.index != match_node.bounty_slot:
		return
	if killer != null:
		killer.banked += match_node.rules.bounty_reward
		killer.stats.add(&"bounties")
		Events.bounty_claimed.emit(killer.index, slot.index, match_node.rules.bounty_reward)
	match_node.clear_bounty(killer == null)


## What a kill is worth to whoever made it: the kill itself, mult, half a tank and a life back.
static func _pay_killer(match_node: Match, cause: StringName, killer: PlayerSlot) -> void:
	if killer == null:
		return
	killer.kills += 1
	if cause == &"bomb":
		killer.stats.add(&"bomb_kills")
	if not killer.kart.alive:
		return
	killer.kart.gain_mult(match_node.rules.kill_mult, &"kill")
	killer.kart.refill_nitro(killer.kart.stats.nitro_kill_refill)
	# A kill patches the killer up, so a wounded kart can fight its way back rather than having
	# to break off for the Junction.
	killer.kart.restore_life()


## The joker pick waiting while the kart is dead, GAME.md 3.7. A bot takes one at random on the
## spot, since there is nobody to read the cards to.
static func _offer(match_node: Match, slot: PlayerSlot) -> JokerOffer:
	var kart := slot.kart
	var choices := match_node.joker_catalog.offer(
		match_node.rng, kart.offer_count(match_node.offer_size), kart.jokers.ids()
	)
	var offer := JokerOffer.new(kart, choices)
	if not offer.is_done():
		Events.joker_offered.emit(slot.index)
	if not slot.is_human() and not offer.is_done():
		offer.take(match_node.rng.randi_range(0, choices.size() - 1))
		if offer.stage == JokerOffer.Stage.REPLACING:
			offer.replace(match_node.rng.randi_range(0, kart.jokers.count() - 1))
	return offer


## Whether this kill could hand the killer a place, GAME.md 3.13: sudden death, somebody to
## credit, and that somebody currently behind the player they just took out. Only in overtime,
## because that is where a place changing hands is the match changing hands.
static func _behind(match_node: Match, slot: PlayerSlot, killer: PlayerSlot) -> bool:
	return (
		match_node.state == Match.State.OVERTIME
		and killer != null
		and PlayerSlot.by_score(slot, killer)
	)


## Says so, once the places really have changed. Going to the top of the board is a different
## thing to passing somebody in the middle of it, so it is said differently.
static func _announce_overtake(match_node: Match, slot: PlayerSlot, killer: PlayerSlot) -> void:
	if not PlayerSlot.by_score(killer, slot):
		return
	killer.stats.add(&"overtakes")
	var leading: bool = match_node.standings()[0] == killer
	Events.announced.emit(killer.index, "TAKING THE LEAD" if leading else "OVERTAKE")
