class_name BotTrait
extends Resource
## A personality that shifts a bot's goal weights, GAME.md 9.1.

@export var id: StringName
@export var display_name := ""
## Relative chance of a bot getting this trait.
@export var weight := 1.0
## Pot value from which the bot heads for the Junction.
@export var bank_threshold := 120
## During Last Call every bot banks anything above this.
@export var last_call_bank_threshold := 1
@export var hunt_weight := 1.0
@export var collect_weight := 1.0
## How keen the bot is on the Royal Flush pads, which pay while they are held.
@export var flush_weight := 1.0
@export var jackpot_min_chips := 20
@export var dodge_multiplier := 1.0
## Distance within which a Boosting enemy makes the bot flee.
@export var flee_distance := 6.0
## Drives into enemies instead of shooting them.
@export var rams := false
## Chance per decision that the bot is willing to fire at all.
@export var fire_chance := 1.0
