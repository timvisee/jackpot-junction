class_name KartStats
extends Resource
## Handling numbers from GAME.md section 4.1. Starting values: tune in playtests and write the
## result back into both the resource and GAME.md.

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

@export_group("Nitro")
## Speed multiplier while burning nitro.
@export var nitro_speed_multiplier := 1.4
## Seconds a full tank burns for.
@export var nitro_capacity_seconds := 2.0
## Seconds an empty tank takes to refill.
@export var nitro_recharge_seconds := 12.0
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

@export_group("Collisions")
@export var wall_hit_threshold := 0.5
@export var wall_hit_speed_loss := 0.3
@export var bump_push_speed := 6.0
@export var bump_speed_loss := 0.2

@export_group("Body")
@export var length := 1.6
@export var width := 1.0
@export var height := 0.8


func acceleration() -> float:
	return top_speed / accel_time
