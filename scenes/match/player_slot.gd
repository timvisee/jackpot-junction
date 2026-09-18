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


## Whether driving onto the Junction and cashing in would end the match here and now, GAME.md
## 3.4. Banked plus pot is the sum, which is the number the running order already shows as a
## score and a [code]+N[/code] beside it. Last Call pays double, so during it this says yes no
## later than it has to rather than promising more than it knows.
func would_win(target: int) -> bool:
	return kart != null and kart.alive and not kart.pot.is_empty() and score() >= target


## Ranks two slots for the results, GAME.md 3.8: most banked, then most kills, then fewest
## deaths. Only what is banked wins a match.
static func by_banked(a: PlayerSlot, b: PlayerSlot) -> bool:
	if a.banked != b.banked:
		return a.banked > b.banked
	return _tie_break(a, b)


## Ranks two slots for the running order, which counts what a kart is still carrying as well, so
## a hot lap climbs the board before it reaches the Junction and drops back on dying.
static func by_score(a: PlayerSlot, b: PlayerSlot) -> bool:
	var left := a.score()
	var right := b.score()
	if left != right:
		return left > right
	return _tie_break(a, b)


## How a tie is settled, which is the same question whichever number was being compared.
static func _tie_break(a: PlayerSlot, b: PlayerSlot) -> bool:
	if a.kills != b.kills:
		return a.kills > b.kills
	return a.deaths < b.deaths


func color() -> Color:
	return Palette.player_color(color_index)


## Humans are local players and remote players alike.
func is_human() -> bool:
	return input is PlayerInput or input is NetInput


## A practice dummy in the Garage, GAME.md 9.4: neither a player nor a bot, and not a seat for
## anybody to take.
func is_dummy() -> bool:
	return input is DummyInput


## A human playing on this machine, the only kind that gets a HUD block and rumble.
func is_local_human() -> bool:
	return input is PlayerInput


## The device a human slot reads, or [constant DeviceInput.ANY].
func device() -> int:
	var player := input as PlayerInput
	return player.device if player != null else DeviceInput.ANY


func display_name() -> String:
	if is_dummy():
		return "P%d Dummy" % (index + 1)
	if bot_trait != null:
		return "P%d %s" % [index + 1, bot_trait.display_name]
	return "P%d" % (index + 1)
