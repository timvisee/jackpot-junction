class_name PlayerSlot
extends RefCounted
## One participant in a match, human or bot. Slots are the identity used for kills, ownership
## and scores, never node paths.

var index := 0
## How this player's kart is dressed, GAME.md 4.4.
var style := KartStyle.new()
## What this player calls themselves, GAME.md 3.8. Empty for a bot or a dummy, which are named
## after what they are; every human has one, their own or one off the funny list.
var player_name := ""
## Which of the player colors this slot uses; defaults to the slot index.
var color_index := 0
var input: KartInput
var kart: Kart
var respawn_left := 0.0
## The joker choice waiting while the kart is dead; null when none is pending.
var offer: JokerOffer
## At a client: when a card was last dropped or destroyed out of this seat's hand here, on the
## engine's clock, see [method changed_hand_lately].
var hand_changed_at := -1.0
## The personality of a bot slot; null for humans.
var bot_trait: BotTrait
## The only score that counts at the end of the match.
var banked := 0
var kills := 0
var deaths := 0
## Everything else the kart did, for the awards on the results screen.
var stats := PlayerStats.new()
## Milliseconds there and back to the machine this player plays at, as the host last timed it,
## GAME.md 10.3: 0 for a player at the host, and for a bot.
var round_trip := 0.0


func _init(slot_index: int, kart_input: KartInput, slot_color: int = -1) -> void:
	index = slot_index
	color_index = slot_color if slot_color >= 0 else slot_index
	input = kart_input


## What this player is worth right now: what they have banked plus what they are still driving
## around with. Only [member banked] wins the match, but this is the number that says who is
## really ahead at this moment, and the bots and the standings both read it.
func score() -> int:
	return banked + (kart.pot.value() if kart != null else 0)


## What cashing the pot in would bank here and now, GAME.md 3.4: its worth, times whatever the
## kart's jokers pay on a cash-out, Glass Jackpot's half again for every copy held, and times
## [param payout], the Junction's own, which Last Call doubles. Rounded down, as it is never more
## than the Junction would pay.
func cash_out_value(payout := 1.0) -> int:
	if kart == null or kart.pot.is_empty():
		return 0
	return floori(kart.pot.exact_value() * payout * kart.bank_payout())


## Whether driving onto the Junction and cashing in would end the match here and now, GAME.md
## 3.4: what is banked and what the cash-out would bank, see [method cash_out_value], come to
## [param target]. [method Match.would_win] says it with the Junction's payout as it is.
func would_win(target: int, payout := 1.0) -> bool:
	if kart == null or not kart.alive or kart.pot.is_empty():
		return false
	return banked + cash_out_value(payout) >= target


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
## Whether a card left this seat's hand here so lately that the host may not have heard yet, see
## [constant JokerOffer.ANSWER_HOLD]: the snapshots made before it still hold the card.
func changed_hand_lately() -> bool:
	var since := Time.get_ticks_msec() * 0.001 - hand_changed_at
	return hand_changed_at >= 0.0 and since < JokerOffer.ANSWER_HOLD


func is_human() -> bool:
	return input is PlayerInput or input is NetInput


## A practice dummy in the Garage, GAME.md 9.4: neither a player nor a bot, and not a seat for
## anybody to take.
func is_dummy() -> bool:
	return input is DummyInput


## A human playing on this machine, the only kind that gets a HUD block and rumble.
func is_local_human() -> bool:
	return input is PlayerInput


## The ways of driving the bots in [param slots] were dealt, for the next bot to be dealt one
## of the others first, see [method BotTraitTable.pick].
static func traits_in(slots: Array[PlayerSlot]) -> Array[BotTrait]:
	var found: Array[BotTrait] = []
	for slot: PlayerSlot in slots:
		if slot.bot_trait != null:
			found.append(slot.bot_trait)
	return found


## The bot's seat a newcomer takes over, GAME.md 9.2: the one in [param wanted_color] if there is
## one, so a player coming back from another room keeps theirs, and otherwise the first. A
## practice dummy's seat is not there to be taken: it is furniture.
static func bot_seat(slots: Array[PlayerSlot], wanted_color := -1) -> PlayerSlot:
	var seat: PlayerSlot = null
	for slot: PlayerSlot in slots:
		if slot.is_human() or slot.is_dummy():
			continue
		if seat == null or (slot.color_index == wanted_color and seat.color_index != wanted_color):
			seat = slot
	return seat


## Whether this is somebody at this machine playing on [param device]. A player who came in on
## any device is playing on the one they last drove with, so their own join press is theirs
## rather than somebody new sitting down beside them.
func plays_on(device: int) -> bool:
	var player := input as PlayerInput
	if player == null:
		return false
	var held := player.held_device()
	return held != DeviceInput.ANY and held == device


## The device a human slot reads, or [constant DeviceInput.ANY].
func device() -> int:
	var player := input as PlayerInput
	return player.device if player != null else DeviceInput.ANY


func display_name() -> String:
	if not player_name.is_empty():
		return player_name
	if is_dummy():
		return "P%d Dummy" % (index + 1)
	if bot_trait != null:
		return "P%d %s" % [index + 1, bot_trait.display_name]
	return "P%d" % (index + 1)
