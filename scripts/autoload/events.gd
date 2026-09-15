extends Node
## Global gameplay signals. Autoloaded as `Events`.
##
## Gameplay code emits these; HUD, audio, tally and jokers listen. Gameplay never reaches into UI.
## Slots identify players and bots (0 to 3); -1 means nobody, for example a pit death.

signal coin_collected(slot: int, coins: int)
signal mult_gained(slot: int, amount: float, reason: StringName)
signal grazed(slot: int)
signal kart_killed(victim_slot: int, killer_slot: int, cause: StringName)
signal kart_respawned(slot: int)
signal bank_started(slot: int)
signal bank_completed(slot: int, amount: int)
signal jackpot_collected(slot: int, coins: int)
signal jackpot_full(zone_index: int)
signal item_picked(slot: int, item: StringName)
signal item_used(slot: int, item: StringName)
signal joker_offered(slot: int)
signal joker_taken(slot: int, joker: StringName)
signal match_state_changed(state: int)
