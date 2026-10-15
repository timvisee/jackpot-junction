extends Node
## Global gameplay signals. Autoloaded as `Events`.
##
## Gameplay code emits these; HUD, audio, tally and jokers listen. Gameplay never reaches into UI.
## Slots identify players and bots (0 to 3); -1 means nobody, for example a pit death.

signal coin_collected(slot: int, coins: int)
signal mult_gained(slot: int, amount: float, reason: StringName)
signal grazed(slot: int)
signal kart_killed(victim_slot: int, killer_slot: int, cause: StringName)
## Said just before a [signal kart_killed] that came about some way its cause does not say, for the
## kill feed, GAME.md 8.3: by the killer's decoy rather than the killer, and by a bullet that came
## off [param bounces] walls first.
signal kill_detailed(victim_slot: int, by_decoy: bool, bounces: int)
## The decoy of [param owner_slot] was destroyed, by [param by_slot] or nobody, as the kill feed
## says a kart's death, GAME.md 8.3. Not one that ran out of time.
signal decoy_destroyed(owner_slot: int, by_slot: int, cause: StringName)
signal kart_wounded(victim_slot: int, by_slot: int, cause: StringName)
signal life_restored(slot: int)
## [param joker] in [param slot]'s hand did something by itself just now, GAME.md 8.3, such as
## Guardian Angel spending the item on a hit: its card goes off in the hand with [param word] over
## it.
signal joker_went_off(slot: int, joker: StringName, word: String)
## [param joker] went from [param slot]'s hand by itself, used up, GAME.md 8.3, such as the Spare
## Tire a death takes: its card burns out of the hand with [param word] over it.
signal joker_used_up(slot: int, joker: StringName, word: String)
## [param slot]'s hand has just become Suited in [param suit], by [enum Joker.Suit], GAME.md 7.3.
## Only where the karts are run, for the Statistics page of 8.5.
signal hand_suited(slot: int, suit: int)
## [param slot]'s hand has just made [param hand], by [enum JokerHands.Hand], GAME.md 7.3. Only
## where the karts are run, for the Statistics page and the catalog's Hands, 8.8.
signal hand_made(slot: int, hand: int)
## Back on the floor, and where: a client hears this before the snapshot that puts the kart
## there, so anything drawn where it came back has to be told the place rather than look at it.
signal kart_respawned(slot: int, at: Vector3)
## The floor has gone from under a kart. The kill follows when it reaches the bottom.
signal kart_fell(slot: int)
## A pot split the way a death splits it, GAME.md 3.6, at a death or at the whistle, see 3.13:
## [param amount] banked and [param lost] gone, in points. Raised for any pot that had something in
## it, so a death that banks nothing still says what went.
signal death_banked(slot: int, amount: int, lost: int)
signal bank_started(slot: int)
signal bank_tick(slot: int, points: int)
signal bank_completed(slot: int, coins: int, mult: float, total: int)
signal jackpot_collected(slot: int, coins: int)
signal jackpot_full(zone_index: int)
signal jackpot_emptied(zone_index: int)
## [param slot]'s pick dealt its card [param index] again, GAME.md 3.7.
signal joker_rerolled(slot: int, index: int)
## A kart drove onto a slot machine, GAME.md 3.15, and bet [param bet] chips of its pot: the reels
## of pad [param pad] spin to [param faces], one byte a reel, by [enum SlotPad.Face]. Said by the
## host, which drew them, so every screen spins the same.
signal slot_spun(slot: int, pad: int, bet: int, faces: PackedByteArray)
## The reels stopped and paid [param won] chips into the pot, 0 for nothing.
signal slot_paid(slot: int, pad: int, won: int)
signal item_picked(slot: int, item: StringName)
signal item_used(slot: int, item: StringName)
signal joker_offered(slot: int)
signal joker_taken(slot: int, joker: StringName)
## A respawn pick of [param slot]'s was answered on this machine, GAME.md 3.7: [param joker] taken
## from it, or none for a skip. Never a pick of which joker to keep, 9.7.
## Heard only where the pick was answered, by the loyalty program's bets, 8.9.
signal joker_answered(slot: int, joker: StringName)
## [param joker] was destroyed out of [param slot]'s hand by its player, from the joker menu or
## given up at a full pick for the card taken, GAME.md 3.7. Heard only where it was done, by the
## loyalty program's bets, 8.9.
signal joker_destroyed(slot: int, joker: StringName)
## [param joker] was dropped out of [param slot]'s hand onto the floor for anyone to take, GAME.md
## 3.7. Heard by the loyalty program's bets, 8.9.
signal joker_left(slot: int, joker: StringName)
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
## The trigger pulled by a player at this machine with as many of their bullets in the air as their
## cannon allows, GAME.md 5.1: no shot, a dry click.
signal cannon_jammed(slot: int)
## A player put up an emote over their kart, GAME.md 3.8: an index into [constant EmoteArt.EMOTES].
signal emoted(slot: int, emote: int)
## Somebody watching put one up, with no kart to put it over: what they are called and which.
signal watcher_emoted(watcher: String, emote: int)
## Somebody watching at this machine asked the host to put one up, GAME.md 3.8: for Front Row,
## 8.10, which is this machine's own.
signal watched_emote(emote: int)
## A kart has been dressed on one of the lobby's stalls, GAME.md 9.6: the [param part] of it that
## changed, in [constant KartStyle.CHOICES] order, and all four as they now are.
signal kart_dressed(slot: int, part: int, style: PackedInt32Array)
## A shot landed on a kart that was there to be hit, shield or not: the shooter's, for their
## accuracy on the results screen, GAME.md 3.8. The shooter's own harmless shot is not one.
signal kart_shot(victim_slot: int, by_slot: int)
signal bullet_bounced
## Two bullets of different karts met and took each other out of the air, GAME.md 5.1: their
## owners'. Only the host ever sees it, a client's bullets being dead reckoned, so it says so.
signal bullets_met(slot_a: int, slot_b: int)
## A bullet landed on a wall, GAME.md 8.3, with the surface normal and the shooter's color, so
## the arena can leave a mark there. An event rather than something the bullet does itself
## because a client's bullets are dead reckoned and never touch anything, GAME.md 10.3.
signal bullet_struck(at: Vector3, normal: Vector3, color: Color)
## A bullet stopped harmlessly on a kart that cannot be hurt just then, GAME.md 3.6, at [param at].
signal bullet_deflected(at: Vector3, color: Color)
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
## A player in the waiting room moved to [param team], from their corner or their switch, GAME.md
## 3.14 and 9.6: decided by the host and told, so the puff of it goes up on every screen.
signal team_joined(slot: int, team: int)
## The host showed [param named] out for sending what no copy of the game sends, GAME.md 10.3, see
## [NetConduct]: said quietly on everybody's screen.
signal player_kicked(named: String)
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
## A room being put up has done [param done] of its phases, from 0 to 1, GAME.md 8.6: how far a
## dedicated server's game is along, for the player waiting for it, 9.3a.
signal room_building(done: float)
## A map of a Grand Prix has been scored, GAME.md 9.7, and this is the whole run as it stands.
## The host scores it; a client is told, and draws its podiums from what it is told.
signal grand_prix_scored(run: Dictionary)
## A profile kept on this machine earned an achievement, GAME.md 8.10: the profile's id, the
## achievement's, and the seat it was earned at, or -1 for none. The toast is what hears it.
signal achievement_earned(profile_id: String, id: StringName, slot: int)
