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

const DECISION_INTERVAL := 0.1
const REPLAN_INTERVAL := 0.3
const WAYPOINT_REACHED := 1.3
## How long a bot sticks with a goal before a merely better one can take it off, GAME.md 9.1.
## Ten decisions a second with nothing holding them together makes a bot that dithers between
## two errands it is equally near; danger and a goal that has gone away still cut in at once.
const GOAL_DWELL := 1.5
## Inside this of its target the bot has arrived, and whatever it went there for is done.
const ARRIVED_RADIUS := 2.0
## How hard the wheel answers the angle to the next waypoint, and how much of that is taken
## back by how fast the nose is already coming round. Without the second one a bot holds full
## lock until it is pointed at the waypoint, by which time it is turning too fast to stop
## there, and it saws at the wheel all the way down the road.
const STEER_GAIN := 2.0
const STEER_DAMP := 0.3
## What the context has to still be offering for each errand, so a bot notices at once when the
## thing it set out for has been taken, collected or has driven off.
const GOAL_NEEDS: Dictionary[StringName, String] = {
	&"flee": "boost_enemy",
	&"jackpot": "jackpot_position",
	&"hunt": "enemy",
	&"item": "item",
	&"collect": "pickup",
	&"flush": "flush_pad",
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
## How long a bot puts up with going nowhere before backing out of it, and how long it backs
## out for. A nose flat against a wall needs no second of proof, so that case is quicker.
const STUCK_TIME := 1.2
const WALL_STUCK_TIME := 0.35
const REVERSE_TIME := 0.7
## After backing up, how long the wheel stays where it was with the power back on. Handing the
## kart straight back to the navigator points it at the target again, which is through the wall
## it just came off; this drives it out along the new heading first.
const SWING_TIME := 0.5
## Under this it counts as going nowhere.
const STUCK_SPEED := 0.6
## Standing still is not the only way to get nowhere: a kart scrubbing along a wall or grinding
## on a corner keeps a speed on the clock and still arrives nowhere. Covering less than this
## much ground in this long, while asking to drive, counts as stuck whatever the speedometer
## says.
const PROGRESS_TIME := 2.0
const PROGRESS_STEP := 2.0
## How far in front of itself a bot feels for a wall it is nosed up against.
const WALL_PROBE := 1.3
## Seconds the handbrake is held to break the rear loose, and the least time between two of
## those. The kart drifts the oversteer way now, GAME.md 4.1, where the handbrake is a flick:
## holding it through a corner only breaks the rear loose again every time the slide is
## caught, which walks the kart from one side to the other and down the road backwards.
const FLICK_TIME := 0.18
const FLICK_COOLDOWN := 1.1
## How tight a corner has to be, and how fast the kart has to be going, before a bot will
## throw it in. Below this it simply steers round.
const FLICK_SPEED := 0.6
const AIM_ERROR_INTERVAL := 0.5
const ITEM_PATIENCE := 5.0
const BULLET_HEIGHT := 0.5
## Where the last stretch of a drive begins, and the least throttle it is taken on. Flat out,
## a kart's turning circle is wider than the pad it is aiming for, so it sails past and comes
## round again forever; easing off makes the circle small enough to land on.
const APPROACH_RADIUS := 6.0
const APPROACH_THROTTLE := 0.28
## Past this angle, with the goal this close, the goal is behind the kart and reversing onto it
## beats turning around: at these distances the turning circle simply does not fit.
const REVERSE_ANGLE := 1.9
const REVERSE_RADIUS := 4.0
## How far ahead of itself a bot checks for a pit, in seconds of travel, and the throttle it
## drops to when it sees one. A second is comfortably more than the half second it takes to
## stop from top speed, so there is room to turn out rather than only to stop.
const PIT_LOOKAHEAD := 1.2
## How much room a bot leaves around a hole, over and above the cells the hole sits in. A kart
## goes down when any corner of it touches the trigger, which sits a little inside those cells,
## so the margin is the kart's half-diagonal less that inset: aiming to miss the hole itself is
## aiming to clip it with a corner.
const PIT_CLEARANCE := 0.6
## Where the look-ahead starts, in seconds of travel. Measured from a little in front of the
## nose rather than from under it: a bot parked beside a hole is not driving into it, and a
## sweep that starts where it stands would have it fleeing a hole it is nowhere near entering.
const PIT_LOOK_FROM := 0.15
const PIT_THROTTLE := 0.25
## Within this of the hole, turning alone will not do it and the brakes go on as well.
const PIT_BRAKE_DISTANCE := 6.0
## How far away a crate or a target is still worth a shot, with nothing better to fire at.
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

var _path: PackedVector3Array = []
var _path_index := 0
var _decision_left := 0.0
var _replan_left := 0.0
var _planned_target := Vector3.INF
var _dodge_left := 0.0
var _dodge_steer := 0.0
## Whether this bot reacts to each bullet it has seen, decided once so it does not change its
## mind about the same one every frame. Kept only for bullets still in the air: a match fires
## thousands, and a bot that remembered every one of them would carry the lot to the whistle.
var _dodge_rolls: Dictionary[int, bool] = {}
## Whether this bot goes after each rival one cash-out from winning, by slot, see [method
## _winning_rival], forgotten once they no longer are.
var _chases: Dictionary[int, bool] = {}
var _aim_timer := 0.0
var _aim_error := 0.0
var _aim_error_left := 0.0
var _willing_to_fire := true
## How long the current goal has been held, and which side of the path the aim is taking.
var _goal_held := 0.0
var _skip_index := -1
var _skip_ahead := false
## The heading last tick, for how fast the nose is coming round.
var _last_heading := 0.0
var _turn_rate := 0.0
var _stuck_time := 0.0
var _reverse_left := 0.0
var _swing_left := 0.0
## Which way the wheel goes while backing out, held for the whole maneuver.
var _reverse_steer := 1.0
## Where the kart was when the ground it has covered was last looked at, and how long ago.
var _progress_mark := Vector3.INF
var _progress_left := PROGRESS_TIME
## The handbrake flick that breaks the rear loose: how long this one lasts and how long until
## another is allowed.
var _flick_left := 0.0
var _flick_wait := 0.0
var _item_hold_time := 0.0
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
	if _decision_left <= 0.0:
		_decision_left = DECISION_INTERVAL
		_decide()
		_forget_spent_bullets()
	input.fire_pressed = false
	input.use_item_pressed = false
	_steer(delta)
	_dodge(delta)
	_shoot(delta)
	_use_item(delta)
	_burn_nitro()


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
			target = match_node.arena.junction_position
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
		&"flush":
			target_node = context["flush_pad"]
			target = target_node.global_position
		_:
			target = _clamp_to_arena(
				(
					match_node.arena.junction_position
					+ Vector3(rng.randf_range(-8.0, 8.0), 0.0, rng.randf_range(-5.0, 5.0)) * _span()
				)
			)
	_willing_to_fire = rng.randf() < bot_trait.fire_chance


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
	# those leaves a bot shuffling about on the pad it has just claimed waiting to be let go.
	if not _should_hold_position() and kart.global_position.distance_to(target) < ARRIVED_RADIUS:
		return true
	return _goal_held >= GOAL_DWELL


## Whether what the bot is doing now is still there to be done.
func _goal_still_on(context: Dictionary) -> bool:
	return not GOAL_NEEDS.has(goal) or context.has(GOAL_NEEDS[goal])


func _context() -> Dictionary:
	var mirror := _mirror()
	var context := {
		"item_appetite": mirror.item_appetite(),
		"bank_urgency": mirror.effort,
		"hunt_urgency": mirror.hunt_urgency(),
		"pot_value": kart.pot.value(),
		"time_left": match_node.time_left,
		# Sudden death reads as Last Call to a bot: what is in the pot is worth taking to the
		# Junction now, because there is no lap after this one.
		"last_call": match_node.in_the_finale(),
		"has_item": kart.held_item != null,
		"wounded": kart.is_wounded(),
	}
	var enemy := _hunt_target()
	if enemy != null:
		context["enemy"] = enemy
		context["enemy_distance"] = kart.global_position.distance_to(enemy.global_position)
		context["enemy_visible"] = _has_line_of_sight(enemy.global_position)
		context["enemy_pot"] = enemy.pot.value()
		context["pot_greed"] = difficulty.pot_hunting if difficulty != null else 0.0
		context["enemy_winning"] = enemy == _winning_rival()
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
		var near := _nearest_enemy()
		if near != null:
			context["near_enemy_distance"] = kart.global_position.distance_to(near.global_position)
			context["near_enemy_visible"] = _has_line_of_sight(near.global_position)
	var best_pickup: Pickup = null
	var best_score := 0.0
	var best_item: Pickup = null
	var best_item_distance := INF
	for node: Node in match_node.arena.pickups.get_children():
		var pickup := node as Pickup
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
	return context


## The Royal Flush pad worth driving to, GAME.md 3.9. A pad somebody else holds, or nobody
## does, is worth taking; the one that would complete the set is worth far more; and a pad of
## the bot's own that is about to lapse is worth going back over to renew.
func _add_flush_context(context: Dictionary) -> void:
	var pads := match_node.arena.flush_pads
	var held := 0
	for pad: FlushPad in pads:
		if pad.owner_slot == kart.slot and not pad.is_disabled():
			held += 1
	var best: FlushPad = null
	var best_score := 0.0
	var best_value := 0.0
	for pad: FlushPad in pads:
		if pad.is_disabled():
			continue
		var value := PAD_VALUE
		if pad.owner_slot == kart.slot:
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
## carrying a pot worth taking off them, and otherwise simply the nearest enemy.
func _hunt_target() -> Kart:
	var winner := _winning_rival()
	if winner != null:
		return winner
	var bounty := match_node.bounty_kart()
	if bounty != null and bounty.slot != kart.slot and bounty.is_targetable():
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
	for node: Node in get_tree().get_nodes_in_group(&"karts"):
		var other := node as Kart
		if other == null or other.slot == kart.slot or not other.is_targetable():
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
	for index: int in _chases.keys():
		if index >= match_node.slots.size() or not match_node.would_win(match_node.slots[index]):
			_chases.erase(index)
	return _nearest_other(
		func(other: Kart) -> bool:
			return (
				other.is_targetable()
				and not other.is_decoy()
				and other.slot < match_node.slots.size()
				and match_node.would_win(match_node.slots[other.slot])
				and _chases_after(other.slot)
			)
	)


## Whether this bot goes after the rival in [param index] about to win, deciding it the first time.
func _chases_after(index: int) -> bool:
	if not _chases.has(index):
		var roll := rng.randf() if rng != null else randf()
		_chases[index] = bot_trait != null and roll < bot_trait.winner_chase
	return _chases[index]


func _nearest_enemy() -> Kart:
	return _nearest_other(func(other: Kart) -> bool: return other.is_targetable())


func _nearest_boosting_enemy() -> Kart:
	return _nearest_other(func(other: Kart) -> bool: return other.alive and other.ramming)


## The closest kart that is not this one and that [param worth_it] accepts, or null.
func _nearest_other(worth_it: Callable) -> Kart:
	var best: Kart = null
	var best_distance := INF
	for node: Node in get_tree().get_nodes_in_group(&"karts"):
		var other := node as Kart
		if other == null or other.slot == kart.slot or not worth_it.call(other):
			continue
		var distance := kart.global_position.distance_to(other.global_position)
		if distance < best_distance:
			best_distance = distance
			best = other
	return best


func _has_line_of_sight(point: Vector3) -> bool:
	var space := kart.get_world_3d().direct_space_state
	var from := kart.global_position + Vector3(0.0, BULLET_HEIGHT, 0.0)
	var to := Vector3(point.x, BULLET_HEIGHT, point.z)
	var ray := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	return space.intersect_ray(ray).is_empty()


## How fast the nose is coming round, from the heading itself rather than from what was asked
## for: a kart in a slide, being shoved or up against something is not turning at the rate its
## wheel says it is.
func _step_turn_rate(delta: float) -> void:
	if delta <= 0.0:
		return
	var turned := wrapf(kart.motor.heading - _last_heading, -PI, PI)
	_last_heading = kart.motor.heading
	_turn_rate = lerpf(_turn_rate, turned / delta, clampf(delta * 12.0, 0.0, 1.0))


func _clamp_to_arena(point: Vector3) -> Vector3:
	var half := match_node.arena.world_size() * 0.5 - Vector2.ONE * 2.0
	return Vector3(clampf(point.x, -half.x, half.x), 0.0, clampf(point.z, -half.y, half.y))


func _steer(delta: float) -> void:
	if target_node != null and is_instance_valid(target_node):
		target = target_node.global_position
		if goal == &"hunt":
			target = _lead_point(target_node)
	_replan_left -= delta
	if _replan_left <= 0.0 or _planned_target.distance_to(target) > 2.0:
		_replan_left = REPLAN_INTERVAL
		_planned_target = target
		_path = match_node.nav.path(kart.global_position, target)
		_path_index = 0
		_skip_index = -1
	var waypoint := _current_waypoint()
	var to_waypoint := waypoint - kart.global_position
	to_waypoint.y = 0.0
	var forward := kart.motor.forward_vector()
	var angle := (
		forward.signed_angle_to(to_waypoint, Vector3.UP)
		if not to_waypoint.is_zero_approx()
		else 0.0
	)
	var mirror := _mirror()
	# Steer where the kart is going, not where its nose points. In a slide those are different,
	# and aiming the nose at the corner sends the kart wide of it; aiming the travel at it makes
	# the bot wind on opposite lock exactly when a driver would.
	var aim := angle
	if kart.motor.drifting:
		aim += kart.motor.slip_angle()
	# Wind off as the nose comes round rather than holding full lock until it is pointed at the
	# waypoint: by then the kart is turning too fast to stop there and it saws at the wheel all
	# the way down the road. Not in a slide, where the nose coming round is the whole point and
	# the wheel is already answering the slip angle.
	_step_turn_rate(delta)
	var settle := 0.0 if kart.motor.drifting else _turn_rate * STEER_DAMP
	input.steer = -clampf(aim * STEER_GAIN - settle, -1.0, 1.0)
	# Bots that are ahead lift off; being behind cannot push them past their own top speed.
	input.throttle = difficulty.top_speed_fraction * minf(mirror.effort, 1.0)
	input.brake = 0.0
	input.handbrake = _step_flick(delta, angle, mirror)
	if absf(angle) > 1.7:
		input.throttle = 0.35
	_close_in(forward)
	_avoid_pit()
	if _should_hold_position():
		input.throttle = 0.0
		input.brake = 1.0 if kart.motor.forward_speed > 0.5 else 0.0
		input.steer = 0.0
	_step_stuck(delta)


## Whether to have the handbrake in this tick, GAME.md 9.1. A tight corner taken at speed is
## worth throwing the kart into: the handbrake goes in for a flick, the rear comes loose, and
## from there the slide is driven on the wheel like anyone else drives one. Holding it would
## keep breaking the rear loose over and over, and a bot that has already got the kart sideways
## has nothing to gain by asking for more of it.
func _step_flick(delta: float, angle: float, mirror: BotMirror) -> bool:
	_flick_wait = maxf(_flick_wait - delta, 0.0)
	if _flick_left > 0.0:
		_flick_left -= delta
		return true
	if kart.motor.drifting:
		return false
	var tight := absf(angle) > mirror.drift_angle()
	if not tight or kart.motor.speed_fraction() < FLICK_SPEED or _flick_wait > 0.0:
		return false
	_flick_left = FLICK_TIME
	_flick_wait = FLICK_COOLDOWN
	return true


## The last stretch onto the goal itself, GAME.md 9.1. Waypoints get a bot to the right part of
## the arena; what loses it the Jackpot is arriving at full tilt, turning wider than the pad and
## going round and round it. Inside [constant APPROACH_RADIUS] it eases off, so the circle it
## can turn in shrinks to something that fits, and it stops drifting. With the goal behind it
## and close, it backs onto it instead: no turning circle fits at that range.
func _close_in(forward: Vector3) -> void:
	if _path_index < _path.size() - 1:
		return
	var to_goal := target - kart.global_position
	to_goal.y = 0.0
	var distance := to_goal.length()
	if distance >= APPROACH_RADIUS or to_goal.is_zero_approx():
		return
	input.handbrake = false
	input.throttle *= clampf(distance / APPROACH_RADIUS, APPROACH_THROTTLE, 1.0)
	var angle := forward.signed_angle_to(to_goal, Vector3.UP)
	if absf(angle) > REVERSE_ANGLE and distance < REVERSE_RADIUS:
		input.throttle = 0.0
		input.brake = 1.0
		# Steering is mirrored in reverse, so the sign flips with it.
		input.steer = clampf(angle * 2.0, -1.0, 1.0)


## The last word on steering, GAME.md 9.1: whatever a bot was doing, it does not drive into a
## pit. Paths already go around them, but a bot cutting a corner, sliding out of a drift or
## chasing a kart across one would go in regardless, so where it is headed is checked against
## the hole and it turns out of it.
func _avoid_pit() -> void:
	var from := kart.global_position + kart.motor.velocity * PIT_LOOK_FROM
	var ahead := kart.global_position + kart.motor.velocity * PIT_LOOKAHEAD
	if not match_node.nav.crosses_pit(from, ahead, PIT_CLEARANCE):
		return
	var forward := kart.motor.forward_vector()
	var away := kart.global_position - match_node.nav.first_pit_center(kart.global_position, ahead)
	away.y = 0.0
	# Sideways rather than straight back: at speed a kart cannot turn around, but it can go
	# around, so it is steered along the hole's edge and off it.
	var escape := away - forward * away.dot(forward)
	if escape.length() < 0.05:
		# Dead in line with the middle of it: pick a side rather than dithering between two.
		escape = forward.cross(Vector3.UP)
	var angle := forward.signed_angle_to(escape, Vector3.UP)
	input.steer = -clampf(angle * 2.0, -1.0, 1.0)
	input.throttle = PIT_THROTTLE
	input.handbrake = false
	input.nitro = false
	if away.length() < PIT_BRAKE_DISTANCE:
		input.throttle = 0.0
		input.brake = 1.0


## When hunting, aim where the enemy will be when the bullet arrives.
func _lead_point(enemy: Node3D) -> Vector3:
	var enemy_kart := enemy as Kart
	if enemy_kart == null:
		return enemy.global_position
	var distance := kart.global_position.distance_to(enemy.global_position)
	var flight := distance / kart.cannon.current_stats().bullet_speed
	return enemy.global_position + enemy_kart.motor.velocity * flight


func _current_waypoint() -> Vector3:
	while (
		_path_index < _path.size()
		and kart.global_position.distance_to(_path[_path_index]) < WAYPOINT_REACHED
	):
		_path_index += 1
	if _path_index < _path.size():
		# Skip a waypoint when the one after it is directly reachable. A pit is not a wall: it
		# stops nothing and blocks no raycast, so the short cut has to be checked against it too.
		# Decided once per waypoint and then left alone: a ray that grazes a corner answers
		# differently from one frame to the next, and each answer is a different way to aim.
		if _skip_index != _path_index:
			_skip_index = _path_index
			_skip_ahead = (
				_path_index + 1 < _path.size()
				and _has_line_of_sight(_path[_path_index + 1])
				and not match_node.nav.crosses_pit(kart.global_position, _path[_path_index + 1])
			)
		if _skip_ahead and _path_index + 1 < _path.size():
			return _path[_path_index + 1]
		return _path[_path_index]
	return target


## Banking and collecting the Jackpot mean standing still inside the zone.
func _should_hold_position() -> bool:
	if goal == &"bank":
		return (
			kart.global_position.distance_to(match_node.arena.junction_position)
			< match_node.arena.junction_radius - 0.9
		)
	if goal == &"jackpot":
		return kart.global_position.distance_to(target) < 0.8
	return false


## Getting a bot off a wall, GAME.md 9.1. Driving at something solid pins the kart there, and
## steering toward a target on the far side of it only holds it harder, so a bot that is going
## nowhere backs up with the wheel over, swings its nose clear and drives out on the heading it
## ends up with before the navigator gets the kart back. The turn is picked once and held for
## the whole maneuver, and it alternates, so a bot that backs into the same corner twice tries
## the other way out rather than rocking on the spot.
func _step_stuck(delta: float) -> void:
	if _reverse_left > 0.0:
		_reverse_left -= delta
		_back_out()
		if _reverse_left <= 0.0:
			_swing_left = SWING_TIME
		return
	if _swing_left > 0.0:
		_swing_left -= delta
		_swing_out()
		return
	if input.throttle <= 0.0:
		_stuck_time = 0.0
		_forget_progress()
		return
	if kart.motor.speed() < STUCK_SPEED:
		_stuck_time += delta
	else:
		_stuck_time = 0.0
	var patience := WALL_STUCK_TIME if _nose_on_a_wall() else STUCK_TIME
	if _stuck_time >= patience or _getting_nowhere(delta):
		_begin_backing_out()


## Starts the maneuver on the tick it is decided, not the one after: the frame it would wait
## is a frame it spends pushing at the wall.
func _begin_backing_out() -> void:
	_stuck_time = 0.0
	_forget_progress()
	_reverse_left = REVERSE_TIME
	_reverse_steer = -_reverse_steer
	_back_out()


## Whether the kart has covered any ground lately. A kart wedged on a corner can keep a speed
## on the clock while going nowhere at all, so what is measured is the ground covered rather
## than the speedometer.
func _getting_nowhere(delta: float) -> bool:
	if _progress_mark == Vector3.INF:
		_forget_progress()
		return false
	_progress_left -= delta
	if _progress_left > 0.0:
		return false
	var covered := kart.global_position.distance_to(_progress_mark)
	_forget_progress()
	return covered < PROGRESS_STEP


## Starts the ground-covered window again from where the kart is now.
func _forget_progress() -> void:
	_progress_mark = kart.global_position
	_progress_left = PROGRESS_TIME


## Backing out: off the gas, on the brakes, wheel held over.
func _back_out() -> void:
	input.throttle = 0.0
	input.brake = 1.0
	input.steer = _reverse_steer
	input.handbrake = false
	input.nitro = false


## Driving out of it: back on the power with the wheel still over, so the kart leaves along the
## heading it backed into rather than turning straight into what it was stuck on.
func _swing_out() -> void:
	input.throttle = difficulty.top_speed_fraction
	input.brake = 0.0
	input.steer = _reverse_steer
	input.handbrake = false
	input.nitro = false


## Whether there is something solid right in front of the nose.
func _nose_on_a_wall() -> bool:
	return not _has_line_of_sight(kart.global_position + kart.motor.forward_vector() * WALL_PROBE)


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


func _dodge(delta: float) -> void:
	if _dodge_left > 0.0:
		_dodge_left -= delta
		input.steer = _dodge_steer
		input.handbrake = false
		return
	for bullet: Bullet in match_node.bullets.bullets:
		if bullet.owner_slot == kart.slot or bullet.is_dead():
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
		var spread := deg_to_rad(difficulty.aim_error_deg / _mirror().effort)
		_aim_error = rng.randf_range(-spread, spread)
	input.fire = false
	var mark: Node3D = _hunt_target()
	# A bot that holds its fire this life still shoots at a rival about to win.
	var willing := _willing_to_fire or (mark != null and mark == _winning_rival())
	if not willing or bot_trait.rams:
		_aim_timer = 0.0
		return
	if mark == null or not _in_reach(mark.global_position, HUNT_RANGE):
		# Nobody worth shooting: break something open instead.
		mark = _scenery_mark()
	if mark == null:
		_aim_timer = 0.0
		return
	var to_aim := _lead_point(mark) - kart.global_position
	to_aim.y = 0.0
	var angle := kart.motor.forward_vector().signed_angle_to(to_aim, Vector3.UP) + _aim_error
	if absf(angle) > _fire_cone(to_aim.length()):
		_aim_timer = 0.0
		return
	_aim_timer += delta
	input.fire = _aim_timer >= difficulty.reaction_delay


## How far off the nose a shot at something [param distance] away is still worth taking,
## GAME.md 9.1. A fixed angle says less and less about a miss the nearer the target is: a kart
## being shoved along is half a meter from the muzzle and forty degrees off the nose, and a bot
## that only fired within eight degrees would keep bumping it rather than shoot it. What the
## target is worth in angle at that distance is added, so the question asked is whether the shot
## goes through it rather than whether it leaves along the nose.
func _fire_cone(distance: float) -> float:
	var wide := asin(clampf(TARGET_HALF_WIDTH / maxf(distance, TARGET_HALF_WIDTH), 0.0, 1.0))
	return minf(FIRE_CONE + wide, FIRE_CONE_MAX)


## Whether a point is close enough to shoot at and not behind a wall.
func _in_reach(point: Vector3, reach: float) -> bool:
	return kart.global_position.distance_to(point) <= reach and _has_line_of_sight(point)


## The nearest crate or shooting target in front of the bot, GAME.md 6.2: both pay whoever
## breaks them, and a bot with nothing else to do may as well be paid. The line of sight stops
## short of the thing itself, which would otherwise block the view of itself.
func _scenery_mark() -> Node3D:
	var best: Node3D = null
	var best_distance := SCENERY_RANGE
	var marks: Array[Node3D] = []
	for crate: Crate in match_node.arena.crates:
		if crate.alive:
			marks.append(crate)
	for target: Target in match_node.arena.targets:
		if target.alive:
			marks.append(target)
	for mark: Node3D in marks:
		var distance := kart.global_position.distance_to(mark.global_position)
		if distance >= best_distance:
			continue
		var toward := mark.global_position - kart.global_position
		if not _has_line_of_sight(mark.global_position - toward.normalized() * SCENERY_CLEARANCE):
			continue
		best_distance = distance
		best = mark
	return best


func _use_item(delta: float) -> void:
	var item := kart.held_item
	if item == null or kart.item_reveal_left > 0.0:
		_item_hold_time = 0.0
		return
	_item_hold_time += delta
	var mirror := _mirror()
	# A bot holds on to an item roughly as long as the players do, and only plays it cleverly
	# once they have shown they play theirs.
	var use := _item_hold_time >= mirror.item_patience(ITEM_PATIENCE)
	var enemy := _nearest_enemy()
	var enemy_distance := (
		kart.global_position.distance_to(enemy.global_position) if enemy != null else INF
	)
	if mirror.items <= 0.3:
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
		&"ricochet_cannon":
			use = use or goal == &"hunt"
		&"coin_magnet":
			use = use or goal == &"collect"
	input.use_item_pressed = use


## Nitro goes into a charge at a close enemy in front, or into escaping a Boosting kart.
func _burn_nitro() -> void:
	input.nitro = false
	var need := _mirror().nitro_threshold()
	if goal == &"flee" and kart.nitro_charge > need:
		input.nitro = true
		return
	if goal != &"hunt" or target_node == null or not is_instance_valid(target_node):
		return
	var to_enemy := target_node.global_position - kart.global_position
	to_enemy.y = 0.0
	var ahead := absf(kart.motor.forward_vector().signed_angle_to(to_enemy, Vector3.UP)) < 0.4
	# A rival about to win is rammed from further off and on less of a tank: a ram that lands
	# knocks coins out of the pot that would have won it, GAME.md 4.1.
	var winning := target_node == _winning_rival()
	var reach := WINNER_RAM_REACH if winning else 9.0
	var spare := need if winning else minf(need + 0.2, 1.05)
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
func _mirror() -> BotMirror:
	return match_node.bot_mirror if match_node != null else _fallback


func _bullets_nearby(radius: float) -> bool:
	for bullet: Bullet in match_node.bullets.bullets:
		if (
			bullet.owner_slot != kart.slot
			and bullet.global_position.distance_to(kart.global_position) < radius
		):
			return true
	return false
