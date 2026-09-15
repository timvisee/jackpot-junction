class_name BotDifficulty
extends Resource
## One difficulty preset from GAME.md 9.1, applied to every bot in a match.

@export var id: StringName
@export var display_name := ""
@export var reaction_delay := 0.3
@export var aim_error_deg := 5.0
@export var dodge_chance := 0.65
@export var top_speed_fraction := 1.0
