class_name MatchRules
extends Resource
## Match-level numbers from GAME.md sections 3.2 to 3.8. Starting values; tune in playtests and
## write the result back into both this resource and GAME.md.

## The numbers a host has to tell a client about, GAME.md 10.3. Everything else in here is the
## same on both machines because it ships in the same resource, but these are the ones the lobby
## moves, and a client that joined with its own lobby open would otherwise play the host's match
## by its own settings: its own clock, its own target, its own answer to whether the whistle is
## really the end. The list also carries what a client reads for itself rather than off the wire,
## such as how many lives to draw pips for.
const WIRE_FIELDS: Array[StringName] = [
	&"duration",
	&"target_score",
	&"own_bullets_hurt",
	&"overtime",
	&"timed",
	&"lives",
	&"last_call_duration",
	&"countdown",
	&"max_players",
	&"map",
]

@export_group("Coins")
@export var chip_value := 1
@export var gold_chip_value := 5
@export var pad_gold_chance := 0.05
@export var pad_mult_die_chance := 0.08
@export var coin_pad_respawn := 5.0
@export var crate_drop_min := 2
@export var crate_drop_max := 4
@export var crate_gold_chance := 0.10
@export var pickup_radius := 0.9
@export var dropped_chip_lifetime := 15.0

@export_group("Items")
@export var power_pad_respawn := 15.0
## Coins a shooting target pays the kart that knocks it down.
@export var target_coins := 3
@export var item_reveal_time := 0.5

@export_group("Mult")
@export var kill_mult := 1.0
@export var graze_mult := 0.5
@export var graze_distance := 0.6
@export var graze_cooldown := 0.3
@export var mult_die_mult := 1.0

@export_group("Junction")
@export var bank_rate_base := 40.0
@export var bank_rate_doubling := 0.5
@export var last_call_payout := 2.0
## Pot value at which the Junction starts blinking at a local player, and where it blinks
## hardest. Nothing but a nudge: the pad works the same either way.
@export var junction_hint_start := 250.0
@export var junction_hint_full := 1200.0
## What the nitro refill rate is multiplied by while a kart stands on the pad. Cashing out puts
## a kart still and in the open in the middle of the arena for a couple of seconds, so the pad
## hands it the one thing that gets it out of there again.
@export var junction_nitro_recharge := 4.0

@export_group("Jackpot")
@export var jackpot_accrual := 1.0
## What the accrual and the cap are multiplied by at the top excitement level of GAME.md 8.4.
## A hot table fills faster and holds more, so the pile everyone is fighting over grows with
## the room rather than in spite of it.
@export var jackpot_accrual_hot := 3.0
@export var jackpot_cap_hot := 2.0
@export var jackpot_cap := 60
@export var jackpot_amber := 20
@export var jackpot_rate_base := 2.0
@export var jackpot_rate_doubling := 0.5
@export var last_call_accrual := 2.0

@export_group("Overtime")
## Whether the clock running out sends the match to sudden death instead of ending it, GAME.md
## 3.13. Off means the whistle goes on the hour as it always did.
@export var overtime := true

@export_group("Hot table")
## What the nitro refill rate is multiplied by before anything else touches it. One in a match,
## where nitro is meant to be scarce; far more in the Garage of 9.4, which is a room for trying
## the button rather than for rationing it.
@export var nitro_recharge_base := 1.0
## What the nitro refill rate is multiplied by at the top excitement level. Nitro is scarce by
## design, but a finale where nobody has any is a finale where nobody does anything.
@export var nitro_recharge_hot := 3.0
## The excitement level at which jokers start turning up on the floor of their own accord, and
## the seconds between them at the top. Below the top they come at half that pace. Nothing
## common is ever thrown out this way: the late match is where the good cards come from.
@export var wild_joker_level := 5
@export var wild_joker_interval := 22.0
## Seconds a joker thrown onto the floor lies there before it goes.
@export var wild_joker_lifetime := 15.0

@export_group("Royal Flush")
## Coins every held pad trickles into its holder's pot each second, so a pad is worth
## something on its own rather than only as a quarter of the flush.
@export var flush_pad_income := 1.0
## What that trickle is multiplied by at the top excitement level of GAME.md 8.4, so a room
## that is already going pays out faster and the pads are worth more the hotter it gets.
@export var flush_pad_income_hot := 3.0
## Seconds a pad stays claimed before it lapses back to nobody. Driving over it again renews
## it, so a flush has to be put together inside this window and then kept up.
@export var flush_pad_decay := 30.0
## Mult gained for holding all four flush pads at once.
@export var flush_mult := 3.0
## Fraction of the nitro tank a flush refills.
@export var flush_nitro_refill := 1.0
## Seconds a flush keeps paying its winner after the pads have cleared, at the rate all four
## of them paid together. The pads rest for longer than that, so the winner is still ahead
## when the board comes back and everyone starts again from nothing.
@export var flush_lock_seconds := 12.0
## Seconds the pads stay disabled after a flush.
@export var flush_disable_time := 20.0

@export_group("Death and respawn")
## Whether dying hands the player a joker to pick, GAME.md 3.7. Off in the waiting room of 9.6,
## where there is no run to build and a hand of cards over the screen is a player who cannot see
## the pad they are meant to be driving onto.
@export var offer_jokers := true
@export var death_bank_fraction := 0.5
## What a ram that does not kill knocks out of the victim's pot, and the most it can ever be,
## GAME.md 4.1. Driving nitro into somebody carrying a fortune should cost them something even
## when they live through it.
@export var ram_coin_fraction := 0.25
@export var ram_coin_max := 8
@export var death_drop_fraction := 0.3
@export var death_drop_max := 10
@export var death_joker_drop_chance := 0.2
@export var death_item_drop_chance := 0.5
@export var floor_item_lifetime := 15.0
@export var respawn_delay := 3.0
@export var spawn_protection := 2.0
@export var pit_fall_time := 0.4
@export var bump_attribution_window := 2.0

@export_group("Bounty")
## Seconds before the first bounty can be called, and the range between later ones.
@export var bounty_first_delay := 45.0
@export var bounty_interval_min := 25.0
@export var bounty_interval_max := 50.0
## How long a bounty stands before it lapses.
@export var bounty_duration := 20.0
## Banked points the leader must be clear by for a bounty to be worth calling.
@export var bounty_min_lead := 120
## Banked points the killer collects.
@export var bounty_reward := 150

@export_group("Friendly fire")
## Whether a kart's own shots can hurt it, GAME.md 5.1. Off by default: a bullet that bounces
## back into its owner, or one fired into a wall at point-blank range, is a bad surprise
## rather than an interesting risk. Either way the bullet is spent on the kart it came from;
## the rule only decides whether it hurts. Anything a kart owns counts as its own, so this
## also covers its turret's shots and its decoy's.
@export var own_bullets_hurt := false

@export_group("Lives")
## Hits a kart takes before it dies; pits kill outright.
@export var lives := 2
## Top speed multiplier while a life is missing.
@export var wounded_speed := 0.85
## Seconds after losing a life during which the kart cannot be hit again, so a burst of
## bullets cannot take both lives in the same moment.
@export var hurt_protection := 1.2

@export_group("Match")
## Which arena the match is played in, GAME.md 6.3. One of [constant ArenaMaps.IDS].
@export var map := &"lucky_crossing"
## Whether the match runs against a clock. The Garage in 9.4 turns it off: no timer, no Last
## Call, no end.
@export var timed := true
@export var duration := 300.0
@export var target_score := 3000
@export var last_call_duration := 30.0
@export var countdown := 3.0
@export var max_players := 4


func to_wire() -> Dictionary:
	var data: Dictionary = {}
	for field: StringName in WIRE_FIELDS:
		data[String(field)] = get(field)
	return data


## Takes the host's numbers on. Anything the host did not send is left alone, so an older host
## costs a client the fields it never knew about rather than the whole match.
func from_wire(data: Dictionary) -> void:
	for field: StringName in WIRE_FIELDS:
		if data.has(String(field)):
			set(field, data[String(field)])
