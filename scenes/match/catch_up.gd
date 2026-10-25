class_name CatchUp
extends RefCounted
## Rubber banding, GAME.md 3.16: a player or team behind the leader earns coins faster, pulls
## stronger items, and draws a sooner, richer bounty onto the leader, so a runaway game stays close.
## The bonus fades as the gap closes, so it never hands the win to whoever is behind. Everything is
## read off the standings, which are the same on every machine, so the host's economy and each
## screen's HUD agree without a word over the wire beyond the [member MatchRules.catch_up] switch.
## Ticked by the match each frame on every machine, as [TireMarks] is.


## Sets every kart's [member Kart.coin_bonus] from how far its side trails the leader, so a trailing
## kart earns that much more from each chip, GAME.md 3.16.
static func update(match_node: Match) -> void:
	for slot: PlayerSlot in match_node.slots:
		if slot.kart != null:
			slot.kart.coin_bonus = factor(match_node, slot)


## The coin multiplier for [param slot]: 1.0 when level, ahead, or the rule is off, ramping to
## [member MatchRules.catch_up_max] as its deficit reaches [member MatchRules.catch_up_deficit].
static func factor(match_node: Match, slot: PlayerSlot) -> float:
	var rules := match_node.rules
	if rules == null or not rules.catch_up or not _counts(match_node):
		return 1.0
	var mine := _side_score(match_node.slots, slot)
	var leader := mine
	for other: PlayerSlot in match_node.slots:
		leader = maxi(leader, _side_score(match_node.slots, other))
	var deficit := leader - mine
	if deficit <= 0 or rules.catch_up_deficit <= 0.0:
		return 1.0
	var share := clampf(float(deficit) / rules.catch_up_deficit, 0.0, 1.0)
	return 1.0 + (rules.catch_up_max - 1.0) * share


## How much [param kart]'s item pick leans toward stronger items, GAME.md 3.16: none level or ahead,
## up to [member MatchRules.catch_up_item_bias] at full deficit, read off the coin bonus it already
## carries so the two scale together, see [method PowerUpTable.pick].
static func item_bias(kart: Kart) -> float:
	var rules := kart.rules
	if rules == null or not rules.catch_up or rules.catch_up_max <= 1.0:
		return 0.0
	var share := clampf((kart.coin_bonus - 1.0) / (rules.catch_up_max - 1.0), 0.0, 1.0)
	return share * rules.catch_up_item_bias


## The lead a bounty is called on and the reward it pays while catch up is on, GAME.md 3.16: a
## runaway leader is hunted sooner and for more. The plain values when it is off.
static func bounty_lead(rules: MatchRules, lead: int) -> int:
	return int(lead * rules.catch_up_bounty_lead) if rules.catch_up else lead


static func bounty_reward(rules: MatchRules, reward: int) -> int:
	return int(reward * rules.catch_up_bounty_reward) if rules.catch_up else reward


## A side's live score, GAME.md 3.14: its team's running total in team play, its own otherwise.
static func _side_score(slots: Array[PlayerSlot], slot: PlayerSlot) -> int:
	return Teams.running(slots, slot.team) if slot.team >= 0 else slot.score()


## Whether the race is on, so a catch-up bonus is worth anything: not in the lobby, the countdown or
## once the whistle has gone.
static func _counts(match_node: Match) -> bool:
	return match_node.state in [Match.State.PLAYING, Match.State.LAST_CALL, Match.State.OVERTIME]
