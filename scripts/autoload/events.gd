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
## Back on the floor, and where: a client hears this before the snapshot that puts the kart
## there, so anything drawn where it came back has to be told the place rather than look at it.
signal kart_respawned(slot: int, at: Vector3)
## The floor has gone from under a kart. The kill follows when it reaches the bottom.
signal kart_fell(slot: int)
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
## The flag dropping at the end of a countdown, GAME.md 8.3. A room that holds nobody on a grid,
## such as the Garage, never sends this: there is no flag where there was no countdown.
signal countdown_done
## The table threw a joker onto the floor because the room is hot, GAME.md 3.11.
signal wild_joker_dropped(joker_id: StringName)
## The announcer called something, GAME.md 3.12: a run of kills, a streak or a trade.
signal announced(slot: int, call: String)
signal bullet_fired(slot: int)
## A player put up an emote over their kart, GAME.md 3.8: an index into [constant EmoteArt.EMOTES].
signal emoted(slot: int, emote: int)
## Somebody watching put one up, with no kart to put it over: what they are called and which.
signal watcher_emoted(watcher: String, emote: int)
## A kart has been dressed on one of the lobby's stalls, GAME.md 9.6: the [param part] of it that
## changed, in [constant KartStyle.CHOICES] order, and all four as they now are.
signal kart_dressed(slot: int, part: int, style: PackedInt32Array)
## A shot landed on a kart that was there to be hit, shield or not: the shooter's, for their
## accuracy on the results screen, GAME.md 3.8. The shooter's own harmless shot is not one.
signal kart_shot(victim_slot: int, by_slot: int)
signal bullet_bounced
## A bullet landed on a wall, GAME.md 8.3, with the surface normal and the shooter's color, so
## the arena can leave a mark there. An event rather than something the bullet does itself
## because a client's bullets are dead reckoned and never touch anything, GAME.md 10.3.
signal bullet_struck(at: Vector3, normal: Vector3, color: Color)
signal kart_bumped(slot: int)
## A kart into a wall. [code]force[/code] is 0 for the lightest contact worth hearing at all
## and 1 for a flat-out shunt, so a scrape and a proper thump are not the same sound.
signal kart_crashed(slot: int, force: float)
signal turbo_taken(slot: int)
## A drift ended having earned its exit boost. Only raised for the kart being driven here: it
## is a receipt for the driver, and every kart in the room earning one is a racket.
signal drift_boosted(slot: int)
## This machine's own kart was put back where the host had it, GAME.md 10.3: how far it moved and
## whether it was too far to hide. Never leaves the machine it happened on; nobody else's picture
## changed and nobody else needs telling.
signal kart_corrected(meters: float, snapped: bool)
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
## A player in the waiting room of GAME.md 9.6 has said they are ready, by holding the pad long
## enough, or has taken it back by driving off it. The host works this out, since it is the host
## that simulates every kart; clients are told, so the tick over a kart and the count at the top
## of the screen say the same thing in every room at once.
signal player_ready(slot: int, ready: bool)
## The host of a waiting room has said what the next match is going to be, in words, or that they
## are still choosing it, GAME.md 9.6. Said again whenever somebody joins, so nobody who arrives
## while it is being chosen is left not knowing.
signal match_planned(summary: String, choosing: bool)
## And how many bots the host has asked for in it, before the seats left in the arena cap it, and
## how many players the room may hold, GAME.md 9.6: the room says how many bots will come in with
## the players, and whether there is a seat left to take. Said alongside the plan.
signal room_planned(bots: int, seats: int)
## A map of a Grand Prix has been scored, GAME.md 9.7, and this is the whole run as it stands.
## The host scores it; a client is told, and draws its podiums from what it is told.
signal grand_prix_scored(run: Dictionary)
