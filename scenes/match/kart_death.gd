class_name KartDeath
extends RefCounted
## What happens when a kart dies, GAME.md 3.6: coins and maybe a joker or the item hit the floor,
## a share of what is left of the pot is banked, whoever did it is paid in mult, nitro and a life
## back, and a respawn is set running with a joker pick to make while it waits. Jokers bend every
## part of it, which is what [DeathOutcome] is for.
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
	Showdown.went_out(match_node, slot)
	slot.stats.add(&"coins_lost", kart.pot.coins)
	if cause == &"pit":
		slot.stats.add(&"pit_deaths")
	if killer_slot == slot.index:
		slot.stats.add(&"self_kills")
	killer_slot = _credited(match_node, killer_slot, slot, cause)
	var death := DeathOutcome.from_rules(match_node.rules)
	for joker: Joker in kart.jokers.jokers:
		joker.modify_death(kart, death)
		joker.on_death(kart)
	KartLives.lose_on_death(kart)
	var killer: PlayerSlot = null
	if killer_slot >= 0 and killer_slot != slot.index and killer_slot < match_node.slots.size():
		killer = match_node.slots[killer_slot]
		for joker: Joker in killer.kart.jokers.jokers:
			joker.on_victim_death(killer.kart, kart, death)
	# Read before the death moves any money, so that afterwards the two can be compared.
	var behind := _behind(match_node, slot, killer)
	# What leaves the pot goes first, into the killer's pot and onto the floor, and the bank is a
	# share of what is left of it: all of it with Insurance Policy, and all of the pot with Tight
	# Grip as well, which lets none of it go.
	var left := kart.pot.coins - _spill(match_node, slot, killer, death)
	var banked := Scoring.death_bank(left, kart.pot.mult, death.bank_fraction)
	var worth := Scoring.pot_value(left, kart.pot.mult)
	slot.banked += banked
	if worth > 0:
		Events.death_banked.emit(slot.index, banked, worth - banked)
	_scatter(match_node, slot, death)
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
	_detail(slot, cause)
	Events.kart_killed.emit(slot.index, killer_slot, cause)
	if behind:
		_announce_overtake(match_node, slot, killer)
	if match_node.camera_rig != null:
		# A kill in a hot match hits harder than the first one of the round.
		match_node.camera_rig.shake(0.2 + 0.5 * match_node.intensity.share())
	match_node.check_target()


## What the kill feed is told beyond the cause, GAME.md 8.3, when there is anything: that the
## killer's decoy did it, and how many walls the bullet came off. Only for the hit that killed,
## which a bullet or a ram says of itself as it lands, see [member Kart.kill_how]; a fall or a
## bomb has nothing more to say.
static func _detail(slot: PlayerSlot, cause: StringName) -> void:
	var how := slot.kart.kill_how if cause in [&"bullet", &"turret", &"ram"] else {}
	slot.kart.kill_how = {}
	var decoy := bool(how.get("decoy", false))
	var bounces := int(how.get("bounces", 0)) if cause != &"ram" else 0
	if decoy or bounces > 0:
		Events.kill_detailed.emit(slot.index, decoy, bounces)


## The coins that leave the pot before any of it is banked: what the killer takes off it, and
## what spills onto the floor where it died. Returns how many, which [member DeathOutcome.sealed]
## keeps at none.
static func _spill(
	match_node: Match, slot: PlayerSlot, killer: PlayerSlot, death: DeathOutcome
) -> int:
	if death.sealed:
		return 0
	var kart := slot.kart
	var stolen := 0
	if killer != null and death.steal_fraction > 0.0 and killer.kart.alive:
		stolen = floori(kart.pot.coins * death.steal_fraction)
		killer.kart.collect_coins(stolen, null)
	var drop := Scoring.death_drop(kart.pot.coins - stolen, death.drop_fraction, death.drop_max)
	if drop > 0:
		var lifetime := match_node.rules.dropped_chip_lifetime
		match_node.arena.spawn_chips(kart.global_position, drop, lifetime, 0.0, true, slot.team)
		slot.stats.add(&"coins_dropped", drop)
	return stolen + drop


## What else the kart leaves on the floor where it died: maybe a joker, and maybe its item.
static func _scatter(match_node: Match, slot: PlayerSlot, death: DeathOutcome) -> void:
	var kart := slot.kart
	var rules := match_node.rules
	var rng := match_node.rng
	var position := kart.global_position
	# With Carbon Copy what goes on the floor is a copy, and the hand keeps its own, GAME.md 7.3,
	# which its card says, 8.3.
	var copier: Joker = null
	for joker: Joker in kart.jokers.jokers:
		if copier == null and joker.copies_drops():
			copier = joker
	var held := kart.jokers.jokers.duplicate()
	var copied := false
	for i: int in death.joker_drop_count:
		if not held.is_empty() and rng.randf() < death.joker_drop_chance:
			var dropped: Joker = held.pop_at(rng.randi_range(0, held.size() - 1))
			if copier != null:
				dropped = dropped.duplicate()
				copied = true
			else:
				# Gone from the hand without the player's say, which its card says, GAME.md 8.3.
				dropped.used_up(kart, "LOST")
				kart.jokers.remove(dropped)
			match_node.arena.spawn_floor_joker(position, dropped, rules.floor_item_lifetime)
	if copied:
		copier.went_off(kart, "COPIED")
	if kart.held_item != null:
		if rng.randf() < death.item_drop_chance:
			match_node.arena.spawn_floor_item(position, kart.held_item, rules.floor_item_lifetime)
		kart.held_item = null


## The price on a head, GAME.md 3.10: paid to whoever took it, and off the board either way.
## Who is credited with [param slot]'s death, GAME.md 3.14: [param killer_slot], unless that is a
## teammate, who takes nothing for it, no mult, no life, no bounty and no Pickpocket, and nobody is
## credited. A teammate's shot or blast counts as an own goal; a bump into a pit does not.
static func _credited(
	match_node: Match, killer_slot: int, slot: PlayerSlot, cause: StringName
) -> int:
	if killer_slot < 0 or killer_slot >= match_node.slots.size():
		return killer_slot
	var killer := match_node.slots[killer_slot]
	if not Teams.teammates(killer, slot):
		return killer_slot
	if cause != &"pit":
		killer.stats.add(&"self_kills")
	return -1


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
		and _ahead(match_node, slot, killer)
	)


## Whether [param a] is ahead of [param b] in the running order: in team play their teams, by what
## each has banked and carries, GAME.md 3.14.
static func _ahead(match_node: Match, a: PlayerSlot, b: PlayerSlot) -> bool:
	if a.team < 0 or b.team < 0:
		return PlayerSlot.by_score(a, b)
	return Teams.running(match_node.slots, a.team) > Teams.running(match_node.slots, b.team)


## Says so, once the places really have changed. Going to the top of the board is a different
## thing to passing somebody in the middle of it, so it is said differently.
static func _announce_overtake(match_node: Match, slot: PlayerSlot, killer: PlayerSlot) -> void:
	if not _ahead(match_node, killer, slot):
		return
	killer.stats.add(&"overtakes")
	var first := match_node.standings()[0]
	var leading := first == killer or Teams.teammates(first, killer)
	Events.announced.emit(killer.index, "TAKING THE LEAD" if leading else "OVERTAKE")
