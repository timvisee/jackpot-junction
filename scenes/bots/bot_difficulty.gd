class_name BotDifficulty
extends Resource
## One difficulty preset from GAME.md 9.1, applied to every bot in a match.

@export var id: StringName
@export var display_name := ""
@export var reaction_delay := 0.3
@export var aim_error_deg := 5.0
@export var dodge_chance := 0.65
@export var top_speed_fraction := 1.0
## How much a fat pot pulls a bot toward whoever is carrying it, GAME.md 9.1. Zero is a bot that
## never looks at what anybody is holding and simply fights whoever is nearest. Only the hard
## bots read the board this way: knowing that a kart is worth 900 points right now, and going
## after it across the arena, is the difference between an opponent and a threat.
@export var pot_hunting := 0.0
