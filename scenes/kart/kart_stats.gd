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
@export var grip_drift := 4.0
## When on, only the handbrake starts a drift; steering alone never does.
@export var handbrake_drift_only := true
## Braking of the handbrake, reduced while drifting; 0 means it never brakes.
@export var handbrake_decel := 12.0
@export var drift_steer_threshold := 0.8
@export var drift_speed_fraction := 0.7
@export var handbrake_speed_fraction := 0.4
@export var drift_exit_steer := 0.3
@export var drift_yaw_multiplier := 1.35
## Degrees the nose kicks into the turn when a drift starts while steering.
@export var drift_entry_kick_deg := 15.0
@export var drift_speed_decay := 0.05
@export var drift_min_duration := 0.6
@export var drift_exit_boost := 0.2
@export var drift_exit_boost_duration := 0.8

@export_group("Turbo pads")
@export var turbo_speed_multiplier := 1.5
@export var turbo_duration := 1.0
@export var turbo_steer_multiplier := 0.5

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
