class_name MatchRules
extends Resource
## Match-level numbers from GAME.md 3.6 and 3.8. Economy and scoring numbers join in M2.

@export_group("Death and respawn")
@export var respawn_delay := 3.0
@export var spawn_protection := 2.0
@export var pit_fall_time := 0.4
@export var bump_attribution_window := 2.0

@export_group("Players")
@export var max_players := 4
