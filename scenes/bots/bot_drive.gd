class_name BotDrive
extends RefCounted
## Driving a bot to wherever its [BotBrain] wants to be, GAME.md 9.1: a grid path to the goal,
## followed by aiming at the waypoint after next where the kart can drive straight to it; the
## handbrake flicked into a corner tight enough for one; easing onto the goal, or backing onto one
## close behind it; and holding still on one it is waiting on. Stepped by its brain every tick,
## into the brain's input, before the brain has its say about dodging, shooting and items, and
## before [BotPits] has the last word.

const REPLAN_INTERVAL := 0.3
const WAYPOINT_REACHED := 1.3
## How hard the wheel answers the angle to the point it is aiming at, and how much of that is taken
## back by how fast the nose is already coming round. Without the second one a bot holds full lock
## until it is pointed at the point, by which time it is turning too fast to stop there, and it
## saws at the wheel all the way down the road.
const STEER_GAIN := 2.0
const STEER_DAMP := 0.3
## Seconds the handbrake is held to break the rear loose, and the least time between two of those.
## The kart drifts the oversteer way, GAME.md 4.1, where the handbrake is a flick: holding it
## through a corner only breaks the rear loose again every time the slide is caught, which walks
## the kart from one side to the other and down the road backwards.
const FLICK_TIME := 0.18
const FLICK_COOLDOWN := 1.1
## How fast the kart has to be going, as a share of top speed, before a bot throws it into a tight
## corner. Below this it simply steers round.
const FLICK_SPEED := 0.6
## Where the last stretch onto a goal it stops on begins, and the least throttle it is taken on.
## Flat out, a kart's turning circle is wider than the pad it is aiming for, so it sails past and
## comes round again forever; easing off makes the circle small enough to land on.
const APPROACH_RADIUS := 6.0
const APPROACH_THROTTLE := 0.28
## Past this angle, with the goal this close, the goal is behind the kart and reversing onto it
## beats turning around: at these distances the turning circle simply does not fit.
const REVERSE_ANGLE := 1.9
const REVERSE_RADIUS := 4.0
## A kart it is hunting and cannot ram to death, see [method _holds_off]: inside the first it stops
## closing in and turns to keep its cannon on the kart, and inside the second, with the kart in
## front of it, it backs away.
const STANDOFF := 4.5
const BACK_OFF := 2.5
## How far off its nose, in radians, the kart may be for the bot to back straight away from it.
const BACK_ANGLE := 0.8
## Half the width of the swathe a short cut to the waypoint after next has to be clear for: the
## kart's half width and a little, so a run that grazes a wall's corner is not one the kart fits
## along, see [method ArenaNav.clear_run].
const SWATHE := 0.65
## Past this angle the point aimed at is behind the kart, and it is turned round to on this much
## throttle.
const TURN_ROUND := 1.7
const TURN_THROTTLE := 0.35

var brain: BotBrain

var _path: PackedVector3Array = []
var _path_index := 0
var _replan_left := 0.0
var _planned_target := Vector3.INF
## Which waypoint the short cut was last decided for, and the waypoint aimed at: decided once per
## waypoint and then left alone, since a line that grazes a corner answers differently from one
## frame to the next, and each answer is a different way to aim.
var _aim_for := -1
var _aim_index := 0
## The heading last tick, for how fast the nose is coming round.
var _last_heading := 0.0
var _turn_rate := 0.0
## The handbrake flick that breaks the rear loose: how long this one lasts and how long until
## another is allowed.
var _flick_left := 0.0
var _flick_wait := 0.0


func _init(owner: BotBrain) -> void:
	brain = owner


## One tick's driving toward the brain's target, into its input, see the class.
func step(delta: float) -> void:
	var kart := brain.kart
	var input := brain.input
	_replan_left -= delta
	if _replan_left <= 0.0 or _planned_target.distance_to(brain.target) > 2.0:
		_replan_left = REPLAN_INTERVAL
		_planned_target = brain.target
		_path = brain.match_node.nav.path(kart.global_position, brain.target)
		_path_index = 0
		_aim_for = -1
	var aim_at := _aim_point()
	var to_aim := aim_at - kart.global_position
	to_aim.y = 0.0
	var forward := kart.motor.forward_vector()
	var angle := 0.0 if to_aim.is_zero_approx() else forward.signed_angle_to(to_aim, Vector3.UP)
	var mirror := brain.bot_mirror()
	# Steer where the kart is going, not where its nose points. In a slide those are different,
	# and aiming the nose at the corner sends the kart wide of it; aiming the travel at it makes
	# the bot wind on opposite lock exactly when a driver would.
	var aim := angle
	if kart.motor.drifting:
		aim += kart.motor.slip_angle()
	# Wind off as the nose comes round rather than holding full lock until it is pointed at the
	# point: by then the kart is turning too fast to stop there and it saws at the wheel all the
	# way down the road. Not in a slide, where the nose coming round is the whole point and the
	# wheel is already answering the slip angle.
	_step_turn_rate(delta)
	var settle := 0.0 if kart.motor.drifting else _turn_rate * STEER_DAMP
	input.steer = -clampf(aim * STEER_GAIN - settle, -1.0, 1.0)
	input.handbrake = _step_flick(delta, angle, mirror)
	# Bots that are ahead lift off; being behind cannot push them past their own top speed.
	input.throttle = brain.difficulty.top_speed_fraction * minf(mirror.effort, 1.0)
	input.brake = 0.0
	if absf(angle) > TURN_ROUND:
		input.throttle = TURN_THROTTLE
	_close_in(forward)
	if brain.goal == &"hunt":
		_hold_off(forward)
	if brain.holding_position():
		input.throttle = 0.0
		input.brake = 1.0 if kart.motor.forward_speed > 0.5 else 0.0
		input.steer = 0.0
	brain.stuck.step(delta)


## The point of the path to aim at: the waypoint after next when the kart can drive straight to
## it without a wall, a crate or a hole in the way of any of its width, see [method
## ArenaNav.clear_run], else the next one, and the target itself past the end of the path. The
## short cut used to be a ray along the middle and a check of the line against the holes: two
## questions where the grid can answer both at once, for the whole kart, and without the physics.
func _aim_point() -> Vector3:
	var here := brain.kart.global_position
	while _path_index < _path.size() and here.distance_to(_path[_path_index]) < WAYPOINT_REACHED:
		_path_index += 1
	if _path_index >= _path.size():
		return brain.target
	if _aim_for != _path_index:
		_aim_for = _path_index
		_aim_index = _path_index
		var next := _path_index + 1
		if next < _path.size() and brain.match_node.nav.clear_run(here, _path[next], SWATHE):
			_aim_index = next
	return _path[_aim_index]


## How fast the nose is coming round, from the heading itself rather than from what was asked
## for: a kart in a slide, being shoved or up against something is not turning at the rate its
## wheel says it is.
func _step_turn_rate(delta: float) -> void:
	if delta <= 0.0:
		return
	var heading := brain.kart.motor.heading
	var turned := wrapf(heading - _last_heading, -PI, PI)
	_last_heading = heading
	_turn_rate = lerpf(_turn_rate, turned / delta, clampf(delta * 12.0, 0.0, 1.0))


## How fast the nose is coming round, in radians a second, see [method _step_turn_rate].
func turn_rate() -> float:
	return _turn_rate


## Whether to have the handbrake in this tick, GAME.md 9.1. A tight corner taken at speed is
## worth throwing the kart into: the handbrake goes in for a flick, the rear comes loose, and
## from there the slide is driven on the wheel like anyone else drives one. Holding it would
## keep breaking the rear loose over and over, and a bot that has already got the kart sideways
## has nothing to gain by asking for more of it.
func _step_flick(delta: float, angle: float, mirror: BotMirror) -> bool:
	var motor := brain.kart.motor
	_flick_wait = maxf(_flick_wait - delta, 0.0)
	if _flick_left > 0.0:
		_flick_left -= delta
		return true
	if motor.drifting:
		return false
	var tight := absf(angle) > mirror.drift_angle()
	if not tight or motor.speed_fraction() < FLICK_SPEED or _flick_wait > 0.0:
		return false
	_flick_left = FLICK_TIME
	_flick_wait = FLICK_COOLDOWN
	return true


## Holding off a kart it is hunting and cannot ram to death, GAME.md 9.1, rather than driving into
## it: two bots that did bumped and went round each other for as long as it took either to land a
## shot, since a bump hurts nobody. Inside [constant STANDOFF], in sight of it, it stops and turns
## on the spot to keep its cannon on the kart, and inside [constant BACK_OFF], with the kart in
## front, backs straight away from it. A kart with nitro or a Boost on goes on in for the ram.
func _hold_off(forward: Vector3) -> void:
	var kart := brain.kart
	# Asked before it is cast: a kart freed since it was picked is the error otherwise.
	var thing: Variant = brain.target_node
	if thing == null or not is_instance_valid(thing) or not thing is Kart or kart.ram_kills():
		return
	var quarry: Kart = thing
	var to_quarry := quarry.global_position - kart.global_position
	to_quarry.y = 0.0
	var distance := to_quarry.length()
	if distance >= STANDOFF or not brain.has_line_of_sight(quarry.global_position):
		return
	var angle := forward.signed_angle_to(to_quarry, Vector3.UP)
	var input := brain.input
	input.throttle = 0.0
	input.handbrake = false
	input.brake = 1.0 if kart.motor.forward_speed > 1.0 else 0.0
	input.steer = -clampf(angle * STEER_GAIN, -1.0, 1.0)
	if distance < BACK_OFF and absf(angle) < BACK_ANGLE:
		input.brake = 1.0
		input.steer = 0.0


## The last stretch onto the goal itself, GAME.md 9.1. Waypoints get a bot to the right part of
## the arena; what loses it the Jackpot is arriving at full tilt, turning wider than the pad and
## going round and round it. Inside [constant APPROACH_RADIUS] it eases off, so the circle it can
## turn in shrinks to something that fits, and it stops drifting. With the goal behind it and
## close, it backs onto it instead: no turning circle fits at that range. Not onto a kart it is
## after, though: its cannon points the other way, and it turns round to it.
func _close_in(forward: Vector3) -> void:
	if _path_index < _path.size() - 1:
		return
	var input := brain.input
	var to_goal := brain.target - brain.kart.global_position
	to_goal.y = 0.0
	var distance := to_goal.length()
	if distance >= APPROACH_RADIUS or to_goal.is_zero_approx():
		return
	input.handbrake = false
	input.throttle *= clampf(distance / APPROACH_RADIUS, APPROACH_THROTTLE, 1.0)
	var angle := forward.signed_angle_to(to_goal, Vector3.UP)
	if absf(angle) > REVERSE_ANGLE and distance < REVERSE_RADIUS and brain.goal != &"hunt":
		input.throttle = 0.0
		input.brake = 1.0
		input.handbrake = false
		# Steering is mirrored in reverse, so the sign flips with it.
		input.steer = clampf(angle * 2.0, -1.0, 1.0)
