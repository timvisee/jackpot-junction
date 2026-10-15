class_name BotGoals
extends RefCounted
## Which errand a bot is on, GAME.md 9.1: fleeing, taking cover, banking, the Jackpot, a fight, a
## pickup, an item, a pad, a slot machine, or wandering about for want of anything better. A pure
## choice from a description of the situation, so it is tested with a plain dictionary; [BotBrain]
## builds the description and does the driving. The ranges and values it weighs things by are the
## brain's own.

## Seconds left on the clock under which any pot at all goes to the bank: whatever is not banked at
## the whistle is lost.
const LATE := 20.0
## How close a visible enemy has to be to a wounded bot on the Jackpot for it to leave the pile:
## one more hit loses everything it is carrying.
const WOUNDED_DANGER := 10.0


## Picks a goal from the situation. Pure, so it can be tested with a plain dictionary.
static func choose(context: Dictionary, personality: BotTrait) -> StringName:
	if float(context.get("boost_enemy_distance", INF)) <= personality.flee_distance:
		return &"flee"
	# Somewhere to hide from a kart with a line on it, in a showdown, see [BotTactics].
	if context.has("cover"):
		return &"cover"
	# Its own cash-out would take the match: straight to the Junction, before anybody can stop it.
	if bool(context.get("self_winning", false)):
		return &"bank"
	# Collecting the Jackpot, a bot stays until the pile is gone, GAME.md 9.1, whatever its pot has
	# grown to on the way: leaving half a pile is leaving it to whoever drives on next. What moves
	# it is danger -- a kart about to ram it, above, or one of those in [method in_danger].
	if bool(context.get("collecting_jackpot", false)) and not in_danger(context):
		return &"jackpot"
	var pot := int(context.get("pot_value", 0))
	# A bot that is behind settles for a smaller pot; one that is ahead can afford to hoard.
	var threshold := roundi(personality.bank_threshold / float(context.get("bank_urgency", 1.0)))
	if bool(context.get("last_call", false)):
		threshold = personality.last_call_bank_threshold
	if bool(context.get("wounded", false)):
		threshold = maxi(roundi(float(threshold) * BotBrain.WOUNDED_BANK_SHARE), 1)
	if pot > 0 and (pot >= threshold or float(context.get("time_left", INF)) < LATE):
		return &"bank"
	var jackpot_chips := int(context.get("jackpot_chips", 0))
	if (
		jackpot_chips >= personality.jackpot_min_chips
		and not bool(context.get("jackpot_contested", false))
	):
		return &"jackpot"
	var hunt := 0.0
	var enemy_distance := float(context.get("enemy_distance", INF))
	# What the enemy is carrying, to a bot that cares what anybody is carrying. A pot is coins
	# somebody else has already collected and not yet made safe, GAME.md 3.6, and a bot that
	# reads the board will cross the room for one and go further than it otherwise would.
	var purse := float(context.get("enemy_pot", 0.0)) * float(context.get("pot_greed", 0.0))
	var reach := (
		BotBrain.POT_HUNT_RANGE if purse >= BotBrain.POT_WORTH_CHASING else BotBrain.HUNT_RANGE
	)
	if bool(context.get("enemy_winning", false)):
		# A rival about to win, that this bot has chosen to go after, is gone after from anywhere
		# on the table, seen or not, however cautious the bot: stopping them may be its last
		# chance of winning itself.
		hunt = maxf(personality.hunt_weight, 1.0) * BotBrain.WINNER_PULL
	elif enemy_distance <= reach and bool(context.get("enemy_visible", false)):
		# A bot that is behind goes looking for a fight; one that is ahead can sit on its lead.
		hunt = (
			personality.hunt_weight
			* float(context.get("hunt_urgency", 1.0))
			* (
				(1.0 - enemy_distance / reach)
				+ minf(purse / BotBrain.POT_FULL_PULL, BotBrain.POT_MAX_PULL)
			)
		)
	var collect := 0.0
	var pickup_distance := float(context.get("pickup_distance", INF))
	if pickup_distance < INF:
		collect = (
			personality.collect_weight
			* float(context.get("pickup_value", 1.0))
			/ (pickup_distance + 2.0)
		)
	var item := 0.0
	var item_distance := float(context.get("item_distance", INF))
	if not bool(context.get("has_item", false)) and item_distance <= 12.0:
		item = 0.8 * personality.collect_weight * float(context.get("item_appetite", 1.0))
	var flush := 0.0
	var flush_distance := float(context.get("flush_distance", INF))
	if flush_distance < INF:
		flush = (
			personality.flush_weight
			* float(context.get("flush_value", BotBrain.PAD_VALUE))
			/ (flush_distance + 2.0)
		)
	# A pull it has made up its mind to, see [BotSlots], against the rest.
	var slot := 0.0
	var slot_distance := float(context.get("slot_distance", INF))
	if slot_distance < INF:
		slot = BotSlots.VALUE / (slot_distance + 2.0)
	if slot > 0.0 and slot >= hunt and slot >= collect and slot >= item and slot >= flush:
		return &"slot"
	if flush > 0.0 and flush >= hunt and flush >= collect and flush >= item:
		return &"flush"
	if hunt > 0.0 and hunt >= collect and hunt >= item:
		return &"hunt"
	if item > 0.0 and item > collect:
		return &"item"
	if collect > 0.0:
		return &"collect"
	return &"wander"


## Danger enough to leave the Jackpot for, short of a kart about to ram: the clock about to take
## the pot anyway, or a wounded bot with somebody close enough to land the hit that loses it.
static func in_danger(context: Dictionary) -> bool:
	if float(context.get("time_left", INF)) < LATE:
		return true
	if not bool(context.get("wounded", false)):
		return false
	return (
		bool(context.get("near_enemy_visible", false))
		and float(context.get("near_enemy_distance", INF)) <= WOUNDED_DANGER
	)
