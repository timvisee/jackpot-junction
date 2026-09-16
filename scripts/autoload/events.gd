extends Node
## Global gameplay signals. Autoloaded as `Events`.
##
## Gameplay code emits these; HUD, audio, tally and jokers listen. Gameplay never reaches into UI.
## Slots identify players and bots (0 to 3); -1 means nobody, for example a pit death.

signal coin_collected(slot: int, coins: int)
signal mult_gained(slot: int, amount: float, reason: StringName)
signal grazed(slot: int)
signal kart_killed(victim_slot: int, killer_slot: int, cause: StringName)
signal kart_wounded(victim_slot: int, by_slot: int, cause: StringName)
signal life_restored(slot: int)
signal kart_respawned(slot: int)
signal death_banked(slot: int, amount: int)
signal bank_started(slot: int)
signal bank_tick(slot: int, points: int)
signal bank_completed(slot: int, coins: int, mult: float, total: int)
signal jackpot_collected(slot: int, coins: int)
signal jackpot_full(zone_index: int)
signal jackpot_emptied(zone_index: int)
signal item_picked(slot: int, item: StringName)
signal item_used(slot: int, item: StringName)
signal joker_offered(slot: int)
signal joker_taken(slot: int, joker: StringName)
signal match_state_changed(state: int)
## One tick of the starting clock, counting down to the flag.
signal countdown_tick(count: int)
signal bullet_fired(slot: int)
signal bullet_bounced
signal kart_bumped(slot: int)
## A kart into a wall. [code]hard[/code] separates a proper thump from a scrape along it.
signal kart_crashed(slot: int, hard: bool)
signal turbo_taken(slot: int)
signal nitro_started(slot: int)
signal nitro_gained(slot: int)
signal pad_claimed(slot: int)
signal flush_completed(slot: int)
signal bounty_called(slot: int)
signal bounty_claimed(killer_slot: int, victim_slot: int, amount: int)
signal bounty_lapsed(slot: int)
signal crate_destroyed
signal target_struck(slot: int, coins: int)
signal shield_popped(slot: int)
signal bomb_exploded(slot: int)
signal oil_hit(slot: int)
signal player_joined(slot: int)
signal player_left(slot: int)
