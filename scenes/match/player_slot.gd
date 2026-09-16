class_name PlayerSlot
extends RefCounted
## One participant in a match, human or bot. Slots are the identity used for kills, ownership
## and scores, never node paths.

var index := 0
## Which of the player colours this slot uses; defaults to the slot index.
var color_index := 0
var input: KartInput
var kart: Kart
var respawn_left := 0.0
## The joker choice waiting while the kart is dead; null when none is pending.
var offer: JokerOffer
## The personality of a bot slot; null for humans.
var bot_trait: BotTrait
## The only score that counts at the end of the match.
var banked := 0
var kills := 0
var deaths := 0
## Everything else the kart did, for the awards on the results screen.
var stats := PlayerStats.new()


func _init(slot_index: int, kart_input: KartInput, slot_color: int = -1) -> void:
	index = slot_index
	color_index = slot_color if slot_color >= 0 else slot_index
	input = kart_input


## What this player is worth right now: what they have banked plus what they are still driving
## around with. Only [member banked] wins the match, but this is the number that says who is
## really ahead at this moment, and the bots and the standings both read it.
func score() -> int:
	return banked + (kart.pot.value() if kart != null else 0)


func color() -> Color:
	return Palette.player_color(color_index)


## Humans are local players and remote players alike.
func is_human() -> bool:
	return input is PlayerInput or input is NetInput


## A human playing on this machine, the only kind that gets a HUD block and rumble.
func is_local_human() -> bool:
	return input is PlayerInput


## The device a human slot reads, or [constant DeviceInput.ANY].
func device() -> int:
	var player := input as PlayerInput
	return player.device if player != null else DeviceInput.ANY


func display_name() -> String:
	if bot_trait != null:
		return "P%d %s" % [index + 1, bot_trait.display_name]
	return "P%d" % (index + 1)
