class_name KartRev
extends RefCounted
## The kart's virtual rev counter, GAME.md 8.4. Free of scene nodes so it can be unit tested,
## like [KartMotor].
##
## The engine is not pitched off road speed. It has a needle of its own that the road pulls on:
## flat out it sits at the limiter, off the line the clutch slips so the throttle revs it while
## the kart is still standing, driven wheels slipping in a drift spin it faster than the road
## does, reverse is one short gear that whines up and stays there, and nitro or a turbo pad
## carries it past the limiter. There is no gearbox: one continuous pull from idle to the top.

## Below this speed backwards the kart counts as going forwards, so a kart rocking about a
## standstill does not flick between the forward and reverse gears.
const REVERSE_SPEED := 0.05

var stats: KartSoundStats
## Where the needle is: [member KartSoundStats.idle_rev] at idle, 1 at the limiter, and up to
## [member KartSoundStats.over_max] while the kart is being shoved past its top speed.
var rev := 0.0
## How hard the engine is being driven, 0 coasting or braking to 1 flat out. The engine is
## quieter off the throttle.
var load := 0.0


func _init(sound_stats: KartSoundStats) -> void:
	stats = sound_stats
	rev = stats.idle_rev


func step(motor: KartMotor, input: KartInput, delta: float) -> void:
	rev = _follow(rev, _target(motor, input), stats.rev_rate_up, stats.rev_rate_down, delta)
	var wanted := clampf(input.throttle - input.brake, 0.0, 1.0)
	load = _follow(load, wanted, stats.load_rate_up, stats.load_rate_down, delta)


## Where the needle is heading this tick, before the smoothing.
func _target(motor: KartMotor, input: KartInput) -> float:
	var top := maxf(motor.stats.top_speed, 0.001)
	var fraction := absf(motor.forward_speed) / top
	var band := fraction
	if motor.forward_speed < -REVERSE_SPEED:
		# Reverse is one short gear of its own: it whines up and sits there.
		band = fraction / maxf(motor.stats.reverse_top_speed / top, 0.001)
	if band > 1.0:
		# Past the limiter, on nitro or a turbo pad, it simply screams on.
		band = 1.0 + (band - 1.0) * stats.over_slope
	band = clampf(band, 0.0, stats.over_max)
	var from_road := stats.idle_rev + (1.0 - stats.idle_rev) * band
	if motor.drifting or input.handbrake:
		# Driven wheels that have let go spin the engine faster than the road does.
		from_road += stats.slip_rev_bonus * input.throttle
	if motor.spinning():
		# The tires have let go on oil and so has the driver: it settles to a fast idle.
		return stats.idle_rev * stats.spin_idle_multiplier
	if input.brake > 0.5 and fraction < 0.02 and input.throttle < 0.01:
		return stats.idle_rev
	# The clutch slips off the line, so the throttle revs the engine against a kart that has not
	# started moving yet, and the kart catches up to it. This is what pulling away sounds like.
	var clutch := clampf(1.0 - fraction / clutch_fraction(), 0.0, 1.0)
	var free := stats.idle_rev + input.throttle * (stats.launch_rev - stats.idle_rev)
	return lerpf(from_road, maxf(from_road, free), clutch)


## The speed fraction over which the clutch bites, which is exactly the speed at which the road
## on its own would ask for [member KartSoundStats.launch_rev]. Handing over there is what keeps
## the needle climbing: were the clutch to bite sooner, the road would not have caught up yet and
## the engine would drop back down again, which is heard as a harsh flare rather than a swell.
func clutch_fraction() -> float:
	return maxf((stats.launch_rev - stats.idle_rev) / (1.0 - stats.idle_rev), 0.02)


## Playback speed for the engine loop: the needle against the rev the file was recorded at.
func pitch() -> float:
	return clampf(rev / maxf(stats.nominal_rev, 0.001), stats.pitch_min, stats.pitch_max)


## The engine's level in dB: full flat out, dropping away as the driver lifts.
func volume_db() -> float:
	return stats.engine_db + stats.off_throttle_db * (1.0 - load)


## Exponential follow with a different rate each way, so the needle climbs quicker than it falls.
static func _follow(value: float, target: float, up: float, down: float, delta: float) -> float:
	var rate := up if target > value else down
	return value + (target - value) * (1.0 - exp(-rate * delta))
