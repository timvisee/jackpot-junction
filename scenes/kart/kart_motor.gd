class_name KartMotor
extends RefCounted
## The arcade handling model from GAME.md 4.1, free of scene nodes so it can be unit tested.
##
## The kart has a heading and a direction of travel that are separate. Every tick the speed
## follows throttle and brake, the heading follows steering, and the direction of travel turns
## toward the heading at a grip rate. The steady slip angle is about the yaw rate divided by the
## grip: a few degrees while driving. A drift, started by a flick of the handbrake, lets the rear
## step out and come round on its own, the wheel asking for the angle it hangs at, see
## [method _step_slide].

## Everything the motor carries from one tick to the next, GAME.md 10.3. A client replaying its
## own ticks after the host corrects it has to start from the motor the host had, not from a
## position with a fresh motor behind it: a kart mid-drift, mid-boost or mid-spin is most of
## what it is about to do. Kept as one list so a field added to the motor and forgotten here
## shows up as a kart that replays differently rather than as a silent drift apart.
const STATE_FIELDS: Array[StringName] = [
	&"heading",
	&"velocity",
	&"forward_speed",
	&"steer",
	&"drifting",
	&"drift_amount",
	&"drift_time",
	&"slide_rate",
	&"boost_time_left",
	&"turbo_time_left",
	&"spin_time_left",
	&"speed_bonus",
	&"steer_multiplier",
	&"nitro_bonus",
	&"_kick_remaining",
	&"_drift_direction",
	&"_spin_direction",
]

var stats: KartStats
## Yaw in radians about +Y. Forward is -Z rotated by the heading, like a Node3D.
var heading := 0.0
## World-space velocity on the XZ plane.
var velocity := Vector3.ZERO
## Signed speed: positive when traveling roughly nose first, negative in reverse.
var forward_speed := 0.0
## The steering actually applied this tick: the input shaped by the stick curve and smoothed.
var steer := 0.0
var drifting := false
## How far into the slide the kart is, 0 gripping and 1 fully sideways. The flag above says
## whether a drift is being asked for; this says how much of one has actually arrived.
var drift_amount := 0.0
var drift_time := 0.0
## How many drifts this motor has paid the exit boost for, so the kart can tell one was just paid.
var boosts_paid := 0
## How fast the rear is coming round on its own in a drift, in radians a second, signed like the
## steering: positive swings the nose to the right.
var slide_rate := 0.0
var boost_time_left := 0.0
## Seconds of held throttle and raised speed limit left after a turbo pad, GAME.md 6.2.
var turbo_time_left := 0.0
## Seconds of spin-out left after the tires let go on an oil stain.
var spin_time_left := 0.0
## Multipliers set by power-ups: Boost raises the speed bonus and lowers the steering.
var speed_bonus := 1.0
var steer_multiplier := 1.0
## Speed multiplier while the kart burns nitro, 1 when it does not.
var nitro_bonus := 1.0

## Radians of drift entry kick still to apply, signed like the steering that started it.
var _kick_remaining := 0.0
## Which way the current drift is pointed, so a change of direction can be noticed.
var _drift_direction := 0.0
## Which way the nose whips during a spin-out: +1 left, -1 right.
var _spin_direction := 1.0


func _init(kart_stats: KartStats) -> void:
	stats = kart_stats


## The motor's whole state, for the wire and for the replay buffer.
func capture() -> Array:
	var out: Array = []
	for field: StringName in STATE_FIELDS:
		out.append(get(field))
	return out


func restore(state: Array) -> void:
	if state.size() != STATE_FIELDS.size():
		return
	for i: int in STATE_FIELDS.size():
		set(STATE_FIELDS[i], state[i])


func forward_vector() -> Vector3:
	return Vector3(-sin(heading), 0.0, -cos(heading))


func speed() -> float:
	return velocity.length()


## Fraction of top speed currently driven, unsigned, may exceed 1 while boosted.
func speed_fraction() -> float:
	return speed() / stats.top_speed


func boosting() -> bool:
	return boost_time_left > 0.0


func turboing() -> bool:
	return turbo_time_left > 0.0


## True while the kart is spinning out on oil: no steering, no throttle, barely any grip.
func spinning() -> bool:
	return spin_time_left > 0.0


## Yaw rate in radians per second for a fraction of top speed.
func yaw_rate(fraction: float) -> float:
	var degrees := lerpf(
		stats.yaw_rate_low_deg, stats.yaw_rate_high_deg, clampf(fraction, 0.0, 1.0)
	)
	return deg_to_rad(degrees)


## Speed limit right now, including drift exit boost and turbo. A pad, a Boost and a bottle do
## not stack: whichever is giving the most is the one in charge.
func max_speed() -> float:
	var bonus := maxf(speed_bonus, nitro_bonus)
	if turboing():
		bonus = maxf(bonus, stats.turbo_speed_multiplier)
	if boosting():
		return stats.top_speed * bonus * (1.0 + stats.drift_exit_boost)
	return stats.top_speed * bonus


## Angle in radians between the nose and the direction of travel, positive when the nose points
## left of the travel direction. Zero when standing still.
func slip_angle() -> float:
	if velocity.length() < 0.05:
		return 0.0
	var travel := velocity.normalized() * signf(forward_speed if forward_speed != 0.0 else 1.0)
	return travel.signed_angle_to(forward_vector(), Vector3.UP)


func step(input: KartInput, delta: float) -> void:
	boost_time_left = maxf(boost_time_left - delta, 0.0)
	turbo_time_left = maxf(turbo_time_left - delta, 0.0)
	spin_time_left = maxf(spin_time_left - delta, 0.0)
	var forward := forward_vector()
	var along := velocity.dot(forward)
	var was_moving := velocity.length() > 0.05
	var was_reversing := was_moving and along < 0.0
	forward_speed = velocity.length() * (-1.0 if along < 0.0 else 1.0)
	_step_steer_input(input, delta)
	_step_longitudinal(input, delta)
	_step_drift(input)
	_step_drift_amount(delta)
	_step_slide(delta)
	_step_steering(delta)
	var reversing := forward_speed < 0.0
	var target := forward_vector() * (-1.0 if reversing else 1.0)
	var travel := velocity.normalized() if was_moving else target
	# Setting off, or braking through a stop into reverse: travel starts along the nose. A
	# spinning kart keeps its line even as the whipping nose flips the sign of the speed.
	if not was_moving or (reversing != was_reversing and not spinning()):
		travel = target
	var angle := travel.signed_angle_to(target, Vector3.UP)
	# Tires that have let go in a big slide keep sliding until the kart slows down, and a drift
	# takes the grip away over its entry time rather than in one tick.
	var letting_go := clampf((absf(angle) - deg_to_rad(20.0)) / deg_to_rad(25.0), 0.0, 1.0)
	var grip := lerpf(
		lerpf(stats.grip_normal, stats.grip_sliding, letting_go), stats.grip_drift, drift_amount
	)
	if nitro_bonus > 1.0:
		grip *= stats.nitro_grip_multiplier
	if spinning():
		grip = stats.spin_out_grip
	travel = travel.rotated(Vector3.UP, angle * (1.0 - exp(-grip * delta)))
	if spinning():
		# Oil does not grab: the kart slides on and bleeds speed slowly.
		forward_speed = move_toward(forward_speed, 0.0, stats.spin_out_decel * delta)
	elif drifting:
		forward_speed *= 1.0 - stats.drift_speed_decay * delta
		# Hanging the kart out costs speed, and costs more the further it hangs. A slide held at a
		# sensible angle is quick; one left to come all the way round scrubs itself to a stop,
		# which is what makes catching it worth doing rather than merely tidy.
		var past := maxf(absf(slip_angle()) - deg_to_rad(stats.slide_scrub_deg), 0.0)
		forward_speed = move_toward(
			forward_speed, 0.0, stats.slide_scrub * sin(past) * drift_amount * delta
		)
	else:
		# Sliding sideways outside a controlled drift scrubs speed hard, down to a near standstill.
		var slip := absf(travel.signed_angle_to(target, Vector3.UP))
		var sideways := sin(maxf(slip - deg_to_rad(10.0), 0.0))
		forward_speed = move_toward(forward_speed, 0.0, stats.slip_friction * sideways * delta)
	velocity = travel * absf(forward_speed)
	velocity.y = 0.0
	var limit := max_speed()
	if velocity.length() > limit:
		velocity = velocity.normalized() * limit
	_hold_the_slide_angle()


## The tires will not let the nose get further than [member KartStats.slide_max_deg] from where
## the kart is going. Bleeding the slide off at the limit is not enough: the rear is swinging at
## 370°/s by the time it gets there and carries straight through, and past a right angle the kart
## counts as traveling backwards, which inverts its steering. So the rotation is arrested there.
func _hold_the_slide_angle() -> void:
	if spinning() or velocity.length() < 0.5:
		return
	var edge := deg_to_rad(stats.slide_max_deg)
	var slip := slip_angle()
	if absf(slip) <= edge:
		return
	heading = wrapf(heading - (slip - signf(slip) * edge), -PI, PI)
	slide_rate = 0.0


## The rear coming round, GAME.md 4.1. It lets go once, when the handbrake is flicked, and
## a life of its own, and the wheel drives it by asking for an angle rather than for more
## slide: full lock into the slide asks the kart to sit at [member KartStats.slide_hold_deg],
## half lock asks for half of that, a straight wheel asks for none and opposite lock asks for
## less than none, which is a catch. The rear chases whatever was asked for, damped so it
## settles rather than wallowing. A wheel held over therefore holds an angle, which is the
## whole difference between driving a slide and fighting one.
##
## Catching it is the end of it, so opposite lock held after the catch steers the kart rather
## than throwing it the other way; another flick of the handbrake breaks the rear loose again.
func _step_slide(delta: float) -> void:
	if not drifting or spinning():
		# Gathered up as briskly as a catch would: the drift is over.
		slide_rate = move_toward(
			slide_rate, 0.0, deg_to_rad(stats.slide_hold_deg) * stats.slide_catch * delta
		)
		return
	if slide_rate == 0.0:
		return
	var way := signf(slide_rate)
	var hanging := -slip_angle() * way
	var into := clampf(steer * way, 0.0, 1.0)
	var against := clampf(-steer * way, 0.0, 1.0)
	# Where the wheel is asking the kart to sit: full lock into the slide asks for the whole
	# angle, half asks for half, straight asks for none and opposite asks for less than none.
	var wanted := deg_to_rad(stats.slide_hold_deg) * (into - against * stats.slide_catch)
	if hanging >= deg_to_rad(stats.slide_max_deg):
		wanted = minf(wanted, 0.0)
	slide_rate += way * stats.slide_seek * (wanted - hanging) * delta
	slide_rate -= slide_rate * minf(stats.slide_damp * delta, 1.0)
	if signf(slide_rate) != way:
		# Caught: the rear has come back in line rather than swinging through it.
		slide_rate = 0.0


## Shapes the raw steering by the stick curve and eases it toward the target, so a keyboard tap is
## a small correction and a held key builds to full lock.
func _step_steer_input(input: KartInput, delta: float) -> void:
	var raw := clampf(input.steer, -1.0, 1.0)
	var target := signf(raw) * pow(absf(raw), maxf(stats.stick_curve, 0.1))
	var increasing := (
		absf(target) > absf(steer) or (target != 0.0 and signf(target) != signf(steer))
	)
	var ramp := stats.steer_ramp_up if increasing else stats.steer_ramp_down
	if ramp <= 0.0:
		steer = target
	else:
		steer = move_toward(steer, target, delta / ramp)


func _step_longitudinal(input: KartInput, delta: float) -> void:
	if spinning():
		return
	var accel := stats.acceleration() * (1.5 if nitro_bonus > 1.0 else 1.0)
	# The bottle and a turbo pad are each their own throttle, GAME.md 4.2 and 6.2: both push
	# whether or not the pedal is down, so a kart coasting or reversing is thrown forward by
	# either. Braking still wins, so there is a way not to be carried into a wall.
	var throttle := input.throttle
	if (nitro_bonus > 1.0 or turboing()) and input.brake <= 0.01:
		throttle = 1.0
	if throttle > 0.01 and (forward_speed >= 0.0 or input.brake <= 0.01):
		forward_speed = move_toward(forward_speed, max_speed() * throttle, accel * delta)
	elif input.brake > 0.01:
		if forward_speed > 0.05:
			forward_speed = move_toward(forward_speed, 0.0, stats.brake_decel * input.brake * delta)
		else:
			var target := -stats.reverse_top_speed * input.brake
			forward_speed = move_toward(forward_speed, target, accel * delta)
	else:
		forward_speed = move_toward(forward_speed, 0.0, stats.coast_decel * delta)
	if input.handbrake and stats.handbrake_decel > 0.0:
		# A drift scrubs speed gently; without steering the handbrake is a hard, quick stop.
		var decel := stats.handbrake_drift_scrub if drifting else stats.handbrake_decel
		forward_speed = move_toward(forward_speed, 0.0, decel * delta)


func _step_drift(input: KartInput) -> void:
	var fraction := absf(forward_speed) / stats.top_speed
	if drifting:
		# The rear is loose or it is not. Nothing the wheel does ends the drift, since straightening
		# it and winding it the other way are how the slide is driven; it is over when the slide
		# has been caught or has bled away, and the handbrake is a flick to start it rather than
		# something to hold down.
		if fraction < stats.handbrake_speed_fraction * 0.75 or slide_rate == 0.0:
			_end_drift()
		return
	if spinning() or forward_speed <= 0.0:
		return
	# Only the handbrake starts a drift, with the wheel over and the kart quick enough.
	var steering := absf(steer) >= stats.handbrake_drift_steer
	if not input.handbrake or not steering or fraction < stats.handbrake_speed_fraction:
		return
	drifting = true
	drift_time = 0.0
	# The rear lets go, once, the way the kart was turned.
	slide_rate = signf(steer) * deg_to_rad(stats.slide_start_deg)
	# The rear swings out: the nose kicks into the turn over the next fraction of a second.
	var kick := deg_to_rad(stats.drift_entry_kick_deg)
	_kick_remaining = signf(steer) * kick if absf(steer) > 0.1 else 0.0


## How much of the drift has actually arrived. Asking for one starts the rear coming round
## rather than putting it there, letting go hooks it back up, and turning the other way mid-
## drift throws most of the slide away: the rear has to come back through the middle and bite
## before it will step out the other side.
func _step_drift_amount(delta: float) -> void:
	if not drifting:
		_drift_direction = 0.0
		drift_amount = move_toward(drift_amount, 0.0, delta / maxf(stats.drift_exit_time, 0.001))
		return
	var way := signf(steer)
	if way != 0.0 and _drift_direction != 0.0 and way != _drift_direction:
		drift_amount = minf(drift_amount, stats.drift_switch_amount)
		_kick_remaining = way * deg_to_rad(stats.drift_entry_kick_deg)
	if way != 0.0:
		_drift_direction = way
	drift_amount = move_toward(drift_amount, 1.0, delta / maxf(stats.drift_entry_time, 0.001))


func _end_drift() -> void:
	drifting = false
	_kick_remaining = 0.0
	if boost_earned():
		boost_time_left = stats.drift_exit_boost_duration
		forward_speed *= 1.0 + stats.drift_exit_boost
		boosts_paid += 1
	drift_time = 0.0


## Running into something spoils the slide, GAME.md 4.1. The exit boost is for a drift that was
## driven all the way round, not for one that finished in a wall, so the charge goes and any
## boost already running is cut. The kart keeps sliding; it just has nothing to collect at the
## end of it until it has earned another one.
func spoil_drift() -> void:
	drift_time = 0.0
	boost_time_left = 0.0


## Whether the drift running right now would pay its exit boost if it ended here: long enough
## to have been meant, and still quick enough to have been a drift rather than a shuffle. The
## sparks ask the same question, so what the kart promises and what it pays are one answer.
func boost_earned() -> bool:
	return (
		drift_time >= stats.drift_min_duration
		and speed_fraction() >= stats.drift_boost_speed_fraction
	)


func _step_steering(delta: float) -> void:
	if spinning():
		heading = wrapf(
			heading + _spin_direction * deg_to_rad(stats.spin_out_rate_deg) * delta, -PI, PI
		)
		return
	if drifting:
		drift_time += delta
		_step_entry_kick(delta)
	var speed_now := absf(forward_speed)
	var pivot := deg_to_rad(stats.turn_in_place_rate_deg) * steer_multiplier
	# Steering right is clockwise seen from above, which is a negative rotation about +Y.
	# Turning on the spot and turning on the wheels are the same control, so they are mixed
	# rather than switched between: a kart shuffling about in a corner crosses this range over
	# and over, and a step in the turn rate is felt every single time.
	var rolling := _rolling_rate(speed_now) * signf(forward_speed)
	var blend := clampf(speed_now / maxf(stats.pivot_blend_speed, 0.001), 0.0, 1.0)
	heading = wrapf(heading - (steer * lerpf(pivot, rolling, blend) + slide_rate) * delta, -PI, PI)


## How fast the nose comes round on the wheels at this speed, with everything that scales it. A
## drift does not tighten the steering, it takes authority away from it: what turns the kart then
## is the rear coming round, which [member slide_rate] carries.
func _rolling_rate(speed_now: float) -> float:
	var rate := yaw_rate(speed_now / stats.top_speed)
	rate *= lerpf(1.0, stats.slide_front_authority, drift_amount)
	if nitro_bonus > 1.0:
		rate *= stats.nitro_steer_multiplier
	return rate * steer_multiplier


## Plays out the drift entry kick as an extra yaw over [member KartStats.drift_entry_kick_time].
func _step_entry_kick(delta: float) -> void:
	if _kick_remaining == 0.0:
		return
	var total := deg_to_rad(stats.drift_entry_kick_deg)
	var rate := total / maxf(stats.drift_entry_kick_time, 0.001)
	var step := minf(rate * delta, absf(_kick_remaining)) * signf(_kick_remaining)
	heading = wrapf(heading - step, -PI, PI)
	_kick_remaining -= step
	if absf(_kick_remaining) < 0.0001:
		_kick_remaining = 0.0


## An oil stain: the tires let go. The kart keeps the line it was on while the nose whips
## around at [member KartStats.spin_out_rate_deg] for about a second, with steering and
## throttle doing nothing. [param direction] is +1 to spin left, -1 to spin right.
func apply_spin_out(direction: float) -> void:
	spin_time_left = stats.spin_out_time
	slide_rate = 0.0
	_spin_direction = 1.0 if direction >= 0.0 else -1.0
	drifting = false
	drift_amount = 0.0
	drift_time = 0.0
	_kick_remaining = 0.0
	turbo_time_left = 0.0
	boost_time_left = 0.0


## A turbo pad points the kart down its arrow and fires it along it, GAME.md 6.2, and then for
## the next second holds the throttle down for the driver and lifts the speed limit, so the kart
## runs fast whatever their finger was doing when they crossed the pad.
##
## Nothing else is taken: the wheel, the handbrake and the brake all work the whole time, at full
## authority, so the boost is something to steer and drift with. It used to be a rail instead,
## which the kart was locked onto and could only be thrown off by asking for it back, and the
## result was a pad that either drove for you or did nothing at all.
func apply_turbo(direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z).normalized()
	if flat.is_zero_approx():
		return
	heading = atan2(-flat.x, -flat.z)
	turbo_time_left = stats.turbo_duration
	drifting = false
	drift_amount = 0.0
	drift_time = 0.0
	slide_rate = 0.0
	_kick_remaining = 0.0
	forward_speed = stats.top_speed * stats.turbo_speed_multiplier
	velocity = flat * forward_speed


## A shallow wall hit. Returns true when the kart glanced off: the nose turns most of the way
## toward running along the wall and the kart is nudged away from it, so driving along walls
## takes no fight. [param normal] points from the wall toward the kart; [param travel] is the
## velocity before the body slid along the wall.
func apply_wall_glance(normal: Vector3, travel: Vector3) -> bool:
	var flat_normal := Vector3(normal.x, 0.0, normal.z).normalized()
	var flat := Vector3(travel.x, 0.0, travel.z)
	if flat_normal.is_zero_approx() or flat.length() < 1.0:
		return false
	var into := -flat.normalized().dot(flat_normal)
	if into <= 0.0 or asin(minf(into, 1.0)) > deg_to_rad(stats.wall_glance_angle_deg):
		return false
	var along := flat - flat_normal * flat.dot(flat_normal)
	if along.is_zero_approx():
		return false
	along = along.normalized()
	var facing := forward_vector() * (-1.0 if forward_speed < 0.0 else 1.0)
	var turn := facing.signed_angle_to(along, Vector3.UP) * stats.wall_glance_turn
	heading = wrapf(heading + turn, -PI, PI)
	var speed := flat.length() * (1.0 - stats.wall_glance_speed_loss * into)
	velocity = along * speed + flat_normal * stats.wall_glance_bounce
	velocity.y = 0.0
	forward_speed = speed * (-1.0 if forward_speed < 0.0 else 1.0)
	return true


## Wall contact: the velocity into the wall is gone already (the body slid); a hard hit also
## costs part of the remaining speed.
func apply_wall_hit(into_speed: float) -> void:
	if into_speed > stats.wall_hit_threshold * stats.top_speed:
		velocity *= 1.0 - stats.wall_hit_speed_loss
	turbo_time_left = 0.0


## Contact with another kart. [param normal] points from the other kart toward this one.
func apply_bump(normal: Vector3) -> void:
	var flat := Vector3(normal.x, 0.0, normal.z).normalized()
	velocity = velocity * (1.0 - stats.bump_speed_loss) + flat * stats.bump_push_speed
	velocity.y = 0.0
