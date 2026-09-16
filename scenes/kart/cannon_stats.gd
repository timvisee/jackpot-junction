class_name CannonStats
extends Resource
## Cannon and bullet numbers from GAME.md 5.1 and 5.2. Cannon power-ups swap this resource.

@export_group("Firing")
@export var fire_cooldown := 0.4
@export var max_live_bullets := 3
@export var muzzle_offset := 1.0
@export var spread_count := 1
@export var spread_angle_deg := 0.0
@export var free_aim := false

@export_group("Bullet")
@export var bullet_speed := 17.0
@export var bullet_radius := 0.15
## Wall bounces before a bullet dies. Zero by default: jokers and the Ricochet Cannon add some.
@export var bounces := 0
@export var lifetime := 3.0

@export_group("Aim assist")
@export var aim_assist := true
@export var aim_assist_cone_deg := 15.0
@export var aim_assist_range := 15.0
@export var aim_assist_turn_rate_deg := 50.0
