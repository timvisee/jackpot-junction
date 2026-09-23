class_name MatchHeat
extends RefCounted
## What the room's heat does to the table, GAME.md 8.4, kept out of [Match] with the rest of what a
## match is dressed in. The excitement meter itself is [MatchIntensity]; this is the table
## answering it.


## The room speeding everything up, GAME.md 8.4. A hot table is not only louder: the Jackpot
## fills faster and holds more, nitro comes back quicker, and past a certain heat the table
## starts throwing good jokers onto the floor. A finale where nobody has anything left to spend
## is a finale where nobody does anything.
static func step(match_node: Match, delta: float) -> void:
	var rules := match_node.rules
	var share := match_node.intensity.share()
	var last_call := rules.last_call_accrual if match_node.state == Match.State.LAST_CALL else 1.0
	for zone: JackpotZone in match_node.arena.jackpot_zones:
		zone.accrual_multiplier = lerpf(1.0, rules.jackpot_accrual_hot, share) * last_call
		zone.cap_multiplier = lerpf(1.0, rules.jackpot_cap_hot, share)
	var nitro := rules.nitro_recharge_base * lerpf(1.0, rules.nitro_recharge_hot, share)
	for slot: PlayerSlot in match_node.slots:
		if slot.kart != null:
			slot.kart.nitro_recharge_scale = nitro
	_wild_jokers(match_node, delta)


## Good cards turning up on the floor once the room is going, GAME.md 3.11. Nothing common is
## ever thrown out this way: a late match is where the jokers that change how a kart plays come
## from, and they are worth breaking off whatever you were doing for.
static func _wild_jokers(match_node: Match, delta: float) -> void:
	var rules := match_node.rules
	var level := match_node.intensity.level
	if match_node.joker_catalog == null or level < rules.wild_joker_level:
		match_node.wild_joker_left = rules.wild_joker_interval
		return
	match_node.wild_joker_left -= delta * (1.0 if level >= MatchIntensity.LEVELS else 0.5)
	if match_node.wild_joker_left > 0.0:
		return
	match_node.wild_joker_left = rules.wild_joker_interval
	var rng := match_node.rng
	var joker := match_node.joker_catalog.quality(rng, Joker.Rarity.UNCOMMON)
	if joker == null:
		return
	var arena := match_node.arena
	var half := arena.world_size() * 0.5
	var spot := arena.clamp_to_floor(
		Vector3(rng.randf_range(-half.x, half.x), 0.0, rng.randf_range(-half.y, half.y))
	)
	arena.spawn_floor_joker(spot, joker, rules.wild_joker_lifetime)
	Events.wild_joker_dropped.emit(joker.id)
