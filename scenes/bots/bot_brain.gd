class_name BotBrain
extends Node
## The utility AI from GAME.md 9.1. Every tenth of a second it picks a goal from its trait's
## weights and the situation; every tick it follows a grid path toward the goal, dodges bullets
## it can see coming, fires when an enemy is in front of the cannon after its reaction delay, and
## uses its item when the moment fits. Writes into a [BotInput] the kart reads.
##
## How keenly it does any of that is set by the [BotMirror] on the match: the bots play at
## the pitch the players set, with their own trait on top.

const DECISION_INTERVAL := 0.1
const REPLAN_INTERVAL := 0.3
const WAYPOINT_REACHED := 1.3
const HUNT_RANGE := 18.0
const FIRE_CONE := 0.14
const DODGE_RANGE := 8.0
const DODGE_HORIZON := 1.0
const DODGE_DISTANCE := 1.2
const DODGE_TIME := 0.35
const STUCK_TIME := 1.2
const REVERSE_TIME := 0.7
const AIM_ERROR_INTERVAL := 0.5
const ITEM_PATIENCE := 5.0
const BULLET_HEIGHT := 0.5

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
var _dodge_rolls: Dictionary[int, bool] = {}
var _aim_timer := 0.0
var _aim_error := 0.0
var _aim_error_left := 0.0
var _willing_to_fire := true
var _stuck_time := 0.0
var _reverse_left := 0.0
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
	if kart == null or not kart.alive or kart.frozen or kart.falling or not match_node.is_running():
		input.clear()
		return
	_decision_left -= delta
	if _decision_left <= 0.0:
		_decision_left = DECISION_INTERVAL
		_decide()
	input.fire_pressed = false
	input.use_item_pressed = false
	_steer(delta)
	_dodge(delta)
	_shoot(delta)
	_use_item(delta)
	_burn_nitro()


## Picks a goal from the situation. Pure, so it can be tested with a plain dictionary.
static func choose_goal(context: Dictionary, personality: BotTrait) -> StringName:
	if float(context.get("boost_enemy_distance", INF)) <= personality.flee_distance:
		return &"flee"
	var pot := int(context.get("pot_value", 0))
	# A bot that is behind settles for a smaller pot; one that is ahead can afford to hoard.
	var threshold := roundi(personality.bank_threshold / float(context.get("bank_urgency", 1.0)))
	if bool(context.get("last_call", false)):
		threshold = personality.last_call_bank_threshold
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
	if enemy_distance <= HUNT_RANGE and bool(context.get("enemy_visible", false)):
		hunt = personality.hunt_weight * (1.0 - enemy_distance / HUNT_RANGE)
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
	if hunt > 0.0 and hunt >= collect and hunt >= item:
		return &"hunt"
	if item > 0.0 and item > collect:
		return &"item"
	if collect > 0.0:
		return &"collect"
	return &"wander"


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
	goal = choose_goal(context, bot_trait)
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
		_:
			target = _clamp_to_arena(
				(
					match_node.arena.junction_position
					+ Vector3(rng.randf_range(-8.0, 8.0), 0.0, rng.randf_range(-5.0, 5.0))
				)
			)
	_willing_to_fire = rng.randf() < bot_trait.fire_chance


func _context() -> Dictionary:
	var mirror := _mirror()
	var context := {
		"item_appetite": mirror.item_appetite(),
		"bank_urgency": mirror.effort,
		"pot_value": kart.pot.value(),
		"time_left": match_node.time_left,
		"last_call": match_node.state == Match.State.LAST_CALL,
		"has_item": kart.held_item != null,
	}
	var enemy := _nearest_enemy()
	if enemy != null:
		context["enemy"] = enemy
		context["enemy_distance"] = kart.global_position.distance_to(enemy.global_position)
		context["enemy_visible"] = _has_line_of_sight(enemy.global_position)
	var threat := _nearest_boosting_enemy()
	if threat != null:
		context["boost_enemy"] = threat
		context["boost_enemy_distance"] = kart.global_position.distance_to(threat.global_position)
	for zone: JackpotZone in match_node.arena.jackpot_zones:
		if zone.active:
			context["jackpot_chips"] = zone.whole_chips()
			context["jackpot_contested"] = zone.occupant_count(kart) > 0
			context["jackpot_position"] = zone.global_position
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
	return context


func _pickup_value(pickup: Pickup) -> float:
	var chip := pickup as Chip
	if chip != null:
		return float(chip.value) * maxf(kart.pot.mult, 1.0)
	if pickup is MultDie:
		return 3.0 * maxf(float(kart.pot.coins), 2.0)
	if pickup is FloorJoker:
		return 6.0
	return 1.0


func _nearest_enemy() -> Kart:
	var best: Kart = null
	var best_distance := INF
	for node: Node in get_tree().get_nodes_in_group(&"karts"):
		var other := node as Kart
		if other == null or other.slot == kart.slot or not other.is_targetable():
			continue
		var distance := kart.global_position.distance_to(other.global_position)
		if distance < best_distance:
			best_distance = distance
			best = other
	return best


func _nearest_boosting_enemy() -> Kart:
	var best: Kart = null
	var best_distance := INF
	for node: Node in get_tree().get_nodes_in_group(&"karts"):
		var other := node as Kart
		if other == null or other.slot == kart.slot or not other.alive or not other.ramming:
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
	input.steer = -clampf(angle * 2.0, -1.0, 1.0)
	# Bots that are ahead lift off; being behind cannot push them past their own top speed.
	input.throttle = difficulty.top_speed_fraction * minf(mirror.effort, 1.0)
	input.brake = 0.0
	input.handbrake = (absf(angle) > mirror.drift_angle() and kart.motor.speed_fraction() > 0.6)
	if absf(angle) > 1.7:
		input.throttle = 0.35
	if _should_hold_position():
		input.throttle = 0.0
		input.brake = 1.0 if kart.motor.forward_speed > 0.5 else 0.0
		input.steer = 0.0
	_step_stuck(delta)


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
		# Skip a waypoint when the one after it is directly reachable.
		if _path_index + 1 < _path.size() and _has_line_of_sight(_path[_path_index + 1]):
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


func _step_stuck(delta: float) -> void:
	if _reverse_left > 0.0:
		_reverse_left -= delta
		input.throttle = 0.0
		input.brake = 1.0
		input.steer = -input.steer
		input.handbrake = false
		return
	if input.throttle > 0.0 and kart.motor.speed() < 0.5:
		_stuck_time += delta
		if _stuck_time >= STUCK_TIME:
			_stuck_time = 0.0
			_reverse_left = REVERSE_TIME
	else:
		_stuck_time = 0.0


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
	if not _willing_to_fire or bot_trait.rams:
		_aim_timer = 0.0
		return
	var enemy := _nearest_enemy()
	if enemy == null:
		_aim_timer = 0.0
		return
	var distance := kart.global_position.distance_to(enemy.global_position)
	if distance > HUNT_RANGE or not _has_line_of_sight(enemy.global_position):
		_aim_timer = 0.0
		return
	var to_aim := _lead_point(enemy) - kart.global_position
	to_aim.y = 0.0
	var angle := kart.motor.forward_vector().signed_angle_to(to_aim, Vector3.UP) + _aim_error
	if absf(angle) > FIRE_CONE:
		_aim_timer = 0.0
		return
	_aim_timer += delta
	input.fire = _aim_timer >= difficulty.reaction_delay


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
	input.nitro = (
		ahead
		and to_enemy.length() < 9.0
		and (kart.nitro_active or kart.nitro_charge > minf(need + 0.2, 1.05))
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
