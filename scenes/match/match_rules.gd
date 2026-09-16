class_name MatchRules
extends Resource
## Match-level numbers from GAME.md sections 3.2 to 3.8. Starting values; tune in playtests and
## write the result back into both this resource and GAME.md.

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

@export_group("Jackpot")
@export var jackpot_accrual := 1.0
@export var jackpot_cap := 60
@export var jackpot_amber := 20
@export var jackpot_rate_base := 2.0
@export var jackpot_rate_doubling := 0.5
@export var last_call_accrual := 2.0

@export_group("Royal Flush")
## Mult gained for holding all four flush pads at once.
@export var flush_mult := 3.0
## Fraction of the nitro tank a flush refills.
@export var flush_nitro_refill := 1.0
## Seconds the pads stay disabled after a flush.
@export var flush_disable_time := 20.0

@export_group("Death and respawn")
@export var death_bank_fraction := 0.5
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

@export_group("Lives")
## Hits a kart takes before it dies; pits kill outright.
@export var lives := 2
## Top speed multiplier while a life is missing.
@export var wounded_speed := 0.85
## Seconds after losing a life during which the kart cannot be hit again, so a burst of
## bullets cannot take both lives in the same moment.
@export var hurt_protection := 1.2

@export_group("Match")
## Whether the match runs against a clock. The Garage in 9.4 turns it off: no timer, no Last
## Call, no end.
@export var timed := true
@export var duration := 300.0
@export var target_score := 3000
@export var last_call_duration := 30.0
@export var countdown := 3.0
@export var max_players := 4
