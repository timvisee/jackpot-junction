class_name BotGoals
extends RefCounted
## Which errand a bot is on, GAME.md 9.1: fleeing, banking, the Jackpot, a fight, a pickup, an item,
## a pad, or wandering about for want of anything better. A pure choice from a description of the
## situation, so it is tested with a plain dictionary; [BotBrain] builds the description and does
## the driving. The ranges and values it weighs things by are the brain's own.


## Picks a goal from the situation. Pure, so it can be tested with a plain dictionary.
static func choose(context: Dictionary, personality: BotTrait) -> StringName:
	if float(context.get("boost_enemy_distance", INF)) <= personality.flee_distance:
		return &"flee"
	var pot := int(context.get("pot_value", 0))
	# A bot that is behind settles for a smaller pot; one that is ahead can afford to hoard.
	var threshold := roundi(personality.bank_threshold / float(context.get("bank_urgency", 1.0)))
	if bool(context.get("last_call", false)):
		threshold = personality.last_call_bank_threshold
	if bool(context.get("wounded", false)):
		threshold = maxi(roundi(float(threshold) * BotBrain.WOUNDED_BANK_SHARE), 1)
	if pot > 0 and (pot >= threshold or float(context.get("time_left", INF)) < 20.0):
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
	if enemy_distance <= reach and bool(context.get("enemy_visible", false)):
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
	if flush > 0.0 and flush >= hunt and flush >= collect and flush >= item:
		return &"flush"
	if hunt > 0.0 and hunt >= collect and hunt >= item:
		return &"hunt"
	if item > 0.0 and item > collect:
		return &"item"
	if collect > 0.0:
		return &"collect"
	return &"wander"
