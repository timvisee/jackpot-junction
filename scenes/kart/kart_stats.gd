class_name KartStats
extends Resource
## Handling numbers from GAME.md section 4.1. Starting values: tune in playtests and write the
## result back into both the resource and GAME.md.

@export_group("Speed")
@export var top_speed := 13.0
@export var accel_time := 1.2
@export var brake_decel := 20.0
@export var reverse_top_speed := 5.0
@export var coast_decel := 4.0

@export_group("Steering")
@export var yaw_rate_low_deg := 200.0
@export var yaw_rate_high_deg := 110.0
@export var min_steer_speed := 0.5

@export_group("Grip and drift")
@export var grip_normal := 8.0
@export var grip_drift := 2.5
@export var drift_steer_threshold := 0.8
@export var drift_speed_fraction := 0.7
@export var handbrake_speed_fraction := 0.4
@export var drift_exit_steer := 0.3
@export var drift_yaw_multiplier := 1.6
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
