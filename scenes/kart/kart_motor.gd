class_name KartMotor
extends RefCounted
## The arcade handling model from GAME.md 4.1, free of scene nodes so it can be unit tested.
##
## Two models live here, picked by [member KartStats.model], so they can be driven against each
## other with the same kart, track and camera.
##
## The rate model is the original. The kart has a heading and a direction of travel that are
## separate. Every tick the speed follows throttle and brake, the heading follows steering, and
## the direction of travel turns toward the heading at a grip rate. The steady slip angle is
## about the yaw rate divided by the grip: a few degrees while driving, and in a drift, with low
## grip and quicker yaw, the nose leads the travel direction by tens of degrees.
##
## The tire model turns a steering wheel instead of a kart. The stick winds a front wheel angle
## on at a rate, each axle is given a slip angle from where the kart is actually going, and the
## tires pull sideways in proportion to that slip up to a grip limit they cannot exceed. Yaw
## comes out of the difference between what the two axles pull, so understeer, oversteer and
## drift are what the numbers do rather than states to be entered. The two things that make it
## feel like a vehicle rather than a cursor: the turn radius is set by the wheel instead of by
## the speed, and the kart carries sideways velocity that has to be scrubbed off.

## How far the wheel has to go over to take a kart back off a turbo pad's arrow. Well past
## a nudge, so lining the kart up during the shove does not throw it away.
const TURBO_RELEASE_STEER := 0.6

var stats: KartStats
## Yaw in radians about +Y. Forward is -Z rotated by the heading, like a Node3D.
var heading := 0.0
## World-space velocity on the XZ plane.
var velocity := Vector3.ZERO
## Signed speed: positive when travelling roughly nose first, negative in reverse.
var forward_speed := 0.0
## The steering actually applied this tick: the input shaped by the stick curve and smoothed.
var steer := 0.0
var drifting := false
## How far into the slide the kart is, 0 gripping and 1 fully sideways. The flag above says
## whether a drift is being asked for; this says how much of one has actually arrived.
var drift_amount := 0.0
var drift_time := 0.0
## How fast the rear is coming round on its own, in radians a second, signed like the
## steering: positive swings the nose to the right. Only the oversteer drift style uses it.
var slide_rate := 0.0
var boost_time_left := 0.0
var turbo_time_left := 0.0
## Direction a turbo pad pushes along while [method turboing].
var turbo_direction := Vector3.ZERO
## Seconds of spin-out left after the tires let go on an oil stain.
var spin_time_left := 0.0
## Multipliers set by power-ups: Boost raises the speed bonus and lowers the steering.
var speed_bonus := 1.0
var steer_multiplier := 1.0
## Speed multiplier while the kart burns nitro, 1 when it does not.
var nitro_bonus := 1.0

## How fast the nose is coming round, in radians a second, positive turning left. The tire
## model integrates this; the rate model sets the heading directly and leaves it alone.
var yaw := 0.0

## The front wheel angle the tire model has wound on, in radians, positive turning left.
var _wheel := 0.0
## Radians of drift entry kick still to apply, signed like the steering that started it.
var _kick_remaining := 0.0
## Which way the current drift is pointed, so a change of direction can be noticed.
var _drift_direction := 0.0
## Which way the nose whips during a spin-out: +1 left, -1 right.
var _spin_direction := 1.0


func _init(kart_stats: KartStats) -> void:
	stats = kart_stats


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


## Speed limit right now, including drift exit boost and turbo.
func max_speed() -> float:
	if turboing():
		return stats.top_speed * stats.turbo_speed_multiplier
	var bonus := maxf(speed_bonus, nitro_bonus)
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
	_step_turbo_release(input)
	if stats.model == KartStats.Model.TIRES:
		_step_tires(input, delta)
		return
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
	if turboing():
		# A pad shoves along its arrow whatever way the nose points; grip takes over afterwards.
		velocity = turbo_direction * stats.top_speed * stats.turbo_speed_multiplier
		forward_speed = velocity.length() * (-1.0 if velocity.dot(forward_vector()) < 0.0 else 1.0)
		return
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
		if _oversteering():
			# Hanging the kart out costs speed, and costs more the further it hangs. A slide held
			# at a sensible angle is quick; one left to come all the way round scrubs itself to a
			# stop, which is what makes catching it worth doing rather than merely tidy.
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
## counts as travelling backwards, which inverts its steering. So the rotation is arrested there.
func _hold_the_slide_angle() -> void:
	if not _oversteering() or spinning() or velocity.length() < 0.5:
		return
	var edge := deg_to_rad(stats.slide_max_deg)
	var slip := slip_angle()
	if absf(slip) <= edge:
		return
	heading = wrapf(heading - (slip - signf(slip) * edge), -PI, PI)
	slide_rate = 0.0


## The tire model, GAME.md 4.1. Sub-stepped, because tires are stiff: a whole 60 Hz tick of a
## grip force that wants to reverse inside that tick oscillates instead of settling.
func _step_tires(input: KartInput, delta: float) -> void:
	var steps := maxi(stats.substeps, 1)
	var step_delta := delta / float(steps)
	for i: int in steps:
		_step_tires_once(input, step_delta)
	velocity.y = 0.0
	var limit := max_speed()
	if velocity.length() > limit:
		velocity = velocity.normalized() * limit
	forward_speed = velocity.dot(forward_vector())


func _step_tires_once(input: KartInput, delta: float) -> void:
	var forward := forward_vector()
	var right := forward.cross(Vector3.UP)
	var long_speed := velocity.dot(forward)
	var lat_speed := velocity.dot(right)
	_step_wheel(input, absf(long_speed), delta)
	if spinning():
		_step_spin(delta)
		return
	if turboing():
		velocity = turbo_direction * stats.top_speed * stats.turbo_speed_multiplier
		return
	long_speed = _drive(input, long_speed, delta)
	if absf(long_speed) < stats.creep_speed:
		_step_creep(input, right, long_speed, delta)
		return
	# Where each axle is pointing against where it is actually going. The front axle's own steering
	# comes off its slip, which is the whole of what steering does here.
	var reference := maxf(absf(long_speed), 1.0)
	var direction := signf(long_speed)
	var front_arm := stats.wheelbase * stats.weight_bias
	var rear_arm := stats.wheelbase * (1.0 - stats.weight_bias)
	var front_slip := atan((lat_speed + yaw * front_arm) / reference) - _wheel * direction
	var rear_slip := atan((lat_speed - yaw * rear_arm) / reference)
	var front_force := _tire_force(front_slip, stats.front_stiffness, stats.front_grip)
	var rear_grip := stats.rear_grip
	if input.handbrake:
		# The handbrake is not a state to be in, it is grip taken away from the back axle.
		rear_grip *= stats.handbrake_rear_grip
	if nitro_bonus > 1.0:
		rear_grip *= stats.nitro_grip_multiplier
	var rear_force := _tire_force(rear_slip, stats.rear_stiffness, rear_grip)
	# Yaw is what is left over when the two axles pull by different amounts.
	var torque := front_arm * front_force * cos(_wheel) - rear_arm * rear_force
	yaw += torque / maxf(stats.rotational_inertia, 0.01) * delta
	yaw -= yaw * minf(stats.yaw_damping * delta, 1.0)
	var lateral := front_force * cos(_wheel) + rear_force
	lat_speed += (lateral - yaw * long_speed) * delta
	# The friction circle: rubber spent holding the kart round a corner is rubber it cannot
	# also use to drive or brake, so a corner taken at the limit costs speed.
	var used := absf(lateral) / maxf(stats.front_grip + stats.rear_grip, 0.01)
	long_speed = move_toward(long_speed, 0.0, stats.slip_friction * used * used * delta)
	heading = wrapf(heading + yaw * delta, -PI, PI)
	var turned := forward_vector()
	velocity = turned * long_speed + turned.cross(Vector3.UP) * lat_speed
	_set_drifting(absf(rear_slip) > deg_to_rad(18.0) and absf(lat_speed) > 1.5, delta)


## Whether a drift is running under the oversteer style, where the rear has a mind of its own.
func _oversteering() -> bool:
	return stats.drift_style == KartStats.DriftStyle.OVERSTEER


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
	if not _oversteering() or not drifting or spinning() or turboing():
		# Gathered up as quickly as counter-steering would: the drift is over.
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


## Drifting is not a mode here, it is a reading: the rear is sliding and the kart is going
## sideways with it. It still earns the exit boost, so a long slide held and gathered up pays
## the same as it does under the rate model.
func _set_drifting(sliding: bool, delta: float) -> void:
	if sliding:
		drift_time += delta
		drifting = true
		return
	if drifting:
		_end_drift()
	drifting = false


## The sideways pull of one axle: proportional to its slip angle until the tire runs out of grip,
## and flat after that. The flat part is the whole game, since it is what a kart does once it is
## asking for more than the floor will give.
func _tire_force(slip: float, stiffness: float, grip: float) -> float:
	return -clampf(stiffness * slip, -grip, grip)


## The wheel follows the stick at a rate rather than jumping to it, and full lock winds off as the
## kart speeds up. Both together are what a keyboard player feels as weight instead of twitch.
func _step_wheel(input: KartInput, speed_now: float, delta: float) -> void:
	var raw := clampf(input.steer, -1.0, 1.0)
	var shaped := signf(raw) * pow(absf(raw), maxf(stats.stick_curve, 0.1))
	var fraction := clampf(speed_now / stats.top_speed, 0.0, 1.0)
	var lock := deg_to_rad(lerpf(stats.steer_angle_low_deg, stats.steer_angle_high_deg, fraction))
	# Positive heading is a left turn, and steering right is positive on the stick.
	var target := -shaped * lock * steer_multiplier
	_wheel = move_toward(_wheel, target, deg_to_rad(stats.steer_speed_deg) * delta)
	steer = raw


## Throttle, brake and drag along the nose, shared with the rate model's numbers.
func _drive(input: KartInput, long_speed: float, delta: float) -> float:
	var accel := stats.acceleration() * (1.5 if nitro_bonus > 1.0 else 1.0)
	var throttle := input.throttle
	if nitro_bonus > 1.0 and input.brake <= 0.01:
		throttle = 1.0
	if throttle > 0.01 and (long_speed >= 0.0 or input.brake <= 0.01):
		long_speed = move_toward(long_speed, max_speed() * throttle, accel * delta)
	elif input.brake > 0.01:
		if long_speed > 0.05:
			long_speed = move_toward(long_speed, 0.0, stats.brake_decel * input.brake * delta)
		else:
			long_speed = move_toward(
				long_speed, -stats.reverse_top_speed * input.brake, accel * delta
			)
	else:
		long_speed = move_toward(long_speed, 0.0, stats.coast_decel * delta)
	if input.handbrake:
		long_speed = move_toward(long_speed, 0.0, stats.handbrake_drift_scrub * delta)
	return long_speed


## Crawling or stopped. Slip angles measured from almost no velocity are noise, so the kart is
## steered by plain geometry instead: it goes where it points, turning on the arc the wheel asks
## for, and pivots on the spot when it is not rolling at all.
func _step_creep(input: KartInput, right: Vector3, long_speed: float, delta: float) -> void:
	var pivot := deg_to_rad(stats.turn_in_place_rate_deg) * steer_multiplier
	if absf(long_speed) < 0.2:
		yaw = 0.0
		if pivot > 0.0 and absf(input.steer) > 0.1:
			heading = wrapf(heading - input.steer * pivot * delta, -PI, PI)
		velocity = forward_vector() * long_speed
		return
	# Rolling slowly: the arc the wheel asks for, with the pivot fading out of it.
	var geometric := long_speed * tan(_wheel) / maxf(stats.wheelbase, 0.01)
	var crawl := clampf(1.0 - absf(long_speed) / stats.creep_speed, 0.0, 1.0)
	var steered := -input.steer * pivot * crawl
	yaw = geometric + steered
	heading = wrapf(heading + yaw * delta, -PI, PI)
	var settle := minf(delta * 12.0, 1.0)
	var lat_speed := velocity.dot(right) * (1.0 - settle)
	velocity = forward_vector() * long_speed + forward_vector().cross(Vector3.UP) * lat_speed


## An oil stain under the tire model: the nose whips round while the kart keeps its line.
func _step_spin(delta: float) -> void:
	heading = wrapf(
		heading + _spin_direction * deg_to_rad(stats.spin_out_rate_deg) * delta, -PI, PI
	)
	yaw = 0.0
	var speed_now := velocity.length()
	if speed_now > 0.01:
		velocity = velocity.normalized() * maxf(speed_now - stats.spin_out_decel * delta, 0.0)


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
	if turboing():
		forward_speed = max_speed()
		return
	var accel := stats.acceleration() * (1.5 if nitro_bonus > 1.0 else 1.0)
	# The bottle is its own throttle, GAME.md 4.2: nitro pushes whether or not the pedal is
	# down, so a kart coasting or reversing is thrown forward by it. Braking still wins, so
	# there is a way to burn nitro without being carried into a wall.
	var throttle := input.throttle
	if nitro_bonus > 1.0 and input.brake <= 0.01:
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
		var too_slow := fraction < stats.handbrake_speed_fraction * 0.75
		if _oversteering():
			# The rear is loose or it is not. Nothing the wheel does ends this one, since
			# straightening it and winding it the other way are how the slide is driven; the drift
			# is over when the slide has been caught or has bled away, and the handbrake is a flick
			# to start it rather than something to hold down.
			if too_slow or slide_rate == 0.0:
				_end_drift()
			return
		if stats.handbrake_drift_only:
			# Straightening up while holding the handbrake turns the drift into a straight stop.
			if too_slow or not input.handbrake or absf(steer) < 0.1:
				_end_drift()
			return
		var steering := absf(steer) >= stats.drift_exit_steer
		if too_slow or (not steering and not input.handbrake):
			_end_drift()
		return
	if turboing() or spinning() or forward_speed <= 0.0:
		return
	var steering := absf(steer) >= stats.handbrake_drift_steer
	var handbrake := input.handbrake and steering and fraction >= stats.handbrake_speed_fraction
	var hard_turn := absf(steer) >= stats.drift_steer_threshold
	var fast := fraction >= stats.drift_speed_fraction
	if handbrake or (not stats.handbrake_drift_only and hard_turn and fast):
		drifting = true
		drift_time = 0.0
		if _oversteering():
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
	if not stats.drift_ramp:
		drift_amount = 1.0 if drifting else 0.0
		_drift_direction = signf(steer) if drifting else 0.0
		return
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
	if drift_time >= stats.drift_min_duration:
		boost_time_left = stats.drift_exit_boost_duration
		forward_speed *= 1.0 + stats.drift_exit_boost
	drift_time = 0.0


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
	if stats.pivot_blend_speed <= 0.0:
		_step_steering_switched(speed_now, pivot, delta)
		return
	# Steering right is clockwise seen from above, which is a negative rotation about +Y.
	# Turning on the spot and turning on the wheels are the same control, so they are mixed
	# rather than switched between: a kart shuffling about in a corner crosses this range over
	# and over, and a step in the turn rate is felt every single time.
	var rolling := _rolling_rate(speed_now) * signf(forward_speed)
	var blend := clampf(speed_now / stats.pivot_blend_speed, 0.0, 1.0)
	heading = wrapf(heading - (steer * lerpf(pivot, rolling, blend) + slide_rate) * delta, -PI, PI)


## The original hard switch at [member KartStats.min_steer_speed], kept so the blend can be
## driven against it.
func _step_steering_switched(speed_now: float, pivot: float, delta: float) -> void:
	if speed_now <= stats.min_steer_speed:
		if stats.turn_in_place_rate_deg > 0.0 and steer != 0.0:
			heading = wrapf(heading - steer * pivot * delta, -PI, PI)
		return
	var rate := _rolling_rate(speed_now)
	heading = wrapf(heading - steer * rate * signf(forward_speed) * delta, -PI, PI)


## How fast the nose comes round on the wheels at this speed, with everything that scales it.
## Under the oversteer style a drift does not tighten the steering, it takes authority away
## from it: what turns the kart then is the rear coming round, which [member slide_rate]
## carries.
func _rolling_rate(speed_now: float) -> float:
	var rate := yaw_rate(speed_now / stats.top_speed)
	if _oversteering():
		rate *= lerpf(1.0, stats.slide_front_authority, drift_amount)
	else:
		rate *= lerpf(1.0, stats.drift_yaw_multiplier, drift_amount)
	if turboing():
		rate *= stats.turbo_steer_multiplier
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


## A shove is a gift, not a sentence, GAME.md 6.2: braking, yanking the handbrake or putting
## the wheel over ends it there and then, and the kart keeps the speed it was given. Without
## this a pair of pads pointing at each other is a trap with no way out of it.
func _step_turbo_release(input: KartInput) -> void:
	if not turboing():
		return
	if input.brake > 0.01 or input.handbrake or absf(input.steer) > TURBO_RELEASE_STEER:
		turbo_time_left = 0.0


## A turbo pad shoves the kart along its arrow without turning it. Facing along the arrow, or
## straight against it, the shove lasts the full duration and the kart simply runs faster,
## forward or in reverse. Crossing the pad sideways gives only a short shove, after which the
## kart slides on its slipping tires until it has nearly stopped.
func apply_turbo(direction: Vector3) -> void:
	var flat := Vector3(direction.x, 0.0, direction.z).normalized()
	if flat.is_zero_approx():
		return
	var angle := absf(flat.signed_angle_to(forward_vector(), Vector3.UP))
	var align := deg_to_rad(stats.turbo_align_angle_deg)
	var aligned := angle <= align or angle >= PI - align
	turbo_direction = flat
	turbo_time_left = stats.turbo_duration if aligned else stats.turbo_side_push_time
	drifting = false
	drift_time = 0.0
	_kick_remaining = 0.0
	velocity = flat * stats.top_speed * stats.turbo_speed_multiplier
	forward_speed = velocity.length() * (-1.0 if flat.dot(forward_vector()) < 0.0 else 1.0)


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
