class_name BotBrain
extends Node
## The utility AI from GAME.md 9.1. Every tenth of a second it picks a goal from its trait's
## weights and the situation; every tick it follows a grid path toward the goal, dodges bullets
## it can see coming, fires when an enemy is in front of the cannon after its reaction delay, and
## uses its item when the moment fits. With nothing to shoot at, it breaks open whatever scenery
## is in front of the cannon instead, since a crate pays in chips and a target pays in coins.
## Writes into a [BotInput] the kart reads.
##
## How keenly it does any of that is set by the [BotMirror] on the match: the bots play at
## the pitch the players set, with their own trait on top.

## Which karts [method _nearest_other] looks for: any it could hurt, one ramming with Boost or
## nitro, or a rival about to win that this bot goes after.
enum Kind { TARGET, RAMMING, WINNING }

const DECISION_INTERVAL := 0.1
## How long a bot sticks with a goal before a merely better one can take it off, GAME.md 9.1.
## Ten decisions a second with nothing holding them together makes a bot that dithers between
## two errands it is equally near; danger and a goal that has gone away still cut in at once.
const GOAL_DWELL := 1.5
## Inside this of its target the bot has arrived, and whatever it went there for is done.
const ARRIVED_RADIUS := 2.0
## What the context has to still be offering for each errand, so a bot notices at once when the
## thing it set out for has been taken, collected or has driven off.
const GOAL_NEEDS: Dictionary[StringName, String] = {
	&"flee": "boost_enemy",
	&"jackpot": "jackpot_position",
	&"hunt": "enemy",
	&"item": "item",
	&"collect": "pickup",
	&"flush": "flush_pad",
	&"slot": "slot_pad",
	&"cover": "cover",
}
const HUNT_RANGE := 18.0
## How far a bot that reads the board will go after a pot, and the smallest pot worth crossing
## the room for, GAME.md 9.1.
const POT_HUNT_RANGE := 26.0
const POT_WORTH_CHASING := 150.0
## The pot worth a full point of pull toward its carrier, and the most pull any pot can be
## worth. Added to the urge to hunt rather than multiplied into it, because distance is exactly
## what a pot is meant to overcome: somebody about to win is worth crossing the room for.
const POT_FULL_PULL := 500.0
const POT_MAX_PULL := 3.0
## What a Royal Flush pad is worth to a bot: a pad on its own, then one that would complete
## the set. A pad pays its holder for as long as they keep it, GAME.md 3.9, and the fourth
## one is worth a detour across the arena.
const PAD_VALUE := 4.0
const PAD_FLUSH_VALUE := 24.0
## A rival one cash-out from winning, GAME.md 9.1: how strongly a bot is pulled to go after them,
## ahead of almost anything else, and how far off it lights nitro to ram them.
const WINNER_PULL := 8.0
const WINNER_RAM_REACH := 14.0
## A pad of the bot's own with less than this left on the clock is worth going back for.
const PAD_RENEW_LEFT := 10.0
const PAD_RENEW_VALUE := 2.5
## How far off the nose a shot is still taken, before the target's own width is added to it,
## and the widest that sum is allowed to get.
const FIRE_CONE := 0.14
const FIRE_CONE_MAX := 1.1
## Half the width of what is being shot at, near enough: a kart is a meter across and a box is
## about the same.
const TARGET_HALF_WIDTH := 0.6
const DODGE_RANGE := 8.0
const DODGE_HORIZON := 1.0
const DODGE_DISTANCE := 1.2
const DODGE_TIME := 0.35
const AIM_ERROR_INTERVAL := 0.5
## How far ahead of a kart it is hunting a bot steers, in seconds of the kart's travel, see
## [method _steer].
const STEER_LEAD := 0.5
const ITEM_PATIENCE := 5.0
## Given up on, see [method go_elsewhere]: how long the errand somewhere else is held, and how far
## away somewhere else is at least.
const ELSEWHERE_TIME := 4.0
const ELSEWHERE_DISTANCE := 12.0
const BULLET_HEIGHT := 0.5
## What a wounded bot cuts its banking threshold to: a full cash-out is also how it gets its
## second life back, GAME.md 3.4, so it settles for a smaller pot to go and collect one.
const WOUNDED_BANK_SHARE := 0.5
## How far away a crate or a target is still worth a shot, with nothing better to fire at.
const SCENERY_RANGE := 13.0
## How far short of a piece of scenery its line of sight is checked, so it does not block the
## view of itself.
const SCENERY_CLEARANCE := 0.9

var kart: Kart
var match_node: Match
var input := BotInput.new()
var bot_trait: BotTrait
var difficulty: BotDifficulty
var rng: RandomNumberGenerator
var goal := &"collect"
var target := Vector3.ZERO
var target_node: Node3D
## Led along a person's own line at the Final Hand's last quarter, STORY.md 8.2, see [BotLed]: a
## model of them rather than a hunter, deciding nothing else and holding its fire and its items.
var led := BotLed.new(self)
## Getting it off a wall and out of a corner, see [BotStuck].
var stuck := BotStuck.new(self)
## Getting it where it is going, see [BotDrive].
var drive := BotDrive.new(self)
## Shots that do not fly off the nose, and somewhere to hide, see [BotTactics].
var tactics := BotTactics.new(self)
var slots := BotSlots.new()
## The last word on its driving, which keeps it out of the holes, see [BotPits].
var pits := BotPits.new(self)

var _decision_left := 0.0
var _dodge_left := 0.0
var _dodge_steer := 0.0
## Whether this bot reacts to each bullet it has seen, decided once so it does not change its
## mind about the same one every frame. Kept only for bullets still in the air: a match fires
## thousands, and a bot that remembered every one of them would carry the lot to the whistle.
## Taken again once the bullet has bounced: off a wall it is a bullet coming another way.
var _dodge_rolls: Dictionary[int, bool] = {}
var _dodge_bounces: Dictionary[int, int] = {}
## Whether this bot goes after each rival one cash-out from winning, by slot, see [method
## _winning_rival], forgotten once they no longer are.
var _chases: Dictionary[int, bool] = {}
var _aim_timer := 0.0
var _aim_error := 0.0
var _aim_error_left := 0.0
var _willing_to_fire := true
## How long the current goal has been held.
var _goal_held := 0.0
var _item_hold_time := 0.0
## How much longer the errand somewhere else is held, see [method go_elsewhere].
var _elsewhere_left := 0.0
## Who is about, as of the last decision, see [method _look_around]: the kart it would go after
## and whether it is in reach and in sight, the rival about to win it goes after, the nearest
## enemy, and the scenery it would shoot with nobody in reach.
var _mark: Kart
var _mark_visible := false
var _mark_seen := false
var _winner: Kart
var _nearest: Kart
var _scenery: Node3D
## The best scenery to shoot at so far, and how far away it is, while [method _scenery_mark] looks.
var _best_scenery: Node3D
var _best_scenery_distance := 0.0
## Stands in for the match's reading when a brain is stepped on its own, in tests.
var _fallback := BotMirror.new()


func setup(
	bot_kart: Kart,
	the_match: Match,
	personality: BotTrait,
	level: BotDifficulty,
	random: RandomNumberGenerator
) -> void:
	kart = bot_kart
	match_node = the_match
	bot_trait = personality
	difficulty = level
	rng = random
	if bot_kart.input is BotInput:
		input = bot_kart.input
	elif bot_kart.input is DemoInput:
		input = (bot_kart.input as DemoInput).bot
	else:
		bot_kart.input = input


func _ready() -> void:
	process_physics_priority = -1
	_decision_left = rng.randf_range(0.0, DECISION_INTERVAL) if rng != null else 0.0


func _physics_process(delta: float) -> void:
	if kart == null or not kart.is_active() or not match_node.is_running():
		input.clear()
		return
	_decision_left -= delta
	input.fire_pressed = false
	input.use_item_pressed = false
	if led.is_on():
		goal = &"led"
		target_node = null
		if not led.drive(delta):
			target = led.back_to()
			_steer(delta)
			pits.guard()
		return
	if _decision_left <= 0.0:
		_decision_left = DECISION_INTERVAL
		_decide()
		_forget_spent_bullets()
	tactics.step(delta)
	_steer(delta)
	_dodge(delta)
	_shoot(delta)
	_use_item(delta)
	_burn_nitro()
	pits.guard()


## Closest distance two objects reach within [param horizon] seconds, from their relative
## position and velocity on the floor plane.
static func closest_approach(
	relative_position: Vector3, relative_velocity: Vector3, horizon: float
) -> float:
	var r := Vector3(relative_position.x, 0.0, relative_position.z)
	var v := Vector3(relative_velocity.x, 0.0, relative_velocity.z)
	var speed_squared := v.length_squared()
	if speed_squared < 0.0001:
		return r.length()
	var t := clampf(-r.dot(v) / speed_squared, 0.0, horizon)
	return (r + v * t).length()


func _decide() -> void:
	if _elsewhere_left > 0.0 and kart.global_position.distance_to(target) > ARRIVED_RADIUS:
		_elsewhere_left -= DECISION_INTERVAL
		_look_around()
		return
	_elsewhere_left = 0.0
	var context := _context()
	var wanted := BotGoals.choose(context, bot_trait)
	if wanted != goal and not _may_switch(wanted, context):
		wanted = goal
	_goal_held = _goal_held + DECISION_INTERVAL if wanted == goal else 0.0
	goal = wanted
	target_node = null
	match goal:
		&"flee":
			var threat: Node3D = context["boost_enemy"]
			var away := (kart.global_position - threat.global_position).normalized()
			target = _clamp_to_arena(kart.global_position + away * 8.0)
		&"bank":
			target = match_node.arena.junction_near(kart.global_position)
		&"jackpot":
			target = context["jackpot_position"]
		&"hunt":
			target_node = context["enemy"]
			target = target_node.global_position
		&"item":
			target_node = context["item"]
			target = target_node.global_position
		&"collect":
			target_node = context["pickup"]
			target = target_node.global_position
		&"flush", &"slot":
			target_node = context[GOAL_NEEDS[goal]]
			target = target_node.global_position
		&"cover":
			target = context["cover"]
		_:
			target = _clamp_to_arena(
				(
					match_node.arena.junction_near(kart.global_position)
					+ Vector3(rng.randf_range(-8.0, 8.0), 0.0, rng.randf_range(-5.0, 5.0)) * _span()
				)
			)
	_willing_to_fire = rng.randf() < bot_trait.fire_chance
	if _mark != null:
		tactics.think_bank(_lead_point(_mark), _mark_seen)


## Looks about the room, at the pace the bot thinks rather than every tick, GAME.md 9.1: who it
## would go after and whether it has a line on them, the rival about to win it goes after, the
## nearest enemy, and, with nobody in reach, the scenery in front of it worth a shot. Every tick
## asked all of that of every kart and every crate, with rays, and a tenth of a second is quicker
## than any reaction delay a bot has.
func _look_around() -> void:
	_winner = _winning_rival()
	_mark = _winner if _winner != null else _quarry()
	_nearest = _nearest_enemy()
	_mark_visible = _mark != null and has_line_of_sight(_mark.global_position)
	_mark_seen = (
		_mark_visible and kart.global_position.distance_to(_mark.global_position) <= HUNT_RANGE
	)
	_scenery = null if _mark_seen else _scenery_mark()


## Gives up on what it was doing, GAME.md 9.1, having got nowhere at it for a long while, see
## [BotStuck]: backs away and wanders off to a spawn point well away from here, and holds to that
## for a few seconds, so that the next decision does not send it straight back.
func go_elsewhere() -> void:
	goal = &"wander"
	target_node = null
	var away: Array[Vector3] = []
	for point: Vector3 in match_node.arena.spawns_for(match_node.slots.size()):
		if point.distance_to(kart.global_position) > ELSEWHERE_DISTANCE:
			away.append(point)
	if away.is_empty():
		target = _clamp_to_arena(match_node.arena.junction_position)
	else:
		target = away[rng.randi_range(0, away.size() - 1)] if rng != null else away[0]
	drive._planned_target = Vector3.INF
	_elsewhere_left = ELSEWHERE_TIME
	stuck.begin_backing_out()


## Whether a bot is allowed to drop what it is doing for [param wanted], GAME.md 9.1. Something
## about to hit it, and an errand that has stopped existing, are both worth turning on a penny
## for; anything else waits out the dwell, so two errands a bot is equally near stop pulling it
## back and forth. Wandering is what a bot does for want of a plan, so it never holds one up.
func _may_switch(wanted: StringName, context: Dictionary) -> bool:
	if wanted == &"flee" or goal == &"wander":
		return true
	# Danger on the Jackpot is danger now, not after the dwell.
	if goal == &"jackpot" and BotGoals.in_danger(context):
		return true
	if not _goal_still_on(context):
		return true
	# An errand the bot is standing on is finished, whatever the clock says. Holding one of
	# those leaves a bot shuffling about on the pad it has just claimed waiting to be let go. A
	# pull is not: it is over once the bot has pulled, and the machine leaves its context then.
	var arrived := kart.global_position.distance_to(target) < ARRIVED_RADIUS
	if goal != &"slot" and not holding_position() and arrived:
		return true
	return _goal_held >= GOAL_DWELL


## Whether what the bot is doing now is still there to be done.
func _goal_still_on(context: Dictionary) -> bool:
	return not GOAL_NEEDS.has(goal) or context.has(GOAL_NEEDS[goal])


func _context() -> Dictionary:
	var mirror := bot_mirror()
	var context := {
		"item_appetite": mirror.item_appetite(),
		"bank_urgency": mirror.effort,
		"hunt_urgency": mirror.hunt_urgency(),
		"pot_value": kart.pot.value(),
		# Sudden death has no clock, GAME.md 3.13: its nought is no seconds left, and read as that
		# it sent a bot to the bank with the first chip it took off the Jackpot.
		"time_left": INF if match_node.state == Match.State.OVERTIME else match_node.time_left,
		# Bots on their own in sudden death for long enough end it, see [BotMirror].
		"finish_it": mirror.finishing(),
		# Sudden death reads as Last Call to a bot: what is in the pot is worth taking to the
		# Junction now, because there is no lap after this one.
		"last_call": match_node.in_the_finale(),
		"has_item": kart.held_item != null,
		"wounded": kart.is_wounded(),
	}
	_look_around()
	var enemy := _mark
	if enemy != null:
		context["enemy"] = enemy
		context["enemy_distance"] = kart.global_position.distance_to(enemy.global_position)
		# Nobody hides for long in a showdown's room, GAME.md 9.7a, and there is nothing else in it to
		# do: a bot knows where the nearest kart is, seen or not, and goes after it. So does a bot
		# ending sudden death with nobody but bots left in it, 3.13.
		context["enemy_visible"] = (
			match_node.rules.showdown() or mirror.finishing() or _mark_visible
		)
		context["enemy_pot"] = enemy.pot.value()
		context["pot_greed"] = difficulty.pot_hunting if difficulty != null else 0.0
		context["enemy_winning"] = enemy == _winner
		# A showdown's kart worse off than the one with a line on it goes behind something.
		if enemy is Kart and tactics.think_cover(enemy as Kart) != Vector3.INF:
			context["cover"] = tactics.cover
	# Its own cash-out would take the match: nothing else is worth the time.
	context["self_winning"] = (
		not kart.is_decoy()
		and kart.slot < match_node.slots.size()
		and match_node.would_win(match_node.slots[kart.slot])
	)
	var threat := _nearest_boosting_enemy()
	if threat != null:
		context["boost_enemy"] = threat
		context["boost_enemy_distance"] = kart.global_position.distance_to(threat.global_position)
	for zone: JackpotZone in match_node.arena.jackpot_zones:
		if zone.active:
			context["jackpot_chips"] = zone.whole_chips()
			context["jackpot_contested"] = zone.occupant_count(kart) > 0
			context["jackpot_position"] = zone.global_position
			# Came for it, standing in it, and alone there, so the pile is running into its pot.
			context["collecting_jackpot"] = (
				goal == &"jackpot" and zone.holds(kart) and not context["jackpot_contested"]
			)
	if context.get("collecting_jackpot", false) and kart.is_wounded():
		var near := _nearest
		if near != null:
			context["near_enemy_distance"] = kart.global_position.distance_to(near.global_position)
			context["near_enemy_visible"] = has_line_of_sight(near.global_position)
	var best_pickup: Pickup = null
	var best_score := 0.0
	var best_item: Pickup = null
	var best_item_distance := INF
	# By index rather than over get_children(), which builds the list afresh ten times a second.
	var pickups := match_node.arena.pickups
	for index: int in pickups.get_child_count():
		var pickup := pickups.get_child(index) as Pickup
		if pickup == null or not pickup.can_collect(kart):
			continue
		var distance := kart.global_position.distance_to(pickup.global_position)
		if pickup is ItemBox:
			if distance < best_item_distance:
				best_item_distance = distance
				best_item = pickup
			continue
		var value := _pickup_value(pickup)
		var score := value / (distance + 2.0)
		if score > best_score:
			best_score = score
			best_pickup = pickup
	if best_pickup != null:
		context["pickup"] = best_pickup
		context["pickup_value"] = _pickup_value(best_pickup)
		context["pickup_distance"] = kart.global_position.distance_to(best_pickup.global_position)
	if best_item != null:
		context["item"] = best_item
		context["item_distance"] = best_item_distance
	_add_flush_context(context)
	var machine := slots.wanted(kart, bot_trait.slot_appetite, rng, DECISION_INTERVAL)
	if machine != null:
		context["slot_pad"] = machine
		context["slot_distance"] = kart.global_position.distance_to(machine.global_position)
	return context


## The Royal Flush pad worth driving to, GAME.md 3.9. A pad somebody else holds, or nobody
## does, is worth taking; the one that would complete the set is worth far more; and a pad of
## the bot's own that is about to lapse is worth going back over to renew. In team play its
## team's pads are its own, 3.14.
func _add_flush_context(context: Dictionary) -> void:
	var pads := match_node.arena.flush_pads
	var held := 0
	for pad: FlushPad in pads:
		if _ours(pad.owner_slot, pad.owner_team) and not pad.is_disabled():
			held += 1
	var best: FlushPad = null
	var best_score := 0.0
	var best_value := 0.0
	for pad: FlushPad in pads:
		if pad.is_disabled():
			continue
		var value := PAD_VALUE
		if _ours(pad.owner_slot, pad.owner_team):
			if pad.held_left > PAD_RENEW_LEFT:
				continue
			value = PAD_RENEW_VALUE
		elif held >= pads.size() - 1:
			# The last one of the set: taking it is the flush itself.
			value = PAD_FLUSH_VALUE
		var distance := kart.global_position.distance_to(pad.global_position)
		var score := value / (distance + 2.0)
		if score > best_score:
			best_score = score
			best = pad
			best_value = value
	if best == null:
		return
	context["flush_pad"] = best
	context["flush_value"] = best_value
	context["flush_distance"] = kart.global_position.distance_to(best.global_position)


func _pickup_value(pickup: Pickup) -> float:
	var chip := pickup as Chip
	if chip != null:
		return float(chip.value) * maxf(kart.pot.mult, 1.0)
	if pickup is MultDie:
		return 3.0 * maxf(float(kart.pot.coins), 2.0)
	if pickup is FloorJoker:
		return 6.0
	return 1.0


## How much further a bot goes looking on this floor than on a map of the usual size, GAME.md
## 6.3: an XL map's is a third again as wide, and a bot that only ever looked as far as it does on
## the usual one hung about the middle of it.
func _span() -> float:
	return maxf(1.0, match_node.arena.world_size().x / 40.0)


## Who to go after: a rival whose cash-out would win the match, wherever they are, then whoever
## is carrying a bounty, when they are close enough to be worth the detour, then whoever is
## carrying a pot worth taking off them, and otherwise simply the nearest enemy. Asked afresh;
## the brain itself asks at the pace it thinks, see [method _look_around].
func _hunt_target() -> Kart:
	var winner := _winning_rival()
	return winner if winner != null else _quarry()


## Who to go after with nobody about to win: whoever carries a bounty near enough, whoever carries
## a pot worth taking off them, or the nearest enemy, see [method _hunt_target].
func _quarry() -> Kart:
	var bounty := match_node.bounty_kart()
	if bounty != null and not _ours(bounty.slot, bounty.team) and bounty.is_targetable():
		if kart.global_position.distance_to(bounty.global_position) <= HUNT_RANGE * _span():
			return bounty
	var rich := _richest_enemy()
	return rich if rich != null else _nearest_enemy()


## The enemy carrying the most, among those close enough and loaded enough to be worth going
## after, GAME.md 9.1. Null for a bot that does not read the board, which is every bot below
## hard, and for a room where nobody is carrying anything worth crossing it for.
func _richest_enemy() -> Kart:
	if difficulty == null or difficulty.pot_hunting <= 0.0:
		return null
	var best: Kart = null
	var best_pot := POT_WORTH_CHASING
	for node: Node in FrameGroups.of(get_tree(), &"karts"):
		var other := node as Kart if is_instance_valid(node) else null
		if other == null or _ours(other.slot, other.team) or not other.is_targetable():
			continue
		if kart.global_position.distance_to(other.global_position) > POT_HUNT_RANGE * _span():
			continue
		if float(other.pot.value()) > best_pot:
			best_pot = float(other.pot.value())
			best = other
	return best


## The nearest rival one cash-out from winning that this bot goes after, GAME.md 9.1, or null: its
## trait's chance, decided once each time a rival gets there, so it commits to the chase or not.
func _winning_rival() -> Kart:
	if not _chases.is_empty():
		for index: int in _chases.keys():
			if (
				index >= match_node.slots.size()
				or not match_node.would_win(match_node.slots[index])
			):
				_chases.erase(index)
	return _nearest_other(Kind.WINNING)


## Whether this bot goes after the rival in [param index] about to win, deciding it the first time.
func _chases_after(index: int) -> bool:
	if not _chases.has(index):
		var roll := rng.randf() if rng != null else randf()
		_chases[index] = bot_trait != null and roll < bot_trait.winner_chase
	return _chases[index]


func _nearest_enemy() -> Kart:
	return _nearest_other(Kind.TARGET)


func _nearest_boosting_enemy() -> Kart:
	return _nearest_other(Kind.RAMMING)


## The closest kart that is neither this one nor a teammate, GAME.md 3.14, and is of the
## [param kind] asked for, or null. By kind rather than by a test handed in, which was a new
## function made for every kart looked at, several times a tick.
func _nearest_other(kind: Kind) -> Kart:
	var best: Kart = null
	var best_distance := INF
	for node: Node in FrameGroups.of(get_tree(), &"karts"):
		var other := node as Kart if is_instance_valid(node) else null
		if other == null or _ours(other.slot, other.team) or not _of_kind(other, kind):
			continue
		var distance := kart.global_position.distance_to(other.global_position)
		if distance < best_distance:
			best_distance = distance
			best = other
	return best


## Whether [param other] is of the [param kind] [method _nearest_other] looks for.
func _of_kind(other: Kart, kind: Kind) -> bool:
	match kind:
		Kind.RAMMING:
			return other.alive and other.ramming
		Kind.WINNING:
			return (
				other.is_targetable()
				and not other.is_decoy()
				and other.slot < match_node.slots.size()
				and match_node.would_win(match_node.slots[other.slot])
				and _chases_after(other.slot)
			)
	return other.is_targetable()


## Whether what belongs to [param slot] on [param team] is on this bot's side: its own, or in team
## play a teammate's, GAME.md 3.14, never to be gone after.
func _ours(slot: int, team: int) -> bool:
	return Teams.allied(kart.slot, kart.team, slot, team)


## Whether [param bullet] is no danger to this bot: its own, or a teammate's with friendly fire
## off, GAME.md 3.14, which goes through it.
func _harmless(bullet: Bullet) -> bool:
	# Its own, unless it has come back off a wall or a bumper where a kart's own shots hurt it.
	if bullet.owner_slot == kart.slot:
		return bullet.turns == 0 or not kart.rules.own_bullets_hurt
	return bullet.spares_team and Teams.same(bullet.owner_team, kart.team)


func has_line_of_sight(point: Vector3) -> bool:
	var space := kart.get_world_3d().direct_space_state
	var from := kart.global_position + Vector3(0.0, BULLET_HEIGHT, 0.0)
	var to := Vector3(point.x, BULLET_HEIGHT, point.z)
	var ray := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	return space.intersect_ray(ray).is_empty()


func _clamp_to_arena(point: Vector3) -> Vector3:
	var half := match_node.arena.world_size() * 0.5 - Vector2.ONE * 2.0
	return Vector3(clampf(point.x, -half.x, half.x), 0.0, clampf(point.z, -half.y, half.y))


## One tick's driving toward the target, see [BotDrive]: a kart it is going after is followed
## where it moves, and one it is hunting is led a little, so the bot comes round to where its
## shot would meet it rather than to where it was; not as far as the shot itself leads it, which
## for a kart running away is halfway across the room.
func _steer(delta: float) -> void:
	if target_node != null and is_instance_valid(target_node):
		target = target_node.global_position
		if goal == &"hunt":
			target = _clamp_to_arena(_lead_point(target_node, STEER_LEAD))
	drive.step(delta)


## Where to aim to hit [param enemy], GAME.md 9.1: where it will be when the shot gets there,
## from the muzzle at the speed the shot flies, the moment the two meet worked out rather than
## guessed from how far away the kart is now. The guess fell further behind the faster a kart
## crossed in front, and a kart crossing in front is the shot there is to take. Led no further
## than [param longest] seconds, nor than a shot lives.
func _lead_point(enemy: Node3D, longest: float = INF) -> Vector3:
	var enemy_kart := enemy as Kart
	# Blind Spot, one of Kit's cards: aimed at where the kart is, never at where it is going,
	# STORY.md 6.3.
	if enemy_kart == null or KitCards.holds(enemy_kart, &"blind_spot"):
		return enemy.global_position
	var stats := kart.cannon.current_stats()
	var muzzle := kart.global_position + kart.motor.forward_vector() * stats.muzzle_offset
	var flight := intercept_time(
		enemy.global_position - muzzle, enemy_kart.motor.velocity, stats.bullet_speed
	)
	flight = minf(flight, minf(longest, stats.lifetime))
	return enemy.global_position + enemy_kart.motor.velocity * flight


## When a shot at [param speed] from here meets something [param relative] away moving at
## [param velocity], on the floor plane: the sooner of the two times the distance it has moved
## to equals the distance the shot has, or, for something running away faster than any shot,
## the time the shot takes to where it is now.
static func intercept_time(relative: Vector3, velocity: Vector3, speed: float) -> float:
	var r := Vector2(relative.x, relative.z)
	var v := Vector2(velocity.x, velocity.z)
	var guess := r.length() / maxf(speed, 0.01)
	var a := v.length_squared() - speed * speed
	var b := 2.0 * r.dot(v)
	var c := r.length_squared()
	if absf(a) < 0.0001:
		return -c / b if b < 0.0 else guess
	var root := b * b - 4.0 * a * c
	if root < 0.0:
		return guess
	root = sqrt(root)
	var soon := minf((-b - root) / (2.0 * a), (-b + root) / (2.0 * a))
	var late := maxf((-b - root) / (2.0 * a), (-b + root) / (2.0 * a))
	if soon > 0.0:
		return soon
	return late if late > 0.0 else guess


## Banking and collecting the Jackpot mean standing still inside the zone.
func holding_position() -> bool:
	if goal == &"led":
		return led.holding()
	if goal == &"bank":
		return (
			kart.global_position.distance_to(match_node.arena.junction_near(kart.global_position))
			< match_node.arena.junction_radius - 0.9
		)
	if goal == &"jackpot":
		return kart.global_position.distance_to(target) < 0.8
	if goal == &"cover":
		return kart.global_position.distance_to(target) < BotTactics.COVER_ARRIVED
	return false


## Drops the dodge decisions for bullets that have gone, at the pace the bot thinks rather than
## every frame: nothing goes wrong while a dead one lingers, it simply takes up room.
func _forget_spent_bullets() -> void:
	if _dodge_rolls.is_empty():
		return
	var live: Dictionary[int, bool] = {}
	for bullet: Bullet in match_node.bullets.bullets:
		var id := bullet.get_instance_id()
		if _dodge_rolls.has(id):
			live[id] = _dodge_rolls[id]
	_dodge_rolls = live
	for id: int in _dodge_bounces.keys():
		if not live.has(id):
			_dodge_bounces.erase(id)


func _dodge(delta: float) -> void:
	if _dodge_left > 0.0:
		_dodge_left -= delta
		input.steer = _dodge_steer
		input.handbrake = false
		return
	for bullet: Bullet in match_node.bullets.bullets:
		if _harmless(bullet) or bullet.is_dead():
			continue
		var relative := bullet.global_position - kart.global_position
		if relative.length() > DODGE_RANGE:
			continue
		var approach := closest_approach(
			relative, bullet.velocity - kart.motor.velocity, DODGE_HORIZON
		)
		if approach >= DODGE_DISTANCE:
			continue
		var id := bullet.get_instance_id()
		# Off a wall or a bumper it is a bullet coming another way, and decided about again.
		if _dodge_bounces.get(id, 0) != bullet.turns:
			_dodge_rolls.erase(id)
		_dodge_bounces[id] = bullet.turns
		if not _dodge_rolls.has(id):
			_dodge_rolls[id] = (
				rng.randf() < clampf(difficulty.dodge_chance * bot_trait.dodge_multiplier, 0.0, 1.0)
			)
		if not _dodge_rolls[id]:
			continue
		var side := bullet.velocity.cross(Vector3.UP).normalized()
		if Vector3(relative.x, 0.0, relative.z).dot(side) > 0.0:
			side = -side
		var angle := kart.motor.forward_vector().signed_angle_to(side, Vector3.UP)
		_dodge_steer = -clampf(angle * 2.0, -1.0, 1.0)
		_dodge_left = DODGE_TIME
		input.steer = _dodge_steer
		return


func _shoot(delta: float) -> void:
	_aim_error_left -= delta
	if _aim_error_left <= 0.0:
		_aim_error_left = AIM_ERROR_INTERVAL
		var spread := deg_to_rad(difficulty.aim_error_deg / bot_mirror().effort)
		_aim_error = rng.randf_range(-spread, spread)
	input.fire = false
	input.aim = Vector2.ZERO
	var mark: Node3D = _mark if _still_there(_mark) else null
	# A bot that holds its fire this life still shoots at a rival about to win, and a decoy always
	# shoots, whatever its trait: one holding its fire or ramming for its twenty seconds was no use
	# to its owner, GAME.md 7.2.
	var decoy := kart.is_decoy()
	# Nor does a bot in a showdown, GAME.md 9.7a, a fight with nothing else in it, which starts
	# with a row of crates to shoot a way out through, nor bots ending sudden death on their own.
	var shoots := decoy or match_node.rules.showdown() or bot_mirror().finishing()
	var willing := shoots or _willing_to_fire or (mark != null and mark == _winner)
	if not willing or (bot_trait.rams and not shoots):
		_aim_timer = 0.0
		return
	# One round a wall is shot off the wall, with bullets that bounce, see [BotTactics].
	var banked := Vector3.ZERO
	if mark == null or not _mark_seen:
		banked = tactics.bank_way if mark != null else Vector3.ZERO
		if banked == Vector3.ZERO:
			# Nobody worth shooting: break something open instead.
			mark = _scenery if _still_there(_scenery) else null
	if mark == null:
		_aim_timer = 0.0
		return
	var to_aim := banked if banked != Vector3.ZERO else _lead_point(mark) - kart.global_position
	to_aim.y = 0.0
	_swivel(to_aim)
	var cone := FIRE_CONE if banked != Vector3.ZERO else _fire_cone(to_aim.length())
	if banked != Vector3.ZERO:
		var turn := tactics.aim().signed_angle_to(banked, Vector3.UP)
		input.steer = -clampf(turn * BotDrive.STEER_GAIN, -1.0, 1.0)
	elif tactics.backfire(to_aim, cone):
		# Holding Backfire, a mark behind is shot out of the back, braking for it, GAME.md 7.3.
		input.brake = 1.0
	# Where the cannon points, which Backfire turns round while the brake is held.
	var angle := tactics.aim().signed_angle_to(to_aim, Vector3.UP) + _aim_error
	if absf(angle) > cone:
		_aim_timer = 0.0
		return
	_aim_timer += delta
	input.fire = _aim_timer >= difficulty.reaction_delay and not tactics.bounces_back()


## Points a cannon that aims freely, the Swivel Cannon's, GAME.md 7.1, along [param to_aim], as a
## player does with the stick, off by the same wobble the wheel would have been: a bot used to
## hold one for its twelve seconds and fire it down its nose.
func _swivel(to_aim: Vector3) -> void:
	if not kart.cannon.current_stats().free_aim or to_aim.is_zero_approx():
		return
	var way := to_aim.normalized().rotated(Vector3.UP, _aim_error)
	input.aim = Vector2(way.x, way.z)


## Whether [param thing] picked out at the last decision is still there to be shot at: a kart
## still in the room and not under spawn protection, a crate or a target still standing.
static func _still_there(thing: Variant) -> bool:
	# Taken as it is: a mark freed since it was taken is not a Node3D any more, and a typed
	# argument would be the error before the question could be asked.
	if thing == null or not is_instance_valid(thing):
		return false
	if thing is Kart:
		return (thing as Kart).is_targetable()
	if thing is Crate:
		return (thing as Crate).alive
	return not thing is Target or (thing as Target).alive


## How far off the nose a shot at something [param distance] away is still worth taking,
## GAME.md 9.1. A fixed angle says less and less about a miss the nearer the target is: a kart
## being shoved along is half a meter from the muzzle and forty degrees off the nose, and a bot
## that only fired within eight degrees would keep bumping it rather than shoot it. What the
## target is worth in angle at that distance is added, so the question asked is whether the shot
## goes through it rather than whether it leaves along the nose.
func _fire_cone(distance: float) -> float:
	var wide := asin(clampf(TARGET_HALF_WIDTH / maxf(distance, TARGET_HALF_WIDTH), 0.0, 1.0))
	return minf(FIRE_CONE + wide, FIRE_CONE_MAX)


## The nearest crate or shooting target in front of the bot, GAME.md 6.2: both pay whoever
## breaks them, and a bot with nothing else to do may as well be paid. The line of sight stops
## short of the thing itself, which would otherwise block the view of itself.
func _scenery_mark() -> Node3D:
	_best_scenery = null
	_best_scenery_distance = SCENERY_RANGE
	for crate: Crate in match_node.arena.crates:
		if crate.alive:
			_weigh_scenery(crate)
	for target: Target in match_node.arena.targets:
		if target.alive:
			_weigh_scenery(target)
	return _best_scenery


## Takes [param mark] as the scenery to shoot at, see [method _scenery_mark], when it is nearer
## than the best yet and in sight, the line stopping short of the thing itself.
func _weigh_scenery(mark: Node3D) -> void:
	var distance := kart.global_position.distance_to(mark.global_position)
	if distance >= _best_scenery_distance:
		return
	var toward := mark.global_position - kart.global_position
	if not has_line_of_sight(mark.global_position - toward.normalized() * SCENERY_CLEARANCE):
		return
	_best_scenery_distance = distance
	_best_scenery = mark


func _use_item(delta: float) -> void:
	var item := kart.held_item
	if item == null or kart.item_reveal_left > 0.0:
		_item_hold_time = 0.0
		return
	_item_hold_time += delta
	var mirror := bot_mirror()
	# A bot holds on to an item roughly as long as the players do, and only plays it cleverly
	# once they have shown they play theirs, unless its level knows how from the start.
	var use := _item_hold_time >= mirror.item_patience(ITEM_PATIENCE)
	var enemy := _nearest if _still_there(_nearest) else null
	var enemy_distance := (
		kart.global_position.distance_to(enemy.global_position) if enemy != null else INF
	)
	if mirror.items <= 0.3 and not difficulty.item_sense:
		input.use_item_pressed = use
		return
	match item.id:
		&"boost":
			use = (
				use
				or goal == &"hunt"
				or goal == &"flee"
				or (goal == &"bank" and kart.pot.value() >= bot_trait.bank_threshold)
			)
		&"shield":
			use = use or kart.pot.value() >= bot_trait.bank_threshold * 0.5 or _bullets_nearby(6.0)
		&"turret":
			use = use or enemy_distance <= 15.0
		&"oil_stain":
			use = use or goal == &"flee" or (enemy_distance <= 10.0 and _enemy_behind(enemy))
		&"bomb":
			use = use or goal == &"flee" or (enemy_distance <= 8.0 and _enemy_behind(enemy))
		&"ricochet_cannon", &"spread_cannon":
			use = use or goal == &"hunt"
		&"swivel_cannon":
			use = use or (goal == &"hunt" and _mark_visible)
		&"decoy_kart":
			use = use or goal == &"hunt" or goal == &"flee"
		&"bullet_wipe":
			use = use or _bullets_nearby(4.0)
		&"coin_magnet":
			use = use or goal == &"collect"
	input.use_item_pressed = use


## Nitro goes into a charge at a close enemy in front, or into escaping a Boosting kart.
func _burn_nitro() -> void:
	input.nitro = false
	var need := bot_mirror().nitro_threshold()
	if goal == &"flee" and kart.nitro_charge > need:
		input.nitro = true
		return
	if goal != &"hunt" or target_node == null or not is_instance_valid(target_node):
		return
	var to_enemy := target_node.global_position - kart.global_position
	to_enemy.y = 0.0
	var ahead := absf(kart.motor.forward_vector().signed_angle_to(to_enemy, Vector3.UP)) < 0.4
	# A rival about to win is rammed from further off and on less of a tank: a ram that lands
	# knocks coins out of the pot that would have won it, GAME.md 4.1. So is anybody, by bots
	# ending sudden death on their own.
	var pressing := target_node == _winner or bot_mirror().finishing()
	var reach := WINNER_RAM_REACH if pressing else 9.0
	var spare := need if pressing else minf(need + 0.2, 1.05)
	input.nitro = (
		ahead and to_enemy.length() < reach and (kart.nitro_active or kart.nitro_charge > spare)
	)


## True when the enemy is somewhere behind the kart, where a dropped item lands.
func _enemy_behind(enemy: Kart) -> bool:
	if enemy == null:
		return false
	var to_enemy := enemy.global_position - kart.global_position
	to_enemy.y = 0.0
	return to_enemy.dot(kart.motor.forward_vector()) < 0.0


## The match's reading of the players, or a neutral one when there is no match to ask.
func bot_mirror() -> BotMirror:
	return match_node.bot_mirror if match_node != null else _fallback


func _bullets_nearby(radius: float) -> bool:
	for bullet: Bullet in match_node.bullets.bullets:
		if (
			not _harmless(bullet)
			and bullet.global_position.distance_to(kart.global_position) < radius
		):
			return true
	return false
