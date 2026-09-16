class_name KartStats
extends Resource
## Handling numbers from GAME.md section 4.1. Starting values: tune in playtests and write the
## result back into both the resource and GAME.md.
##
## Two handling models live here, picked by [member model]. The rate model is the original: the
## stick sets a yaw rate and the direction of travel chases the nose. The tire model turns a
## wheel instead and lets the tires decide what the kart does with it, which is what the Tire
## model group below is for. Most of the numbers outside that group are shared.

## Which handling model drives the kart, GAME.md 4.1.
enum Model {
	## The stick is a yaw rate and the travel direction chases the nose.
	RATE,
	## The stick is a steering wheel and tires with a grip limit decide the rest.
	TIRES,
}

@export var model: Model = Model.RATE

@export_group("Speed")
@export var top_speed := 10.5
@export var accel_time := 1.5
@export var brake_decel := 20.0
@export var reverse_top_speed := 5.0
@export var coast_decel := 4.0

@export_group("Steering")
@export var yaw_rate_low_deg := 200.0
@export var yaw_rate_high_deg := 110.0
@export var min_steer_speed := 0.5
## Seconds for the applied steering to go from centre to full lock; 0 is instant.
@export var steer_ramp_up := 0.0
## Seconds for the applied steering to return to centre; 0 is instant.
@export var steer_ramp_down := 0.0
## Exponent on the stick deflection; 1 is linear, higher gives finer control near centre.
@export var stick_curve := 1.0
## Turning speed while standing still, to line up a shot; 0 disables it.
@export var turn_in_place_rate_deg := 70.0
## Speed by which the turn on the spot has faded out entirely and the kart is turning on its
## wheels alone. Manoeuvring in a corner crosses this range constantly, and a hard switch
## between the two rates is felt every time; 0 keeps that switch, at [member min_steer_speed].
@export var pivot_blend_speed := 2.2

@export_group("Grip and drift")
## How fast the direction of travel turns toward the nose, per second. Slip is about yaw over grip.
@export var grip_normal := 16.0
@export var grip_drift := 4.8
## When on, only the handbrake starts a drift; steering alone never does.
@export var handbrake_drift_only := true
## Braking of the handbrake without steering: a quick straight stop; 0 means it never brakes.
@export var handbrake_decel := 22.0
## Braking of the handbrake while drifting, gentle so a drift keeps its speed.
@export var handbrake_drift_scrub := 4.2
## Steering needed for the handbrake to start a drift; below it the handbrake just stops the kart.
@export var handbrake_drift_steer := 0.3
@export var drift_steer_threshold := 0.8
@export var drift_speed_fraction := 0.7
@export var handbrake_speed_fraction := 0.4
@export var drift_exit_steer := 0.3
@export var drift_yaw_multiplier := 1.55
## Degrees the nose kicks into the turn when a drift starts while steering.
@export var drift_entry_kick_deg := 15.0
## Seconds over which that kick plays out, so the rear swings rather than snaps.
@export var drift_entry_kick_time := 0.15
@export var drift_speed_decay := 0.05
@export var drift_min_duration := 0.6
@export var drift_exit_boost := 0.2
@export var drift_exit_boost_duration := 0.8

@export_group("Tire model")
## Wheelbase, and how far forward of the middle the weight sits. A kart with its weight back
## rotates more easily and lets go at the rear first.
@export var wheelbase := 1.15
@export var weight_bias := 0.5
## Full lock in degrees, at a standstill and at top speed. Winding the lock off with speed is
## what keeps a fast kart from being twitchy without making a slow one feel numb.
@export var steer_angle_low_deg := 34.0
@export var steer_angle_high_deg := 17.0
## Degrees a second the wheel turns toward where the stick is asking. This is the weight in
## the steering, and the one number a keyboard player feels most.
@export var steer_speed_deg := 320.0
## How hard each axle bites per radian of slip, in m/s² per radian.
@export var front_stiffness := 90.0
@export var rear_stiffness := 110.0
## The most each axle can pull sideways, in m/s². Under about 8 the kart understeers on the
## way in; a rear below the front is a kart that wants to swap ends.
@export var front_grip := 12.0
@export var rear_grip := 13.0
## What the handbrake leaves of the rear grip, so pulling it steps the back out.
@export var handbrake_rear_grip := 0.25
## How hard the kart resists being turned. Higher is heavier and slower to rotate.
@export var rotational_inertia := 1.6
## A whisker of extra yaw damping. The tires damp the kart themselves, since yaw shows up in
## their slip angles, so this is only here to take the ring out of the numbers: turn it up and
## it starts deciding the cornering instead of the grip.
@export var yaw_damping := 0.25
## Below this speed the tire model hands over to plain geometry, so a crawling kart does not
## chatter on slip angles measured from almost no velocity.
@export var creep_speed := 1.6
## Physics sub-steps per tick. Tires are stiff, and one step of 60 Hz is not enough for them.
@export var substeps := 4

@export_group("Nitro")
## Speed multiplier while burning nitro.
@export var nitro_speed_multiplier := 1.9
## Steering and grip multipliers while burning nitro, so the speed comes with a handful.
@export var nitro_steer_multiplier := 0.6
@export var nitro_grip_multiplier := 0.55
## Seconds a full tank burns for.
@export var nitro_capacity_seconds := 2.0
## Seconds an empty tank takes to refill: slow, so nitro is scarce and kills are the way to it.
@export var nitro_recharge_seconds := 90.0
## Fraction of the tank a kill hands the killer.
@export var nitro_kill_refill := 0.5
## Seconds after letting go before the tank starts refilling.
@export var nitro_recharge_delay := 0.6
## Fraction of the tank needed to start burning, so a near-empty tank cannot be tapped forever.
@export var nitro_min_start := 0.2

@export_group("Turbo pads")
@export var turbo_speed_multiplier := 1.5
@export var turbo_duration := 1.0
@export var turbo_steer_multiplier := 0.5
## Within this angle of the pad's arrow, forward or backward, the pad pushes for the full duration.
@export var turbo_align_angle_deg := 45.0
## A kart crossing the pad sideways only gets a short shove, then slides.
@export var turbo_side_push_time := 0.15
## Braking from sliding sideways outside a drift, per second at a right angle of slip.
@export var slip_friction := 14.0
## Grip while the tires have let go in a big uncontrolled slide, so the kart keeps sliding
## sideways instead of hooking up until it has slowed down.
@export var grip_sliding := 1.5

@export_group("Spin-out")
## Seconds the nose keeps whipping around after the tires let go on an oil stain.
@export var spin_out_time := 1.1
## Degrees per second the nose spins during it.
@export var spin_out_rate_deg := 420.0
## Grip while spinning: near zero, so the kart keeps sliding the way it was going.
@export var spin_out_grip := 0.8
## Speed scrubbed per second while spinning.
@export var spin_out_decel := 3.0

@export_group("Collisions")
@export var wall_hit_threshold := 0.5
@export var wall_hit_speed_loss := 0.3
@export var bump_push_speed := 6.0
@export var bump_speed_loss := 0.2
## A wall hit within this angle of the wall is a glance: the kart bounces off a little and turns
## to run along the wall instead of grinding into it.
@export var wall_glance_angle_deg := 35.0
## Fraction of the angle to the wall the nose turns on a glance.
@export var wall_glance_turn := 0.6
## Speed pushed away from the wall on a glance.
@export var wall_glance_bounce := 1.2
## Fraction of speed lost on a glance straight into the wall; shallower glances lose less.
@export var wall_glance_speed_loss := 0.15

@export_group("Body")
@export var length := 1.6
@export var width := 1.0
@export var height := 0.8


func acceleration() -> float:
	return top_speed / accel_time
