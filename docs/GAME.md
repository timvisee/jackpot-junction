# Jackpot Junction

This document describes the game Jackpot Junction: its gameplay, mechanics,
presentation, technology and roadmap. It is the source of truth for
implementation and will be updated as development progresses with new ideas,
decisions and features.

Unless stated otherwise, every number in this document is a starting value for
tuning, not a fixed rule. Tuning happens in playtests. When a number changes in
the game, update it here.

## 1. Vision

Jackpot Junction is a top-down arena kart game for 1 to 4 players at one
screen, and up to 8 online, in which every life is a hand of cards. You drive a small, drifty kart through a
bullet-filled toy diorama, collect poker-chip coins and multipliers, and decide
when to drive to the Junction in the center of the arena to cash your pot out.
Cashing out takes up to a few seconds, during which you are exposed. Dying banks
only half.

It is a relatively small but polished arcade game with no fixed deadline. It
is built in stages: single-player against bots first, then local shared-screen
multiplayer, then online multiplayer.

### 1.1 Design pillars

1. **Push your luck.** Everything you hold can be lost. Banking is a decision,
   not an event, and bigger pots take longer to bank.
2. **Readable chaos.** One screen, muted floor, bright color-coded bullets.
   You should always be able to see why you died.
3. **Drive like a toy.** Karts are agile, drift satisfyingly, leave tire marks
   and smoke. Aim is forward-only, so driving is the core skill.
4. **Every life is a hand.** Coins times mult, bent by jokers, paid out with a
   big tally. Balatro on wheels.

### 1.2 Inspiration

- Wii Tanks (Wii Play): arena layout, diorama look, camera angle, bouncing
  bullets, forward-only firing with a limited number of live bullets.
- Balatro: coins times mult scoring, jokers that bend the rules, the tally.
- Bullet hell: grazing, dense but readable bullet patterns.
- Mario Kart: held items used on a button press, turbo pads.

### 1.3 Story

Under the casino there is a story, and it is told the way everything else in the game is: in what
the house prints, paints and says, with no story mode of its own. A player who ignores it plays
exactly the game this document describes; one who reads the small print finds out who runs the
house, and the Final Hand of 8.7 ends it for everybody in a way nobody can miss. Nothing in it
changes a rule, a number or what anything is called, but for the Final Hand, whose room the house
rearranges while it is played, and five cards of Kit's that the story deals now and then, 3.7; a
player who wants none of it can switch it off, 8.5. STORY.md is its source: the world, the twist,
every line it prints and when, and the notes a player finds. A section of this document the story
reaches says so and names the section of STORY.md, and STORY.md names this one back.

## 2. Core loop

What a player picks up and carries in the pot are called chips on every screen, in every card
and lesson: they are poker chips, and the game used to call the same thing chips in one place,
coins in another and points in a third. Points are the banked score, a pot's chips times its
mult. This document and the code call the chips coins in places, `coins` in the pot and the
stats; a player never reads that word.

Within a life:

1. Spawn with an empty pot: 0 coins, mult 1.
2. Collect coins from coin pads, crates, the Jackpot zone and other players'
   drops.
3. Raise your mult by killing karts and grazing bullets.
4. Decide when to drive to the Junction and cash out. The pot drains into your
   banked score at a rate that ramps up, so small pots bank in under a second
   and huge pots take several seconds, during which you are exposed.
5. The pot resets. Repeat.

On death:

1. Half of your pot value is banked. Some of your coins, and maybe a joker or
   your held power-up, drop on the floor for anyone to take.
2. During the respawn delay you pick 1 of 3 jokers, or skip.
3. You respawn far from enemies with 2 s of protection.

A match lasts 5 minutes or until someone banks the target score, or a team, 3.14. A cash-out that
crosses the target runs to its last coin first, so its player collects the whole
pot rather than whatever was in it at the moment it went over; the match carries
on round them meanwhile, and ends the moment that cash-out is done or stops, the
kart driven off the Junction or killed on it. The final 30 s
are Last Call: the Junction pays double. When the timer ends, a pot still being
carried banks what a death would bank of it, unless the match plays on for the
last one standing, see 3.13. The highest banked score wins, counted once the
last of it is in.

## 3. Rules

Everything in this section is a rule of the game rather than of one machine:
all of it applies in single-player, in shared-screen and online alike, and
10.3 says what that costs and how it is paid.

### 3.1 Pot and score

Each player has:

- **Coins**: integer, starts at 0 each life.
- **Mult**: number, starts at 1 each life. Can be fractional, since grazes give
  +0.5.
- **Pot value**: coins times mult, rounded down whenever it is banked.
- **Banked score**: the only thing that counts at the end of the match.

### 3.2 Coins

| Item         | Effect   | Source                                             |
|--------------|----------|----------------------------------------------------|
| Chip         | +1 coin  | Coin pads, crates, death drops, Jackpot zone       |
| Gold chip    | +5 coins | 5% of coin pad spawns, 10% of crate drops          |
| Mult die     | +1 mult  | 8% of coin pad spawns, instead of a chip           |
| Dropped chip | +1 coin  | Death drops, vanishes after 15 s                   |

| Parameter                       | Starting value                          |
|---------------------------------|-----------------------------------------|
| Coin pads in the first map      | 12                                      |
| Coin pad respawn                | 5 s after pickup                        |
| Pickup radius                   | 0.9 m from kart center                  |
| Crates in the first map         | 8                                       |
| Crate                           | destroyed by 1 bullet, drops 2 to 4 chips, respawns after 30 s |

### 3.3 Mult

| Event         | Effect    | Notes                                                       |
|---------------|-----------|-------------------------------------------------------------|
| Kill          | +1 mult   | Credited to the owner if a turret or decoy made the kill    |
| Graze         | +0.5 mult | Enemy bullet passes within 0.6 m of your hitbox without hitting. Awarded when it leaves the graze area. Cooldown 0.3 s per player |
| Mult die      | +1 mult   | Pickup                                                      |
| Death         | reset     | Mult back to 1                                              |
| Full cash-out | reset     | Mult back to 1                                              |

Mult does not decay. Bullets from your own kart, turrets or decoys never count
as grazes.

### 3.4 The Junction: cashing out

The Junction is a pad in the center of the arena. Banking is a channel with a
ramping drain. While a kart is inside the pad, its pot value drains into its
banked score at a rate that grows the longer the kart stays:

```
rate(t)   = R0 * 2^(t / D)                   points per second
banked(t) = R0 * D / ln(2) * (2^(t / D) - 1) points banked after t seconds
R0 = 40 points per second, D = 0.5 s
```

- `t` is the time spent continuously on the pad. Leaving the pad resets `t`
  to 0. What is already banked stays banked.
- Draining removes points from the pot value. The remaining coin count is
  derived as `ceil(remaining value / mult)`. Mult is untouched until the pot is
  empty, so leaving early keeps your mult.
- When the pot is empty: coins reset to 0, mult to 1, and the tally plays.
- During Last Call every banked point counts double.
- The Junction is always open. A pulsing variant is in the ideas backlog.
- The neon ring blinks when a player on this screen is carrying an unbanked pot
  worth 250 or more, brighter and quicker the bigger the pot, up to a fortune of
  1200. It only nudges; the pad behaves the same either way.
- A pot that would win the match takes the ring over: banked plus what cashing
  the pot in would bank at or past the target score. That is what the Junction
  would really pay, not the pot's bare worth: the pot times whatever the kart's
  jokers pay on a cash-out, Glass Jackpot's half again for every copy, and times
  the Junction's own payout, which Last Call doubles. With a target of 3000, a pot
  of 2000 under Glass Jackpot already wins. The ring stops climbing the same scale
  and goes flat gold, on
  and off three times a second. That is a different thing to say, so it is said
  a different way rather than as more of the first. The same pot blinks as the
  `+N` beside its owner's score in the running order, for every player rather
  than only the ones on this screen: somebody else one cash-out from ending it is
  worth knowing about. The moment a pot gets there it is called out on every
  screen, its owner's own, their rivals' and a watcher's, the announcer's way
  under the middle of the screen, their name and MATCH POINT in their color,
  once, and not again for the same player for ten seconds however the pot hovers
  on the line. The room climbs for it too, 8.4. Each machine sees it from the pots
  and the banked scores it already has, so nothing more is sent. A room with no
  target has nothing to win, whatever is in a pot. It sets its owner alight as
  well. In their corner of the
  HUD the chips pill and the mult pill each go solid in their own color, with a
  pale rim and a glow of that color round them flickering with the fire, and
  shiver, snapping to a new small tilt many times a second and now and then
  jolting bigger and settling back, as if straining to hold the heat in, and a
  sheet of fire in that color climbs off each, blue off
  the chips and red off the mult, in four bands with clean, smooth edges between
  them: a white heat deep in it, a pale core, a light shade of the pill's color
  and a darker rim, every band brighter than the pill so the fire glows against
  it. It
  is cut from noise that rolls upward and folds over itself, finer across than up,
  so it burns in tall narrow tongues that sway more the higher they reach, split,
  and throw off scraps that rise and go out, with a few round sparks climbing out
  of the top. It climbs up over the banked score above the pills, and a tongue
  that climbs high burns out smoothly on the way rather than being cut off flat,
  as it is kept clear of the sides it sways towards. The total goes gold. Their
  kart lays gold tracks for everybody to see, see 4.3: a bright gold ribbon under
  each rear wheel, a little wider than a plain mark, that holds for a moment and
  fades out two seconds behind the kart, a short trail rather than the table
  painted gold, leaving the ordinary marks under it. Faint, as they first were,
  they went unseen on the felt and all but vanished on the driving school's pale
  floor; twice a plain mark's width, as they were next, they were too heavy. Every machine works it out from the banked scores and pots it
  already has, so nothing more goes over the wire for it. Last Call pays double, so the blink comes on no later than it has to and
  never promises a win it cannot pay.
- Standing on the Junction patches a wounded kart up to two lives, see 3.6, but a
  pot has to go in first: the life comes with the last coin of the cash-out, which
  is exactly when the kart is most worth shooting. A kart that rolls on with
  nothing to bank is owed the life straight away.
- Nitro refills 4x as fast while a kart stands on the pad, on top of whatever the
  hot table is already giving it. Cashing out parks a kart still and in the open
  in the middle of the arena for a couple of seconds, which is the moment it most
  needs something to leave with; a full tank is also what makes coming back worth
  it. A client works this out for itself, see 10.3: the pad is in the same place
  on both machines, so who is standing on it needs no round trip.
- The pad has one life to give every 3 seconds per kart, and the wait runs whether
  the kart stays or leaves and comes back. Otherwise a kart parked on the Junction
  is patched up the instant it is wounded and can never be finished off in the
  middle of the arena, which is the one place everybody has to come to.

Time to fully bank a pot with the starting values:

| Pot value | Time on pad |
|-----------|-------------|
| 50        | 0.7 s       |
| 100       | 1.1 s       |
| 250       | 1.6 s       |
| 500       | 2.1 s       |
| 1000      | 2.6 s       |
| 2500      | 3.2 s       |
| 5000      | 3.7 s       |

### 3.5 The Jackpot: a bank that grows

The Jackpot is a zone that accumulates chips over time. A single kart standing
in it collects the pile into its pot. It is the mirror image of the Junction:
you gain there, you bank at the Junction, and the distance between the two is
the tension.

| Parameter        | Starting value                                                  |
|------------------|-----------------------------------------------------------------|
| Zones            | 2 predefined spots in the map, one active at a time             |
| Accrual          | +1 chip per second while active, capped at 60 chips             |
| Collection rate  | `2 * 2^(t / 0.5)` chips per second into the pot of the kart inside, `t` resets on leaving |
| Contested        | 2 or more karts inside: collection pauses for everyone; teammates do not contest each other, 3.14 |
| Emptied          | Zone deactivates; the other zone activates with 0 chips         |
| Heat             | Accrual and the cap both run with the excitement level of 8.4: at level 6 the pile fills three times as fast and may grow to twice as many chips |
| Last Call        | Accrual doubles, on top of the heat                              |
| Signal           | Traffic light on the zone: red below 20 chips, amber below 60, flashing green when full |
| Collecting       | The kart wears the progress ring of 8.3, full when it drives on and gone when the pile is. The counter is painted on the tile the kart is parked on, so the ring is the only part of it a collector can see |
| Cleared          | A handful of gold thrown up off the tile the moment the pile goes, on every screen |

A full pile of 60 chips takes about 2.7 s to collect. Chips from the Jackpot
are plain chips and multiply with your mult like any other.

### 3.6 Death

A kart has two lives. A bullet hit, a bomb blast or a ram by a kart with an
active Boost or burning nitro takes one. With a life to spare the kart limps
on: darker, at 85% top speed, blinking and untouchable for 1.2 s, so a burst of
bullets cannot take both lives in the same moment. Untouchable is for the lives
only: a ram still knocks coins out of the pot, see 4.1. Standing on the Junction with
an empty pot restores the lost life, and so does banking a pot dry there, see 3.4;
so does taking somebody out. A joker can add a life, Spare Tire and Scar Tissue in
7.3, each one more on top of the two, there the moment the card is taken rather
than a wound, with a heart more under the player's name; healing fills them too,
unless the card says nothing heals, and coming back always does.
Losing the last life is death. A kart that drives into a pit falls for 0.4 s,
uncontrollable, and dies whatever its lives. On death, in this order:

1. **Drop coins**: `floor(0.3 * coins)` chips, at most 10, leave the pot and
   scatter up to 3.2 m around the death spot, and vanish after 15 s. A killer
   with Pickpocket takes its share of the coins first, into its own pot.
2. **Bank half of what is left**: `floor(0.5 * coins left * mult)` is added to
   banked score. What drops is gone from the pot before any of it banks, so
   Insurance Policy banks all that is left rather than all there was, and Tight
   Grip, which lets nothing drop, keeps the whole pot to be banked.
3. **Drop items**: 20% chance that one random held joker drops. 50% chance
   that the held power-up drops, both a couple of meters clear of the wreck.
   Floor items vanish after 15 s.
4. **Mind the holes**: anything that lands over a pit, chips and items alike,
   drops into it, shrinking as it goes, and is gone. It cannot be picked up on
   the way down.
5. **Credit the killer**: +1 mult. Turret and decoy kills credit their owner.
   Pit deaths credit the last kart that bumped the victim within 2 s. Self kills
   credit nobody.
6. **Reset the pot**: coins 0, mult 1.
7. **Respawn** after 3 s at the spawn point farthest from any enemy, with 2 s
   of spawn protection: invulnerable and cannot fire; another player's bullet
   stops on it, spent and harmless, with a small flash of its color on every
   screen, rather than going on through as if nobody were there, which read as
   a kart that was not; the same goes for the blink after a wound. Its own
   shots pass through it, and anybody's through a kart gone down a hole; a ram
   still knocks coins loose, see 4.1, though a pot just reset has none. Picking
   up coins and items is allowed. Coming back opens a ring across the floor in
   the player's color with a column of light standing in it, gone inside a
   second. The blinking says something about that kart to whoever is already
   looking at it; the flare says to the whole room that somebody is back, and
   where.

Every screen shows how the pot split, since a number over a wreck saying half was
banked left a player to work out what became of the rest. The share that banks
leaves the wreck as a stream of gold coins, a coin for every 15 points or so and
never fewer than 3 nor more than 12, drawn in toward that player's banked score,
in their corner of the screen if they play at this one and on their row of the
standings if not, and +N in gold says how much beside the score as the first coin
lands. The share that is lost is thrown into a trash can that comes up beside the
wreck, toward the middle of the screen: the coins go up and over one after another,
going gray on the way, and drop in behind the can's front, gone inside it rather than
landing on top of it; the can bumps as each goes in, −N in red rises over it as the
first goes in, and it shuts its lid once the last has and fades, a couple of seconds
all told. Coins that crumbled to dust where they fell were gone before anybody saw
they were lost. The can is for the players at this screen alone: one over every
bot's wreck and every other machine's player's said more than anybody wanted, and
what those bank still flies to their rows of the standings. It is drawn under the
rest of the HUD, the corners, the standings and the joker pick, where a coin flying
into a score is drawn over it. A death that banks all that is left,
with Insurance Policy, has nothing to crumble, and one that banks nothing, with
High Roller, sends nothing to the score. The chips dropped in step 1 are real chips
on the floor, and scatter as ever.

### 3.7 Jokers

Jokers are passive rule modifiers held for the rest of the match.

- On every respawn the player is offered 3 jokers during the respawn delay and
  picks 1 or skips. Offers never include a joker the player already holds,
  except a joker that stacks, until the stack is at its most, see 7.3. So no
  card on offer would do nothing if taken, and the pick has nothing to warn of.
- Once a pick, the card under the cursor may be dealt again for 50 banked
  points, a slot machine's spin of the pick: the nitro key, Ctrl or a pad's
  right shoulder, there being no kart to burn it in, said in the pick's hints as
  reroll -50, or the Reroll button beside Skip on a touch screen. The new card is
  dealt as a pick deals, leaning to the hand's suit, 7.3, and is never the card it
  takes the place of nor another the pick shows; it turns over from its back where
  that one was, with the shuffle of the deck and a rattle of dice. Not in a keep
  pick, 9.7, nor with fewer than 50 points banked, and a bot never does. At a
  client the card is named for the host, which deals it and takes the points.
- A player holds at most as many jokers as the match's Joker slots, 5 to start
  with and 3 to 8 in the match settings, unless a joker in the hand says
  otherwise: Deep Pockets adds 2 slots to however many that is and stands in one
  of them. Online it is the host's number, sent with the rest of its settings. A player with a full hand
  who wants a new one must first destroy or drop one: at the respawn pick,
  choosing a joker to discard destroys it; in the arena, the joker menu lets you
  drop one on the floor or destroy it.
- Jokers can drop on death, see 3.6. A joker on the floor can be picked up by
  any kart, including its previous owner, for 15 s. A kart whose hand already
  holds it leaves it lying for somebody else, unless it stacks and the stack has
  room: a second copy of a joker that does not stack was the same joker twice,
  and Carbon Copy made one at every death.
- Players start a match with no jokers. The first offer comes with the first
  death.
- An offer still open at the whistle is dropped. Nobody respawns out of the
  results, so there is nothing left for the pick to be for, and leaving it up
  would put an unusable card over the standings.
- The offer stays open until the player picks or skips. Respawn waits for the
  choice, but never happens before the 3 s delay has passed. The match keeps
  running meanwhile.
- Nothing can be taken, skipped or destroyed for the first 0.5 s the cards are up.
  A player is killed with a thumb on the trigger and the pick opens under that same
  thumb, so the card under the cursor was being claimed before anybody had read a
  word of it. The cursor walks the whole time: which card somebody is looking at
  was never the problem. A button held down through the wait is not counted as
  pressed when it ends, which is the press this is here to stop. The cards come in face down,
  wearing the card back of 8.9, and turn over inside that half second, so the wait looks like a
  deal rather than a delay.
- The joker menu can be opened while driving; the kart stays fully
  controllable.
- It opens while dead as well, and a player waiting to come back is the player
  with time to read their hand. Dropping and destroying are the two things it
  will not do then: there is no kart to drop a card from, and the respawn pick is
  already asking what is worth keeping. The pane says as much, and offers the
  cursor alone while the kart is down: a button drawn under a card that does
  nothing when pressed reads as the game having stopped listening.
- Menu controls: steer left and right, the bracket keys or the D-pad walk the
  cursor, number keys pick directly, the drop button lays the card on the floor,
  the destroy button burns it. Steering picks cards so that whatever the player
  already drives with, arrow keys or stick, chooses a card too; the kart steers
  along with it, and a held direction moves one card rather than racing through
  the hand.
- Bots pick jokers at random, weighted by rarity, and never skip.
- The offer is a row of joker cards in the middle of the player's share of the
  screen, the card under the cursor lifted, lit and described underneath.
- With a full hand the card under the cursor is the one about to be thrown away,
  so it wears a red frame and a big red cross rather than the gold frame a card
  being claimed wears.
- Offer controls: steer left and right, the bracket keys or the D-pad move the
  cursor, number keys pick directly, the item button takes, the destroy button
  skips. With a full hand the same controls pick the joker to destroy, and the
  destroy button goes back. The skipping is a chip at the far end of the pane's
  line, the key or the pad's button that does it and skip or back beside it in a
  thin frame of their own, brighter than the hints round them: a player who had
  not read to the end of the small print did not know a pick could be turned
  down, and the big button under the pane it once was took a fifth of the screen
  at a big UI scale. A click on it skips as well. On a touch screen it is a
  button under the pane, a finger's size.
- Holding the joker menu's button over a pick, Tab or Y, reads the hand instead,
  read the way 3.7 reads it: the pick steps aside, the hand comes up at its
  full size with its cursor and its pane, and the pick takes, skips and walks
  nothing while it is held; let go, the pick is back as it was. The pane's line
  says so, "hand" beside the button, whenever there is a hand to read.
- Offer weights by rarity: common 60%, uncommon 30%, rare 10%.
- An offer is dealt from the table's deck: the twenty cards every deck starts with and those the
  loyalty program of 8.9 has added for the profile playing, or online for the host. Every seat
  and every bot at a table is dealt from the same deck, and the rarities are weighed among the
  cards it holds.
- From the story's first stage, 8.7, a line of small print runs under the cards of the pick, NEW
  TERMS AVAILABLE and what follows it in STORY.md 6.3. It says nothing about the offer that is not
  true: the cards are dealt by rarity as ever. From the first stage it reads TERMS ACCEPTED for
  as long as a card taken takes to fly into the hand, which is what the story's achievement Terms
  Accepted is named for, 8.10 and STORY.md 8.7. A pick skipped is counted in the profile as terms
  declined, which the story prints later, STORY.md 6.3.
- Once the story has had its first note found, 8.7, a pick may hold one of Kit's cards in place of
  one of the house's: five jokers drawn in pencil, each with a cost, 7.3. The host deals them, one
  pick in five and at most once a map, one pick in three after the story's ending, never at the
  Final Hand and never to a bot, for a seat that has told it, when it joined, that it may have them,
  one flag sent as the loyalty program's unlocks are, 8.9. They are in every machine's catalog so
  any machine can read one, never in the deck the program deals, never on the catalog's pages of 8.8
  and never counted for Full Deck. Taken, the pick shows a pencil tick rather than TERMS ACCEPTED.
  STORY.md 6.3.

The joker catalog is in section 7.3.

### 3.8 Match

| Parameter       | Starting value                                            |
|-----------------|-----------------------------------------------------------|
| Duration        | 5:00                                                      |
| Target score    | 3000 banked ends the match early                          |
| Last Call       | Final 30 s: Junction pays double, Jackpot accrues double  |
| Time out        | Sudden death, see 3.13, unless the lobby option turns it off; then every pot still carried banks what a death would bank of it |
| Countdown       | 3 s before the karts can move                             |
| Players         | 1 to 4 humans at one machine and up to 8 online, see 9.3, with as many bots as the match settings ask for that there are seats for |
| Tie-break       | Most kills, then fewest deaths                            |
| Names           | 1 to 16 characters each, or one off the funny list for anybody who does not set one |
| Driving         | Simple or advanced per player, see 4.2                    |

Flow: Title screen, Lobby, Countdown, Playing, Last Call, Overtime, Results. At the
whistle nobody is stopped dead: every driver lets go of the wheel and the karts
roll to a halt on their own, out of anyone's control and out of reach of pits,
hazards and the Junction alike, while the rig swings onto the winner and
fireworks go up over the table in their color. That is the
end of the match and it is left to itself: the podium waits two and a half seconds
before it comes up, and the hand of cards stays where it is until it does, because
a scoreboard thrown over the top of a kart still rolling takes the ending away from
the people who were in it. The music steps back 9 dB over 0.8 s as the screen
arrives and comes back up when the room does. Results show every player's banked
score and kills, ranked, then offer Rematch, Back to lobby and Back to title (in a
Grand Prix, the next map instead, see 9.7), on one machine and for a LAN host alike:
the lobby on one machine is Play's, and online it is the waiting room everybody
goes back to together. The cursor is already on Rematch on one machine and on Back
to lobby for a LAN host, whose room of people wanting another go goes there next:
the screen arrives on its own rather than being opened,
so it points at what most people want next instead of waiting to be found. A client,
which does not get to decide there is another match, is pointed at the way out.

The title compiles the game's shaders behind itself the first time this build
of the game runs on this machine, see 10.7, and says so in a pane over the whole
title, the license too, on a shade: "Preparing", "Compiling shaders, please
wait...", a gold bar with how far along it is in percent beside it, and Skip,
which has the cursor and keeps it. The menu is out of reach until the bar is full,
when the pane fades away by itself and the cursor goes to Play, or until Skip, or
Back, stops it, whatever was not compiled then compiled the old way, on first use,
and the pane up again at the next start, since nothing was kept. It was a thin
bar in a corner with the menu answering throughout, which was missed, and the
first match stuttered. Once through, it leaves a stamp, and the next start has
nothing to compile and shows no pane, until a new version, another graphics card
or a cleared cache.

The screen is a payout slip, 8.1a, headed Payout slip, and opens with a podium framed as the
photo on the license is: the top three on three steps, the winner
in the middle on the tallest, second a little lower on one side and third lowest
on the other, each with their own kart standing on top of it turning slowly on the
spot, starting just short of looking at the camera so it looks straight out half a
second after the podium comes up, each with the plate it wore in the match on its back, the learner's L or a
license plate, a bot's too, see 4.4, its wheels on its step. It is a small 3D scene of its own rather than a picture, lit by its own
light in a world of its own so nothing of the arena behind it leaks in, and taken against a stage
at night drawn behind it: dark overhead and warmer toward the floor, the casino's lights far behind
it out of focus, soft discs of gold, warm white and red each glowing up and fading slowly in its own
time; velvet curtains either side in broad rounded folds with a sheen down each, casting a shadow
on the stage, gathered by a twisted gold cord with a tassel, under a pelmet of swags draped in
pleats and fringed in gold; and lit as the House's invitation is, STORY.md 6.1a, by two lamps just
off its top, as far either side of the winner's step as each other, their soft beams a matched pair
crossing onto it, wherever it stands in the picture, beside the middle on a podium of two, and a
pool of their light on the floor under it,
the light breathing slowly up and down over seven seconds. It is drawn once and only faded after:
the curtains are one array of triangles drawn into a picture of their own at the screen's own
pixels, smoothed, and shown as one sprite; the far lights are sprites of one disc; and what moves
is their modulate and the light's. A plain dark back made the winners look as if they had been
photographed for a form, and a turning sunburst behind them was too busy for the picture. A match of
two fills two steps.

Below it, with air between the picture and the list, the slip is printed as a
receipt: cream paper torn off the house's printer, the winner's color in the hairline
inside its edge. Each player gets a line of their own rather than a line of text,
with their place on a chip of their color and their name in it, darkened to read on
paper, a bot's with the robot's head after it as in the room's standings, dotted leaders across to what they banked on the right, their kills and
deaths in gray, and a dashed rule under the line. The line of whoever is reading the
slip is marked in foil, the way a line is with a highlighter, and the winner's is
stamped WINNER with the driving test's red rubber stamp. Lines level on what they banked say what
put them in order, since the order alone does not: each carries a chip naming the tie-break of the
table above that decided it and what that line had of it, `Tie · 5 kills` over `Tie · 3 kills`, or
`Tie · 1 death` once the kills are level too.

The slip is one long bill, its pages printed one under another, each past a perforation and
headed as it is: the map just played, then in a Grand Prix how the run stands, 9.7, with no photo
finish of its own, the run's podium being the finale's in the room, and at the
Final Hand the house's evaluation, STORY.md 8.4. It is torn off the printer at the top of the
whole bill and at its foot, and a barcode of the match's number and the small print close it, at
the foot of the last page only. A page shorter than the longest is paper left blank at its foot,
so every page stands the same. The bill runs down the middle of the screen and off it, and is
scrolled over rather than paged through: it runs straight off the top of the screen, and fades out
over the ways on at the foot, so the paper goes under them rather than being cut, its torn edges
going with it. Turning the page brings the next one to the middle of the screen in a short scroll.
Over the bill's left edge, reaching onto its margin and no further, clear of the standings down
the right of the screen, the pages' arrows stand upright in foil, up and down, with a dot for each
page between them on a pill of the house's dark and the page in view lit in gold; an arrow with
no page that way is out of sight. On a touch screen they stand beside a bill that does not fit the
screen too, one long page and all, and step down it as the keys do, the rest of a page first, a
screen at a time, then the next, each out of sight only where there is nothing more that way. The cursor starts on the arrow down while there is a page under
the one in view, so a press goes on down the bill, and goes to the way on under the bill once the
last page is in view, and back to the arrow down on the way back up, unless it was taken
elsewhere. Up and down turn the pages too, on the keys, a pad's cross or its stick, a push of the
stick a page; a page taller than the screen shows the rest of itself first. The shoulders and Page
Up and Page Down turn them as well, and the arrows' binds hang on them while a pad or the keys are
in hand, 8.3. A wheel and a finger move the bill by hand, a finger wherever on the bill it is
put down, a line, the podium or a stamp, and a swipe let go carries it on a little, slowing; and a
pad's right stick scrolls it smoothly, faster the further it is pushed. The ways on stand on their own in a row
along the foot of the screen under the bill: the one that carries the match on, Rematch, Next map
or Continue, in foil, and the rest only ways out. Each page's podium is drawn only while it is in
view. The small print moves on with the story of 8.7, a second line joins it from the
story's second stage, from its third a line of microprint under the reader's own line says how the
house classified them, CLASSIFIED: HUNTER · PROFILE UPDATED, worked out from the match's own numbers
as the awards are, after the ending the slip is headed Payslip, and the Final Hand adds the house's
evaluation under the lines with the house's own stamp, and a tab to tear the page off by, in place
of
the ways on: STORY.md 6.2 and 8.4.
Offline, after a map in which one of the story's notes was taken, its folder peeks in beside the
slip and opens over it, STORY.md 7.2.
A screen narrower than the bill and its arrows, a phone's under a big UI scale, 8.5, has both
shrunk about the middle to the width there is. A room of more than four, 9.3, has its lines compact, smaller
lettering, a smaller chip and less air between them, the stamp lying over the line under
the winner's, so a slip of eight is
not twice as long as a slip of four. So does a short screen, under 820 of the interface's units
tall, a phone's under a big UI scale, whoever is in the room, and its podium is drawn at 62% of
its size, so more than a couple of lines fit under it. Under each player up to three awards, as
separate chips rather than run together into one sentence, say what they did that was worth
saying, `PlayerStats.deal`. Each award is earned by doing enough of a thing, its least, which a
figure everybody reaches never is: a mult that never left x1 is no Multiplier Maniac. A feat is
anybody's who did it enough; a contest only the one who did the most of it, the one placed higher
where two are level. The least of a total, shots fired say, is for a five-minute map and goes with
the length of the map played, a fifth of it for a one-minute map and up to four times it; the least
of a peak or a share, a cash-out or the mult or the accuracy, and of a feat, is what it is. The
awards are dealt in finishing order, the winner taking the most interesting of theirs, then the
second, and so on, then round again up to three, each title once on the slip, so a feat two players
earned is the higher placed one's; the most interesting is the highest tier, and within a tier the
one furthest over its least. A ribbing is dealt last and never to the winner; a player who earned
nothing has no chips. One of a thing is said as one, "1 graze".

| Award | Tier | Kind | What it counts | Least | With the map's length |
|---|---|---|---|---|---|
| Royal Flush | Headline | Feat | Flushes, 3.9 | 2 | No |
| Vault Cracker | Headline | Feat | Chips out of the Jackpot | 200 | No |
| Last Word | Headline | Feat | Places taken in sudden death, 3.13 | 1 | No |
| Pyrotechnician | Headline | Feat | Bomb kills | 2 | No |
| Bounty Hunter | Headline | Feat | Bounties collected, 3.6 | 2 | No |
| Big Spender | Headline | Feat | The biggest single cash-out | 1000 | No |
| Sharpshooter | Headline | Feat | Targets knocked down, 6.2 | 3 | No |
| Knocking on the Door | Headline | Feat | Match points, counted as they are called out, 3.4, so a pot hovering on the line is one | 2 | No |
| Marksman | Skill | Contest | Shots fired that landed on another kart, shield or not, as a share, of 15 shots at least | 50% | No |
| Multiplier Maniac | Skill | Contest | The peak mult | x6 | No |
| Close Shave | Skill | Contest | Grazes | 5 | Yes |
| Power Slide | Skill | Contest | Drifts carried to the boost | 5 | Yes |
| Battering Ram | Skill | Contest | Players rammed, once a ram, whether it popped a shield, took a life, killed or only knocked coins out | 3 | Yes |
| Card Counter | Skill | Contest | Flush pads taken | 25 | Yes |
| Sideways Specialist | Skill | Contest | Distance drifted | 150 m | Yes |
| Comeback Kid | Skill | Contest | Lives restored | 5 | Yes |
| Regular Customer | Busy | Contest | Cash-outs | 15 | Yes |
| Card Shark | Busy | Contest | Jokers taken | 8 | Yes |
| Gadgeteer | Busy | Contest | Items used | 5 | Yes |
| Nitro Junkie | Busy | Contest | Time on nitro | 15 s | Yes |
| Pad Hopper | Busy | Contest | Turbo pads | 10 | Yes |
| Demolition Crew | Busy | Contest | Crates broken | 10 | Yes |
| Vacuum Cleaner | Busy | Contest | Chips picked up | 500 | Yes |
| Trigger Happy | Busy | Contest | Shots fired | 80 | Yes |
| Road Warrior | Busy | Contest | Distance driven, and a fifth further than anybody else, since everybody drives | 1200 m | Yes |
| Crash Test Dummy | Ribbing | Contest | Deaths | 8 | Yes |
| Butterfingers | Ribbing | Contest | Chips lost | 300 | Yes |
| Piggy Bank | Ribbing | Contest | Chips dropped on the floor, at a death or knocked out by a ram | 80 | Yes |
| Spelunker | Ribbing | Contest | Pit falls | 3 | Yes |
| Own Goal | Ribbing | Contest | Self kills, a teammate's among them, 3.14 | 1 | No |
| Banana Skin | Ribbing | Contest | Spins on oil | 3 | Yes |

Butterfingers and Piggy Bank tell much the same story, the coins in a pot at a death being most of
what it drops there, so a player is given at most one of the two. Four more are counted for the
Statistics page of 8.5 alone and earn no award, the slip having enough to say: the longest drift,
the most kills in one life, bullets shot down, each of two bullets meeting one for its kart unless
both were one kart's, and the biggest pot carried. The leasts were set against
bots' matches and then for people: bots cash out every few seconds and never burn nitro. The list
follows the game: a
mechanic worth playing around is worth counting, so anything added to the floor
gets a line here, and a line here is counted the same on every machine in the
match. A statistic that only adds up on the host is a wrong number on somebody
else's results screen, see 10.3.

- **Names.** Every seat at a machine may set one, 1 to 16 characters, in a box of
  its own on the Seats tab of the settings, 8.5, remembered between sessions,
  or in the lobby and the Garage from its switch in the pause menu, 4.2 and 4.4,
  which keeps it in the same place.
  A seat that never sets one is handed a name off a
  list of silly ones when the match starts, and no two players in a room are ever
  handed the same one, because a results screen listing P1, P2, P3 and P4 says
  nothing about anybody. A name is trimmed, cut to length and stripped of square
  brackets on the way in, since the standings and the kill feed are drawn with
  BBCode and a name is a name rather than markup. Whoever is at the table keeps
  their name through a rematch. Bots are handed a robot's name off a list of their
  own that no player is ever given, robot slang and worse, Clanker, Rusty, Tin Can,
  Droid and the like, so a bot is told from a player at a glance down the standings,
  and dealt with the bot's way of driving and dress, the same all through a Grand
  Prix; somebody sitting down in a bot's seat goes by their own name, not the bot's.
  Practice dummies are named after what they are, so neither takes a name off
  anybody.
  Online the host owns every name in the room, as it owns everything else that
  decides what a player sees: a client says what it is called once its seat is
  assigned and the name reaches every screen in the snapshot, see 10.3. A client
  that says nothing is handed a funny name as it sits down in the lobby, and the
  host keeps it for them from room to room with their color, so the name they
  were called in the lobby is the name on every map and every podium. Somebody
  watching, 10.3, is named by the host as they knock: what they gave if nobody
  else in the game has it, and otherwise, or with nothing given, a funny name
  off a list of their own that nobody else has, from the furniture they are sat
  on and the seat they have in the stands: Couch Potato, Stool Pigeon, Front Row
  Fran. So a name under an emote floating up the screen says it is somebody
  watching before anybody reads the rim. It is kept off the lists while they
  watch, so nobody who comes after is handed it, and it is the name under their emotes and on the host's
  Manage players, whatever their own machine sends. A machine connects
  under its first seat's name, the settings' and the profile's, which the lobby's switch
  changes like any other; Play Online and LAN games ask for none, a box for it
  there being one more thing between the player and the list.
- **Profiles at other seats.** The first seat at a machine is the profile playing,
  8.5, and every other seat is that profile's guest, until its player sits in as
  another profile kept on the machine: Link profile on their switch in the pause
  menu, in any room or map, lists the profiles they can be, then Unlink when they
  are one, then Back. A linked seat is that profile at once: its name, its kart's
  dress, its plate or learner's L, its favorite color, 4.4, where nobody else in
  the room is in it, and how it drives, and whatever the seat changes of them is
  that profile's. It says so plainly: under the name on its switch, the
  profile's plate, or its L, and "Bob's profile", the button then reading Change
  profile; and on the Seats page of the settings, "Linked to Bob" beside the
  seat's row. The maps it plays to the whistle go into that
  profile's statistics. A profile sits at one seat at a time, never the profile
  playing and never the first seat; the button is only there when the machine
  keeps another profile, and a profile sat in cannot be deleted. Unlinked, a seat
  is a guest again, under its own name or a funny one. It is for the sitting
  alone: back at the title every seat is a guest again, and the profile playing is
  still the one it was. Online it works the same at a client, which says the
  name, the kart and the plate to the host as a seat says them sitting down.
  `SeatLink`, from `DriveSwitches`, through `Settings.link_seat`.
- **Emotes.** A player can put one of four up over their kart: GG, a smile, a
  scowl or a heart. Round, so a chip, 8.1a: a poker chip in their color with its
  notches, so it says who as well as what, with the emote printed in ink on a
  cream inlay in the middle of it, the way a casino's own chips carry its mark. On a pad the right stick held up, right, down or
  left picks them in that order, asked for as the stick is let go, and not while
  the stick is aiming a cannon that aims freely, which is what it is for then;
  on a keyboard they are 7, 8, 9 and 0, or V and then a way, W, D, S or A or the
  arrows, and on a touch screen a small button with a smile on it beside the
  menu button, 4.2, which opens a row of the four along the top of the screen.
  The wheel shows what there is: the four round the player's own kart, up,
  right, down and left, in their color, following the kart where it is drawn
  between physics ticks, as the item tag does, rather than stepping along with
  each tick and jumping about over a kart that glides. It comes up once the right stick is
  pushed past a third of the way and stays for as long as it is held off the
  middle, with the one it points at bigger and the others faint. Held at the edge
  on one, a ring round it fills over a quarter of a second; full, it is armed, bigger
  still and beating, and letting go asks for it: the stick back in the middle
  within a tenth of a second of leaving it, which a stick let go always is. A
  stick let go snaps back past the middle to the far side for a moment, and that
  is not a pick of the one there; when the wheel asked for whatever the stick
  pointed at last, that was often the far side, and a flick to the edge and
  straight back asked too. Moved off the armed one slower than that, onto another
  or back toward the middle, is changing one's mind, and asks for nothing; so is
  letting go before the ring is full, or from short of the edge, so a player can
  bring the wheel up to look at it and think better of it. And for three seconds after V, with the key for each way beside it, the
  four ways picking from it rather than driving while it is up and V again
  shutting it. Only while one is being chosen: once it is asked for, it is up
  over the kart and the wheel goes, the stick's until the stick is back in the
  middle, and a number key or the touch screen's row, which say which already,
  never bring it up at all. The bubble pops up over the kart, above the ready
  tick of 9.6, stays about two seconds and fades, and the next one waits a
  second, so each can be read before it is replaced. The machine that runs the
  karts decides, the host online, and says so to every machine, so it comes up
  on every screen at once, a client's own included; the ask goes over the wire
  as one more field at the end of a client's controls. A player whose kart is
  down emotes all the same, at the same pace, and with nothing to put it over it
  floats up from the bottom of the screen the way a watcher's does, below, rimmed
  in the player's own color and with their name under it in the same; their wheel
  comes up at the bottom too. Past the whistle a player emotes still, through the
  payout slip, and one on the podium of its photo finish has theirs pop up over
  their kart in the photo as well, where everybody is looking. Bots emote as well, now and then, see 9.1. Somebody
  watching, 10.3, has the same emotes and the
  same ways to them, the touch screen's button included, and no kart: theirs
  floats up from the bottom of every screen at a spot of its own and fades, the
  way a reaction rises up a live stream, on a bubble rimmed in gray rather than
  in a player's color, with their name under it; their wheel is in gray at the
  bottom of their own screen, where those rise from. They ask the host, which
  puts it up for everybody as often as a player may.
- A room that has lost its host says so on a pane in the middle of the screen,
  built like the joker detail pane in 8.3, and has the screen to itself: the HUD
  stands down and takes any open joker pick, the standings, the blocks and the
  control hints with it. There is nothing left in that room to answer, and a card
  pick left open under the notice would be asking for a choice about a match that
  is not there any more.
- The title screen offers Play, Play Online, the Driving School until the license
  is earned, Clubhouse, Settings and Quit. The Clubhouse, named for the club a player of the
  tables belongs to rather than as extras, since the program and the catalog in it are anything
  but, puts its own buttons in their place, the Loyalty
  Program of 8.9 once the house has welcomed the profile into it, the Catalog of 8.8, the
  Achievements of 8.10, the Garage of 9.4, and Back, the
  cursor on the first, the column keeping its height with room under them so the
  mark and the name over the buttons stay where they are, and Back or the back key brings the
  title's own back with the cursor on Clubhouse: what is not a way in to a match kept behind one
  button, so the column
  stays short enough for a phone. Once the license is earned the Driving School is a lesson to go
  back over rather than a way in, and leaves the buttons: it is under the license peeking in from
  the right edge, Driving School between turning it over and putting it away, its bind the
  dialogs' option key, F or a pad's X, and on the License page of the settings, 8.5. While the
  Clubhouse is up, the Garage's bay peeks in from the right edge over the license, sliding in as
  the Clubhouse opens and away as it closes: the kart dialog's enamel sign, YOUR KART, over a
  roll-up door two thirds up, the player's kart parked in the lit bay behind it. Under the cursor
  it slides out, the door rolling up and the kart coming forward, and a click, a tap or the
  accept button opens the kart dialog of 4.4a. Going right from a button reaches whichever of the
  bay and the license is nearer the button's height, up and down go between the two, and left
  goes back to the nearest button. A screen with no room for the bay beside the buttons and over
  the license, as a big UI scale makes, has none, and no button stands in for it. The first
  time a profile
  comes to the title, once the shaders have compiled and before the title's opening, the
  invitation that brought the player to the tables comes up over it, STORY.md 6.1a: the House's
  envelope and a card out of it under two spotlights, coming on in turn and all at once on a
  press, with one button, Accept the invitation, which tears the card's stub off; it has the
  screen to itself, the cursor walking nowhere and Back doing nothing, and the driving school's
  first page comes after it, the free lesson its stub promises, 9.4a, the title and its opening
  waiting until the player gets there, by passing the test or skipping it. It is put up under the warm-up's pane and drawn once there, and moves after that without
  being drawn again, so it does not stutter as it starts. The first time the title comes up
  after the profile's first map played to its whistle, the house's welcome to its loyalty
  program comes up the same way, a letter with the program's card on it and one button, Activate
  card, and opens the program's map, 8.9. And until the driving test of 9.4a is passed a flyer
  beside the Driving School button, pointing at it: a sign of the school's
  paper cut to an arrow at the button (`ArrowStyle`, 8.1a), a red hairline
  inside its edge, the learner's L on it, NOW ENROLLING blinking in the rubber
  stamp's red over "Earn your very own license here." in ink and "No
  experience required.", nudging toward the button now and then, a click or a
  tap on it the button's, fitted to the room beside the button, its words
  wrapped narrower on a phone or at a big UI scale, the L with its pointer alone
  in less, and gone on a screen with none; once the driving test is passed, the driver
  license peeks in from the right edge, out under the cursor and in full on a
  click or on the button that opens the hand of jokers, see 3.7, which is drawn
  alone in the bottom right corner over the version, for the
  device last touched anywhere in the game, a pad's button after a match on the
  pad, and on a touch screen the finger of 8.3, for the tap. Nothing else is written along the
  bottom: who made the music, the models and the sounds is said in Settings, About, see 8.5.
  Once the story of 8.7 has had a note found, a manila folder peeks in upright from the left edge
  the way the license does from the right, OFF THE BOOKS in marker across it, opening on the notes
  found, reached going left from the buttons as the license is going right, either of them slid out
  and marked as a button is while the cursor is on it, and marked in pencil while a note in it is
  unread; while its Final Hand is due a flyer in the house's gold points at Play the way the
  school's points at its button; and after its ending Play reads Clock in, Play Online Clock in
  online and the Clubhouse Staff Room, doing what they always did,
  a line in the Count Room's green takes the place of the line under the name, and the seal's fine
  print reads otherwise: STORY.md 7.2, 8.1 and 8.6. While the story is on, the house's letters
  come up over the title one a visit, as the program's welcome does, 8.9: STORY.md 6.11. A question
  asked over the title, this one or any
  other, keeps the cursor on its own two answers. Play goes straight into the lobby, the waiting
  room of 9.6, the way hosting a LAN game does, with the match settings up over it, whose first
  question is whether it is a Grand Prix of several maps or a quick match on one, see 9.7; anybody
  else at the machine joins in there. There is no screen of rules of its own before it. Until this
  machine has earned the driver license of 9.4a, Play, Play Online and the Garage each ask for it
  first, every time: "Missing license", "Nobody drives the Junction without one. Earn your very own
  license at the driving school.", with Earn it now, which is the driving school, and Drive anyway;
  Back puts the question away and goes nowhere, and the cursor goes back to the button that asked,
  so a question that follows, how to drive say, has it to give back when it is put away too. At the
  start of a match the drive and fire controls are shown next to each human player's kart, from the
  countdown until that player has both driven and fired, or for 10 s at most. For a player who
  drives the simple way, see 4.2, it is the way to go and fire.
- The match settings offer match length, target score, bot count, one global bot
  difficulty, the item set (basic items or all items), whether a kart's own
  bullets hurt it, and teams and their friendly fire, 3.14, with the values in this document as
  defaults. Every choice is
  remembered for the next match. Bots run from none to one fewer than the arena has
  seats: 0 to 3 on one machine, and online up to 7 in a lobby for eight, see 9.3. A map runs 1, 3, 5 or 8 minutes; a debug build
  also offers 5 seconds, first in the list, straight through to the podium for
  somebody testing what comes after it.
- Pausing in single-player and local play freezes the match for everyone.
  Online it takes the whole room: opening the menu shows it at once and asks
  the others, and the match only stops once every machine has its menu open.
  While anybody is still playing the match runs on, and the moment one of them
  closes their menu it starts again for everyone. Somebody joining a stopped
  room starts it again, and somebody leaving can be the last one holding it up.
  So the menu is headed Paused alone, where opening it stops the match, and online
  Menu, until the match has stopped for everybody, when it is Paused too. In a map
  of a Grand Prix a quiet line at the foot of the buttons, under a dotted rule as a
  ticket's fine print is, says how the run is played, kept out of the heading, which it
  made too big a thing, and scrolled to with the buttons on a short screen:
  `Grand Prix · map 2 of 3 · 5 min each · first to 3000 · jokers: keep all`.
  The host does not have to wait: Pause game, straight under Resume on its menu
  and over the match settings of 9.6, stops it for everybody at once, and a
  client with no menu of its own open is told the host paused the game, on a
  pane in the middle of the screen. It holds until the host closes its menu, or
  presses Pause game again: the button stays up while the room stands, held down
  in the house's gold with a tick at its end while it is the host's own pause
  that holds the room, so the one who stopped everybody can see they did and let
  go again. At a dedicated server the player with the host's say has it, and a
  pause they made goes with the say when it is handed on, rather than holding the
  room until the next holder happens to close a menu.
  The menu comes up over the room darkened behind it, as the host's match
  settings of 9.6 do, its buttons as big as ever in a list under the heading
  that scrolls where the screen is too short for all of them, a phone's under a
  big UI scale with a host's eight, following the cursor, shaded at an edge with
  more past it, and on a touch screen scrolled by a swipe and pressed by a tap, though not
  through a dialog opened over it, which keeps the screen's touches from whatever is drawn under
  it, see `TouchInput.keep_touches`, and while it is up each player at this screen has a switch
  over their own corner of the HUD for how they drive, see 4.2, and in the lobby
  and the Garage for their name and color, see 4.4; a player who gets up while it is up, their pad
  unplugged and their kart handed to a bot, takes their switch with them, the cursor on it coming
  back to the menu. Clubhouse, Staff Room once the story is over, puts in place of the menu's
  buttons what of the title's Clubhouse can be had in a room: the Loyalty Program of 8.9 once the
  house has welcomed the profile, the Catalog of 8.8, the Achievements of 8.10, in the lobby and
  the Garage Customize kart, the kart dialog of 4.4a over the menu, and Back, the cursor
  on the first, and not the Garage or the Driving School, which are rooms of their own. They and
  Clubhouse wear NEW as the title's do, the switches are down while they are up, and Back or the
  back key brings the menu's own back with the cursor on Clubhouse, as does opening the menu
  again. Online, Back to
  title asks first, in place of the menu: the host is told that everybody who
  has joined will be disconnected, and a client that it leaves the room and the
  others play on. A player with the host's say at a dedicated server, 9.3a, is
  told the say passes on, and only while somebody else is playing to pass it to:
  alone in the game they are told it ends, and with only watchers left that it
  ends for those watching. A host nobody has joined yet, to play or to watch, is not
  asked: there is nobody to disconnect. The cursor starts on Stay, and Back is
  Stay too. A map also
  has Back to lobby, over Back to title, for whoever decides where the room
  goes: this machine offline, which goes back to Play, and the host online,
  which takes everybody back to the waiting room of 9.6 still connected. It asks
  first, since the map ends there, and so does the Grand Prix it is part of.

### 3.9 Royal Flush pads

Four pads spread around the arena, each marked with a card suit of its own: a
spade, a heart, a diamond and a club. Driving over a pad paints its frame and its
suit in your color and takes it from whoever held it, and a flush is holding all
four suits at once. The suits are drawn flat on the plate rather than lettered:
the pads once wore A, K, Q and J, which read as labels rather than as cards to
collect.

- Every pad you hold pays you 1 coin a second into your pot, for as long as you
  hold it, so a single pad is worth taking and worth defending. The rate runs with
  the excitement level in 8.4: three times as fast at level 6 as at level 1, so
  the pads pay best exactly when the room is worth being out in. A holder who is
  dead, falling or rolling out the end of the match earns nothing while they are;
  the pad keeps their color and waits for them.
- The whole board pays on one beat rather than four. A single clock decides when a
  coin is due, and every pad that owes somebody one hands it over on that tick, so
  a player holding three pads is paid three coins at once instead of a stutter of
  singles and the rings go up together across the table.
- Every coin paid throws a ring of light off the pad in its holder's color,
  growing outward and fading over 0.7 s, so four pads ticking over read as four
  pads ticking over from anywhere on the table. The ring is square like the pad
  and lined up with it, not stood on a corner. Coins landing in the same instant
  are one clink, however many pads and players they belong to: four chips stacked
  on one frame is a rattle rather than four coins.
- Holding all four at once, all four being every pad in the room the kart is in,
  which on every map is every pad on the map, is a
  Royal Flush: +3 mult, a full nitro tank, and the
  four pads keep paying you for 12 s after they have cleared, at the rate all four
  of them paid together. Without that last part the reward for winning a flush
  would be that the thing paying you stops. The pads rest for 20 s, so the winner
  is still being paid for most of it and everyone starts again from nothing when
  the board comes back. Announced to everyone with a fanfare.
- While a flush is still paying, the resting pads throw their rings in the winner's
  color, since a pad wearing nobody's color is still handing somebody coins.
- A claim lapses on its own after 30 s, the frame dimming over the last 12 s of it,
  and driving over your own pad again renews it for another 30 s. A flush has to be
  put together inside that window and then kept up; three pads cannot be banked for
  the whole match while their holder waits for a chance at the fourth.
- All four pads clear and stay disabled for 20 s after a flush, then come back
  neutral.
- Pads keep their color when their holder dies, so a flush can be finished
  after a respawn, and stolen pads have to be won back.
- Decoys cannot claim pads. Bots claim pads only by driving over them.
- In teams a pad is its team's, and a flush is a team's, 3.14.

### 3.10 Bounty

Now and then a price goes on the leader's head, to give everyone else a reason
to go after them.

- No bounty in the first 45 s. After that one is called every 25 to 50 s, at
  random, but only on a leader who is at least 120 banked points clear of second
  place and alive at that moment. A match's rules can switch bounties off
  altogether, which the tutorial of 9.4a does.
- The bounty stands for 20 s. Whoever kills the carrier banks 150 points on top
  of the usual kill reward. If nobody manages it, or the carrier dies some other
  way, it lapses.
- The carrier wears a gold crown, is marked on the standings, and both the
  calling and the collecting are announced in the kill feed.
- Bots go after the carrier ahead of whoever is nearest, as long as it is within
  their hunting range.
- In teams the price goes on the leading team's top earner, 3.14.

### 3.11 A hot table

The excitement level of 8.4 is not only something to hear. Past the middle of the
meter the room itself speeds up, so a finale has something to spend as well as
something to listen to.

| At the top of the meter | What happens                                                   |
|-------------------------|----------------------------------------------------------------|
| Jackpot                 | Fills three times as fast and holds twice as many chips, see 3.5 |
| Royal Flush pads        | Pay three times as fast, see 3.9                                |
| Nitro                   | The tank refills three times as fast. Nitro is scarce by design, but a finale where nobody has any is a finale where nobody does anything |
| Jokers                  | From level 5 the table starts throwing cards onto the floor: one every 44 s at level 5 and every 22 s at level 6, lying there for 15 s |

Nothing common is ever thrown out that way. A late match is where the cards that
change how a kart plays come from, and one landing is worth breaking off whatever
you were doing for. They are ordinary floor jokers once they land, see 3.7: anyone
with a free slot may take one.

None of this touches how a kart drives. The room decides what there is to fight
over and how fast it arrives, never how the kart answers the wheel.

### 3.12 The announcer

Some kills are worth more than a line in the feed. The room calls those out in big
letters under the middle of the screen for a couple of seconds, on a plate of the
house's stock framed in the player's color, 8.1a: their name in that color and the
call in foil capitals. Each kind of call is dressed in something of its own behind
the plate, so it is known before it is read (`CallBanner.Dress`): a run of kills
fans out a hand of cards over the plate, a pair for a double up to five for a
spree; a streak burns off the plate's top edge in a row of flames in the player's
color, higher the hotter it is; an overtake has chevrons pointing on either side; taking the lead
runs out a checkered flag; a trade has the two-way traffic sign standing up
behind the plate, turned a little, as a run's cards do. Match point,
3.4, the call that matters most, is run out on hazard tape behind its plate, a
little askew.

| Call         | When                                                              |
|--------------|-------------------------------------------------------------------|
| Double kill  | Two kills inside 4 s                                              |
| Triple kill  | Three, then Quad kill, then Killing spree for anything longer     |
| Hot streak   | 3 kills without dying, then On fire at 5 and Untouchable at 8     |
| Trade kill   | Killing the player who killed you within the last 2.5 s           |
| Overtake     | A kill in overtime that puts you past the player you took out     |
| Taking the lead | The same, when it puts you top of the running order             |

One call per kill, the biggest thing that just happened: a run of kills outranks a
streak, which outranks a trade, since the rarer the thing the louder it should be.
An overtake in sudden death is louder than any of them and is called on top of
whatever else the kill was worth, because at that point it is the match changing
hands rather than a good shot.
A death with nobody to credit, down a pit or on your own bomb, is nobody's moment
and is never called. Dying wipes a streak and a run both.

The calls are text for now. They are worked out apart from how they are shown, so
a voice can be put behind them later without the rules moving.

### 3.13 Overtime

The clock running out does not end the match while there is still a field out
there. It goes to sudden death instead, and the timer says OVERTIME rather than
counting anything.

- Nobody respawns. A kart that goes down in overtime is out, and is offered no
  joker, because there is no respawn for it to be for. Their corner says "waiting
  on players" rather than counting down to a respawn. They keep
  their controls for the one thing left to do with them: reading their hand, see
  3.7.
- A kart that dies after the whistle changes nothing. A bomb already in the air
  or a fall already begun still lands once the match is over, and still ends in a
  wreck, but it banks nothing, pays nobody, counts as nobody's kill or death and
  is offered no joker pick: the scores at the whistle are the final ones, and a
  pick sat open over the podium was a question about a match already decided. The
  podium takes any pick still on screen down with it as well, whatever put it there.
- The Junction still pays. A player who would rather keep what they are carrying
  than bet it on staying alive can drive in and bank it, the same as ever.
- The last kart standing banks its whole pot, at full value, and the whistle goes.
- A kill that moves the killer past the player they took out in the running order
  is called out, see 3.12, and counts toward the Last Word award on the results
  screen. In sudden death the pot a player is carrying is a pot nobody is coming
  back for, so a kill changes the order far more often than it does with a clock
  running, and that is the whole shape of the finish.
- Everybody going down at once is nobody's win: the whistle simply goes and the
  unbanked pots are lost as usual.
- A field already down to one when the clock runs out has nothing to play out, so
  the whistle goes on the hour, and the one left is the last one standing: it
  banks its whole pot, at full value, as it would at the end of sudden death.
- In teams it is played to the last team standing, 3.14.

The room does not wind down for it. Sudden death counts as the finale the same as
Last Call does, see 8.4, so the lights and the music stay at the top, and bots
treat it the same way: what is in the pot is worth taking to the Junction now,
because there is no lap after this one. Entering it sounds the Last Call alarm
again, pitched down: the same warning, only final.

The lobby carries the switch, alongside the other match options in 3.8: Out of
time is either Last one standing or Match ends, and the choice is remembered with
the rest of them. Both say what happens rather than naming it: a player reading
Out of time wants to know what the clock running out will do to them, and Sudden
death and Whistle on the hour each needed the rule explained before they meant
anything.

With Match ends the whistle goes on the hour, and every pot still being carried
banks what a death would bank of it, bent by the kart's jokers the way its death
would be: half, all of it with Insurance Policy, nothing with High Roller.
Nothing drops and nobody is paid for it, since nobody died, and every screen
shows the split as it shows a death's, see 3.6, in the pause before the podium, which the
coins are done in. Nobody had the time
to take it to the Junction, as the whistle came with no warning but the clock,
and a pot carried to the end was still played for. With Last one standing nothing
banks at the clock: the match plays on, and the last kart standing takes the lot.
Either way the places, the winner's lap of honor and a Grand Prix's points are
counted once the last of it is in. A match won by reaching the target ends once
the cash-out that reached it is done, and banks nothing more after that: the
target was the finish line.

### 3.14 Teams

A match can be played in teams: the karts split into two, three or four sides, and the karts on a
side bank into one score together and win or lose together. Everything else in this section is
what that changes; whatever it does not mention plays as it always does, kart by kart.

**Setting it up.** The match settings have a Teams row, 3.8: Off, 2 teams, 3 teams or 4 teams,
Off to start with and remembered like the rest, in a quick match and a Grand Prix, on one
machine and online alike, the host's choice sent with the rest of its settings. With teams on,
a Friendly fire row comes up under it, Off to start with, below.

**The four suits.** The teams are the suits of a deck, in this order: Hearts in red, Spades in
purple, Diamonds in blue and Clubs in green, the palette's own slots, 8.1, so a palette for color
blindness, 8.5, changes them as it changes everything else. Two teams are Hearts and Spades. A
team is named by its suit wherever it is written, and the suit is its mark.

**How a kart shows it.** A kart on a team is painted in the team's color: its body, its bullets,
its trail, its aim guide, its corner of the HUD and its chip in every list. Teammates share a
color, which is the one place two karts ever do, 4.4: in team play which side a kart is on is
the thing to read at a glance, more than which player it is. Each keeps the roof marker shape of
its own color, 4.4, so teammates are still told apart, and flies a small pennant with its team's
suit printed on it, so the team reads in shape as well as color for a player who cannot tell
the colors apart: a card of cream stock off a whip at its back corner, face up to the camera,
streaming back, swinging round as the kart turns and sagging as it slows, as a flag of 4.4 does. A player's own color is kept for them, and is theirs again in a match without
teams.

**Choosing a side.** A seat that sits down goes to the smallest team, the first of those tied
in the suits' order. In the waiting room it is changed two ways, either of them at any time
before the match: on the player's switch in the pause menu, 4.2, where the color button is the
team button while teams are on, "Team: Hearts" with the suit, moving them to the next team; and
by driving, the room's corners being the teams', 9.6. Teams do not have to be even: two against
one is a match. The bots come in with the match and are seated on the smallest teams first.
Online the host decides, as it decides colors, and keeps each player's team from room to room.

Teams are settled at the flag and stay so for the map, and in a Grand Prix for the run, 9.7.
Somebody joining a match takes over a bot's kart and its team with it, 9.2, or, with no bot to
take over, joins the smallest team; a player leaving hands their kart to a bot on the same team.

**Scoring together.** Each kart keeps its own pot and its own mult, collected, carried and lost
as ever. What it banks, a cash-out, a death's half or a bounty, goes into its team's bank, and the
team's bank is the score: the sum of what its karts banked. What each banked is kept as well and
shown as their share. The target score of 3.8 is set per kart, and a team plays to it times the
size of the biggest team at the flag: two against two at 3000 is the first team to 6000. A team
of two banks about twice what one kart would, and a target left as it was ended a team match in
half the time. The waiting room's ticket, 9.6, and the clock's board say the team's number.

- **The winner** is the team with the most banked. Level, more kills between its karts wins it,
  then fewer deaths.
- **Match point**, 3.4, is called for a pot that would take its team's bank to the target, with
  the team's name in its color.
- **Sudden death**, 3.13, ends when only one team has karts left, and each kart of it still
  standing banks its whole pot at full value. With Match ends every pot banks its death's share
  into its team's bank.
- **The bounty**, 3.10, goes on the leading team's top earner of the map, once that team is 120
  clear of the next, and whoever collects it banks the 150 into their own team's bank.

**Friendly fire.** Off, teammates cannot hurt each other. A teammate's bullets pass through a
kart, its shield, its turret and its decoy as though nothing were there, and pass each other in
the air rather than shooting each other down, as a spread from one cannon does; a teammate's
bomb is not set off by a teammate driving over it and its blast does them nothing; a teammate's
Boost or nitro ram is a bump, knocking no chips loose. Oil is the exception: a slick spins out
whoever crosses it, since it never kills. A kart's own bullets and bombs are its own business,
under the lobby's switch for them, 3.8. Bullet Wipe takes away only the bullets that could hurt
its user. On, everything hurts a teammate as it hurts anybody else, but a kart that takes out a
teammate is credited with nothing, no mult, no life back, no bounty and no Pickpocket, and it
counts toward Own Goal on the results, 3.8; a teammate's bump into a pit credits nobody either.

**A teammate is not an enemy.** Nothing that looks for an enemy finds one: the aim assist of 5.2,
Aimbot and Curve Ball, a turret, a decoy and a bot all pass over teammates. A teammate's bullet
grazing a kart gives no graze. A respawn picks the spawn farthest from the other teams, not from
everybody.

**At the tables.**

- **Royal Flush pads**, 3.9, are claimed in the team's color. A teammate driving over a pad of
  their team's renews it rather than taking it, and the pad pays whoever drove over it last.
  A team holding all four pads at once has a flush: the +3 mult and the full tank go to whoever
  took the fourth, and each pad pays its own holder through the 12 s after.
- **The Jackpot**, 3.5, is not contested by teammates: two karts of one team on the pile do not
  pause it, the first of them on collects it and the other waits behind. A kart of another team
  on it pauses it as ever.
- **Jokers** that speak of an enemy or another kart mean a kart of another team: Toll Booth banks
  a share of the other teams' cash-outs only, and Vulture pays for chips dropped by the other
  teams' karts. A joker on the floor is anybody's, a teammate's dropped one included.

**On the screen.** The standings of 8.3 have a row for each team and none for its karts: its
place, its suit and name, its bank and what its karts are carrying, ordered by bank, the leading
team's edged in foil, and the crown of 3.10 on the row of the team whose kart carries the bounty.
A row for every kart under its team's was too many rows. A player's corner shows the
team's bank where their own banked score was, big, and their share small beside it. The score
tanks in the arena are the teams'. The payout slip, 3.8, has a line for each team, stamped WINNER
on the winning team's, with each of its players' lines under it saying what they banked, in
smaller figures and in gray, the team's and its players' printed as one block: the dashes between
its lines and no air, the team's close over its first player's, and the reader's team washed as one,
their own line the stronger, so the marker runs on from the team's line into theirs unbroken, so the team's bank over them is the score that reads as the one that
counts; the awards are each player's as ever. Its podium gives each step to a team, its karts side by side on
it, as wide as the team; and the board in the arena names the winning team.

### 3.15 The slot machine

Two pads on every map, across the middle from each other, are slot machines: a cabinet's face set
in the floor, gold-rimmed and wider than a cell, with three reels in it. A kart that drives onto
one with chips in its pot bets a quarter of its first hundred chips and half of the rest, rounded,
at least one, so a big pot bets big: 10 of 40, 25 of 100, 175 of 400. The reels spin and stop one
after another, left to right, in a second and a little. A pot of fewer than 25 chips does not
pull: a few chips' pull was a gamble worth nothing to make.

| The reels show | Pays the bet | How often |
|---|---|---|
| Three sevens | 10 times | 4% |
| Any other three of a kind | 3 times | 12% |
| A pair | once, the bet back | 34% |
| Anything else | nothing | 50% |

- A pull is worth a little more than it costs, 1.1 bets on average, so it is a gamble worth taking
  now and then rather than a tax. What it pays goes into the pot, chips like any others, at the
  pot's mult when it is banked: a big pot's quarter is a big bet.
- The faces are the slot machine's own, drawn rather than lettered: a red seven, cherries, a bell,
  BAR, a lemon and a chip.
- One bet at a time: a machine with reels turning takes nobody else's until they stop. A kart pulls
  once every ten seconds at most, however long it stays on.
- The bet goes into the machine as the reels start, and the winnings come out to whoever bet, as
  they stop. A kart taken out while its reels turn makes the pull void, which is a reason to come
  after somebody on a machine: the reels stop dead where they are and go dark, the machine shakes
  as a cabinet that will not pay out, its edge flashes red, VOID stands over it in red and its
  buzzer goes, two low blasts; the bet is lost. The whistle going while they turn does not stop
  them, and the host still pays.
- The host draws the reels and says what they show, and every machine spins its own to the same
  faces, so everybody watches the same pull. The reels are one picture drawn once a run and one
  draw on the table, flat in the floor, so they never stand in front of a kart; karts drive over
  them as over any pad.
- A pull takes its bet with a chip's click, the pad's gold edge lit in the bettor's color while
  the reels turn. A win says what it paid over the machine in gold, with the cabinet lit up, the
  reels that made it glowing gold in their frames and the others dimmed beside them, and a
  run of bells, three of a kind with a puff of gold too; a loss says what went in, in gray. The
  reels tick as they turn and clunk as each stops.
- A kart that drives on and may not pull is turned away, on every machine, and nothing is said:
  there are sounds enough at the table. The pad's gold edge goes gray while it is on and a moment
  after. A kart with the chips that is still resting from its last pull is also shown its wait:
  a little clock over the machine, a wedge in its own color emptying clockwise as the rest runs
  out. A kart still on the pad as its own reels stop is left alone, so a win is never grayed.
- Three sevens are a party: the room's lights turn on the machine, a few fireworks go up over it,
  confetti flies off it, a gold ring grows out of it, the casino on the rail has a jackpot of its
  own, and the machine's own jackpot sounds, its bells climbing twice over a pour of coins.
- **The casino round the table.** On every map with slot machines, four more stand in a row on
  the far rail, the one the camera looks across, each a cabinet with its own reels in its face, a
  lamp on top and a lever down its side: seen from the camera they rise over the crowd, never over
  the floor. They are for show. A cash-out of 400 or more lights them up, their lights chasing
  along the row in gold, a halo round each lamp and a beam swinging round over each, with a bell.
  A jackpot looks like none of that: a Jackpot pile one kart let grow to the rules' cap, 3.5, and
  emptied by itself, to a scatter of chips and bells as the chips fly off the pile and JACKPOT!
  over it, or three sevens on a pad. Every machine's reels spin and stop on three sevens one after
  the next, and the lamps and halos flash red and gold all together, the beams swinging round in
  step and twice as fast, for longer than a cash-out's.

## 4. Kart

### 4.1 Handling

The kart is a CharacterBody3D driven by a hand-rolled arcade car model. Its
direction of travel is separate from its heading. Each physics tick the travel
direction turns toward the heading at a grip rate, so the steady slip angle is
about the yaw rate divided by the grip: a few degrees while driving. A drift,
started with a flick of the handbrake, lowers the grip and lets the rear step out
and come round on its own, so the kart visibly goes sideways with the rear swung
out, then hooks up and launches once the slide is caught.

| Parameter                     | Starting value                                        |
|-------------------------------|-------------------------------------------------------|
| Kart size                     | 1.6 m long, 1.0 m wide, 0.8 m high                    |
| Top speed                     | 10.5 m/s, crossing the arena takes about 3.6 s        |
| 0 to top speed                | 1.5 s                                                 |
| Brake deceleration            | 20 m/s²                                               |
| Reverse top speed             | 5 m/s                                                 |
| Coast deceleration            | 4 m/s² with no input                                  |
| Yaw rate at low speed         | 200°/s                                                |
| Yaw rate at top speed         | 138°/s, interpolated linearly by speed: 4.4 m of turning circle flat out. 5.5 m would not place the kart in a lane, 4.2 m turned in on itself, and of the two either side of that 4.4 m was the one that placed it best |
| Minimum speed to steer        | none: turning on the spot at 170°/s and turning on the wheels are one control, mixed by speed and fully on the wheels by 2.2 m/s. That leaves the turn rate near enough flat from a standstill to walking pace, 170 to 187°/s, which is what maneuvering in a corner wants. The old hard switch at 0.5 m/s stepped from 70 to 195°/s every time it was crossed, and a kart shuffling about crosses it over and over |
| Grip, normal                  | travel direction turns toward the nose at 30 rad/s, so the kart goes where it is pointed within about 33 ms |
| Grip, drifting                | 4.8 rad/s, 35 to 55° of slip depending on speed       |
| Drift entry                   | the handbrake while steering, at over 40% of top speed; steering alone never drifts. The slide arrives over 0.18 s and hooks back up over 0.12 s rather than switching on: a drift that lands in one tick reads as the kart teleporting sideways |
| Drift entry kick              | the nose turns an extra 15° into the turn over the first 0.15 s of a drift started while steering, and again when the drift changes sides |
| Drift style                   | **Oversteer**. A flick of the handbrake breaks the rear loose and the wheel then asks the kart to sit at an angle rather than asking for more slide: full lock into the slide holds about 40°, half lock about 24°, a straight wheel none, and opposite lock asks for less than none, which catches it. The rear chases whatever was asked for, damped so it settles rather than wallows, so a wheel held over holds an angle instead of running away. Nothing the wheel does ends the drift, since straightening up and winding on opposite lock are how a slide is driven; it is over when the slide has been caught or has bled away, which pays the usual exit boost. Catching it ends it, so opposite lock held afterwards steers rather than throwing the kart the other way, though holding the handbrake through a catch does break the rear loose again, which is how a kart is thrown from side to side on purpose. The front keeps half its steering while the rear is out, a slide past 25° scrubs up to 13 m/s² off the speed, and the tires arrest the rotation at 88°, so a slide cannot become a spin: that is what oil is for |
| Changing sides mid-drift      | 30% of the slide survives it. The rear comes back through the middle, bites for about a tenth of a second and then steps out the other way, instead of the whole kart mirroring in one tick |
| Drift speed decay             | 5% per second                                         |
| Drift exit boost              | +20% top speed for 0.8 s if the drift lasted 0.6 s or longer and the kart is still carrying half its top speed when the slide ends. A drift that was allowed to die is not one worth rewarding, and without the speed rule a slow shuffle held for the minimum collected as much as a corner taken well. Running into something spoils it: a square hit on a wall or a crate, or a knock into another kart, drops the charge and cuts any boost already running, since the boost is for a slide driven all the way round rather than one that finished in a wall. The kart keeps sliding and can earn another one. Glancing along a wall is part of driving in a room this size and costs nothing |
| Handbrake                     | with steering above 30% it starts a drift and scrubs speed at 4.2 m/s²; without steering it is a straight stop at 22 m/s², about half a second from top speed, that lays down skid marks |
| Nitro                         | held button, and a throttle in its own right: it pushes the kart forward whether or not the accelerator is held, though braking still overrules it. 190% top speed with 1.5 times the acceleration, steering at 60% and grip at 55%, so it is fast and a handful, kills on contact; a full tank burns 2 s and takes 90 s to refill from empty, starting 0.6 s after letting go; a kill refills half a tank; the tank is kept across deaths; cannot restart below 20% |
| Wounded                       | one life left: top speed 85%, body tinted darker until a cash-out or a kill restores the life |
| Spin-out                      | crossing an oil stain: the nose whips around at 420°/s for 1.1 s while grip drops to 0.8 rad/s, so the kart keeps its line and skids; steering and throttle do nothing and speed bleeds at 3 m/s² |
| Wall glance                   | hitting a wall within 35° of it turns the nose 60% of the way along the wall, nudges the kart 1.2 m/s off it and costs at most 15% speed; steeper hits are stopped by the wall and cost 30% speed above half of top speed |
| Turbo pad                     | fires once the kart's center is on the pad, not when its bumper touches the edge. The kart is turned to point down the pad's arrow and sent along it at 150% top speed, and for the next 1.0 s the throttle is held down for the driver and the speed limit stays raised, so the shove lands whatever their finger was doing when they crossed the pad. Nothing else is taken: the wheel, the handbrake and the brake all work at full authority the whole time, so a shove is something to steer and to drift with, and braking through one slows the kart the way it does through nitro. It used to be a rail the kart was locked onto, which could only be escaped by asking for the kart back, and the result was a pad that either drove for you or, once you could steer out of it, did nothing at all |
| Sideways slip friction        | outside a drift, sliding more than 10° sideways brakes at up to 7 m/s² at a right angle; past 20° of slip the grip fades to 4 rad/s. Both were harsher, and both read as the kart fighting the driver rather than as weight |
| Wall contact                  | velocity into the wall is canceled; if that component exceeded 50% of top speed, total speed drops by 30% |
| Kart to kart bump             | both karts pushed apart at 6 m/s along the contact normal and lose 20% speed |

Ramming only kills when the rammer has the Boost power-up active, see 7.1, or
is burning nitro. Turbo pads do not enable ramming kills.

A ram the victim lives through knocks a quarter of their coins, at most 8, out of
their pot and onto the floor around them, as dropped chips that anybody may
collect and that vanish after 15 s like any other drop, see 3.6. A ram that kills
scatters coins through the death sequence already; this is for the one that does
not, which would otherwise cost a kart carrying a fortune nothing at all. Tight
Grip, 7.3, keeps every coin in the pot: its death drops no chips and a killer takes
none, and a ram it lives through knocks none out.

A kart too freshly hurt to lose a life, blinking after a wound or just back from a
death, is still knocked by a ram: it loses the same share of its coins, only not
the life. Being untouchable was never meant to make a full pot safe to shove.
A Shield still takes the whole ram, coins and all. A kart is rammed at most once
every 0.2 s, since two karts in touch meet on every physics tick and a ram that
did not let go would otherwise knock a pot out a handful a tick until nothing was
left.

A kart that can ram another kart to death goes through a crate as well, so a
square hit while Boosting, burning nitro or under Road Rage breaks it and pays
its chips, and the kart keeps the speed it arrived with rather than being stopped
dead by a wooden box. Anything slower bounces off it as before.

After the first play session the handling changed as follows. Drifts start only
with the handbrake, which also brakes; steering alone keeps grip. A stopped
kart turns in place. The kart and its bullets are slower. Shots are shown by an
aim guide and bend a little more. Steering rates stay instant, 200 to 110°/s,
after a smoothed variant felt worse. A second session found drifts invisible,
which traced to the travel direction snapping to the nose every tick; the model
above replaced it, with the numbers exposed on the F4 panel of the
development scene.

A tire model, the stick turning a front wheel and tires with a grip limit deciding the rest, was
driven against this one and rejected. At 10.5 m/s on a table 60 m across an honest tire model
understeers everywhere unless the tires are given grip no vehicle has: holding a 5 m radius at
that speed needs 2.2 g. It also turned a kart crawling in a corner at 69°/s where the rate model
turns it at 191, and winding a wheel on at a rate, however small, is lag on the one thing this
game wants to be immediate. A rate model is not a shortcut at this speed and this scale; it is
the right tool.

### 4.2 Controls

There are two ways to drive, and each player picks their own. Advanced is
kart-relative: left and right turn the nose, throttle and brake work along the
heading. Simple is screen-relative: the way pushed is the way on the screen the
kart goes, see below. Aiming is forward-only by default. All bindings are
remappable. Every action exists once in the Godot input map; an input router
assigns physical devices to player slots, see 10.2.

| Action                      | Gamepad             | Keyboard and mouse        |
|-----------------------------|---------------------|---------------------------|
| Steer                       | Left stick X        | A / D, or Left / Right    |
| Throttle                    | Right trigger       | W, or Up                  |
| Brake, reverse              | Left trigger        | S, or Down                |
| Up and down, simple driving | Left stick Y        | W / S, or Up / Down       |
| Fire                        | A                   | Space                     |
| Handbrake, drift            | Left bumper         | Shift                     |
| Nitro                       | RB                  | Ctrl                      |
| Use power-up                | X                   | E                         |
| Joker menu, hold            | Y                   | Tab                       |
| Joker menu: select          | Left stick or D-pad left / right | Arrows, A / D, brackets or 1 to 5 |
| Respawn pick: take          | Fire or use power-up | Space or E                |
| Joker menu: drop            | A                   | E                         |
| Joker menu: destroy         | B                   | Q                         |
| Joker card: details, hold   | Right stick click   | Alt                       |
| Jokers by mouse             |                     | Over a card to read it, click to keep a hand card open or take a pick card |
| Free aim, Swivel Cannon only| Right stick         | Mouse position on the arena plane, or a finger on it on a touch screen |
| Emote                       | Right stick, held then let go | 7, 8, 9 or 0     |
| Emote wheel, then a way     |                     | V, then W, D, S or A      |
| Pause                       | Start               | Esc                       |
| Join, in lobby or mid-match | Start               | J                         |
| Mute music                  |                     | M                         |
| Menus: press the button under the cursor | A      | Enter or Space            |
| Menus: back out                          | B      | Esc                       |

In simple driving left, right, up and down are ways on the screen rather than things to do with
the wheel, and the kart is driven there for the player. Pushing any way puts the gas down as far
as the push and turns the kart toward that way as it goes: the wheel is full over 25° or more off
it and less by as much nearer, so the nose comes round without sawing either side of it. A kart
facing more than 120° away turns before it goes, the gas coming in as the nose comes round and
all the way down within 60°. Letting go brakes the kart to a stop and no further; nothing
reverses it. The kart turns to the way last pushed even after it has been let go of, so a flick
of the stick is enough to turn it and fire that way. A way pushed from nothing counts however
quick the push; a way that changes while held counts once held for 0.08 s, since two keys held
for a diagonal never come up at the same moment and the one left down between is not the way
anybody meant. Once within a degree of it the kart has got there, and a bump or a wall that turns
it afterwards is not turned back against. A kart that goes down comes back with nothing to turn
to. In a slide it is the travel that is turned toward the way rather than the nose, which leads.
Up and down have bindings of their own, which the gas and the brake share on the keyboard. A
pad's own gas and brake, the triggers unless rebound, still work the pedals while either is
pressed, over whatever the push asked for; nothing says so, since the push is the way to drive
here. The keyboard's never do, being the up and down of the push. Nitro and the handbrake are as they are, except that nitro lit when
let go drives on rather than braking. The joker cursor of 3.7 and the respawn pick walk by the
push rather than by what the wheel does with it, which goes over the wire as one more field at the
end of a client's controls; a client from before it sends the wheel alone, which for it was the
push. Which way a player drives is kept per local seat, and a seat nobody has asked drives the
advanced way.

**Auto throttle.** All of the above is simple driving with Auto throttle on, the push working the
pedals too. It is off to start with, kept per local seat as the way of driving is, and switched on
the seat's switch over the pause menu, under Simple driving, and on its card in the Seats page of
the settings, the first seat's under its Driving on the Controls page too. Off, on a pad or the touch screen, the pedals are the player's own: the triggers, or
the touch screen's gas and brake, the slider whole again or the gas and brake buttons back, while
the stick goes on pointing the way. The push then only steers, toward the way pushed, and only
while it is held: let go, the kart is not turned on toward the way last pushed, so a kart standing
still turns as far as the stick is held over and no further, which makes aiming easy; nothing
brakes it but the brake. The drive hint and the card beside the switch say steer, gas and fire,
and the driving school's tasks say the wheel and pedals' words. On the keyboard it is always on,
whatever the switch says: its four keys are all of them the way to go, with none left for the gas,
so the keyboard has no switch for it.

The first way into driving from the title, whether Play, Play Online or the Garage,
asks first how to drive: a big button each for simple and advanced, with its picture, its name
and what it is in a line, over a word that the settings can change it later. The cursor starts on
simple and stays on the two. The answer is every seat's that has not given one of its own, and is saved at once.
Back puts the question away unanswered and leaves the title as it was, and it is asked again
until it has been answered. Help me choose, beside the Driving row of the settings, asks it again,
for the first player alone and without the word about the settings, the cursor starting on what
they drive now; the row shows the answer.

While the pause menu of 3.8 is up, each player at this screen has a switch held over the middle
of their own corner of the HUD, so four people at one screen each find theirs where they already
look: a pane edged in their color with their name, and a button with the way they drive on it,
picture and all, that changes it to the other. It is kept on the screen whatever size the corner
is drawn at, is saved at once, and the kart drives the new way the moment the menu closes, the
touch controls changing with it. The player at a touch screen has a second button under the
first, for its controls, Slider or Buttons with their pictures, changed over the same way. In the
lobby and the Garage there are two more over those, see 4.4: a box to type another name in, and
their color by name. Beside each switch a small card on the HUD's scrim says what that player is
playing on, Keyboard, Gamepad 1 or Touch screen, and draws what they drive with there the way
they drive: the throttle and the steering, or in simple driving the way to push, and the fire
button with them, the cannon being the other thing every map asks of them. A player who
picks up a pad sees it change. The card is on the side of the switch toward the middle of the
screen: under it for a player in a top corner, over it for one in a bottom corner, where under
it would be off the screen. Online only the players at this machine have one. A pad's cursor goes out to them
from the menu: sideways from any of its buttons is the top switch on that
side, and only sideways, up off the top of the menu and down off the bottom staying in it; back
toward the middle from a switch is Resume, and up and down go between the switches on one side.

A hint that names the push of simple driving draws it as the one control it is: on a pad the
stick with a head on each of its four sides, square rather than wide; on a touch screen the same
stick, empty, since it is the one under the left thumb; and on a keyboard the four keys, up,
left, down and right, the way WASD is written. A pad with the two halves on different sticks gets
both pairs. The hint over the kart at the start of a match, see 3.8, is the way to go and fire,
and changes over if the player switches.

The pad is knocked as well as the speaker: taking a life, dying, a big cash-out,
hitting a wall and running into another kart all come through the hands, as hard
as the thing that caused them. Knocks are held to one every 0.3 s per player, since
grinding along a wall reports contact on every tick it is touching and a pad
buzzing continuously is a pad nothing else can be felt through. A box a kart
bounces off answers as a wall does; a box it goes straight through at ramming
speed does not stop it, so there is nothing to feel. Only the pad a player drives
with is knocked: a player reading every device, as one alone at a screen does, has
the pad they last drove with knocked, and none while they drive on the keyboard; a
pad lying on the table that nobody drives with never is, nor one at a seat of the
demo of 9.8 that its bot drives. The accessibility setting in 8.5 turns all of it off.

Where two actions are the opposite ends of one control, the hints name the control
rather than both of them: on a pad the two halves of a stick are a stick, and
"Left Stick X-Axis - / Left Stick X-Axis +" describes the input map rather than
anything a thumb does. On a keyboard they really are two keys and both are named.

A menu is driven with the pad as well as the keyboard: the stick and the D-pad walk
the cursor, A presses whatever is under it and B is the Back button. Held over a way, the stick or
the D-pad walks once, and after a moment walks on, quickly, for as long as it is held, as a key held
down does; the way pushed last goes on, and nothing goes while no control has the cursor. Back only backs
out of somewhere there is a way out of, which is the pause menu, the lobby, Play
Online, LAN games, a form on either and the settings, and not the title screen, where there is
nowhere to
go. While the settings are listening for a new binding, B is a binding like any
other button.

A phone's keyboard comes up over the bottom of the screen, and a text box down there, a name or
a plate in the settings, went under it, typed into blind. While a box is typed into and the
keyboard covers it, a bar just above the keyboard shows what the box is for, from the words
beside it in its row or its hint, and what is in it, the caret blinking where it is, a secret
as dots. The typing still goes into the box itself, so everything that listens to it hears it as
it always has; the bar goes as soon as the box lets go or the keyboard does, and a box the
keyboard leaves clear gets none. `KeyboardBar`, put up on a touch screen only.

A phone's own Back, the system's button or gesture, is B: it closes a question or a pane and
backs out of a screen or out of the room's menu. Where B does nothing, in a match, the lobby,
the Garage or the driving test with nothing up over them, it opens the room's menu, as the menu
button in the corner does, since a phone has no other key for it. On the title it does nothing,
as B does there. It never quits the game outright, which is what Android would do by itself:
`quit_on_go_back` is off, and `Game.go_back` hands it on as Back.

The two things a thumb does on a gamepad are firing and using an item, so they take
the two buttons under it. The joker screens borrow the same hand: A drops, B
destroys. Destroy cannot share with use, because the respawn pick puts taking a
joker and skipping it on one screen and reads taking first, so a shared button
would leave skipping unreachable.

On a touch screen the controls are drawn over the room instead. They come on by themselves on
a phone or a tablet; `++ --touch=1` turns them on anywhere, with the mouse standing in for a
finger, and `++ --touch=0` turns them off. `make run ARGS=--touch=1` is the first of those. Every finger is answered on its own, so one thumb can
steer while the other presses, and a finger belongs to whatever it went down on until it comes
up. A menu button in the top right corner opens the room's menu of 3.8, which is the way back to
the title and out of the game for a player with no Escape key. It opens as the finger comes up
on it, and not if the finger slid off it first. It works with nothing here to drive as well:
somebody watching an online game, or a player whose seat is still on its way, has the menu too.
Everything else lets go of a finger the moment there is no kart under the controls, and the
menu button once did as well, so a tap on it did nothing then. A smaller button beside it, with a smile on it,
opens the four emotes of 3.8 in a row along the top of the screen, clear of the board and the
driving buttons under it; a tap on one puts it up and shuts the row, and a tap anywhere else
shuts it too and goes on to whatever it landed on. It is only there with another person in the
match, at this screen or another: against bots alone it would be a button for talking to nobody.

The left thumb steers with a stick that comes to wherever it goes down in the lower left of the
screen, and waits in that corner while nobody has a thumb on it. It only steers, so it is pushed
side to side, and how far it is pushed is how far the wheel is turned; and it is drawn as that
wheel, see-through like the buttons, a rim with a spoke to each side and one down and a band at
its top, turning with the push up to a quarter turn at full lock. A knob sliding along a line
said nothing a wheel does not say better, and it is still pushed rather than turned round, which
a thumb does without looking. In simple driving it is the stick it always was. The right
thumb has a slider in the bottom right corner: one tall pill with nitro, gas, brake and drift
down it, top to bottom, the gas the tallest, since the thumb rests there most, and the two at
the ends a little taller than the brake, since a thumb reaches for them. A thumb goes down
anywhere on it and slides from zone to zone, and belongs to the slider until it comes up,
however far off its ends or its side it strays. Nitro holds the gas as well, for when the tank
runs dry under it, and so does drift, so a slide keeps its power; brake is the brake alone, and
reverses once stopped, and says REVERSE on it, or REV where the word will not fit, while the
kart is standing still or rolling back, since that is what it does then. The nitro is grayed
while the tank is short of what it takes to start a burn, and is only the gas until it fills.
The drift is grayed while the kart is standing still or rolling back, there being nothing to
slide; grayed, either still does what it does. Sliding from the gas down to drift crosses the
brake on the way. Going down on the slider clicks, and so does crossing from one zone into the
next: the phone gives the shortest, lightest buzz it has, and so it does as the thumb rolls onto
fire, so a wrong zone is felt rather than seen. The rumble switch of 8.5 turns it off with the
rest, and the Android build asks for leave to vibrate for it. The nitro tank is a bar across the
bottom of the nitro. Fire is a round button beside the slider at the height of the gas, and a
thumb rolled across off the slider onto it fires as well as driving, which is how one thumb
drives and shoots at once; the item button is under fire. The item button is always there, and
faint while there is nothing in hand to play, so a thumb knows where it is before it is needed;
with an item it wears the item's own picture, and while a box is still opening the pictures
flick past the way they do in the corner. Something an item started and has still to finish, a
shield up or shots loaded, keeps its picture on the button after the item has left the hand,
with a ring round the inside of its rim counting down in time or in shots, in the item's color,
the way the nitro button's tank does; an item picked up meanwhile takes the picture, being the
one the button plays, and the ring stays round it. While the kart cannot be driven, on the grid
for the countdown or waiting to come back, the stick, the slider and every driving button are
grayed out and press nothing: a thumb resting on fire after a death would otherwise take a card
of the respawn pick it has not read. The gas held through the last lamp takes the kart away on
the green. The driving buttons go while the podium is up, where they would sit over its own. The
hints that name keys, in the corner and beside the kart, are not shown on a touch screen: the
buttons say what they are on them. A hint that is shown, such as the tutorial's line over the kart
in 9.4a, names the button on the screen instead of a key: gas, fire, nitro and drift as a pill
with the button's word on it; the item as the item button itself, round, wearing the picture of
the item in hand or empty and faint with nothing in it, since the button has no word on it and a
pill reading ITEM named a button nobody could find; and steering as the wheel under the left
thumb, or in simple driving the stick. The
standings hang from the top right corner under the menu button rather than down the middle of
the right-hand side, which is the slider's and the item button's, and the kill feed hangs under
them and stops short of the buttons and the slider, dropping its oldest lines. The hand of
jokers keeps to the stretch between the stick's ring and the nearest button or the slider,
shrinking its cards when that is narrower than the hand, and the respawn pick moves up, and
shrinks its own cards a little if it has to, to keep its button above the hand. A phone is drawn
big so its buttons can be pressed, see the UI scale of 8.5, and what is only read does not need
the size: on a touch screen the player's corner, the standings and the kill feed are drawn at
three quarters of the rest of the UI, each shrunk toward the corner or edge it hangs from, and
the round buttons, the slider and the stick are see-through, so the arena under a thumb is still
there to be seen. The camera keeps the karts out from under them all the same, as it does the
HUD's panels, 8.2, while they are up: the middle of each, seven tenths of its size across and
down, since a kart partly under the see-through edge of one is still seen. Being round, they
are chips of 8.1a: the house's stock with a rim and notches round it in the player's own color,
lit in it while a thumb is on one, and the slider, the stick and the nitro tank are in it too,
as the player's corner and nitro cells are, so the controls under the thumbs say whose they are
(`TouchInk`). The hand of jokers is tucked into the bottom edge while none of its cards is
being read, smaller and half below the edge, and comes up to its full size as a card is held or
kept open.

With the Swivel Cannon in hand, a finger that goes down on the arena rather than on any of the
controls points the cannon at that spot on the floor, and it follows the finger as it moves.
Lifted, the cannon stays on the spot it was let go over, the way it stays on the mouse. Pointing
never fires, which is the fire button's, and a finger on a button points nothing. Without a
freely aimed cannon a finger on the arena does nothing, and the next one comes to hand pointing
down the nose until a finger says otherwise. The mouse a phone makes out of its fingers is not
read for the aim at all, since it is wherever the last finger went down, the buttons included.

The slider is one of two ways to drive, and the settings' Controls, first there on a touch
screen, have the other: Touch driving, Slider or Buttons, each a button with its picture as the
ways to drive have, a tall pill cut into zones and a big round button with three round it, put
up at once, a match under way or not. Buttons is a round button each for gas, brake, nitro and
drift in an arc round the bottom right corner with fire, the gas the biggest and nearest the
corner, each only itself: drift is the handbrake alone and nitro the nitro alone. A thumb
sliding from one button to the next lets go of the first and presses the second, and one resting
on the seam between gas and fire presses both. The item button is further in, fire being at the
bottom edge already, and the nitro tank is a ring round the rim of its button. The four click,
are grayed and say reverse as they do on the slider.

Both drive the simple way too, for a player who drives it, and change over the next frame when
the choice does. The stick points the way rather than turning the wheel: its knob goes every way
round inside the ring, how far it is pushed past the dead middle is how much gas, and the pedals
are its, so the right thumb has neither. The slider is a shorter pill of nitro over drift, two
halves of it, with fire and the item beside it where they were; without the slider fire takes
the corner, being the button pressed most, with drift beside it along the bottom, nitro over it,
and the item between the two.

The hand of jokers is read by holding a finger on a card. The hand opens on that card, lifted
out of the fan with what it does over it, for as long as the finger stays, and sliding the
finger along the hand reads the others; the card still answers where it rose from, so the finger
holding it is not left behind. A quick tap of under 0.3 s keeps the card open instead, and its
pane has a button each for dropping it and destroying it, the destroy in red. It stays open
until the card is tapped again, a button on its pane is pressed, or a finger comes down on
nothing at all; the stick and the driving buttons leave it be, so the kart can be driven while
the card is read. The pane says which of those it is: a card only held says how to keep it open,
and one kept open how to close it. A kart waiting to come back can keep a card open to read it
but gets neither button, as on a keyboard. A card kept open closes when the hand changes under
it and when a respawn pick comes up. Either way the other thumb stays on the stick and steers
the kart rather than walking the cursor off the card. There is no button to open the hand with,
so none is drawn beside it. The card a finger rests on goes over the wire with the rest of a
client's controls, as one more field at the end that a client from before it never sends, and a
drop or a destroy goes with the card it was for.

Without a touch screen the mouse does for the player on the keyboard what a finger does here.
Over a card of the hand, that card opens with its pane, and off it the hand closes again; a
click keeps it open, with the same Drop and Destroy buttons on its pane, which are clicked, and
the pane says to click it again or press the pause key to close it, which a click anywhere else
does too. The pause key only closes the card, and pauses the match once no card is kept open:
the card is what the player is looking at. Over a card of
the respawn pick the pick's cursor goes to it, and a click takes it. The pick is not held still
under the mouse the way it is under a finger, so its keys and the fire button go on answering
the card the cursor is on. A mouse only points at anything once it has moved in the match: one
left lying over the bottom of the screen by somebody on the keys alone would hold the hand open,
and a hand held open keeps its player from playing their item.

The respawn pick of 3.7 is read the same way, and answered with a tap: a finger held on one of
its cards moves the cursor there and shows what it does, and nothing is taken when it comes up,
while a quick tap of under 0.3 s takes the card tapped, or destroys it on the destroy step. The
pick's usual wait before it can be answered holds for a tap as it does for a key. The pick and
the hand under it answer their own fingers: reading a card of the pick leaves the hand shut, and
reading the hand leaves the pick's cursor where it was. The card of the pick a finger rests on
stays on this machine; only a tap goes over the wire, as the number key. Whichever of the two
was touched last is drawn over the other, pane and all, so the description being read is never
under the other's cards, which on a small screen they meet. Only one of them has a card picked
out at a time, too: going to the hand leaves the pick with no card lifted and no pane, its title
and its button staying, until a finger goes back to it, and going to the pick closes the hand,
card, pane and all. A pick coming up comes up in front, being the thing on the screen that wants
reading, and closes a card of the hand left open; one opened over the pick stays open. The pane
says "Tap a card to take it, hold it to read it" in place of naming buttons, and a button under
it skips the pick, or goes back from the destroying to the choosing; keeping one of last map's
has nothing to skip to and no button. That button and the drop and destroy buttons of the hand
are pressed by the touch controls rather than the mouse, so there is no pointer to light them
up: while a finger is on one it wears the pressed look with the gold edge, as every other button
does under the cursor, and loses it if the finger slides off. A finger going down on a joker
clicks, in the hand and in the pick, and so does each card it is swiped along onto, the same
short buzz the slider gives, so reading along the row is felt card by card.

### 4.3 Trails

- **Tire marks**: a ribbon mesh per rear wheel, drawn while the kart moves,
  darker and wider while drifting or braking. Everything short of a drift is kept
  faint, since a floor covered in the marks of ordinary driving says nothing: a
  straight line is barely there, a hard turn and a brake not much more. A full
  drift leaves a clear skid at just under half opacity, and a straight handbrake
  stop leaves the darkest mark of all. A kart whose pot would win the match, see
  3.4, lays its marks in gold over them, all but solid, a quarter wider, and drawn
  a little brighter than their color so they glow where the bloom is on, and the
  gold holds for a moment and fades out over 2 s, leaving the ordinary mark under
  it to fade over its 20 s.
  Marks fade out over 20 s, or 4 s with the tire marks setting on Short or Mine,
  see 8.5, faded by their shader, and are laid a stretch of
  about thirty meters at a time: a finished stretch is never built again, both
  wheels are one thing to draw in it, and it goes once it has faded, so marks
  cost next to nothing to keep on the floor. Built whole again every frame, the
  marks of four karts were most of what a match cost to run. They are laid where the model's own rear wheels are, measured off it rather than
  guessed from the kart's length, so they come down under the wheels making them
  instead of trailing a hand's width behind the kart. What is measured is the
  middle of each tire, not the point the model hangs the wheel from: that sits at
  the inner face, a tire's width inboard of where the rubber meets the floor, and
  taking it for the contact patch drew the marks between the wheels rather than
  under them.
- **Smoke**: a faint exhaust particle trail whose rate scales with throttle,
  with bursts on drift entry, drift exit boost, turbo pads and Boost.

- **Drift sparks**: a fountain off each rear wheel, lit white while the slide has its exit
  boost earned and quiet otherwise, so they go out again if the kart is allowed to slow below
  the speed the boost asks for, so the sparks are the news that the drift is worth
  ending rather than a decoration on every slide. Spending the boost throws gold off the back
  and flashes a light with it for 0.45 s, and that gold appears nowhere else: white is ready,
  gold is gone. The flash follows a drift ending with enough time on it rather than the boost
  itself, which is the same condition but the one a watching client can see, since the drift
  and its length come over in the snapshot and the boost does not. There is no HUD for any of
  this and there should not be: it is a driving reward and it belongs on the kart.
- **Nitro**: a flickering blue-white flame from the exhaust with a warm glow on the
  floor, a trail of tiny glowing sparks left behind that fade over a second, and a
  thick plume of smoke thrown backward that swells as it drifts, much heavier than
  the faint exhaust trail of ordinary driving.

### 4.4 Customization

- One kart body. Player color is a material tint on the body and the bullets.
- 8 player colors, see 8.1. Each color also has a distinct roof marker shape
  for color-blind readability, eight shapes for a room of eight, 9.3: a ball, a
  box, a wedge, a ring, a drum, a pill, a cone and a diamond, in the order of the
  colors. The shape goes with the color rather than the seat, so a player who
  changes color changes shape too.
- A player picks another name and another color in the lobby and the Garage,
  from their switch in the pause menu, 4.2: a box with their name in it, empty
  with the funny name they were handed showing faintly if they never set one,
  and a button with a swatch of their color and its name on it, Red or Blue,
  that moves them on to the next one nobody else in the room is in, since no two
  karts are ever the same color, teammates aside, 3.14, whose button is their team's. The name is the color's own in the palette
  worn, 8.5, not the one it stands in for: a white is White. The kart is painted over at once, body, marker, hat, flag, trail
  and aim guide, and so are their corner of the HUD and the switch. A name is
  kept once they are done typing, in their seat's settings, where the Seats
  tab of 8.5 keeps it; emptied, the seat is handed a funny name again from the
  next match. A color goes on with them from room to room the way the one they
  were given always has, and the one they move on to is their seat's favorite
  from then on, kept in their profile, 8.5, a seat each, or in the profile sat in
  at that seat, 3.8: the color they are given wherever nobody before them has it,
  in a room they open, a room they sit down in, here or at a client, which asks
  the host for it as it sits down, a bot's kart taken over and repainted in it,
  the Garage and the driving school, and the kart on their license, 9.4a. Without
  one a seat takes the color its place at the table gives it, as it always did. A profile new
  to the machine, the first one or one added on the Profiles tab, starts with a favorite at
  random for its first seat, so that new players are not all in the same color before they
  choose one.
  The Seats page of the settings chooses it too, and the kart dialog of 4.4a, which writes the
  name on masking tape and has the colors in spray cans. While the box has the cursor the keys are the box's,
  so a player on the keyboard sits still rather than driving round the room
  with the letters of their name, online, where the room goes on under the
  menu. Online a client asks the host for both, which decides, as it owns every
  name and color in the room, and the snapshot brings the answer back to every
  screen, the client's own included.
- Four more things a player picks, remembered per seat between sessions. None of
  them changes how the kart drives, and the player color is still the player
  color underneath all of it: these say whose kart it is a second time rather
  than instead.
- A bot dresses its kart too, a paint, a hat, a flag and a trail drawn at random
  when it takes the wheel, so a field of bots is a field of karts rather than of
  one kart in four colors. Never the crown, which the bounty's carrier wears,
  3.10. A bot taking over the kart of somebody who left drives it as they left it.
- On its rear bumper, under the flag, a kart of this machine's wears a plate,
  which nobody picks at a stall: a learner's L, a red L on a white square, until
  this machine has earned the driver license of 9.4a, and the license plate that
  comes with it after, up to eight characters: on the kart and in a list of
  players a plain plate, black on pale with a dark rim and a bolt in each top
  corner, which is what reads that small; and big, where it is chosen, printed
  as the house's documents are, 8.1a: the school's cream paper with rounded
  corners, a hairline of ink inside its edge, a screw in each top corner with
  DEPT. OF KARTS in microprint between, and the letters in the condensed
  capitals, spaced a little, suggested as the license is issued and
  chosen, changed, or cleared for a bare bumper, on the License tab of the settings,
  8.5, or on the bench of the kart dialog, 4.4a. All of them type it on the plate itself, `PlateField`: the printed plate is the
  text box, its letters in the plate's lettering and its rim gold while it is
  typed into, with "Tap to edit", "Click to edit" or the pad's accept button
  "to edit" beside it, rather than a box with the plate drawn next to it to say
  what it would read. It is cleaned as it is typed, upper case and nothing a
  plate cannot hold, but a space at the end stands until the plate is left:
  cleaned away at once, nobody could type one between two words. A bot wears one too: the
  easiest bots are learners, with the L, and the rest hold a license, with a
  plate drawn from their name and the match's seed, "HUN-382" for a Hunter;
  the driving test's bots are easy, and wear the L. Online, 10.3, a
  client says what its seats wear as it says their name and dress, the host
  puts it on, and the snapshot carries every kart's plate to every screen, so a
  kart wears the same plate on every machine.
- In the lobby they are picked by driving rather than from a menu, at the stalls: a pad on
  the floor for each of the four, with its picture lying on it, a paint
  roller, a top hat, a flag and the puffs of a trail, the same the touch
  screen's fire button shows on one (a word had to be read from a moving kart,
  and in one language), along
  the back wall of the waiting room of 9.6, quick to go through between matches
  without a dialog up. Everywhere else they are picked in the kart dialog of
  4.4a, which the Garage has in their place, and which the lobby's pause menu
  has too. On one, the fire button puts the next of that thing on the kart rather
  than a shot out of the cannon, so a player goes through them at their own pace
  and stops on the one they want. While a kart stands on a pad a card hangs over
  it, in place of the drive and fire hint of 3.8 and drawn as it is, see 8.3:
  what the kart wears there, large in its player's color, No hat for none, and
  under it, smaller, the button and what it puts on next, Space next: Cap, or The
  only one so far where there is nothing else yet. A press changes the card in
  place, swelling it for a moment, so going through them quickly reads as one
  name after another; the names that used to rise over the kart at each press
  ran into each other. A kart driven from another machine has the name alone.
  On a touch screen the fire button itself shows what it does there: while
  the kart stands on a stall it carries a picture of that stall's thing in place
  of FIRE, a paint roller, a top hat, a flag on its pole or the puffs of a
  trail, and the card draws the button the same way, the picture on a round
  chip, rather than naming a fire button that is not what it is for just then.
  The pad lights in the color of whoever is on it. The host decides who is on a
  stall, as it decides who is on the ready pad, and says so to every machine, so
  the kart changes on every screen at once, and the snapshot carries it to a
  machine that was not there to hear it. A player at this machine keeps what
  they picked in their seat's settings. Online a client keeps its own and says
  it to the host whenever it is seated, alongside its name, so it arrives
  dressed in every room it goes to; before the stalls, a client's kart was plain
  on every screen but its own settings.

| Choice | Options                                                            |
|--------|--------------------------------------------------------------------|
| Paint  | Solid, Stripes, Checks, Spots                                      |
| Hat    | None, Cap, Top hat, Crown, Party, Learner                          |
| Flag   | None, Pennant, Banner, Checkered                                   |
| Trail  | Smoke, Sparks, Confetti, None                                      |

- **Paint** is a pattern laid over the color rather than a second color: a
  generated texture mapped triplanar, so the model needs no unwrapping and the
  pattern sits on the kart rather than on the world. Smoothed and mip-mapped
  rather than snapped to the pixel, since a kart is a painted toy and not a
  sprite, and the podium camera comes right down to it. A striped red kart is
  still unmistakably the red one.
- **Hats** sit on the crown of the driver's helmet, and the roof marker moves up
  over whichever one is worn rather than through it. The Learner is the driving
  school's block of 9.4a, a white cube with the red L on its sides and its top,
  worn square, facing the way the kart does, white whatever the player's color.
- **Flags** fly from a pole at the back, clear of the bodywork and streaming
  behind the kart rather than out of its side. All of them are the player's color
  except the checkered one, which is the color a checkered flag is.
- **Trails** replace the exhaust smoke: sparks or confetti in the player's color,
  or nothing at all. Whatever it is still thickens with the throttle and in a
  drift, see 4.3. Confetti is thrown as tumbling slips with some thickness to them
  rather than flat squares, which spend half a tumble edge-on and invisible, each
  cut from one of a few sheets of the player's color, a shade lighter or darker or
  a touch round the color wheel either way, and there is twice as much of it, and Kit's
  pencil leaves its scribbles lying every way,
  because it has to read as a trail from the other end of the room. Sparks
  are hot streaks drawn out along the way each flies, thrown up and back fast and
  falling in an arc, white-hot as they leave and cooling through the player's
  color, gone in half a second; round flecks drifting up read as embers.
- A kart is dressed the same on every screen: the four choices ride with the kart
  in the snapshot, see 10.3, and a choice a machine has never heard of is the
  plain one rather than a crash.
- A Decoy Kart wears what its owner wears, hat and flag included. It is only worth
  anything for as long as somebody takes it for you, and a kart in your color
  with none of your things on it is not you.
- The podium at the end of a match shows each kart as its owner dressed it, see
  3.8, plate and all, and so does the Garage.
- The table above is what the game always had, and all of it is everybody's but four:
  Checks, the top hat, the checkered flag and confetti are won in the loyalty program of
  8.9 now, which pays out more of each of the four parts too, three more kinds, a gold
  plate, tire marks and a card back, and editions of all of it; a stall or the kart dialog offers a seat what its profile has won, and a guest's
  seat what the profile playing has. A bot wears only what is in the table above.
  Whatever is won keeps to the rule of all of it: the player color and the roof marker
  still say whose kart it is, and nothing makes a kart bigger, smaller or harder to see.

### 4.4a The kart dialog

Where a kart is dressed with a dialog rather than by driving over stalls: from the
Garage's lift, 9.4, from Customize kart in the Clubhouse of the pause menu in the Garage and the lobby,
and out of any room from the bay peeking in while the title's Clubhouse is up, 3.8,
and from Customize kart on the License tab of the settings, 8.5, unless they
are laid over a room. A dialog over
whatever opened it, as the catalog is, 8.8, headed YOUR KART on an enamel sign, and
put away by Back, a plate the Department of Karts printed as the bench's own is: its
screws, DEPT. OF KARTS between them and BACK in the plate's lettering. With room round
it, it stands in a frame of dark steel, rivets along it and a band of hazard stripes
along its foot with the Garage's motto across it, THE GARAGE · EVERY PART BACK IN ITS
PLACE; on a short screen, as a phone's, it fills the screen with no frame.

- **The kart.** The seat's own kart, big, standing on the floor of an old bay between the
  red posts of the Garage's two-post lift, let down, its arms folded along the floor: a
  block wall painted in two tones with a red line between, two green enamel shop lamps on
  their cords. The bay is built in 3D round it, a room: its back wall and a wall either side
  running on past the camera, far taller than any screen shows, under a dark ceiling, its
  concrete floor with an oil stain, the lift, a red tool chest and a stack of tires by the
  wall beside its posts, and the lamps, each a light seen in a faint haze. Along the left
  wall a workbench with a vise and a toolbox, a shelf of paint cans over it, a window high
  up and a fire extinguisher; along the right a rack of tires, an electrical panel, a racing
  poster, a clock and an air hose on its reel over an air compressor; two oil drums in a back
  corner, a stack of cones in the other, each with its own square foot, a floor jack by the
  left post and a broom against the wall. The story is in it only quietly, STORY.md 6.10: a
  calendar on the back wall left of the lift that is the Workbench's, Kit's last day ringed from the third stage and turned over
  once the last note is found, and right of the lift a cork board with the last six notes
  found pinned up on it, each in its paper's size and color, red string from pin to pin as
  somebody working something out would have it, a first-aid kit on the floor under it, and
  until a note is found the kit on the wall there instead; nothing is ever found here. The
  kart stands on a turntable let into the floor between the lift's posts, dark steel with
  two yellow stripes across it, which turns with it: turned by hand, to a part, or in one of
  its moves; left as it was while the kart is off it, and no marks laid on it, since it
  turns with the kart rather than under it. Filmed over the whole of the dialog
  inside its frame; the camera coming round to a part comes round
  the bay too, and the kart's shadow and its marks lie on that floor. The pegboards, the
  bench, the storage, the sign and the frame are drawn over it, flat, as they were over
  the bay's picture before it was built. It wears what it is dressed in. It turns by
  dragging it, by the mouse or a finger, a finger counted once rather than again as the mouse a
  phone makes of it, and the dialog keeping the screen's touches to itself, from the lift's
  touch controls and a room's menu under it; or by the right stick, the hand cursor over it only
  while it can be turned, standing on the lift and not behind the card back's hand of
  cards, which a small dark card
  over the bench's right end shows for the device in hand rather than says, a turntable's
  arrow beside the mouse, the finger or the stick; let go, it sways where it stands and
  drifts back to showing its back and its side. Standing, every so often it does
  something nobody asked it to, while no rack is out, whichever part is looked at: a jump,
  a wheelie, a quick spin, a rev of its engine, a shake as a wet dog's, a look round over
  either shoulder, three little hops, a tip onto the wheels of one side, and, seen standing,
  a drift or a donut out in front of the lift; its
  wheels going round, its trail thick behind it and its marks on the floor, and it jumps or
  spins for joy at a new piece put on, and does a donut in a shuffle: two whole turns,
  ending as it started rather than snapping back. A drift or a donut, the shuffle's or one of
  its own, is done out on the floor in front of the lift, where there is room for it: it
  drives out, the camera standing back, does it there, and drives back and hops up onto the
  lift. A move asked for in the middle of another,
  a shuffle pressed again in its donut, waits for that one to end, every move starting and
  ending with the kart as it stands, so they run on into each other without a cut.
- **Each part as it is best seen.** A part's rack out, or the cursor moved to its hook, has
  the kart turned to it at once, inside half a second, and the camera brought round with
  it: the hat from the front and close, the flag from the side, the plate from behind and
  low, the paint from a front corner. For the trail and the tire marks it drives laps on
  the open floor in front of the lift instead, clear of its posts, a wide circle round a
  traffic cone that pops up out of the floor for them and sinks into it after, drifting
  round it quickly as a donut is, a lap in two and a half seconds: its nose turned well in
  and swinging a little, its front wheels turned against it, its body leaning out of the
  turn, the white sparks of a match's drift off its rear wheels and its marks laid hard, the camera standing well back
  and higher for it, and staying back until it is home on the lift again; its trail streaming
  behind it and its marks laid on the floor, fading as they do in a match, so both are
  seen as they are when it moves. It turns round on the lift to face the way out first,
  then pulls off it on a curve that meets the laps at their near side and their own speed,
  the drift coming on as it joins them, and when another part
  is looked at it drives back, slowing, and hops up onto the lift; from wherever it is on
  the way, without a cut. The
  card back, which is on no kart, leaves it turned as it was, the camera standing back and
  a hand of five cards held up in front of it, drawn over the bay as the cards are drawn in
  a match and fanned as the joker hand is, a third bigger than a joker card, with no
  shadow round them: its backs in
  the back worn or the one the cursor is on in its rack, dealt up from below into a fan one
  card after another, swinging a little past their place and back, bobbing as it is held,
  turned over one after another to a new back, and dropped away as its rack is put back,
  the cursor left on its hook without it being looked at until it moves, or another part is looked
  at, the card back's rope tied to it; the shuffle leaves it standing,
  and so does the hook the cursor starts on as the dialog opens, the flag's, the top left
  one. Whatever flies from its
  pole feels the wind while it drives or does one of its moves, and while it is turned, by
  hand or to a part, and a second and a half after, the dice swinging on their strings and
  a flag round its pole; standing still, a flag hangs straight back off its pole, face on
  from the side, rather than left swung round it by the turning.
- **A hook for each part.** A pegboard stand either side of the lift, a black pegboard in
  a red steel frame on legs and casters, its foot saying half the motto, EVERY PART and BACK
  IN ITS PLACE: a shadow board, a hook on it for each part of the dress, the piece worn
  hanging from its peg on a black clip over its outline painted in yellow, the part
  stenciled beside it, the piece's name in marker on a strip of masking tape, and its
  finish under that where it has one. A hat or a flag hangs as the thing itself, filmed in
  a small world of its own; a paint as a patch of its pattern in the player's color, the
  card suits as the kart's own three stickers on it, a suit on a cream disc each; a trail
  as what it leaves behind; the plate in its frame; the marks it lays; the card back as the
  card, only on a profile's tab, a guest having none. The kart's back to the left, the flag,
  the plate's frame, the trail and the card back; its front and top to the right, the hat,
  the paint and the tire marks. The cursor on a hook, or its rack out, picks it out as a
  piece on the rack is, its tape gold and glowing and its outline lit, and the mouse over
  one the same in white. A hook looked at, its rack out, the cursor on it or the
  mouse over it, has a rope from the screw eye at its edge to where its part is on the kart,
  the hat's to the hat worn, upper middle, or the top of the driver's head with none,
  following the kart as it turns and drives; no other hook has one, so the bay is not a web
  of them.
- **The shuffle.** Where the last hook on the right would be, a machine's plate rather than
  a hook, so it is never pressed for one: hazard stripes round dark steel, a big red push
  button in a yellow collar with a die's face on it, and SHUFFLE stenciled by it over PARTS
  AND COLOR AT RANDOM. The mouse over it or the cursor on it lights the button; pressed, it
  goes down into its collar, its die's faces spinning down through it as a slot machine's
  reel does, round over the top and away under the bottom, drawn out by the speed, until it
  brakes, runs a little past one at random and settles back onto it; and it puts a piece of every part on the kart at random, of those
  won and everybody's, a card back on a profile's, and a color nobody else in the room is
  in, another than the one it was in, and keeps them. The option key, F or X,
  presses it from anywhere in the dialog, and its button goes down and its die spins as for
  a click.
- **The rack.** A hook pressed hangs the rack of its part over the bench, rising into its
  place from behind the bench's bottom edge, a little past and back, and dropping back
  behind it as it is put away; a pegboard of the
  stands' own make in a red frame, the part stenciled along its top with how many of it
  are won: every piece of the part hanging from a peg on a clip over its outline painted in
  yellow, its name on masking tape under it, the one worn in an outline of the house's gold
  with ON clipped to its corner. The part's None first where it has one, the trail's past
  its plain smoke, and its plain one first where it has none; then those won in the loyalty
  program, 8.9, and everybody's; then those not won yet, an outline painted in dashes with
  only a peg in it, a "?" stenciled there and the tape saying where in the program it is
  won, the landmark's own name. The cursor on a piece picks it out: its tape gold foil, a
  little bigger than the masking tapes beside it and glowing on the board, which reads on
  any screen however its gold and their white come out, its outline painted over brighter
  and thicker, the board inside it warmed and the piece lifted a little off its peg; the
  mouse over one the same in white. The cursor's frame slides from outline to outline as it
  goes. The cursor on a piece has the kart try it on, and so does
  the mouse over one, for as long as it is over it: gone off it, the kart wears what it
  did. Pressed, a piece is worn and kept, and the kart cheers; a piece not won is neither.
  More pieces than the rack holds scroll along it, by the cursor, a drag, or the chevrons
  stenciled on black plates at its ends, pressed a rackful at a time and faded where there
  is nothing more. Close, a black plate stenciled with a cross as the motto's plate is,
  screwed on and standing up over its top edge where it is easily found and pressed, Back, or the hook pressed again puts the rack away, the kart in what it
  wore. The keys that wear a piece and put the rack away are drawn along its top for the
  device in hand, Enter or a click and Escape, or A and B, and on a touch screen it says to
  tap a piece.
- **The bench.** Along the foot, under the kart: the colors as eight spray cans standing on
  it, the one in use lifted with its cap off on a spot painted in the house's gold, one
  somebody else in the room is in tagged with who and not to be pressed, 4.4. The mouse
  over a can, or the cursor on one, has the kart try its color on for as long as it is
  there, and only pressed is it kept. A paint chip card standing by the cans says which:
  COLOR over a swatch, the color's name, and whether it is the kart's own or being tried
  on, or that there is none yet. The name written in marker on masking tape, the die at the
  tape's right end rolling a name the house makes up, none the other tabs go by: picked up
  off the tape by the mouse or the cursor, tilted and rocking with a warm glow round it, and
  thrown when pressed: a cube tumbling over and over up off the tape, its faces coming
  round as a die's do, lit from above and its edges darker, hopping as it comes down and
  rolling to rest on another face, at random. And the plate screwed
  to the bench's front, typed onto as the License tab's is, once there is a license for
  it. A guest wears the profile playing's plate, the bench saying whose after the word PLATE,
  and a learner the L: the driving school's white square with its red L, as the kart wears
  it, screwed to the bench where the plate goes, only to be seen, saying itself. While the name or the plate is typed into, the binds of the keys
  that are letters, the page keys' and the shuffle's, are not shown: they are typed.
- **The cursor's ways.** Up and down either board and across the kart between them. The
  bench is two rows, the cans over the name, its die and the plate: down from the left
  board's bottom hook, the card back's or the trail's where there is no card back, to the
  first can; along the cans and down from any of them to the name; right from the name to
  the die and on to the plate, and back, or with no plate to type, the learner's L in its
  place, on to the shuffle; up from the name to the first can and from the die to the last;
  between the shuffle's plate and the plate. While the rack is out, down off
  either board is onto it.
- **Binds.** While keys or a pad are in hand, each of the dialog's buttons wears its key or
  pad button hung under it, as the other dialogs' do, Escape or B under Back, N or View under
  Next new while it is there, below, and F or X under the shuffle's button, Escape only while
  it would put the dialog away, not while a rack is out, which it puts away instead; what the
  cursor is on, and only that, Enter or A
  under it: a hook's piece, for the rack it opens, a can, the name's tape, the die and the
  plate; and the page keys show at the key board's end with more than one tab. None for the
  mouse alone, and none on a touch screen.
- **Tabs.** A key on the bay's key board for each seat at this machine in the room, a
  plastic fob in its color with the seat over its name, and after them a manila tag on a
  string for every other profile kept here, 8.5, each changed in its own file, its name in
  pen as big as fits across it, squeezed a little for the longest. The one the dialog is on
  hangs straight, lit, with a warm gold glow round it and a gold line round its edge; the
  others hang swung on their hooks, darker. The mouse on one picks it out the same way in a
  soft white, along its own shape, a little lighter and hanging nearer straight. Out of any
  room, the profile playing's key and the other profiles'. The page keys turn them, and so
  does a click or a tap on one. They hang from a timber rail along the top of the bay, from
  its left end past the page keys' glyphs nearly to Back; more than it has room for, they
  scroll along it: to keep the one the dialog is on in sight as the page keys turn them, by
  the mouse's wheel over the rail, and dragged along it by the mouse or a finger, flung on a
  little as they are let go, a key dragged rather than pressed not turned to, and a railful
  at a time by a fob at either end, a dark plastic one as the seats' keys are, hung under
  the rail from a split ring with a white chevron on it pointing the way, shown only toward
  more keys: at the rail's left end, or beside the page keys' glyphs while they show there.
  While there are more past an end, the keys fade out toward it, each fading across its own
  width, none past the rail's ends, and each laid on a whole pixel of the screen so that it
  does not shimmer as it moves. A key's picture is kept by its size rounded: moved along,
  a control's size drifts in its last places, and a picture looked for by that was drawn
  again, the key missing for that frame, which flickered.
- **New.** A piece of dress won in the loyalty program, 8.9, or moved up a finish by an edition
  there, is new until the dialog has shown it, as a card new in the catalog is, 8.8. Its place on
  the rack wears the gold NEW tag over its outline's top left corner, ON having the right, until
  the cursor, the mouse or a finger has been on it, and a screen reader hears it said; the hook of
  its part wears one over its outline's outer top corner, away from its tape, while its rack holds
  one, and the key of whose kart it is over its top right corner, swung with it and faded with the
  rail, while that kart has one, a guest's all but a card back, having none of its own. Next new,
  8.8, is a small plate of the Department's left of Back, in Back's make with its face pressed into
  it, saying how many are new on every tab, each profile's once: pressed, the cursor goes to the
  next new piece after where it is, the tab up's first, a hook at a time down the left board and
  then the right, each rack in its own order, then the tabs after it, round past the last; its tab
  turned to and its rack hung out with the cursor on it rather than on the piece worn, and the
  rings of its landing going out over the rack rather than cut off where its pieces scroll. What
  was seen is kept in each profile's file as the dialog goes. Only what is won from then on is new:
  a profile from before there was new dress has none, however much it had won, and everybody's
  pieces never are. While the profile playing has any, the ways in wear NEW too: Customize kart in
  the pause menu's Clubhouse where the room offers it, and on the Me tab, the title's bay over its
  sign's top left corner, the rest of it being off the screen's edge, and the Clubhouse, 3.8. Each
  tag is a picture of itself, so the bay's own pictures are kept as they are, 10.7.
- **In a room**, a change is worn at once, as a stall's is: here and on the host it is put on
  and said to every screen, and a client says it to the host, which puts it on, the snapshot
  bringing it back to every screen, 10.3. The Garage stands still under it, as under its
  pause menu.
- Storage in the bay's corners, for it to be a garage rather than a backdrop: a stack of
  tires and a box of BOLTS to the left, boxes marked SPARES and "??" and a drum of oil to the
  right.

## 5. Combat

### 5.1 Cannon and bullets

| Parameter                      | Starting value                                     |
|--------------------------------|----------------------------------------------------|
| Aim                            | Forward-only along the kart heading                |
| Trigger                        | Holding fire shoots at the cooldown rate           |
| Fire cooldown                  | 0.4 s                                              |
| Max live bullets per kart      | 3; a shot past it is refused, with a dry click and a puff of smoke at the muzzle, once a cooldown while the trigger is held, for a player at that machine |
| Bullet speed                   | 17 m/s, about 1.6 times kart top speed             |
| Bullet radius                  | 0.15 m                                             |
| Bounces                        | 0 by default, destroyed on wall contact; Rubber Bumpers and the Ricochet Cannon add one each |
| Lifetime                       | 3 s                                                |
| Muzzle                         | 1.0 m ahead of the kart center                     |
| Own bullets                    | Stopped by the owner and destroyed either way, harmless by default and deadly with the lobby option in 3.8 turned on. A kart's turret and decoy shoot its own bullets, so the same answer covers those |
| Bullet vs bullet               | Both destroyed, unless they came from the same cannon, which lets a spread leave the barrel |
| Bullet vs crate                | Both destroyed, crate drops its chips              |
| Bullet vs spawn-protected kart | Passes through                                     |
| Bullet vs shielded kart        | Shield pops, bullet destroyed                      |
| Bullet vs turret or decoy      | Target destroyed, bullet destroyed                 |

Bullets are Area3D nodes moved by raycast every physics tick so they cannot
tunnel through walls or karts at any speed. Every bullet knows its owner and is
tinted in the owner's color with a short trail. Cannon types and jokers may
change any value in this table.

A shot whose muzzle sits inside a wall or a crate, because the kart or turret
is pressed against it, is checked from the shooter's center: a crate in the
way still breaks, a wall just eats the bullet, and nothing passes through or
bounces back into the shooter.

### 5.2 Aim assist

To make forward-only aiming forgiving, bullets bend slightly toward targets. The bend stops
at the first bounce and the accessibility setting in 8.5 scales it, down to nothing.

The assist is for a shot taken on the move. A kart sat still with its nose down a corridor is
not taking a hard shot, and helping it there turns a parked kart into a turret, so the bend
fades away while one stands about and comes straight back when it drives off.

Everything worth shooting counts as a target, not only karts: a box broken is cover gone and
coins on the floor, a bomb set off from across the room does more than a bullet ever does, and
a shooting target pays. So is the waiting room's football of 9.6, which is all there is to aim
at in there. But none of that wins a match, so a kart always comes first: it is
weighed as though it were much nearer than it is, and a box has to be well inside one before
the shot goes to the box instead.

The bend cannot go round anything, so nothing it could not reach is aimed at. A player standing
behind a wall is passed over for whatever is on this side of it, and a shot fired past the edge
of a wall is left alone rather than curved into the brickwork. Curve Ball made the want of this
obvious, bending hard enough to bury a shot in a wall the player was deliberately shooting past. Two
jokers change this: Curve Ball bends much harder and keeps bending after a bounce, and
Aimbot turns the shot toward the nearest enemy as it leaves the barrel. Both work at their
own strength whatever the accessibility setting says.

| Parameter    | Starting value                                                  |
|--------------|-----------------------------------------------------------------|
| Cone         | Targets within 15° of the bullet heading                        |
| Range        | 15 m                                                            |
| Turn rate    | At most 50°/s                                                   |
| Active       | Until the first bounce                                          |
| Targets      | Enemy karts, decoys, turrets, crates, bombs and shooting targets. Never the owner, never spawn-protected karts |
| Priority     | A kart counts as 0.4 of its real distance away, so a player is chosen over a box twice as near |
| Direction    | Only what is inside the cone is considered at all, so nothing behind the shot takes the aim off what is in front of it |
| Line of sight | Anything with a wall or a box between it and the shot is passed over; the bend cannot go round either |
| Standing still | Under 22% of top speed for 1.2 s, then the bend fades over 1.5 s to a quarter of itself; driving off restores it at once |

Turret bullets and Swivel Cannon bullets have no aim assist.

### 5.3 Cannon types

The default cannon is described above. Power-ups temporarily replace it, see
7.1: Ricochet Cannon, Spread Cannon and the free-aiming Swivel Cannon. Jokers
can permanently modify the cannon's stats. The mouse and a finger on a touch
screen aim a player's Swivel Cannon and nobody else's: a bot's points down its
nose, rather than wherever the host's pointer happens to be.

### 5.4 Health

Karts have two lives, see 3.6: the first hit wounds, the second kills. A
wounded kart is darker, drives at 85% top speed, is untouchable for 1.2 s
while it blinks, and gets its life back on the Junction or by taking somebody
out. The Shield power-up absorbs a hit without costing a life; spawn
protection makes the kart untouchable.

## 6. Arena

### 6.1 Layout rules

- The whole arena fits on one 16:9 screen with the fixed camera. Playable area
  of the first map: 37.5 m by 20 m, surrounded by walls, 40 m by 22.5 m total.
- The layout has two-fold rotational symmetry so that no spawn is favored.
- The Junction is in the center and reachable from all sides, with hazards or
  cover near it so that banking is never a free walk.
- Cover is partial. Bullets only bounce with Rubber Bumpers or a Ricochet Cannon,
  so cover is worth something, but no spot is safe from every angle.
- Keep it simple: a handful of wall segments, a few crates and pits, four turbo
  pads. No moving hazards in the first map.
- Maps are Godot scenes. Markers in the scene define spawns, pads, zones and
  the Jackpot spots. Adding a map means adding a scene.

### 6.2 Elements

| Element        | Behavior                                                              |
|----------------|------------------------------------------------------------------------|
| Wall           | Solid, bounces bullets, stops karts                                    |
| Crate          | Destructible cover, see 3.2                                            |
| Pit            | A real hole: a shaft cut through the felt and the table. Karts that enter fall for 0.4 s and die, see 3.6. Bullets fly over it |
| Turbo pad      | Directional speed boost, see 4.1                                       |
| Coin pad       | Spawns chips, gold chips and mult dice, see 3.2                        |
| Power-up pad   | Spawns a held item, see 7.1                                            |
| Flush pad      | Takes the color of the last kart over it; all four in one color score a Royal Flush, see 3.9 |
| Target         | A shooting-gallery plate at bullet height. A bullet knocks it down and pays the shooter 3 coins; it comes back after 4 s. Karts bump into the post |
| Joker pad      | Keeps a joker lying on it, another one 6 s after it is taken. Used by the Garage in 9.4 |
| Junction pad   | Cash-out zone, circle of radius 2.5 m, see 3.4                         |
| Jackpot zone   | Growing chip pile, 2.5 m square, see 3.5                               |
| Spawn point    | 4 points near the corners                                              |

### 6.3 Maps

Three arenas, all 32 by 18 cells of 1.25 m, all holding the same furniture: a
Junction in the middle, two Jackpot zones, two pits, four Royal Flush pads, eight
spawn points, four turbo pads, two slot machines, coin pads, item pads and crates. What differs is
the shape of the room around them. Each has an XL map as well, see The XL maps
below: the same map made roomier, in the same room.

The lobby picks one and remembers it. Online it is the host's pick: the map rides
the wire with the rest of the host's settings, see 10.3, and a client builds
nothing at all until that message has landed rather than guessing from its own
lobby and driving round the wrong room.

#### Lucky Crossing

The open one. Long lanes top and bottom, short walls screening the Jackpots from
the center, and the pits above and below the Junction, a lane's width clear of it.

```
################################
#..............................#
#.S....C..s..F.......s..C....S.#
#.....####..B......B..####.....#
#..P......T....XX....T......P..#
#....C.........XX.........C....#
#.......B....C....C....B.......#
#........#....JJJJ....#........#
#...KK...#$...JJJJ....#...KK.F.#
#.F.KK...#....JJJJ...$#...KK...#
#........#....JJJJ....#........#
#.......B....C....C....B.......#
#....C.........XX.........C....#
#..P......T....XX....T......P..#
#.....####..B......B..####.....#
#.S....C..s.......F..s..C....S.#
#..............................#
################################

#  wall          S  spawn point      C  coin pad       P  power-up pad
s  spawn point past four karts
J  Junction pad  K  Jackpot zone     T  turbo pad      X  pit
R  target        D  joker pad       O  portal
B  crate         .  floor            F  Royal Flush pad
G  gate, a piece of wall that opens, see 9.4a
$  slot machine, see 3.15
```

Every element is optional. A map with no `J` in it has no Junction, and nothing
that reaches for one finds one; the driving test's lot of 9.4a holds its Junction back until its
fifth lesson. A map may hold several, each banking as the one does.

- The four turbo pads point along the vertical lanes at columns 10 and 21,
  each toward the opposite pad, so karts can rocket past the Junction's flanks.
- The pits sit above and below the Junction, a cell of floor clear of it, so
  approaching from the top or bottom means going around them, while the coin pads
  beside that gap reward the risk. They sat right against the pad once, and a kart
  pushed off the Junction's edge went straight down.
- The short vertical walls screen the Jackpot zones from the center, so a kart
  collecting the Jackpot can only be shot from the top or bottom lane, or by a
  bouncing bullet.
- The four Royal Flush pads sit on a ring: two on the top and bottom lanes and
  two behind the Jackpot zones, so a flush is a lap of the arena.
- The two slot machines, `$`, sit across the middle from each other, out of the
  way of karts going past, see 3.15: on Lucky Crossing lying along the walls left
  and right of the Junction, in the Vault along the walls of its room in the
  corners by a coin, on Crossfire against the walls over and under the Junction,
  and on House Rules along a wall in the pockets beside the Flush pads. The XL
  maps have theirs as their own maps do, the Vault's lying across its room's
  corners. A `$` with a wall right beside it, left or right, turns to lie along
  that wall, in the middle of its stretch, its reels read from the room; one with
  a wall right over or under it stands in the middle of that wall across, so
  Crossfire's pair stand on its middle line rather than half a cell either side
  of it. The showdown's room, with no chips in it to bet, has none.
- Four spawn points are in the corners, `S`, and four more, `s`, are for a room of
  more than four karts, see 9.3. A match of four starts in the corners and comes
  back to life in them, as it always has. The fifth kart on starts on an `s`, and
  the sixth on its twin across the middle of the room, so a match of six has one
  more at each end rather than two at one; once there are more than four karts a kart
  coming back to life may come back on any of the eight. The `s` discs are only on
  the floor while there are: in a match of four they are spawns nobody starts on,
  and a disc says somebody does, so they are put down as the fifth kart arrives,
  on every screen. Each `s` sits out toward
  the walls with a clear run at the Junction it faces: never a pit or a turbo
  pad in the way, and never in a lane a turbo pad fires down.

#### The Vault

The Junction is inside a walled box with four ways in, two wide and two narrow.
Banking is a room you have to go into and come out of, so a pot taken in there is
a pot somebody can corner. The coin pads inside pay for the risk, the Jackpots sit
in line with the narrow doors, and the pits are out in the open where the running
is fast.

```
################################
#..............................#
#.S..F.....>C..P...C<.....F..S.#
#..............s...............#
#........#####....#####........#
#.....XX.#.CB......BC.#........#
#.C...XX.#...........$#.B....P.#
#........#....JJJJ....#.B......#
#.sKK.........JJJJ.........KK..#
#..KK.........JJJJ.........KKs.#
#......B.#....JJJJ....#........#
#.P....B.#$...........#.XX...C.#
#........#.CB......BC.#.XX.....#
#........#####....#####........#
#...............s..............#
#.S..F.....>C...P..C<.....F..S.#
#..............................#
################################
```

#### Crossfire

Four diagonal walls leaning away from the middle, so every approach to the
Junction is a corner and the two side lanes pinch to a gap with a pit in it. The
Jackpots are behind a wall at the top and bottom, reachable only round the ends,
which makes collecting one a commitment rather than a detour.

```
################################
#.......C..F..KKKK.............#
#.S...C..s....KKKK....s..C...S.#
#............######............#
#...P#...B......$.........#P...#
#.v...#....C........C....#...^.#
#......#....B......B....#......#
#.......#.....JJJJ.....#.......#
#.C.F...X#....JJJJ....#X.......#
#.......X#....JJJJ....#X...F.C.#
#.......#.....JJJJ.....#.......#
#......#....B......B....#......#
#.^...#....C........C....#...v.#
#...P#.........$......B...#P...#
#............######............#
#.S...C..s....KKKK....s..C...S.#
#.............KKKK..F..C.......#
################################
```

#### The XL maps

Lucky Crossing XL, The Vault XL and Crossfire XL are their maps made roomier: 42 by
24 cells rather than 32 by 18, so a third again each way and nearly twice the
floor, in the same room as the map they are the XL of, lit, crowded and dressed the
same way. They are maps of their own, picked from the same list as any other,
since a map is a floor plan and some later maps may only come in one size.

The usual size is drawn for four karts, and more than four on it is a crowd: a
room of up to eight, 9.3, plays the XL instead. Once the arena has more than four
seats the match settings carry Small maps for 5+ karts, off to start with. Off, a
map at the usual size that is about to be played with more than four karts is
played as its XL, whether it was picked for a quick match or dealt in a Grand
Prix, 9.7, and the arena row says so under the map; on, the map is played as
picked, for a crowd somebody wants. It counts karts rather than people, since a
bot takes as much room as anybody, and it is decided as the map starts, when
everybody who is going to play it is there. A run that plays a map as its XL
still never plays the same room twice running, since a map and its XL are one.

They keep the furniture of their maps, a little more of the coins and crates and
the same number of everything else, spread over the bigger floor, and hold to a
few rules the usual maps were too cramped for:

- Every pit has two cells of open floor all the way round it, and four between it
  and the Junction, so a kart pushed off the pad has somewhere to go that is not
  down.
- Every turbo pad launches down at least eight cells of open lane with no hole in
  it, so it never drives a kart into a wall or a pit. Its pads are sections of two
  side by side, so a section is easy to hit at speed. Pads side by side that point
  the same way launch as one pad: as two, a kart driven down the line between them
  had its center on the edge of both, well onto neither, and went through without
  a launch.
- No lane narrower than three cells.

On a bigger floor the lamp over the table widens to keep its corners as far inside
its cone as the usual floor's are, the
disco heads reach as far again across it and the shadows are drawn out as far as
the camera now stands back, all only past the size the usual maps are; and the
bots look as far again for somebody to hunt and wander as far round the Junction,
where on the usual reach they hung about the middle.

```
##########################################
#........................................#
#.S......C...s..F...........s...C......S.#
#..............B..........B..............#
#......#####........XX........#####......#
#..P.............C..XX..C.............P..#
#..........B.TT............TT.B..........#
#.....C............................C.....#
#.......B........C......C........B.......#
#.........#....................#.........#
#.........#........JJJJ........#.......F.#
#....KK...#........JJJJ.......$#...KK....#
#....KK...#$.......JJJJ........#...KK....#
#.F.......#........JJJJ........#.........#
#.........#....................#.........#
#.......B........C......C........B.......#
#.....C............................C.....#
#..........B.TT............TT.B..........#
#..P.............C..XX..C.............P..#
#......#####........XX........#####......#
#..............B..........B..............#
#.S......C...s...........F..s...C......S.#
#........................................#
##########################################
```

```
##########################################
#........................................#
#.S...F.......>C.....P....C<.......F...S.#
#.............>............<.............#
#........B..........Cs..........B........#
#...........######......######...........#
#....XX.....#.CB..........BC.#...........#
#.C..XX.....#..............$.#...........#
#...........#................#...B.....P.#
#..C........#................#...B.......#
#..................JJJJ..................#
#.s..KK.......C....JJJJ............KK....#
#....KK............JJJJ....C.......KK..s.#
#..................JJJJ..................#
#.......B...#................#........C..#
#.P.....B...#................#...........#
#...........#.$..............#.....XX..C.#
#...........#.CB..........BC.#.....XX....#
#...........######......######...........#
#........B..........sC..........B........#
#.............>............<.............#
#.S...F.......>C....P.....C<.......F...S.#
#........................................#
##########################################
```

```
##########################################
#.........C...F....KKKK..................#
#.S....C...s.......KKKK.......s..C.....S.#
#.........B.........CC...................#
#................########................#
#.vv.P.#.....B.......$............#.P.vv.#
#.......#......B..........B......#.......#
#........#.....C..........C.....#........#
#.........#.....B..............#.........#
#..........#..................#..........#
#...........#......JJJJ......#...........#
#.C.F..XX...#...C..JJJJ......#...XX......#
#......XX...#......JJJJ..C...#...XX..F.C.#
#...........#......JJJJ......#...........#
#..........#..................#..........#
#.........#..............B.....#.........#
#........#.....C..........C.....#........#
#.......#......B..........B......#.......#
#.^^.P.#............$.......B.....#.P.^^.#
#................########................#
#...................CC.........B.........#
#.S.....C..s.......KKKK.......s...C....S.#
#..................KKKK....F...C.........#
##########################################
```

#### House Rules

The story's own map, 8.7: the Count Room's, 8.1, which nobody plays before the story's Final Hand
and which joins a quick match's list after it for a profile that has played it with its story on,
STORY.md 8.2 and 10. No Grand Prix deals it, and its id goes on the end of the list of maps like any
new map's, so every machine can load it when a host picks it. One size only, with the four starts
past the corners every map has for a room of eight. The same furniture as every map,
laid out in a lattice no person would have drawn: the walls are short rows of server racks, two
blocks of them on either side with a cross aisle through the middle where the Junction is, and a
rack across the floor above and below it. The Jackpots are inside the rack blocks, between two rows,
so collecting one is standing in a corridor with a way in at either end; the pits are floor tiles
lifted out of the raised floor in the cross aisle, beside the Junction; the turbo pads are cooling
vents along the top and bottom lanes and up and down the outer ones. Every row of racks stops two
cells short of the edge, so the lanes round it are two wide at their narrowest.

```
################################
#.S.....s..>....P............S.#
#............C......B....C.....#
#...#KK.#............C.#...#...#
#...#KK.#...########...#$F.#...#
#...#...#.....B........#...#..v#
#.P.#...#...C.....C....#...#...#
#.....C...XX..JJJJ....B.....s..#
#.F.......XX..JJJJ.B...........#
#...........B.JJJJ..XX.......F.#
#..s.....B....JJJJ..XX...C.....#
#...#...#....C.....C...#...#.P.#
#^..#...#........B.....#...#...#
#...#.F$#...########...#.KK#...#
#...#...#.C............#.KK#...#
#.....C....B......C............#
#.S............P....<..s.....S.#
################################
```

At the story's Final Hand, and only there, STORY.md 8.2, the house plays against the candidate on
it. From half way a rack rises out of the raised floor where its forecast of a kart ends, two tiles
across the road capped in gold, stands a few seconds and sinks, a wall to drive into and never a
death, and about one time in four a gold
turret of the house's rises in a rack's place, owned by nobody, and fires a burst at the forecast
rather than at the kart. From three quarters the three bots follow the candidate's own line, 9.1.
The racks and the turret are the host's, sent to clients as the turret power-up is, and never rise
on a pad, the Junction, a pit or a start; bots are routed round a rack while it stands. Played after
the ending, House Rules is a map like any other.

#### Showdown

The tie-breaker's map, 9.7a: a small room for a fight to the last kart, with nothing in it to buy
or bank. No Grand Prix deals it: it is a tie-breaker, not a map of a run. A quick match's list offers
it all the same, last, in every build, and picked there it is a showdown for everybody in the room,
won by the last kart standing; like a run's, it counts toward nothing, 9.7a, so a short one against a
single bot is no way to fill the program's bets. Its id goes on the end of the list of maps like any
new map's, so every machine can load it when a host starts one.

28 by 16 cells, three-quarters of a usual map's floor, and none of the furniture every other map
holds: no Junction, no Jackpots, no coin pads, no Royal Flush pads, no pits and no turbo pads. What it
has is a few walls, 44 crates and four power-up pads. Its eight spawn points are the four
corners, `S`, for a fight of four or fewer, and four more, `s`, past them, and each is tucked away so
that no spawn point has a line to any other: a showdown starts with everybody having to go and find
somebody. Each corner is a bay behind two short arms off the walls, open toward the middle between
them; along the top and the bottom a spawn point waits in a corridor behind a long wall; each side
has one behind a wall of its own; and the middle is open floor round a post two cells square, the
crates standing either side of it as two brackets that open toward it. Six pieces of wall in all,
the room's own counted, and never less than two cells between any two of them, nor between a wall
and a crate standing on its own, so nowhere is a squeeze. And every spawn point starts sealed in: a
row of crates stands across every way out of its bay, corridor or alcove, so the first thing anybody
does is shoot their way out, which buys the room a few seconds before anybody meets anybody.

```
############################
#S...#.......s........#...S#
#....#................#....#
#....BBBBB########BBBBB....#
#....B................B....#
###BB#.....P....P.....#BB###
#....#...BB......BB...#....#
#s...#...B...##...B...#....#
#....#...B...##...B...#...s#
#....#...BB......BB...#....#
###BB#.....P....P.....#BB###
#....B................B....#
#....BBBBB########BBBBB....#
#....#................#....#
#S...#........s.......#...S#
############################
```

It has no room of its own to be dressed in. A showdown is played in the room the run ended in, the
same room its party is put up in after it, 9.7: the run's last floor taken away and this one put
down. Picked in a quick match it is dressed as After Hours.

## 7. Power-ups and jokers

### 7.1 Power-ups

Power-ups are held items, Mario Kart style: a kart holds at most one and uses
it with a button. Picking up a pad while already holding an item is not
possible; the pad keeps its item.

| Parameter            | Starting value                                        |
|----------------------|-------------------------------------------------------|
| Pads in the first map| 4                                                     |
| Pad respawn          | 15 s after pickup                                     |
| Item selection       | Weighted random from the table below, revealed after a 0.5 s roulette flicker on pickup |

First set:

| Power-up        | Weight | Effect                                                                          |
|-----------------|--------|---------------------------------------------------------------------------------|
| Boost           | 25     | 3 s: +50% top speed, steering at 80%, ramming kills. You remain vulnerable to bullets |
| Shield          | 25     | Absorbs one bullet or ram, then pops. Expires after 10 s                        |
| Turret          | 15     | Deploys a turret at your position. Rotates at 180°/s toward the nearest enemy, fires 1 default bullet per second. Lives 20 s or 1 hit. Kills credit you. Can hit you |
| Ricochet Cannon | 20     | Next 8 shots bounce off walls once more and fly 25% faster                      |
| Chip Magnet     | 15     | 8 s: pickup radius times 3, chips within it drift toward you at 6 m/s           |
| Oil Stain       | 20     | Leaves a slick 1.8 m behind you for 25 s. Any kart whose center crosses it, you included, spins out. It never kills. The slick lies a little above the floor, clear of the Junction, the Jackpot tiles and every pad: those all stand proud of the floor, and a slick at floor level vanishes inside whichever one it was dropped on, which is exactly where somebody wants to drop one |
| Bomb            | 20     | Drops a bomb 1.8 m behind you. It arms after 0.6 s and blows up when any kart, you included, drives over it, when a bullet hits it, or after 30 s. The 2.6 m blast kills karts, breaks crates and turrets and sets off other bombs. Kills credit you |

Later set, off by default and switched on per match in the lobby, each in a game once the
loyalty program of 8.9 has added it for the table:

| Power-up        | Effect                                                                          |
|-----------------|---------------------------------------------------------------------------------|
| Decoy Kart      | Spawns a bot kart in your color with a random trait, see 9.1. Lives 20 s or 1 hit. Its kills and chips credit you. Can hit you |
| Spread Cannon   | Next 6 shots fire 3 bullets in a 20° fan. The live bullet allowance triples with the fan, so the fan counts as one shot |
| Swivel Cannon   | 12 s of free aim with the right stick, the mouse or a finger, no aim assist     |
| Bullet Wipe     | Erases every bullet within 8 m                                                  |

Nothing in a match says more of an item than its picture and its name: it is held for a second or
two, 8.3a. The catalog of 8.8 says the rest, each item's sentence of what it does and the numbers
in the tables above that the HUD never shows, how long it lasts, how many shots and how far it
reaches, read from the item itself so the two can never say different things. The sentence goes
without numbers for that reason.

### 7.2 Owned turrets and decoys

- Everything a turret or decoy does is attributed to its owner: kills give the
  owner +1 mult, coins a decoy collects go into the owner's pot.
- A decoy cannot collect the Jackpot and does not count as somebody standing in
  it, the same as it cannot claim a Royal Flush pad in 3.9. Parking one on the pile
  was worth more than driving there for it, and it blocked whoever did.
- They can hurt their owner, who receives no credit for that.
- A decoy always shoots, whatever trait it is dealt: one that held its fire, or rammed rather than
  shot, for its twenty seconds was no use to anybody, and its owner's Dead Ringer, 8.10, could never
  come of it.
- They are destroyed by one hit and count as targets for aim assist and grazes
  by other players.
- Decoys collide with karts like karts do. Ramming a decoy or a turret with
  Boost destroys it; without Boost it is only a bump.

### 7.3 Joker catalog

Mostly rule benders, some stat tweaks, a few cursed jokers with a big upside and
a real downside. Starting set; balance is untested.

From the story's second stage, 8.7, the pane that describes a card carries one line of small print
under its effect: the term the card is, in the house's words, "Formerly a day of the month." under
Payday. The lines are in STORY.md 6.3, and a joker added here gets its line there in the same change.
The Effect column below is still the whole of what a card does. Every card a profile has taken is
kept for it and can be looked up from the title in the catalog of 8.8, and the ones it never took
lie face down there. Twenty-seven of them are in every deck from the start, and the loyalty
program of 8.9 adds the other twenty, a few at a time. Every joker has a suit, see Suits below.

| Joker            | Rarity   | Kind   | Suit | Effect                                                                    |
|------------------|----------|--------|------|---------------------------------------------------------------------------|
| Hair Trigger     | Common   | Stat   | ♠ | Fire cooldown -30%                                                        |
| Big Tank         | Common   | Stat   | ♠ | +2 max live bullets                                                       |
| Magnet Hubcaps   | Common   | Stat   | ♦ | Pickup radius times 2                                                     |
| Nitro Habit      | Common   | Stat   | ♣ | Drift exit boosts and turbo pads last three times as long                 |
| Slipstream       | Common   | Rule   | ♣ | Grazes give +1.5 mult instead of +0.5                                     |
| Green Light      | Common   | Rule   | ♣ | Turbo pads give +1 mult                                                   |
| Vulture          | Common   | Rule   | ♦ | Chips dropped by other karts are worth 3 chips to you                     |
| Odometer         | Common   | Rule   | ♦ | +1 chip for every 20 m you drive, the meters you burn nitro for counting double                                          |
| Spare Tire       | Common   | Rule   | ♥ | One more life. The death that takes the last one takes the tire too, never dropped |
| Insurance Policy | Uncommon | Rule   | ♥ | Bank all that is left of your pot on death                                |
| Tight Grip       | Uncommon | Rule   | ♥ | Your pot never spills: no chips dropped on death or knocked out by a ram  |
| Getaway Driver   | Uncommon | Rule   | ♦ | Junction drain ramps twice as fast, D = 0.25 s                            |
| Pickpocket       | Uncommon | Rule   | ♦ | Kills move 50% of the victim's chips into your pot; the victim drops none |
| Rubber Bumpers   | Uncommon | Rule   | ♠ | Your bullets bounce off walls once more                                   |
| Comeback         | Uncommon | Rule   | ♥ | Respawn with mult equal to half your mult at death, rounded up            |
| Loaded Dice      | Uncommon | Rule   | ♦ | Every chip has a 25% chance to count as a gold chip                       |
| Toll Booth       | Uncommon | Rule   | ♦ | Whenever another kart completes a cash-out, you bank 15% of it            |
| Tailslide        | Uncommon | Rule   | ♣ | +1 chip for every 8 m you drift                                           |
| Guardian Angel   | Uncommon | Rule   | ♥ | A hit about to cost you a life uses the Shield or Bullet Wipe you hold instead, the moment it lands: a Shield takes any hit, a Bullet Wipe a shot only. An item still being rolled for off a pad is not yours yet. Its card pulls out of the hand and glows when it does, see 8.3. An item it will spend wears the joker's halo, a flat ring of gold, over its picture in your corner, and its chip beside the kart is rimmed in full gold under the halo too |
| Jerry Can        | Uncommon | Stat   | ♣ | Nitro refills 4x as fast                                                  |
| Direct Debit     | Uncommon | Rule   | ♦ | 5 points of your pot bank themselves every second, wherever you are. Your mult is left alone |
| Payday           | Uncommon | Rule   | ♦ | +1 chip every second, wherever you are and whatever you are doing        |
| High Roller      | Uncommon | Cursed | ♣ | All mult gains are doubled, but death banks 0%                            |
| Curve Ball       | Uncommon | Rule   | ♠ | Your bullets curve hard toward enemies: a 55° cone out to 22 m at 150°/s, and they keep curving after a bounce |
| Aimbot           | Rare     | Rule   | ♠ | Every shot leaves the barrel turned up to 14° toward the nearest enemy within 20 m and in front of you |
| Backfire         | Uncommon | Rule   | ♠ | Holding the brake, or drifting, points your cannon out of the back of the kart, so you can answer whoever is behind you without turning round and losing the ground. The aim guide follows it. Free aim overrules it: a hand on the Swivel Cannon has already said where the shot goes |
| Road Rage        | Uncommon | Cursed | ♣ | Ramming above 90% of top speed kills without Boost, but top speed is -10% |
| Snake Eyes       | Uncommon | Cursed | ♣ | Start every life with mult 3, but grazes give nothing                     |
| Scar Tissue      | Uncommon | Cursed | ♥ | One more life, but neither the Junction nor a kill heals you: only coming back does. Stacks with Spare Tire, and nothing heals |
| Lucky Seven      | Rare     | Rule   | ♣ | Every 7 chips you collect give +1 mult, counted by what they are worth, so a gold chip is five of them                                  |
| Hot Streak       | Rare     | Rule   | ♣ | +0.5 mult every 10 seconds you stay on the floor                          |
| Deep Pockets     | Rare     | Rule   | Wild | +2 joker slots, one of which it stands in                                 |
| Wild Card        | Rare     | Rule   | Wild | Respawn offers 5 jokers instead of 3                                      |
| Carbon Copy      | Rare     | Rule   | Wild | A joker your death drops goes on the floor as a copy, and you keep your own, Carbon Copy among them. A card thrown away from the hand is thrown away |
| Glass Jackpot    | Rare     | Cursed | ♦ | Completed cash-outs pay 150%, but dying drops all your chips and 2 jokers |
| Double Tap       | Uncommon | Rule   | ♠ | Your bullets wait out only half of a wounded kart's moment of grace, 3.6, before they can hit it again |
| Cushion Shot     | Uncommon | Rule   | ♠ | +1 chip every time one of your bullets bounces off a wall |
| Snowball         | Rare     | Rule   | ♠ | Fire rate +10% for every kill this life, up to +50% |
| Second Wind      | Uncommon | Rule   | ♥ | Come back with a full tank of nitro and a Boost running, 7.1 |
| Daredevil        | Uncommon | Rule   | ♥ | A graze while you are wounded patches you up |
| Burnout          | Uncommon | Rule   | ♣ | Your jokers count every drift boost as a turbo pad |
| Copy Cat       | Rare     | Rule   | Wild | Counts as one more copy of the joker just before it in your hand, even past its most. Only a joker that stacks |
| Flush Draw       | Rare     | Rule   | Wild | Two cards of a suit are enough to be Suited |
| Royal Court      | Rare     | Rule   | Wild | Come back with +1 mult for every Cursed joker you hold |
| Echo             | Rare     | Rule   | Wild | Your jokers that pay chips or mult pay it again one time in four. Its card says ECHO, at most once in a second and a half |
| Lucky Charm      | Uncommon | Rule   | ♦ | Slot machines, 3.15, pay you a step better: a pair as three of a kind, three of a kind as three sevens |
| Pit Crew         | Uncommon | Rule   | ♣ | Turbo pads refill half your nitro tank, all of it with two, at most once every 3 s: with Burnout every drift boost is a pad, and nitro is not meant to be endless, 4.1 |

#### Kit's cards

Five more jokers, in every machine's catalog but dealt only by the story, 3.7 and STORY.md 6.3:
drawn in pencil over the face of a house card, Kit's line along the foot where the house's term
would go, and of no suit, so none counts toward Suited. Each has a cost. Starting values, untested:

| Card | Effect | Cost |
|---|---|---|
| Brake Check | A dead stop with chips in the pot adds 1 mult, up to 3 a life, once every 8 s | 10% off top speed |
| Not Today | A pick skipped adds 2 mult for that life | Each house card taken takes 1 mult off |
| Blind Spot | Bots aim at where the kart is, never where it is going | No standings board while it is held |
| Loose Change | Chips the kart drops never fade back to the house | It drops half again as many |
| Under the Table | Its banked score is off the standings until the whistle: no bounty and no match point on it | Last Call pays it single |

#### Stacking

Most of the jokers that hand out a number stack: a hand that holds one is
offered it again at the respawn pick, and takes it off the floor again, until
the stack is at its most. Each copy is a card of its own in the hand. The most
keeps a stack from running away with a match: three for all of them but Wild
Card, whose seven cards are as many as the pick has room for on a phone, and the
two that are lives, since two more lives already double the rules' own two.

| Joker          | One copy           | Every copy past the first | ×2          | ×3          | Most |
|----------------|--------------------|---------------------------|-------------|-------------|------|
| Payday         | +1 coin a second   | +1 coin                   | 2 coins     | 3 coins     | 3    |
| Odometer       | +1 coin per 20 m   | +1 coin                   | 2 coins     | 3 coins     | 3    |
| Tailslide      | +1 coin per 8 m    | +1 coin                   | 2 coins     | 3 coins     | 3    |
| Green Light    | +1 mult a pad      | +1 mult                   | +2          | +3          | 3    |
| Hot Streak     | +0.5 mult per 10 s | +0.5 mult                 | +1          | +1.5        | 3    |
| Lucky Seven    | +1 mult a 7 chips  | +1 mult                   | +2          | +3          | 3    |
| Direct Debit   | 5 points a second  | +5 points                 | 10          | 15          | 3    |
| Loaded Dice    | 25%                | a roll of its own         | 44%         | 58%         | 3    |
| Big Tank       | +2 bullets         | +2 bullets                | +4          | +6          | 3    |
| Rubber Bumpers | 1 bounce           | +1 bounce                 | 2           | 3           | 3    |
| Deep Pockets   | +2 slots           | +2 slots                  | +4          | +6          | 3    |
| Aimbot         | 14°                | +7°                       | 21°         | 28°         | 3    |
| Curve Ball     | 150°/s             | +75°/s                    | 225°/s      | 300°/s      | 3    |
| Toll Booth     | 15%                | +10%                      | 25%         | 35%         | 3    |
| Vulture        | 3 coins            | +1 coin                   | 4 coins     | 5 coins     | 3    |
| Slipstream     | +1.5 mult          | +0.5 mult                 | +2          | +2.5        | 3    |
| Nitro Habit    | 3 times as long    | once as long again        | 4 times     | 5 times     | 3    |
| Jerry Can      | 4x as fast         | 2x more                   | 6x          | 8x          | 3    |
| Getaway Driver | twice as fast      | once as fast again        | 3 times     | 4 times     | 3    |
| Hair Trigger   | cooldown -30%      | 3 shots in 7 more         | -46%        | -56%        | 3    |
| Double Tap     | ½ the grace        | half again                | ¼           | ⅛           | 3    |
| Cushion Shot   | +1 coin a bounce   | +1 coin                   | 2 coins     | 3 coins     | 3    |
| Magnet Hubcaps | radius times 2     | twice the ground          | times 2.8   | times 4     | 3    |
| Wild Card      | 5 cards            | +2 cards                  | 7 cards     |             | 2    |
| Spare Tire     | 1 life more        | +1 life                   | 2 lives     |             | 2    |
| Scar Tissue    | 1 life more        | +1 life                   | 2 lives     |             | 2    |
| Pit Crew       | half a tank        | half a tank               | all of it   |             | 2    |

- Where a stack's copies do more than add up, its first copy applies the whole
  stack and the others do nothing, so the numbers are the table's rather than
  one copy's multiplied by the next: two Vultures are 4 coins a chip, not 9, and
  two Jerry Cans six times as fast, not sixteen. When the first copy leaves the
  hand, the next one is first.
- Payday, Odometer, Tailslide, Green Light, Hot Streak, Lucky Seven and Direct
  Debit pay the whole stack at once, so two Paydays are one pop of two coins a
  second rather than two of one.
- Hair Trigger adds to how often the cannon fires rather than cutting the
  cooldown again: each copy is the same three more shots in seven, so the third
  is worth as much as the first. Magnet Hubcaps doubles the ground the kart
  reaches with each copy past the first rather than how far it reaches, so
  three reach four times as far rather than eight.
- Curve Ball's third copy turns a bullet 300°/s, short of a full circle in a
  second. A bullet only ever bends toward an enemy in the cone ahead of it, so
  none goes round and round one, however hard it turns.
- One death takes every Spare Tire.
- A client hears its hand from the host by name, 10.3, and holds copies of its
  own, so each kart there counts its own stacks.
- High Roller, Road Rage and Glass Jackpot do not stack: a second copy of any of
  them would be all upside or all downside, the other half already at its worst.
  Nor do the jokers that are a rule rather than a number, such as Insurance
  Policy, which a second copy would do nothing for.
- Copy Cat is one more copy of the joker just before it in the hand, which is
  the order the cards were taken in, so a hand can hold a stack one past its
  most: a fourth Hair Trigger, a third Spare Tire, its life and all. When that
  card goes it copies the one before it now; after a joker that does not stack,
  or first in the hand, it does nothing. It does not stack itself. In a hand its
  words end with the card it copies, "Copying Hair Trigger.", and its card turns
  to that card's face and back every few seconds, a sheen across it as it turns
  and a cat in the copied face's corner to say it is a copy.

#### Suits

Every joker has a suit, printed before its kind in the top left corner as a playing card's index
is, the corner a fanned hand leaves showing, for what it feeds: Spades shooting, Hearts staying alive, Diamonds chips and banking, Clubs driving and mult.
Deep Pockets, Wild Card, Carbon Copy, Copy Cat, Flush Draw, Royal Court and Echo are wild, a
jester's hat in their corner, and count as any suit. Suits are how a hand is built rather than a list of
cards: the jokers that feed one thing are worth more together, and a few that feed one suit from
another, Cushion Shot turning shots into chips and Burnout drifts into pads, are how one build
reaches into the next. The suits are the four of the Royal Flush pads, 3.9, and of the teams,
3.14, drawn the same way, in cream for Spades and Clubs and red for Hearts and Diamonds as a deck
has them.

- **Suited.** A hand holding three jokers of one suit is Suited in it, and that suit pays a bonus
  of its own for as long as it is: two cards of a stack count as two. Wild cards join the suit the
  hand holds most of, the first of Spades, Hearts, Diamonds and Clubs where two are level, so they
  count once rather than in every suit. With Flush Draw two cards are enough. Five slots hold one
  suit Suited at a time, Deep Pockets' seven two of them.

  | Suit     | Suited                                                          |
  |----------|-----------------------------------------------------------------|
  | Spades   | Your bullets fly 20% faster                                     |
  | Hearts   | Come back holding a Shield, unless you already hold a power-up  |
  | Diamonds | Every chip you pick up is worth one more                        |
  | Clubs    | Every drift boost gives +0.5 mult                               |

  A hand that makes a hand, see Hands below, says so beside its cards, over its count, 8.3: a little cream playing
  card for each suit in it, fanned, over the best hand it makes, SUITED or FULL HOUSE, spaced out
  in gold above a fine rule with a diamond at its middle; a card turns over into place as its suit
  comes. And the pane
  that describes a card says which suit it counts toward and what three of it pay, short: "3×",
  the suit drawn, and the bonus, "3× ♣: every drift boost gives +0.5 mult."
- **Hands.** Besides being Suited, the suits a hand holds make hands, as a poker hand is made of
  its cards' ranks, and every hand a hand makes pays at once, a Flush the Four of a Kind and the
  Suited inside it too. Wild cards join the suit held most of, as for Suited; a Rainbow takes a
  card of each suit of its own. Flush Draw makes two cards of a suit Suited and changes nothing
  else, so its pairs are Suited outright.

  | Hand           | What it is                          | What it pays                                         |
  |----------------|-------------------------------------|------------------------------------------------------|
  | Flush          | Five cards of one suit              | Its suit's bonus twice over                          |
  | Four of a Kind | Four cards of one suit              | A chip every 3 s                                     |
  | Full House     | Three of one suit, two of another   | The pair's suit's bonus too: Suited in both          |
  | Rainbow        | One card of every suit              | Cash-outs bank 10% more                              |
  | Suited         | Three cards of one suit             | Its suit's bonus                                     |
  | Two Pair       | Two cards each of two suits         | Cash-outs bank 5% more                               |

  A suit's bonus twice over is bullets 44% faster for Spades, a Shield held and a Boost running
  on coming back for Hearts, two more for every chip for Diamonds and +1 mult for every drift boost
  for Clubs. A Flush takes a whole hand of five; Deep Pockets' seven make room for more.

  A hand made is not made in silence. On its player's screen its name is stamped into the sign,
  growing in, with a soft band of light sweeping across the sign's cards and gold, and for a Four
  of a Kind or a Flush to a soft riffle of cards and a bell, higher for the Flush, the lesser hands
  silent; it is called in gold over the hand of cards, "FULL HOUSE!", on a dark half disc that
  fades up from the screen's edge behind the hand; and the cards that make it light up one after
  another, as dealt. Nothing of it is seen on the table: a ring of the hand's suits bursting out
  round the kart, and a column of gold over it for the best hands, were too much for a hand; the
  ring is kept for a moment that earns it. A hand lost while the kart
  lives is let go of on its player's screen: struck through, dropping off as its cards turn face
  down, to a falling riffle for the best hands, and a note in gray says so, "Full House lost". A
  death's loss is said by the death. Each of these can be turned off on its own while it is
  tried.

  While the hand's key is held, Tab or a pad's Y, the pay table of the hands slides up from the
  screen's foot beside the sign, 8.3, standing on it with only its top corners rounded, and back
  down as the key is let go. Under HANDS in its middle it lists every hand with its cards and what
  it pays, the ones the hand makes lit in a gold band with a gold bar at its left, and for the next
  one up the suit the hand holds most of, Suited, Four of a Kind or Flush, how many more cards of
  it that wants, "1 more ♦". It is one picture drawn at the screen's own pixels, on whole pixels. The pane over the card under the cursor lights
  its suit's line gold while the hand is Suited in that suit, and with the details key held, Alt
  or the right stick pressed, says under it what the hand makes, "Your hand: Full House, Suited."
  Two seats at the screen share one table, a little smaller, in the middle of the room between
  their two hands, up while either holds their key, marked as the standings mark a player's row:
  the first seat's hands with a stripe of its color on the row's left edge and its color washing in
  from there, the second's the same from the right edge, a hand both make both; and the next hand
  up said for the one holding theirs; where the two hands leave it
  no room, a UI scale over 100% at 1080 lines, it stays down. Three seats and more have none. The
  catalog has a page of the hands, 8.8.
- **The offer leans toward the hand.** Half the time, one of the cards of a respawn pick is
  dealt from the suit the hand holds most of, wild cards not counted, by rarity as ever; the rest
  are dealt as they always are. An empty hand, one of wild cards alone, or a deck with nothing
  of that suit left to offer gets no lean. A map gives three or four picks, and a plan dealt at random
  rarely came together inside one.
- **Bots build too.** A bot takes the card of its leading suit when one is offered, the rarest of
  them, and otherwise one at random as before; with a full hand it destroys a card of another suit.
- **Curses and their antidotes.** On a death the cursed jokers' terms are applied first and the
  rest after them, whichever order the cards were taken in. So Insurance Policy banks all that is
  left under High Roller's 0%, Tight Grip keeps the chips Glass Jackpot would drop, the two jokers
  still going, and with Carbon Copy those two go on the floor as copies. Before, whichever card was
  taken last had the say.

## 8. Presentation

### 8.1 Art direction

A model of a place, on a table, lit like a model: the table is the subject and the
room around it is scenery. Casino accents, a few road elements, and shapes simple
enough to read at speed from above. What has changed from the flat-shaded start is
the lighting and the surfaces, not the shapes: the game is still a toy diorama,
built well enough that it looks like one on purpose.

**The rooms.** A map is a place rather than a floor plan. Each one names a
`RoomLook`, and the room decides the light, the color of every surface, how the
crowd is dressed and how much of the room behind the table is in focus. Four of
them:

| Room | Map | What it is |
|------|-----|------------|
| The Workbench | Lucky Crossing | Warm and close. A tungsten key across the table, a cool fill from the far side and a soft lamp over the felt, with the room falling away into the dark past the stands. The home table. |
| After Hours | The Vault | The room is dark and the table is the only lit thing in it: one lamp hung over the felt, the sun down to a hint, the crowd a band of shapes in the dark with the neon on their edges. |
| The Yard | Crossfire | Late afternoon, no lamp. A low warm sun across the concrete, soft long shadows, dust in the air over the far side and no glow at all: the same game played outdoors with the day nearly done. |
| The Garage | The practice rooms of 9.4 | Cool strip light on a concrete bay, no sun and no weather. The place the karts are fixed in: tires, chests, cans, a kart up on jack stands with its wheels off, a compressor and its hose, a creeper under the bench and the House's soda machine round a bay marked out on the floor. The one room with nobody in it, so its clutter is stacked against the wall of the bay rather than standing behind stands that are not there. |

The lobby names the room under the arena it belongs to, so picking a map reads as
picking a place rather than a floor plan.

A fifth room is the story's, 8.7: the Count Room, the room the house built for itself, a table on
a raised floor of square tiles in a hall of server racks lit in a terminal's hard green, rows of them
behind the crowd with their lights winking, softly and slowly, small ones settling into a steady
glow rather than shimmering as the camera moves, cable trays over them and monitors on them
scrolling numbers nobody reads, the winking and the scrolling each a shader rather than a light or a
node. Its walls are racks capped in green, its boxes stacks of drives, its Junction a processor seen
from above, its pits floor tiles lifted out with cable at the bottom, its Jackpots banks of memory
and its turbo pads cooling vents; looks only, every one of them plays as it does anywhere. Nothing
anybody put down: no litter, nothing a degree off. Its crowd stands in exact rows, every figure the
same and undressed, facing the table, with no tribune and nobody at the console, and its disco rig
is green. It is House Rules' room, 6.3, and seen first at the story's Final Hand, STORY.md 3.9 and
8.2.

Rooms are data, not code: nothing in a room decides anything about play, which is
exactly why the same match can be played in any of them. Adding another is a
resource file and a map that names it.

**The light.** Every room is lit the same way and differs only in the numbers: a
key, an optional lamp hung over the middle of the table, and an ambient that says
how much the room itself glows and carries the room's fill, the cool light from
the other side that keeps a shadow a dark side rather than a hole. The fill has a
color and a strength and no direction: it was a light of its own once, and a
second directional light is a second pass over every pixel for a difference
nobody could see, 10.7. A lamp is what separates a room
from a field: a sun lights everything it can see, and a lamp lights what is under
it and lets the rest go. Whichever of the two is doing the work casts the shadows
and the other casts none, so a room never pays for two shadow maps. How dark those
shadows go and how soft their edges are is the room's to say, and every room says
soft: a toy on a table is lit by the room it is in as much as by the lamp over it,
so a shadow is a dark side rather than a hole cut in the floor. Past the table the air thickens, so the far side of the
room is dimmer than the near side even before anything is in the way.

**Surfaces.** Nothing in a room is a flat color. Everything is built from six
materials -- felt, wood, paint, marking, metal and neon -- and a room says what
color each of them is. The detail maps are grayscale and are multiplied by that
color, so one felt serves a green card table and a slate yard, and a room is a
palette rather than a set of pictures. They are mapped in world space rather than
by UV: the meshes are built in code, a slab the size of a table has no unwrap
worth the name, and two crates side by side should not show the same knot in the
same place.

The scale that matters is the one the camera actually sees, see 8.2. From forty
meters up a two-centimeter weave is nothing, so every map carries something coarse
enough to survive the distance -- the boards in the table, the worn patches in the
felt, the joints between slabs in the yard -- with the fine grain riding on top of
it for the times something is looked at closely. `make textures` generates the lot:
they are noise filtered in the frequency domain, which wraps by construction, so a
table can be tiled out of one without a seam.

**What is inside the arena.** The walls and the boxes are the room's too. A wall
keeps the block it always was -- it is the thing a kart bounces off -- and gains a
capping strip round the top of it, which is what stops thirty meters of wall
reading as one flat slab; every third long one carries something small up there,
out of the way of the driving: a stack of chips in the card room, a cone in the
yard, bolts on the bench. A breakable box is built out of what its room has by the
crate: sealed packs of cards two by two and three high, offcuts of board stacked
crossways, or cement sacks on a pallet. All of it stays inside the cube the
collider is, so cover is the shape it looks like, and a test says so.

A room is built in three parts: what it is put together from, the room itself --
the floor under the table, the walls round it, the board at the back and what hangs
on that board -- and the clutter lying about in it. The first is shared, the second
is the shell and the third is the props, and each of the last two is baked into as
few meshes as it will go.

**The room round the table.** A table standing in the dark is a table standing in
the dark: the eye finds the edge of it as soon as the camera moves. So each room is
built as a room. The table has a skirt and legs, it stands on a floor, and three
walls go up round it -- the far one and the two sides, never the near one, because
the camera sits there and a wall behind the camera is a wall in front of it the
moment the view pulls out over the winner. The walls stand a couple of meters past
the edge of the table, which is a couple of meters past the furthest clutter: a
wall sixty meters behind the crowd is a wall nobody ever knew was there, and the
whole point of a room having one is that the table is in a room. The air of 8.1
does the rest: past the stands everything thins into the room's own color.

Then what is in it. The workbench has a backboard with a pegboard on it and the
tools of whoever built the thing lying where they were put down; the card room has
a line of brass stanchions with a velvet rope slung between them behind the crowd,
and what the house plays with left out on the baize, in all four suits;
the yard has a low fence behind the crowd, one painted hazard area where the plant
is kept and tape strung across whatever else is cordoned off, hoarding along the
back with a hard hat hung on it, floodlights over the lot, a truck, a forklift and
the rest of what a yard has standing about. Two of the rooms are models on a real table, so
everything round them is the size it would be next to a model -- a hammer left on
the bench is a third as long as the arena is wide -- and the yard is a place rather
than a model, so a scaffold tower there is the size of a scaffold tower. All of it
is boxes and cylinders in the room's own materials, which is what keeps a hammer
and a stack of chips looking like they came out of the same game.

Three rules keep the clutter out of the game. It starts right behind the crowd and
goes back nine meters from there, because a room reads as somewhere from what is
close enough to make out and the camera sees very little past the stands; nothing
big is allowed nearer than twelve meters to the wall, which puts the big things down
the flanks, and the flanks keep off the near corners; and the near apron carries only
things that lie flat, since that is the side the camera looks across. Which band a
prop belongs to is settled before the prop is, so that a room deals its big things as
well as its small ones rather than only reaching for them where they will not fit. None of it collides with anything,
and a test holds the line: no prop's box may touch the arena's own, and nothing in
front of the table may stand more than three meters tall.

The wall behind the arena is nearer than the rest of it, and lower. The camera
looks down at the table, so anything far behind the crowd is high up on the screen
rather than far off, and anything tall and near is above the top of it: a wall the
player can see has to stand about ten meters past the crowd, be painted a color
the table is not, and carry its pegboard and its notices at head height rather than
where a wall would really have them. The clutter behind the arena stops short of it
so that it is the backdrop rather than something behind the backdrop.

Each room also has a handful of things that are placed rather than scattered,
because they are the ones a player will see every match: the lamp on its arm over
the bench, with the vice on the bench edge and the calendar nobody turned over on
the board behind it; the two shades hung over the far side of the card room and the
pictures on its wall; the lit sign over the warehouse doors in the yard, the paint
on the apron under them, and a stack of barrels in against the fence on either
flank of it, turned along the fence rather than across it so that it fits in the
three meters there are between the back of the stands and where the clutter is
allowed to start. Dealt, barrels are too wide to go anywhere but out past the
crowd, which is a yard whose barrels nobody ever sees. A room reads as somewhere
because of these rather than because of the clutter, which is what fills the space
between them. Three of them move with the story of 8.7: the yard's sign is lettered, the
calendar is ringed and in the end turned over, and the card room's pictures are Employee of the
Month frames, STORY.md 6.8. The hard hat on the yard's hoarding never moves, which is its part.

What a room puts where is dealt rather than rolled: the kinds of thing it has are
shuffled into a deck and dealt one to a place, so it gets one of everything before
it gets two of anything. Rolling for each place separately is what left a yard with
five stacks of barrels in one corner and no bricks in it at all.

The floor the karts drive on is kept for them, and the clutter is told so rather
than kept away by the width of the band: the arena's own footprint is the first
patch spoken for in every room. A prop is placed by its middle and the longest of
them are six meters end to end, so in a room whose clutter starts at the wall one
turned the wrong way would otherwise lie across it.

Nothing is put down on top of anything else, either. Every kind of prop carries the
patch of table it covers, measured off the parts it is built from and turned with it:
a hammer asks for fifteen meters of bench and a glass asks for three. Before anything
is built the patch is checked against the crowd's own -- the booth, the hoardings, the
tanks -- against the runs the room itself has put down, and against every prop placed
so far; a prop that finds nowhere of its own after forty tries is left out rather than
put down in something else. One thing fewer in a full room beats two of them in one
place. A single patch the same size for every prop is what used to leave rod stock
lying through a stack of chips and barrels standing in each other however many places
were tried, and a round patch big enough to hold a prop whichever way it was turned
costs nine times the table a hammer lying on it does. Two tests hold the line: no two
patches may touch, and no prop may reach outside its own.

A fourth rule is about how it looks rather than where it is: it was put there by
somebody. Everything sits on a five-meter grid a hand's width off and square with
the table a degree or two off, and anything that comes in more than one is stacked
rather than strewn -- rod stock three down and two on top, barrels in a row with
one over them, cones in a line, chips in stacks squared off next to each other, a
pair of dice set down either side of their place rather than dropped near it. The
difference between a room that has been dressed and a room that has been sprinkled
is entirely in this, and none of it costs a frame.

**Focus.** A room can put everything a set distance past whatever the camera is
looking at out of focus, rather than at a fixed distance from the camera: the rig
comes in on the karts and pulls out to the room, see 8.2, and the table has to
stay sharp at both ends of that. It reads as a model -- and it costs about half a
millisecond a frame, which is why no room ships with it turned on. It is a number
in the room file for anybody who wants to spend that.

**What a room may spend.** A room is data, and every line of it has a price in
frames. The rule is that a match runs at the frame rate it ran at before any of
this existed, and anything that cannot hold that is not in a room by default:

| | Cost | Where it is used |
|---|---|---|
| Lamp over the table | ~0.3 ms | Every room that has one: it is what makes a room a room |
| Bloom on the neon | ~0.5 ms | After Hours only, where the signs and the felt are the light |
| Shadows from the sun | shared with the lamp | Only one of the two ever casts: a sun that is a hint casts nothing |
| Screen-space occlusion | ~0.5 ms | Nowhere. It was half the cost of the room system and most of why the corners looked sooty |
| Depth of field | ~0.4 ms | Nowhere by default |
| The room and its clutter | under the noise | Every room: a few hundred boxes and cylinders, merged at load into a dozen, and the shell casts no shadows |
| Anti-aliasing | ~0.3 ms | Everywhere, at 2×. It is what keeps a room of straight edges from crawling |
| Textures | ~0.1 ms | Everywhere. The two big slabs carry their own world-space UVs rather than being mapped triplanar, which is three texture reads saved on the meshes that cover most of the screen |

**What is baked, and what cannot be.** A room is built out of boxes and cylinders,
one node each, and one node is one thing for the card to draw: The Vault was asking
for fourteen hundred draw calls a frame, most of them a poker chip or a pack of
cards the size of a hand. None of it moves, none of it is ever hidden by itself,
and all of it wears a material out of the room's own small set, so as the map loads
it is merged -- one mesh per material and shadow setting, built in the room's own
space, with the nodes it came from freed behind it. That is about sixty
milliseconds of the map's load and it halves the draw calls: 1435 to 673 in The
Vault, 958 to 720 on the Workbench, 1185 to 722 in The Yard. Breakable boxes are
merged one box at a time, since each of them still has to go off the floor when it
is shot, and the walls keep their colliders, since that is the part a kart drives
into.

The light is not baked and cannot be. Godot's lightmapper is an editor tool:
`LightmapGI.bake` is not in the scripting API at all -- `ClassDB.class_has_method`
says so on this build -- and the module behind it is compiled only into the editor,
so an exported game has nothing to bake with even if the call existed. It would
also not be the win here. What the frame rate is spent on in a room is the passes
over the screen and the shadow map, both of which serve the karts, and the karts
move.

`make bench` prints the frame rate for a match on each map, measured over 600
frames after a warm-up, so a change that costs frames is caught while it is being
made. The warm-up matters: the first run of a scene compiles shaders, and a cold
measurement reads three times slower than the same build warm. `make profile` says
where a frame goes: it runs the same match under Godot's own profilers, with
`tools/profile_server.gd` standing in for the editor's debugger over the remote
debug protocol, and prints the script functions by their own time, the server
passes and the GPU passes. A frame rate says that something costs; the profile
says what, which is the half of the question a bench cannot answer.

- **Floor**: dark green felt with asphalt lanes and painted road markings.
- **Walls and crates**: sand-colored wooden toy blocks.
- **Beyond the walls**: the table the arena stands on, and past that the room it
  stands in -- the table's edge and legs, a floor under it, walls round it and the
  room's own clutter in between.
- **Junction pad**: the same disc of the same size in the same place in every room,
  with the room's own thing painted on it. After Hours it is a roulette wheel let
  into the baize: red and black pockets round a brass spindle with the green zero
  among them. In the Yard it is a bay marked out the way a yard marks the one
  square of floor everybody is meant to drive into -- black and yellow round the
  edge and two painted lines pointing in. On the bench it is a steel inspection
  plate, bolted down round the rim and turned bright in the middle. The rim that
  blinks is not the room's: the hint of 3.4 says the same thing wherever it is
  said, so it is the same neon ring on every one of them, and whatever a room
  paints stops short of it. A traffic light over the pad turns green during a
  cash-out. Everything else on the floor is set in the same way: a coin pad and a
  power-up pad wear a rim, and a turbo pad is a lit face in a dark frame. A disc of
  color lying on felt reads as a sticker; the same disc with a rim round it reads
  as a fitting.
- **Pits**: a hole in the floor with something waiting at the bottom of it, because
  a hole with nothing in it is a hole. What is down there is the room's: rusted
  rebar in the yard, bright nails on the bench, something dark under the card table.
  The yard paints black and yellow round the rim of its own, which is the one
  marking on a floor that is a warning rather than a decoration, and the card room
  edges its own in a thin dark red neon, only just lit, an edge to find rather than
  a sign that shouts: lit by one lamp over a dark table, it had dark
  holes in dark felt out past the brightest of the lamp that nobody saw until they
  were in one, The Vault XL's out in its far corners worst of all. None of it is in
  the way -- a pit kills whatever falls in long before any of it is touched.
- **Jackpot zone**: a vault floor tile with a chip pile that grows, a traffic light
  for its state, and its chip count painted on the floor of the zone, the way
  a Royal Flush pad wears its suit. The number belongs to the square a kart has to
  stand in, so it is on the square rather than floating over it, and like the pad
  suits it goes behind whatever is parked on top of it rather than being drawn
  through it. It does sit clear of the tile's own gold trim, since a marking buried
  in the floor is a marking nobody sees. See 3.5.
- **On the floor itself**: a dozen small things dropped and left there, flat enough
  to drive over without noticing -- a card face up on the baize, a chip, a washer on
  the bench, a scrap of paper in the yard. Only empty floor takes any, so nothing
  lands on a pad or in a pit, and nothing stands more than a hand's width tall. A
  floor with nothing at all on it reads as a floor rather than as a place somebody
  has been.
- **Chips**: poker chips, standing on their edge, with pale notches cut round the
  rim. The edge is what the camera looks at, and a notched edge is the one thing
  that says poker chip at twenty pixels across. Gold for the gold chip, which is
  metal rather than plastic, and a die for the mult die: a real one, white with
  black pips, which read more clearly than the mult's red did, one to six with
  each two opposite faces adding up to seven. Its faces are one small picture drawn once and shared by every die,
  laid over the cube the way a box mesh lays its faces out, so a die is still
  one thing to draw rather than one more for every pip.
- **Item boxes**: gold crates with black bands and a beam of light, glowing and
  pulsing so they read at a glance, branded on the top and the sides with a white
  question mark on a dark chip. One a wreck drops holds a known item and says so:
  a crate in the item's color, branded with its picture of 8.3a instead. Nothing
  hangs over a box: the brand is on it, where the eye already is.
- **Jokers on the floor**: a white playing card leaning well back as it spins, so
  the camera over the table always sees a face, printed on both sides like a card
  in the hand: the joker's picture of 8.3a in its kind's color on a dark face edged
  in the same color. The card is known on the floor by the shape it is known by in
  the hand, rather than by initials over it.
- **Karts**: toy go-karts with a simple driver figure, body tinted in the
  player color, a roof marker shape per color. Painted and lacquered: the body
  takes a coat of clear over the color, so the lamp over the table runs along it
  as the kart turns, and a little of the light wraps round the edge so a kart still
  reads against a dark felt. Its wheels stand on the felt: the model was lifted a
  quarter of a meter over it for the heights the first karts were built to, which
  the camera overhead hid and the Showroom's low camera did not. The bullets, the
  aim guide and what a kart is hit by kept their heights.
- **Bullets**: glowing spheres in the owner's color with a short trail. A shot
  that lands on a wall leaves a small round dark mark of the shooter's color lying
  flat against it, soft at the edge rather than cut out, which fades out over about
  seven seconds. A room wears 60 of them at
  once and the oldest goes to make room, so a long firefight against one wall does
  not end with the wall made of scorch marks.
- **Hoardings**: two boards of the house's own advertising, plus the clock of 8.3.
  Where they stand and what holds them up is the room's, GAME.md 8.1: the workshop
  bolts one to a scaffold tower behind the far wall and stands another out on a
  flank, the card room hangs both from rods over the far rail, and the yard braces
  a pair against the wind out by the corners. The clock stays near the middle of
  the far edge whatever the room does, since that is the one board a player looks
  for rather than reads by accident.
- **Traffic lights and road signs** as props at lane ends and near spawns.
- **The mark**: a seal, engraved the way a banknote's is, in the house print of
  8.1a. A scalloped medallion of foil engraved with guilloché bands, a ring of ink
  with the house's fine print running round it, JACKPOT JUNCTION · DEPT. OF KARTS ·
  LICENSED ON EVERY TABLE, the game's name over the top, and filling the middle the
  foil chip: the Junction seen from above, a poker chip of foil with cream notches
  round its rim and fine rings engraved in it, a crossroads cut through it in ink
  with foil curbs and cream lane lines down each arm, and the pot a red chip on the
  crossing, rimmed in ink. No neon: foil, ink and the red chip. Drawn small, the
  mark itself under 96 pixels across, it is the foil chip alone, since a seal's fine
  lines and fine print are only mush at that size: the license's band wears the
  chip, the title, the school and About the seal. The name is a casino and a road,
  and so is the mark. It is drawn in code like every other picture here, see 8.3a,
  and `make logo` writes it out. After the ending of the story of 8.7 the title's seal
  alone reads JACKPOT JUNCTION · THE HOUSE · UNDER HUMAN OVERSIGHT round its ring,
  STORY.md 8.6; the icon and everything exported keep the mark as it is. The icon and
  the splash are in `assets/app/`, out of the project's root. The icon is
  the mark on nothing: `icon.png`, 512 pixels, for every platform, and for Windows,
  which picks a window's icon from a set by the size it shows it at, `icon.ico` with every
  size from 16 to 256 pixels each drawn at its size, so its small ones are the chip. The
  splash is the mark on a plate, a ticket of the house's stock with notched corners,
  engraved waves and a foil hairline: `splash.png`, which the boot splash shows on the
  stock the title stands on, and `splash.ico`. `assets/logo/` keeps the icon, the foil
  chip alone and the splash at 128, 512 and 2048 pixels for use anywhere else, and the
  banner the README opens with, the mark with the name beside it as About sets them. It
  also keeps Android's launcher icon, which the export names: a launcher since Android 8
  cuts its own shape out of layers, so the stock and its waves fill one to the edges, the
  seal sits on another inside the circle no shape cuts into, and a third is the foil chip
  in one ink, cut rather than shaded, for a launcher that tints its icons; before Android
  8, the splash. The Mac has `icon.icns`, which the project names for it as it names
  `icon.ico` for Windows: drawn the way macOS draws its own icons since Big Sur, a plate
  with rounded corners 824 of 1024 pixels across on nothing with a soft shadow under it,
  the stock engraved with its waves, a foil hairline inside its edge and the mark on it, at
  every size from 32 to 1024 pixels, the small ones the chip. Changing the drawing and
  running that is the whole of changing the logo.
- **Buttons** are the pane in miniature, tickets of 8.1a: dark stock with notched
  corners, a foil hairline faint enough to say it is a button, and the house's gold
  round whichever one has the cursor, with a lane chevron at its left end. A menu
  driven with a stick has to say where the cursor is without being pointed at, so
  the focused state and the hovered state are the same state. On paper, the payout
  slip's stub, a button is printed instead (`HouseTheme.PAPER_BUTTON`): words in
  ink inside an ink hairline, a wash of ink and the chevron in ink under the cursor,
  and the way on a ticket of ink with foil words (`PAPER_PRIMARY`), since foil laid
  on cream is gold nobody can read.
- **The title screen** wears the mark of 8.1 over the name, the name set in the
  condensed capitals of 8.1a in foil, and has a carnival
  sunburst turning slowly behind it, narrow beams of faint foil light over the
  engraved stock so the lines show through, fading out round the mark well before
  the screen's sides and foot, with poker chips and a few cards face down, in the
  card back the player wears, 8.9, drifting up past it out at the edges, fading
  away toward the mark. Drawn rather than modeled: the menu is a
  flat screen with no match running behind it, so a scene would be a scene loaded
  to be looked at once. Dark on purpose; the point of the screen is the words on
  it. The first time it comes up in a run it opens, see 8.1a.
- **The score tanks**: a glass tank per player standing on the table just outside
  the arena wall, off to one side of the far edge, filling with that player's own
  color as they bank and brim-full at the target score of 3.8. The standings say
  who is ahead in numbers; this says how close anybody is to being done, which is
  the question that decides whether a pot is worth carrying another lap. Four a
  third full is a match with a way to go; one brimming is somebody about to take
  it. The crowd leaves them a bay rather than standing in front of them, and a
  room with no clock and nothing to reach has no tanks, since one that can never
  fill is furniture. The row is drawn for four, off to one side of the DJ booth in
  the middle of the edge; a room of more, 9.3, keeps the end of it a row of four
  has by the booth and grows away from it, closing up only where it would
  otherwise run past the corner of the table.
- **The hoardings**: two advertising boards on posts standing out past the far
  corners of the table, angled in toward it, and a third between them carrying the
  match clock as four seven-segment digits, amber and red for Last Call. The HUD
  keeps the same clock in its corner, but a hall has a clock on the wall, and a
  player watching the table rather than the corner still knows how long is left.
  How hard a sign is lit comes from the room: a hall that turns its lights down
  does not turn its signs off, so After Hours the words and the color bars carry
  their own light and the clock is the brightest thing off the table, while in
  daylight a sign is paint on a board.
  They stand on the far edge rather than out at the sides because that is the edge
  the camera of 8.2 has behind the table; the crowd leaves each one a bay; and the
  Garage takes them down with the rest of the dressing. The two ads are drawn from
  a set of house advertising as the room goes up, so a run of matches is not the
  same two posters over and over, and a line too long for its board is drawn
  smaller rather than run off the edge of it. The set grows with the story of 8.7:
  each stage adds lines, some with the player's name, and of the two a room draws one
  comes from the newest stage reached. The story speaks in two more places big enough
  for the camera: a poster of the house's on each room's back wall, pinned to the
  board behind the bench, framed and lit high on the card room's far wall or pasted on
  the yard's hoarding by the hard hat, changed once a stage; and a word painted on the road in a box across
  one open lane of each map, as a road paints KEEP CLEAR, which is the first thing it
  says, flush with the floor and worn thin where the karts run, as old road paint is.
  STORY.md 6.1. The clock board has something better than a number to say at the two
  moments it has one: READY and SET with the gantry lamps of 8.3, GO! in green as the
  flag drops, OVERTIME flashing red through sudden death, and the winner's name in
  their own color at the whistle. The flash holds still for anybody who has asked for
  fewer of them in 8.5.
- **The fireworks**: a match that has been won is seen off with a display over the
  table. Shells go up off the felt and break overhead in the winner's color, with
  the odd gold one among them, each lighting the room and banging over the fanfare
  as it goes, through the pause the podium waits out in 3.8 and on under the
  standings. The room decides nothing
  by it: it is the last thing the match does, and it is for whoever won rather than
  for their kart, which may well be lying in a pit at the whistle.
- **The crowd wears the room.** Where everybody stands, how tall they are, which
  way they face and where in the beat they are is rolled per person, but what they
  are wearing comes from the room's own wardrobe: a carnival of deepened colors
  at the Workbench, a band of near-black shapes with the room's neon along their
  edges After Hours, muted workwear in the Yard. Random bright hues over a
  thousand people read as confetti, and confetti next to the table is the loudest
  thing on the screen while the karts are the smallest.
- **The crowd**: a band of small figures eight rows deep standing on the table all
  the way round the arena, and a DJ booth a few meters into it along the top edge,
  with a pair of speakers that pulse on the beat. The band fades outward: the rows
  at the rail are shoulder to shoulder and each one behind is a little further back,
  a little further apart along its length and a little emptier, so the house ends in
  knots of people with space around them rather than in a line. The tribunes are
  stepped over the front four rows only; the rest stand on the flat behind them. The booth stands in the
  crowd rather than behind it, with people in front of it and people behind it,
  because a booth out on its own past the back row reads as a thing parked next
  to the party rather than as the middle of one. The people who would be standing
  where it is stand somewhere else, and no tribune is built over it. Getting on for a thousand of them, and no two
  the same: where somebody stands, how tall they are, which way they are facing,
  what they are wearing, how dark their face is and where in the beat they are is
  all rolled per person, and a sixth of the places are left empty, because a row
  of identical people evenly spaced reads as a fence. One stretch of each side is
  built up into a tribune: steps rising away from the arena with a wall across the
  back, and everybody standing on that stretch goes up a step per row with it.
  Somewhere along a side rather than the whole of it, since a stand that goes all
  the way round is a bowl and this is a table with people standing at it. They bob
  while the room is
  quiet, they are on their feet at excitement levels 5 and 6, see 8.4, and a kill
  gets them jumping for a couple of seconds whatever the meter says: the loudest
  thing that happens in a match is answered by the room and not only by the HUD.
  The whole house is one instanced mesh drawn in two calls and animated in a
  vertex shader off a single beat the room shares, so nothing is touched per
  person per frame and a fuller house costs a longer buffer rather than more work.
  Scenery throughout, with no collision and nothing that decides anything, and
  every machine runs its own off the same events. An accessibility setting in 8.5
  empties the stands for anybody who would rather have the table to themselves.
  The Garage has none of it, the same as it has no disco lights. From the story's
  fourth stage, 8.7, the rolled place in the beat narrows map by map until the house
  moves as one, and at its Final Hand every figure stops and leans in toward the
  player's kart wherever it goes, the figures being round, STORY.md 6.9.

Starting palette:

| Use                  | Color                                        |
|----------------------|-----------------------------------------------|
| Felt floor           | `#2F5D45`                                     |
| Asphalt lanes        | `#3A3A40`                                     |
| Road markings        | `#E8D8A0` cream, `#E3B341` yellow             |
| Blocks               | `#E6D2B5` with `#C9AE86` edges                |
| Table                | `#8A5A3C`                                     |
| Chips                | `#F2C14E` gold, `#F7F3EA` and `#C4453C` stripes |
| Junction neon        | `#FF4FA3` magenta, `#35D0FF` cyan             |
| Disco heads          | magenta, cyan, white, gold, violet, green     |
| Player colors       | red `#E23D3D`, blue `#3D6FE2`, yellow `#F2D23D`, green `#43C463`, purple `#9B4FE2`, orange `#F28C3D`, cyan `#3DD9E2`, pink `#F26BB8` |

- **Disco lights**: six moving-head spot lights stand on posts along the long
  edges of the table, working through magenta, cyan, white, gold, violet and
  green, and follow the excitement levels from 8.4, one head per level. They can be switched off in
  the accessibility settings in 8.5 and stay off in the Garage. At level 1 a
  single head drifts slowly, pointing up and sweeping the air above the room with
  a barely visible beam. Every level brings another head on; the heads tip down
  onto the floor over level 3 and are fully down from level 4, so the lights come
  down to the players rather than being switched on over them; and they sweep
  wider, faster and brighter the higher the room goes. Level 6 has all six at
  their widest, kept deliberately short of washing the table out: six heads
  blazing would cost more in readability than they buy in atmosphere. A head that
  is not taking its turn goes dark where it stands, beam gone and lens unlit,
  rather than vanishing: the lamps are part of the room. Only a room that wants no
  rig at all, such as the Garage, takes the posts away with it.
- The levels themselves hold for long enough, see 8.4, that the rig needs no
  guard of its own against flickering: it only eases between them, sweeping the
  beams open at 0.35 of the climb a second so a step up takes rather more than
  half a second. While any head is still dark the lit run walks around the rig by
  itself, every 7 s at rest down to every 2 s at the top, so the room keeps moving
  without getting brighter.
- At the whistle the rig is handed the winner: every head leaves its sweep, swings
  onto their kart over 1.6 s and follows it as it rolls out, drawing in to a narrow
  11° as it goes so the table around them stays readable. Whoever won gets it: a bot
  that has out-driven the room the same as a player, and a leader who went down
  before the whistle the same as one still driving.
- Each beam is cut to the distance it actually has to cross and widened to its
  own spot angle every frame, so however far across the table a head is
  pointing its cone ends in a lit pool on the floor rather than in mid-air.
- No head keeps one look. Each walks its own way through the six colors, holding
  one for 9 s at rest down to 3.5 s at the top and fading over to the next in 0.8 s,
  on its own staggered clock so the rig never changes color all at once. Dark heads
  walk on too, so a head coming back on is not still wearing the color it went out
  with. The color changes are kept well away from the beat: a head that changed
  color on the beat would read as a strobe rather than as a rig working the room.
- Each head also opens and closes its cone, 30% either side of the width its level
  asks for, each on its own clock and quicker the hotter the match is, so the beams
  keep working even while the level has been standing for a while. The winner's
  spotlight overrides both the width and the breathing.
- From level 3 every lit head flashes on the beat, harder on the first beat of
  the bar, faintly at first and hardest at level 6. The track is a steady 120 BPM
  in four, so the beat comes straight off the music's playback position. The
  lights cast no shadows and change nothing about play.

### 8.1a The house print

Everything on screen that is not the table is something the house printed: a
ticket, a chip, a card, a board, or paint on the road. The driver license of 9.4a
was the first thing made this way, with its cream paper, its fine lines and figures
behind the words and its rubber stamp, and it is the model for the rest: every
menu, HUD piece and dialog is cut from the same stock and printed the same way, so
a screenshot of any of them could only come from this game. Before this the menus
were the engine's controls in a dark color with a gold accent, and looked it. The
direction was set on 2026-10-05 from a proposal of thirty questions, every one of
them answered with its default. `docs/house-print/index.html` keeps the pictures:
the screens as built beside 0.13.1, the mark, the system and the proposal's
drawings.

Three rules hold it together:

1. **Printed, not paneled.** Every surface is house stock or paper cut to a shape.
   Nothing is a plain translucent box with round corners.
2. **Six shapes and a road line.** Ticket, chip, card, board, strip and sign, with
   lane dashes for lines and lane chevrons for focus. A new screen is built from
   these rather than growing a shape of its own.
3. **Engraving at a whisper.** Fine line patterns sit under everything at four to
   six percent of their ink, felt before they are seen.

**Materials.** Two papers and one foil, and the colors the game already has, each
keeping the job it has:

| Material | Color | What it is for |
|----------|-------|----------------|
| Stock | `#131218`, raised `#1B1A22`, lit `#27252F`, pressed `#0E0D12` | The dark card of everything driven past or clicked through: panes, buttons, boxes, HUD strips, boards |
| Paper | `#F2EAD6` with ink `#211F24` | Documents only: the license, the payout slip, the driving school, the Grand Prix final |
| Foil | `#F2C14E`, laid on as a fill from `#FFE39A` to `#C38D2B` | The house: focus, the primary button, headings, rules and frames |
| Neon | magenta `#FF4FA3`, cyan `#35D0FF` | The Junction's own, kept for cashing out: the bank ring and the pot |
| Signal | amber `#FFB23D`, red `#E5483B` | Boards and warnings: the clock, Last Call, a slow line, match point |
| Coins and mult | blue `#3FA9F5`, red `#F2564B` | The two halves of a pot, wherever either is shown, as in 8.3 |

**Engraving.** Five patterns, all in `scenes/ui/engraving.gd`: banknote waves, lines
that drift together and apart across the head of something; the seal, a rosette in
plaited rings; the license's long arcs rising off the foot; the four suits as a
watermark; and microprint, small capitals along a rule that read as a line from a
step back and as words up close. Each is a set of polylines worked out for the size
of whatever wears it, so it is sharp at any UI scale and nothing is a picture
stretched to fit. On stock they are drawn in foil at 6%, on paper in ink at 7%.
Nothing engraved moves, so nothing on a pane shimmers while it is read, except the
title's rings, which turn once every few minutes. A seal's rings have to be dense
and narrow to read as engraving: a wide band of few lines reads as rope, which is
why the menus' backdrop carries the license's arcs rather than a seal. What the microprint
along the HUD's corner blocks and under the title's name says moves with the story of 8.7,
STORY.md 6.4: it is the quietest place the story has. Along the corner blocks it is set at 9,
and at 14 on a touch screen, where a phone's few inches made the 7 it started at a line that
could not be read however close it was held: quiet, but there to be found.

**Texture.** Nothing is flat color: a fine texture is laid inside each shape, made
in code as a tile that repeats without a seam (`Surface`), each of its pixels
lightening or darkening what is under it a little so no color moves, one texel to
a screen pixel at any UI scale so it is as fine on a big screen as on a small one.
Panes, dialogs and the buttons on them are laminated card: a few fine scratches
and a soft light from the top left, a little lighter there and a little darker in
the bottom right; the HUD's strips are the same. Gold foil is brushed, faintly,
under a sheen. The payout slip is fine paper, a light tooth and short fibers
darkening toward brown. Joker cards have a playing card's linen, a fine weave of
crossing threads 8 px apart with plain card between them, each lit along one edge
and shaded along the other and a little uneven, laid one texel to a screen pixel
however small a card is drawn, so it stays crisp on their dark face rather than
smearing. The clock board is behind glass, a gloss down from its top
edge and a streak across it. The menus' backdrop is card-table felt. A chip's face
shows the flecks of the clay it is pressed from. Each control takes the tile from
a place of its own, so two buttons side by side are never one texture twice. Every
column and row of a tile is evened out to nothing on the whole, since one a shade
off is a line clean across the screen once the tile repeats down it, and the felt
and the grain are laid twice at two scales that never line up, so no clump of
them is seen repeating across a big field as a grid.

**Shapes.**

- **Ticket**: panes, buttons, boxes and questions. Its four corners are notched
  inward the way a ticket is punched, and a hairline of foil runs just inside its
  edge in the color of whatever it is about, the house's gold where it is about
  nothing in particular. A pane with a header has a perforation across it under
  the header, a dotted line with a bite out of either side, and the hairline
  frames the header and the body separately; the 6 px bar of color a pane wore
  along its top is gone into the header's frame. Banknote waves sit under a pane's
  head and fade out down it, and a soft shadow sits under the whole, faded in one
  smooth run rather than in steps, which showed as bands. Inside it there is one
  gap, 20 px between the hairline and whatever it holds, on every side, above and
  below a perforation as much as beside the words: a box with more room either side
  of it than over it looks dropped in rather than set. A perforation is as tall as
  that gap needs whatever its column puts between its children, and a title's
  capitals stand in the middle of its header, since Barlow keeps more of a line over
  its capitals than under them. A list's well is a ticket sunk into the screen
  rather than laid on it, and so is a socket, the cell a binding's key caps and pad
  buttons sit in on the Controls page of 8.5: the keys are the thing and the cell is
  where they go, so the keys stand at their own size in the middle of it with the
  socket's room round them rather than stretched to fill it, and a socket listening
  for a new key says so in gold.
- **Chip**: anything round, from a place in the standings to the mark beside an
  entry of a list, the knob of a switch or a slider and the item slot. A disc with
  notches round its rim, which say poker chip at any size, as the chips on the
  table do.
- **Card**: the jokers, and only the jokers. Rounded as a card is, framed in the
  color of its kind, and engraved in that color too.
- **Board**: hung from the top edge on two bolts, with lit seven-segment digits,
  the same as the clock on the hoarding of 8.1: the match clock, the ready count in
  the lobby, Last Call.
- **Strip**: what is glanced at while driving. A strip of stock bled off an edge of
  the screen with one slanted end: the corner block of the HUD, the rows of the
  standings, the lines of the kill feed.
- **Sign**: what the game warns about. A yellow warning diamond for a question
  that loses something, a round blue sign for a plain question, an amber diamond
  for a slow line, and hazard tape for the moments that matter, match point first.
- **Lane**: not a shape but the road's own line. Lines between rows are dashed like
  a lane line; a slider runs in a lane painted gold as far as its knob, and a switch
  is a short lane with a chip for its knob; loading paints the center line of a lane.

**Looked at closer.** The license, Kit's folder and a note held up to the eye are shown over a
shade drawn as a vignette rather than one flat dark: the dark it is given eased from a little
clearer round the middle, where the thing looked at stands, to nearly black at the corners of the
screen, as a lamp over a table leaves them (`MenuTheme.closer_shade`, vignette.gdshader). It is
warmed up behind the title with the rest, 10.7.

**Focus.** The control with the cursor wears a gold frame and a lane chevron, two
arrowheads painted at its left end. Hovered and focused are the same look, since a
menu driven with a stick has to say where the cursor is without being pointed at.
A button too narrow for the chevron, one that is only a picture, wears the frame
alone, and a box to type into does too, since the chevron would stand on its first
letter. So does a switch, with as much room inside the gold on every side of it:
the chevron wanted room on one side only, which left the switch off center in its
own frame. A button held down goes darker and its words drop 2 px, the way a stamp goes
down. A switch that is on is not lit for it: the lit look is the cursor's alone. The
one button on a screen that moves things on, Done, Rematch, Enroll or Resume, is
gold foil all the time, its words in the dark ink foil is printed with.

**Type.** Everything is set in Barlow, a grotesk drawn after the highway signs and
license plates of California, which suits a game that is half a road: the
condensed ExtraBold for headings and for every number that is read at a glance,
with tabular figures as in 8.3; the semi-condensed SemiBold for names, buttons and
labels; the regular width at Medium for anything that is a sentence; and the
condensed Black for the wordmark on the title. Inter's Regular stays only to draw
what Barlow does not, a name in Cyrillic or Greek; Homemade Apple stays for the
license's signature. Headings, HUD labels and stamps are set in condensed capitals; buttons,
names and sentences as they are written. A heading in foil stands on a dark shadow
a few pixels down, the way foil pressed into card stands proud of it.

**Color roles.** Gold is the house and nobody else's. Magenta and cyan are the
Junction's and appear only where cashing out does, the bank ring and the pot.
Amber and red belong to the boards and the warnings.

**The screens.**

- **The HUD** of 8.3: each corner block is a strip bled off its corner, its inner
  end slanted and striped in the player's color, engraved with waves and a seal,
  with microprint along its foot. The pot is two chip-ended pills, a blue chip for
  the coins and a die for the mult, with the value after them in gold. Speed is a
  small dial with the number in it, nitro ten slanted cells in the player's color.
  The clock is amber seven-segment digits on a board hung from the top edge, and
  while one of Kit's notes lies in the map a small scrap of its paper hangs off the
  right of the board under a magnifying glass, ticked off in red pen once a player here takes it,
  STORY.md 7.1. The
  standings are strips off the right edge, each place in a chip of its player's
  color and the leader's edged in foil; the kill feed's lines are short strips with
  slanted ends, and a line about a player on this screen, killer or killed, is
  striped in their color at its slanted end, as their row in the standings is. Key caps, pad buttons and the item tag are stock with a foil rim.
- **The title**: the sunburst stays as 48 narrow beams of foil light, a third of
  their share of the turn each, laid over the engraved backdrop rather than two
  tones of their own so the lines show through the whole of it, with 192 fine rays
  engraved between them from just past the seal outward and a glow round the mark
  under it all; it turns about the mark now rather than a point under it, once in
  200 seconds, with three bands of guilloché rings round the mark, drawn once and
  turned whole, once every four minutes; the name is set in the condensed Black in
  foil over a line of microprint between two rules; the buttons are tickets. The
  beams and the rays fade from the mark out to nothing at 0.88 of the way to the
  nearest of the screen's sides and its foot, so they never touch one; running to
  every edge, they made the screen busy behind the menu. The chips drifting up are
  the house's chips, the seat cards' own with their notches and ring, slower than
  they were, one crossing the screen in 40 to 80 seconds, and fade the other way:
  gone within 0.45 of the burst's reach from the mark and all there past it, so they
  stay out at the edges and off the words. Nothing on the settled title is drawn
  again a frame, see 10.7: the burst is one array of triangles, the rays' soft edges
  laid into it rather than drawn as smoothed lines, turned whole with the seal, and
  the chips are pictures of their faces, drawn once a run with smaller copies for the
  small ones, and moved, turned and faded.
- **The title's opening**, the first time the title comes up in a run, after the invitation of
  STORY.md 6.1a where a profile has it still to accept, about two
  and a half seconds: the mark large in the middle of the plain stock, four tenths
  of the screen's shorter side, then flying up and shrinking into its place over the
  name while the backdrop and the glow come up round it; the seal's rings growing out
  of it band by band, the inner first; the sunburst sweeping out from it with the
  chips; the name, the microprint and the line under them rising one after another;
  the buttons dealt in one by one; and last whatever peeks in at the edges, the
  license in from the right, Kit's folder in from the left, the flyer and the
  version. Any key, button, click or tap goes straight to the end, and is spent on
  that rather than also pressing Play. The title come back to from a match or the
  settings is simply there, and so is it for a screenshot or a smoke run, or with
  `--intro=0`. The shaders of 10.7 compile first, their pane over the plain stock the
  opening starts on, and it plays from its start once they are done or skipped, since
  compiling under it would make it stutter.
- **Lists of people**: the profiles in the settings, the seats at this screen and
  everybody in a hosted game are one row, the seat card (`SeatCard`): a ticket of
  raised stock with a chip at its left end in the person's color, their seat's
  number or their initial on it, gray for a watcher with no kart; their name over
  a quiet line saying where they stand, Playing now, Linked to Bob, Me, Watching;
  the plate their kart wears; and at the right end what can be done with them, with
  the room for those kept on every row so the plates line up. The row that is you is
  lit a step and rimmed in foil. The settings' two lists are the same width, so the
  pages line up as the tabs are turned.
- **Over a kart**: every hint hung over a kart stands on the house's tag, a small
  ticket of its stock with a foil hairline, and so does the item beside the kart;
  the words that float up off a kart, a graze's mult or a cash-out's tally, are set
  in the condensed cut with its even figures, outlined in the house's dark.
- **The settings' tabs** are index tabs, sloped at the sides, the page showing cut
  from the stock of the pane under it with foil along its top, the others standing
  a little lower in a darker stock.
- **The podium** is a payout slip: cream paper torn off the house's printer with
  its edges serrated, the photo finish framed at the top, each player as a line of
  a receipt with dotted leaders to their score, a barcode at the foot, and the red
  rubber stamp of the driving test saying WINNER. Its pages are one long bill, one
  under another past a perforation, scrolled over, 3.8.
- **Questions** are tickets with a road sign in their header.
- **Loading** is a lane whose center line is painted gold as the room goes up.

**Motion.** A pane is dealt rather than faded: it slides up 24 px and settles in
0.18 s, the way a ticket comes out of a printer (`MenuTheme.deal`), and leaves the
same way, a little quicker, 14 px down in 0.12 s with its shade fading alongside it
(`MenuTheme.put_away`): the pause menu, a notice and the dialogs. A menu on its way
out is not open, so the room is the player's again the moment they close it, and a
pane dealt in again on its way out simply stays. Through the motion a pane asks its
container where it rests every frame, so a layout settled late, or a pane caught
mid-way and dealt again, still ends where it belongs. Focus slides from one control
to the next: a gold frame glides from the button the cursor left to the one it
reached in 0.16 s and fades as it lands (`FocusGlide`), following the button if it
is still being laid out or rising with its pane, and drawn at the very point it has
reached rather than snapped to whole pixels, while the control with the focus wears
its own frame all along. It is drawn in the ink of the frame it lands as: gold on the
house's stock, and black on a document's paper, such as the payout slip's buttons, where
gold is lost on the cream. It never glides to or from a control that cannot be pressed,
such as the match settings blacked out for the Final Hand, which the cursor only passes
over; besides the buttons it glides to whatever wears the same frame with the cursor, the
catalog's cards of 8.8. The glide can be switched off in Accessibility, 8.5. A press is a stamp. Only the title's rings turn.
None of it happens where nothing is drawn, so the tests see every pane where it
settles.

**How it is built.** One `Theme`, made in code by `HouseTheme` and laid over the
engine's default theme at start, dresses every control the engine draws: buttons,
boxes and the lists they open, switches, fields, tabs, sliders, scroll bars, bars
and tooltips. Over the default rather than on the root window, since a window's
theme stops at the first canvas layer, and the pause menu, the HUD and every pane
over a room live in one. A screen dresses nothing itself and a new control comes
out right. A theme has no cursor in it, so `PointerHand` gives every one of those
a click acts on the pointing hand as it comes into the tree, the arrow while a
button cannot be pressed and between tabs, and leaves a cursor of its own alone,
a grip's; what draws itself and hears its own clicks, the kart bay's keys, the
title's peeks, Kit's pages, the hand of jokers, shows the hand where a click acts.
The shapes are StyleBoxes drawn in code:
`TicketStyle` for the ticket, with its notches, perforations, frames, engraving,
chevron and shadow, worked out once for a size and kept; `TabStyle` for an index
tab and `LaneStyle` for a slider's lane. `HouseArt` draws the small pictures, the
switch, the list mark, the box's arrow and the slider's knob, finely and once.
`Backdrop` is the engraved stock behind every menu screen, and `MenuTheme` keeps
the helpers that make a screen, a pane, a title or a row out of them. Anything that
draws itself, the HUD and the license among them, uses `Engraving` and the shapes
directly rather than a picture of them. The work goes screen by screen in this
order: the menus, then panes and dialogs, then the HUD, then the overlays, then the
title, the driving school and the touch controls, each played before the next.

### 8.2 Camera

A single perspective camera looks down at the arena at a fixed tilt and frames the
karts rather than the room. What has to be on screen is every kart; the rest of
the arena is scenery, and the crowd, the table and an empty third of the felt can
all go off the edge. Framing the whole room made the room the subject: most of a
match happens in one part of it, and the karts were eight pixels of a picture
mostly made of floor.

So the camera comes in as close as it can while every kart it tracks, with 4 m of
floor around it, still projects inside the view, and follows the middle of the box
they are all in. It never comes closer than 24 m however tightly they are packed,
and never pulls back further than the distance that holds the whole arena, which is
also where it waits when there is nobody to follow.

It also looks a little ahead of whoever is driving on this machine. Framing every
kart puts the middle of all of them in the middle of the screen, which for the
player at the wheel is as much screen behind their kart as in front, and what a
driver needs is the road ahead. The aim slides the way they are traveling -- the
travel rather than the facing, so a kart sliding out of a corner leads the way it
is really going -- by as far as they would get in a little under half a second, up
to 6 m. Standing still it is nothing, so a kart waiting on the grid sits in the
middle.
Only the karts somebody is driving here get it: a rival's kart is something to
watch rather than somewhere to look, and leading for all four would be four leads
canceling each other out.

Sliding the aim has to be paid for, because the fit still has to hold every kart on
screen from wherever the aim ends up. Most of it is free: the margin of floor behind
the karts is floor nobody is looking at, so up to 70% of it comes off the trailing
side of what is framed rather than out of the distance, and the trailing kart ends
up exactly as far from the aim as it was before the aim moved. Past that the lead
costs distance, and it may cost at most 12% before it gives up the rest. A camera
that pulls back to look ahead has made everything smaller in order to show more of
it, which is the trade the wrong way round; left to take what it wanted, seven
meters of lead pulled the camera half again as far out in a close fight.

Nothing the HUD lays over the screen is let cover a kart. The corners of 8.3, the
hints hung off them, the standings, the clock, the hands of jokers and a respawn
pick that shares the screen are each a rectangle of it, drawn things only: a hand
is as big as its cards, a line of words as wide as its words. On a touch screen
so are the stick, the slider and each round button of 4.2 while they are up, each
only its middle, seven tenths of its size across and down: they are see-through,
and a kart partly under the edge of one is still seen, so the camera gives up
less of the screen for them than they take. Wherever a kart
being framed would come out under one of them, the camera goes further back,
which moves every kart in toward the middle of the screen, or slides its aim
across or up, a handful of ways tried, whichever costs the least distance, so the
kart comes out from under. The aim moves a step at a time between them, so it
glides rather than jumping as the karts drive about. It goes back at most 60% past
the distance that holds the whole arena; a kart under something over the middle of
the screen, which no distance clears, is left there rather than every kart shrunk
to a speck for it. It goes out quicker than it comes in, and a kart on the move
is kept further clear the faster it goes, a quarter of a second of its travel
more, so one driven at a panel finds the camera already clear of it rather than
catching up. A pick taking the middle of the screen of a player alone on it may
cover the table: the one watching it is the one picking.

The floor ahead of each kart driven on this machine is kept in view as well, so
its player always sees what they are driving toward: a point as far ahead as the
kart gets in 0.6 s of its travel, at least 3 m and at most 7 m, the way it faces
while it is nearly still, and inside the walls, past which there is nothing to
drive toward. It is held on the screen with the karts and out from under the HUD
as they are. A rival's road is not this player's, so nobody else's kart gets one.

Whatever it is asked, the camera moves smoothly. A kart that joins, or comes back
across the room after going down, used to be in the framing all at once, and the
camera jumped to take it in: from a close shot of a fight to the whole floor at
160 m/s, from standing, in a frame. Now its place in the framing glides there
over a second, easing in and out: from the nearest edge of the box the others are
in for a kart new to the shot, where it changes nothing, and from where it was
counted last for one that came back elsewhere, which is any kart that went
further in a frame than a kart drives, 6 m. The first karts of a shot are taken
where they are, as the shot opens on them, and a kart gone from the shot that
comes back glides in again. The floor ahead of a kart driven here comes with it.
The camera then eases toward the framing in two steps: an aim follows the framing
as the camera itself used to, and the camera follows the aim on a critically
damped spring of 0.2 s that carries its speed from frame to frame. Eased by the
aim alone, it set off at its fastest the very frame anything changed: the HUD's
answers, coming in ten times a second, nudged it ten times a second. With the
spring a move starts and stops gently and a new aim bends it rather than starting
another, and the two take as long together to catch up with a kart driving
steadily as the aim alone took, so it keeps up with fast driving as before. What
keeping clear of the HUD adds, back, up and across, fades over from one answer to
the next in a straight line over the tenth of a second between them, so a panel
coming up, or a kart going under one, moves the camera over in one move too. A
kart appearing in the far corner of a close shot used to take the camera to about
10,000 m/s² and 630,000 m/s³ in a frame; it now peaks at about 430 m/s² and
4,700 m/s³, and in forty seconds of bots driving and going down the frames over
500 m/s² went from 85 to none.

All of it runs on a phone too, so it is kept cheap, 10.7. The HUD says what it
covers ten times a second rather than every frame; the camera works out afresh
how to keep the karts clear ten times a second as well, keeping what it found on
top of the framing it works out every frame in between, and spreads each of those
looks over a few frames, a few slides of the aim a frame, so no one frame carries
the whole of one; each look tries the slide in use, the middle, the eight a step
off it and one of the rest in turn, and leaves out every kart and panel that could
never meet whatever it tries.

For testing, a debug build's Debug page, or `--show-clearance` on any build, draws
what the camera keeps clear over the match: every panel the HUD reports, the
middles of the touch controls among them on a touch screen, shaded red, the frame
the karts are fitted into, a ring round each kart's middle, green while it is clear
and red while it is under a panel, a bar from each kart driven here out to the
floor kept in view ahead of it, ringed the same, and a line saying how far back
the camera is and how its aim is slid. It costs next to nothing while it is up:
the panels are drawn again only as they change, and the rings and bars are drawn
once and then moved.

A match opens on the room it is played in: the moment the map is built the camera
is placed to hold the arena, the crowd round it and three meters of the floor past
that, centered. The start of a match is the one moment a player has to look at the
place they are about to drive in, and a rig already in tight on four karts parked
at their spawns shows them a map they cannot see.

Nothing is held there. From the first frame the rig is doing what it always does,
so the countdown is one long move inward that lands about as the lights go green:
the opening shot is where the move starts rather than a wait before it. A room
opens once, so a match that sits in a lobby and then counts down does not jump back
out as the countdown begins.

A player can stop it following at all. The fixed camera of 8.5 holds the whole
arena, centered, for the length of the match, so nothing on screen moves except the
karts. It sits a little closer than the framing the rig waits at when there is
nobody to follow: that shot keeps a meter of floor round the arena because it is
waiting for karts to arrive into it, and one held all match knows where they are.
It does not open out at the whistle either, since opening out is a move and this is
the camera that was asked not to make any. It costs
size: a kart is as small as it ever gets at that distance, and reading the game
from it is harder. It is offered because a camera that pans, comes in and pulls
out is the thing on screen that moves most, and for a player who cannot watch that
the trade is worth making.

The opening shot still happens and the rig still comes in from it. That move is
the map being shown rather than the karts being chased, and a fixed camera that
refused to arrive would sit every match three meters further out than it belongs.
The tutorial of 9.4a is unaffected: it has no arena to hold and is following a
kart round its lot on purpose.

At the whistle it stops following and opens back out to the whole arena over the
pause the podium waits out in 3.8, easing rather than cutting, and it holds still
for it: the tremble stops and nothing landing afterwards shakes it again. The karts have
stopped being the subject by then: the rig is swinging onto the winner and the
match is over, so the last thing it does is hand the room back.

| Parameter        | Starting value                                                    |
|------------------|-------------------------------------------------------------------|
| Projection       | Perspective, FOV 35°                                              |
| Pitch            | 55° below horizontal                                              |
| Framing          | Every tracked kart plus 4 m of floor fits the 16:9 view, between 24 m and the distance that holds the whole arena plus a 1 m margin |
| Opening shot     | The whole arena plus 3 m of the room round it, centered, placed as the map finishes building and moved in from at once |
| Pan              | Target is the middle of the box all alive karts are in, clamped to half the arena so the look-at point stays over the table |
| Fixed camera     | Off by default, in the accessibility settings of 8.5. Holds the arena exactly, without the 1 m margin the waiting framing keeps, for the whole match: no pan, no coming in, no look-ahead, and no opening out at the whistle. The opening shot and the move in from it still happen |
| Look-ahead       | The aim slides the way the karts being driven on this machine are traveling, 0.45 s of it and at most 6 m, which is about a fifth of the width of the screen at the distance the rig usually sits. Paid for out of the trailing margin first, up to 70% of it, and then out of the distance, up to 12% more. Applied before the pan clamp, so a player already driving at the wall gets none of it: there is nothing out there to look ahead at |
| Aim              | Slid along the camera's own up axis so that what is framed sits as far below the middle of the screen as it does above. The camera is tilted, so the near edge of a thing lands lower than the far edge lands high; a fit that only picks a distance puts whichever binds hard against its edge and piles all the slack on the other side |
| Zoom             | Fixed. The distance does the framing, so a kart the same size on screen is the same distance away wherever it is standing. The fit is worked out against a view 7% narrower than the real one, which is the margin that keeps a kart off the very edge |
| Clear of the HUD | No tracked kart's middle, with 1.1 m round it and 0.25 s of its travel more (at most 3 m), under anything the HUD draws over the room, nor the floor ahead of a kart driven here; on a touch screen the stick, the slider and the round buttons count too, while they are up, each the middle 70% of its size across and down; slides of the aim of up to 40% of half the screen each way, looked for every 0.1 s, four a frame, and moved toward a step of 20% at a time; each answer faded over to in a straight line over the 0.1 s to the next; at most 1.6 times the distance that holds the arena; the fixed camera keeps the floor 1.2 m in from the walls clear instead |
| Floor ahead      | For each kart driven on this machine, a point 0.6 s of its travel ahead (3 m to 7 m, its facing when nearly still), inside the walls, held on screen and clear of the HUD |
| Coming into the shot | A kart that joins, or comes back more than 6 m from where it was a frame before, glides into the framing over 1 s, smoothstep: from the nearest edge of the others' box when new, from where it was counted when it came back. The first karts of a shot are taken as they are |
| Smoothing        | In two steps: an exponential aim and a critically damped spring of 0.2 s after it, taking together 0.6 s to catch up with something moving steadily for the pan and 1.2 s for the distance, 0.3 s when the aim is going back out, applied every drawn frame. The distance is slower on purpose: a camera that pumps in and out with every bump is worse than one that is too far off. The rig opts out of the engine's physics interpolation for that reason: it follows karts that move on the physics tick, but the following is what this smoothing is, and having both would smooth an already smoothed camera |
| Shake            | Small on deaths, larger on cash-outs of 500 or more               |
| Ultrawide        | Shows more floor on the sides, never fewer karts                  |

In shared-screen play the camera is the same for everyone, and the look-ahead is
the average of whoever is driving on it: two players heading opposite ways lead it
nowhere, which is the right answer, since the shot has to hold both of them.

### 8.3 HUD and feedback

Each player has a HUD block. In shared-screen play the blocks sit in the four
corners, in single-player and online only the local block is shown. Local means
somebody at this machine: a block, a hand of cards and a joker pick are all things
a player here has to be able to answer, so a host never shows them for a player at
the other end of a wire, who has their own screen for all three.

The corners are handed out by who is sitting at this screen, not by seat number at
the table: the first player here takes the top left, the second the top right, then
the bottom two. A client online may well be player three, and alone in its room it
still gets the top left corner rather than the bottom one its seat number would
name. Somebody leaving frees their corner for the next player to sit down.

The block is a fixed width, and everything in it is clipped to that rather than
measured from its own text. A pane that grows when the speed goes from 99 to 100
and shrinks again at the next corner never stops moving, and the eye follows
movement: the one thing a corner block must not do is ask to be looked at. It is
the strip of 8.1a, bled off its corner of the screen rather than standing 16 px
off it, its inner end slanted and striped in the player's color: the name with
kills and deaths beside it along the top, the banked score and the lives over the
pot on the edge it comes off, the speed dial and the nitro cells on its inner end,
toward the middle of the screen, and the item and the hints along the foot. It is
352 px across, the room the old card and its margin took, so a cornered hand's
lane beside it is as wide as it was.

- **Banked score**, large.
- **Pot** as `chips × mult = value`, updating live, with each half in a pill of
  its own color, each pill ending in what it counts, a chip for the chips and the
  die the mult is picked up as, on a line of its own the width of the strip: chips
  in blue and mult in red, the same two colors wherever
  either half is shown. A cell grows to fit the number in it -- a mult clipped at
  24.5 loses the digit that says what the pot is worth -- and the block round them
  is wide enough that they grow into it rather than out of it, so the pane itself
  still never moves. A pot is one number made of two, and which of the two is
  moving is the whole of what a player is deciding about -- another lap for more
  chips, or the Junction for the mult before somebody takes it off them. Written
  as one line of text it read as arithmetic.
- **The item in hand**, with its own picture beside its name, and under it whatever
  that item started and has still to finish: a power-up that runs for a few seconds
  gets a line of its own, named the same and in the same color, with a bar counting
  the time down, and a cannon power-up gets one counting its shots down instead,
  since the spread and the ricochet are loaded rather than timed. One power-up is
  one line: the Swivel Cannon is free aim for a while and holds the cannon open for
  as long as that lasts, and two lines of the same name counting down together say
  nothing the first does not. A player who has just played something should be able
  to see it is still working without counting in their head.
- **Joker hand**: the held jokers as a row of overlapping cards along the bottom
  of the screen, one hand per local player, each card framed in its kind's
  color with the joker's own picture and its name, and one, two or three round
  pips under the name for how rare it is: steel for common, cyan for uncommon,
  magenta for rare. The kind's color is engraved on the card too, 8.1a: a hairline
  inside the frame, rings round the picture and waves across the foot.
  Count and color say it twice on purpose, since the card already spends its
  color on saying what kind of joker it is and color alone is not something
  every player can read. Three or more cards fan out, the
  middle riding higher and the ends tipping away, like a hand held in a fist.
  While the joker menu is open the selected card lifts straight up out of the
  fan with a bright frame, its name, description and the menu controls float
  above it, and the other cards dim. It keeps the tilt it had: the cards turn
  about their bottom corner, so a card that straightened up as it rose swung
  sideways as well, and a card being picked should only go up. The hand goes away at the whistle: it belongs
  to a match being played, and under the podium it is a row of cards lying across
  the standings of a match that is already decided. A count beside the hand reads how many of
  the slots are taken, out of however many the hand has room for, turning gold
  once the hand is full. It stands on the screen's edge the hand is held at, staying put as
  the hand opens and tucks away, and the sign of a hand made, 7.3, stands right over it. With three or four players at the screen each hand keeps
  to its owner's corner instead, beside their block on the same edge. The two top
  players' hands hang from the top edge, between their block and the clock: the
  cards stay upright to be read, but the fan bows down, the card being read drops
  out of it and its pane opens under it. Shared out along the bottom edge, a hand
  was nobody's in particular, and one pushed up off a bottom block looked like
  that block's. A cornered hand is tucked into its edge as a touch screen's is
  (4.2): smaller and half past the edge while none of its cards is being read,
  coming out to its full size as the joker menu opens or the mouse comes onto
  it. Four hands at full size are four hands over the arena.
- **Lives**: two hearts in the player color under the banked score, drawn off the
  heart curve so they have the dip and the point that tell the shape apart at
  twenty-one pixels. A square said one of something and left you to work out what.
  A lost life goes dark.
- **Held power-up**: the item's own picture beside its name, both in the item's
  color, see 8.3a. While the box is still opening the picture flicks through the
  other items, which says "not yet" in the same language as the rest of the row.
- **The type.** Everything in the game is set in Barlow, in three cuts and on one
  scale, see 8.1a for the cuts and why. Weight carries the role rather than size
  carrying the importance: anything read at a glance mid-corner -- a banked score,
  the clock, a heading -- is set in the condensed display cut, names and buttons
  in the semi-condensed middle weight, and anything that is a sentence in the text
  cut. Anything that is a number that changes --
  a banked score, the clock, a speed, a place in the standings -- is set with
  tabular figures, so every digit is the same width and the line stays where it
  is while it counts. Proportional digits move the whole line sideways on every
  tick, and a number that moves is a number read twice. The faces that are
  not Barlow, besides the Inter that draws what Barlow cannot, are the hand the
  signature on the driver license of 9.4a is written in, Homemade Apple, under
  the Apache license: a signature set in a text face is a name typed on a line;
  and, for the papers of the story, 8.7, Kit's hand in Caveat, the other hands
  among the notes in Kalam and Patrick Hand, the House's typed documents in
  Courier Prime and an old page of the Highway Code in IM FELL English, all under
  the Open Font License, and the marker on the folder in Permanent Marker, under
  the Apache license. Sizes come off a scale where each step is
  about a quarter larger than the one below it, because a screen with nine sizes
  on it reads as nine screens. Display lines are tracked out a little: a heavy
  face set tight reads as a shout.
- **The pane** is the shape every panel in the game is cut from, the ticket of
  8.1a: dark stock with room to breathe, notched corners, a foil hairline inside
  its edge in the color of what it is about, banknote waves under its head, a
  shadow under it, and a perforation under a header. It replaced a translucent
  card with rounded corners and a bar of color along its top. The joker pane below
  was the first thing built as a pane; the
  podium screen, the pause menu and the online lobby all wear it too, so a panel
  looks like this game's panel wherever it turns up.
- **The joker pane** describes whichever card is under the cursor, and is the same
  pane everywhere a player reads about a joker: above the hand for the card lifted
  out of the fan (under it, for a hand hanging from the top edge), and under the row for the respawn pick and again for the card
  being destroyed. It is built like a standings row so the two read as the same
  game: a dark translucent card with room to breathe and a bar of the joker's own
  kind color along the top of it. The name, how rare the joker is and what kind it
  is share the first line, a rule separates them from what the joker actually does,
  and the buttons for whatever can be done from there sit at the foot in gray,
  drawn as buttons. Things told apart beats one paragraph they were all run into.
  A joker that stacks, held more than once, says how many beside its name in gold,
  ×2 or ×3, since each copy is a card of its own in the hand; on offer at the
  respawn pick, one already held says what taking it makes it, "makes ×2". Its
  words say what the whole stack does, "worth 4 coins to you" for two Vultures,
  every number the stack has changed in the same gold, so a stacked figure is
  never mistaken for the card's own; one copy's words are the card's, in the
  pane's own ink. On a Rule joker that gold is all but the Rule color of the
  pane's top edge and its kind; it stays, since it is the ×2's, and the number
  still stands out of the words around it. How far it stacks, "Stacks up to
  ×3.", is left off the words: it was one more sentence on every card for a
  number the player has no way to act on while reading it. Holding Details,
  Alt or a click of the right stick, 4.2, puts it back at the end, and beside
  every gold number what one copy says, in the pane's own ink: "worth 4 coins
  (3 coins) to you". It is each player's own key, for the cards on their own
  screen share, on the hand and on the respawn pick alike. The hand's pane, open
  on its key, names it last in its row of keys, "Alt details", the right
  stick's click on a pad; the settings' Controls list it with the rest, "RS"
  for the click rather than the engine's "R/RS". A touch screen has no key for
  it and keeps its cards short. On a
  keyboard Tab goes down first, since Alt and then Tab is the desktop's own
  window switch. A
  long row of cards, two Wild Cards' seven, shrinks to fit across its share of
  the screen.
- **The respawn pick** shows the offered cards in a straight row, the one under
  the cursor risen and grown and nothing else: it grows about its own bottom
  center, so it stays where it was along the row rather than drifting sideways as
  it swells. It takes the middle of the screen when one player is on it:
  they are dead, and the one watching is the one picking; the hand under it tucks
  into the bottom edge, smaller and half under it, as a phone's always is, and the
  pick stands over it, so no card of the one is over the other. With somebody else sharing
  the screen it shrinks and goes down to the foot of its own share, where its hand
  was, which steps aside for it while it is up, with the pane beside the cards and
  its button at the end, so the whole pick is a strip along the bottom edge instead
  of a wall across the arena the others are still driving in, and the camera keeps
  their karts clear of it, 8.2. Where the strip is wider than the share, at a big
  UI scale, its cards shrink to half their size and its pane's words to 260 wide
  first, the skip chip on a line of its own; past that the pane stands over the
  cards and the title over it. With three or four players it
  keeps to its owner's corner, as the hand does: above a bottom player's hand, and
  under a top player's, stacking down from it with the pane under the cards.
- **Nitro tank** as ten slanted cells in the player's color, lit as far as the
  tank is full, like the segments of a gauge on a dashboard, and lit the nitro
  color while burning.
- **Speedometer** over it: a small dial, three quarters of a ring open at the
  foot, with the number in km/h in its middle and the unit written in the gap,
  both turning the nitro color while the bottle is lit. The dial is full at a kart flat out on
  nitro, so the needle still has somewhere to go when it lights. The number is the
  kart's real speed scaled by 20, which puts a kart at about 210 km/h flat out and
  400 on nitro: the honest meters a second is a single figure and says nothing
  about how the driving feels. In mph, chosen in the settings or by the system's
  locale, 8.5, it is the same converted, about 130 and 250, MPH in the gap. A dead
  kart reads zero. Its face is a gauge's, a
  foil rim and a tick every so far round, the ring's track dark up to the kart's
  own top speed, the foil's past it where only nitro takes it and red at the end
  of that; the fill is white over it, and a slim red pointer out on the ring,
  clear of the number, swings onto the speed on a spring, overshooting a sudden
  change a little before it settles, and trembles at the top of the nitro's
  stretch. The fill is drawn to where the pointer stands rather than to the speed
  itself, so the two always move as one. A foil bar across the track holds the highest speed of the last
  moment, a second or so, before it falls back. The face is drawn once into a
  picture, the pointer and the bar once each and only turned, so a frame of
  driving redraws the fill alone, one arc, 10.7.
- **Control hints**, on by default and switchable in 8.5: a line under each
  player's block, on a small ticket of the HUD's stock hung from its foot (or
  standing on its top for a block at the foot of the screen), a little in from
  the screen's edge, square where it meets the block and notched only at the two
  corners of its free end, part of their corner while the block itself never
  grows and shrinks as the hints come and go, showing the button that drifts, the one that burns nitro and
  the one that plays a held item. Each shows only while it is worth pressing, so
  a parked kart with a full tank sees the nitro reminder alone and an item still
  rolling in its roulette shows none. The button that opens the joker menu is
  drawn to the left of the joker hand, and shows only while cards are held.
  Driving and firing are left out: they already have the hint beside the kart at
  the start of a match, shown each seat at this machine once, in the first room it
  plays in, the lobby as a rule, and not again at every map, where it nagged; Always
  show drive hints in 8.5 brings it back at the start of every map. That hint, and every hint hung over a kart, is the same
  size on the screen wherever the camera is, as big as the HUD's own words. Sized
  in the world, it shrank to a smudge whenever the camera pulled out to frame a
  whole room, and a stall's hint drawn bigger to make up for that was twice its
  size over the same kart a moment later.
- **Joker pictures**: every joker has a flat pictogram of its own, drawn in its
  kind's color on the dark of the card. A card is recognized across the table by
  its shape; two letters at that size are a shape that has to be read first. How
  they are built, and how to add one, is 8.3a.
- **Bindings are drawn, not written.** Everywhere the game names a control -- the
  hints above, the joker hand and pick, the tutorial's line over the kart in 9.4a, the
  hint beside the kart, the join line in the lobby and the rebinding rows in 8.5
  -- the binding is a picture of the thing being pressed. A key is a key cap with
  the key on it. A gamepad face button is the round one in the color everybody's
  pad has it in: A green, B red, X blue, Y yellow, with the letter on it in the
  dark the pad prints it in. A shoulder, a trigger, Start and the stick clicks
  are pills with their name on. A stick is the gate seen from above with an L or
  an R written inside it, and a solid head each way along the axis it reads, or
  one head when only half the axis is bound. The D-pad is a cross with the
  pressed arm lit. A mouse button is a mouse seen from above, its left or right
  half filled in the ink, or its wheel for the middle button, and a double click
  is the same mouse with ×2 beside it; any other mouse button, the wheel turned
  say, is written on a key cap. A tap on a touch screen is a hand with its finger
  on the glass and the ring of the tap round the fingertip, Material Symbols'
  touch_app, filled, in the ink with a dark rim; the hand first drawn for it, put
  together from rounded boxes, read as a box with a stick on it. The shut theory
  book's corner, the rubber stamp and the license
  draw it for a phone, where a pill reading "Tap" was one more button to look
  for, and the mouse a phone makes out of every touch does not turn either back
  into a mouse. A face button, a stick, the D-pad, a mouse and a finger are
  drawn as buttons rather than on one, since each is already a shape and a box around a button is
  a box around a button; everything else is a word, and a word needs something to
  be written on.
  Everything but a face button sits on a solid chip of the house's stock with a
  soft black edge and a rim, foil on a line in a plain hint's ink and the line's own
  color on one with a color of its own, a key cap with a lip of it along its foot,
  8.1a, so it is dark against the felt,
  the crowd and a light wall and rimmed against a dark menu. A picture you have to
  pick out of the background first is a picture that has already cost the corner
  you were reading it in. "Shift drift   Ctrl nitro" is a sentence to be read; the same line with
  the keys drawn as keys is a picture to be recognized, which is what a hint
  glanced at mid-corner has to be. The shapes are drawn rather than loaded from a
  set of pictures, because the bindings belong to the player: any key on the board
  can end up in one of them.
- Every hint is drawn for the scheme that player is using: their own device when
  they are pinned to one, and otherwise whichever they last touched, which the
  game tracks from the input events themselves. The joker hand, the respawn
  picker and the start-of-match hint follow the same rule, so a player who picks
  up a pad mid-match sees gamepad buttons everywhere.
- **Match timer** at the top center, in amber seven-segment digits on a board hung
  from the top edge, the same digits as the clock on the hoarding of 8.1, every
  unlit segment still faintly there; red during Last Call and overtime, and the
  word OVERTIME set on the same board in the display cut. Last Call is said in the
  middle of the screen as it starts, for its first three seconds, on a bar's neon
  sign (`NeonSign`): the words bent in red tube inside a tube frame on a dark board,
  glowing into the room, flickering on as a tube does and then humming, steady
  from the start for anybody who turned flashes down in 8.5; and GO in the
  gantry's green as the flag drops.
- **Item beside the kart**: a player on this screen who picks an item up sees it
  beside their kart as well as in their corner, small, on the house's tag, a small
  ticket of its stock with a foil edge, 8.1a, off the
  kart's top right corner, which it keeps to however far out the camera has
  pulled: it turns through the items the way the
  roulette in the corner does while the box is opening, settles on the one they
  got, holds a moment and fades slowly, the corner going on saying what they hold.
  Once it can be used the button that uses it sits on the chip's lower corner,
  drawn for the keys or the pad that player is on, and fades with it. Used, it goes
  at once. It comes up again, fading in over the last few meters and out as they
  drive on, while a player holding an item nears another item box: a box they
  cannot take with the slot full, which they used to drive straight through
  wondering why nothing happened. One taken with another box already under the
  kart, as off a pad that puts its next one straight out, stays up for that box
  rather than fading and coming straight back, and goes as they drive away. The eyes are on the kart as it drives through the box, not
  on the corner of the screen. Nobody else's pickup puts one up.
- **Royal Flush tally** under the timer, while a player at this screen holds a
  Royal Flush pad, see 3.9: a little playing card for each pad, tucked under the
  clock's board so it sticks out of it and fanned a touch, a cream one with the
  pad's suit in its holder's color for every pad held and a dark one with the suit
  faint for every pad nobody holds, the pads being those
  of the room the first player at this screen is in, which on every map is every
  pad on the map. This screen's players
  come first, whatever their suits, then whoever holds most, and the free suits
  last, so a player's own count is the run on the left and the faint ones are the
  suits still to get. It says how close a flush is without four frames to find
  round the table, and is gone the moment nobody here holds one, since four faint
  suits on every screen most of the match say nothing. A flush a player here scored
  stays on it while it pays out: the pads have cleared and wear nobody's color, but
  they are that player's for a while yet, so all four suits are in their color,
  with a bar under them that empties as the payout runs out. The snapshot carries
  whose flush is paying and for how long, so a client's tally shows it too. And it
  goes up on every screen, whoever there holds what, while somebody else holds all
  the pads but one: a warning rather than a count, that player's suits pulsing,
  swelling and glowing in their own color, with an exclamation mark in it at the
  end of the row, since the last pad is the one to go and take off them. A
  watcher's screen, 9.3, has nobody of its own to count for and is there to
  follow the match, so it shows the tally whenever anybody holds a pad, most held
  first, and whoever's flush is still paying. The suits
  stand on their own, with no panel behind them, each with a dark outline of its
  own. They stay solid rather than dimming as a claim runs down: a client is not
  told when a holder renews one, so its dimming would be a guess.
- **Start gantry**: the countdown is a horizontal rack of three lamps hung over the
  middle of the screen, the way a racing track starts a field, rather than a number:
  a ticket of the house's stock with a foil hairline, 8.1a, its lamps chips, dark
  until they light and glowing round their rims once they do.
  They fill up red left to right and the whole row turns green on the drop, under the
  GO. A driver on the grid watches the lights, not a clock. The rack and the start
  tones are one countdown rather than two: the first lamp lights with its tone as the
  field is held, each of the rest lights with its own, and the higher tone comes with
  the green. However long the countdown is set to, there are three of each, so what a
  player sees and what they hear never disagree; over the usual three seconds that is
  a lamp a second, which is the pace anyone counting a field down counts at. The rack
  goes a moment after the drop whatever the match goes on to, a Last Call that starts
  with the flag included, on every screen.
- **Kill feed** in the top right: the last five kills, newest first, reading as
  "P1 shot P2", "P1 rammed P2", "P1 bombed P2", "P1 shoved P2 in" for a pit
  shove, "P2 fell in" for a fall nobody caused and "P2 wrecked itself" for a
  self kill. A turret's kill is its owner's and says whose turret made it, "P1's
  turret shot P2", or "P1 was shot by their own turret" with own bullets deadly:
  a player shot from across the room wants to know it was the turret that got
  them, not the kart they can see nowhere near. A decoy's is the same: its kill,
  by its bullet or its ram, is its owner's and reads "P1's decoy shot P2", and a
  decoy destroyed is news as a kart's death is, "P2 shot P1's decoy", "P1's
  decoy fell in", "P1 took out their own decoy"; one that ran out of time is
  not. The host says so, each kill that came by a decoy announced just before
  the kill itself, `Events.kill_detailed`, and each decoy destroyed with
  `Events.decoy_destroyed`, both relayed. A kill by a bullet that came off a wall
  first has the mark of a ricochet at the end of its line, in the feed's gray: a
  wall on the right and the bullet's path coming in to it and going off it, with
  ×2, ×3 beside it for more walls than one. No words for it, "off the wall"
  being one more phrase to read in a line that says enough already. The bullet
  counts the walls and the death says them with the rest, `Events.kill_detailed`.
  Names are in the players' colors. Lines hold for 6 s and fade. Each line stands
  on a short strip of its own off the right edge, 8.1a, as long as its words.
  The feed drops below a player block that owns that corner.
- **Standings**: a ranked list down the right-hand side, one row per kart with
  its banked score and, in gold beside it, whatever it is still carrying around
  unbanked. Each row is a strip off the right edge, 8.1a, its place written on a
  chip of its player's color, the leader's row edged in foil, and the row of the kart with the
  bounty, 3.6, marked at its end with a gold crown, the one its kart wears; a bot's name has a
  little robot's head after it, so a room of players and bots says which is which. Rows are ordered by what is banked alone, the same as the results
  screen in 3.8: a pot is worth nothing until it reaches the Junction, and a board
  that counted it put a player who had won nothing at the top and dropped them
  three places for being shot. The carried pot is still shown beside the score,
  so a hot lap is plain to read without being scored. The leader's
  row is the largest and last place the smallest, both kept small, 24 and 15 points,
  since every row is table a kart cannot be seen on, 8.2; and the players on this screen
  have their own color striped along their row's slanted end, and washed a short way in from both
  ends of the row, from the stripe and from the screen's edge, fading to nothing. A carried pot that would win the match blinks,
  see 3.4. A player online whose line to the host is too slow wears an amber
  warning sign beside their name, on every screen, see 10.3. It stands down in
  three- and four-player shared-screen games, where every player already has a
  corner block. A room of more than four, 9.3, has smaller rows, eight of them
  not twice as tall as four, the leader still the biggest; and on a short screen,
  a phone or a big UI scale, 8.5, it shows four rows, the top of the order with a
  player on this screen who is further down in the last of them, at their own
  place. In teams it has a row for each team, 3.14.
- **Dropping something**: a kart that bursts, or a crate that breaks, throws what
  it was carrying clear of itself rather than having it appear on the floor. It
  flies on every machine: the throw is cosmetic, since the pickup is already lying
  where it lands on both, so a snapshot carries the flight still to run and a
  client picks it up part way through rather than starting it again. Each
  piece flies out of the middle of the thing that dropped it and settles onto the
  spot it is going to lie on, growing from nothing as it goes: the same 0.3 s arc
  as taking one, run the other way. Anything simply put down, such as what a coin
  pad puts out, is just there.
- **Taking something**: a pickup never simply blinks out. Whatever it was, chip,
  gold chip, mult die, joker card or item box, leaves the floor and flows into the
  kart that took it over 0.3 s, easing away slowly and arriving fast, rising a
  little and shrinking to nothing as it goes. It is the pickup's own model that
  flies, so a chip goes in as a chip and a card as a card, and from a distance it
  is plain who got what. Online it happens on every screen: the host does not say
  who took a pickup, so the kart standing on it is credited with it.
- **Destruction**: a kart, turret or crate that is destroyed leaves a burst of
  tumbling chunks in its own color with a brief flash. A kart lost down a pit
  shrinks away instead. The Bomb keeps the one real explosion, see 7.1.
- A cash-out shows one tally that counts up to what it paid. A player parked on the
  Junction while their Royal Flush pads trickle finishes a cash-out of a single coin
  every second, so a run of them climbs that one number instead of spawning a label,
  a shower of chips and a thump apiece; the equation is dropped once it is no longer
  what made the total, and the tally goes away on its own when the coins stop. The
  chime keeps the same company: one per run rather than one per coin.
- In-world: a progress ring around the kart while banking or collecting the
  Jackpot, the chip count on the floor of the Jackpot zone, floating `+0.5` on grazes,
  and for local players an aim guide of four faint dots ahead of the cannon. A
  local player is whoever is steering the kart, which online is a kart the host
  moves: the guide is for the hand on the stick, not for the machine running the
  physics. The item tag beside a kart names the key or pad button that uses the
  item; on a touch screen it names none, since the touch controls already put a
  button with the item's picture under the thumb, 4.2. The guide and the
  free-aim arrow hang off the kart as it is drawn,
  smoothed between physics ticks, rather than where the last tick left it: a
  screen that draws faster than the physics runs, a phone's at 90 Hz, showed dots
  placed off the tick jumping back and forth against the kart every frame.
  Royal Flush pad frames glow and pulse in their holder's color, the suit on the
  plate in it too; a flush shows
  ROYAL FLUSH over the kart.
  A life going shows a heart breaking over the kart and one handed back shows a
  whole one, rather than the words that were there before: two words have to be
  read, and a player who is reading is not driving. A joker that does something
  by itself says so on its own card: in its player's hand the card pulls out of
  the fan, further than a card being read, grows by a third, lights up and glows
  round its frame in pale gold, with a word over it in the same gold, under it
  for a hand hanging from the top and leaning as the card leans in the fan,
  holds there for most of a second and goes back, the word fading with it. A tucked hand comes up meanwhile, as it does
  for a card being read. Only on the moment it made a difference, which for most
  jokers is every moment and so never: Guardian Angel spending the item on a
  hit, GUARDED; Insurance Policy banking a pot at a death, INSURED; Tight Grip
  keeping coins a death or a ram would have spilled, GRIPPED; Pickpocket taking
  coins off a kill, STOLEN; Toll Booth paid out of another kart's cash-out, TOLL;
  Road Rage making a ram land that nitro or Boost did not, WRECKED; and Carbon
  Copy dropping a copy, COPIED. A joker that goes from the hand by itself, used
  up, gets the destroying kind: the Spare Tire a death takes is framed and lit in
  red with LOST over it, shakes for a moment, then drops out of the hand and
  fades, turning over to the card back the player wears, 8.9, as it goes, and the
  cards left close up behind it. So does every joker a death drops
  on the floor, LOST the same, Glass Jackpot's two each: it went without the
  player's say, and the card on the floor is anybody's now. A card a full hand
  trades out for a new one from a pick, 3.7, goes the same way with REPLACED
  over it: the player's say, but the card is gone all the same. What the player gives
  up themselves, dropping or destroying a card or swapping one at the pick, goes
  the plain way, without the shake, the red or a word: they saw it go. It still
  drops out of the hand turning over to the back worn. The word is on the card rather
  than over the kart, where words are kept out: the card is where the player
  looks to see what a joker did. A haloed heart over the kart, tried first for
  Guardian Angel, said a life was kept without saying whose doing it was. The
  host says it to every client, and a puppet's jokers say nothing of their own.

The tally is the payoff moment and gets the polish budget. The whole time a pot
is being banked, chips go from the kart into the pad at a steady beat, more of
them at a time the faster it drains, so the bank reads as money going in for as
long as it is rather than only once it is done. On a completed cash-out a burst
of them follows while a counter above the kart counts up with rising slot-machine
ticks: `coins × mult`, then `= total`, in about 0.8 s. Cash-outs of 500 or more
add a fanfare, confetti and screen shake. A death shows where its pot went
instead, see 3.6. The in-world tally and the chips play for every kart, so
everyone sees when an opponent cashes out.

### 8.3a Icons

Two sets of flat pictograms: one per joker, in the middle of its card, and one per
power-up, beside its name in the HUD block. They are built from one shared
vocabulary, `scenes/ui/icon_shapes.gd`, which is what makes the two look like one
hand's work; the recipes themselves are `scenes/ui/joker_art.gd` and
`scenes/ui/power_up_art.gd`, one `match` arm per id.

They are drawn rather than loaded: a folder of PNGs would weigh something, would
be cut for one size, and would have to be recolored for every kind and every
item. `make jokers` puts every icon in the game on one screen, the power-ups
first and then the cards, which is the only way to judge a set that is meant to
look like a set.

**The rules that make thirty drawings one set.** Break these and the card stops
matching the others before anybody can say why.

- One subject, and at most two supporting shapes behind it. A card is read at a
  glance from a hand of five, not studied, and an item is picked up and played
  inside a couple of seconds.
- No text. The name is already beside or under the picture.
- No third color, no gradients, no outlines drawn around fills.
- Nothing outside 0.06 to 0.94 of the box, so the picture never touches the frame.
- Do not reuse a silhouette another card already owns. A round thing with a hole
  in it is Aimbot's; a five-pointed star is Wild Card's; a burst is Road Rage's.

**The box.** Every picture is handed a square box and draws in fractions of it:
`(0, 0)` is the top left corner, `(1, 1)` the bottom right, y downwards. Radii,
spans and stroke widths are fractions of the box's shorter side. Nothing is in
pixels, which is what lets the same recipe serve the card in the hand, the larger
one in the respawn pick and anything else that asks for one.

**The two colors.** A picture gets exactly two, both handed in:

- `ink` is the subject: the thing the icon is about.
- `dim` is the same color at 40% alpha, from `IconShapes.behind`, for whatever
  the subject sits on, in or behind -- the die under its pips, the pipe behind the
  flame, the road under the arrow.

The color arrives from outside, so a picture never names one itself: a joker's is
its kind's, a power-up's is the item's own. That is what keeps a Stat card steel,
a Rule card gold and a Cursed card red without forty places having to know it.

**The vocabulary.** Every picture in both sets is built from these and nothing
else. All of them are on `IconShapes` and all take the canvas and the box first,
which the examples below leave out for brevity.

| Shape | Call | What it is for |
|-------|------|----------------|
| Disc | `_disc(x, y, r, ink)` | a solid round thing: a coin, a chip, a ball, a wheel, a pip |
| Ring | `_ring(x, y, r, ink)` | the same hollow: a rim, a gate, a sight |
| Arc | `_arc(x, y, r, from, to, ink)` | part of a circle, in degrees clockwise from east with y down: a guard, a wing, a skid, a sweep |
| Line | `_line(x1, y1, x2, y2, ink)` | a stroke between two points |
| Bar | `_bar(x, y, w, h, ink)` | a rounded rectangle from its top left: a body, a panel, a block, a slab |
| Triangle | `_tri(x, y, span, facing, ink)` | a solid triangle centered on x, y, facing in degrees clockwise from up: an arrow head, a bullet tip, a beak |
| Flame | `_flame(x, y, span, turn, ink)` | a teardrop standing on x, y with its tip `span` away, blowing `turn` degrees off straight up |
| Shield | `_shield(x, y, span, ink)` | square shoulders tapering to a point |
| Bolt | `_bolt(x, y, span, ink)` | a lightning bolt, for speed rather than for a thing |
| Star | `_star(x, y, span, ink)` | five points, the house's own mark |
| Burst | `_burst(x, y, span, ink)` | ten points, for something going off |

Every line is `STROKE` thick, 5.5% of the box, so weights match across the set.
Shield, bolt, star and burst are one-off silhouettes: each belongs to one card and
is not to be borrowed. Star and burst are the same spiked ring at different point
counts, so a third silhouette of that shape would be `_spiked` with new numbers
rather than new code.

**Adding a picture for a new joker or power-up.** The two go the same way; only
the file and the list differ.

1. Decide the one thing it is about, and check nothing owns that shape already.
   Run `make jokers` and look.
2. Add a `match` arm keyed on the id -- in `JokerArt.draw_into` for a joker,
   `PowerUpArt.draw_into` for an item -- drawing the subject in `ink` and anything
   it sits on or behind in `dim`. Build it out of the vocabulary above; if it
   genuinely needs a shape that is not there, add the shape to `IconShapes` so the
   next one can use it too, rather than drawing it inline.
3. Add the id to that file's `known()`.
4. Run the tests. `test_every_joker_has_a_picture_and_every_picture_has_a_joker`
   and its power-up twin hold the two lists to each other in both directions: one
   without a picture fails, and so does a picture left behind by something that
   has gone. They are written out separately on purpose, since a list that derives
   itself from the other cannot catch either mistake.
5. Run `make jokers` again and look at it next to the rest.

Anything with no arm of its own falls through: a joker gets the star and an item
gets a plain ring, so a missing picture is a card that looks like Wild Card rather
than a card with a hole in it. The test is what stops that shipping.

**A worked example.** Nitro Habit is a bottle with a flame coming out of the
bottom of it:

```gdscript
&"nitro_habit":
    IconShapes.bar(on, box, 0.34, 0.24, 0.32, 0.6, dim)   # the bottle, behind
    IconShapes.bar(on, box, 0.42, 0.12, 0.16, 0.14, dim)  # its neck, behind
    IconShapes.flame(on, box, 0.5, 0.8, 0.3, 0.0, ink)    # the flame, the subject
```

Three shapes, two of them `dim` and one `ink`, everything between 0.12 and 0.84 of
the box, and the only thing drawn in full color is the thing the card is named
for.

### 8.4 Audio

- **Music**: three tracks by Ovani Sound -- "Deceased Rodent" at 120 BPM,
  "Ginger Bread" at 128 and "Let It Breathe" at 136 -- each in three intensities
  that all run in step and crossfade over 1 s at the same position. The fade is
  linear in amplitude so the level never dips. Each is cut to its own loop, 88 to
  94 s, an exact fifty bars with the decay tail folded under the start, so the
  music loops without a gap. Intensity 1 plays by default and in the menus, from
  the moment the game starts, but not under the invitation before the first title,
  STORY.md 6.1a, which comes in silence: the music fades out if it was playing and
  starts from the top as the title opens. It goes on through a pause, under the pause
  menu and the Garage's bay, which pause the room, and so do the sounds of what is pressed
  there; the match's own sounds stop with it.
- **Which track**: one is picked at random as a room is built, so a run of
  matches is not the same loop over and over. Two tracks are two pieces of music
  rather than two layers of one, so the change is a fresh start rather than a
  crossfade, and the roll is each machine's own: online everybody hears their own
  record. Everything that moves on the beat -- the booth's speakers, the crowd,
  the disco lights, the camera's tremble -- reads the tempo of whatever is
  playing, since the three were written at three different ones.
- **Excitement meter**: underneath everything is one meter from 0 to 1. Heat
  comes from things that just happened and fades over a few seconds: a kill
  0.30, a wound 0.14, a bomb 0.14, a cash-out 0.10, a Royal Flush 0.22, a graze
  0.06, all decaying at 0.30 a second. Pressure comes from how the match stands
  and does not fade: up to 0.25 for the biggest unbanked pot, up to 0.25 for how
  close the nearest two karts are within 10 m, 0.20 while anyone is cashing out
  and 0.12 for a nearly full Jackpot. The two add up, capped at 1, and the
  reported value climbs at 3 a second and falls at 1.2. Pressure alone never
  quite reaches the top and one kill on its own does not either, so nothing winds
  up unless several things are going on at once.
- **Excitement levels**: the meter is not read directly. A match is run as six
  levels, opening at 1 and finishing at 6, and each level has a fixed effect:

| Level | Meter from | Lights                                                      | Music                     | Camera                    |
|-------|------------|-------------------------------------------------------------|---------------------------|---------------------------|
| 1     | 0.00       | One head, pointing up, drifting over the air above the room  | Intensity 1, mix dullest  | -                         |
| 2     | 0.12       | Two heads, still pointing up                                 | Intensity 1               | -                         |
| 3     | 0.28       | Three heads, tipping down onto the floor, faint beat flash   | Intensity 1               | -                         |
| 4     | 0.45       | Four heads, fully down on the floor, sweeping wider          | Intensity 2               | -                         |
| 5     | 0.62       | Five heads, wider, quicker and brighter                      | Intensity 2               | -                         |
| 6     | 0.80       | All six, widest and quickest, hardest flash on the beat      | Main mix, fully open      | A nudge on every beat     |

- **Moving between levels**: the meter has to keep asking for a different level
  for 2.5 s running before the room follows it, the level then moves one step,
  and having moved it stands for 6 s whichever way it went. Giving a level back
  also takes the meter falling 0.06 below the mark that won it. So the evening
  builds rather than flickers: a flurry cannot flick the room up and straight
  back down, and a climb from 1 to 6 takes at least half a minute of sustained
  action. A bounty being called puts the room up a level on the spot, since a price on the
  leader's head is an announcement rather than something to wait out, and the usual hold
  keeps it there. Three more things skip the queue. Last Call stops listening to the meter
  and walks the room up on its own clock, one level every 2 s until it is at the top,
  so the finale arrives over about ten seconds as a build rather than as a switch;
  a room already halfway up gets there sooner. Somebody one cash-out from winning,
  3.4, does the same, since the match may be about to end; once nobody is, the
  room goes back to the meter and comes down as gradually as ever. And every human player being dead
  drops the room to level 1 at once, except during Last Call, which is the finale
  whoever happens to be lying in a pit for the last few seconds of it.
- The music is not switched by Last Call either. It follows the levels like
  everything else, so the full mix arrives with level 6 partway through the climb.
- **Winding up between levels**: the music bus carries a low-pass filter and a
  gain stage that follow how far through the levels the room is, 0 at level 1 and
  1 at level 6. The filter sweeps from a muffled 1.7 kHz up to fully open and the
  gain from -7.5 dB to -2.6, so an opening lap sounds like a bar with music on
  somewhere and the finale sounds like the music. The early levels are meant to
  sit under the room rather than lead it. Both sit after the bus volume, so the
  audio settings keep full control. How far the gain comes up is the player's,
  see Intense music in 8.5: those 5 dB are where it starts, and Off leaves the
  music at the level 1 gain all the way up while the filter still opens.
- **Going under**: a player at this screen dying pulls the same filter down from
  wherever the levels have it to 380 Hz in 0.2 s, as if the music were heard from
  under water, holds it there 1.5 s and sweeps it back up over 3 s. Only the
  player's own screen does it: online a client goes under for its own death and
  nobody else's, and a bot going down is only heard as a death. Dying again on the
  way back up takes it straight back down. The audio settings of 8.5 can turn it
  off.
  A kill shakes the camera by 0.2 plus half of that same share. At level 6 the camera thumps on every
  beat and harder on the first of the bar, each shaped so it has fallen away before the
  next arrives, which is the one place the room is felt as well as heard. A beat hits
  harder than a kart being wrecked in a cold room and stays short of a kill in a hot
  one, so the music is felt through the floor without ever outshouting what is
  happening on it. All shake obeys the accessibility toggle in 8.5.
- The F3 overlay shows the level and the meter with its two parts, the layer,
  both players' levels and positions, how far the filter is open, and the mute
  state.
- **Chips**: clink on pickup, pitch rising with rapid pickups.
- **Mult**: dice rattle on gain, a soft ping on graze.
- **Cash-out**: slot-machine ticks while draining, a jackpot chime on
  completion, fanfare on big pots.
- **Jackpot**: a soft tick per accrued chip when nearby, and a bell heard by
  everyone when the pile is full.
- **Karts**: every kart carries its own engine and tires, positional in the
  room. The kart somebody is driving here gets all of it; every other kart gets
  a lean version, one engine and one squeal covering whatever its tires are
  doing, no wheelspin chirp, and its engine shifted a little off the recorded
  pitch by slot, so three karts behind you are three engines rather than one
  louder one. A kart somebody else is driving over the network is one of these
  too: it sounds like any other kart that is not yours.
- **How loud another kart is**: 2 dB over your own at the distance the ears sit
  at, which is another kart right alongside, and the falloff takes it from there.
  Your own engine is a bed running the whole time, so anything much under it
  simply disappears; a kart has to be able to poke through that bed as it comes
  past, and be well under it by the time it is across the room. Everything else a kart does is a one-shot the whole room
  hears. Sounds are from the Cascadia Games Racing Sound Pack.
- **How far off a kart sounds**: level falls by 6 dB each time the distance
  doubles from the 2.5 m the ears sit at, so a kart right behind you is close to
  its written level and one across the room is about 20 dB down. That range is
  what makes somebody coming up behind you worth hearing.
- **Rev counter**: the engine is not pitched off road speed. One engine loop is
  stretched across the whole range by a needle that the road pulls on, running
  from an idle at 0.13 to the limiter at 1 and on to 1.30 when the kart is shoved
  past its top speed. There is no gearbox: one continuous pull. The needle
  climbs and falls at 4.5 a second, so it leads the kart rather than tracking it.
  - Off the line the clutch slips: the throttle revs the engine against a kart
    that has not moved yet, up to 0.62, and the kart then catches up to it. This
    is what pulling away sounds like, and it is why the engine revs on the grid
    during the countdown while the kart is held still.
  - The clutch bites over exactly the speed the road needs to reach that same
    0.62, so the needle climbs to it and carries straight on. Biting any sooner
    would drop it back down before it climbed again, which is heard as a harsh
    flare rather than a swell. The bite point is derived from the flare height
    rather than set on its own, so the two cannot drift apart.
  - Driven wheels slipping in a drift or on the handbrake add 0.16 at full
    throttle, so a drift revs higher than the road alone would ask for.
  - Reverse is one short gear of its own: it whines up to the limiter at the
    reverse top speed and stays there.
  - Nitro and turbo pads carry the needle past the limiter at 30% of the speed
    over the top, capped at 1.30, so a burn screams rather than simply repeats.
  - Spun out on oil the driver is off the pedal and it drops to a fast idle.
  - The loop plays between 0.55 and 2.30 times its recorded speed. Off the
    throttle the engine drops 6.5 dB without dropping its revs, following the
    pedals at 9 a second down and 5 back up.
- **Tires**: three squeals, one for each way of losing grip. A bright one
  for a controlled drift, rising with the slip angle; a duller one for sliding
  sideways with nobody asking, from 13 to 43 degrees of slip, and at half its voice
  for a spin-out on oil, under the spin's own sound at -9 dB: both at full drowned
  the room out;
  and that same duller one pitched well down for wheels locked under the
  handbrake or under hard braking from speed. All three are silent below 0.8 m/s
  and at full voice by 3, come in at 14 a second and die away at 7, and rise in
  pitch with speed. A chirp of wheelspin fires when the throttle goes down at a
  standstill.
- **Drift boost**: the same chime a turbo pad and nitro get, a little brighter,
  the moment a drift ends having earned its exit boost. It is the receipt the
  gold sparks give the eye. Only the kart being driven here rings it: the bots
  throw themselves into every tight corner, and a room full of that is a racket.
  No swell under it, which stays nitro's alone.
- **One-shots**: a rushing pass on a turbo pad; a swell that runs backwards into
  its own kick when nitro lights, played from 0.18 s before the end of the file
  so the kick lands just after the button; the pack's spin-out on oil; its
  crashes for a kart into a wall, the heavier one on top of a square hit, from
  -28 dB for a knock to -16 dB for a flat-out shunt, which at -8 dB was the loudest
  thing in a match, over the guns and the bombs; and its
  start tones for the countdown, one per lamp of the start gantry, with the higher
  one on the flag. Both come from the countdown itself rather than from the match
  starting, so a room with no countdown has neither.
- **Level**: everything a kart itself makes comes down 5 dB together, so the
  engine flat out sits near -4 dB and the squeals below that. It is running the
  whole time, so it is the bed the rest is heard over rather than an event in
  it. All of it goes to a Kart bus under the effects bus, so one slider in 8.5
  covers the lot.
- **Hitting a wall**: walls are clipped constantly in a room this size, so the
  same bang every time wears out fast. How hard the wall was hit, 0 at the
  lightest contact worth hearing and 1 straight into it flat out, runs the level
  from -24 dB up to -8 and the playback speed from 1.3 down to 0.9, and only
  past 0.55 of it does the heavy layer come in underneath. A kart may be heard
  hitting a wall once every 0.45 s at most, because bouncing down a wall breaks
  contact between every touch and each touch would otherwise be another bang.
  No effect with more than one file ever plays the same one twice running.
- **What makes those levels real**: a positional voice has its level added to
  its distance attenuation and the sum clamped to a ceiling. So the ears sit at
  exactly the distance a kart is written for, 2.5 m, where that attenuation is
  nothing, and the ceiling sits above the loudest thing asked for. With the
  ceiling at or under the levels every voice is flattened onto it instead and
  none of the numbers above do anything, which is audible as an engine that
  never changes and squeals that snap in at full voice.
- **Where the ears are**: the camera frames the whole room from well outside it,
  so a listener up there would put every kart at the same distance. The ears sit
  over the karts being driven here instead, two and a half meters up, facing the
  way the camera does, so left on screen is left in the mix. On a client that is
  its own kart, found as soon as the host says which one it is. With two or more
  players at one screen the ears sit in the middle of them, and there is only
  the one pair: so every kart's voice is heard as it would be from over
  whichever kart driven here is nearest it. Each player hears their own kart as
  close as one player alone does, and a kart beside them as beside them, rather
  than everything from halfway across the room. The engine goes to its own bus
  under SFX so it can be balanced against the one-shots.
- The F3 overlay shows the needle, what it does to the loop, the load and the
  three tire levels.
- **Combat**: soft pop on fire, ricochet tick on bounce, thud and a short
  deflating sound on death.
- **Pits**: a tone dropping away as the floor goes from under a kart, pitched well
  down so it reads as going somewhere rather than arriving. What it lands on is the
  death sound, which follows on its own when the fall runs out.
- **Menus**: a button ticks as the cursor lands on it and clicks as it is pressed,
  both well under everything else, at -26 and -20 dB. On a touch screen a tap is
  both at once, and at the level they used to be a tick and a click on every tap
  was noise over the music rather than an answer.
  Backing out with Back, Escape or a pad's B, out of a screen, a pane, a question
  or the cursor off the license and the folder, gives a small buzz at the click's
  level, wherever it is done, over whatever sound the thing put away makes itself.

### 8.5 Settings and accessibility

All settings are saved between sessions, see 10.2. Anything that is on or off is a
switch rather than a tick box, drawn by the game rather than taken from the engine's
theme: an empty tick box is a dark outline on a dark menu, and a row that was off
showed nothing at all beside it. The picture is drawn at four times the size it is
shown at, with soft edges rather than stepped ones, so a big display scaling the menu
up has something to scale: a switch drawn at its own size is a staircase round every
curve of it. Anything picked from a list is a box the height of the buttons round it,
52 pixels and 60 on a touch screen, cut from the same card as a button with the same
gold under the cursor, and the list it opens is a solid pane of entries as big as
the box, spaced out further for a finger, the one under the cursor lit like a button
and the one picked marked with a gold dot. The engine's own was a grey strip of
small print, the smallest thing on any screen it opened over. The settings' tabs
are cards too, padded like buttons and taller for a finger, the page showing lit
with gold along its top.

The tabs, in order: the license's page, its tab named for what the House calls the player at the
story's stage, STORY.md 5.1, Me to start with and with the story off, then Player,
Participant, Number, Candidate and Operator; Seats, Controls, Audio, Video, Accessibility,
Statistics, Profiles and About. From the title the settings are a screen of their own. From the pause menu of a room they open
over the room instead, and Back comes back to the pause menu: the match, and online the
connection and everybody on it, carries on underneath untouched, and a room that goes while they
are open keeps whatever was changed in them. The page keys step through the tabs, round at the
ends, as they turn the large dialogs' pages, 8.8: Q and E, or a pad's shoulder buttons. They are
drawn right after the last tab, as the keys while keys are in hand and otherwise as the shoulders
while a gamepad is plugged in, one the engine knows for a gamepad, and not for the mouse alone;
at the row's right end while the tabs do not all fit and scroll. A box being typed in keeps its Q
and E, and while a rebind is listening they are bindings like any other button. The screen keeps its whole foot for the
page, which on a phone was cramped under two rows of foot: the title stands at the top left,
Back at the top right, and what was last done, a binding bound or reset, between them. The cursor
starts on the first thing on the page, the license on the License page, rather than on Back, and
down from Back or the tabs goes there too, whatever is nearest under them. A page scrolls to
whatever the cursor goes to, with room round it for its mark as far as the page goes, rather than
leaving it out of sight past the page's foot. On the License page it
goes a row at a time, along the cards on top and the sections' grid a row of it at a time, the same
column up and down and never off a row's end, rather than to whatever is nearest that way, which
from a section's button low in its box was the one beside it.

- **License**, first. While the driving school or its test is under way, its pages or
  its lot, it says only that: "License in progress", that the player is taking the
  test right now and finishing it earns the license, the learner's L, and for a player
  who already holds one, that it stays until the new one is earned; no way to the
  school, which would leave the test for the start of another. Otherwise it is headed License,
  as the Statistics page is headed, over whose it is, its number and the day it was issued, and
  under that the driver license earned at the driving school of 9.4a, as it
  was stamped, at seven tenths of its size so the plate and the ways on fit under
  it without the page scrolling, reached by the cursor as a button is, first on the page, and
  taking it under the mouse as the catalog's cards do, marked the same way while it is on it, the
  page where it scrolls, at a large UI scale, keeping room for the mark, and shown in full over the whole screen as the title
  shows it on accept, a click or a tap, growing up off the card and going back down onto it;
  beside it, once the profile has found a note, Kit's
  folder of STORY.md 7.2, standing upright and still, as tall as the card, reached and opened the
  same way, the notes coming up over the settings; from a room's pause menu, once a note has
  been taken in the map under way, grayed with an hourglass on it and a line under it saying the
  new note can be read once the map is over, and neither reached nor opened. Under the cards
  the rest is laid out in sections, two across, each titled in gold as the Statistics page's
  groups are, what is in it down its left: Plate, the plate on the back of the kart to change,
  see 4.4, up to eight letters, digits, spaces and dashes, cleaned as it is typed; Driving
  school, the day it was passed and Retake the driving test, which goes to the school; Your kart,
  "Its parts, its color, its name and its plate." over Customize kart, which opens the kart
  dialog of 4.4a over the settings, there unless the settings are laid over a room, whose pause
  menu has its own way to the dialog where a kart can change; for a
  profile the House has welcomed, the Loyalty Program by its name, how many of its landmarks are
  won and Open the map, which opens it over the settings as 8.9 has; Catalog; Achievements; and Story. All of it stacked down the middle, each under the last, was a page with no
  order to it once everything was won. Before a license is earned, a word on where to get
  one, Earn it now, which goes to the school, and the learner's L the kart wears meanwhile,
  over the Story and Catalog sections. Story is the switch for the story of 8.7, Story
  Progression, for the profile playing and on to start with, over "The small print, the
  notes, and where they lead.": switching it off asks first, saying it can be switched back
  on at any time; off, the story's clock stops and the game is the casino of its first stage
  throughout, STORY.md 5.4. Catalog, whatever the page shows, says "Every joker and power-up
  you have found." and how many of how many, over Open the catalog, which opens the catalog of
  8.8 over the settings: a room's pause menu reaches it this way, having no room of its own for
  it. Achievements says "Everything you have set out to do and done." and how many of how many,
  over Open the achievements, which opens the dialog of 8.10 over the settings the same way.
- **Seats**: down the middle of the page, headed Seats over a line saying what it is for, as the
  Statistics page is headed, a seat card of 8.1a each
  for the four seats at this machine, its chip numbered 1 to 4 in the seat's color,
  with a box for what the seat is called, see 3.8, with the funny-name hint in an
  empty one, and after each the seat's favorite color, 4.4, chosen from all of them
  in a row of chips, the chosen one ringed in gold and standing a little bigger and
  none before one is, the seat's own chip taking it at once, in the palette worn, drawn
  again the moment Color blindness changes it; a single swatch that moved on
  round them was a guess at what came next. Then a small button with the picture of how that seat drives, simple or
  advanced, that changes it to the other, see 4.2. The first seat's is the Driving row of
  Controls, and each shows what the other was changed to.
- **Controls**: how the first player drives, simple or advanced, each a button
  with its picture on it, a kart with an arrow each way round it and a steering
  wheel, and Help me choose beside them for the question the first Play asks, see
  4.2; rebinding per player for gamepad and keyboard, the keyboard's side taking
  a mouse button as well as a key, fire on the left button say, stick dead zone, rumble on
  or off, and on a touch screen, first after the driving, how it drives: by the
  slider or by a button each, see 4.2.
- **Audio**: master, music, effects and kart volume, the master at 50% to start
  with, since at full the game came on loud enough to reach for. The karts have their own
  because their engine and tires run the whole time rather than in bursts, so
  how loud that bed should sit is a matter of taste in a way the rest is not.
  The kart bus is under the effects bus, so the effects slider still scopes it.
  Under Music, Intense music says how much louder the music gets at the hottest
  the room gets, see 8.4, on top of the level it plays at on a quiet table: Off
  leaves it there, and above that it is how much louder it sounds, up to +100%,
  counted as loudness rather than signal, so +100% is twice as loud and ten
  decibels. It starts at +40%, about 5 dB; the 9 dB the music came up by at
  first, +87%, jumped too far at the top of the heat, and a setting still at
  that is read as the new start. It can never make the hottest music quieter
  than the calm. The setting is written beside the slider, and under it are four
  marks with their names: Off, Gentle at +20%, Normal at the +40% it starts at,
  and Strong at the top. A switch turns
  off the music going under water when a player here dies, see 8.4, on by
  default.
- **Video**: window mode, vsync, frame rate limit, show FPS, render scale,
  upscaler, UI scale, bloom, shadows, MSAA, screen smoothing, tire marks and
  the crowd.
  A phone or a tablet starts full screen, with the system's own bars out of the
  way, and so does a released game on a desktop; a build from the editor or a
  debug export starts in a window, beside whatever it is being worked on with. The
  setting, once changed, is kept either way. Bloom and the multisampled edges are the
  passes a room pays for most, and they are the two things worth handing back on
  a card that cannot spare them: at 1080p on a mid card the bloom is about a
  tenth of The Vault's frame and 2x multisampling about a twentieth, and turning
  both off is most of the difference between that room and the others. MSAA is
  off, 2x, 4x or 8x; screen smoothing is the pass over the whole finished
  picture, off, FXAA or SMAA, for about a third of the price of the
  multisampling. A desktop starts with bloom and 2x MSAA and no screen
  smoothing; a phone or a tablet, whose card is the one that cannot spare them,
  starts with neither and with FXAA instead, since a room made of straight lines
  crawls with nothing smoothing it, and at a render scale of 80%. A settings file
  from when the two were one switch, Edge smoothing, reads as what it did: on was
  2x MSAA, off was FXAA. The upscaler is how a room drawn under the screen's
  size, at a render scale below 100%, is brought up to it: the plain stretch,
  which it starts on, or AMD's FSR 1 or FSR 2, sharper for a little more of the
  card. FSR 2 needs the desktop's renderer, and a phone's has FSR 1 in its place.
  Shadows are what the room's sun and lamp cast: off, low, into smaller maps with
  hard edges, or high, into the big ones with soft edges. A desktop starts on
  high and a phone or a tablet on low, which is what each renderer does of its own
  accord, and low or off is the thing to try on a phone that struggles. The frame
  rate limit is the most frames a second the game draws: unlimited to start
  with, or 30, for a phone to last longer on its battery, 60, 120 or 144. A window
  run in the background, 9.3, keeps under it too, and `++ --bench` ignores it,
  since a frame rate held at the player's limit measures nothing. Show FPS, off
  to start with, puts the frame rate in the top left corner of every screen, small
  and faint in the strip above the first player's block, for a player finding out
  what their settings cost. All of it takes effect at once. What a platform has no
  use for is not on the page: a phone or a tablet plays full screen and in step
  with its own screen whatever it is told, so it has no window mode and no vsync,
  and a renderer without FSR 2 does not offer it. The page scrolls on a short
  screen. The UI scale draws every menu and the HUD bigger or smaller, from 75% to
  200% of the size they were laid out at for a screen 1080 lines high, and leaves
  the room behind them as sharp as it was. It starts at 100% on a desktop and at
  150% on a phone or a tablet, which is held close enough that a HUD laid out for
  a monitor across a desk is a HUD of things too small to press. It is picked from
  a list rather than slid, since a slider would grow and shrink the screen under
  the pointer dragging it, and it takes effect at once. `++ --ui-scale=1.5` on the
  command line uses a size for that run alone and saves nothing. A screen drawn
  bigger than the window has room for still fits: a menu taller than the window
  scrolls, the podium shrinks to it, the title leaves out the mark over its name,
  and on a touch screen the pieces of the HUD keep off each other, see 4.2. The
  hint over a kart at the start of a match grows with it too, drawn at the bigger
  size rather than stretched to it, so it stays sharp. Tire marks, 4.3, are
  Full, Short, Mine or Off: every kart's, fading over 20 s; every kart's, gone in
  4 s; only the karts of the players at this screen, gone in 4 s as well, which
  is the least clutter and the least to draw with a full table; or none. A
  desktop starts on Full and a phone on Short, and a settings file from when
  they were only on or off reads on as Full and off as Off. Marks a kart may no
  longer lay go at once rather than fading out. The gold tracks of a pot that would win are laid either way: they
  say who is about to win rather than dressing the floor. The crowd, Full, Half
  or Off, is how many of the house came: the crowd is the most triangles on the
  screen by far and none of them are the match, see 10.7, so a phone starts with
  half a house and a desktop with a full one, and a change stands the house up
  again at the new size a moment later. Off empties the stands and leaves the
  booth, and turning it back on is at once. It is one setting offered on this
  page and in Accessibility alike, since it is both what a card can afford and
  the busiest thing on screen that has nothing to do with the match. Nothing
  about the crowd changes anything a kart can touch.
- **Accessibility**: screen shake on or off, flash reduction, the cursor's glide
  between buttons on or off (on by default, 8.1a), aim assist
  strength from 0% to 100% of the default and never above it, per player, the
  aim guide on or off and how it is drawn, its length from 2 to 8 dots (4), the dots' size from
  half to two and a half times their own, how solid from faint to solid (45%) and their color,
  the player's own, white or a yellow that stands off any felt, with Reset beside the four putting
  them back as they were, there to press only while one of them is not, and reached on a pad down
  or across from the color, the sliders taking left and right for themselves, changing at once over a
  room and shown under the switch as it is set, through a window with rounded corners in a frame
  of foil, the first seat's kart on a strip of felt by the rail swinging its nose slowly to and fro
  with the dots ahead of it, in the palette for color blindness the moment one is chosen, as the
  karts and their guides over a room are, the disco lights Full, Few or Off, the control hints on or off,
  speed in km/h or mph, always show drive hints, off by default, crowd Full, Half or Off, and the
  fixed camera on or off. Speed in is the speedometer's unit, 8.3: until it is chosen, the country of
  the system's locale says, `SpeedUnits`, the measures' own where the system keeps them apart, Linux's
  LC_ALL, LC_MEASUREMENT and LANG in that order, and otherwise its locale; mph only where the
  roads are signed in miles an hour, the United States, the United Kingdom, Liberia and the
  territories and Caribbean states that kept them, and km/h everywhere else, for a locale with no
  country, English on its own say, and for one that cannot be read. Only a choice made is kept. Few lights three heads
  at most however hot the match runs, and is where a phone starts, see 10.7:
  every lit head is a light over the whole table. The crowd is the same setting
  as on the Video page; Off empties the stands and leaves the booth, since it is
  the thousand moving things around the table rather than the party that is worth
  being able to stop. The fixed camera is off by default and is described in 8.2:
  a camera that never goes anywhere is a smaller picture of the karts, which is a
  real cost, and a still one, which for some players is worth more.
  Color-blind roof markers are always on. First on the tab, the player colors
  can be drawn for color blindness: off, protanopia, deuteranopia or
  tritanopia, with the eight colors it gives beside the choice. Each is a palette
  of its own in the same slots, each color as near the hue it stands in for as it
  can be, chosen by simulating that kind of color blindness (Machado 2009) and
  keeping all eight at least 28 apart in CIELAB under it and under normal vision,
  and clear of the felt; the usual palette has blue and purple 7 apart for a
  player without red or green cones. It is every machine's own, since it is about
  whose eyes are looking. Changed from over a room, everything in it changes
  there and then: every kart, a client's and the decoys included, the corners of
  the HUD and the switches, each still the slot of the palette it was.
  A screen reader needs no setting: the engine hands it the menus through AccessKit
  whenever one is running, and nothing is paid for it otherwise, `ScreenReader`. It
  reads every button, label, switch, slider and box as the engine knows them, a row of
  settings named by its label; what the game draws for itself is named from the words
  drawn on it and says it is a button or an entry of a list: the license peeking in,
  read with what its face says, Kit's folder, the bay, the catalog's cards, the
  achievements' rows, the loyalty program's rows, card and pinned note, the kart
  dialog's hooks, cans, rack and plate, the bindings' sockets by action, column and
  keys. A question is read as a dialog of it. What comes up with no cursor to take
  there is said as it comes, after whatever the reader is saying: a notice, a room's
  status, the lamps of the start and GO, Last Call, a match point, an achievement
  earned, who won on the slip, the card under a pick's cursor or lifted from the hand,
  the landmark the map's cursor comes to, whose key the kart dialog turns to, a note's
  page and the whole of a note looked at closer. The HUD's numbers, which change every
  frame, are left to be read rather than said.
- **Statistics**: the profile playing, over every map it played to the end, in six
  groups, two across. Games: maps played and won, Grand Prix runs played and won, and time
  played, the clock running. Driving: distance driven and drifted in kilometers, the longest
  drift in seconds, nitro burned, turbo pads and drift boosts. Fighting: kills, the best kill
  streak, shots fired, accuracy once ten have been fired, near misses, bullets shot down, rams,
  bomb kills, bounties, lives patched up and crates broken. Money: chips picked up and out of the
  Jackpot, cash-outs, the biggest cash-out, the most banked in one map, the biggest pot carried,
  the highest mult and match points. Cards: jokers taken, power-ups used, flush pads taken, Royal
  Flushes, and how often a hand went Suited in each suit, 7.3. Mishaps: deaths, chips lost and dropped, pit falls, own goals and spins on oil.
  Everything the results screen counts is added up, see 3.8, the few that are a best
  kept as the best. A map counts as one played only once its whistle has gone, local
  or online, against bots or people; a Grand Prix counts on its last map. What is done
  counts wherever it is done, though: a match left before its whistle, for the lobby
  or the title, out of the game, or with the line to the host gone, counts all of it
  but the map, and so do the lobby and the driving school, which are no matches, the
  distance, the drifts, the shots, the kills and the rest, and the time spent in them,
  written as they are left. A player here who gets up in the middle of one, from
  their switch, with their pad unplugged, or from a client, has what they did
  written into their profile there and then, the one sat in at their seat too,
  since the kart goes on without them; and somebody who sits down in a kart that has
  been going, a bot's or one somebody got up from, counts from then on only, so
  nobody is counted for what somebody else did. Leaving before the whistle once
  counted for nothing, and the lobby never counted at all. Only the room the game is in writes, and never a
  headless run, so neither a test that starts one nor a smoke run writes the player's
  own statistics. The Garage counts nothing. It is the first seat's, whose profile is
  playing; a seat sat in as another profile, see 3.8, counts into that one, written
  before the title makes every seat a guest again; and a guest's counts nowhere. No
  reset: a new profile starts from nothing. `LifetimeStats`, written by `MatchRecord`
  a moment after the whistle, when a client has the host's last numbers, or as the
  room is left. From the story's second stage, 8.7, a line under the page's title says whose
  record this is, and after its ending Games has one more row, Shifts, the maps played since,
  STORY.md 6.6.
- **Profiles**, after Statistics: who is playing at this machine, down the middle of the page as
  the Seats, License, Statistics and About pages are, headed Profiles over a line saying so as the
  Statistics page is headed. A profile is a person's save, kept
  apart from how the machine is set up: the names, karts and ways to drive of the four
  seats, the driver license and its plate, how far through the driving school they got,
  how far through the story of 8.7 they are, every joker and power-up they ever took for
  the catalog of 8.8, their loyalty program of 8.9, their achievements of 8.10, and the LAN game and server they last
  played on, each profile a file of its own in a folder beside the settings file,
  `profiles/1.cfg` and on, written whole with the one before kept as its backup, so a
  crash part way through a save never costs a profile, see 10.2. The picture, the sound, the
  controls and their bindings, the touch layout and the lobby's choices stay with the
  machine, the same whoever plays. A profile is named for its first player. Each row
  is a seat card of 8.1a, its chip in the first player's color with the name's
  initial on it, the one playing's rimmed in foil and saying Playing now, with the
  plate the profile's kart wears, or
  before a license the learner's L itself rather than a plate reading L, how many maps
  it has played, and Switch, Edit and Delete as pictures, two arrows trading places, and
  the pencil and the trash can the kept servers of Play Online wear, 9.3a, with their words
  as tooltips, Switch dimmed on the one playing. Edit asks for the
  name in a dialog over the
  screen, a box with the name in it, Save and Cancel, and renames that player; a page of
  name boxes would have looked like something to fill in rather than a list to pick from.
  Delete asks first, in a question over the screen with the warning sign, "Delete this
  profile?", saying what goes with it, the cursor on Keep, and is not there for the one
  playing. New profile asks for the name the same way, with two ways ahead: Make, in
  foil and the one Enter presses, makes the profile and leaves the one playing as it is,
  and Make and switch goes to the new one as well. A machine keeps eight, and once it has
  them the page says "Maximum number of profiles reached." The dialog wants a name: Save,
  Make and Make and switch are off while the box is empty, Enter goes ahead and Back
  cancels. Switching puts the
  settings up again for the profile now playing. All of it is done from the title's
  settings: inside a room the names at the table are already the ones playing, so there
  the page only lists the profiles, with Edit, Switch, Delete and New profile all off and
  a line saying to manage profiles from the title. Making one inside a room once froze
  the game: the settings went to a page of their own, under a room that was stopped for
  the menu and stayed stopped. Linking a seat to a profile, 3.8, is still done in a room,
  since it changes no profile. `NameDialog`. A
  settings file from before profiles is not carried over: the first profile starts
  blank. The other seats are guests of the profile playing, kept in it as before,
  until another profile sits in at one, 3.8.
- **About**: the game's mark, its name and its version, and that it is an
  experiment in what an AI model can make: everything in it not credited there
  was made by Anthropic's Claude, whose models are named in the order they worked
  on it, and that "A human oversaw it: played it as it grew, made the calls no model
  would have made, and put their name on it.", which says in the story's terms what
  it always said, for everybody and whether the story of 8.7 is on or off, being true
  either way, STORY.md 3.11. Then everybody else whose
  work is in it, what, by whom, on what terms and where, which a test holds to
  THIRD_PARTY.md, a link to the game's GitHub page, and Godot's own license, which a game
  made with it has to carry.
- **Story**, in a debug build only, last: where the profile playing is in the story of 8.7,
  its stage, its clock and when the next stage begins, the notes found and read, the next
  note and when it is due, whether the Final Hand is due or played, and its shifts; and
  buttons that move it, kept in the profile: a license, a stage back or on, ten minutes
  more, the next note found there and then as if picked up or the last one taken away,
  every note or none, every note unread, the Final Hand due, the ending as if stamped, the
  story started over, and the first invitation of STORY.md 6.1a owed again. The README lists the command line's story
  arguments beside it.

### 8.6 Loading a map

A room takes about a sixth of a second to put up: the floor, the walls, the
thousand people round it, the clutter of 8.1 and the bake that merges the lot.
Done in one go it is ten frames in which the last screen has stopped, which reads
as the game hanging rather than as the game working.

So a map goes up a phase at a time with a loading screen over it: the name of the
room, a bar, and what is being built, and over the name a hand of five cards fanned
face down in the card back the player wears, 8.9, each over the one before as a hand
held lies, a slow wave running through them all the while, so the screen is seen to be
alive rather than stuck; one of them, any one, slides up out of the hand as the room
nears up and turns over to the House's face, its seal in foil on black, as it is up. The cards are
pictures drawn once a run, moved rather than drawn again. The phases are the real ones -- the same list
the room builds itself from -- so the bar moves when something has actually
happened, and a room that takes longer to build shows a bar that takes longer to
fill rather than one that lies faster. It is the same screen whether the match is
local, hosted, or a client waiting on the host to say which room it is. The rooms
between the maps go up the same way under their own names: the Garage, the test
track and the waiting room, the last whether it is hosted, joined or followed back
into from a match.

What a client is told while it waits to be let into a map, starting the match or connecting, is
said on the loading screen's own dark, so the words and the loading screen after them read as
one screen rather than a gray one flashing up between two dark ones.

Anything that cannot wait a frame -- the tests, the dev scenes -- builds the room
in one go as before, which is the same room by the time it is finished.

From the third stage of the story, 8.7, the line under the bar says who the room is being built
for, and the Final Hand's loading screen is headed FINAL HAND, STORY.md 6.5.

### 8.7 The story

The story of 1.3 is presentation and nothing else, but for the Final Hand's room and Kit's cards:
it is told in the margins
of the screens this document describes, and this section says which, how a player moves through it
and what it may never touch. The words themselves are all in STORY.md, in one place, so they are
written and read as a story rather than scattered through a design.

**The clock.** A profile moves through the story by playing and nothing else: its own clock of time
spent on maps since it earned the license of 9.4a, the match clock's time from the flag to the
whistle or to leaving, local or online, against bots or people. A map of 1 minute moves it a fifth as
far as a map of 5, so the story keeps one pace whatever length of map a player likes, and before the
license it does not run at all. Six stages, each named for what the house calls the player in it:
Customer from the license, Player from 5 minutes, Participant from 22, Number from 45 and Candidate
from 72; the Final Hand at 100, about two hours at the tables once the lobby, the picks and the
slips are counted; and Operator after it. Those numbers and the notes' spacing are
constants kept together, so the pace is a line to change once it has been played. The clock, the
stage, the notes found, the terms declined, the Final Hand's answers and the ending are kept in the
profile beside its license, 8.5, and what every screen at a machine shows is the story of the
profile playing. A profile from before the story starts it from nothing, as a new one does; one from
before it was retold keeps its clock and notes, a note now earlier than its next one filed new in
its folder. STORY.md 5.

**Switched off.** The License tab of 8.5 has a switch for it, Story Progression, per profile and on
to start with, which asks before it goes off. Off, the clock stops and the game is the casino of the
first stage throughout, with no notes, no folder, no letters, no scratch on the license, no box
answered for you on the enrollment, none of Kit's cards and no Final Hand; on again, everything is back where it
was. STORY.md 5.4.

**Each machine's own.** None of it goes over the wire, any more than the roll of the music does,
8.4: each machine dresses its own room and prints its own slips for its own profile, so two players in
one online match may read different hoardings, and a machine from before the story, in the same match,
knows nothing about it. The one thing that goes is a flag a seat, whether Kit's cards may be dealt
to
it, sent to the host as the loyalty program's unlocks are, 8.9, since the host deals, 3.7. The match
itself, the one thing every machine has to agree on, it never touches but at the Final Hand, whose
racks and turret are the host's, 6.3.

**Where it shows.** Each of these is described where its screen is, and its words are in STORY.md:

| Surface | What moves with the story | Here | STORY.md |
|---|---|---|---|
| The hoardings | More lines each stage, some with the player's name; green for a second when one of Kit's cards is taken | 8.1 | 6.1, 6.3 |
| A poster | One on each room's back wall, changed once a stage | 8.1 | 6.1 |
| The road | A stenciled word in a box across one lane of each map | 8.1 | 6.1 |
| The payout slip | Its small print, a second line from stage 2, the player's classification and their class's line from stage 3, Payslip after the ending | 3.8 | 6.2 |
| The joker pick | A line of small print under the cards and TERMS ACCEPTED as one is taken, from stage 1 | 3.7 | 6.3 |
| Kit's cards | Now and then one in a pick, from the first note | 3.7, 7.3 | 6.3 |
| A joker's pane | A line of small print under its effect from stage 2, the term the card is | 7.3, 8.3 | 6.3 |
| Microprint | The HUD's corner blocks and the title | 8.1a | 6.4 |
| Loading | The line under the bar | 8.6 | 6.5 |
| Statistics | A line under the title; a Shifts row after the ending | 8.5 | 6.6 |
| The catalog | A line under the title from stage 2; each joker's term, as in its pane | 8.8 | 6.6a |
| The loyalty program | Its name and the line under it by stage, the atlas's name on its cover; Kit's roads in pencil from the first note | 8.9 | 6.6b |
| The house's letters | One at the title as stages 2, 3 and 4 begin, and one after the ending | 3.8 | 6.11 |
| Achievements | Six of them are the story's, hidden until earned; the motto on their table by stage | 8.10 | 8.7, 6.6c |
| The driving school | The Highway Code's edition and a handful of its lines; the enrollment's box answered for the player; the license's scratch and fine print; after the ending, the examiner | 9.4a | 6.7 |
| The rooms | The Yard's sign, the Workbench's calendar, After Hours' pictures | 8.1 | 6.8 |
| The crowd | Watchers from stage 2; in step from stage 4, but for one | 8.1 | 6.9 |
| A bot | One in a piece of the player's dress from stage 3, on this machine only | 9.1 | 6.9 |

**Notes.** The one thing the story puts on a table: a scrap of paper among the litter of 8.1, taken
by driving over it the way a chip is and put away without stopping anything: NOTE COLLECTED written
in pencil on a big torn scrap in the middle of the screen, with a rustle and a pencil's scratch,
with a new note's pencil mark in its corner, then in the player's corner for two seconds, which with
the pencil tick of a bet won off the books, 8.9, is all on the HUD the house did not print. A soft halo breathes on the floor under a note lying
there, so it can be told from the litter. Nothing the house prints ever mentions one, and nothing
says how many there are. The first turns up on the first map after the license, early in it, a quick
match's or a Grand Prix's; the rest are spread over the stages, about one a map at first and fewer
later, one that is due turning up for certain before the ending, at a random moment of a map rather
than at the countdown, at most one a match, and one left lying turns up again in a later map. It
lies on this machine's
floor only and only this machine's karts can take it; bots never go for it, nothing that happens in
the match moves it, and a bullet flies over it. Never in the Garage, the waiting room, the driving
school or a Grand Prix's party. Once one has been found a manila folder peeks in from the left edge
of the title, the way the license does from the right, OFF THE BOOKS on it in marker, and comes out to
the middle and opens on the notes found so far, one on each side of a leaf in the story's order,
turned as the Highway Code's pages are and as fast as the arrows or a pad's shoulder buttons are
pressed, every leaf seen going over, each page's number pencilled at its foot, each note a little
askew on its page under a clip, tape or a staple; the menu's cursor reaches it going left from the
buttons, and Back takes it off the folder or the license again. A note
can be taken off its page, growing up off it, by a click or accept, to be looked at
larger, closer and turned over, a click turning it and a right click putting it back, the folder's
and the closer look's buttons there for the mouse and showing their keys and pad buttons when those
are in hand,
tilting toward the mouse as the license does with the light moving softly over the paper, the notes
either side sliding in and out, and a few have something on the back; what is kept at the back after
the ending is looked at the same way, its gold catching the light; a cross puts
the folder or the note away, turning arrows turn the note over, and the arrows either side carry
the pencil mark when what they go to is new, as the magnifying glass does while a note open in
front of it is new, taking that one out. The profile keeps which notes
have been read as well as which were found, and a note not yet read is marked new in pencil: a
corner of its paper sticking up out of the folder with an exclamation mark on it, and on its page
inside, which the folder turns to quickly from its first spread and takes off its page for a closer
look, a turn or any press stopping it; a note taken out for a closer look is read. After a map in
which a note was taken, the folder also peeks in beside the payout slip and opens over it, online
as well, where the room moving on at the host's word takes it away with the slip, every note read
in it kept read; and at the Final Hand it is offered beside the house's page, so that Kit's last
note can be read before the page is stamped or torn off. The house's letters and Kit's cards taken are kept in it too. STORY.md 7.

**The Final Hand.** At 100 minutes the title hangs a flyer at Play, cut as the driving school's is
at its button but in the house's gold, and Play first deals an invitation, a black card edged in
gold, Take your seat or Not now under it: Not now plays on as ever and is asked again the next time
Play opens the lobby. Taken, a golden ticket, ADMIT ONE, comes up from behind the card for a moment,
the match settings come up with every value blacked out, and when the lobby is ready the ticket's
ADMIT ONE is torn off before the match begins. It is a quick match on House Rules, 6.3, in a room
of its own, the Count Room, 5 minutes and three bots, by every usual rule, and for its first third
an ordinary one. What differs: the player's seat is printed CANDIDATE wherever the house prints a
name; the bots are named after the player, wear their dress and drive on their lifetime readings of
9.1; from a third of the way in the house prints amendments to its terms over the HUD, draws a gold
line on the floor to where it forecasts the candidate's kart will be, and the crowd stops and
watches; from half way racks, and now and then the house's gold turret, rise where a kart's
forecast ends, 6.3; from three quarters the bots follow the candidate's own line, 9.1; at the
whistle the rig, the fireworks and the board are the player's whatever their place; and the payout
slip carries the house's evaluation under the lines, which the slip scrolls down to a moment after
it comes up, its last line but one the house's forecast of the stamp, with the house's own rubber
stamp, its base gold, and a tab to tear the page off by in place of the ways on. Torn off, it is
noted, the ways on come back and the Final Hand stays due, asked for again at the next Play.
Stamped, one line on an empty screen and a record of the decisions approved in the player's name
counting up from the stamp, then the license with the house's stamp on it, and the title, its Play
reading Clock in, with a line in the Count Room's green under its name that says how much of the
player the house can predict, and new fine print round its seal. Online it is dealt by whoever has
the say, and every screen in the room plays it for its own player, the room going back to its lobby
once all are through. STORY.md 8.

**After it.** The game is the same game. What it prints moves on once more, the license keeps the
house's stamp, and House Rules joins a quick match's list of maps, STORY.md 9 and 10.

**Building it.** Milestone M8 of PLAN.md is the order it was built in, and M20 the order it was
retold in, every detail of STORY.md a task, with how each was done and checked.

**What never moves.** The rules and the numbers, every house card's effect, the names of everything
a
player reads in order to play, the standings, the HUD's labels, the announcer's calls, and a bot's
name and driving anywhere but the Final Hand; Kit's cards are cards of their own, not changes to the
house's. A line of the story that could only be true by changing one of these is a
line to change.

### 8.8 The catalog

**The dialogs' keys.** The catalog, the loyalty program of 8.9, the achievements of 8.10 and the
kart dialog of 4.4a answer the same keys the same way, `DialogBinds`, fixed rather than rebound
with the kart's and the hand's in the settings, so a dialog's keys are always where its hints say:

| Role | Keys | Pad | Catalog | Loyalty program | Achievements | Kart dialog |
|---|---|---|---|---|---|---|
| Move the cursor | Arrows, WASD | Cross, left stick | Walk the cards | Drive the roads | Walk the list | Walk the hooks and the bench |
| Act on it | Enter, Space | A | | Pin a landmark; choose an edition | | Hang a rack out; wear a piece |
| Back | Escape | B | Back | Back | Back | Put the rack away; Back |
| Page before, after | Q, E | Shoulders | Jokers, Power-ups | The House's map, Kit's map | | The keys |
| The view | Tab | Y | Detailed | List | Sort | |
| The option | F | X | Stack | The card in full | Hide earned | Shuffle |
| Zoom | Minus, plus | Triggers | | Zoom the map | | |
| The suit | R | Right trigger | Suit | | | |
| The order | T | Left trigger | By suit | | | |
| Next new | N | View | The next new card | The next new landmark | The next new row | The next new piece |
| How it works | H | Left stick, pressed in | | The first look again | | |

The card held up in full turns over on Enter or A alone. A pad's View is the button left of its
middle, which the engine calls Back after an older pad; the hints call it View, as today's pads
print it, so it is never taken for a dialog's own Back.

**Next new.** While anything in one of the four wears the NEW tag, a button at the head's right,
Next new, its face an arrow coming down onto a dot, the cursor dropped onto the next thing new,
rather than words, takes the cursor at once to the next thing wearing it
after the one the cursor is on, in the dialog's own order and round past the last, turning to its
page or its sheet as it goes and showing it as the cursor coming to it by hand does: the pane says
it, it is scrolled to, and its tag comes off and is kept off as the dialog goes. Pressed quickly
again and again it clears every tag in the dialog as fast as it is pressed, nothing waiting on an
animation; and where it lands draws the eye, the same in all four, having come from anywhere: it
comes up a little bigger over what is round it and settles back, a row only a little, wide as it
is, and two rings of foil cased in ink ripple out from it in its own shape and fade. How many are left stands on a chip of the tag's own foil over its top right corner, as a
card's tag hangs over the card's, and once none is left the button goes. Its bind, N or a pad's
View, hangs on the middle of its foot while keys or a pad are in hand, as How it works' does, and a click or a tap presses it; it never
takes the cursor itself. A screen reader hears its words and how many are left, and the jump as it
hears the cursor move. Each dialog dresses it in its own look: a slip on the catalog's mat, a ticket
on the atlas's cover, a box printed on the achievements' felt, a plate of the Department's beside
the kart dialog's Back.

The title's Catalog is the record of every joker the profile playing has ever taken and every
power-up it has ever used, laid out the way a hand lays out its cards, so a card taken once can be read again away from
a match, and the deck still to meet shows as the cards not printed yet. It counts what was taken
rather than what was offered: a card seen in a pick and passed over is still not printed.

**What is kept.** Every joker that comes into a hand at this machine, from the respawn pick of 3.7
or off the floor, and every power-up used, 7.1, by its button or spent by Guardian Angel, in every
room: a match, each map of a Grand Prix, the lobby, the driving test and the Garage. A power-up
picked up and never used, lost with a death or still held at the whistle, does not count: an item is
only known once it has been seen to do what it does. Each is kept with how many times it was taken or
used, and every joker with the biggest stack of it the hand held at once, 7.3, watched in the hand
itself, which a client hears of a card off the floor a moment after the word it was taken; 0.14.1
counted power-ups as they were picked up, and those counts are left behind, and kept no stacks, so
a joker taken then is a stack of one until it is held as a bigger one. A joker that goes off by
itself in the hand, its card flashing there, 8.3, is kept with how many times it did: Toll Booth's
tolls, Pickpocket's pockets picked, Guardian Angel's hits taken, Tight Grip's pots kept shut,
Insurance Policy's payouts, Carbon Copy's copies and Road Rage's wrecks. The profile keeps it beside its statistics, 8.5: the first seat's goes into
the profile playing, a seat another profile sits in, 3.8, into that one, and a guest's, a bot's and a
watcher's nowhere. Online, each machine keeps its own out of what it is told anyway, the host's word
that a seat here took a card or an item, so nothing of it goes over the wire, and a client keeps what
its seats took just as a host does. Only the room the game is in writes, and never a headless run,
written as the room is left, as the statistics are. A profile from before the catalog starts it
empty.

**The dialog.** Catalog under the title's Clubhouse opens it as a large dialog over the title, 3.8, and
Catalog on the License page of the settings over them, 8.5, and Catalog under the Clubhouse of a
room's pause menu over the room: a shade over the screen and the House's cutting mat over nearly all of it, on a layer of its own
above a room's pause menu too, so the same dialog can be laid over any screen later. It has two pages
as the settings have, Jokers and Power-ups, the page keys, Q and E or a pad's shoulders, stepping
between them, each tab
saying how many of how many have been found, Jokers 12 / 35, with a gold tick once the whole set has.
A page with nothing found on it yet has no count on its tab and no cards: in the middle of its well,
how to unlock it, Start a match and take a joker to unlock this page, or use a power-up, and no
pane beside it, the cursor going to Back.
The row of tabs carries the dialog's binds, as the settings' does, 8.5: right after the tabs the
page keys, Q and E or a pad's shoulders, and at its right end, on the jokers' page, the switch's
and the field's, each with its word after it, Tab and F; drawn as keys while keys are in hand, and
otherwise as a gamepad's buttons while one is plugged in; with the mouse alone and no gamepad,
none. Back, B, Escape or a click on the shade beside the pane puts it away,
the cursor back on Catalog. The title stands over the middle of the pane, the story's line under
it, STORY.md 6.6a, and Back at the right of the pane's foot; short of room, under 900 pixels from
top to bottom as a phone's screen is at its UI scale or a desktop's at a large one, the title stands
at the left of the head with the line beside it and Back at its right, as the settings have them,
and there is no foot, leaving the cards the room; and the pane fills the screen, its corners square
and less room inside its edge, with no shade round it, the cards half as far in from the well's
edge and the pane half as far from the well. A page's cards lie on its sheet on the left, see The press
proof below, every card on both pages the one size, a little under a hand's,
in rows that reach across the well from one side to the other, a short last row starting at the
left; where the rows are more than the well has room for, it scrolls, to the card under the cursor
by itself and under the wheel or a finger. The pane describing the card under the cursor stands on
the right, with room round it, and over it the card's picture, large, with the engraved ring the card
has round it, in the card's color, or the question mark of one not taken: the picture rather than the
whole card, which took twice the room to say nothing more. Up to 200 pixels across, as big as the room
the column leaves it lets it be, standing at the top of that room with the pane right under it, its
size reckoned with room kept under it for the tallest a pane gets, so it neither moves nor changes size
as the pane grows and shrinks with what it says; where it would be under 96, a phone's short screen,
it is left out, the card being in the grid. The question mark stands in the middle of its rings by
the mark itself, not by the line of type it is set in.

**The press proof.** The House prints its cards, and the catalog is the profile's proof sheet of
them. The pane is a charcoal cutting mat, a ruler's marks along its top and its grid printed faint
over it. Each page's cards lie on a sheet of the House's card stock, the other page's sheet just under
it, showing over its top and past its right edge; the tabs are the sheets' own, the page showing in
front and joined to its sheet, the other the darker one under it, the first standing on the sheet's
left edge, and the one under the cursor ruled round in gold inside its edge, as a slip's box turns. The sheet's margins carry the printer's marks: crop marks at the cards' edges, which move
with the rows as they scroll, registration targets, and a color bar of the cards' inks and the
press's along its head; in its foot the job's line, Joker deck · Sheet 1 of 2 · 22 of 35 printed, and
the story's motto, STORY.md 6.6a. A card taken is printed; one never taken is only the line the die
would cut it along, dashed in magenta, with a faint question mark. The first card of a page found,
the first joker the profile ever took or the first power-up it used, is ringed in the pressman's red
grease pencil, 1st! beside it, on its left where it ends its row, all of it within the room round the
card so the grid's edge never cuts it off. So is the card taken or used the most, twice at least,
Fave!, and the joker that went off by itself the most, MVP!, each in a pencil of its own, red for
the first, blue for the most taken and green for the busiest: a loop round the card for each reason
it has, started somewhere else round and a little further out, and its word beside it in the same
pencil, a line each, the first found of those level winning a tie. The large picture lies under a
loupe, its turned wooden handle up to the right, and a joker's suit as a little playing card slid
under the bezel at its lower left, 7.3. Where the column has no room for the large picture, a
phone's short screen, it is left out and the pane stands at the column's top, and the suit stands
before the card's name instead. The pane describing the card is a spec sheet printed on the same stock in
ink, every color in it the darker one that reads on paper, held by a bulldog clip; the switch and the
stack's field are pills of the paper. At the foot of the column, over Back, where there is room
under them, lies the printer's job ticket, staying put as the pane over it changes, typed: on the jokers' page the pay table of the hands, 7.3, a line for each with its cards,
its name and in short what it pays; on the power-ups' page whose job it is and the license's
number, the stock, the inks, how many were printed, and the pressman's OK. Where the column has no
room for it, as on a screen of 1080 lines, it lies in the foot left of Back instead, over the
sheet's foot a little, the rule, the fan and the tin left of it; where the foot is too short for
it as well, a small screen's, it is left out rather than anything scrolling.

A third page, Hands, has the pay table of the hands printed on its sheet, 7.3: under WHAT THE HOUSE
PAYS and how the hands pay, a row for every hand, the best first, its cards fanned, its name, what
it is, what it pays and how often the profile has made it, "Made 12 times" or "Not made yet". It
has no column, there being no card to describe, and is one picture kept for the run, 10.7. Back is a slip of the stock, its crop marks out off its corners.
In the foot left of Back lie a steel rule, a fan of ink swatches spilling off the mat's edge, and an
open tin of the House's gold with its lid beside it, the tin left out short of room and the rest with
it. On a wide screen the room the foot has over what they need spreads them out along it toward
Back, rather than all at its left end. Short of room the mat runs past the screen's edges and has no foot, so nothing lies in it, and
the sheet's margins are narrower, without the color bar or the target at its head; where the job's
line and the motto do not both fit in its foot, the motto is said alone.

**Jokers.** Every joker in the game, ordered by rarity, common first, then by kind, stat, rule and
cursed, then by name, so a card keeps its place as more are found. A card taken is drawn as the hand
draws it, 8.3; one never taken is not printed yet, only its die line and a faint question mark,
saying neither its name, its kind nor how rare it is. The card under the cursor wears the cursor's frame of
8.1a, the gold edge a button wears, a little way out round it, the glide sliding it from card to card
as from button to button; the cards stay still, since a card lifting and growing out of a hand is
the hand's, and a page of them doing it was restless. A key or a pad held along a row stops at the
row's end, the last card's too, rather than going on to the tabs over the cards or the pane beside
them. On a touch screen a swipe scrolls the cards,
carrying on a little once let go, and only a tap picks the card under it: the first touch of a swipe
picked the card it landed on, and every card a swipe passed over after it. The pane is the pane of
8.3, the one a match describes a card in, printed on paper: its name, how
rare and what kind, what it does, and from the story's second stage the term it is under that, 8.7.
A switch and a field stand under the pane, as they were left for the rest of a run. Detailed, off to
start with, which the view key also flips, Tab or a pad's Y, has the pane say
what the hand says only while that key is held, Stacks up to ×3 for a joker that stacks, and one
copy's numbers in brackets beside a stack's, and is where more of the kind would go. Stack, a field
drawn as the switch is, its lane a little longer with a chip at either end, minus and plus, and the
stack shown between them in gold, the two lined up one over the other with their words before them,
shows the card as a stack of that many, ×2 beside its name and the numbers the stack changed in gold,
as far as the joker stacks, whether or not the profile ever held so many: a bigger stack is
something to read about before it is held. It starts at every joker's whole stack, each read as
the most it stacks to until the field is stepped down. After the field, and at the pane's foot after how often
it was taken, it says the biggest stack of it the profile ever held, Held up to ×2, or Does not
stack; the option key, F or a pad's X, steps it on, round to one again past the most. The switch and
the field's halves are the mouse's and a finger's; keys and a pad have their buttons.
Under them a row of little cards of the House's paper picks the suit the jokers' page shows, 7.3:
All, the four suits and the wild cards' jester's hat, the one shown full and edged in gold, the
cursor going to the first card left where its own went; R or a pad's right trigger steps it on.
While one suit is shown, a stamp in the House's red across the sheet's head says so and how many
of the deck it shows, "♣ CLUBS ONLY · 12 OF 47", easier to see than the chip pressed in.
Beside Detailed, By suit lays the cards out by suit, Spades to Clubs and then the wild cards, each
suit in the catalog's own order; T or the left trigger flips it. Both are kept for the run as the
switch is, and the row is drawn as one picture, kept for the run, 10.7. Its foot says
how many times it was taken, Taken 14 times, and on a line under it, for a joker that goes off by
itself and has, how many times in its own words, Collected 12 tolls or Picked 5 pockets; one that
does it too often for its card to go off every time, Cushion Shot's bounces or Burnout's drifts, is
counted all the same, its card left still. A card not taken says only
Not found yet, and under it that taking one in a match is the way to read it; one the profile's
loyalty program has yet to add to its deck says that as well, and which bet adds it, 8.9. A card found since the
catalog last showed it wears a gold NEW tag on its corner until the cursor has been on it, kept as
the dialog is put away, and its page's tab wears one too while any card on it does, so a new card on
the other page is seen without turning to it. Next new, above, stands at the right of the head, the
title kept over the middle by as much room at its left, and before Back on a short screen; it goes
from card to card wearing the tag, the jokers' in the order they are laid out and then the
power-ups', from the hands' page from the start, showing every suit where the one shown leaves the
card out. A debug build fills the catalog of the profile playing with
`++ --catalog-all`, every stack held at its biggest, as the README says.

**Power-ups.** The same for the items, each a card of its own the size of a joker's, its picture of
8.3a framed in its color and its name under it, a color too dark to be told from the card lightened,
the first set and then the later set as the sets list them; one never used is not printed yet, as a
joker is. Its pane says what the item does in a sentence, then the numbers no match shows: how long it lasts,
how many shots, how far it reaches, its fuse, and which set it is in, the later one switched on in
the lobby, in the lobby's words, Basic items or All items only, each read from the item itself,
7.1, and at its foot how many times it was used, Used 6 times; one not used says that using one is
the way to read it. The House prints no terms on an item.

**The story.** The jokers' terms are the story's, 8.7, from the second stage, and from then a line
under the screen's title says whose record it is, STORY.md 6.6a. Nothing else moves with it: the
catalog is a record, not a way to progress, and unlocks nothing, STORY.md 10.

### 8.9 The loyalty program

The house runs a loyalty program, as every casino does: it keeps a record of what a player does at
its tables and pays them back for it, so they come back. It is the game's progression and its
reason to come back for one more map: a road map of bets, each a thing to do at the tables, every
bet won paying a reward and opening the roads out of it. Most rewards are dress for the kart, 4.4;
the rest are cards and items the house adds to the deck it deals at the player's own table. None of
it makes a kart faster, tougher or better armed, and nobody at a table is dealt anything that
somebody else at it could not be. The story reads the program as what it is, STORY.md 6.6b, and the
house renames it at each stage, Loyalty Program to start with, on its button and over its map. This
section calls it the program.

**Each profile's own.** The program is kept in the profile beside its statistics and its catalog,
8.5, and counts as they do: the first seat's play into the profile playing, a seat another profile
sits in, 3.8, into that one, and a guest's, a bot's and a watcher's into nothing; in every room a
statistic counts in, every map of a quick match or a Grand Prix, the lobby and the driving school,
and never in the Garage or a headless run. Online each machine counts its own seats out of what it
hears anyway, the snapshot's statistics and the host's word of what a seat took, so nothing of it
goes over the wire, and every player at a table moves on through their own program whoever hosts it:
the host's program says what the table is dealt, below, and nothing about anybody's progress.
Everything counts all along, from a profile's first map, and a bet is won the moment it is both open
and met, so a count already reached when its road is won settles there and then. A profile from
before the program has what its statistics already hold counted for it; the bets of one map it
starts from nothing.

**When it comes.** Not at once, so that a new player has one thing less to take in and a reason to
play a second map. The first time the title comes up after the profile playing has played a map to
its whistle, a quick match's or a map of a Grand Prix, at this screen or online, the house's welcome
is on the table, with the ceremony its invitation had, STORY.md 6.1a: the table dark a moment, then
the house's letter sliding in from below, on its cream letterhead with a card glued to it, and two
spotlights flickering on and settling on the card. The card is the program's: black plastic edged in
gold, the program's name in foil, the profile's name embossed and its member number, the number on
the stub of its invitation, or one like it for a profile that never had one, kept in the profile. It
turns a little toward the mouse, the stick or the phone as the invitation does, and the light catches
its foil. One button under it near the foot of the screen, Activate card, the letter clear of it
however it tilts, and no other way on: the cursor goes nowhere else and Back does nothing. Activated, the card is peeled up off the letter from a corner and comes away,
turning over once on its way to show a magnetic stripe and a signature strip with the player's name
on it; the letter drops off the table; and the map unfolds behind the card, which goes to its place
at the foot of the column beside the map, the map opened unseen while the card was held still,
turned over, so it is drawn and its pictures made before the card goes to it, rather than as it
goes, or, on a short screen where the map leaves its card out, drops off the table
as the letter did, the cursor at the slip road and the first bets open, the first map already
counted in them. Then the House shows its new member round the map, see The first look, below.
The card stays there, at the column's foot under the pane, every time the map is
opened, and gives its room to the pane on a short screen, or under a pane too tall to leave it
any. Its face carries the House's chip as its emblem beside the
number. Put away, the map leaves the title as it was, but for Loyalty Program under Clubhouse,
3.8. A press before the button brings it all at once. Like the invitation it is put up under the
warm-up's pane and drawn once there, and is never shown in a run nobody watches. It comes whether the
story is on or off, the program being the house's and not the story's; with the story off its words
are the first stage's. A profile from before the program is welcomed the first time it comes to the
title with a map played; when the invitation is due as well, the invitation comes first and the
welcome the next time the title comes up. Until it comes nothing says there is a program: no stamp in
a match, no page on the slip and no button.

**The first look.** A map shown out of nowhere says nothing by itself: play-testers drove the cursor
about it and could not tell what it was for, and a pane of words over it did not help them. So the
first time the welcome opens it, the House shows its new member round, in four steps on the map
itself rather than on a picture of it. The welcome's two spotlights come on again over the map,
the rest of the dialog going dark under them, and light what each step speaks of, a soft pool of
light round each thing: beside it a tag of the
House's cream card, perforated along its top as the map's tickets are, a red chip on it counting
the step, 1/4, a heading in the House's capitals and one line, and a thin red line run from it to
what it speaks of, a dot at its end. Each step's movement takes under a second, and a press during
it brings it all at once. A screen reader reads each tag as it comes. The words are the screen's
own, a bet, what it pays, won, a pin, and the House's plain ones, the same with the story on or
off but for the program's name; Kit has nothing to say in it.

1. **You are here.** The slip road lit. Its stamp comes down on it, WON, and the roads it opened
   draw themselves out from it in gold to the bets past it, whose signs come up off the House's
   plans as the gold reaches them, a bet already won by the first map stamped in its turn: "You
   activated your Loyalty Program card, which won the first landmark's bet. Winning a bet opens
   the roads past it to new landmarks.", the program named as the card names it.
2. **Every match counts.** The kart drives to the nearest open bet, the one the first map came
   furthest with, and red chips name the slip's parts beside it: WHAT TO DO by its bet, SO FAR by
   its bar and count, WHAT IT PAYS by its rewards: "Each landmark holds a bet and a reward. Every
   match you play counts toward all open bets at once, so there's no need to pick one."
3. **Pin one to track it.** The slip's Pin lit, and beside the tag a picture of what a pin gives,
   drawn as the thing itself, that bet's name and count along its little road: the strip by a
   match's clock, "Pin a bet to see how far along it is, beside the clock, while you play."; or
   on a screen with no room for the strip, a phone's, the pause menu's note, "Pin a bet to see how
   far along it is in the pause menu while you play." Two buttons, Pin it, the cursor on it,
   which pins the bet as the slip's Pin does, accept being the slip's Pin key on the map, and Not
   now, which pins nothing; a click on the slip's own Pin does as Pin it does.
4. **The Jackpot.** The map drawn back until all of it shows, the light on the JACKPOT at its top
   and on the slip road at its foot: "Every road leads here. Win bets to open more roads and reach
   the Jackpot." One button, Got it, which ends the tour and leaves the map up, the member's to
   look round, drawn back in to the bet the cursor is at.

Accept, a click or a tap anywhere but on a button goes on to the next step, all but step 3, which
waits for one of its two. Skip tour, at the left of every tag, or Back, B or Escape, ends it at once
at any step, the map left as the steps would have left it, its bets won stamped and their roads
gold, the cursor where it stood. On a pad or keys the cursor is on the tag's buttons, left and
right between them, and the binds of Skip tour are drawn on it; a touch screen draws no binds.
Nothing of the map takes input while it is up, and on a narrow screen that would open on the list
the map shows for it. Ended either way, it is kept in the profile and never comes by itself again;
How it works, in the head, shows it again whenever it is asked for, below. A profile welcomed
before the first look came, that has won nothing past the slip road, is shown it once, the next
time it opens the map.

**Where it opens.** Loyalty Program, the first of the Clubhouse's buttons on the title, 3.8, and of
the Clubhouse on the pause menu of any room; and the program's page of the payout slip, below. It is a large dialog over the screen, on
a layer of its own as the catalog of 8.8 is, with its shade and its pane, and Back, B, Escape or a
click on the shade beside the pane puts it away, the cursor back where it was. The map opens with
its cursor at the landmark it was asked for, from the pause menu's note or the slip; or at the
roundabout while an edition is owed; or at the last of the bets it shows being won, below; or at
what is pinned; or where the cursor was left on it; or at the nearest open bet, never at the slip
road won long ago.

**How it works.** A ticket of the cream card at the head's right end, after the List switch and
Next new, How it works in the head's own size of words, narrow enough round them that the
House's pencil keeps its room in the head: it shows the first look again from its first step, the
map as it is, the slip road's stamp coming down again and its roads drawn out again for the
showing. Its bind, H or a pad's left stick pressed in, is hung on its foot while keys or a pad
are in hand, as the slip's Pin has its own. Where the head has no room for its words, a phone's
at a big UI scale, it is a question mark alone.

**The atlas.** The dialog is the House's road atlas, opened. Its pane is the atlas's cover: navy
book cloth over a board, its weave fine and worn lighter and darker in patches, a survey's contours
etched faint over it in gold round a few hills; the House's rules stamped round it in gold, a heavy
one and a fine one inside it with its corners turned in, broken in their foot for the atlas's name,
ROAD ATLAS · MEMBERS' EDITION to start with, which the House changes as the story goes on, STORY.md
6.6b; a brass cap on each corner with a rivet in it; and a red ribbon and a gold one out from under
its foot. The map is taped down to it at three corners, the fourth under the sheets' tabs; the card
lies at the foot of the column beside the map, held at its corners in four photo corners of gray
card glued to the cloth, as an album holds a picture, so that they read as what holds it, in a
pocket pressed into the cloth that shows dark when the card is taken out of it, as the letter's
darker spot does once the card is torn off; Back is at the foot of that column, under the card,
with a pair of dividers lying left of it where there is room, so the map runs on down to just over
the cover's rules, the tape at its foot inside the cover's edge. A pencil of the House's, black
with its name in gold, lies tilted in the room right of the map's tabs, short of the map's right
edge, or with no tabs, the story off, in the head past the line beside the title, where there is
room. The details beside the map are a slip of the House's cream paper lying flat on the
cloth, only a little shadow under it, bound along its top by a wire coil through holes punched in
it, as a pad's page is, the wire over its top edge; its foot torn, a gold hairline inside its edge
under the coil's holes, its name and its district's word over a dotted line, the rest in ink under
it, and a bar filling in gold for how far a bet has come; its Pin is a stub of the paper as Back
is, and its Choose an edition the ink ticket. A landmark not open yet, and the roundabout while it
is shut, is still on the House's plans, STORY.md 6.6b: its page is blueprint paper, a grid on it and
its words and lines in white, a roadworks barrier of yellow and black stripes along its foot, and
CONCEPT stamped across it in white, a little askew and worn; a keystone's is sealed besides, a
seal of red wax with a star in it over its foot's right corner; its back is blueprint too, its
grid on it. Kit's sheet, off the books, is not the House's, and nothing on it is on the House's
plans: open or not, a scrap of his graph paper is torn off and taped over the slip, what the slip
says written on it in his hand in pencil, a rule drawn twice over in the dotted line's place, how
far a bet has come a box he sketched in pencil, hatched as far as it has come; for
one not open yet he has crossed its hidden objective out, written "later" beside it, gone round
it with a loop and drawn an arrow from it to the objective. As
another landmark is chosen, the page saying the
last one turns up over the coil, as a pad's does, the next page under it saying the new one, to
the soft sound of a leaf turning: lifted by its foot's right corner, it bends round a roll along a
slanting fold that sweeps up the page, its face curving away round the roll and its back
coming round and lying over what is left of its face, what is printed on its face showing faintly
through it the wrong way round, as through paper, the roll's shadow on the page under it,
until it has all gone over the coil, fading out softly as it comes up to it, half a second. It is as big as the bigger of the two pages,
as a pad's pages are all of a size, and may fold out past the slip's side as it goes. Back, the
sheets' tabs and the List switch are paper laid on the cloth: Back a stub of the cream card the
map's tickets are, a bite out of either end, a little short of a menu's button but where a finger
presses it, about level with the map's foot, its hairline turning gold under the cursor as the paper lifts a little further off the
cloth; the tabs index tabs of the paper, the one showing joined to the map's top edge and the
others a shade darker behind it; and the switch a pill of the paper, its knob a ring of faint ink
off and the stamp's red on. On a short screen, where the pane fills it, the cover runs a little past
the screen's edges, its brass caps in the screen's corners; nothing hangs out from under it and,
with no foot, nothing lies in it but a pencil under the details, at the column's bottom right,
wherever there is room for one; its name is under the map's middle, and the map is taped at its
right corners only. The cover and everything lying on it are drawn once into a picture, and the
tape, a photo corner, the pencil and the slip's coil once each; the page turning is a picture of
its own only while it turns, 10.7.

**The map.** The pane holds a road map the house printed, on its cream paper, 8.1a, with the creases
of a map that has been folded, in a well sunk into the pane that it runs right to the edge of, cut to
the well's notched corners, a shade all round its inside, deepest along its top, and its rim over
it; and larger than the well: it scrolls to keep the cursor in view, a wheel or a pinch zooms it
between the whole map, a little of the well round it, and close enough to read every sign, and a
mouse or a finger drags it, as far as a little past its edge. Every profile starts at the foot, where the slip road comes onto the map just
under the districts, and the roads run up from there through the districts to the roundabout over
them, on its island, round a pot marked JACKPOT. The house's roads are printed in its ink, and each bet is a landmark beside them, a sign the
shape of its district's with a picture of its own on it, what the place is: a teller's cage, a
cocktail glass, a target, a pencil, no two alike.

- **The Strip**, the left of the map, is the house's own: bets of the tables, chips, cash-outs, cards
  and wins, and the casino's rewards, the cards and items of the deck among them. Its signs are the
  house's marquees, lit in gold, and its streets two ways up: one round its left and over its top,
  the other winding up its middle, with crossings between them.
- **The Department**, the right, is the Department of Karts': bets of driving, and its Lost Property
  office, below. Four of its bets are endorsements as well, Drift, Clean Record, Marksman and, its
  keystone, Advanced: each is stamped on the back of the profile's license once won, 9.4a, a small
  rubber stamp in the driving test's red in a row under the magnetic stripe, laid a little askew as
  the PASSED mark is. The rest pay only what they pay, so the license, which carries the exam's
  endorsements on its front already, does not fill up. Its signs are road signs, on a ring road
  round its right, its Lost Property offices up its left.
- **Off the books** is not the house's at all: Kit's own map, a sheet of graph paper torn off a pad,
  its roads and landmarks in pencil, with the story on and once its first note is found, STORY.md
  6.6b. His first landmark, open as soon as his sheet is, has a road in off the sheet's left edge,
  an arrow pointing in and "the back way in" by it, as the slip road comes onto the house's. Index
  tabs on the map's top edge, in from its cut corner, The House's map and Kit's map, as the
  settings' are on theirs, turn from one sheet to the other, as do the page keys, Q to the House's
  and E to Kit's, or a pad's shoulders, drawn at the tabs' end; and each tab wears the NEW tag of
  8.8 over its corner while a landmark on its sheet does, as the catalog's tabs do for their pages;
  Kit's two roads that run on into the house's districts go off the foot of his sheet to an arrow
  and "to the Ten Times Bar", and in his pencil up off the top of the house's to "to Kit's map", and
  driving along one turns to the other sheet, the kart driving in over its edge along the same road
  and on to the landmark rather than set down there. With the story off it is not drawn, and there
  is no tab.

A landmark is **closed** until a road into it is won: printed pale, its roads faint, showing what it
pays but not what it asks, so a player sees what is ahead and not yet how to get there. **Open**, it
is printed in full, its bet on a ticket under its sign and a little road filling in gold as the count
goes, 312 / 500 km. **Won**, it is marked so it shows on its own colors, with a seal of gold foil and
red ribbons on the Strip, the red stamp in the Department and Kit's tick and a loop round it in
pencil off the books, its picture lit and the roads out of it printed solid. A landmark opens once any one road
into it is won, and most have two or three, so there is no one way through and a bet a player cannot
or will not win can be gone round: the slip road leads to one landmark of each district, and past
it, whichever one bet of the House's a player cannot win, a road still runs to each keystone round it. A **keystone**, one a district, the last landmark on its road to
the roundabout, opens only once every road into it is won, and then asks its own bet; the Strip's and
the Department's open the roundabout. Off the books has a keystone too, and it leads nowhere. The
Department's run of maps won is ended by a map lost or walked out of with its clock going; a room won
in again starts it over from there, and a map won in a room not one of the three neither adds to it
nor ends it.

**How it is printed.** A road map rather than the grid it is drawn from, so it does not read as a
system. The blocks between the roads are not all of a size; each district stands a little turned, its
rows of landmarks curving as streets do; each landmark stands a little off its place and each bend a
little off its own, the same way every time, and wherever a sign and the ticket under it would come
near another's they are moved apart. A road runs from one landmark to the next through its bends,
wandering a little on a long stretch and rounded at its corners. The house's roads are printed as a
road atlas prints them, a casing, a lane and a dashed line down the middle, gold once a road is open
and gray before, where two meet the lane running on through; Kit's are two pencil lines either side
of the way, sketched by hand, dashed and faint until they are open. Each district is a wash of its
own color that follows its landmarks and its roads, bays and all, its edge drawn by hand, the
Strip's gold and dotted, the Department's blue and dashed, Kit's a gray in pencil, the house's two
with faint side streets across them, a dead end here and a crossing there, and each has its name
lettered over it, spaced out, Kit's in Kit's hand. The empty paper has the little drawings a road map
has, in groups as a country has them: woods of round trees and pines on a tint of green, farms of
fields side by side with a barn, rows of hills, villages; a block of casinos, a row of palms, chips
and dice on the Strip; cones in a row, a depot, a grove in the Department; and Kit's doodles off the
books. The House's districts are built up between their side streets wherever there is room round
their signs, the Strip's buildings warm and the Department's gray, and each has a sight of its own,
the Strip a fountain on its plaza and the Department a test track. Where there is room round the
roundabout it stands on an island, its roads in over bridges. A river runs out of the island's
water down the valley between the districts, through a lake in the middle of the map with a boat
on it, and on under the slip road's bridge, or where there is no such valley across the sheet where it has most
room; it never runs through a landmark, wanders, widens on its way and has a lake of its own, reeds
by its lakes. The biggest places are named as a map names them, in a slanted hand, The River, Bluff
Lake, Lucky Pines and Full House Farm among them. The roundabout's island is a burst of gold round the pot printed as a chip marked JACKPOT; the
legend is in the foot's left corner with the compass beside it, and the house's title block in its
right, the program's name, ROAD MAP · NOT TO SCALE, and Printed by the House for its members. The
paper is grained, folded in three across and two down with a shade either side of each crease, worn
pale where two cross, and darker toward its edges; Kit's sheet has the ring his coffee left on it.

A Strip sign is a marquee, a dark board in a gold frame with a row of bulbs along its top and its
foot, lit once won and throwing a glow on the paper round it, and chasing round it, every third bulb
bright, while the cursor is at it and it is not closed; a Department sign a road sign, white
on its blue; the slip road's a motorway sign in green; and off the books a box drawn twice over by
hand, its name in Kit's hand. Each is as wide as its name, its own picture at its left, a keystone's
with a star over it, as pale as the sign while it is closed, and an open one has its bet on a ticket hung from under it, a little narrower
than the sign: the House's a stub of cream card edged in its district's color and notched at its
foot, its count under a perforation along a little road filling in gold as the pinned bet's does,
Kit's a scrap torn along its foot, shaded in pencil. Won, it is marked off its top right corner, on
the Strip a seal of gold foil, its edge cut in points, with two red ribbons under it, in the
Department the red stamp, a closed ring round the word with a fainter one inside it, a little
askew, and off the books Kit's big tick, gone over twice, and a loop round the sign; the NEW tag
hangs over its top left. The lines are drawn at the zoom and the words printed at its own size, so
both are sharp at every zoom. All of it is drawn once into a picture of the sheet at the zoom the map
rests at, and again a moment after the zoom has come to rest elsewhere; only the kart, the landmark
it is at, the NEW tags and the pins are drawn over it as it moves, so the map scrolls and the kart
drives at the screen's own rate. Where everything goes is worked out once a run for each way the map
can be drawn. Every landmark has a name, the Strip's the house's rooms, the Department's its offices
and roads, Kit's in Kit's own words, in the table under The first map.

**The cursor** is a toy kart in the player's color and dress, cut out of paper, flat colors with a
paper border and an ink edge and its shadow on the map, standing at the landmark it is on, whose
sign is lifted off the paper on a soft shadow and marked as a button is, the buttons' gold edge and
its two chevrons, cased in ink so they show on the Strip's gold signs as on the paper. A push of
the stick, the arrows or the cross chooses the next landmark along the road that way, or where no
road goes that way the nearest landmark that way all the same, nowhere only past the map's edge or
where the nearest is far more to one side than that way; and a click or a tap one anywhere, the
mouse a pointing hand over anything a click chooses; the pane says it at once, and the kart drives
there along the fewest roads in the background, unhurried, giving up where it was going if another
is chosen and driving there from where it is, turning back if that is shorter, however often it is
turned, the map moving only to bring what was chosen into view. Over the map, while keys or a pad are in hand, their binds say how: Select landmark, Zoom and
List. It stands before a sign on the road it came
in by, and the map opens where it stood last. The landmark chosen is
described on the slip at the right of the map, over the card: its name and
district, the bet and how far it has come, what it pays, with its picture, its part of the dress or
the cards it adds, and for a closed one "Objective hidden until unlocked" in its bet's place and which roads
would open it, never a keystone, which opens only once that one is won. A switch over the pane, List, which
the view key also flips as in the catalog, Tab or a pad's Y, puts every open bet in a list in the map's place,
nearest done first, for a player who only wants to know what is next; the list reads the same however
the map is drawn, and is what a phone at a big UI scale opens on; a row pressed is the map with the
cursor at it. Minus and plus zoom as the wheel does, a notch a press; a pad's triggers zoom for as
long as they are held, faster the further they are pulled, the right in and the left out, about the
landmark the cursor is at, rather than a notch a pull; and its right stick moves the map about as a
drag does. A landmark won since the
program last showed it wears the gold NEW tag of 8.8 until the cursor has been on it, its sheet's tab
wearing one too, and while there is one, Clubhouse and Loyalty Program on the title wear it too.
Next new of 8.8, a ticket at the head's right after the List switch, takes the kart to the next
landmark drawn that wears it after the one the pane says, in the map's own order, the House's
sheet's and then Kit's, the order the list puts two bets as near done in: in a dash along the
roads, half a second at the most however far, from wherever it is, a drive under way given up, the
map following it; or, on the other sheet, set down there with the map turned to it; and once it is
there, it lands on the sign as Next new lands everywhere, the sign coming up and its rings going
out. The pane says the landmark
at once, so a press never waits on the kart. The list is put away for the map, which is where the
landmarks won are. Once the roundabout is open it stands at
the foot of the list for good, the furthest off, its lap and its ring's bets, there being always
another lap.

**Bets won, shown.** The map opened shows its bets won since it last showed them being won, as the
first look shows the slip road's: the cursor at the first of them in the order they were won, the
map coming round to it, its stamp coming down and its roads drawing out in gold to the bets they
open, whose signs come up off the plans, and then the next, a moment between; each is shown as the
cursor comes to it, so its NEW tag goes. Each is shown a quarter quicker than the one before, and
three at the most so: any more are shown all together in one last beat after the third, their
stamps coming down and their roads drawing out at once wherever they are, the map not coming
round to them, so twenty won while the map was away take no longer than four; those are seen
too, their NEW tags gone. A press, a click or a tap brings the rest at once, the cursor at the
last shown on its own, and Back puts the map away as ever, everything shown. Those of the
sheet the map opens on are shown, and those of the other sheet as it is turned to. Not on the
list, and not where the program was opened at a landmark asked for, the pause menu's note or the
slip's: there they keep their NEW tags until the cursor comes to them.

The head is one row the width of the screen at every size and UI scale, and never wider: the title
with its line beside it, in the middle of the row as the switch is, Next new while there is
something new, and the switch with its bind at the right. Where there is not room for all of it,
the line goes first, and then the binds of Select landmark and Zoom. The pane's column keeps only a little room either side of it, so the map
has the rest. On a short screen, a phone's, the dialog fills the screen as the catalog's does, the
pane half as far from the map, Back is at the head's right and the card leaves the corner to the pane; on a
narrow one the side column is narrower, a third of the width, the map having the rest; the card and
the pane scroll where they say more than the screen is tall; and a touch screen draws no binds of
keys or pads.

**Pinned.** One bet at a time may be pinned, from its pane's Pin button, a red map pin on it, or
accept, an open landmark
or the open roundabout, to keep it in sight: a red map pin on its sign, first in the list; under the
pause menu's pane, apart from it, a scrap torn off the map's paper and pinned there, its name, its
bet and how far it has come along a little road filling in gold, beside the pane where there is no
room under it, and a click or a tap on it opens the program on the map at what is pinned, and so
does accept on it, a pad's cursor going down to it from the menu's last button, or the Clubhouse's while it is up; and, on a
screen wide enough with one player at it, a slim scrap of the same paper by the match's clock with
the pin, its name, its count counted live and the little road: beside the clock, past Kit's scrap,
hung from the screen's top as the clock is and torn along its foot, where the screen is wide enough
for it to keep off the arena, and otherwise under it, under the Royal Flush's tally while that is
up, though never under it on a touch screen, where it would cover what little arena a phone has
and the pause menu's note says it anyway, and not at all while the payout slip is up; a click on
it pauses the match as Escape does and opens the program over the menu at what is
pinned, the menu left up when it is put away. Met in the map, the strip and the note count it in
green with a tick before the count, until the map is written down and it is won; won, it is
unpinned.

**The card.** The program's card lies at the foot of the column, under the slip. Where the slip leaves
it no room, as the roundabout's does with its ring dealt, the card is left out, its photo corners
and its bind with it, rather than the column scrolling it down out of sight; the column scrolls
where the slip alone says more than the screen is tall, as it does on a phone, with room kept for
its scroll bar either way, so the map beside it never changes size and stays on the landmark
chosen. It never takes the cursor, which stays on
the map; a click, a tap or its own bind, the option key, F or a pad's X, drawn on its bottom right corner,
over the photo corner there, while keys or a pad are in hand, holds it up in full as the license is in 9.4a, turning toward the mouse, the stick or the phone, its gold and its chip catching
the light, with the license's two buttons under it, turn it over, Enter or a pad's A, and put it
away; turned over, it
turns face up again on its way back down. It is kept beside the license on the License tab of the
settings too, 8.5, as tall as the license, between it and Kit's folder, or under them on a screen
too narrow for all three, and held up in full from there the same way.

**Settling.** A bet won in a map is won there and then: a small slip stamped BET WON in the player's
corner for two seconds with the reward's picture, its name and what it says as it is paid, a second
one standing beside the first, the way NOTE COLLECTED goes to the corner, 8.7, but
printed by the house, and nothing pausing. After the map the payout slip of 3.8 has one more page,
after the map's and the run's, headed with the program's name: each profile at this machine that won
a bet or came nearer one, under its name, a line for each bet it won, stamped, with what the house
calls paying it and under its name what it paid, each piece by name as the program's pane says it,
Hat: Dealer's visor, rather than only that a reward was issued, and
the open bets it came nearest to, with their bars, three at most, each with a pin at its end to pin
it from the slip as from the program, faint until it is the one pinned; on a pad the cursor goes to
the pins in view right from the page's arrows or up from the ways on, marked as a button is, up and
down between them and on past their ends, and accept pins. A count is known as the map's
own statistics take it past the bet, though it is written down with the map; a bet of a whole map,
won or played, is known as the map is written down and is on the page alone. Online it is this machine's profiles only. A map
with nothing in it for anybody has no page. A bet off the books is not the house's business, and the
house prints nothing of it, STORY.md 6.6b: won in a match, it is a tick in pencil in the player's
corner, no stamp and no words; and on the slip it is a scrap of paper torn off something else and
taped on over the slip's paper, the program's page or, with none, the map's, with the bets won off the
books written on it in pencil, as if somebody had added it after the slip was printed. It is taped a
little askew, over the corner of whatever it lands on, the tape catching the light, and scrolls with
the bill.

**What it pays.** Two kinds of thing, kept apart so that nothing it pays is an advantage at a table:

- **Dress** is the seat's, new in the kart dialog until it has shown it there, 4.4a. What a seat
  may wear is what its profile has won, and a guest's seat what the profile playing has. It rides
  the wire as dress always has, 4.4, so a kart is dressed the same on every screen, and a machine
  that has never heard of a choice draws the plain one.
- **The deck and the items** are the table's. What the table deals, to every seat, every bot and
  every pad alike, is what the program of the profile playing has added, or online the host's. A newer
  host deals everybody a smaller deck, and nobody at the table holds a card that somebody else at it
  could not have been dealt. A dedicated server's game, 9.3a, which has no profile of its own, deals
  from the program of whoever has the host's say there: the game's maker to start with, and whoever
  the say goes to after them. Each client tells the host what its profile playing's program has
  added, the names of the cards and items, as it comes in and again after every map it writes down,
  and the server keeps each one's, so that when the say moves the deck moves with it, with no asking.
  It is taken as each map starts, so a map is dealt from one deck throughout, and a change of say
  counts from the next map. A name the server does not know is left out. Nothing else of it goes over
  the wire: a host deals the picks and rolls the pads as it always has, 10.3, and a machine hosting a
  game deals its own profile playing's deck. The message is new, so a version with it does not play
  with one before it.

Nothing the program pays changes a kart's numbers, and none of it is a lobby rule yet: rules for a
whole table, every kart starting at ×3 mult and the like, may join the Strip later, each a choice the
host makes for everybody.

**The deck.** Twenty-seven of the jokers of 7.3 are in every deck from the start, the ones with the
plainest small print, STORY.md 6.3: the nine commons, Hair Trigger, Big Tank, Magnet Hubcaps, Nitro
Habit, Slipstream, Green Light, Vulture, Odometer and Spare Tire, and eighteen uncommons, Tight Grip,
Getaway Driver, Pickpocket, Rubber Bumpers, Comeback, Loaded Dice, Tailslide, Guardian Angel, Jerry
Can, Curve Ball, Backfire, Double Tap, Cushion Shot, Second Wind, Daredevil, Burnout, Lucky Charm
and Pit Crew. The other twenty the Strip adds a few at a time, the rare first and the ones that
sound most like an economy last: Lucky Seven, Hot Streak, Aimbot and Snowball; Deep Pockets, Wild
Card, Carbon Copy, Copy Cat, Flush Draw and Echo; Snake Eyes, Road Rage, Scar Tissue and Royal Court; High Roller and Glass
Jackpot; Payday and Direct Debit; and Toll Booth and Insurance Policy. Offers are dealt by rarity among the cards the
deck holds, 3.7, so a deck with no rare in it deals none. Which deck a joker starts in is the joker's
own, in its data, and a landmark names the jokers it adds, so a joker added to the game later goes
into the starting deck or onto a landmark by a line, and the split can move as the deck grows. The
catalog of 8.8 counts every card, in the deck or not: one face down that the profile's program has not
added yet says so under Not found yet, and which bet adds it. The Garage's joker pad deals from the
profile playing's deck.

**The items.** The first set of 7.1 is in every game. The later set comes from the Strip, two at a
time: Spread Cannon and Swivel Cannon, then Decoy Kart and Bullet Wipe. The lobby's choice of items,
3.8, is there once the table has one of them, and All items is then the first set and whichever of
the later set the table has.

**Dress.** More of each of the four parts of 4.4, and three new kinds, the plain choice of each open
to everybody from the start:

| Part        | Won in the program                                                                 |
|-------------|------------------------------------------------------------------------------------|
| Paint       | Card suits, Racing stripes, Flames, Patchwork                                      |
| Hat         | Dealer's visor, Fedora, Shark fin, Ear defenders, Horns, Traffic cone, Hard hat, Welding goggles, Paper hat, Fez |
| Flag        | Ace of spades, Windsock, Tape measure, Fuzzy dice, Kit's rag, Magnet               |
| Trail       | Poker chips, Afterburn, Pencil                                                     |
| Plate       | Gold (plain: the cream one)                                                        |
| Tire marks  | Chalk, Dashed (plain: the marks of 4.3)                                            |
| Card back   | Gilt, Hand-drawn (plain: the house's)                                              |
| Won besides | Checks, Top hat, Checkered, Confetti, the four of 4.4 that were everybody's        |

- None of it may stand in for what says whose kart it is. The player's color stays the body's color
  under any paint, the roof marker stays on top over any hat, nothing makes a kart look bigger or
  smaller than it is or harder to see on the floor, and no trail hides a bullet. A dark paint, a
  camouflage and a trail as thick as smoke are off the list for that reason.
- **The gold plate** is the plate of 4.4 in gold, its rim and bolts a darker gold and its letters
  as black as ever, on the back of the kart, the podium and the Showroom alike. A thin gold rim
  round the cream plate was tried first and was hardly there.
- **The poker chips trail** throws chips made as the table's are, in the player's color with a
  lighter face and pale notches round the rim, lit as a thing is: tossed up and back, each turning
  over as it rises and falls with its face the way it flies, and coming down hard, heavy as a chip.
  Plain discs tumbling as confetti does were first, and read as confetti.
- **The paints** are tones of the color, never darker than the shade the old ones are made of, the
  shade dark enough to read. Each faces the camera as the side of the kart it is on does rather than
  as a blend of three sides, which on a curved part was the pattern three times over and blurred,
  and each is drawn at a size of its own, the racing stripes either side of the middle.
- **The card suits** are no pattern but three stickers on the plain color: a spade on the nose, a
  heart on the left and a diamond on the right, each the suit of the Royal Flush pads, 3.9, in its
  card's red or black on a cream disc with an ink rim, so it reads on every color. The sides' are
  on the slanted outside of the pod between the wheels, which looks out and up at the camera. A
  sticker is laid on the faces of the body it falls on, a hair out from them, so it bends over the
  nose's two slopes as a sticker would. Suits printed all over as a pattern were a blur however they
  were drawn: the kart's parts are small and curved, and a suit on them a few pixels round a corner.
- **Tire marks** change only the marks a kart leaves, 4.3: Chalk a paler mark, Dashed a mark broken
  into dashes like a lane line, and Kit's Pencil a mark scribbled in, a pencil going back and forth
  across it as it goes along in dark graphite, under the floor's own gray, with the paper's tooth
  showing through, the hand's
  rhythm and reach wandering, going over it a second time where the kart drifted and lifting off
  now and then. A gray ribbon broken now and then was first, and read as a dashed line rather than
  as anything drawn. As faint as the plain ones and fading as fast, never bright and never lit.
- **A card back** is this machine's alone and goes nowhere: the backs of the cards it draws wear the
  profile playing's, the program's closed landmarks that add cards,
  and the respawn pick's, which comes in face down and turns over inside the half second in which
  nothing can be taken anyway, 3.7. A back won is worn in every room too, by the cards lying face
  down on the floor and the decks stacked round the table, its rim broader and its lines stronger
  there so it reads from over the table (until one is won those keep the deck's red lattice); by
  the few cards drifting up the title among the chips, 8.1; by the hand fanned over the room's
  name on the loading screen, 8.6; and by a joker going out of the hand, which turns over quickly
  as it drops and shows its back the rest of the way, 8.3.
- Dress is put on at the stalls of 4.4 and in its kart dialog, 4.4a, which offer a seat only what
  its profile has won: seven stalls in the lobby, the paint, the hat, the flag and the trail and then
  the plate, the tire marks and the card back, and a hook for each in the dialog, whose rack shows
  the pieces not won yet empty, with where they are won, so a piece is worn as soon as it is won. The host steps every kart on a stall, as it always has, and a client tells it what it
  has won along with the cards it has added, so a client's kart steps through the client's own. The
  card back's stall is this machine's alone: it turns the backs of the cards this machine draws,
  and the host never hears of it. A bot wears only what everybody has.
- **What flies moves.** A flag streams back from the way its kart goes, swings round as the kart
  turns, flutters the faster the faster it goes and hangs when it stops; a windsock fills as it
  goes faster and droops when it stops, rising and falling with the wind it has caught over a
  third of a second or so rather than with the speed of the moment; the tape measure's tape runs
  out as the kart goes and winds back in to a third of it as it stops; dice hang back on their
  strings as the kart drives off and for as long as it picks up speed, swing forward as it
  brakes and out as it turns, well over, and swing back. The look alone, worked out on every
  screen from where the flag has been, which nothing in a match feels, and on the steps the
  karts move on: sampled every drawn frame, a frame between two steps saw no speed at all and
  the next twice as much, so the windsock jittered and the dice's throws cancelled out.
- **The Magnet** is a red horseshoe magnet with bare steel poles, hung from the top of the pole by
  its bend and swung as a flag is, turned on its bar so the camera over the table sees the U rather
  than its edge. While its kart pulls chips in, by a Chip Magnet of 7.1 or Magnet Hubcaps in its
  hand, 7.3, it grows to half as big again within a fraction of a second, beats and rocks, and
  three arcs of its field glow out between its poles, breathing; it eases back as the pull ends.
  Every screen works it out from what it already has of the kart, its reach and its hand, which
  the snapshot brings a client, so it grows on every screen at once; a decoy's grows with its
  owner's, as it wears what its owner wears. The look alone, which nothing in a match feels, and
  only a kart that flies it pays for it: its arcs are made the first time it pulls.
- **The hats** are cut to the helmet as the old ones are. The crown is a gold band round a red
  velvet cap, a gold ball on its rim at every eighth of the way round and a jewel at the front,
  nothing on it pointed; the paper hat a sheet of newspaper folded to a triangle across the head
  and opened round it, on its band; the welding goggles pushed up on the forehead, looking ahead;
  the horns a pair in the player's color, darker at their points, a thick root sunk into either
  side of the helmet where it curves away from the top, clear of the visor, and a tip curling up, big enough to read as horns from where the camera
  is. Bone-white spikes the size they were first read as two pins. The fez is a cone of red felt
  cut short with a flat top, a black button at the middle of its top and a black tassel on a cord
  laid over it, hanging down its side a little back, where it shows beside the felt from the front
  and from over the table. It stands still, as every hat does.

**Lost Property.** The Department keeps a landmark for each room somebody lost something in: the
driving school's traffic cone, the Workbench's tape measure, After Hours' fuzzy dice and the Yard's
hard hat. Once its landmark is open, the thing may lie on the floor of its room, in a spot of its own
on each map, at the usual size or XL: something lost rather than something put out, in a corner,
behind a wall, past a stack of crates, never on a pad or the Junction, and the bet says roughly where,
"Lost in the Yard, by the warehouse doors." It is there for the whole of a map played in its room on
an even chance, and for certain in one once it has missed two, the way a note turns up, STORY.md 7.1,
so it is something come across rather than a chore to fetch; and while it lies there, a manila tag on
a string hangs beside the clock, off the left of its board as the note's scrap hangs off the right, so
a player knows it is in this map, though not where. The tag is filled in by hand: FOUND, the room and the thing, and UNCLAIMED, with
the story's line under it from its second stage, STORY.md 6.6b; taken, it is stamped CLAIMED and
goes. Its spot on a map is worked out from the map rather than drawn in: bare floor clear of
everything a kart is sent to, as far from the Junction as the map has and up against walls and
crates, the same for the map every time. The thing lies as a thing dropped does, half as big again
as it is worn: the cone on its side, the hard hat upturned, the tape run out across the floor, the
dice on their string. The Yard's hard hat is the one off its hoarding: once the landmark is open it
has blown down, and the hook stays empty from then on. It lies on this machine's floor
only, as a note does: only this machine's karts take it, by driving over it, no bot goes for it and
nothing in the match moves it. Taken, it is the reward itself: the cone and the hard hat
are hats, the tape measure and the dice hang from the flag's pole. The story gives each a tag,
STORY.md 6.6b.

**The Showroom.** The Department's keystone opens a bay off the Garage of 9.4, behind a roller door in
its back wall that stays shut until then, SHOWROOM, MEMBERS ONLY over it. Open, the Garage has the
bay behind it, as wide as the Garage, through a way in where the door rolled up, a red carpet from
there to a turntable set into the floor under a lamp of its own. A kart driven onto it and left standing is carried
slowly round with it, round its middle wherever on it the kart stands and turned as far, as on any
turning disc, never spun where it stands, and a close look at it comes up in a frame at the side
of the screen: the bay itself, the kart on the table as it is, filmed by a camera of its own, since
the room's has to keep the whole Garage in its shot, and the room's camera keeps the karts out from
under the frame as it does the HUD's. It cuts as a car advert does, every six and a
half seconds, between eight shots in no set order and never the same twice running, each moving:
a low push in on a front corner first, a wide down the carpet craning down, a low track along its
side, closer at the table's edge, high over the table, round the front against the turn, up from
the floor, and from well back with the lens closing in; the hints hung over karts are left out of
it. The picture is a feed off a camera on the floor rather than a window onto the room: white
brackets in its corners, a red dot by REC blinking in one, the time the feed has run in another
and which camera it is off in a third, CAM 1 to CAM 8 for the shots; faint scanlines rolling down
it, a little grain, its corners darker and red and blue pulled a hair apart at its edges; and
every few seconds a light tear, a band of it knocked sideways and jittering for a moment, now and
then a strong one. It comes on in a burst of snow and a white flash, its focus hunting in and out
before it settles sharp, and a cut is a shorter burst and a tear. The picture is set in a dark
bezel with rounded corners, a monitor's, rather than butting the frame, and the frame slides in
from the side of the screen and back out. The picture is filmed at a camera's thirty frames a
second, whatever the screen runs at, which is half of what filming it every frame cost, 10.7.
What the kart wears is named under it, Standard trim
for the plain of everything: for seeing a kart from all round and its plate and editions, below, up close. Every kind of dress is
put on on the Garage's lift, along its front wall, 4.4a.

**The roundabout.** Until both keystones are won it is printed pale, as a closed landmark is, its
JACKPOT faint under the paper. Once they are, the roundabout opens: a ring of seven bets round the
pot, each a count from the moment the ring is dealt, drawn from the counts of the Strip and the
Department, a number of cash-outs, a distance, jokers taken. Winning all seven is a lap. Each lap is
printed on the program's card and on the license, LAP 3, and pays an edition: the player picks one
piece of dress they have won and it moves up a finish, Foil, then Holographic, then Polychrome, each
over the last and seen on every screen. A finish is a sheen and never a color: the player's color
under it and the marker over it stay as they are. Then the ring is dealt again, seven new bets, each
half as much again as the last lap's of its kind. It never runs out, there being always another lap,
and nothing is ever taken back or reset. The ring's bets are drawn from the counts of the Strip and the Department,
the same for the same card and lap, and stand as badges over and under the roundabout, filling as
they come; the cursor drives to the roundabout from either keystone, the buttons' gold edge as a
ring cased in ink as a sign's is, standing round it clear of its rim, seen where the gold roads come in, and its pane names the seven
with how far each has come. An edition is chosen there, from every piece of dress won: on paint, hats,
flags and the gold plate Foil a band of warm light sweeping across it with its edges lit, Holographic
colors that turn as it is seen from another side, Polychrome bands of every color drifting over it;
a trail in Foil glints gold as it goes, in Holographic turns through the colors and in Polychrome is
every color at once; and tire marks, subtle as they are kept, take a faint tint of the same. Each
rides the wire with the kart's dress, so every screen shows it; the piece is new in the kart dialog
again until it has shown it there, 4.4a.

While an edition is owed the roundabout calls for it: Loyalty Program and Clubhouse on the title wear
NEW, the program opens on the roundabout wherever the cursor was left, rings of foil going out from
it one after another, and its row in the list says the edition owed and opens the editions; on its
pane accept chooses an edition rather than pinning, and the key drawn on the edition's button says
so.

**The first map.** The program's map is drawn as the arenas of 6.3 are, as a grid of characters, so a
landmark is added by drawing it in and giving it a line, and the roads are printed from the grid:

```
............1...........3...........5...........9
            :                       :           :
            2...........8...........6           0
            :                       :           :
            4.......................7...........%
            :                       :
            :                       +.........+
            :                                 :
            :               @@@               :
            :     +---------@@@---------+     :
            :     |         @@@         |     :
            :     |                     n-----f-----e-----+
            :     |                     |                 |
G-----------F-----O                     m-----l-----------g
|           |     |                           |           |
M-----J-----E-----N                           j           d
|     |                                       |           |
H-----D-----I-----B                     k-----i-----------h
|                 |                     |                 |
L-----C-----K-----A                     a-----b-----c-----+
                  |                     |
                  +----------*----------+
                             |
```

```
A-O  the Strip       a-n  the Department      1-9, 0, %  off the books
*    the slip road, where every profile starts, won with the card
@    the roundabout
- |  the house's roads           +  a bend or a crossing with no landmark on it
. :  roads in pencil, off the books; a road off the grid's edge leads off the map
```

| | Name | Bet | Pays |
|---|---|---|---|
| `*` | The Slip Road | Activate your loyalty card | The roads onto the map |
| A | The Cashier's Cage | Cash out 20 times | Dealer's visor |
| B | The Card Room | Take 30 jokers | Lucky Seven, Hot Streak, Aimbot and Snowball, and Checks paint |
| C | Chip Alley | Pick up 5,000 chips | Poker chips trail, and the Magnet flag |
| D | The High Limit Room | Cash out 3,000 at once | Card suits paint |
| E | Flush Row | 10 Royal Flushes | Ace of spades flag |
| F | The Ten Times Bar | Cash out at ×10 mult or more | Snake Eyes, Road Rage, Scar Tissue and Royal Court, and the fez |
| G | The Prize Counter | Use 50 power-ups | Spread Cannon and Swivel Cannon |
| H | Jackpot Plaza | 1,000 chips out of the Jackpot | Fedora |
| I | The Bounty Board | 5 bounties | Decoy Kart and Bullet Wipe, and the confetti trail |
| J | The Last Call Bar | Win a map you were not leading as Last Call began | Gilt card back |
| K | The Shuffle Room | Take 200 jokers | Deep Pockets, Wild Card, Carbon Copy, Copy Cat, Flush Draw and Echo |
| L | The Counting Room | Bank 5,000 in one map | High Roller and Glass Jackpot |
| M | The Winners' Circle | Win 30 maps | Payday and Direct Debit, and the top hat |
| N | Crazy Eights | Hold 8 jokers at once | Toll Booth and Insurance Policy |
| O | The Grand Salon | Keystone: win three Grand Prix | Shark fin, and the roundabout's road |
| a | Milestone 2.5 | Drive 2.5 km | Racing stripes paint |
| b | The Skid Pan | Drift 2 km | Chalk tire marks |
| c | Boost Bend | 100 drift boosts | Flames paint |
| d | Turbo Lane | 150 turbo pads | Windsock flag |
| e | The Nitro Pumps | Burn 3 minutes of nitro | Afterburn trail |
| f | The Records Office | A map of 3 minutes or more without dying | Gold plate |
| g | The Firing Range | Land 60% of 30 shots or more in one map | Ear defenders |
| h | The Body Shop | Ram 25 karts | Horns |
| i | Lost Property, the School | Lost Property: the driving school | Traffic cone |
| j | Lost Property, the Yard | Lost Property: the Yard | Hard hat |
| k | Lost Property, the Workbench | Lost Property: the Workbench | Tape measure |
| l | Lost Property, After Hours | Lost Property: After Hours | Fuzzy dice |
| m | The Long Haul | Drive 50 km | Dashed tire marks |
| n | The Showroom | Keystone: win three maps in a row, one in each of the three rooms | The Showroom, the checkered flag, and the roundabout's road |
| 1 | pencils | Find 3 notes; open from the first note | Pencil trail |
| 2 | seven exactly | Cash out a pot of exactly 7 chips | Patchwork paint |
| 3 | no thank you | Skip every joker offered in a map, three or more | Kit's rag flag |
| 4 | torn up | Destroy a rare joker | A loose note |
| 5 | empty handed | Win a map without ever taking a joker | Welding goggles |
| 6 | quiet hours | A map of 3 minutes or more without firing a shot | Paper hat |
| 7 | walk away | Drive off the Junction with 200 chips or more still in the pot | A loose note |
| 8 | the back roads | Keystone: find 12 notes | Hand-drawn card back, and a loose note |
| 9 | left on the floor | Drop a full hand of jokers, five, in one map | Graph paper paint |
| 0 | no strings | Win a map without picking up a power-up | Pencil tire marks |
| % | house money | Cash out 1,000 or more with an empty hand | Doodled card back |

Every number is a starting value. The pace is aimed at about ten hours of maps, played broadly, for the
Strip and the Department to their keystones, the counts set against what a profile's statistics hold
after an hour or so of play. Off the books runs at the story's pace, its notes being the story's, and
its bets of one map can be won in any.

**Growing it.** The map is data, `data/loyalty/`: the grid, and a line for each landmark, its id, its
district, its bet and what it pays. A bet is one of a few kinds, a statistic of 8.5 reaching a count, a
feat of one map, a thing found, notes found, so a new bet of a known kind is a line and no code. An id
never changes, so a profile keeps what it won however the map is redrawn: a landmark moved keeps its
state, one taken out leaves its reward with whoever won it, and one added is open at once for a profile
that has won a road into it and settled at once if its count is met. The map grows outward: roads can
run on past its edges, a district can spread, and a new district can take another side of the
roundabout, the table's rules perhaps, or a new room's maps. The list beside it reads the same however
big it gets. What would not fit is hundreds of small goals; those are achievements, 8.10, and the
program is for the few dozen things worth a road. Tests hold the grid together: every landmark reached
from the slip road, every road joining two landmarks, every character in the grid a line and every line
in the grid, no two ids alike, a keystone's roads in, and every bet of the House's one that can be gone
round on the way to a keystone. Milestone M10 of PLAN.md is the order it is built in.

### 8.10 Achievements

Achievements are things worth having done once: a way of winning, a moment at a table, a hand held, a
road finished. They stand beside the loyalty program of 8.9 and differ from it in three ways: they are
earned in any order and at any time, nothing opening anything else; none of them pays anything; and
each asks a player to get into a particular spot and see it through, rather than to add up a count,
all but Property Damage, which is there to come as a surprise.
Each is something to set out to do. A few come on the way to something else, but a map played without
a thought for them earns one or two at most, and none needs tens of hours: everything is about twelve
hours of play, nearly all of it the program's own ten, with the story's three and a half running
alongside. They are the game's own rather than the House's or Kit's: they read the same at every stage
of the story and with it switched off, and only the four that are the story's touch it.

**Each profile's own.** An achievement is kept in the profile beside its catalog and its program, 8.5,
with the moment it was earned, and counted as the program counts, 8.9: the first seat's play for the
profile playing, a seat another profile sits in, 3.8, for that one, so a friend linked at the next seat
earns their own in the same map, and a guest's and a bot's for nobody. Watching an online game, 9.3,
counts for the watching machine's profile playing, which is what Front Row is for. It counts in every
room a statistic counts in, every map of a quick match or a Grand Prix, the lobby and the driving
school, and never in the Garage, in a headless run or on a dedicated server; Full Deck and Toybox,
which read the catalog, count wherever the catalog does, 8.8, the Garage included. Earned, it is
written into the profile there and then, as the Final Hand's stamp is, rather than waiting for the room
to be left. Online each machine counts its own seats out of what it already hears, the host's word of a
kill, a cash-out or a card taken and what the snapshot carries, so nothing of it goes over the wire,
with one exception: two bullets meeting are only ever seen by the host, which now says so as it says a
kill, so that Parry counts on a client too. That message is new, and a version with it does not play
with one before it. An achievement is kept by an id that never changes, and one this version does not
know is kept and never shown, as the catalog's cards are.

**Earned already.** Some can be read off what a profile keeps anyway: the license and its
endorsements, the catalog, the program's landmarks and laps, the dress a seat wears, the notes found,
the story's ending and the maps played after it, and the crates broken, 8.5. Those are earned the moment the record shows them,
wherever that is, and a profile from before achievements is credited every one its records already
hold the first time the title comes up with it playing: quietly, each marked new, with one toast saying
how many, "7 achievements unlocked", in place of a run of them. The rest, the moments of a map, start
from nothing.

**The story's six.** Off the Books, Terms Accepted, Not This Time, Employee of the Month, Under the
Floorboards and A Fresh Start are the story's, STORY.md 8.7, and the only ones hidden: in the list
each is a row saying only Hidden
achievement until it is earned, so a player who has not met the story learns nothing from the list but
that there is more to find. Four are ones that nobody who plays on with the story on can miss: a
note
found, the House's evaluation stamped, a map played after it, and every note of the story found, the
last of which turn up by themselves after the ending. Two are choices: the House's evaluation torn
off rather than stamped, and all five of Kit's cards taken. The three loose notes of the program,
STORY.md
7.3, are not among them. With the story off none of the six can be earned and Kit's district does
not
count toward Know Every Street; switched on again, whatever is met is earned there and then.

**Chips and pins.** Every achievement is a commemorative chip, the kind a casino strikes for an
occasion: a poker chip with the table's notches round its rim, 8.1a, a cream inlay in its middle and on
it the achievement's own picture in ink, drawn as the landmarks' and the jokers' pictures are, 8.3a, so
no two are alike and none of them is a picture file. Its color is its denomination, as a casino's are,
and says what it took: white for a first step or for company, red for a moment, green for a feat and
black for the hardest and the longest. The story's six are enamel pins instead, the kind staff wear
on
a lapel, each cut to a shape of its own and edged in metal: Terms Accepted's and Employee of the
Month's struck by the House in its gold, black and red, Off the Books', Not This Time's, Under the
Floorboards' and A Fresh Start's Kit's own, in
their grays, painted by hand rather than struck. One not yet earned is drawn the same in gray, its picture
faint, so a player can see what they are after; a hidden one is the same for all six, a scrap of
Kit's
graph paper folded over something and taped shut, a question mark on it in pencil.

**Unlocked.** The moment one is earned it comes up in a corner of the screen: a ticket of the house's
dark stock sliding in from off the screen's edge, its corners cut and a gold hairline inside its edge,
its stub a piece of the felt with a round pressed into it, torn off along a perforation with a half
round bitten out of either edge, as an admission ticket's is. Its chip or its pin is tossed onto the
stub, spinning as a tossed coin spins until it lands face up in the round; ACHIEVEMENT UNLOCKED over
its name, the name smaller where it is long; and as it arrives EARNED comes down in red across its end,
the rubber stamp of a row of the dialog, a little askew. Five seconds, then it slides back
out the way it came. Its sound is that stamp coming down and then one small bright bell, which nothing
at the table makes: a chime borrowed from the table, a cash-out's or a chip's, said something else had
happened, and a bright run of bells after it sounded like a slot machine paying out. Another earned meanwhile waits its turn, and none comes up while a
loading screen is up or over the ending's last lines. In a room it comes down from the top of the
screen, or up from its foot, to beside the corner of the seat that earned it, 8.3, after any BET WON
there and never over it, as small as it has to be to fit between that corner and whatever stands in
the middle of the screen's edge, the clock and what hangs beside it or the lobby's count, and under
the corner where even its smallest would not fit; the camera keeps it off the karts as it keeps the
corners off them, and a seat sitting in as another profile has that profile's name on its slip.
Anywhere else, on the title, in a dialog, over the payout slip or over a room's menu, it comes in from
the right to the screen's top right corner, and one beside a seat's corner as the menu comes up over
it goes on to there; the menu pausing the room does not hold it, nor those waiting their turn. Nothing pauses and nothing has to be pressed. Clicked with the mouse or tapped
with a finger, it shows its achievement in the achievements dialog, the cursor on its row, the row shown even where
earned ones are left out: in the dialog if it is up; in a room over the room's menu, put up first,
which pauses the match as Escape does and online asks the room to, and is left up to resume from once
the dialog is put away; on the title over it; and a seat's toast shows that seat's profile's
achievements, its name by the count. The toast slides back out at once. A tap is a finger down
on it and up again soon, near where it came down: a thumb resting on it or sliding over it does
nothing, and a touch the touch controls take for the kart never reaches it.

**The dialog.** Achievements, in the Clubhouse after the Catalog, 3.8, and on the License tab of the
settings with how many of how many, 8.5, and in the Clubhouse of a room's pause menu, opens a large
dialog over the screen as the catalog does, 8.8, on a layer of its own, filling the screen on a short one
or a phone's. The pane is a card table. Its felt is green, its nap mottled lighter and darker with
a fine grain and short fibers lying every which way, and round it runs a padded rail of brown
leather, its corners round, its pebbled grain catching the light along the top of its crown,
top-stitched in gold along both its edges, its shadow falling on the felt inside it and on the screen
round it. On a phone, or wherever the pane fills the screen, the table is a little bigger than the
screen: the rail runs on past its edges, narrower and square on its outside, its outer stitching out
of sight and a strip of its leather and its inner seam left flush along every edge and corner. What is on the felt is printed on it in cream, as a
table's layout is. Its head carries the title, how many have been earned of how many, 12 / 53, with a
gold tick once every one has, and at its right two switches. Hide
earned, the option key its bind, F or a pad's X, drawn just before its words, as the catalog's second switch has it, is a craps
table's puck,
black and OFF or white and ON; it leaves out every achievement already earned, and the heading of a
group with nothing left in it; with everything earned the table says so, "Every achievement is
earned.", the cursor on Back. Sort, after it, the view key its bind, Tab or a pad's Y, hung on the
middle of its foot as Next new's is, is printed
on the felt as a
craps table's PASS LINE is, its words in a box of a heavy line and a fine one, only as wide as it
says, turning gold and washed with it under the cursor, as Back is: In order, by the groups of the
list below, each under its heading; Earned, the latest first and the rest after them in order; and
To do, those not yet earned first, the nearest done at the top, the earned ones last. The machine
remembers both. Under the head a line is printed round the rows, a heavy one and a fine one inside
it, as a blackjack table's are, broken at its foot for the table's motto, BRAGGING RIGHTS PAY 3 TO 2.
The rows scroll inside it, fading out toward its top while there are more above and toward its foot
while there are more below, sharp at the list's start and its end, under brass plates for the groups'
headings, with a row for each achievement: its chip or
pin set into a round of the felt at the left, its name in the house's print, what it asks under that
in ink, and at the right the day it was earned, or how far along it is, a little road filling in gold
with its count, 12 / 35, as the program's tickets have it, or nothing for a moment that either happens
or does not. Earned, a row's chip shines and its paper is bright; not yet, its chip is gray and its
paper a little dimmer, its name gray. The hidden ones come last in every order, Hidden achievement
in gray as any not yet earned. A row earned since the dialog last
showed it wears the gold NEW tag of 8.8 until the cursor has been on it, and while one does, the
Clubhouse and Achievements on the title wear it too. Next new of 8.8, printed on the felt as Sort is
and just left of it, goes from row to row wearing it in the order the list is in, each brought to
the middle of the case; a row Hide earned leaves out is shown all the same, as a toast clicked shows its own. The
head is one row and never wider than the screen, at a phone's size and a big UI scale too: where
there is not room for all of it, Hide earned's bind goes first, then Back's room
past its own word, and last the words before the puck, which says OFF or ON by itself. The cursor
walks the rows as a list does, the
wheel, the right stick or a finger scrolls them, and the row under the cursor is marked as a button is
round its paper label, not the whole row, the cursor's frame sliding from label to label, and its chip
turning over once. Back, B, Escape or a click on the shade beside the pane puts it away.

**What counts as what.** A map against three or more is one with three other karts or more at the table
at its whistle, bots or people; in teams, 3.14, it counts the karts of the other teams only. A map
won in teams is won by every kart of the winning team, and so is a Grand Prix, for these and for the
loyalty program's bets alike, 8.9; what a moment asks of the player alone, a cash-out or a life,
is still theirs alone. All In in teams is a win with every chip the player banked in it coming in
the one cash-out, which took their team to the target; Push Your Luck's target is the one set per
kart; By a Nose is a team's margin over the next; and Last Kart Standing asks to be the very last
kart, the team's other karts gone too. A map played is one played to its whistle. Pot worth is chips times mult,
the number the corner shows. Holding is in the hand at once, 3.7, and a full stack is a stack at its
most, 7.3, of a joker that stacks. A moment is counted from where the seat came in, as the program's
bets of one map are, and a seat that sat down in a kart already going counts nothing done before it.

**The list.** Every achievement in its group's order, its id the store's name for it too, the chip it is
struck on and the count its bar shows. Every number is a starting value.

| Id | Name | Objective | Chip | Bar |
|---|---|---|---|---|
| | **Getting started** | | | |
| `street_legal` | Street Legal | Pass the driving test and earn your license | White | |
| `honor_roll` | Honor Roll | Pass the driving test with all seven endorsements | Green | |
| | **Winning** | | | |
| `flawless` | Flawless | Win a map against two or more without losing a single life | Green | |
| `beat_the_house` | Beat the House | Win a map against three bots on Hard | Black | |
| `clean_sweep` | Clean Sweep | Win every map of a Grand Prix of three maps or more, against three or more | Green | |
| `last_kart_standing` | Last Kart Standing | Be the last kart left in sudden death, with three or more others in it as it began | Green | |
| `all_in` | All In | Win a map against three or more with a single cash-out | Green | |
| `by_a_nose` | By a Nose | Win a map against two or more by 50 points or fewer | Red | |
| `buzzer_beater` | Buzzer Beater | Take the lead with a cash-out in a map's last 5 seconds, and win it | Green | |
| `winner_takes_all` | Winner Takes All | Win a Grand Prix in its showdown, 9.7a | Red | |
| `partners_in_crime` | Partners in Crime | Cash out on the Junction at the same time as a teammate, and win the map as a team against two or more | Green | |
| | **The tables** | | | |
| `push_your_luck` | Push Your Luck | Carry a pot worth three times the target score | Black | |
| `let_it_ride` | Let It Ride | Hit three of a kind on a slot machine at match point | Green | |
| `point_of_sale` | Point of Sale | Reach Match Point while cashing out on the Junction | Red | |
| `hit_the_jackpot` | Hit the Jackpot | Empty a Jackpot pile of 120 chips with nobody else on it | Red | |
| `most_wanted` | Most Wanted | Cash out 1,000 or more with a bounty on your head | Red | |
| `snatch_and_grab` | Snatch and Grab | Take out a kart collecting a Jackpot, then empty that pile yourself | Red | |
| `full_house` | Full House | Make three Royal Flushes in one map | Green | |
| | **Fighting** | | | |
| `bank_shot` | Bank Shot | Take out a kart with a bullet that bounced off two walls | Green | |
| `parry` | Parry | Shoot down five bullets of other karts in one life | Red | |
| `long_shot` | Long Shot | Take out a kart 25 m away or more | Red | |
| `payback` | Payback | Take out whoever took you out within 10 s of coming back, three times in one map | Red | |
| `untouchable` | Untouchable | Take out eight karts without dying | Green | |
| `tough_as_nails` | Tough as Nails | Take ten hits without dying | Green | |
| `two_birds` | Two Birds | Take out two karts with one bomb | Red | |
| `set_and_forget` | Set and Forget | Have one turret take out three karts | Red | |
| `road_hog` | Road Hog | Take out two karts with one Boost | Red | |
| `slick_operator` | Slick Operator | Spin out three karts on one oil slick | Red | |
| `dead_ringer` | Dead Ringer | Have your decoy take out a kart | Red | |
| `long_way_round` | Long Way Round | Hold one drift for 15 seconds | Red | |
| `push_comes_to_shove` | Push Comes to Shove | Knock three karts into pits in one map | Green | |
| `a_pit_do_not` | A Pit. Do Not. | Drive into a pit carrying a pot worth 1,000 or more | White | |
| `property_damage` | Property Damage | Break 250 crates | Green | 250 |
| | **The hand** | | | |
| `a_real_handful` | A Real Handful | Hold nine jokers at once | Green | |
| `stacked` | Stacked | Hold two jokers at full stacks at once | Red | |
| `asking_for_trouble` | Asking for Trouble | Win a map holding three cursed jokers | Green | |
| `suit_yourself` | Suit Yourself | Make every hand, and be Suited in every suit | Black | 10 |
| `full_deck` | Full Deck | Take every joker at least once | Black | 47 |
| `toybox` | Toybox | Use every power-up at least once | Green | 11 |
| | **Company** | | | |
| `plus_one` | Plus One | Play a map with somebody else at the same screen | White | |
| `long_distance` | Long Distance | Play a map online with somebody at another machine | White | |
| `full_table` | Full Table | Play an online map with eight karts at the table, bots counting | White | |
| `front_row` | Front Row | Watch an online map from its flag to its whistle, and send some emotes while you do | White | |
| | **The Clubhouse** | | | |
| `dressed_to_the_nines` | Dressed to the Nines | Wear something in all seven parts of the dress at once | Red | 7 |
| `know_every_street` | Know Every Street | Win every landmark of one district of the loyalty program | Green | The nearest district's |
| `most_valued_member` | Most Valued Member | Win every landmark on the House's map | Black | 30 |
| `lap_of_luxury` | Lap of Luxury | Drive a lap of the roundabout: win all seven of its bets | Black | 7 |
| | **The story, hidden until earned** | | | |
| `off_the_books` | Off the Books | Find a note | Kit's pin | |
| `terms_accepted` | Terms Accepted | Stamp the House's evaluation | The House's pin | |
| `not_this_time` | Not This Time | Tear the House's evaluation off | Kit's pin | |
| `employee_of_the_month` | Employee of the Month | Play a map after the ending | The House's pin | |
| `under_the_floorboards` | Under the Floorboards | Take all five of Kit's cards | Kit's pin | |
| `a_fresh_start` | A Fresh Start | Find every note of the story | Kit's pin | |

- **The hardest.** Beat the House and Push Your Luck are the two that take real skill; Full Deck, Most
  Valued Member and Lap of Luxury are the long ones, most of the program's ten hours. A Real Handful,
  Asking for Trouble, Toybox and Dressed to the Nines need cards, items or dress the program adds, 8.9,
  and Toybox the lobby's All items as well.
- **Related, never more than two.** Know Every Street and Most Valued Member are one road finished and
  all of them; Off the Books and A Fresh Start a note and every note.
- **The license.** Street Legal, and Honor Roll with it, comes as the PASSED stamp comes down on the
  license at the driving test's end, 9.4a, not as the test is passed a moment before.
- **Hits.** A hit is one a kart takes and lives through: a life lost with another left, or a shield
  popped; ten in one life, healed at the Junction or by a kill on the way, is Tough as Nails.
- **Dress.** Its seven parts are the paint, the hat, the flag, the trail, the plate, the tire marks and the
  card back of 4.4 and 8.9, each worn as something other than its plain choice and other than None.
  The card back is the profile's, the rest the seat's.
- **Long Way Round** is one drift, from the handbrake's flick until the slide is caught or bleeds
  away, 4.1. A crash into a wall or a kart starts the count again, as it spoils the drift's boost;
  a glance along a wall does not.
- **Property Damage** counts every crate the profile has broken, with bullets, rams or bombs, the
  Statistics page's Crates broken, 8.5, and comes the moment the two hundred and fiftieth breaks; a profile from
  before it is credited what it has broken already.
- **Most Valued Member** is the House's map alone, the slip road and both districts, thirty landmarks, so
  a player with the story off earns it too; not Kit's district and not the roundabout.
- **Point of Sale.** Cashing out drains the pot into the score, so the two together stand still: what
  gets a pot to MATCH POINT on the pad is a kill or a graze from there, a flush pad's pay or a card's,
  or Last Call starting mid-cash-out, and the kart must have been cashing out before it.
- **Hit the Jackpot.** A pile tops out at 60 until the table is hot, 3.11, and at twice that at its
  hottest, the sixth level, 8.4: 120 is a pile left to fill all the way at a table that hot, and
  taken whole by one kart.
- **Push Your Luck** is three times the target score the map was set to, and never earned on a map
  with none, nor against a goal a lesson of the tutorial sets itself.
- **Front Row** asks for some emotes and is earned on the first.
- **Buzzer Beater.** The clock's last five seconds of the map, not of sudden death, which has none: a
  cash-out completed then that takes a kart from level with the leader or behind to ahead of
  everybody, the map then won.
- **Snatch and Grab.** A kart collecting is one a chip of the Jackpot came to in the last second; taken
  out, its pile is the taker's, and emptied by them, whoever else took a little of it meanwhile.
- **Road Hog** is two kills by ram in the three seconds of one Boost; **Slick Operator** three other
  karts spun out on one slick of oil; **Dead Ringer** a kill by your decoy, which always shoots,
  whatever trait it was dealt, 7.2, and which comes with the later power-ups, as Toybox needs.

**On a store.** Built with the store's version of the game, not before, and described here so it is
built the way the rest expects. The game says what a profile earned, and how far along a bar is, to a
small layer of its own, which hands it on to whatever store the build was made for: Steam through
GodotSteam, and any other the same way, each by the id in capitals as its name there,
`STREET_LEGAL`, and each bar's count as a statistic the store draws its own bar from, but for a bar
whose target moves, Know Every Street's on Steam, 10.8. A build for no
store hands it to nobody. Only the profile playing's go to the store, the store's account being the
machine's: as a profile starts playing, at start-up or switched to, everything it has earned is said
again, and a store is only ever told of more and never of fewer, so switching to a profile with fewer
takes nothing away there. The story's four are hidden there too. A store shows its own word of an
achievement as well, and the game's toast comes up all the same. What a store's page wants is drawn by
`make achievement-art`: every chip and pin, earned and not yet earned, and the hidden scrap, from the
same code on a square of the house's dark stock under a soft light, at 1024 pixels and cut down to 256
and 64, the sizes Steam's pages have used, into `build/achievements/`, with a text file and a table
of every id, its name on a store, its name, its objective, whether it is hidden and its bar's count.

**Growing it.** Each achievement is a line of data, `data/achievements/`: its id, name, objective, group,
chip, whether hidden and its count; a picture of its own; and, for a moment of a map, a few lines that
hear it. One added later is earned at once by a profile whose records already hold it. Milestone M11 of
PLAN.md is the order it is built in.

## 9. Modes

### 9.1 Single-player against bots

The first release. One human against 1 to 3 bots in a full match. Bots use the
same kart, cannon, items and jokers as players. The Decoy Kart power-up reuses
the bot brain.

**Brain**: a utility AI ticking at 10 Hz that picks one goal and steers toward
it. Movement uses a navigation mesh baked from the arena scene with
NavigationAgent3D, plus reactive bullet dodging.

| Goal            | When                                                                          |
|-----------------|-------------------------------------------------------------------------------|
| Collect         | Default. Nearest coin pad or dropped chips, weighted by value over distance    |
| Hunt            | An enemy is within 18 m and can be brought in front of the cannon, or within 26 m carrying a pot of 150 or more and this bot reads the board |
| Bank            | Pot value above the trait's threshold, or under 20 s left with a non-empty pot. A wounded bot halves its threshold, since a full cash-out is also its second life back, see 3.4 |
| Jackpot         | The active Jackpot has 20 or more chips and nobody is inside; and once collecting it, until the pile is gone, see below |
| Flush pad       | A Royal Flush pad is worth the detour: a pad held by nobody or by somebody else counts as 4 chips, the one that would complete the set as 24, and a pad of the bot's own with under 10 s left on its claim as 2.5, each divided by the distance to it |
| Grab item       | Holding nothing and a power-up pad is near                                    |
| Flee            | A Boosting enemy is within 6 m                                                |

**Staying on the Jackpot**: a bot that has come for the Jackpot and is collecting it
alone stays until the pile is gone, whatever its pot has grown to on the way. It
used to break off for the Junction the moment the pile had filled its pot past its
banking threshold, leaving half of it for whoever drove on next. What moves it is
danger: a Boosting enemy about to ram it, under 20 s left, when an unbanked pot is
about to be lost anyway, or, wounded, an enemy it can see within 10 m, since one
more hit loses everything. Danger is acted on at once, not after the usual dwell. A
second kart driving on pauses the pile for everybody, see 3.5, so it is no longer
collecting and chooses as it otherwise would, which with a rival that close is
usually a fight.

**Hunting a pot**: a pot is coins somebody else has already collected and has not
yet made safe, see 3.6, so on hard the bots go after whoever is carrying one.
They look further for it, 26 m rather than 18, they pick the richest kart in
range over the nearest one, and what that kart is carrying is added to the urge
to hunt rather than multiplied into it, since distance is exactly what a pot is
meant to overcome. A pot of 500 is worth a full point of pull and 1500 is worth
the cap of three, which is enough to take a bot off almost any errand. Below
hard nobody reads the board, and that is most of the difference between an
opponent and a threat: an easy bot fights whoever is nearest, a hard one comes
for whoever is carrying the most.

Somebody one cash-out from winning, 3.4, is another matter. Each bot decides once,
each time a rival gets there, whether to go after them, by its trait: a Hunter or a
Bumper nearly always (90%), a Balanced bot half the time, a Grazer 40%, a Greedy one
35% and a Cautious one seldom (15%). So a room of bots mostly sends one or two, not
all of them, and a bot that has decided sticks to it rather than changing its mind
every tick; the rival dropping below the winning line is forgotten, and the next
time is decided afresh. A bot that goes goes whatever its level: from anywhere on
the table, seen or not, at eight times its usual urge to fight and never less than
a hunter's, ahead of pickups and items. It lights nitro to ram them from 14 m rather
than 9 and on a smaller tank, and a bot holding its fire this life shoots at them
all the same. A ram or a hit knocks coins out of the pot that would have won it,
and for a bot behind on the board that may be its last chance of winning. The other way round, a bot whose own cash-out would
win goes straight to the Junction, whatever else it was doing.

**Sticking to it**: a goal is picked ten times a second, and two errands a bot is
equally near will otherwise swap places under it every tick and leave it driving
down the middle between them. A goal it has just picked is kept for a second and a
half before a merely better one may take it off. Three things still cut in at once:
a Boosting enemy about to hit it, an errand that has stopped existing because
somebody else took the pickup or the pad, and arriving, since an errand a bot is
standing on is finished whatever the clock says. Wandering is what a bot does for
want of a plan, so it never holds anything up.

**Settling the wheel**: steering answers the angle to the next waypoint, less a
share of how fast the nose is already coming round. Without that a bot holds full
lock until it is pointed at the waypoint, by which time it is turning too fast to
stop there, and it saws at the wheel the whole way down the road. In a slide the
correction is off: the nose coming round is the point of a slide, and the wheel is
already answering the slip angle. Whether the corner can be cut to the waypoint
after next is decided once per waypoint as well, since a line that grazes a corner
answers differently from one frame to the next and each answer is a different way
to aim. It is asked of the grid rather than of the physics, `ArenaNav.clear_run`:
whether a swathe the kart's width and a little either side of the line crosses a
wall, a crate or a hole, sampled every quarter cell. It used to be a ray along the
middle and the line checked against the holes, two questions where the grid answers
both at once, and for the whole kart, which is what scrapes a corner. The driving
itself is `BotDrive`, stepped by the brain.

**Arriving**: waypoints get a bot to the right part of the arena, but the last few
meters are their own problem. Flat out, a kart turns in a wider circle than the pad
it is aiming for, so it sails past and comes round again, forever. Inside 6 m of the
goal itself a bot eases off, down to a quarter throttle at the goal, and stops
drifting, which shrinks the circle to something that fits. With the goal behind it
and under 4 m away it backs onto it instead, because no turning circle fits at that
range. On the Junction and the Jackpot it then holds position as before. A kart it
is hunting it never backs onto: its cannon points the other way, so it turns round
to it instead.

**Drifting**: the kart drifts the oversteer way, see 4.1, so a bot throws it into a tight
corner the way a driver would: the handbrake goes in for a flick of 0.18 s when the corner is
tighter than the trait's drift angle and the kart is above 60% of top speed, with a second or
so before another is allowed. Holding it would break the rear loose again every time the slide
was caught, and walk the kart down the road sideways.

Once the rear is out a bot steers where the kart is going rather than where its nose points,
which is the same thing as winding on opposite lock at the moment a driver would. That makes
the slides short, about a third of a second: the bot catches it as soon as the kart is pointed
down the new road, which is the tidy way to use one.

**Judging them**: `make bots` plays whole matches of four bots at every level, easy, normal and
hard, on several seeds, and reports what each level achieved: banked score, cash-outs, coins
collected and lost, kills, deaths and what caused them, shots and how many landed, items, jokers,
nitro and turbo pads used, and how the wheel was used, how long a bot spent stuck, sitting still
or giving up, and the share of the time it spent on each errand. Each match is a process of its
own, several at once, at a fixed sixty frames a second of the match clock rather than of the wall
clock, so a match runs as fast as the machine allows and the same seed plays the same match again
until the bots themselves drive differently; it is not part of `make check` because it still takes
minutes. `BOT_VS=<commit>` plays the brain of that commit against this one, two seats each,
swapping seats from one seed to the next; the navigator and the kart are this commit's for both.
`BOT_MIRROR` sets the players' habits the bots read, below, which a room of bots otherwise leaves
at nothing, and `BOT_COST=1` times every brain's tick. Bot work is judged on those numbers rather
than on how a match looked, because a single match of four bots is mostly luck: the first three
ideas tried against it all read as clear wins on one match and as losses over three, and a head
to head needs thirty or so matches a level before a tenth either way means anything.

Over 24 seeds a level, the bots as they are now against the ones of 0.19.0, each in a room of
their own and nobody to copy:

| Per bot, 150 s       | Easy, before | after | Normal, before | after | Hard, before | after |
|----------------------|--------------|-------|----------------|-------|--------------|-------|
| Banked               | 461          | 537   | 559            | 656   | 570          | 773   |
| Deaths (holes)       | 4.5 (2.4)    | 2.9 (0.6) | 5.8 (2.4)  | 4.3 (0.5) | 7.2 (2.3)  | 6.3 (0.3) |
| Shots landing        | 77%          | 88%   | 66%            | 73%   | 55%          | 64%   |
| Sitting still        | 24 s         | 6.5 s | 22 s           | 5.4 s | 20 s         | 4.3 s |
| Backing out of things | 8.5 s       | 1.0 s | 6.0 s          | 0.7 s | 4.1 s        | 0.2 s |
| Average speed        | 3.9 m/s      | 5.0 m/s | 4.2 m/s      | 5.4 m/s | 4.3 m/s    | 5.8 m/s |

Head to head, two of each in a room, over 36 matches a level, the new ones banked 623 points a
bot to 351 on easy, 751 to 402 on normal and 905 to 518 on hard, and won 28, 34 and 33 of the
36. Timed in the same matches, a hard bot's tick costs 63 µs against 107.

**Saying something**: a bot emotes now and then, 3.8, on the moments a player would,
so the table's other karts read as players rather than as machines. Pleased at a
double kill or better and at shoving a kart down a hole; cross at being shoved down
one, at being shot at three times in six seconds by one player, hits and near misses
alike, and at being killed within three seconds of coming back; a gg for winning the
match, and now and then one for losing it, at a fifth of the chance, 7%, since a
table where every loser says it at once reads as a script. Each moment is a 35%
chance, weighed by the trait's chattiness, a Bumper rowdier and a Cautious bot half
as talkative, said after a moment's thought of 0.3 to 1.2 s, and a bot that has just
said something says nothing more for 20 s. The host decides, and it comes up
everywhere as a player's does, `BotEmotes`.

**At the Final Hand** of the story, 8.7, the bots are the player: named after them, Bob 2,
Bob 3 and Bob 4, dressed as they dress, and driving from the first second on the player's own
lifetime items, nitro and drift, the readings of the table below, rather than learning them from
the match as it goes; effort is the match's as ever, STORY.md 8.2. Their traits are dealt as ever.
From three quarters of the way in they stop driving their own way and follow the candidate's own
recorded line, three seconds behind and closing to one, holding their fire and their items while
they do, and the house's racks rise where its forecast of each of them ends, which it never gets
wrong, 6.3. It is the one place the story reaches into a bot's driving, and it changes what the bot
reads, where it goes and whether it shoots, never what it can do.

**Getting unstuck**: driving at something solid pins a kart against it, and steering
toward a target on the far side only holds it there harder. A bot that is going
nowhere with the throttle down backs up for 0.7 s with the wheel over, which swings
its nose clear, and then drives out for another half second on that same wheel
before the navigator gets the kart back, so it leaves along its new heading instead
of turning straight into what it was stuck on. It puts up with going nowhere for a
second before deciding, unless it can feel a wall right on its nose, which takes a
third of a second. Standing still is not the only way to arrive nowhere: a kart
scrubbing along a wall or grinding on a corner keeps a speed on the clock the whole
time, so a bot also watches the ground it has actually covered and gives up on
anything that has moved less than 2 m in two seconds. The turn is picked once and
held for the whole maneuver, and alternates, so a bot that backs into the same
corner twice tries the other way out rather than rocking on the spot. A bot turning
round on the spot is not going nowhere, though: with its nose coming round faster
than 1.5 radians a second it is not counted as standing still, and having come
round more than a right angle in those two seconds, all the turning counted rather
than only where it ended up facing, it is not counted as having got nowhere. Backing it out of a turn it was making cost it the turn and a second and a
half besides.

Backing out does not get a bot out of everything, so a longer watch runs under it,
`BotStuck`. A bot that has stayed inside a circle 2 m across for ten seconds, backing
out or not, while not waiting somewhere on purpose, banking on the Junction or
holding the Jackpot, gives up on what it was doing: it backs away and wanders off to
a spawn point at least 12 m from where it was, and holds to that for four seconds, or
until it gets there, so the next decision does not send it straight back. Still in
that circle five seconds after giving up, it is put down on the spawn point farthest
from everybody else, facing the Junction, the way a respawn puts a kart down but
without dying: it keeps its lives, its pot and its jokers. Only in a match: a room
has nothing to be late for, and the driving test holds its bots under the floor on
purpose. Online it is the host's, whose bots they are; a client sees the kart jump
there as it sees a respawn.

**Pits**: paths go around them, and keep a cell clear of them where the room allows: the cells
right round a hole cost a path four times what open floor does, so a bot takes the floor beside
a hole only when there is no other way worth the detour. A wall a path hugs costs a scrape; a hole
costs a life, and the cell beside one left a kart a hand's width either side of falling in. But a
pit stops nothing and blocks no raycast, so a bot cutting a corner, sliding out of a drift,
backing out of a wall, dodging a bullet or shoved off its line would still go in, and the last
word on every tick's driving is `BotPits`: the controls the bot has settled on are played forward
a second, the kart turning at the rate its wheel gives at the speed its pedals give, on the spot
at a standstill as the kart itself turns, and its body is checked against each hole's trigger at
every step of the way. Where the wheel it wants leads in, the nearest wheel either side that does
not is taken instead, the same side as last time while a hole is near, so it does not flip
between the two; only when no wheel keeps it out does it stop, on the brakes going forward and on
the throttle going backward, since the brakes are reverse once a kart has stopped. Short cuts
between waypoints leave the same room. With no hole within reach of a second's driving the check
is a distance to each hole; with one, the controls are played forward every other tick at most
while they hold steady from one tick to the next.

What it checks for is room for the whole kart, not for its middle: the body is two circles along
the nose that just cover its corners, kept 15 cm and a little more at speed off the trigger, which
is the middle 70% of the hole's cells. It used to check a straight line along the way the kart
was moving, a second and a bit ahead, against the hole grown by the kart's half-diagonal. That
said nothing about a kart that was turning, which a bot is most of the time, so its turn carried
it into the hole, and everything about one parked beside a hole: a line from a kart that had
stopped said nothing until it moved and then said stop, so a bot whose errand lay along the edge
of a hole sat there for seconds on end with the throttle and the brakes taking turns. Holes were
two in every five bot deaths then, 2.3 a bot in two and a half minutes at every level, and a bot
sat still for 20 to 24 s of them; now it is about half a hole a bot, a third of one on hard, and
4 to 7 s sitting still, see Judging them.

**Dodging**: for each enemy bullet within 8 m, predict the closest approach
over the next second. If it is under 1.2 m, steer perpendicular to the bullet,
with the difficulty's dodge chance. A bullet that bounces off a wall is a bullet
coming another way, and decided about again; and in a room where a kart's own
shots hurt it, 3.8, its own bullets come into it once they have bounced.

**Firing**: fire when the shot would go through an enemy within 18 m, after the
difficulty's reaction delay, leading the target to where it meets the shot: from the
muzzle, at the shot's speed, the moment the two are in the same place worked out
rather than guessed from how far away the kart is now, which fell further behind the
faster a kart crossed in front. Played against the guess over 36 matches a level, hard
bots' shots landed 65% of the time against 62%. Driving after a kart, a bot steers half a
second of the kart's travel ahead of it at most, inside the room: the shot's lead of a kart
running away is across the arena, and the bot drove there. Through an enemy is 8°
off the heading plus however wide the target is from where the bot is standing, up to
63°: a fixed angle says less and less about a miss the nearer the target is, and a
bot shoving a kart along at arm's length should be shooting it rather than only
bumping it. With nobody in reach, the same shot goes into the nearest crate or
shooting target within 13 m instead: both pay whoever breaks them, see 6.2, and a bot with
nothing else to fire at may as well be paid. The shot is weighed along where the
cannon points rather than along the nose, `BotTactics`: holding Backfire, 7.3, a
bot with a kart close behind it brakes and shoots it out of the back, and a bot
braking for anything else holds its fire at a kart in front, which the shot would
leave the other way from. With bullets that bounce, Rubber Bumpers' or the
Ricochet Cannon's, a kart round a wall within reach is shot off another one:
as it thinks, the bot looks along a fan of ways either side of its aim, within
35°, for one whose shot comes off the first wall it meets, not a crate, which
breaks a bullet, and passes within 0.7 m of the kart, and turns onto it; and
where its own shots hurt it, it does not fire square into a wall within 4 m.

**Cover**: in a showdown, 9.7a, a fight with no coming back, a bot that is the
worse off, wounded, on fewer lives than the kart with a line on it, or with every
bullet it may have already in the air, goes behind something: the nearest open
place within 9 m, no nearer the threat than it is, that the threat cannot see any
of a kart's width of, walls and crates alike. It stays there 2 s, shooting
anything that comes round into sight, and does not hide again for 4 s, so a fight
does not become a wait.

**Traits**: each bot gets one trait that shifts its goal weights.

| Trait    | Weight | Behavior                                                              | Slots |
|----------|--------|------------------------------------------------------------------------|-------|
| Balanced | 40     | Default weights, banks at a pot value of 120                           | 1     |
| Greedy   | 15     | Banks at 200 or during Last Call, prefers the Jackpot                  | 2     |
| Cautious | 15     | Banks at 60, dodge weight times 1.5, avoids fights                     | 0.25  |
| Hunter   | 15     | Hunt weight times 2, banks at 120                                      | 0.5   |
| Bumper   | 10     | Rams constantly, seeks Boost, rarely fires                             | 0.7   |
| Grazer   | 5      | Deliberately weaves close to bullets, banks at 100                     | 1     |

**The slot machines**, 3.15: every 20 seconds a bot with 25 chips or more in its pot and below what
it banks at thinks about a pull, and goes for one with a chance of 30% times its trait's appetite
for them, the Slots column: about once a minute for a Balanced bot, twice for a Greedy one, every
few minutes for a Cautious one. Made up its mind, it heads for the nearest machine that will take
its bet for twelve seconds, weighed against a pickup or a pad as they are against each other, and
having pulled it leaves the machines be until it next thinks about them. A pull it made may get an
emote, 3.8: pleased with one that paid more than it bet, two and a half times as likely for three
sevens, and cross at one that paid nothing, less often, or went void; a pair, its bet back, is
nothing to say.

A room deals each trait once before it deals any twice, drawing by weight among the ones dealt
least, so three bots are three different ways of driving and the seven of a room of eight, 9.3,
are all six and one of them again. Drawn on their own, two of three bots were often the same
Balanced.

**Difficulty**, one global setting chosen in the lobby and applied to every
bot:

| Parameter        | Easy  | Normal | Hard  |
|------------------|-------|--------|-------|
| Reaction delay   | 0.5 s | 0.3 s  | 0.15 s|
| Aim error        | ±10°  | ±5°    | ±2°   |
| Dodge chance     | 40%   | 65%    | 85%   |
| Top speed        | 90%   | 100%   | 100%  |
| Reads the board  | no    | no     | yes   |
| Item sense       | no    | no     | yes   |

Bots play at the pitch the players set, which the code calls the mirror. Every
few ticks the match reads the human players' own statistics from 3.8 and turns
them into four numbers the bots use:

| Reading | Taken from                             | What it changes                                               |
|---------|----------------------------------------|---------------------------------------------------------------|
| Items   | Items used per minute, 3 is all-in     | How long a bot sits on an item, from 30 s down to 2 s, and whether it plays items cleverly at all, which needs a reading above 0.3 below hard. Also how far it will go out of its way for an item box |
| Nitro   | Share of the match spent burning nitro, a twentieth is all-in | How full a bot wants its tank before burning any, from a full tank, meaning never, down to 30% |
| Drift   | Share of distance driven sideways, a quarter is all-in | The corner a bot will yank the handbrake in, from 137°, meaning never, down to 52° |
| Effort  | Live score between the best player and the best bot, banked plus whatever is still in the pot, 600 points is a full step, held between 0.7 and 1.3 | Throttle while ahead, aim error, how readily a bot goes hunting, and the pot it settles for before heading to the Junction |

The first 45 s are measured as if they lasted 45 s, so one early item does not
peg the whole match. Item sense is the hard bots' own: they play every item at a moment it
fits from the first one, the Boost into a chase, a bomb or a slick behind them with somebody
on their tail, a turret with somebody near, the Shield over a fat pot or with shots about,
a cannon item into a fight, the Decoy into a chase or an escape, Bullet Wipe with shots on
top of them, whatever the players do with theirs; how long they hold one with no such
moment, and how far they go for an item box, are the players' as at every level. Over 72
matches of hard bots that knew how against hard bots that did not, the ones that did took
6.5 kills a bot to 5.4, died 5.9 times to 6.2 and banked 756 points to 710. With the Swivel Cannon a bot aims the
cannon at its mark as a player does with the stick, off by its usual wobble; it used to fire
it down its nose for its twelve seconds. Traits still apply over the top: a Bumper is a Bumper
whatever the players do, it just does its Bumper things at their pitch. Effort
never pushes a bot past its own top speed, only lets it lift off when it is
winning, so the bots close a gap by playing better rather than by cheating.
Because the gap is measured against the live score rather than the banked one, a
player carrying a fat pot counts as the leader they are about to become, and the
bots come after them before they reach the Junction.

### 9.2 Local multiplayer

Shared screen, up to 4 players, gamepads plus one keyboard and mouse player.
Four is the most at one machine whatever the room, since a screen has four corners for their
blocks, see 8.3; a room online can hold more of them from other machines, see 9.3. A fifth
pressing join is turned away with a notice saying this device has room for 4 players.
Players join in the lobby, the waiting room of 9.6, by pressing the join button on
their device, Start on a gamepad or J on the keyboard, which seats them in a color
nobody else has, with their seat's name and dress. Until somebody joins on another
device P1 plays on any device, and then settles on the one they last drove with.
Bots fill empty slots if wanted, as many as the match settings ask for. Back to
the lobby from a map, everybody who played it at this machine comes back with it,
in the colors, names and dress they had.

Joining mid-match is allowed: a press on an unused device during a match adds
the player. If a bot kart exists, the joiner takes it over and inherits its
score, pot, jokers and item, so the match keeps its number of karts, in their own seat's
name and dress rather than the kart as the bot drove it. A player from another
machine takes no seat of this one's, since their name and dress are their own to
say, see 10.3. Otherwise the joiner
spawns fresh with an empty pot and 0 banked score. With every seat of the room
taken by people nobody else can join, and nor can a fifth at one machine. A player who leaves mid-match hands the kart back to a bot.

With more than one player at a screen, each of their switches in the pause menu, 4.2, ends in
Leave, for one of them to get up and go while the others play on; with one there is nothing to
leave from, and no button. On a map a bot takes the kart and its score on, as it does for a pad
that is unplugged. In the lobby and the Garage the seat is emptied the way a seat left online is,
9.3, its kart gone until somebody sits down in it. Online it is the players at this machine it
is for, at a client as at the host; the other machines see the kart go the way they see any other.

On a pad, Start is both the join button and the pause button, and which one a
press is depends on whose pad it is: on a pad nobody is driving it takes a seat,
on a pad somebody is driving it pauses. A P1 still playing on any device is
driving whichever device they last drove with, or before they have driven at all,
the one they last used anywhere, the menus that brought them in included; once
somebody sits down beside them on another device, that is the one P1 keeps, and
only with nothing to go on is it the keyboard. Before this, P1 coming into the
lobby on a pad they had only used in the menus was handed the keyboard when a
second pad sat down, and was left with nothing to drive with. Every pad answers
to the bindings, not only the first one plugged in, and drives only its own kart.

### 9.3 Online multiplayer

The third release. Godot's high-level multiplayer over ENet with a
host-authoritative listen server, found on the network or joined by direct IP and port
from LAN games, see below. The host waits in an online lobby that lists who is in and
shows the address to join at, and presses Start when everyone is there;
players may still join a running match. Up to 8 players, at most 4 of them at
one machine, bots run on the host, and a joining client takes over a bot's kart. Design details in 10.3. A join code needs a relay
service and is a backlog item; a Steam build plays with Steam friends over Steam's own network, 10.8.
Joining mid-match follows the local rule in 9.2, and so does leaving one. Leaving the waiting
room of 9.6 does not: nothing is played for in there, so there is no score for a bot to keep, and
the bots come in with the match. The seat is emptied instead. Its kart goes out of the room with a
puff in its color on every screen, nothing counted, and stays out until somebody new sits down in
it, when it comes back in for them as a kart does after dying, in a free color if its own was
taken while it stood empty. Pausing an online match takes
every machine in the room asking for it, see 3.8. The match is played by the
host's lobby settings: a joining client is sent the clock, the target score,
the number of lives and the rest of the numbers its own lobby could have moved,
and drops its own. Everybody says what they are called on the way in, see 3.8.

A client can have more than one player at it, the way one machine can, see 9.2: a press of join
on another device there, Start or J, asks the host for another seat, in the lobby or in a match.
The host seats them the way it seats somebody from another machine, in a color nobody has and
under the name and dress of that seat of the client's settings, the second seat's for the second
player, and they get a corner of their own on that screen. Each is driven, predicted and
corrected on its own, and each can get up and Leave from their switches while the others play
on. They go from room to room with the client, and are seated again on the other side. The
lobby's player limit counts them as it counts everybody, see 9.6.

**Up to eight.** A room online takes up to eight players from several machines, and never more
than four at any one of them, see 9.2. The host's Player limit, below, runs from 2 to 8 and
starts at 4, so nobody hosting for the first time puts eight karts on a map drawn for four
without asking for it; after that it starts where the host last left it, as it always has. The
arena has as many seats as that limit, and never fewer than four: a lobby for two still has four
seats, the two nobody else may take there for bots, and a lobby for eight holds eight karts. How many of them are bots is the match
settings' to say, 3.8, from none up, so two people can play each other with no bots at all. On
one machine with nobody connected nothing changes: four seats, bots up to three. The host
counts the seats each machine asks for and turns a fifth down whatever that machine says, with
the notice a fifth player at the host gets, so a client cannot take a room by asking for all of
it.

Games hosted at a player's machine are LAN games, the LAN tab of Play Online, 9.3a: one way in to
playing with other machines from the title rather than one for each kind of host. Play Online's
tabs, Servers and LAN, and in a Steam build Steam friends first, 10.8, stand on the top edge of the
box of the page showing, in from the notch of its corner: the tab showing cut from the well's own
dark with a strip of foil along its top, so tab and box read as one piece, the others recessed
beside it. A click or the page keys turn them, the one last turned to is kept for next time, and
coming back from a LAN game that turned the player away comes back to LAN. Until 2026-10-16 LAN
games was a screen of its own behind a button under the servers. The LAN tab finds the games on
the network by itself and lists every game that answers, in the box
every list of games and servers is shown in: a well sunk into the screen, darker than it, with a
shade along its inside top edge and a faint rim, under a small gray heading, "Games on your
network", with room for about five rows whether or not there are any, which scrolls once there are
more. Empty, it still marks the list off from the buttons under it. Under the last row is a link
to put something on the list, centered and scrolling with the rows, with room round it to make it
about as tall as a row, underlined words in gold with a gold rim under the cursor, which a click or the cursor presses: Host a game here, Add a server on
Play Online and Make a game on a server's games, each the same as its button under the box, but
where the eye already is when it finds the list wanting. An empty list is the link alone at its
top, where it once said it was empty, "No servers yet" and the like, which is the same thing said
as something to do about it. Sunk in rather than raised: the
game's gold-barred pane, tried first, read as a dialog box come up over the screen rather than a
part of it. A row each: a
button with the game's name on it, over a smaller line in gray saying whether it is in the lobby
or which map it is on, "Playing Crossfire, map 2 of 3", how many play in it of how many may, and
whether it wants a password, which joins it, and an eye beside it, which watches it instead, see 10.3, "Watch" its tooltip: a word
on every row beside the words of the row is one more word to read, and the eye is the same on all
of them. The eye cannot be pressed on a game whose host lets nobody watch. A pointer resting on a
game's row says where it is hosted, "Host:" and its address and port. A game on a version this one cannot play says which version
it is on and neither can be pressed, its words dimmed with them. A game's name is the one its host
gave it in Lobby settings, see 9.6, and with none it is whose it is, "Ann's game", by the name of
whoever has the host's say, so it follows the say as it passes. A name is up to 32 characters on
one line, cleaned the way a player's name is, and a name or a line too long for its row ends in an
ellipsis. The rows go in the lobby first, then by name. A host on an older version that says no
name and no map is listed by whose it is and "Playing". A game hosted by a test, in the unit tests or the
multiplayer check, says it is one, "(test)" after its name or "Test game" for one with none, since
it answers anybody on the network who looks, its developer's own game among them; the server check
names its server and its game "Server check (test)". The list is made again as games come, go and change, and a
pad's cursor stays on the button it was on. Finding is asking rather than being called to: about once a second the screen asks on
port 7779 of every machine the network reaches, and of its own, which a broadcast does not always
reach, and a host answers from there to whoever asked. That is what lets several copies of the
game on one machine all look at once; only the host needs the port to itself, and a second host
on the same machine is reached by its address. A game that stops answering drops off the list
after a few seconds. Under the box, side by side and as wide as it together, Host a game hosts
one at this machine, on port 7777, and Direct connect asks for an address and a port, with Join,
Watch and Cancel, for a game the asking does not reach: another network, or a router that keeps
broadcasts in. It asks in a dialog over the list laid out the way the match settings are, see 9.6:
a shade over the screen, the game's pane in the middle with its title in gold and a line under it
in gray, a row each for the boxes, a line in red for what is wrong with them, and the buttons in a
row under them; the cursor goes round the boxes and the buttons and never off the dialog. Back, or
B, or Cancel puts it away, and Back from the list goes to Play Online. The address and port joined
last are in the boxes again next time. Every box for an address, here and for a server in Play
Online, gets a phone's keyboard for addresses, which puts no space after a dot the way its keyboard
for words did, and a space typed into one is dropped, since no host has one; a box for a port gets
the keyboard of digits. `MenuTheme.host_field`.

Joining says so while it is tried: Connecting to the address and port, on a pane over the room,
until the host answers. An address nobody answers at is given up on after a few seconds rather
than the half a minute ENet waits by itself, and the pane says it could not connect before the
title comes back; once connected the connection has its usual patience again. The pane is under
the pause menu, so Escape while it is tried opens the menu over it, to leave by; the pane saying
it could not connect is over the menu, since the room goes once it has been read. The lobby room is
never shown the match's own lobby panel, which is for a match held on its grid.

Somebody can join to watch instead of to play: the eye beside a found game's row, or Watch beside
Join under Direct connect's boxes. They
say so in the handshake, and the host lets them in even with every seat taken, up to four of
them on top of the clients who play; a fifth is told as many are watching as the match
can take. A watcher is never given a seat or a kart and nothing it sends is heard: it is sent
the rules, the run and the snapshots of the room the host is in, follows the host from room
to room as everybody does and is let in again in each, and the camera frames the karts as it
does for anybody. Nobody waits for a watcher: not the ready pad, not the lamps of a map held
for everybody still building it, and not a pause, which the room agrees without them. The line
under the ready count says they are watching, in place of the one that says how to take a seat,
since there is no seat for them to take. Nor is there anything for them to press: a map's
podium scrolls on to how the run stands, the page under it, by itself after six seconds, the
finale first after the last map, and the host still decides when the next map starts. It does so
the once: a watcher who goes back up to the map's podium is looking at it, and it stays. A bar
along the foot of the arrow down, or of Continue after the last map, fills over those six seconds,
so it going on is no surprise, and is seen where it will happen.

The host names the game and says who may come in. Lobby settings, on the host's pause menu over
Manage players, comes up in place of the menu with five things on it. Game name, first, is what
the lists of games call it, see 9.3: empty to start with, and the box says the name an empty one
gives, "Ann's game"; it is given once the box is left, with Enter or Back, rather than at every
letter, since at a dedicated server each change goes over the wire and into the server's log. The
cursor starts on the next, Player limit, the most players the game
takes, 2 to 8 with the host's own players counted, 4 to start with; a password, none to start with; Allow
watchers, on to start with; and Watch without password, off, which lets somebody who has come to
watch in without the password while anybody who has come to play is still asked for it. Somebody
watching can only look, so a host may well keep its seats to the people it told and let anybody
look. With watchers not allowed the last is moot and grayed. All five are the door's and change
at once; none shows anybody out who is already in, the last four answer the next knock. A player past the
number is told the match is full, and somebody watching takes no seat and is let in whatever it
is; with watchers not allowed they are told the game is not open to watchers. The name, the number
and the two about watchers are kept for next time. The password is kept for as long as the game is
hosted and no longer, so one forgotten never locks a later lobby without anybody knowing.

A client knocks with its version, whether it has come to watch, its name and the password it was
given, which to start with is none. A host with a password that is given none says so and
nothing else is wrong: the client is asked for it rather than sent back, on a pane of its own on
the loading screen's dark that says the game needs a password. Join knocks again with what was
typed, on a connection of its own: the one turned away is done with, and a room that thought it
was still talking to the host would sit in an empty lobby. A wrong one goes back to LAN games,
which says the password was wrong, with Direct connect's boxes up holding the address it knocked at
and the cursor on Join; so does Back, or B, which says nothing, since nothing went wrong.

The host can show anybody out. Manage players, on the host's pause menu wherever the room is,
comes up in place of the menu: everybody in the game as a seat card of 8.1a, the host's own
players first, rimmed in foil, marked Me and with nothing beside them, then each other player by
the name of their seat, its chip in their color with their seat's number, and each watcher by the
name the host gave them on a gray chip, with Kick beside every one of those. Every player
has the plate on their kart beside the name, see 4.4, or before a license the learner's L itself
rather than a plate reading L, so the host can tell two Bobs apart; somebody watching has no kart
and the room a plate would take. A client with
two players at it is two rows: Kick on one of them takes that player's seat and leaves the
client playing with the other, and Kick on the last shows the client out. A room of eight and
its watchers is a dozen rows, so where they do not fit on the screen they scroll between the
title and Back, the row with the cursor kept in sight. Kick asks first, in place of the list,
"Kick Bob?", saying they go back to the title, or the server's games, and can join again; Back
is no, and the list again with the cursor on that Kick.
Somebody kicked is told the host removed them from the game, on the pane a refusal comes up on,
and goes back to the title from it; the host lets go of the connection half a second later
whatever they do with that, so nobody stays by not listening. They may join again. Their seat
goes the way a seat does when anybody leaves: emptied in the waiting room, a bot's on a map.

A window in the background keeps playing. A window the desktop has stopped
drawing can hold the main loop up on the frame it is waiting to present, and on
the host that is the whole room frozen until somebody clicks back into the game.
While a machine is in an online room an unfocused window stops waiting for the
desktop and runs free at 60 frames a second instead, and is given back whatever
it had the moment it comes back.

### 9.3a A dedicated server

A LAN game has one of the players host: their machine runs the match and everybody else connects
to it. That is the right thing on a LAN and a poor one over the internet, where the host's router
has to be told to let everybody in and the whole game goes when the host does. So a game can also
be hosted on a dedicated server: the game run headless on a machine of its own, with nobody
playing at it, holding as many games at once as it is set up for. Players connect to the server,
and each makes a game there or joins one somebody else made. LAN games stay as they are, for a
game hosted at one of the players' own machines.

**A game with nobody at the host.** A game of the server is hosted the way a player's machine
hosts one, the waiting room of 9.6 and the arena after it, with nobody at it: no seat, no HUD, no
camera anybody looks at, and nobody finding it on the network by asking, since the server lists
it. Every seat is for somebody at another machine, so every one of up to eight can go to a
client where a host with a player of its own keeps one for them, and watchers on top of them as
before. It has no pause menu to ask
with, so the room stops once every player in it asks, see 3.8, and nobody waits on the host.

**The host's say.** Nobody at the server can choose a match, answer the door or show anybody
out, so a player at another machine has the host's say instead: whoever made the game, since
they are the first to sit down in it, and when they leave, whoever has been in it the longest
since, who is told they are the host now. Somebody watching never has it. It is the whole of what
a host decides, from the same menus: Lobby settings and then the match settings as the room
opens, the match settings again back from a match and from the pause menu, Manage players, Pause
game and Back to lobby there, and Next map, Rematch and Back to lobby on the podium. None of it is
done at their machine. It is asked of the server, which does it for everybody, the one who asked
among them, and which takes it only from the player with the say and only as far as those menus
could have said it: a map that is not one, a number of bots no row offers or a kick of their own
seat is not heard. The deck the game deals and its later items are theirs too, from their loyalty
program, 8.9, taken as each map starts, so the say handed on hands them on from the next map. While they choose the match their karts wait where they are, sent nothing to
drive on, and the room does not go. Their Manage players lists everybody else, with their own
players as Me; the players at one client share its say. It can be handed on, too: beside Kick on
the row of everybody else who plays is Make host, which asks first, "Make Bob the host?", as Kick
does, and on yes gives that player the say at once and takes it from whoever pressed it, whose
host's panes close. They are told who made them the host.
Somebody watching has none, having no say to be given, and nor does a LAN game's Manage players,
whose host is the machine the game runs on.

**Play Online.** The title's way to playing with other machines, in two screens. The first is the
player's own servers, in the box of 9.3 headed "Your servers", a row each for the dedicated
servers they keep: on its left a grip, six dots, that it is moved up and down the list by; a
button with the server's name over its address and port, the address smaller and in gray since
the name is what the player gave it to be known by, which connects to it; and beside it, each a
button with a picture and its word for a tooltip: a pencil,
Edit, which opens the dialog of Add a server with the server in its boxes, headed "Edit a server",
whose Save changes it in its place on the list, and says "That server is on your list already" for
one made into another server it keeps; and a trash can, "Remove", which asks first, "Remove this
server?", with Remove and Keep. The order is the player's, kept with the list. Connected to, a
kept server keeps the name the server gives itself, see The server below, and shows it: as its
name on the row for one the player gave none, and on the smaller line before its address, "Friday
Night Karts · 1.2.3.4:7777", for one they did. The server's games screen has it for its title, and
the lobby of one of its games names it. Edited into another server, a kept one forgets it until it
is connected to again. A mouse or a
finger drags a row by its grip, "Drag to move" its tooltip, the other rows making way as it goes,
and it is kept where it is let go; the box scrolls while it is held at the box's top or bottom
edge. The grip takes the cursor too, for a pad or the keyboard: accept, A or Enter, picks the row
up, rimmed in gold from end to end and its dots an arrow up and down; up and down move it a place
at a time, held to repeat, the stick a place a push, and accept or Back, B or Escape, puts it
down, as does the cursor going anywhere else. While it is picked up nothing takes the cursor off
the grip. The up and down arrows there were before it moved a server a press at a time, two
buttons a row for one thing to do. The list is empty to start
with, the box holding only its link, Add a server, and keeps up to 20. Under it, side by side as LAN games' are,
Add a server and Direct connect; LAN games is the next tab, see 9.3. Add a server and Direct connect ask for the
server's address and its port, 7777 to start with, in the dialog LAN games asks in, and Add a
server for a name too, which may be left empty for its address to stand for it: Add keeps it and
closes the dialog onto the list with the cursor on it, a server already on the list renamed rather
than kept twice, and Connect connects without keeping it. Only an address is taken, here and in LAN
games' dialog: an IPv4 or IPv6 address, the latter with or without its square brackets, or a host
name, its labels of letters, digits and hyphens, none over 63 long nor starting or ending with a
hyphen, and not all digits, which is an IPv4 address or nothing. Anything else is said in the
dialog's red line, and an address with its port on the end is told the port has a box of its
own. A kept server in a settings file that is not one is left out of the list. Back, or B, or Cancel puts the dialog
away, and Back from the list goes to the title. A server is connected to the way it always was,
said in a dialog of the same look: "Connecting", "Connecting to" its address and port, and a bar
that eases along over the five seconds a server is given to answer, filling once it has; Cancel,
or Back, hangs up. It goes on to the second screen once the server has let this machine in, or
says why not in the same dialog, "Could not connect" over the reason in red with OK: nobody
answered, the server is on a version this one cannot play, or it is a LAN game. Whether to play or
to watch is chosen on the second, game by game, since a server holds several. The list, the
server connected to last, and the address and port a LAN game was joined at are the player's,
not the machine's: they go with the player's profile. The second, titled with the name the
server's owner gave it, or Games for a server with none, lists the server's games
the way LAN games lists the games on the network, in the same box, headed "Games on this server"
and with Make a game as its link,
a row each the way LAN games has them, the game's name over how it stands, which joins it, with
the eye beside it, and Make a game under them. A game made on a server is named the way a hosted
one is, by its maker in Lobby settings, which start from the name the maker last gave, and anybody
the host's say passes to can change it. Over the box it says which server it is and what to do there, "Connected to" its address
and port, "Join a game on this server, or make one now." On all
three screens everything down the middle is as wide as the box: the lines of words wrap inside it
rather than widening the column, and the buttons and Back fill it. Make a game asks the server for one, says it is making it in a dialog with a bar that
fills as the server starts the game's process, the process starts up and its waiting room is built
a phase at a time, see 8.6, the bar weighted by how long each takes, and once it is up goes into its
lobby, where the maker has the host's say and sets it up the way a host does, see 9.6: Lobby
settings first, then the match. Join and the eye go into a game's lobby the way joining a LAN game
does, the password asked for there if it has one. Back hangs up and goes back to the first
screen, and so does the server going away, saying so. Back from one of its games, over, shown out
of it, or with a wrong password or none, the first screen connects to the server again by itself,
kept or not, and goes straight on to its games, which say why. Anybody in the game's lobby is told
where friends find it, in Play Online on the server, by the name it gives itself if it gives one,
at its address, "Friends find this game in Play Online, on Friday Night Karts at 1.2.3.4:7777", in
place of the line saying which port to join a LAN host on.
A server and a LAN game are both found on 7777, so each says which it is at the door: LAN games
knocking at a server is told it is a dedicated server whose games are in Play Online, and Play
Online knocking at a LAN game, or at one of a server's games by its own port, that it is a game to
join from LAN games. Neither is let in to wait for something that never comes.

**The server.** It is the game itself, exported for Linux as a server build of its own,
`jackpot-junction-server`, in every release, see 10.5: started with no arguments at all, it is
headless and a server, and it carries no sound and only the sizes of its pictures and models,
about 75 MB against the game's 95. The game proper is a server too, started headless with
`--server` after `--`: `./jackpot-junction --headless -- --server`, or `make server` from a
checkout. Linux is what it is made for and tried on. It listens on port 7777, the port a LAN
game is hosted on, unless given `--port`, so a LAN game on the same machine takes another one, and
holds up to 8 games at once unless given `--games`, on the ports after its own: 7778 to 7785 to
start with, so a server behind a router has 7777 to 7785 let through for UDP. `--game-ports=9000-9015`
puts the games on a stretch of ports of its own instead, as many games as it has room for, still no
more than 8 at once unless `--games` says more. `--name="Friday night"` gives it a name, which
players see over its games and the log says as it opens; up to 32 characters, cleaned the way a
game's is, and with none it is known by its address. `--password=...` keeps it to the people told:
Play Online connecting to it asks for the password in a dialog over the screen, the server's name
in its line, "Friday Night Karts needs a password.", with a box that hides what is typed, Connect
and Cancel. Nobody sees its games or makes one without it: a wrong one comes back to the dialog
with "Wrong password" in red under the box, and an empty one is asked for again. The one it let
the player in with is kept with the server on their list, or for the rest of the run for a server
they did not keep, so coming back from one of its games, or to it later, does not ask again; one
the server has since changed is asked for afresh. Its games ask for it too, at their own ports, of
anybody knocking there, which a player who came by its list has given already and somebody trying
the ports never has: they are turned away, "This server has a password: join its games from Play
Online", and are not asked for the lobby's password either. The server hands it to its games in
the environment it starts them in rather than on their command lines, which anybody on the
machine can list. Each of the five may be set in the environment instead, `JJ_PORT`, `JJ_GAMES`,
`JJ_GAME_PORTS`, `JJ_NAME` and `JJ_PASSWORD`, the way a container is set up, with the command line
having the last word over the environment. Each game is a process
of its own, the game started again headless as a host with nobody at it, from the waiting room on: a
game is the whole game, its event bus and everything else it keeps among it, and two in one process
would hear each other's every kill. That costs about a quarter of a gigabyte and a small part of a
core a game. As it starts the server says where it listens: every address of its machine, the ones
anybody else can reach it on listed. The server starts a game when somebody asks for one and tells them its port once it is
up, lists it while anybody plays in it, and forgets it once its process has ended. A game ends
itself once everybody who was playing in it has left, telling anybody still watching that it is
over; once nobody has come to it in half a minute; or once it has heard nothing from the server for
ten seconds, since a server that has gone has taken its list with it. The server stops a game that
never says it is up, or says nothing for ten seconds.

**Idle.** A server nobody plays on is little more than the engine: about 90 MB and next to no
processor, and no game's process runs until somebody makes a game. The game's own autoloads, its
settings, sound, events and connection, bring nearly all of the game in with them, over a hundred
megabytes of it, so the hall is started without them: the game's main loop is a scene tree of its
own, `GameTree`, which drops them before they load when the game is started with `--server` and no
game to run, and the first scene is a boot scene, which goes on to the title, the hall or a game,
rather than the title, which would bring the game in by itself. The hall names nothing of the game,
since whatever it names it loads, and it runs ten frames a second with its physics off.

**The log.** The server writes a line to its output for everything worth knowing, with the date,
the time and which game it was: the server opening, and that it asks for a password; who is asked for it, and who gave a wrong one
and from where; who comes to look at the games and leaves the
list; who made which game, on which port; each game up; who came in to play or to watch and from
where; who was turned away at the door and why; who has the host's say; Lobby settings changed,
with the game's name;
somebody shown out; the next match chosen; each room the game goes into, the lobby or a map; play
starting, with everybody in it; Last call and Overtime; the results in order with what each player
banked; and the end of each game and why. A game's own output is kept quiet and its lines come to
the server to be written with the rest, so there is one log to read; an error a game raises still
reaches it.

### 9.4 The Garage

A practice room reached from the title screen's Clubhouse, before anybody starts a
real match. It is set in The Garage of 8.1, which both practice rooms share: a
concrete bay in the place the karts are fixed in, with the trade's own clutter
round the walls of it. Nobody watches in here, so the band of floor the stands
would stand on is filled with what a garage has in it instead of left bare. Nobody is playing against you in it: no bots, no clock, no score to
protect, only two dummy karts standing about to be shot at. It
runs an ordinary match on its own map with the timer switched off, so nothing
ever ends and the player can take as long as they like. There is no countdown
either, so no start gantry, no start tones and no flag: the player is let out onto
the floor rather than held on a grid for a race that is not being run.

```
################################
#.R..R..R......................#
#...................D..........#
#..............S.......S...S...#
#.P.....P......................#
#.........F..........F.........#
#BB.....................KK.....#
#BB...........JJJJ......KK.....#
#....XX.......JJJJ.............#
#....XX.......JJJJ.............#
#BB...........JJJJ.............#
#BB............................#
#.........F..........F....$....#
#.>..C..C..............C..C..<.#
#..............................#
#............................S.#
#..............................#
################################
```

It is no longer the place the game is taught in, which is the driving school's job,
9.4a, but a floor to try a kart out on, so the middle of it is left open and what
there is to do stands round the walls. Nothing in here has a sign over it: the
labels that once floated over the Junction, the Jackpot, the jokers and the dummies
made a room to be read rather than driven. What each part of the floor is for is
painted on it instead, in the lift's yellow and the room's marking white, and the
only words on it are painted too: FIRING LINE, the dummies' bay numbers and the
lift's.

- The Junction in the middle of the open floor, with two rings painted round it to
  drive and drift round: the outer one runs through the four Royal Flush pads, so
  a lap of it takes all four, and the inner one is dashed. The marks of laps karts
  have driven round them lie between, old marks that never fade, drawn as a kart's
  own are, 4.3. Six traffic cones stand just outside the outer ring, three over its
  top and three under its foot: a kart that clips one knocks it over and away, and it
  is stood back up where it was a few seconds later. A cone is knocked, never hit,
  and stops nobody.
- A range at the back left: three shooting targets that pay coins, see 6.2, each
  at the top of a lane painted down from the back wall, a firing line across their
  foot, and two item pads at the firing line carrying the full item set rather than
  the first set.
- Two dummy karts parked at the back right, each backed into a bay of its own,
  numbered 1 and 2 on the floor, and facing out into the room. Nobody is driving
  them, so they never move and never shoot back. Each one carries a pot of coins
  with a mult on it and an item in the boot, so a kill scatters chips and often
  drops the item, and each comes back to its own bay after the usual respawn delay
  carrying something new, rather than at the spawn farthest from the player.
- A joker pad between the door and the bays that keeps a joker lying on it, so
  jokers can be tried out, kept, dropped and destroyed without dying for them.
- A pit on the left between two stacks of crates, painted round with yellow
  stripes. Driving into it is the quick way to a respawn and the joker pick that
  comes with one, 3.7. The Jackpot zone stands across the rings from it, over the
  way in to the rolling road, and a slot machine, 3.15, over the right end of the
  straight.
- A straight across the front of the rings with a turbo pad at either end pointing
  at the other, and four coin pads on it to be launched through.
- The tests of a kart, on the right. A rolling road against the right wall, level
  with the Junction: a bay with a cradle of steel rollers set in its floor, DYNO
  painted at its open end, and a low fence of steel posts and yellow rails down
  either side, which stops a kart as a wall does, so the one way in is from the
  room. A kart driven onto the rollers nose first toward the wall rolls on at the
  speed it came in at, braking into place and squaring up as it goes, is strapped
  down there, four orange straps let out one after the next from ratchets on the
  floor beside the bay to its corners and wound back in as it is let go, and is held
  there, its wheels turning the rollers, running up to whatever top speed its motor
  reaches with the throttle held, nitro and jokers and all; backing off the rollers
  lets it go, and it is not taken onto them again until it has left the bay.
  A speed trap across the straight's right half: a checkered timing strip between
  two timing posts with a red beam between their lamps, from the straight down
  toward the front wall, which takes the speed of a kart driven over it either way,
  says it over the strip and flashes the lamps.
  Both are read off the test bench, a board bolted to a scaffold of its own on the
  floor out past the right wall, a little back from the rolling road so the kart on it
  is never behind it, over the wall and turned to the camera, the clutter round the
  room kept off its floor: a round dial with its needle on the rolling road's speed
  and a red tell-tale left at the best of the visit, and beside it in segment digits,
  as the match clock's, the rolling road's speed now, the trap's last and best, and
  the longest drift anybody held, in seconds to the tenth. Speeds are in the HUD's
  units. A close look at the board comes up at the left of the screen, away from the
  rolling road, the way the Showroom's comes up for its kart, 8.9: while a kart is on
  the rollers, titled Dyno and saying how to leave them, and for four seconds
  after it is let go, with its best, or after a kart goes through the trap, titled
  Speed trap with its speed and whether it is the best yet. The camera films the
  board from in front, easing in on it, and its picture is a camera's feed as the
  Showroom's is, CAM 1, but a security camera's, a faint cool green, the turn from the
  rolling road to the trap tearing it, and a new best on either jolting it hard.
- The rail is the workshop's too. The slot machines the floor's slot machine puts on
  the far rail, 3.15, are in for repair, and still light up for a big cash-out: one
  stands with its door swung open and its insides showing, a red toolbox beside it,
  another has an OUT OF ORDER card taped over its reels, and a screwdriver lies by a
  third. A workshop clock hangs beside the Showroom's door, stopped, its glass
  cracked, in the one room with no clock to keep. The tools hang on a pegboard on the
  rail behind the range, each over its painted outline, one outline empty.
- The player starts on the floor between the rings at their top, a little in front
  of the Showroom's door and facing the Junction, and a second player in the front
  right corner. A spawn's turn comes in reading order, so the dummies stand level
  with the player's start rather than above it.
- Pressing join brings a second player in on another device, the same as in a
  match, and takes an empty seat rather than one of the dummies. Pausing leads
  back to the title.
- Nitro comes back 25 times as fast as it does in a match: a tank in a few
  seconds rather than a minute and a half. The scarcity in 4.1 is a rule about
  matches, and a room for finding out what the button does is the one place it
  gets in the way.
- The camera holds the bay tighter than it holds an arena. It frames the players'
  karts and not the dummies, which stand parked in their bays, with one meter of
  floor round them instead of four: that band is the room a crowd sits in, and there
  is no crowd in here to look at, so the karts may as well be bigger.
- The disco lights from 8.1 stay off in here: it is a place to look at the
  controls, not a nightclub.
- No standings either: there is no clock and nothing to reach, so a table of who
  is ahead would be a table about nothing, with two dummies ranked in it.
- No way to the driving school of 9.4a from in here: that is the title's Driving
  School, and the school's end leads here.
- A roller door in the back wall stays shut until the loyalty program of 8.9 opens the
  Showroom behind it: a bay with a turntable for looking at a kart from all round.
- The kart is dressed on the lift, along the front wall under the left of the room
  and well off the side wall: a bay
  marked out in the room's yellow between the red posts of a two-post lift, its arms
  folded in along the floor, YOUR KART painted big on its floor in the same yellow
  with STOP HERE under it, as a parking bay has its words. A player here who stops their kart
  in it has the kart dialog of 4.4a put up on their seat's tab, the room standing
  still under it as under the pause menu; the kart has to leave the bay before
  stopping in it puts it up again, and the bay's lines light in the color of whoever
  is in it. The pause menu has Customize kart too. There are no stalls in here; the
  lobby keeps its own.

### 9.4a The tutorial

A short, playable lesson in how to drive and what the game is, dressed as a driving school, with
a driver license at the end of it. A new player is brought to it: the invitation of STORY.md 6.1a
promises a free lesson on its stub, and accepting it opens the school's first page rather than the
title. After that the title's Driving School button opens it, and every way in to driving, Play,
Play Online and the Garage, asks for the license first, every time until it is earned: "Missing
license", with Earn it now, which is the school, and Drive anyway, which is the way in asked for.
With the story of 8.7 off there is no invitation, and nothing sends a player here but that
question and the button. Half a minute of school, then about three minutes of driving test for
somebody new, less for somebody quick, and room for somebody who wants to try things out, since
nothing hurries a player on. One player at this machine, no join, nothing online; the license
screen leads on to the Garage and the road, so going round once locks nothing away. Finishing it is
remembered in the settings, and so are the license's number and date; leaving starts over from
the first lesson, since nothing in the middle is saved.

**Skipping, and the settings.** The school can be left at any moment, and its settings reached
from its very first page, so a player whose music is too loud, whose screen is wrong or whose keys
act up puts it right before going on. On a page of the school, Escape or B, Start on a pad, or
on a touch screen the menu button in the top right corner, as a room has it, 4.2, opens the
school's menu over the page, the page held still under it so the book stops reading:
Resume, with the cursor, Settings, which is the settings screen of 8.5 over the page, as a room's
pause menu has it, and Skip driving school. In the test the room's pause menu has Skip lesson,
gone from the final exam on, and Skip driving school where a room has Back to title. Skip driving
school asks first, in the school and in the test alike: "Skip the driving school?", "Earn your
license any time from the title's Driving School button.", with Skip, which is the title, and
Stay, which has the cursor; Back again is Stay.

**The driving school.** Two pages over the title's own turning background, before the test, each
in the middle of the screen at its own size, or shrunk all over to fit where a big UI scale on a
short screen leaves no room for it, so nothing of a page is out of sight.

The enrollment: the game's mark and name with DRIVING SCHOOL under them, "Nobody drives the
Junction without a license. Earn yours.", and, come straight from the invitation, the stub's own
line over it, "Free lesson included."; a box for the name that goes on the license, which starts
with the first seat's name or with one off the funny list of 3.8 for a seat that never gave one,
and is the first seat's name from here on and the license holder's once the test is passed, a
retake's as well; the course in three numbered steps, driving theory, driving test, your license;
one big button, Enroll, and Enter in the box enrolls too; and under it a smaller one, Straight to
the exam, for a player who can drive already, which goes straight to the final exam, no book and
no lessons before it, once a question has made sure: "Straight to the exam?", the cursor on
staying for the course, which Back answers too. Under the buttons one line of small print, "Enrolling accepts the terms of the
Dept. of Karts.", the first of the terms the story of 8.7 counts, STORY.md 6.7. While the story is
on, a tick box sits over the Enroll button, a little air between them, "I will come back after I
lose.", empty as the page comes up; a moment after the page has opened it ticks itself in the
house's gold, with "Answered for you." beside it in gold, STORY.md 6.7. It is no part of
enrolling, and pressing it does nothing.

The page opens the way the title does, 8.1a, every time it comes up and not once a run: the mark
large in the middle and up into its place, then the name, DRIVING SCHOOL and the pane rising in one
after another, and the pane's rows after them, the box, the buttons and the small print last, in
about two seconds. Any key, button, click or tap goes straight to the end, and is spent on that
rather than also pressing Enroll. It is not the title's: the title still opens its own way the
first time it comes up. On a short screen at a big UI scale the page is shrunk to fit as above,
the opening with it.

The theory: the Highway Code of the Junction, 212th edition, an edition that goes up with the story
of 8.7 on its title page, running head and covers alike, a handful of its lines turning darker as
it does, STORY.md 6.7, a book in a leather cover with a spine and the edges of its leaves showing,
open at a spread of two cream pages with a running head over each and its page number in the
outer corner. It comes up shut on the right, its spine to the left as a shut book lies, and waits
to be opened, by a click or a tap on it or the accept button, drawn on its bottom right corner for
the device in hand, its cover lifting a little off the pages now and then as if about to open, so
it reads as a book to open. Beside it, on the left half it will open onto, "Read carefully." in
the gold of a heading over "There will be questions." in gray, inside the book's own room so
nothing moves when it goes. It fades as the book opens. Opened, the front cover lifting off it
toward the spine and coming down over it onto the left, a rustle each, the other way from the way
it shuts at the end, it lies on its title page, the game's mark and name over the book's own and
its edition, with the first rule on the page across from it, and waits again, the same control
drawn on the right page's bottom corner, until it is clicked, tapped or accepted once more. Then
its pages turn by themselves: the first leaf at once, each next one sooner, until they riffle past
twenty a second and the page numbers race to the 212th; then the riffle slows over its last
moments, the page numbers counting on a spread a leaf, every leaf down before the next comes up,
all of it planned before the first so none is put down mid-air, about three seconds from the
second click to the end of the book. The text is cut into pages with nothing cut across two and no
chapter heading left at the foot of one, and drawn from a seeded generator so it reads the same
every time: chapters numbered in Roman numerals, Oversight, whose one section, § 1, "Every table is
watched.", opens on the clause § 1.1, "No table shall open without human oversight.", in the book
with the story or without it, STORY.md 6.7, then The kart, Signs and markings, Chips and pots, Pads
and the mult, Handling, Items, Jokers, Hazards, Bots, Emotes, Bounties, Overtime and Examinations,
each of sections numbered on through the book, long enough for a whole read without coming round
again, each section a rule in bold with three to seven clauses of filler under it, § 3.1, § 3.2
and on, and figures falling among the clauses where they will, numbered as they come, the speed
limit, karts crossing, a Jackpot, the Junction, a Royal Flush, a mult die, a drift, a pit, a
roundabout. A leaf at a time lifts off the right page about the spine and comes over onto the left
in perspective, growing a little as it comes up and going a shade darker as it turns from the
light, a soft sheen running across the paper and a shade where it bends at the spine, its front
the page it was and its back the next left page, each turn a soft rustle, softer and a touch
higher as the pages race. The last leaf comes over onto the end of the book, pages 211 and 212: the
next page of the text, whichever it is, nothing skipped, and across from it Final provisions, a
chapter of its own numbered on from that page's, "This concludes the Highway Code of the
Junction.", the holder now being fully informed and to be asked about it, THE END, and the
printer's note, "No karts were harmed in the making of this book. Most were merely
inconvenienced." That stands a moment and the book shuts, a breath, the right half swinging over
onto the left on the spine, the front cover coming down over it, the back of the book, tooled
leather like the front but with the publisher's word on the book, what three readers said of it,
"Impossible to put down. It shuts itself." the Examiner's, a barcode on a cream label and the
price, 212 chips, where the front has the book's name in gilt, with a thud and a puff of dust off
its edges; and, the shut book standing a moment, "Got that?" beside it where the right page was,
with Absolutely and Not a word, either of which goes on to the test. That is the question the book
promised, and the only one: the pop quiz that once followed the book is gone. Nothing under the
pages says how fast it is going: the pages say it.

**The test ground.** One open lot the size of a regular map, 6.3, its long side across the
screen, walled as a table is, with nothing on its floor at first but the start: the kart on its
spot in a corner, the two mode pads beside it, and the dressing round the edges. There are no
rooms, no gates and no corridors. Each lesson brings its own pieces into the lot where the arrow
points, and they stay once the lesson is done, so the lot fills as the test goes on and is a
table to play a match on by the final exam; each piece stands where a map's piece would, so the
lot never reads as a heap of lessons. The dressing is in boxes and cylinders of the room's own
materials that stand where a kart does not go, the edges of the floor and the tops of the walls:
road signs on poles planted in the wall tops, each plate standing in front of its pole rather than
round it, facing the camera, which looks north, so they read, an L by the start, a 30 over the long
run, the roundabout by the first ring of cones, karts crossing by the second, a P by the parked
kart's bay and FINAL EXAM on the south wall pointing into the middle; bunting in the players'
colors over the start; a zebra crossing painted over the lane of cones and a parking bay round the
parked kart; the cones each lesson lays out; and the examiner's booth on the north wall, a cabin with a lit window looking down into it and a pennant on a
pole either side. A cone is knocked over by a kart that hits it and lies where it falls, rolled a
little, for the rest of the test, and the license counts it, below. Four inspectors from the
Department of Karts watch the test: people built the way the crowd's are, 8.1, a third bigger, in
gray suits with a hi-vis vest over them, a pale band round it, and a clipboard held at the chest
with a pen over it, standing on the lot's walls. Each turns to keep its eyes on the learner's kart
wherever it is, and every few seconds one bows its head to the clipboard and writes something
down for a moment and a half, which is never said, and one always does as a cone goes over.
`SchoolInspectors`. The kart wears the learner's L on its rear bumper for the whole test, see 4.4.
The loading screen says Driving test, and the last lesson is the final exam. Nothing greets the
player at the start: the school did.

The camera follows from 26 m back, as the test track's did, since a lot framed whole puts the kart
too far away to see what a control did. A kart that dies comes back on the start, facing the way
the lot goes, or wherever the lesson under way puts it. Nothing here drops a joker on death, and
the picks never deal a Cursed card: a trap is no way to meet a mechanic. No disco, no crowd, no
hoardings, no clock and no standings, as in the Garage, and no bounty of 3.10: a price on a head
is a match's thing, and the rules have a switch for it.

**Pieces that rise.** Nothing of a lesson pops into the lot. Each piece is outlined on the floor
where it will stand, in the school's cyan, a moment before it comes, so the eye finds it; then a
piece that stands up, a cone, a target and its lamp, a box, a crate, a parked kart, a bot on its
lift, rises out of the floor, slowly, over about a second, with a low rumble, as
the house's racks do at the Final Hand, STORY.md 8.2, and is in play once it is up; a flat one, a
pad, a Jackpot, the Junction, drops out of the sky onto its outline, squashed a little as it lands
with a thud, a small bounce and a ring of dust round it. The jokers lesson's trench goes the other
way: it is outlined, the lid of floor over it drops away into it, and it comes back up once the
lesson is done; shut, the trench is floor to a kart and to the bots' map, its shaft out of sight.
A square pit of two cells by two, south of where the Junction will be, opens with the trench and
stays open for the rest of the test, for a player who wants another joker pick. A piece not yet come is not
seen and not in play: not processed, and out of the physics world with it, which is what a paused
body or area is. All of them are in the shader warm-up of 10.7, so none of them is a hitch the
first time it is seen.

**The clipboard.** The one place in the test with words in it. The examiner's clipboard: a board
covered in the table's green felt with a foil rim, a gold clip at its head riveted with a poker
chip, and clipped to it a sheet of the school's cream paper, 8.1a. The form is printed on it in
ink, DEPT. OF KARTS · DRIVING TEST over the lesson's name and a rule, a line under the name saying
what the lesson is about, and the lesson's tasks under that, one lesson at a time, each with the
control it takes drawn into it, the key, the pad button or the touch screen's button for the device
in hand. As the test starts, the board comes up large in the middle of the screen with the first
lesson's name, its line and its first task, holds there about a second and a half, nothing dimmed
and the kart free to drive, and then flies to the top right corner, shrinking as it goes, to stay
there, clear of the player's own corner on the left; driving sends it sooner. That happens once:
each lesson after is written in where the board hangs, and the board lands there as Next new's
finds do, 8.8: it comes up a little bigger out of its corner, toward the play, and settles back,
and two rings of foil cased in ink ripple out from it in its own shape and fade, running off the
screen's edges where the corner leaves them no room. The kill feed, which hangs there too, hangs under it while it is up.

A tick box is printed in ink, notched at its corners like the house's tickets, and ticked in the
examiner's red pen once done, the tick running past the box as a quick hand's does; a bar is the
dashboard's own, a row of slanted cells filled in red pen as far as the task has got, as the nitro
tank is. A task that is done is ticked and grayed with a short chime; the one being done is bright,
with a bar under it where it is a matter of how far, and a count's box stays empty until the count
is complete; tasks not yet reached are not shown, so the list grows as the lesson goes, and a task
that comes up while the lesson goes on is written in at the corner as the one before is ticked,
and that is all: the board lands for a new lesson only, not for a task ticked, the next coming up
or the line under the name changing, which the player is looking at already. An extra, the drift, is written a shade dimmer under Extra, and the lesson does not wait
for it. A lesson done is stamped PASSED in green with the driving test's rubber stamp in place of
its tasks for a second, under its name, and then the next lesson. On a touch screen it hangs from
the top as anywhere, and the touch controls are drawn over it, never it over them: the menu button
over its top right corner, and the right thumb's controls over its foot where a long list on a
small screen reaches down to them.

Nothing else in the test is written: no notice at the top of the screen, no words over the kart and
no words on the pointers at the HUD. The one line that is not a lesson's is for a joker pick, 3.7,
that opens on a hand already full: "Your hand is full. Replace a card or skip it.", written under
the lesson's name for as long as the pick is open.

In every line on the board the game's own words stand out from the words round them: a counter of
the HUD, chips, mult, pot, bank and banked, nitro and lives, bold in the color the HUD shows it in,
chips blue, mult red, the pot and the bank gold, the nitro amber and the lives the hearts' red; and
a place on the floor, the Jackpot, the Junction and a Royal Flush, bold in a green of its own. "Mult
will multiply your pot" then reads as the two things on the screen it is about rather than as a
sentence. A line marks them with braces, `{Mult}`, `Terms` draws them, and a line that is done
drops the colors with the rest of its ink.

**Over the kart.** The control for the task being done and nothing else: the key, the pad button
or the touch screen's button, half again as big as the drive and fire hint of 3.8, following a pad
picked up or a switch of driving mode. A task that needs no one control, holding the pads, reading the hand, banking at the Junction, has none. It is one
sprite redrawn as the task changes rather than a new one each time. An arrow on the floor ahead of
the kart pulses toward wherever the task needs the kart to go, when it needs it anywhere, with a
cyan ring on the floor round the spot itself, as big as what it marks, a pad's width round a pad
and a whole Jackpot round a Jackpot; within a few meters of the spot the arrow goes, and the ring
stays until the spot is reached. A task that needs the kart nowhere in particular, the nitro's, has
neither.

**The HUD comes in pieces.** At the start only the clipboard is on the screen, the player's corner
block not at all. Each piece of the corner block appears with the lesson it is for, framed by
corner brackets pulsing round it the way an inspector frames what is being looked at, and a ring
that starts as wide as the screen and shrinks onto it and away to nothing in a second, twice over,
which is what pulls the eye to it wherever it was looking, with no words: what it is, is the
clipboard's line. The brackets stay until the lesson's first task is done, or until a task the
lesson names: the nitro tank and the speedometer with the speed lesson; the item slot with the
first item picked up, until that item has done its piece; the lives with the jokers lesson, and the
hand with its first card, until the hand has been read, the brackets stepping aside while the hand
is open, when the cards still to read wear an eye each in the middle of the card; the pot with the
chips lesson, a shut padlock on the bank and an open one on the pot as the Junction comes, both
until the pot has been banked; and the mult pill with the final exam's dice. The corner's own
control hints stay off throughout: the clipboard and the control over the kart say it.

**Driving mode.** The tutorial does not ask how to drive up front. A player who has answered before
drives their way; one who never has is asked the question of 4.2 on the start, before the kart will
move, and the answer is kept. Two big lit pads lie beside the start, SIMPLE and ADVANCED, each a
disc with the way of driving's own picture on it, the one the question of 4.2 draws, its name under
the picture on the face itself, and a ring round it with a run of lamps round that. The one in use
is lit cyan, its lamps chasing; the other is plainly off, gray and unlit, its lamps dark, so there
is no mistaking which is on. Driving onto the other switches to it on the spot, and while the kart
is near them the clipboard says what they are and that the menu changes it any time. They go back
from the lot once the first lesson is done, shrinking away to nothing: the exam is played over
where they lay, and a switch of the way of driving in the middle of it would be nobody's choice.

The lessons, in order, each bringing its pieces into the one lot:

1. **Driving.** A lane of cones rises ahead of the start, up the west side of the lot, and a ring
   of cones at its head. Drive forward, a bar filling over ten meters driven, then go round the
   ring, a bar filling as the kart's heading turns a full circle either way, moving or standing,
   counted from where that task started, so sawing the wheel back and forth adds up to nothing. Simple driving is told to push
   the way to go. There is no lesson in reversing: letting go is the brake, and the controls card
   of 8.1 has reverse.
2. **Speed.** The long run along the north of the lot, with a ring of cones at its far end. The tank
   is filled as the lesson starts and comes back in seconds as it does in the Garage, 9.4, since
   the bottle is the lesson and not the wait for it. One task: burn a full tank, the bar showing how
   much of it has gone, done when it runs dry. The nitro tank and the speedometer appear in the
   corner. Under it, as an extra, drift round the cones: one drift held long enough for a turbo,
   0.6 s of drift at half speed or more, 4.1, ticks it, its line on the clipboard drawing the
   handbrake. The lesson does not wait for it.
3. **Shooting and an item.** Three targets rise along a wall, a lamp on a pole beside each, dark
   until the target is hit and green after. Hit each once. Then a box rises in the middle of the lot
   holding a Turret, with no roulette: pick it up, which brings the item slot into the corner, and
   drop it, the targets' lamps having gone dark again for it; it hits them, which it
   does when no kart is in reach, see 6.2, as every turret does while the tutorial runs and a
   match's never. A shot of the player's own at them counts for nothing then. A box taken with the
   Turret gone and the targets not all hit comes back after three seconds. Once all three are hit,
   the turret is taken down, so the parked kart of the next lesson is nobody's to shoot but the
   player's.
4. **Jokers.** A parked kart rises in its bay, facing the kart coming down from the targets, which
   never moves or shoots and goes down to
   one hit, for good, dropping a card, Magnet Hubcaps, since it helps with the chips straight after:
   shoot it and pick the card up, which brings the hand into the corner. Then the floor across the
   lot drops away, a trench from wall to wall between the kart and the far side, with the arrow
   across it: there is no way round it, and a kart that goes in dies and comes back on the far side,
   where the joker pick of 3.7 opens, for a second card; a pick skipped does the trench as well.
   Two cards in the hand, read each, with
   the hand's key held and the steering walking the hand on a keyboard or a pad, or a tap on each
   card on a touch screen, see 3.7, on a bar that fills a card at a time. The lives appear with the
   lesson. The trench closes once the hand is read, the square pit opened with it staying open, and
   from here on a death opens the pick, as it does in a match.
5. **Chips.** Four Royal Flush pads come down round the lot, each with at least two cells of floor
   between it and a wall, which pay whoever holds them and lock
   in for a flush, the pot appearing in the corner: hold every pad at once, the arrow and its ring
   on the nearest pad not yet the player's. Then a Jackpot comes up, full, which fills over time and
   pays whoever waits in it: drain it. Then the Junction comes up in the middle of the lot: bank the
   coins of the pot, all of them, the bar being how much of the most the pot held is in the bank,
   so the exam starts with nothing in hand and the points have to be earned in it. A pot emptied
   any other way, a death say, sends the player back to the Jackpot. The bank appears with the
   Junction. A joker that banks of its own accord, Direct Debit, 7.3, is held off until this
   lesson puts the Junction in the lot: banking before the player has seen what does it would teach
   the wrong thing. A flush is holding every pad of the lot, as on any map.
6. **The final exam.** The clipboard has the goal, bank 500, its bar filling as the points come,
   counted from the start of the exam, what a death banks of the pot, 3.6, counted with the rest;
   and under a rule seven hints, each a thing worth doing in a match, ticked on its own when it
   happens and all of them ticked with the goal: take out another kart, reach a mult of 4, drain a
   Jackpot, claim a Royal Flush, bank your whole pot at the Junction, use an item, hold three
   jokers. From the goal the match point of 3.4 is on, MATCH POINT called, the gold tracks and the
   burning pot, on a match point of the lot's own since the rules have no target to end on: the bank
   as the exam began plus the 500, reached by what is banked since and what the pot would bank, and
   never on an empty pot, which is the match's own rule too. Item pads, coin pads, crates, mult
   dice, which bring the mult pill into the corner, and a second Jackpot come up with forty chips
   over the floor to open with, and an easy bot comes up on a lift at the lot's edge, a second at
   250 held, banked since the exam began and the pot's worth together, so a player who never banks
   still meets it. A death is a respawn and a joker pick, a bot comes back at the lift farthest
   from the player, nobody else's
   banking counts against the player, and nobody can win the match itself. The exam is the one
   lesson the pause menu's Skip lesson does not pass: the entry is gone from the menu from the exam
   on, and the way out is to pass or to skip the school. Passing is a fanfare and the fireworks of
   8.3 over the lot in the player's color, the bots blown up where they stand, a bang each and the
   death a kart has, for good, with their bullets, their turrets and their decoys gone, so nothing
   of the exam shoots on or banks on, the settings remember it, and a couple of seconds after the
   bang the license comes up, below. A kart parked on the Junction with an empty pot finishes a
   cash-out of nothing every tick, which neither the chips lesson nor the exam's hint counts. Which
   of the seven hints were done on their own, before the goal ticked the rest, is kept for the
   license.

The pause menu's Skip lesson passes the lesson under way, its pieces rising at once. Straight to
the exam starts the kart on the start with every piece of the lot up, the trench closed and the
square pit open, the corner
block whole and the hand empty, the clipboard on the exam. A debug build's menu has Debug: skip to end
under Skip lesson besides, which drops whatever lesson is on and passes the test on the spot, with
nothing earned, to look at the end of it. The test's time runs from the kart's first move to the
goal ticked, and is kept with the best, for the license screen.

**The license.** Over the lot, with the kart held and the clipboard and the
pause menu gone, on the pane the podium is cut from with the player's color
along its top: YOU PASSED, "The examiner found nothing to object to. Your
license, then.", the course as a row of its three steps, each a number or a
green tick with its name beside it, the theory ticked, the driving test ticking
as the pane comes up and the license as the stamp comes down, and the card. The card is the shape of one in a wallet, 560 by
352, drawn as every picture in the game is, 8.3a: cream paper, darker toward
the foot, with the fine curves of a banknote and the four suits as a watermark;
a dark band along the top with the game's mark, JACKPOT JUNCTION · DEPT. OF
KARTS in small print over DRIVER LICENSE in the title's gold, and a gold CLASS K
chip on the right; a photo on the left, the holder's own kart in their color,
hat and flag, in a little lit world of its own, turning slowly, and only while the
card can be seen, from just short of looking at the camera, so it looks straight out
half a second after the card is first seen rather than starting with its back turned,
in a gold frame
on a dark ground; beside it NAME, the enrolled name, large, then CLASS "K ·
Kart" and LICENSE NO., JJ and six digits drawn once when the test is first
passed and kept in the settings with the date, the holder's name and what they
earned, ISSUED, that day, and EXPIRES, the same day 420 years on; ENDORSEMENTS
as chips in two rows, KO, MULT 4, JACKPOT, ROYAL FLUSH,
CASH-OUT, ITEMS and FULL HAND, gold for the ones earned on their own in the exam
and a faint outline for the rest; a retake keeps the number and the date,
endorses what its own exam earned in place of what the license carried, where it
once left the endorsements as the first pass had them, and carries the name enrolled
for it, where it once kept the first pass's; the holder's name slanted in blue ink over a
SIGNATURE line under the photo; and the fine print along the foot, VALID ON ALL
TABLES · NOT VALID AS ID · KEEP OFF THE FELT · NO CASH VALUE. The card has a
back, which it turns over to show where it is shown in full, on a click or a
tap on it or on the hand's button again, Tab or Y, and nothing on the screen
says there is one: it turns right over about its upright axis, in perspective,
the back coming round as it passes edge-on, its tilt up or down going over with it so that it
comes to rest just where the turn left it rather than jumping; the notes and the program's card
turn the same way. On it, a magnetic stripe along the
top, a hologram, a disc of foil drawn by a shader whose colors run round and
through as the card is tilted, as a foil's do with the angle it is seen at,
and run as it is turned over, fine rings engraved under them, a glint where
the light catches it that moves only as the card moves, a glance of light
crossing it now and then while it lies still, the game's mark raised in
the middle in a foil of its own, and round it, between two thin rings, the
game's name the way a seal has it, JACKPOT over the top and JUNCTION along
the foot, both upright, a star at either side, struck faintly in a foil whose
colors run with the rest, there to be found rather than printed over it;
beside it, in a column, PROPERTY OF THE
DEPT. OF KARTS with the small print of whose card it is, "If found, return to
the nearest Junction. Any Junction.", the examiner's own signature, for
whoever reads that far, beside it in the examiner's red pen "cones" and how many
the test knocked over, where it knocked any over, a cheat code, up up down down left right left right
B A, "Does nothing. We checked.", and the number as a barcode under them
all. While the story is on, 8.7, a line is scratched into the stripe, the card's pale stock showing
through the scratches, "They're watching how you drive. Stay strange. —K.", and the fine print
along the back's foot ends HUMAN OVERSIGHT: 0, which reads 1 after the story's ending; the first
time a license is issued, held up in full after its stamp, it turns over by itself after a beat to
show its back a moment, STORY.md 6.7. The screen is two pages, one after the other, so each fits a
phone held
sideways: first the heading, the line, the course and the card, with air over and
under it, the line about the stamp under it; then, once the card is stamped, the
congratulations, the test's time and the ways on in a row in its place. Either is drawn
smaller, about its middle, on a screen smaller than it, a big UI scale say, 8.5, so
nothing scrolls. It was one column, taller than a phone's screen, with the screen
scrolling under a pane that did not; then the card and the ways side by side,
wider than it needed to be. The rubber stamp, a wooden handle on a red base,
hangs off the card's right edge over its own shadow, breathing a little and
leaning a good way after the mouse as it moves, over the card if the mouse is
there, and under its base is drawn
the control that presses it, the left mouse button, Enter or the pad's accept,
whichever was touched last, and nothing on a touch screen; under the card a
line says "Click the stamp to make it official", or Tap, or Press, by the same
device. It is a button, so a click, a tap, or that control with the cursor on
it, which it starts with, presses it. Pressed, it lifts and swings over the
card's lower right corner, slams down with a thud, which is when the card takes
the mark, two red rings with PASSED inside them, DEPT. OF KARTS over the word
and the date under it, a star in the outer ring's gap either side, laid a little
askew and short of solid the way ink is, a smaller stamp the same one scaled down,
and the card shivers; then the stamp fades away leaving the mark. Nothing goes
on without stamping: the stamp is the point. A moment after, the license is held
up in full over the screen, as the title and the settings show it, see below, for
the player to look at what they have just earned, turning toward the mouse, the
stick or the phone and turned over with a click or a tap; put away, with Back, a
click or a tap beside it or Put it away, the second page comes up,
CONGRATULATIONS and the name in gold, "Class K. Valid on every table. The Junction is yours.", the
test's time under it in small gray type, "Test time 3:12", with "best 2:58" beside it once an
earlier pass was quicker and nothing more made of it, and the three ways on side
by side, Garage, Hit the road, which is Play, with the cursor, and Back to title. The license is seen again on
the title, peeking in from the right edge the way a card in a hand does, tilted
and a third off the screen, dimmed a little so it does not take the eye from
the buttons, sliding in straight under the cursor, as it is, and back out
from under it, a touch screen having the tap alone and nothing sliding under a
finger, and shown in full over a shade on a click or a tap, or on accept with
the cursor on it; with keys or a pad in hand a hint in the bottom right corner
of the title says the way that reaches it from the buttons, right, and with the
cursor on it accept, which shows it, as one in the bottom left corner does for
Kit's folder, STORY.md 7.2, and with the mouse or a finger there are none; the
way a joker is shown out of the hand, held up to be looked at: it turns a little
in perspective toward the mouse as it moves, or the way the right stick is
pushed, or the way a phone is tilted from how it was held as the card came up,
which needs no permission of the phone, and settles back, with turning arrows
that turn it over and a cross that puts it away under it, as Kit's folder has,
STORY.md 7.2: there for the mouse, never taking the cursor, the key or pad button
each answers to drawn on it while keys or a pad are in hand, and a line saying how
to turn it and put it away for the device in hand; a click turns it over and a
right click puts it away, a tap on the card turns it and a tap beside it puts it
away; and on the License tab of the settings, 8.5, with the plate to change under
it. The plate for the back of the kart, see 4.4, comes with the license, starting from the
holder's initials and the number's last three digits, "TLT-123", and is chosen there rather than
at the end of the test, which is the road's.

After the story's ending, 8.7, the license carries the house's own gold stamp, APPROVED, over its
lower left corner as the Department's PASSED is over its lower right; its class reads K · Operator,
it expires NEVER, and its back says it is the property of the house and was reviewed by its holder,
STORY.md 8.6. A license issued or retaken after that is signed by its holder as the examiner,
STORY.md 6.7.

A map may hold more than one Junction, each banking as the one does, and the
Royal Flush is per room for the same reason: a map of rooms wants each room's
own. No map has rooms now that the test is one lot, so the one Junction and the one
room make this the rule it always was.

### 9.6 The waiting room

Where everybody stands before a match starts. On the screen it is called the Lobby: its loading
screen says so, whatever the code and this document go on calling it. A menu is a poor place to wait: there is nothing
to do in one, and it cannot tell four people which of them everybody is waiting for or whether
the one who has pressed nothing is thinking or has walked off. So the waiting is done in a room
that is driven in.

It is the corner of the garage of 9.4 -- the same concrete bay, the same light, the same things
round the walls -- and it is deliberately almost empty: a pad in the middle, four spawns and
four things standing on the floor to drift round while the last player finds their seat. A
stack of wheels, a cone, and a drum with a box opposite it down one side of the room -- two marks
a few lengths apart, which is a figure of eight for anybody who wants one. The wheels stand a
cell further from the back wall than the rest of their corner would put them, leaving room to
come off the dressing stalls along that wall. The box is the only
thing in here that breaks, and it comes back in seconds rather than the half minute a box takes
in a match: it is there to be driven round, not to be hidden behind. The wheels and the drum are
solid, unlike the clutter in every other room, because driving through the one thing there is to
drive round is worse than having nothing there. The cone is the driving test's own, 9.4a: a kart
that drives into it knocks it over, away from where the kart came from, and a few seconds later
it tips itself back up where it stood, to be knocked over again, on every screen of the room as
its karts reach it. Nitro comes back as fast as it does in the Garage, a tank in a
few seconds, on every machine in the room: a client works its own tank out, see 10.3, and so
works out the room's rate for it, and the room's heat on a map, from its own meter.

And a football, in front of the pad, to knock about. It rolls on the floor and nowhere else: its
height is held, so no kick lifts it, and the walls and props throw it back the way they throw
back a kart. It is not solid to karts. A kart that meets it is not stopped by it as by a wall; the
ball is kicked out of its way instead, off whichever side of the kart it met, with however fast
that side was coming at it, and rolls to a stop on the concrete. The kart is the heavy thing.
A kart on nitro kicks it twice as hard, and the ball may go twice as fast for it. A shot kicks
it too: 9 m/s on the way the shot was going, and the shot is spent on it. It is a target for the
aim assist of 5.2 the way a box is, so a shot at it leans onto it. It is heard being hit,
by how suddenly its speed changes, which every machine can see the same way: a soft thump when a
kart is close enough to have kicked it and a knock off anything else, louder the harder the hit,
and nothing while it only rolls. It
is nobody's on the pad, and a ball ever found outside the room goes back to where it started.
Online the host kicks it and tells everybody where it went, often and without waiting for an
answer; a client draws it rolling on between one telling and the next. Until the client's own kart
meets it: then it is kicked there and then, on that machine, which runs it from there on and tells
the host where it is, and the host goes by that word and passes it on, for as long as the client
has it, two seconds after its kart last touched it or until somebody else kicks it. The last to
kick it is the one whose word counts. Waiting a round trip for the host to kick it was a kart
driving into a ball that stood there and then shot off from under it. What the host says in the
meantime is from before the kick, so the client keeps to its own word until the host has said it
goes by it. A shot is still the host's to land, as every bullet is, and takes the ball back.

Nothing else is in it. There is no clock, nothing to shoot but the ball, nothing to collect and
no score: the room asks one thing of anybody in it.

**Readying up.** The cash-out pad is the ready marker. Driving onto it charges it, a ring of
blocks round it fills as it charges, and after a couple of seconds a tick lights over the kart.
When everybody in the room has one, the whole ring turns green and the match begins a second
later. The room says it is going before it goes: a cut to the arena on the frame the last
tick lit would take the last player's own moment of readying away from them.

It is heard as well, quietly. A player charging the pad hears a soft tick for every block of
their arc as it lights, each a little higher than the last, and a chime when the tick goes up
over their kart. Only a player at this screen hears their own charge -- somebody else's is seen
and not heard, or a room of four charging at once would be a clatter -- while anybody readying
up is heard by everybody. The ring going green is a bigger moment than one more player in it, and
is heard as one: the same chime run up through its third and fifth to the octave, a note every
0.09 s, the last a little louder. The player who fills the room hears that run instead of their
own chime, since the two on top of each other would be neither.

Ready lasts exactly as long as the standing does. Roll off the pad and the charge and the tick
go with it, on the frame the kart leaves. That is the honest reading of a pad nobody is on: a
room that started because everybody was ready a moment ago would start without them. It holds
in the second the ring is green as well: somebody knocked off the pad, or somebody new taking a
seat, calls the start off until the room is full again.

The ring of blocks round the pad is split between whoever is in the room -- an arc each, in
their own color, filling as they hold it. One ring showing whoever had got furthest read as a
single pad filling, which in a room of four says nothing about which of them it has taken. It is
forty-eight blocks, so a room of eight, 9.3, still has an arc of six each; a charge is heard in
no more ticks than a player alone on the pad heard when it was twenty-four, so the ticks of a
lone player do not run twice as fast.

**Crashing.** Nothing in here costs anything, so dying costs nothing either. A kart that falls
down a hole or gets rammed off the pad is back on the floor on the next tick, with no wait to
sit through and no hand of cards to pick from: there is no run being built in a waiting room, and
a joker pick over the screen is a player who cannot see the pad they are meant to be driving
onto, at the moment everybody else is waiting for them to.

Saying it by driving rather than by pressing is the whole point. A button on a menu says the
same thing, but it does not put the player who is waiting anywhere in particular, and it does
not show the room who it is waiting on. A kart parked on the pad does both, in the one place
everybody is already looking.

**Who is here.** Down the right-hand side, where a match keeps its running order, the room
keeps a list of who is in it: a name each in their own color, in the order they arrived, with
no place and no score, since nothing in here is being played for. Past four names it is two
columns, so a room of eight is no taller than a room of four. Each player's own block in
the corner is cut down the same way: their name, their lives, their nitro and their speed, and
nothing about scoring -- no banked chips, pot, mult, kills or deaths.

**Teams.** With teams on, 3.14, the room's corners are the teams': a mat painted on the concrete
in each team's corner, as many as there are teams, in the team's color with its suit painted
large on it, flat, as the Royal Flush pads' suits are. Hearts has the front left corner, nearest
the camera, Spades the front right, Diamonds the back right and Clubs the back left, so two
teams stand either side of the room. Driving onto a team's mat and stopping there moves a player
to that team: the ring a kart wears cashing out, 8.3, fills round it over two thirds of a second
while it stands there going slowly, so a kart drifting across a corner on its way somewhere is not
moved by it, and full, the kart is painted over in the team's color with a puff of it on every
screen. A mat a player's own team already has does nothing. The switch's team button in the pause
menu does the same from anywhere in the room, for a player who would rather not drive across it.
A seat sitting down comes in at its team's corner, and a kart that crashes comes back at its own:
put down beside the mat toward the middle of the room, each of the team a little further along, so
the suit is not hidden under a kart. The list of who is here goes by team, each team's
names under its suit and its name, and the ticket says how the teams stand, "2 v 2", with the bots
counted where they will sit. Online the host sees whose kart stands on a mat, as it sees who
stands on the pad, and moves them; a client's switch asks the host, as it does for a color. A
host turning teams on, or to fewer of them, keeps everybody on a team that is still there and
seats the rest on the smallest ones. In the list the names under a team are set smaller, on strips
only as long as they are, and the team's own row, which leads no race in here and wears no foil,
reaches further in, so the teams stand out over who is on them.

**What it says.** The count is written twice: at the top of the screen for the player at this
machine, as `1 / 2 PLAYERS READY`, and on a sign standing on top of the back wall, as `1 / 2`
with `PLAYERS READY` under it. Both say how many bots come in with the players too, `1 / 2
PLAYERS READY + 2 BOTS`, so nobody expecting a match of two finds four karts on the grid: as
many as the host asked for that the arena has seats left for, and nothing when that is none. The
host says the number it asked for with the plan, and each machine takes off the seats its room
has filled.

At the top of the screen the lines are printed as the house's, 8.1a: on a short ticket hung from
the top edge as the clock board is in a match, square where it meets the edge and notched at its
foot, little room round its words, so it stays over the count's sign on the back wall rather than
in front of it: the count in foil figures with what it counts in capitals beside it, and under a
perforation the next match, "Next: Lucky Crossing · 3 min · first to 2000" or that the host is
still choosing. How to take a seat is shown where a newcomer would sit: in the corner of the
screen their block would take, on an empty seat, a corner block's strip cut off the edge as theirs
will be but faint and empty, its number over the way to take it, "SEAT 2" and "J or Menu to take
a seat". That the room is full, and how to join from another machine, go on a small tag of their
own at the foot of the screen, gone while it has nothing on it.

The sign is a small board rather than the hoarding a room hangs its clock on. A hoarding is set
back over a crowd and read from anywhere on the floor while a match is being played; there is no
crowd here, the camera is holding the whole room, and up there it sat outside the shot. So it
stands on the wall over the middle of the room, off the floor the karts drive on, leaning back so
the face turns up toward a camera looking down at it. The count gets a line of its own, because
it is the news: one long line across a letterbox was all width and no height. The camera holds
the whole room rather than following anybody, since what matters in here is the pad and who is
standing on it.

Who is ready is the host's to decide, see 10.3. The host simulates every kart, so it is the only
machine that can see who is standing on the pad; a client is told, the same way it is told
everything else about somebody else's kart, and draws the same ticks, the same count and the
same green ring from what arrives. A client fills the ring itself, off the karts it can see on the
pad, so the arcs move on every screen; an arc stops one block short of full until the host has
said that player is ready, so a client never shows somebody as ready before the host has.

**Getting more people in.** Under the count is how to do it: the buttons that take a seat at
this machine, the key and the pad's both, drawn as the buttons rather than named, and -- when
there is a host to join -- the address and port somebody at another machine connects to. Both
buttons, because the line is for somebody who has not pressed anything yet: the device this
machine last heard from is the one the player already driving is holding. The room is where
both questions get asked, so it is where they are answered; anywhere else and a player has to
leave the room to find out how to let their friend in.

A room holds no more players than it may: four at one machine, and online no more than the
host's lobby lets in, see 9.3, whichever machine they sit at. Once it is full the line says
`Maximum number of players reached` in place of how to take a seat, and a press of join at this
machine is turned away with a notice saying so and how many the game has room for, in the lobby
and in a match alike. With four at this machine and seats still free for others, the line says
`This device has room for 4 players` instead, and so does the notice. A client knows the limit because the host says it with the plan, and again
whenever Lobby settings change it, so its line and its notice are the same as the host's. Two
machines asking for the last seat at once is settled by the host, which seats one and turns the
other away, and the one turned away gets the same notice. The notice takes nobody's controls, since the players in the room are still
driving on the keys and pads a menu would take: it goes by itself after a few seconds, or at OK
under the mouse or a finger. The door held the limit for somebody knocking from another machine
and not for somebody at the host's own, which sat a third player down in a lobby for two.

A seat taken in here goes through to the arena with everybody else, and as who it was in the
room: the same color, the same name, the same dress.

**Choosing the match.** Whoever decides where the room goes chooses what the match is going to
be in here: the host online, and on one machine the machine itself, which is where Play goes
straight to. They are a Grand Prix or a quick match, a big button each, see 9.7, then a row of
presets for the house rules, then rows for how many maps or which arena, how long, the target, how
many bots and how hard, the items and how many jokers a hand holds, own bullets and what the clock
running out does, in two columns that fold, see How the pane is laid out below. They come up over the
room the moment it is opened, again from the host's pause menu, and start on whatever the host
chose last time. Hosting online they come up one step later: first the lobby's own settings of
10.3, who may come in, since friends are knocking from the moment the room is open, with Next
on them, and Back or B, going on to the match's. That is on hosting only: back in the room after
a match with everybody still connected, who may come in has been settled, so the match's come up
alone, and Lobby settings on the pause menu is there for a host who wants to change it. On one
machine nobody knocks, and the match's come up first. The room is open while they are up -- friends join and drive around -- and the
host's own karts wait where they are, since the controls are working the menu. So do the karts at
any screen under any menu there: the pause menu and whatever comes up in its place, Lobby settings,
Manage players and its questions, the House's invitation, a name being typed, anything with the
cursor on it. Neither the arrows nor a stick drive them, the throttle does not rev them, and their
engines die away as a kart's that is down do, coming back once the menu is put away.

Everybody in the room is told what is coming, under the count:
`Next: Crossfire · 5 min · first to 3000`, or for a Grand Prix
`Next: Grand Prix of 3 maps · 5 min each · first to 3000`, or that the host is still
choosing, or on one machine that it is still being chosen. The bots are left to the count
above it, which says how many will really come in rather than how many were asked for. The pane says who can join while it
is up: friends online, and on one machine anybody else there, with J or Start. On a screen too
short for it, a phone's under a big UI scale, the rows scroll between the title and Done, which
stay where they are, rather than the whole pane running off the top and the bottom or being drawn
too small to read; a pad's cursor takes the rows with it. The cursor starts at the top of the
rows rather than on Done, and Back is Done, its key or button drawn on it while keys or a pad are
in hand, so a pad never has to walk down to it. The room does not go while the host is
choosing, however ready everybody else is: a match that started
halfway through the menu would be the one that was set before they began.

**How the pane is laid out.** Thirteen rows and more down one column ran off a desktop's screen as
much as a phone's, and a first look at them was a wall of choices for somebody who only wanted to
play. So under the two big buttons the rows stand in two columns, torn apart down the middle by a
line of perforation the way a ticket is from its stub: The floor on the left, where the match is
played and who with, and House rules on the right, how it plays.

| Column      | A quick match                                       | A Grand Prix                                      |
|-------------|-----------------------------------------------------|---------------------------------------------------|
| The floor   | Arena, the room it is played in under it            | Maps, Map sizes, Tie-breaker                      |
|             | Small maps for 5+ karts, in a room for more than four, 6.3 | the same                                   |
|             | Bots, Bot difficulty, Teams, and Friendly fire with teams on, 3.14 | the same                           |
| House rules | Match length, Target score, Joker slots             | Time per map, Target score, Joker slots           |
|             | Items, once the loyalty program has added the later set, 8.9 | the same                                 |
|             | Your own bullets, Out of time                       | the same, then Jokers between maps                |

Every box in a column is as wide as the widest of them. Left and right take the cursor across
to whatever in the other column is level with it, the head of one that is folded, after the chip
beside it in a row of two; left to itself it went to whatever was nearest, which over the gap
between the columns was as often a preset as the row beside it. Each column folds. Its head is a tab with
its name in the house's capitals and a chevron at its end, and folded, the tab carries two lines
of fine print saying what its rows are set to: `3 maps · Normal and XL · tie-breaker` over
`3 bots, normal · no teams`, say, or `5 min each · first to 3000 · 5 jokers` over
`own bullets harmless · last one standing · pick one to keep`. A press anywhere on it opens it, its
rows dealt in under the tab and the cursor on the first of them; pressing the tab of an open
column folds it again. Both start folded the first time a machine opens the settings, so somebody
new sees the two big buttons, the presets, four lines of what the match is going to be and Done,
and after that each is as it was left, kept with the rest of the choices. On a screen too short
for both open, a phone's under a big UI scale, opening one folds the other, and where even one is
too tall its rows scroll between the title and Done as above. A screen too narrow for the two side
by side stacks them, The floor over House rules, with the perforation running across between them.
At the Final Hand, STORY.md 8.1, both are open and neither folds, since the fine print would say
what the blacked-out values are.

**Presets.** Between the big buttons and the columns a row of chips sets every one of House rules'
rows at once, but for Jokers between maps: a poker chip of its own color on each, its name, and a
line under the name of what it sets. The floor is left alone, since which map and who plays it are
not a matter of how, but for a quick match's arena, which a preset deals afresh, 9.7.

| Preset      | Chip  | What it sets                                                                                 |
|-------------|-------|----------------------------------------------------------------------------------------------|
| Standard    | Gold  | 5 min, first to 3000, 5 jokers, basic items, own bullets harmless, last one standing: the values in this document |
| Quick hand  | Green | 3 min, first to 2000, 4 jokers, and the rest as Standard                                     |
| High roller | Purple | 8 min, first to 5000, 8 jokers, all items once the loyalty program has added them, and the rest as Standard |
| Cutthroat   | Red   | 5 min, no target, 3 jokers, basic items, own bullets deadly, and the match ends at the whistle |

The chip of the preset the rows are set to is lit in gold, the way the chosen kind of game is. Rows
set to none of them light Custom, a fifth chip, of steel; pressing Custom opens both columns, the
cursor on the first row of House rules, for somebody who wants to set the match up for themselves,
and on a screen with room for only one, House rules alone. A preset is not kept: which chip is lit
is read off the rows, and the rows are remembered as ever. One picked with a column folded changes
the fine print on its tab, which flashes gold to say so. A chip is pressed anywhere on it, its
poker chip as much as its words.

The bots are on top of everybody in the room, as many as the arena has seats left for, and the
room holds no more people than the arena can seat, so nobody who got in is left standing when
the match begins.

**After the match.** The podium of 3.8 offers the host of an online match a way back: Back to
lobby, first in the row, with the cursor on it. It takes everybody back to this room together,
still connected, the same people in the same colors, and the host's match settings come up
again, since the next match is chosen here the same as the first one was. A client's podium
says the host takes everybody back, rather than offering a button that could only take one
of them. Whoever wants to stop there leaves from the room, the way anybody does.

### 9.7 Play: a Grand Prix

A Grand Prix is a run of several maps with the same people in it, one after another. A quick
match is the single map, set up and played on its own.

**Setting up.** Play has one lobby, and the first thing its match settings ask is which: two
big buttons side by side at the top, Grand Prix with a trophy on it and Quick match with a
stopwatch, the picture beside the name and a line under the name saying what it is, no taller
than they need to be, and the chosen one lit in gold the way the ways to drive are, 4.2. The rows
under them follow the answer. A quick match picks its arena, and pressing Quick match, again too,
deals it one: a map at the usual size that a Grand Prix would deal, never the one the row is
showing, so every press changes it, and a preset picked in a quick match deals one the same way.
Somebody who wants a particular map picks it from the row after. A Grand Prix asks instead how many
maps, 2 to 6, 3 to start with, since its arenas are not chosen, they are dealt, and in House rules,
9.6, what jokers carry between them. Under Maps, Map sizes says which sizes of map it deals from,
see 6.3: two chips side by side, Normal and XL, both lit to start with, and putting out the one
left lit lights the other, since a run dealt from no maps has nowhere to go. Under them,
Tie-breaker, a switch, on to start with, says whether karts level on points at the end of the run
play a showdown to settle it, 9.7a. A map and its XL are the same room, and a run never plays the
same room twice running. The length row reads Time per map, since it is. The host's match settings
online, 9.6, are the same rows with the same first question. Whichever was chosen last is chosen
again next time.

**The waiting room first.** Starting a Grand Prix does not start a map. Everybody goes to the
waiting room of 9.6, and the first map begins when everybody playing is parked on the pad --
on one machine as much as online, since a room of four people on one screen has the same
question of who is ready. Only then is the playlist dealt, when everybody who is going to play
it is there.

**The playlist.** Every arena comes round once before any comes round again, and no arena is
played twice running, so a run of three plays each of the three once and a run of six plays
each twice, never back to back. The run is the host's; each map is told which one of how many
it is, so a client knows as well as the host whether its podium leads on.

**Between maps.** A map that is not the last ends on its podium as any map does, and the run's
standings so far, see The end below, headed Standings after map so many of so many, are the page
under it on the same bill, 3.8, past a perforation, once the run's points are in. They are turned
to with the arrow down over the bill's edge, which the cursor starts on, or up and down, or
scrolled down to, and back up again as often as anybody likes while the host leaves them up. Next
map is in the row along the foot whichever page is in view, for whoever moves everybody on, and the
cursor goes to it once the standings are in view, so going on is a press at a time; beside it a
client is told who does, see 9.3. After the last map its podium is the only page at first, with Continue in the row,
which goes on to the party in the room and then the final standings, printed under the last map's
podium and turned to as the party ends; the last map is still a scroll up, and the ways on are
Back to lobby and Back to title. A single map is one page, and its ways on are the whole row.
There is no rematch of a map in the
middle of a run and no leaving from its podium -- the pause menu is still the way out. The
podium says which map of how many it was. Online the host moves everybody on, the same way it
moved everybody out of the waiting room; a client's podium says so, and a client can look at the
standings as well. The next map is the same match on the next arena: the same people, in the
same colors, with the same settings.

**Jokers between maps.** A Grand Prix has a row for what everybody takes on from one map to
the next of the jokers they end it holding, in the lobby and in the host's settings alike:

| Choice              | What goes on to the next map                                        |
|---------------------|---------------------------------------------------------------------|
| Discard all         | Nothing: every map starts from an empty hand                        |
| Pick one to keep    | The one each player picks as the next map starts, or none -- the choice to start with |
| Keep one at random  | One of each hand, drawn at random                                   |
| Keep all            | The whole hand                                                      |

The podium of the map just finished says which rule the run is on. Choosing is done where a card
is always chosen: on the joker pick of 3.7, as the next map starts, with the jokers the player held
at the whistle, under "Keep which joker for this map?". Skip keeps none of them, for a player who
would rather start the map with an empty hand. The karts are frozen on the grid and the lamps wait for everybody's pick, so the stick
that steers moves the cursor and nothing is driving while somebody reads. Nobody is waited for
past 15 s: a pick still open then keeps one of its jokers at random. A player with only one joker
keeps it without being asked, since a choice of one is not a choice, and every bot keeps one at
random, having nobody to choose for it. Online a client works its own pick the way it does a
respawn's and the host's answer is the one that counts; a seat kept for a client holds its pick
open until the client sits in it. Everybody else sees who the lamps are waiting on. The other
rules' jokers are in everybody's hands before the lamps go. Nothing is carried out of the last map.

**The same bots.** The bots are chosen once, when the playlist is dealt, and drive every map of
it: the same number, in the same seats and colors, each with the same way of driving and so the
same name and the same dress. The Hunter in the second seat on the first map is the Hunter in the
second seat on the last. A seat kept for a player at another machine is dealt a way of driving too, for the maps it
spends as a bot -- before its player has sat down, or after they have left.

**Points.** Each map is won the way a single one is, on banked chips, and pays points by where
everybody finished it:

| Place  | 1st | 2nd | 3rd | 4th | 5th | 6th |
|--------|-----|-----|-----|-----|-----|-----|
| Points | 10  | 7   | 5   | 3   | 2   | 1   |

The run is won on points, by a bot as readily as by anybody. Level on points at the end of it,
with Tie-breaker on, is a tie, and a showdown settles it, 9.7a. With it off, whoever won more maps
is ahead, then whoever banked more over the whole run: a tie between a player who won a map and
one who never did is not one anybody watching would call even. That order stands between karts
level on points in the middle of a run too, where there is nothing to settle yet, and between
karts the showdown itself could not tell apart. Second on every map beats a win and two lasts. Every podium in the middle of a run is the map's own, each row with its three
awards at most and nothing about points; the run's standings it goes on to say them, each row
with what the map just played paid it, "+10" in green, beside its points over the run so far.
A chip saying what a place paid used to stand first among the awards, a fourth pill on every row
saying something the next page says better. The host scores each map at its whistle and tells
the room how the run stands, and every screen draws its podium from that.

**In teams.** A run played in teams, 3.14, keeps its teams from the first map to the last, and is
scored by team: each map pays its teams the points of their places, the winning team 10 and the
next 7, the run is won by a team, its ties broken by maps won and then by banked over the run, and
the standings, the run's podium and the party's board, GRAND PRIX CHAMPION over the team's name,
are the teams'. Somebody joining part way through a run is seated on the smallest team. Its
showdown of 9.7a is between teams: teammates share their points and are never level with each
other, so a run only needs one when two teams or more are level, every kart of them plays it, to
the last team standing, and a team lasted as long as its last kart did. The banked tie-break is
what the team's karts banked between them.

**The end.** The last map ends on its own podium first, the same as every map before it: the
map's results and awards, the points left to the standings after the party. Its one way on is Grand
Prix results, which is everybody's to press, a client's as much as the host's, since it only
changes what that screen shows. With anybody level on points and Tie-breaker on, the way on is
Tie-breaker instead, and the party waits for the showdown, 9.7a.

After the last map that first goes to a room of its own, put up for the party rather than for
playing in: nothing of any map is in it, and it is laid out so that everything in it can be seen
from where the camera ends up. A dance floor of dark tiles, a few of them lit on every beat in
the colors of the top three, fenced down both sides and across the front with the card room's
velvet rope on brass posts, a gap left in it in front of the podium. At its back corners stand
stacks of chips the size of the card room's in the same three colors. On the floor, forward of
the middle, a podium with the three on it in their own colors and dress, facing the camera and
floating a little up and down over their steps, each a little behind the next, a light on it.
Behind them the DJ booth, half again its usual size, up on a riser with neon along its front so
it is seen over the podium rather than behind it. Behind the booth a hoarding of the room's own
kind, bigger than the ones over a crowd, reading GRAND PRIX CHAMPION over the winner's name in
their color. The crowd all the way round, on its feet; the disco rig over the floor with every
light on the winner; the music at its loudest; confetti off the steps; and fireworks in all
three colors going up behind the board, framing it rather than covering it. None of that is on
at first: the room opens hushed, the music muffled as if heard from outside the room and a
little down, the crowd and the DJ standing still, the floor dark and one light drifting over it,
while the nitro's swell, slowed and deepened, rises under it. For as long as the swell runs, two
smoke machines on the floor behind the podium, one each side, spit a thick, wide jet of smoke
down the floor past it. It drops on the first bar of the music at least 1.7 s in: the filter is
swept open and the music is back at full within half a second, the crowd starts dancing, the
floor lights, the rig comes up with every light on the winner, confetti goes off every step and
the fireworks start. The machines stop, and their smoke hangs over the lit floor for a few
seconds before it thins away. It is built in the materials of the room the run ended in, well
away from its arena, which is hidden, with the HUD, while it is on. It stands in a hall of its
own, a floor that runs on past the camera and dark walls at the back and sides with a line of
neon along them in the three colors, so nowhere in the shot does the world stop. The places on
the steps are painted the same size on all three, sized to the lowest. The camera starts high
over the room and flies in slowly over 6 s to look down on the podium from in front of it, holds
there for two seconds, and the accept button skips the move, and the hush with it. Each machine
stages it for itself from what it already knows, so nothing about it goes over the wire.

Then the run's podium comes up over it, the same one every map before
it led to, headed Grand Prix over Final
standings after however many maps it was: the top three of the run on the steps, then everybody
ranked on points, each with how many maps they won, their points in gold, and a chip for every
map saying where they finished it and what it paid. Beside the place of anybody the last map
moved is an arrow: green and up for a climb, red and down for a fall, in a column of its own that
is left out altogether when nobody moved, rather than a gap before every name. Only then does the board in the arena, which
names the winner at every whistle, name the champion of the run instead of the last map's
winner. The run's podium's ways on are Back to lobby, to the waiting room online and to Play's
lobby on one machine, or back to the title.

### 9.7a A showdown

A Grand Prix that ends with karts level on points does not hand the run to whichever of them won
more maps. It puts them in a room together, takes the money out of it, and lets them settle it the
way a table settles a tie: by who is still there at the end. Tie-breaker in the Grand Prix's rows
of 9.7 turns it on and off, on to start with; off, the run is settled as it always was.

**Who plays it.** Every kart level on points with another, anywhere in the standings, and all of
them in the one showdown; in teams every kart of the teams level on points, see 9.7: a tie for first and a tie for fifth are played out on the same floor at
the same time. Each tie is settled among its own karts, by the order they outlast each other, so a
kart in one tie is as good a target as one in its own and knocking out somebody else's rival is
still a kart fewer. Bots play it as bots, but for one thing: every one of them knows where the
nearest kart is, seen or not, since there is nothing else in the room for a bot to do, and goes
after it unless an item is closer. A seat kept for a player at another machine who has left is
driven by its bot, as on every map.

Everybody else watches. Their karts sit it out, their corners say Watching the tie-breaker, and
emotes, 3.8, still go up; a machine with nobody in the showdown watches it the way a watcher of
9.3 does, the camera on the fight.

**The rules.** Sudden death of 3.13 from the flag, on the Showdown map of 6.3, in the room the run
ended in:

- Nobody respawns. A kart that goes down is out, and offered no joker.
- Two lives each, and taking somebody out gives a lost one back, 3.6, as it always does.
- No money. There is nothing on the floor and nothing to bank: crates break as ever but drop
  nothing, and stay broken, so the cover wears away as the fight goes on; a wreck drops no chips.
  No bounty is called and no joker is thrown onto the floor.
- Power-ups from the four pads, the table's usual ones less Chip Magnet, which has nothing to pull.
- The same hand for everybody. Three jokers are dealt at random from the table's deck as the map
  starts and every kart in it holds the same three, so nobody is better armed than anybody else
  and nobody knows the hand before the room does. Only jokers that do something in a fight are
  dealt: none about chips, pots, the Junction or banking. There is no pick before the lamps.
- Two minutes on the clock. It is meant to be over well inside that, and a room that small with
  items in it usually is.

**Settled.** The last kart standing wins its tie. Every kart ranks above each kart it outlasted in
its own tie, so the order inside each tie is the order its karts go out in, the last out first.
Karts that go down in the same moment are level on it, a trade or one bomb, and the order of 9.7
puts them in order: maps won, then banked over the run. A clock that runs out on more than one kart
ranks those still standing by lives left, and then by the same order.

The points stay what the maps paid. The showdown's order is what the standings sort by next, after
points, and every row that played in it carries a chip on the final standings saying where it
finished its own tie: Showdown 1st, Showdown 2nd.

A tie settled any other way says how it was settled. With Tie-breaker off, in the standings in the
middle of a run, and between karts the showdown could not tell apart, every row level on points with
another carries a chip naming what put them in order and what it had of it: `Tie · 2 maps won`
beside `Tie · 1 map won`, or `Tie · 1,240 banked` once maps won are level as well, so nobody is left
to wonder why the row above theirs with the same points is above it. A map's slip does the same for
lines level on what they banked, 3.8.

**Getting there.** The last map's podium is put up as ever, and under its caption a line says who
is level: `Level on points: Ada and Bram (24), Cy and Dot (9). A showdown settles it.` In the place
of Continue the way on is Tie-breaker, in foil, and it goes straight into the map, as Next map
does: no waiting room and no pick. It starts a map, so online it is the host's to press, and a
client is told The host starts the tie-breaker; on one machine anybody's.

**The opening.** The room comes up dark, the lamp over the table down to a third and the disco rig's
heads shared out between the karts in the fight, and over the start a plate under the middle of the screen as the
announcer's calls are, 3.12: SHOWDOWN in foil capitals, dressed in a pair, two cards of the same
rank fanned out behind it, since that is what a tie is, and under it the names in the fight, each
in its color. It stands while the lamps run, under the Last Call alarm pitched down as sudden death
has it, the music hushed and the crowd standing still. At the flag the plate goes, the room's light
comes up and the crowd roars. All through it a tag hangs under the clock on two cords, saying what
kind of time this is and how many are left, `SHOWDOWN · 3 LEFT`, and the clock is in red from the
flag, as sudden death's is.

**While it runs.** The standings down the right, 8.3, are the showdown's, in pictures rather than
words: the karts still in at the top, ordered by lives left, each with a heart for every life in its
own color, as its corner has them, and under them the karts that are out, the last one out first,
each with a skull, its place on its chip saying where it went out. Karts sitting it out are not on
it. The score tanks on the table, 8.1, have no score to fill with, so they make way for a row of
playing cards on stands where they stood, one for every kart in the fight, faced in its color with a
border and a pip; a kart that goes out folds its card, which falls forward face down, its dark back
to the room. Each kart that goes out is called on a plate of its own, its name and OUT in its color,
outranking any call its killer's kill was worth. A corner says nothing of money, with none in the
room: no banked chips and no pot, only, once its kart is out, `out of the showdown`, or for a seat
sitting it out `watching the tie-breaker`.

**The end.** With one kart left the whistle goes, and a plate in the winner's color says it, on a
checkered flag: `Ada BREAKS THE TIE`, with the rig on them and fireworks in their color, as at every
whistle; in a quick match on the map, `WINS THE SHOWDOWN`. A few seconds on the room goes straight to
the party of 9.7, staged in this room, and the final standings come up over it. The showdown has no
slip of its own: what it decided is in the standings.

**What it counts for.** It is not a map of the run. It is not counted as a map played and nothing
done in it counts toward a statistic, a bet of the loyalty program or an achievement, but for
Winner Takes All, 8.10. The run itself is counted once the showdown is over rather than on its last
map, since only then is it known who won it.

**Online.** The host runs it as it runs the next map: the karts in it go with the rules a client is
sent before its seat, the room with them, and its order with the run's points, 10.3, so every
screen ranks it the same. A machine that arrives in the middle of a showdown watches it.

**Debug.** `++ --grand-prix-tie`, in a debug build, has every map of a run pay every seat the same
points, so any run ends in a showdown of everybody. A quick match on the Showdown map, 6.3, is a
showdown for the whole room in any build.

### 9.8 A demo for a booth

The game shows itself where nobody is at the controls: on a stand at a fair, in a shop window, on
a screen beside whoever is showing it. It plays Grand Prix after Grand Prix on its own, with the
HUD, the picks and the payout slip a player sees, and anybody walking past picks up a pad and is
playing at once.

**Starting it.** `--demo` among the game's own arguments, 10.2, in a debug and a release build
alike, and `make demo` from a checkout. The title comes up as it always does, so the shader
warm-up of 10.7 runs behind its pane, but with nothing of a player's first start on it: no
invitation, no opening, no welcome, no question of how to drive and no menu. Once the shaders are
compiled the first run is dealt. It plays until the game is closed. The mouse pointer is hidden
while it plays and comes back the moment the mouse moves. The demo is never online, and puts no
game on anybody's list of LAN games.

**Its own settings.** The demo plays on `user://demo.cfg`, with its profiles beside it in
`demo.profiles/`, unless `--settings=` names another file, so nothing it does ever touches the
player's own settings and profiles on the same machine. The first time it starts, with no
`demo.cfg` yet, it takes the machine's part of the player's own settings, 8.5: the picture, the
sound, the controls and the accessibility, so a booth starts the way its owner set the machine up.
On a machine nobody has played on it takes the booth's defaults instead: the game's own, in full
screen. From then on they are the demo's own, changed from Settings on its pause menu, below, and
kept.

**Its profile.** The demo plays as a profile of its own, made afresh in memory every time it starts
and never written anywhere: a member of the loyalty program of 8.9 with every landmark won, so the
table deals every joker and power-up there is and a kart can wear any dress. A demo on a machine
nobody has played on looks no emptier than one on a machine somebody has played on for months. Its
story, 8.7, is off. Nothing played in the demo is recorded, by a bot or by somebody who sat down:
no statistics, no catalog, no bets, no achievements and none of their toasts, no Kit's notes on the
floor, no Final Hand, no Lost Property, no bet pinned over the clock and no page of the program on
the slip.

**The table.** Two seats at this machine, each with its corner of the HUD, 8.3, its picks and its
line on the slip as a player's, but driven by a bot, and two bots besides: four karts, a full
table of the usual size, since a fifth would play every map as its XL, 6.3. `--demo-seats=<n>`, 1
to 4, and `--demo-bots=<n>` set other numbers. Every kart drives at Normal, 9.1, the seats' bots
too, so whoever sits down meets a fair table. Every kart, a bot's too, is dressed afresh at random
as each run is dealt: every part of 4.4, the Showroom's of 8.9 and a finish on each drawn on its
own from all there is, and worn for the whole run, as a bot's dress always is. Each seat is also
handed a funny name, 3.8, a color nobody else at the table has, drawn at random, and a license
plate, 4.4, made up for it.

**The runs.** Every run is a Grand Prix, 9.7, of three maps dealt from the normal maps and the XL
maps alike, three minutes a map to a target of 3000, with Overtime, Pick one to keep and
Tie-breaker on, every kart for itself. The waiting room is left out: the playlist is dealt as the
run starts, and the first map's lamps go once its room is up.

**The picks.** A seat's picks are worked where everybody sees them, the way a player works them,
rather than answered at once as a bot's are: the respawn pick of 3.7 and the pick of a joker to
keep on the grid, 9.7. The cards are read for a second and a half or so, then the cursor steps
from card to card about every 0.85 s, a step or two either way, at least to the next card and
back, stops on one drawn at random and takes it a second later; a full hand then picks the card to give up the same way. A pick takes three to six
seconds in all, long enough for whoever is watching to read the cards. The seats emote now and
then, by the bots' own rules, 3.8.

**The slip.** Nobody has to press on through the payout slip of 3.8: it goes on by itself, a bar
filling along the foot of what it is about to press, as on a watcher's slip, 9.3: the arrow down
while it is to turn the page, and the way on after. The map's podium is up for 8 s, then the run's
standings under it for 8 s, and then Next map. After the last map the
podium is up for 8 s, then Continue, the party in its own room, and the final standings for 12 s. A
run that ends level plays its showdown, 9.7a, as any run does. Then the title comes up for 10 s,
its menu hidden and the line below on it, saying in foil under its tagline how long it stands, The
next Grand Prix starts in 7 seconds, so it reads as a wait rather than as the game stuck, and the
next run is dealt. Somebody who has sat down can
still press on sooner.

**The line.** While the demo plays and a seat is still a bot's, a line along the foot of the screen
says Press any button to play, printed on a ticket in the house print of 8.1a and breathing
slowly. The camera keeps the karts clear of it as it does the HUD's panels, 8.2.

**Taking a seat.** Somebody sits down by pressing on a device nobody holds: two presses within
two seconds, of the keys the game plays with, a pad's buttons, or a stick or a trigger pushed out
from rest. The mouse never sits anybody down, being the hand of whoever is showing the game, which
also clicks the window to bring it up; a seat it took once sat waiting on a keyboard nobody
touched, its pick open for good. Nor does a key the game has no use for, the one that switches
windows say, a stick that rests off its middle, or a device that only ever reports an axis held,
as some keyboards do; and nothing sits anybody down while the window is behind another. They have
the first of the demo's seats nobody holds, on that device, there and then, on the grid, in the
middle of a map or with a pick up. The bot lets go and whoever pressed has the kart as it was: its
score, its pot, its jokers, its item, its dress, its name and its corner of the HUD. It is said
where nobody can miss it: the seat's name in its color and YOU'RE IN under the middle of the
screen, the announcer's place, 3.12, three flares going up round the kart one after another, 3.6,
and a sound, and the hint beside the kart of 8.3 comes up over it for a few seconds. The presses
that sit somebody down are theirs alone: Start on a pad nobody holds takes a seat rather than
pausing, as it does in any room, 9.2, and is no join; Escape on the keyboard opens the pause menu,
below, for whoever is showing the game. Once every seat of the demo is held, another device takes
over a bot's kart, as anybody joining a map does, 9.2, with a corner of the HUD of its own. A seat
taken drives the simple way, 4.2, with Auto throttle on, without asking, since that is how
somebody who has never held the game gets driving soonest. On the title between runs a press deals
the next run at once, with whoever pressed in its first seat. Whoever sits down keeps the seat from
map to map and from one run to the next. A seat that hears nothing from its device for 60 s, the
mouse counting for nothing, goes back to its bot, which drives on from where the kart is; it is said
the same way, the name and BACK TO THE BOT and a single flare, and the seat drives the simple way
with Auto throttle again for whoever sits down next. A bot's kart taken over goes back the same way.
The run goes on whoever is in it.

**The pause menu.** The demo's pause menu has Resume, Settings, kept in `demo.cfg`, Play the full
game and Quit, and no way back to a lobby, since the demo has none. Play the full game is in foil,
with a glint of light running across it every few seconds to catch the eye. Over the corner of each
seat somebody holds, its switch, 4.2, has the way they drive, simple or advanced, and Auto throttle
on a pad; nothing else, no Leave and no profile, since a minute of nothing is the way up. A seat its
bot drives has none. Left open for 60 s with nothing pressed, the menu puts itself away.

**The full game.** Play the full game leaves the demo for the title, for a visitor to play the game
as anybody new does: the invitation, the opening, the question of how to drive and the driving
school offered on the first Play. They play on a profile of their own, made afresh in
`demo.profiles/` as the demo is left, with a head start, so a machine nobody has played on does not
show a visitor an empty game either: the program's card activated, and the landmarks nearest the
slip road on the Strip and in the Department won, about a third of the program and no keystone, so
the stalls have dress of the program's to offer and the deck cards of its own. Sixty seconds with
nothing pressed by anybody, wherever the game is, a menu, a room, a map or a slip, and the demo
takes over again. The visitor's profile is thrown away, and the machine's settings and the lobby's
choices go back to how they were when the demo was left, so nothing one visitor changed is left
for the next. While a visitor is away in the full game, the title's Quit asks first, over the
title, whether to quit the game or go back to the demo, the cursor on going back, which takes the
demo up again at once, the same way; Back puts the question away. The title the demo comes back to
says The demo starts in 7 seconds, counting down. A visitor's profile left behind by a
game closed while they played goes the next time the demo starts.

## 10. Technology

### 10.1 Engine and project settings

| Setting             | Value                                                        |
|---------------------|--------------------------------------------------------------|
| Engine              | Godot 4.7, GDScript                                          |
| Renderer            | Forward+                                                     |
| Physics             | Jolt Physics, 60 ticks per second, physics interpolation on  |
| Telemetry           | None                                                         |
| Resolution          | 1920 by 1080 at 16:9 as the design target, 60 fps            |
| Stretch             | `canvas_items` with `expand` aspect, already set             |
| Anti-aliasing       | MSAA 2x                                                      |
| Lighting            | One directional light with soft shadows, SSAO on             |
| Platforms           | Linux, Windows, macOS first. Consoles need a porting partner. Mobile with on-screen controls later |
| Performance budget  | 60 fps on a mid-range laptop iGPU, and on a mid-range phone at its render scale, with 4 karts, 100 live bullets and full trails; see 10.7 |

### 10.2 Architecture

Scenes with a colocated script are the unit of composition. Data lives in
Resource files. Rules that need code, such as jokers, are a Resource paired
with a small script that implements hooks.

```
res://
├── addons/            gdUnit4 and other addons
├── assets/            models, textures, audio, fonts, the app's icon and splash
├── data/              Resource files: jokers, powerups, cannons, coins, ai_traits
├── scenes/
│   ├── arena/         one scene per map plus shared arena elements
│   ├── kart/          kart.tscn, motor, cannon, aim, contacts, pot, holders, trails, sound
│   ├── bullet/
│   ├── pickups/       chip, gold chip, mult die, item box, floor joker, floor item
│   ├── zones/         junction pad, jackpot zone
│   ├── bots/          bot brain
│   ├── ui/            player hud, tally, joker pick, joker menu, lobby, results
│   ├── fx/            destruction bursts and other world effects
│   ├── garage/        the practice room from 9.4
│   └── match/         match state machine, the death sequence, snapshots, player stats
├── scripts/           shared code: autoloads, scoring math, input router
├── tests/             gdUnit4 tests
├── docs/              this design, the story, the plan, the changelog, development and servers
└── THIRD_PARTY.md
```

Key pieces:

- **Match**: state machine Lobby, Countdown, Playing, LastCall, Overtime, Results. Owns
  the player list, timer and standings, and instantiates the arena scene.
- **Kart**: CharacterBody3D with child components: KartMotor for handling,
  Cannon, Pot for coins and mult, JokerHolder, ItemHolder, GrazeArea, Trails.
  Input comes through a KartInput interface with PlayerInput, BotInput and
  later NetInput implementations, so bots, decoys and players share one kart.
- **Bullet**: Area3D stepped by raycast, owner id, bounces left, aim assist.
- **Zones**: JunctionPad and JackpotZone implement the ramping channels from
  3.4 and 3.5 using the pure functions in scoring.
- **Scoring**: pure functions in one script, no scene dependencies: pot value,
  death split, bank rate, amount banked over a time span, Jackpot collection
  over a time span. Covered by unit tests.
- **Events**: an autoload with global signals such as `coin_collected`,
  `kart_killed`, `grazed`, `bank_completed`, `item_used`. HUD, audio and jokers
  listen to these.
- **Jokers**: a base Joker resource with hooks. Each joker is a subclass and a
  `.tres`. Holders get their own instance so jokers can keep state, such as
  Lucky Seven's counter. Hooks, extended as needed:
  `modify_kart_stats`, `modify_cannon_stats`, `modify_bank_rate`,
  `on_coin_collected`, `on_graze`, `on_kill`, `on_death`, `on_respawn`,
  `on_turbo_pad`, `on_bank_completed`, `on_other_bank_completed`,
  `modify_joker_offer`.
- **Power-ups**: a base PowerUp resource with `activate(kart)` and an optional
  duration or shot count. Cannon types are power-ups that swap the Cannon's
  stats resource.
- **Input router**: assigns devices to player slots in the lobby and rewrites
  incoming input events to the right slot, so gameplay code only sees actions
  per player.
- **Bots**: BotBrain node driving a BotInput, trait as a Resource.
- **Persistence**: settings, bindings, volumes and accessibility toggles are
  saved with ConfigFile in `user://settings.cfg`, which names the profile
  playing, and each profile, see 8.5, in a file of its own in `user://profiles/`,
  `Profile`, read and written through `Settings` by the same names as before
  profiles, so nothing that reads a seat's name had to change. What the loyalty
  program of 8.9 has won is kept in the profile beside the catalog, and how they
  are written so that none is ever lost to a crash is the next point.
  `++ --settings=<path>` runs with another settings file, a `user://` path, an
  absolute one or a bare name in the user directory, for seeing the game as a
  new player does without touching one's own; its profiles are kept beside it,
  in a folder named for it. A test that writes settings takes them away with
  `Settings.remove_files`, profiles and all, which never takes the player's own.
  Nothing automated plays on the player's own settings and profiles, which live
  on the same machine: a run started on a script rather than the game, `-s`, as
  every gdUnit test and every check, bench and probe in `tools/` is, plays on
  `user://tests.cfg` and the profiles beside it, `Game.TEST_SETTINGS`, shared
  between them, unless it names a file of its own; and a tool that starts the
  game as a scene names them in the environment, `JJ_SETTINGS=tests.cfg`, as
  `tools/smoke`, `tools/profile`, the multiplayer and server checks and
  `make bench` do. Only the game started as a game, `make run`, `make dev`, the
  editor or an export, plays on the player's own, and not even that with `--demo`,
  which plays on `user://demo.cfg` and the profiles beside it, 9.8.
- **Saving safely**, `SafeFile`: a profile is months of a player's progress, and a
  file written over in place is a file a crash, a power cut or a phone killing the
  game halfway through a save leaves half written, which the next start would
  read as a new profile and then save over. So the settings and every profile are
  written in three steps:
  1. The whole file is written beside itself, `1.cfg.tmp`.
  2. The file it replaces, if there is one, is renamed to its backup, `1.cfg.bak`,
     over the backup before it.
  3. The new file is renamed into its place, `1.cfg`.

  A rename is all or nothing, so whatever happens part way, a whole file is left:
  stopped in the first step, the old file is still in its place and the half-written
  `.tmp` is never read; stopped between the second and the third, there is no file
  in its place, and the backup, the save before, is read. Reading, a file that will
  not read, or reads as nothing, is read from its backup instead, and is set aside
  as `.broken`, the latest one kept, rather than written over by the next save, so
  it can still be looked at; the next save puts a whole file in its place and leaves
  the good backup be. A profile left with only its backup is still listed and plays
  from it. At worst a player loses the last save, a map's statistics or a setting
  changed, never the profile. One backup is kept, the save before: with every save
  written whole, a file goes bad only by the disk failing under it, and an older
  copy would be no surer. The engine does not wait for the disk to have the new
  file before renaming it; most file systems, ext4 among them, see to that for a
  file replaced by a rename, and on one that does not, a power cut could leave the
  new file empty, which reads as nothing and so is read from its backup. Removing a
  profile removes its backup and any broken one with it.
- **Quitting**: `Game.quit` is the one way out, for the title's Quit, the window
  closing, a server's game that is over and the dev runs alike. A sound still
  playing as the engine shuts down is left behind in memory, and the engine says
  so at exit: instances leaked and resources still in use, four and two for every
  sound. So the room goes, every sound is stopped, and the mixer gets 0.15 s to
  let go of them before the engine stops: frames are no measure of that, since
  the mixer keeps a clock of its own. `tools/smoke`, `tools/multiplayer_check` and
  `tools/server_check` fail on anything left behind at exit, from any process.
  Meanwhile the window shows the menus' own dark, `MenuTheme.BACKGROUND`, which
  is the color behind nothing at all, between scenes as well: the engine's gray
  flashed up as the game went.

### 10.3 Networking

Designed in from the start so that M6 is an addition, not a rewrite: all rules
run in one place, the Match, and karts are driven by a KartInput interface.

#### Who owns the connection

The `Net` autoload, not the scene being played. A session used to hang off the match scene, so
the wire went down with the scene: the peer closed as the scene was freed and every client was
dropped the moment the host changed rooms. That was survivable while a match was one scene from
beginning to end. It is not survivable with the waiting room of 9.6 in front of it, where the
host and everybody who has joined move from one room to another and expect to still be talking.

So the connection outlives any one room. Scenes come and go under it; the peer, the slots and
the clients stay until somebody leaves on purpose, which is every way back to a menu. It also
fixes the path the RPCs travel on at `/root/Net/Session`, where before it was whatever the scene
happened to be called and both ends had to agree.

Letting go of a connection closes the peer at once and takes it off the API a frame later,
`NetPeer.let_go`, and only if no other peer has been put there since. Godot ties itself to the
`tree_exited` of every node that has made or answered a remote call, and taking the peer off
empties that cache; in a release build the untying uses the wrong callable, and every such node
still in the tree says "Attempt to disconnect a nonexistent connection". Letting go from a
session's own `_exit_tree` was exactly that, since `tree_exited` comes after every `_exit_tree`:
three errors at the end of every dedicated server game and on a client leaving one. An editor
build never shows it, so `tools/server_check` runs an exported server with `SVCHECK_SERVER`, and
fails on any engine error in the server's log.

The cost of a longer life is that nothing is cleaned up by a scene change any more. Whatever the
session holds is held until it is closed, so closing is somebody's job rather than something
that happens by itself. The one thing it lets go of on its own is the match it was playing: the
moment that match leaves with its room, the session holds nothing until the next room takes it
over, and ignores whatever arrives in between rather than handing it to a match that is gone. It is also what a dedicated server needs, see 9.3a: such a server runs room
after room with the same clients connected throughout, which a session owned by a scene can
never do, and it is a session with nobody at it, no local seat and no HUD or camera for nobody to
look at.

#### Versions

Two games only play together on the same major and minor version: 0.5.0 and 0.5.3 do, 0.5.3
and 0.6.0 do not. A patch release fixes things without changing what goes over the wire;
anything bigger may well change it, and two games that disagree about what a snapshot says do
not fail politely. So before anything else is said on a new connection, the client gives its
version and the host answers with its own and whether the two can play. A client it turns away
is never seated: it is told which version the host has and which it has itself, and goes back to
the menu. The handshake has 5 s to finish, so a client too old to know about it is dropped rather
than left waiting for a seat that never comes.

#### Leaving the room together

The waiting room and the arena are two matches on one connection, and the changeover is the
host's to call, in both directions: into the arena when everybody is ready, and back to the room
after the podium. The room everybody is in is not the room they are going to, so the host says
it is going before it goes, and everybody who is connected changes room on the word rather than
on their own clock. A client that changed when it felt like it would be driving round a lobby
the host had already left, or standing on an arena floor being simulated by nobody.

Arriving is the other half. The rules and the seat are sent once, when a peer connects, and both
of them belong to the match that was up at the time -- a match that has since been taken down.
So everybody is seated again on the other side, and it is the client that asks. Once its own
new room is built and listening, it asks the host for a seat; the host seats whoever has asked
once its own room is up, and keeps anybody who asked early until then. Told rather than asked,
a seat and a set of rules sent the moment the host arrived could reach a client still in the
old room and be applied to the match being taken down -- which the arena's loading screen hid,
and the room, which is up in a frame, would not. In the arena the seats were kept for them,
after the players at the host's machine and ahead of the bots, and come with the arena's rules
and the arena's seed. They are kept rather than taken from the bots, because the bots are what
the host asked for on top of everybody in the room. A client's name and color go with it either
way: the name because the client says it again the moment it is seated, the color because the
host seats each of them in the color they had in the room they came from. Being seated again
is what puts a `NetInput` in the new match's slot, so the kart a client has been driving is
still the kart it drives.

A client with several players asks for all of them at once, by its own number for each, the
first 0, and the host keeps their seats by client and by that number. Every message about a seat
carries the number: the seat handed out, the name and the color it claims, the controls sent up
and the host's word on the kart sent back. The first of them to sit down in a room is the one
told the rules. One asked for later, somebody pressing join at the client, is checked against
the lobby's limit on the host and turned away with a message of its own when there is no room,
which the client shows as the notice of 9.6; the client does not guess, since two machines can
ask for the last seat at the same time. Kept by number, the two players at one client stay
apart: each claims its own name and color, each has its own history of predicted ticks, and
leaving empties the one seat. A seat asked for again is the seat already held, a second press of
join on a pad whose seat is on its way asks for nothing more, and a player shown out before the
client has seen their slot is gone from it all the same. This changed what the machines say to each other, which is why it
came with 0.9.0 rather than a patch release.

Seated is not the same as there. A client still has the room to build once it knows which one
it is, and a slower machine than the host's used to arrive to a countdown already running, or to
a match already going. So on arriving at a map the host holds the field on the grid, lamps dark,
until every client has said it has the room up. Every screen shows how many players it is still
waiting on, out of everybody playing, over a bar that fills as they arrive. Players, not
machines: a client with two at it is two still to come, and two in once its room is up; counted
by machine, a room of eight at four machines read as four. Nobody is waited for
longer than 15 s: a machine that slow, or one that has stopped answering, holds up everybody
else for that long and no longer, and the lamps go without it. A player who leaves while
everybody waits is not waited for. The waiting room holds nothing, since nobody is racing in it.

Somebody who connects in the middle of a match comes in through the waiting room, since that is
where joining opens, and the host may well be somewhere else. So a newcomer is shown in. With the
host in the waiting room it is seated at once; with the host in an arena it is given the same word
everybody else followed on the way in, follows it, and asks for its seat from there, taking over a
bot or adding a kart. It arrives in whatever the match is doing, the podium included, which it
is shown at once rather than after the pause of 3.8, since it has no whistle to wait out. In a
Grand Prix it is sent the run as it stands. A match with no bot to take over and no room for
another kart turns it away in the handshake, saying the match is full. Snapshots only go to
clients that are seated, so one still on its way in never draws the arena's karts in the room it
is leaving.

#### Who decides what

One rule underneath all of it: **a client may decide where its own kart is and
what its own controls just did; everything else is the host's.** A client can
move, and it can answer its own buttons on the tick they are pressed. It cannot
award itself anything, hurt anybody, or decide that it picked something up; it
only shows its kart taking what it has driven over, and waits to be told.

| Question | Answered by | How the other end finds out |
|----------|-------------|------------------------------|
| Where my own kart is | the client driving it | it sends its answer with its controls; the host follows it |
| Where anybody else's kart is | the host | the snapshot, thirty times a second |
| Two karts touching | the host | it takes the wheel off both for a moment, and says so |
| Nitro burning, and the tank | the client predicts, the host confirms | the message addressed to that client |
| A turbo pad's shove | the client predicts it | nothing to send: the pad is in the same place on both |
| Going down a hole | the client predicts the fall | the host decides the death, in the snapshot |
| Breaking a box by ramming it | the client predicts it | the host settles it within a second, in the snapshot |
| Taking a pickup or a Royal Flush pad: the look and the sound | the client predicts it | the host settles it within a second, in the snapshot |
| Pulling the trigger: cooldown and sound | the client | nothing to send; the host's word for it is dropped on the way in |
| The bullet itself | the host | the snapshot |
| Who hit whom, who died, lives | the host | the snapshot and relayed events |
| Coins, pots, cashing out, score | the host | the snapshot |
| What is on the floor and who took it | the host | the snapshot, as what changed |
| Items held and items used | the host | the snapshot |
| The joker pick in front of me | the client works its own | it names the card it took, and the host takes it only if it dealt that card |
| Dropping or destroying a card of my hand | the client, at once | it names the card, and the host does it only if the hand holds that card |
| The waiting room's football | the client whose kart kicked it last, for a while, 9.6 | it tells the host, and the host passes it on |
| Statistics and awards | the host | the snapshot |
| The clock, the state, Last Call, overtime | the host | the snapshot |
| Jackpot, Royal Flush pads, the bounty | the host | the snapshot |
| Excitement, music, lights, the crowd, the announcer | every machine, for itself | nothing is sent; the same events arrive at both |
| Match rules: clock, target, lives | the host | sent once, before a slot is handed out |
| A showdown: who is in it, its room, and the order they went out in | the host | the karts and the room with the match rules; the order in the snapshot, and with the run's points at the whistle |
| Pausing | every machine has to agree | asked and answered both ways |

What this is meant to guarantee:

- A client never watches its own kart lag its controls. Driving, nitro, the
  trigger and the joker cursor all answer on the tick.
- A client can never give itself a coin, a kill, a life or a point.
- A client can never move its kart further than a couple of meters from where the
  host's own simulation put it. Past that the host keeps the wheel and says so.
- Anything a client guesses at is settled by the host within a round trip, and
  every guess has a way of being put back: a box comes back solid, a kart is put
  where the host has it, a correction is walked in rather than applied.
- Nothing a client guesses at is ever announced twice. A puppet raises no events
  of its own, except the ones it is deliberately raising instead of the host's.

What it is not:

- It is not cheat-proof. A modified client can drive its own kart anywhere inside
  the plausibility limit and can hold its own trigger down. This is a game played
  with friends over a direct address, 9.3, and the trade is deliberate: the same
  limits that would stop it would put the round trip back into the driving.
- It is not lockstep. The two machines are not expected to agree exactly, only to
  agree closely and to be put right when they do not.
- A snapshot does not fit in one datagram. See the sizes below.

**A mechanic is not finished until it works online.** This is the standard the
rest of this section exists to meet, and it applies to everything in this
document: every rule in 3, every number, every statistic and award in 3.8,
every light, sound and label in 8. Whatever a player can see, hear or count on
the host, a player on a client sees, hears and counts the same, at the same
moment and with the same value on it.

Anything new therefore gets one of three answers before it is done, and the
answer is written down here next to the mechanic:

1. **Its state goes in the snapshot**, if it is something that persists: a
   score, a pot, a timer, whether a thing is standing or in pieces.
2. **Its moment is relayed**, if it is something that happens: a kill, a
   cash-out, a tone, a crash. A client raises none of these for itself, because
   its karts are puppets and its match takes no physics step.
3. **It is worked out from what is already there**, if the client has the
   ingredients: the excitement meter, the Junction's blink, the running order.
   This is the only answer that costs nothing, and the only one that is wrong
   if the ingredients turn out to be missing.

A fourth answer, *it is host-only*, is not available for anything a player can
perceive. Half a mechanic on one machine is a bug, not a limitation.

`tests/test_online_sync.gd` is where this is held to. It runs a match on both
machines and compares every number either would show a player, it insists every
signal is either relayed or named as one that stays put, and it fails if the
match it ran was too quiet to prove anything. A new mechanic or statistic
belongs in that comparison, and a new signal has to be put in one list or the
other before it will pass.

- ENetMultiplayerPeer, default port 7777. The host runs the server and plays.
- The host sends a state snapshot at 30 Hz: karts, bullets, pickups, turrets,
  bombs, oil, crates, shooting targets, Royal Flush pads, Jackpot zones, the
  bounty, slots and joker offers. Clients keep a puppet match that renders the
  snapshots and dead-reckons bullets between them. The rule is that anything a
  player can read off a screen is either in the snapshot or worked out from it:
  a pot halfway through a cash-out carries the part of the coin already drained,
  not just its coins and its mult, because the two are different numbers and the
  one on the screen is the second. Snapshots were chosen over
  MultiplayerSpawner and MultiplayerSynchronizer because every gameplay node
  is built in code.
- Clients send their input state to the server every physics tick with an
  unreliable ordered RPC. The server simulates all karts.
- Snapshots go unreliably but in order: one that arrives after a newer one is
  dropped rather than shown, since shown it would run the clock back and the karts
  back the way they came. ENet did that already for any snapshot big enough to go
  in pieces, which it always sends in order, and now does it for a small one too.
- A slow line is warned of. The host knocks on each client twice a second and
  times the answer, settling each new time a third of the way into the last, and
  a knock gone unanswered counts for as long as it has been waiting, since a line
  gone quiet is at least as slow as the wait. The time goes on the seats that
  client holds and out with the rest of each player in the snapshot. Past 100 ms
  there and back, which is already a lot for a game this quick and well short of
  where a chip taken flat out starts to blink out rather than fly into the kart
  that took it, the player sees an amber warning sign and the time
  beside their name in their corner, and everybody sees the sign beside their
  name in the standings. A client that has heard nothing from the host for longer
  than that while the match is running counts the silence as its round trip too,
  since the host's word on how slow the line is is exactly what is not arriving.
- The connection uses ENet's range coder both ends. A snapshot is still bigger than
  one datagram: it is split against the MTU of 1392 bytes *before* the datagrams
  are compressed, and an unreliable packet in pieces is lost whenever any piece
  is. Fitting one in a single datagram is a job for a smaller snapshot, not a
  smaller wire, and is open. Neither end lets ENet throttle what goes
  unreliably: left to itself it drops unreliable packets before they go whenever
  the round trip wobbles, and with a snapshot in five pieces that was every
  snapshot lost for seconds at a time. A client saw 3 of 168 through one such
  wobble, its own kart going down a hole it never heard it had died in and
  falling on below the floor. Measured on a four-bot match, a busy snapshot is
  about 6.4 KB, or five fragments:

  | Section  | Bytes | Of what                                  |
  |----------|-------|------------------------------------------|
  | slots    | 2252  | 4 players, mostly their statistics       |
  | karts    | 1680  | 4 karts                                  |
  | pickups  | 1576  | 10 on the floor, and a real match has more |
  | flush    | 400   | 4 pads                                   |
  | the rest | 480   | jackpots, crates, clock, bounty          |

  Most of what is left is shape rather than substance: every entry is a dictionary,
  so its keys are written out again for every kart and every player, thirty times a
  second. Writing entries as plain values instead of dictionaries is still worth
  doing.
- **The slow parts go at a slow beat.** A player's name, way of driving and
  statistics and a kart's dress and plate hardly ever change, and a room of eight,
  9.3, sent them thirty times a second: a fifth of a snapshot of eight, which came
  in eight pieces. Each player's go in one snapshot out of fifteen, twice a second,
  every player on a beat of their own so that no one snapshot carries everybody's;
  a name, a way of driving, a dress or a plate also goes in the four snapshots after
  it changes, so a dress picked on a stall shows at once and one lost packet changes
  nothing. The statistics go at the beat alone, since they change all the time and
  matter at the end, and all of it goes in every snapshot while the match is not
  being played, so the podium is drawn from everybody's last statistics, and in the
  next one for somebody who has just arrived. A client keeps what it was told until
  it is told again. Measured over a minute of hard bots on Lucky Crossing XL, before
  and after:

  | Karts | Typical snapshot     | One in twenty is up to | After: typical      | After: one in twenty |
  |-------|----------------------|------------------------|---------------------|----------------------|
  | 4     | 5.8 KB, 5 pieces     | 6.4 KB, 5 pieces       | 4.7 KB, 4 pieces    | 5.4 KB, 4 pieces     |
  | 8     | 10.4 KB, 8 pieces    | 11.0 KB, 8 pieces      | 8.2 KB, 6 pieces    | 9.0 KB, 7 pieces     |

  Deflated, as a stand-in for ENet's range coder, a snapshot of eight is about
  1.3 KB, so a host with seven players and four watchers at other machines sends
  something like 430 KB a second.
- **The floor is sent as what changed.** A chip lies where it fell until somebody
  drives over it, and sending every one of them thirty times a second was the
  largest part of a snapshot. So a snapshot carries what appeared and what went,
  and the whole floor again every couple of seconds. On the measurement above that
  takes a typical snapshot from 6.4 KB to 5.1 KB, and more on a busier floor.

  Unreliable packets go missing, so none of this trusts a single telling. Every
  change is repeated over a few snapshots, which costs a handful of numbers and
  means one lost packet changes nothing. The whole floor goes out on its own clock
  regardless, so a client that missed something is never wrong for long, and a
  client that has only just arrived is sent all of it at once rather than waiting.
  The few pickups that are actually going somewhere — pulled in by a Chip Magnet,
  or still in the air from whatever dropped them — carry their position every
  snapshot, as an id and a place and nothing else.
- Hits, pickups, banking and scoring are server-authoritative. The server seeds
  all randomness and relays gameplay events so clients' HUD and audio react. That
  includes the ones a client could never raise for itself because its karts are
  puppets: the countdown tones and the green light, a kart hitting something, a
  kart going down a hole, nitro lighting up and a drift carried to its boost.
  Every event is either relayed or named as one that stays where it was raised,
  and a test holds the two lists to the full set, so a new one cannot quietly
  never reach a client.
- Which slot a client plays arrives in a message of its own, after the first
  snapshots have already built the karts. Anything that depends on knowing it,
  such as which kart sounds like your own rather than like somebody else's, is
  asked again every snapshot rather than settled once when a kart is built.
- What a client cannot run for itself it is told or works out from what it is told.
  Its karts are puppets and its match takes no physics step, so the whistle never
  goes there: the rig swings onto the winner off the snapshot's standings rather
  than off a result it worked out.
- Anything a client is told about is told all of it, and keeps no clock of its own.
  A crate running its own respawn timer would come back the frame after a snapshot
  broke it and be broken again by the next one, throwing fresh debris thirty times
  a second for as long as it was really gone. The same goes for a shooting target,
  which only a bullet puts down and a client runs no bullets.
- The match is played by the host's lobby settings. A joining client is sent them
  before it is given a slot, see 9.3, since until then it reads its own.
#### Driving your own kart

A client used to send its controls and wait: the host drove the kart and the
client watched the answer arrive. At 25 ms of ping that is a round trip between
pressing the throttle and the kart moving, which reads as a sluggish kart rather
than as a network, and the game is not worth playing that way.

So a client drives its own kart itself, at once, and the host corrects it.
Everything else stays exactly as it was: the host is still the only authority on
who hit whom, what was collected and what anything is worth.

- **The client predicts.** Every physics tick it numbers its controls, sends
  them, and immediately steps its own kart with them: the same motor, the same
  `move_and_slide`, the same arena. The kart answers the stick on the frame the
  stick moved, whatever the ping is.
- **It keeps what it did.** Each tick's sequence number, controls and resulting
  state go in a history buffer, about two seconds of them.
- **The host plays the ticks back one a tick.** Packets go into a short queue and
  one comes out per physics tick, in order. This matters more than it sounds. The
  client has already driven that tick itself and kept the answer, so a host that
  ran the same controls twice, or took two at once because two packets arrived
  together, would land somewhere the client never predicted and correct it for a
  mistake neither of them made. One packet, one tick, in order, and the difference
  between that and taking whatever has arrived is the difference between correcting
  on every snapshot and correcting on none.
- **A short queue absorbs the jitter.** A couple of ticks are held in hand, and
  after the queue runs dry it waits until it has that much again before playing
  out. The delay is a thirtieth of a second for everybody watching and nothing at
  all for the player driving, who is not waiting on this. A queue that runs dry
  anyway leaves the kart on the controls it last had, because a player whose
  packet is late is still holding the throttle down.
- **The host acknowledges.** It stamps each client's kart state with the last
  sequence number it actually drove, not the last that arrived, and sends the pair
  back to that client alone, at snapshot rate. Other clients are not interested:
  the broadcast snapshot still carries everybody's pose for drawing, and this is
  the one extra message, sent to one peer.
- **The host takes the client's word for it.** Along with the controls, a client
  sends what it made of that tick, and the host's kart ends the tick there. The
  host simulates it anyway, which is what settles anything the kart ran into and
  what catches a claim that is nonsense, but between the two answers the one a
  player is looking at on their own screen is the one that stands. A client
  driving on its own is then never corrected at all, because there is nothing to
  correct: both machines agree because one of them is following the other.
- **Until the host has to settle something.** Running into another kart, being
  hit, going down a hole, dying, coming back: none of those is a question one end
  can answer on its own, and a bump least of all, since each machine sees the
  other kart where it last heard and each predicting its own side would have both
  shoved and neither right. The host takes the wheel for a fraction of a second,
  drives the kart itself, and says so.
- **A claim has to be believable.** Further from where the host's own simulation
  put the kart than a good few ticks of driving, and the host keeps the wheel
  instead. The limit is what stops a kart appearing on the far side of the room;
  it costs nothing to check because the host is simulating the kart regardless.
  Nor may a claim say the kart went further than it can drive: the kart banks a
  tick of driving at its limit every tick, four ticks of it at most, each claim
  spends the distance it says the kart went, and one past what is banked is not
  followed. Nor may its way from where the kart was cross a wall or a crate: one
  ray a claim, at bullet height, `ClaimCheck.through_wall`, so cheap enough for
  every client every tick. An honest kart up against a wall slides along it and
  never crosses one, and a kart claimed into a wall a little at a time, each step
  within its reach, is stopped at the first. A kart the host drove itself for a
  moment catches up again from there.
- **A claim is where the kart went, not what it holds.** It comes with the motor's
  whole state, since a client replays from it, and a client could say anything
  in it. So the host keeps its own answer for the tick, driven from the same
  controls, as the most a claim may say: no fuller nitro tank, no more boost,
  turbo or drift banked, no shorter a spin, no power-up the host did not give,
  and no more speed than the kart can go, `ClaimCheck`. Each has a tick or two of
  slack for a client a tick out of step, which is all an honest one ever differs
  by. And controls or a claim that are not what a client sends, a word where a
  number goes or a number that is not one, are dropped whole: a single one in the
  steering would take the kart off the map. On a dedicated server nobody at it
  plays, so this is everything that stands between a changed client and the game.
- **A changed client is shown out.** A connection, however bad, loses, delays,
  repeats and reorders what is sent and never changes it: a datagram damaged on
  the way is dropped before anything reads it, a call that does not decode is
  refused by the engine before the game sees it, and every client let in plays the
  same version. So word from a client that no copy of the game sends, controls or
  a claim with a word or a non-number in them, or more fields than the game sends,
  `NetInput.SENT`, a ball or a joker that is not one, a name, a plate or a kart's
  dress longer than any copy of the game says one, `SeatWire`, or more seats asked
  for than one machine may have, can only come from a changed client. After three of them, `NetConduct.KICK_AT`,
  one more than none in case the game itself ever has a bug that sends one, the
  host shows it out: it is told "Kicked: abnormal behavior detected", everybody
  else sees the same after its name in a line of the kill feed, and a dedicated
  server writes each one in its log, "Tim sent abnormal state (2/3)", and the
  kick after the third, "sent abnormal state 3 times". What a slow line sends never counts: a claim
  too far away to follow, a packet too late to play, a pick answered after it
  closed or a card no longer held are what an honest player on a bad connection
  sends, and they are only not acted on. `tools/server_check` fails on any such
  line in a server's log, and `tools/multiplayer_check` on any at its host.
- **The client reconciles when the host had the wheel.** It compares where it
  predicted it would be at that sequence number with where the host says it was.
  Agreement costs nothing and changes nothing. Disagreement rewinds the kart to
  the host's state and replays every tick since, so the correction lands in the
  present rather than in the past. While the host was following the client there
  is nothing to put right, and the ticks are simply retired.
- **A correction is never walked in through a wall.** The offset between where the
  kart is simulated and where it is drawn is a picture lagging behind, not a
  movement, so nothing tests it for collisions; up against a wall that is how a
  kart comes to be seen halfway through one. It is tested for room and shortened
  until it fits.
- **Corrections are walked in, not applied.** The simulation goes onto the host's
  answer at once; the picture does not. What is left between the two is carried
  as an offset on the drawn position and heading, and a fifth of it comes off
  every tick, so the kart on screen never jumps, it only ever stops lagging. A
  fresh correction adds to whatever is still outstanding rather than replacing
  it, which matters: replacing would put the picture back by however much was
  left, and a jump on every correction is the thing this exists to avoid.
- **The tolerance is deliberately loose.** A disagreement under ten centimeters
  or a degree and a half is not worth replaying a second of driving over. Nobody
  can see it, and the host decides everything that would actually turn on it. The
  offset is capped at about a kart's length, because past that the picture would
  be somewhere the kart is not, which is worse than the correction it is hiding.
- **A big enough disagreement simply lands.** Past six meters nothing is being
  hidden: that is a respawn, a death, a blast or a pit, and gliding the kart
  across the room would be stranger to watch than arriving.
- **Corrections happen on the physics tick.** The host's answer arrives whenever
  the network delivers it, which is between ticks. A body moved there is a body
  moved between the two poses the engine is interpolating the picture from, and
  it is drawn swerving through somewhere the kart never was. So the answer is
  held and acted on at the top of the next tick.
- **Garbage at the door is dropped at once.** What is not ENet with the game's own
  compression never gets as far as the game: ENet drops it unread, and resets a
  connection that does not open the way the engine does, a stray scan and another
  program's protocol alike. What does get through has to say hello first, one
  knock of the game's own, `NetGuard`, which says what it is, `"magic":
  "jackpot-junction"`, beside its version. A hello that is not one, looked at before it is
  read, one without the marker, or a second hello, is dropped there and then, and
  said in the log with the address it came from. A copy of the game from before
  the marker, 0.10 and older, is dropped with the rest: it cannot play with this
  one anyway. So is one connection too many from one address,
  sixteen waiting to say hello at once or sixty in a minute, more than any room of
  players behind one router opens, eight of them since a room takes eight. A
  host takes two connections more than everybody who may be in, playing and
  watching, so somebody knocking at a full room is told it is full rather than not
  answered: a connection counts from the moment it opens, before the door has said
  anything to it. One that says nothing is dropped when the
  handshake runs out after five seconds, and said too. A flood of datagrams that
  are not the game's cannot be traced to anybody, since ENet drops them unread, so
  a server only says once a minute that it is getting one, a thousand a second
  and three hundred a connection more than its players send: a firewall is the
  place to stop it. Past the door, a player who floods is shown out as for sending
  what no copy of the game sends: a thousand messages in a second in a game,
  `NetConduct.FLOOD`, every one a client sends counted, or sixty in a second of
  those a person sends by hand, a name, a dress, a plate, a color or a team, a
  seat, a pause, an emote or a say at a dedicated server, `NetConduct.SAYS`, since
  each of those has the host tell every other screen; and ten games asked for in
  a second at the server's list, told "Kicked: abnormal behavior detected" either
  way. A pause asked for again as it was changes nothing and tells nobody. A team
  is changed only in the waiting room, where teams are picked, 3.14: asked for in
  a match, where moving would take what the player banked to the other side, the
  host leaves the player where they are. `tools/server_check` sends
  a stranger's garbage at both doors and has the server say it dropped it.

What a client predicts is movement and nothing else. It does not decide that it
picked a coin up, hit anybody, fired a shot that counts, or cashed out: all of
that arrives from the host as it always did. Its predicted kart pushes off walls
and crates because those are the same on both machines, and off other karts
because they are there to be bumped into, but a bump only ever costs a life on
the host. A kart the host says is dead, frozen on the grid or rolling out the
end of the match is not predicted at all; it follows the snapshot, because none
of those are states a player is steering out of.

What a client predicts is everything it can work out from its own controls and
put right afterwards, which is more than where the kart is:

- **Nitro**, because it is the button with the most immediate effect in the game.
  It decides how fast the kart is about to go and whether it goes through a crate
  or bounces off one, so a client that waited for it spent the wait driving at a
  speed it had not asked for. The tank rides the message addressed to this client
  rather than the snapshot, which would fill it back up a round trip late.
- **A turbo pad's shove**, since a pad is painted on the floor and is in the same
  place on both machines, which makes it as safe to predict against as a wall.
  Losing the tires on an oil stain is the other way round and the host keeps the
  wheel for it: no client can see it coming, the stain is the host's and so is the
  direction it throws the kart.
- **Bumping into things**: the walls, the crates and the other karts. Puppets sit
  on a physics layer of their own so a predicted kart has them to push off, and so
  that a host and a puppet match sharing a scene tree, which is tests today and a
  split screen later, never shove each other's karts about.
- **Going down a hole**, which starts here the moment the kart is over the edge.
  A fall is not a guess to be talked out of: once the kart is in the hole its
  position stops being reconciled, because the host is still a round trip behind
  and its answer says the kart is driving along quite happily, which would lift it
  back out to drive over the hole and fall in a second time. The drop runs and
  stops there: a puppet is never killed on its own machine, so whether that cost a
  life, and whose fault it was, still comes from the host.
- **A box driven through at ramming speed**, which comes off the floor here, in
  pieces, and stays off it. The snapshots arriving over the next round trip were
  built before the host had heard about it, and letting those put the box back is
  what left a kart stuck against a box it had already gone through, waiting to be
  dragged past it. So the client's own answer stands for a second, which is long
  enough for the host to agree; if it does not, the box comes back solid. What the
  box was worth and who gets the credit for it are the host's either way.
- **Taking something off the table**: a chip, die, item box or card driven over,
  and a Royal Flush pad driven onto, 3.9. Waiting a round trip to be told was a
  kart driving through a chip that was still there, and the chip then flying into
  it from behind. The host follows this machine's word for where its kart is, so
  it finds the kart on the chip on the same tick and nearly always agrees: the
  pickup flies into the kart and is heard the tick the kart reaches it, judged by
  the same reach the host's physics has, and a pad takes the kart's color. The
  snapshots built before the host heard leave both that way for up to a second,
  `Pickup.PREDICTED_HOLD`; if the host has not agreed by then the pickup is back on
  the floor and the pad back as the host last had it. What it was worth, the item
  in a box, the card in the hand and whether a flush came of it are the host's and
  arrive as they always did, and the host's word for the take is not heard a
  second time, `Audio.ahead`. A kart takes one box at a time and no more cards than
  its hand has room for, counting the ones taken here that the host has not dealt
  yet. The F3 overlay counts what was taken here and how much of it was put back.
- **The joker pick**, which is not physics at all. The cursor moves and the card
  is taken on the tick the key goes down, and the snapshot leaves that one pick
  alone while it is open rather than walking the cursor back to where the host had
  it a round trip ago. Answered, it stays answered: the snapshots made before the
  host heard still carry the pick, and they neither put the cards back up nor take
  the card out of the hand again, for up to a second, `JokerOffer.ANSWER_HOLD`.
  Past that the answer is taken to be lost on the way and the host's pick comes
  back to be answered again, since a kart waits on its pick to come back. The
  host's word for the joker taken is not heard a second time.

  The answer goes to the host by name, `JokerWire`: the card taken or none for a
  skip, and the held card it replaced, sent once and reliably. The host takes it
  only if its own pick dealt that card, a skip only from a pick that has one, and
  a replacement only of a card the hand holds, `JokerOffer.answer_with`, and it
  no longer runs its own copy of a client's pick off the client's controls at
  all. It used to, and the two could disagree: the cursor is walked by the stick,
  and the stick is what the host lets go of when it plays late packets out in a
  hurry, so the host's cursor could stop a card short of the client's and take
  that card instead of the one on the player's screen.
- **The hand of cards**, for the same reason. It is opened and walked here, and a
  card dropped or destroyed goes out of the hand here at once and to the host by
  name, which drops or destroys that card if the hand holds it, whatever its own
  idea of the cursor was. The snapshots made before it heard leave the hand as it
  is here for up to a second, as they do a pick.

None of this decides anything. A predicted bump never costs a life, a predicted
fall never costs one either, a predicted pick never changes which joker is
actually held: those are the host's answers and they arrive as they always did.
A puppet raises no events of its own for any of it, because the host relays the
real ones and a machine announcing both would say everything twice.

- **The trigger, but not the bullet.** Pulling the trigger puts the cannon on
  cooldown and is heard, on the tick the button goes down. The bullet itself comes
  from the host, because whether one lives depends on a bullet fired by somebody
  this machine only ever sees where they were a round trip ago: a predicted bullet
  would often be one that never was, and unfiring one is worse than waiting for
  one. The host's own word for that same shot is dropped on the way in, so it is
  not heard twice.

  The cap on bullets in the air refuses a shot past it, and a client cannot count
  them itself: it has no bullets of its own. So the host says how many of the kart's
  are up, and how many shots it has refused, on the end of the kart's state, where
  a client of an older version does not look; this machine counts the shots it has
  pulled since against the same limit, which makes it cautious: against a full sky
  it does not answer the trigger and leaves it to the host, because the count it is
  working from is a round trip old and a shot promised and not delivered is worse
  than one that arrives late. The host's word comes after: a shot it fired is heard
  then, and one it refused clicks dry here as it would have on the host. Taking the
  oldest bullet out of the air instead, tried for a while so the trigger never did
  nothing, had a shot in flight vanish for nothing a player did; the click and the
  puff say what the trigger doing nothing means.

Two more things follow that are worth stating. The kart is predicted, not the
world, and the world includes the bullets in it. And prediction assumes the two machines run the same code over the same
numbers, which is why the host sends the whole motor state rather than only a
position, and why the rules arrive from the host before play starts.

`tests/test_online_prediction.gd` holds all of this to numbers, with a wire whose
round trip the test sets. Over 100 ms of round trip, four times the ping this was
reported at: the kart answers the stick on the tick it moved rather than five
ticks later, and over four seconds of driving, drifting and handbrake turns not
one of 110 snapshots needed correcting at all.

The number that matters most is how far a correction moves the kart somebody is
looking at, because that is the whole of what a player can see of any of this. On
a wire losing a packet in five, the kart is put right ten times in a second and a
half of driving and not one of those moves it: the corrections are absorbed
whole. Knocked four meters out of place by hand, which nothing in the game does,
it lands 2.8 m and walks off the rest.

The rest of online play is held to a slow line too. `NetLag` sits under the
connection when a test asks for it, and nothing in the game does: each end holds
what it hears for half the round trip, with jitter on top for what goes
unreliably, never puts out of order what goes reliably or in order, and hears a
hang-up only after the last word said before it. The suites that play over a
socket, the online match, several players at a client, arriving, the handover
between rooms and the door, each run a second time over a 50 ms round trip with
10 ms of jitter, and `make multiplayer-lag` plays the whole Grand Prix of
`tools/multiplayer_check` over one; `make check` runs both. Beside its run on one screen the
check plays a room of eight, 9.3, and plays it short: the host with two players at it and three
clients with two each, a quick match on a map at the usual size that eight karts play as its XL,
every machine seeing the eight start on spots of their own and a podium with a row each, and the
whistle as soon as the lamps have gone. There every player at
a client drives over a chip the host leaves in front of them and onto a pad of
their own on the first map, each taken at once and then agreed to by the host,
with nothing put back. A chip taken by somebody else flies into their kart on a
client up to a round trip of about 150 ms. Past that their kart on the client is
so far ahead of the host's by the time the word comes that the chip has gone that
nobody is near enough to have taken it, and it blinks out.

### 10.4 Conventions

- Static typing everywhere. The `untyped_declaration` warning is treated as an
  error in project settings.
- `snake_case` for files, functions, variables and signals. `PascalCase` class
  names via `class_name`. Signals are named in the past tense, `coin_collected`.
- One script per scene, colocated and named after it: `kart.tscn`, `kart.gd`.
- Scripts and shaders live in files of their own, `.gd`, `.gdshader` and
  `.gdshaderinc`: none embedded in a scene or a resource, where an outside
  editor, the linter and a diff cannot get at them, and no shader written as a
  string in a script. `tests/test_smoke.gd` fails on one. There is no size
  under which embedding pays: a five-line script is still one nobody finds.
- Autoloads are kept to a minimum: Game, Events, Audio.
- Numbers live in Resources or exported variables, never as literals in logic.
- Tests with gdUnit4 for scoring math, the cash-out and Jackpot curves, the
  death split and joker hooks. Tests run headless in CI.
- Formatting and linting with gdformat and gdlint from godot-gdscript-toolkit.
- All user-facing strings go through `tr()` with English as the source
  language, so translations can be added later without touching code.
- Every tunable number here matches the value in the game. Changing one means
  changing both.
- Nothing ships single-player only. A new mechanic, number, statistic or award
  works in an online match or it is not done, and the sweep in
  `tests/test_online_sync.gd` grows with it. See 10.3 for the three ways state
  reaches a client and how to choose between them.
- Performance is kept by rule, not by luck. 10.7 lists the rules every frame
  saving came out of, each with the measurement that put it there, and ends
  with the checklist new code is held to. A change that costs frames is caught
  by `make bench` and explained by `make profile` and `make probe` before it
  lands, and the numbers go into 10.7 with the change. A change that adds a
  shader adds it to the warm-up behind the title, and `make warmup-check` says
  whether it did.
- Every change a player would notice adds its line to the `## [Unreleased]`
  section of `CHANGELOG.md`, in the same commit that makes it. The test is
  whether somebody who plays the game would care, not whether the diff was
  large: a renamed variable is not a line, a joker that now fires backwards is.
  Write it for them, in the game's words rather than the code's. Refactors,
  tests and tooling leave the file alone. See 10.5 for what a release does with
  it.

### 10.5 Releasing

Versions are [semantic](https://semver.org/spec/v2.0.0.html) and live in one
place, `config/version` in `project.godot`. `CHANGELOG.md` keeps a section per
version, newest first, in [Keep a Changelog](https://keepachangelog.com/) form,
and an `## [Unreleased]` section at the top that the current work goes into as
it is done. `tools/changelog` is the only thing that edits either:

| Command                        | What it does                                                        |
|--------------------------------|---------------------------------------------------------------------|
| `tools/changelog`              | Checks the file parses and that `project.godot`'s version has a section. `make check` and CI run it |
| `tools/changelog release X.Y.Z` | Turns `Unreleased` into a dated `X.Y.Z`, sets `project.godot`, counts the Android version code up by one, and fixes up the links at the foot |
| `tools/changelog extract X.Y.Z` | Prints one version's notes. The release workflow uses it            |

A release is therefore: cut it, read it over, commit, then tag `vX.Y.Z` and push
the tag. The tag starts the release workflow, which exports Linux, Windows and
macOS builds, the Android APK and the Linux dedicated server build of 9.3a, each
Linux build for 64-bit ARM as well as for x86_64, and
publishes them with that version's changelog section as the release notes,
GitHub's own list of commits appended underneath. Each zip holds the game itself
at its top, one file with everything inside it: `jackpot-junction` for Linux,
`jackpot-junction.exe` for Windows, `jackpot-junction-server` for the server,
and for macOS the app. The ARM builds are the same presets with the architecture
changed, "Linux ARM64" and "Linux Server ARM64", and the game's carries the ETC2
and ASTC textures as well as the desktop ones: most ARM graphics read only the
first, and a desktop card in an ARM machine only the second. That adds under
two megabytes to the build. A tag whose version has no
section fails the workflow rather than publishing a release with nothing written
on it, and so does an APK that is not signed with the release key: nothing is
published until everything is built. The server build is Godot's own dedicated
server export, preset "Linux Server": every resource stripped of what only
drawing needs, textures and meshes left as placeholders of the same size, since
scripts and scenes still name them, and `assets/audio` left out altogether,
since no sound is loaded but by name when it plays and a server plays none. The
game run as a server, from a release with `--server` or from a checkout with
`make server`, loads no sound either, `Game.serving`, so it plays the same game
its build does; the pictures and models it does load, since only an export can
strip those. Its
`dedicated_server` feature is what makes it a server with no `--server` to give,
and headless with no `--headless`. The workflow can also be run by hand from the
Actions tab, as a dry run: the same builds, kept as the run's artifact for a
week instead of published.

The server is published as a Docker image too, `timvisee/jackpot-junction-server`
on Docker Hub, one image for x86_64 and ARM, built from the two server exports by
`docker/Dockerfile`. It is Google's distroless glibc image, which is the C library
the server's `ldd` asks for and a nonroot user to run it as, with three files on
top: the server, tini to run it under, since the first process in a container
is only given the stop signal if it asks for it and the engine does not, and
busybox as `/bin/sh`, since the engine asks a shell where the desktop is as it
starts and without one logs an error in the server and in every game. About 92
MB, nearly all of it the server. The Dockerfile only copies files in, so the ARM
half is built on the x86 runner without emulating anything. Every run builds it,
so a broken image fails a dry run; a tag pushes it, before the release itself,
as the version, `0.11.0`, and as `latest` when the tag is the newest release and
not a pre-release, `v0.11.0-rc.1`. A fix to an older version published after a
newer one leaves `latest` where it is, and the GitHub release is marked the
latest exactly when the image is. Pushing needs two repository secrets,
`DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`, a Docker Hub access token with read
and write, and a tag with either missing fails before anything is built.
`docker/compose.yaml` is the example a server is run from, `docs/SERVER.md` has the rest.

Tagging is a person's decision, not a step in a script: it says a build is worth
other people's time. The same tag builds the Steam version too and puts it on Steam's `staging`
branch, 10.8; making it the one everybody on Steam gets is a person's decision as well.

Android has an export preset of its own, `com.timvisee.jackpotjunction`, for
phones and tablets played by touch, 4.2: a 64-bit ARM build from Godot's own
template, landscape either way up, full screen, with the network permissions
online play needs. It needs no Gradle and no NDK, only an Android SDK for
`apksigner` and `zipalign` and a JDK: the editor's settings name them on a
machine of one's own, and in CI `ANDROID_HOME` and `JAVA_HOME` do.

There are two builds of it. `make android` is a debug APK in `build/android`,
signed with the debug keystore the editor's settings name, for trying things on
a phone on the desk; `make android-install` puts it on the phone adb can see.
`make android-release` is the APK a release publishes: the release template,
signed with the release key, and checked by `tools/android-signed` to be signed
with that key and nothing else, read by the newest `apksigner` that can read it:
the newest build tools can want a newer Java than the export's, and then read no
signer at all, which failed the first release run to have the check. The key is a keystore of its own, kept out of
the project and meant for other Android apps as well, since Android only
installs an update over an app signed with the same key and losing it means no
app signed with it can ever be updated again. On the machine it was made on it
is `~/.android/release.keystore`, alias `timvisee`, and its password is kept in
nothing on that machine: `make android-release` asks for it at the terminal,
tries it on the keystore before a minute of exporting rather than after, and
keeps nothing it is told. `ANDROID_KEYSTORE`, `ANDROID_KEYSTORE_ALIAS` and
`ANDROID_KEYSTORE_PASSWORD` in the environment name a keystore, a key and a
password instead of those two and the question. The keystore and its password
belong in a backup together. The release workflow has the key from three
repository secrets: `ANDROID_KEYSTORE_BASE64`, the keystore itself in base64,
`ANDROID_KEYSTORE_ALIAS` and `ANDROID_KEYSTORE_PASSWORD`. Another app's
repository takes the same three.

The version code is counted, not worked out: Android refuses an APK whose code
is lower than the one installed, so every release counts it up by one, and
`tools/changelog release` does that as it cuts the version, so a release never
has to remember to. 0.8.0 was 1, the first APK anybody could install, from the
debug key; every release after it is one more, whatever its version number. The
preset's `version/name` is left empty, so the APK takes the game's own version.

### 10.6 Assets and licensing

- Use free resources: CC0 and similarly licensed models, textures, music and
  sound effects, starting with Kenney's kits. Custom audio and sound effects
  may be made later.
- Every third-party asset and library is recorded in `THIRD_PARTY.md` with its
  author, source, license, files and modifications, so licensing is arranged
  properly before release. Adding a file means adding a row.
- The license texts go in every build with the assets they license: the export
  presets take in every `*.txt` and `*.md`, which is `THIRD_PARTY.md` and the
  licenses beside the assets, the font's, the car kit's, the sounds' and the
  music's, forty kilobytes in all. Nothing in the game reads them; they are there
  because the font's license, the OFL, asks for its text to go wherever the font
  goes, and the credits are the attribution the others ask for. Every other text
  file is left out by name: the design, the plan, the readme and the changelog.
- The game's source code is open source under the GPL-3.0. Third-party assets
  keep their own licenses. Assets made for the game are licensed separately
  under CC-BY-4.0.
- The repository lives on GitHub. GitHub Actions runs the headless gdUnit4
  tests on every push and produces export builds for Linux, Windows and macOS
  on tags. Builds are published as GitHub Releases, and on Steam, 10.8, with an
  additional permission to link the Steamworks SDK. itch.io is a backlog item.

### 10.7 Performance

The frame budget in 10.1 is a phone's: an Android build draws the same room at the
same rules, with a card a thirtieth of a desktop's and a processor a quarter as
fast, so what is cheap on a desktop is measured as if it were not. Three tools say
where a frame goes: `make bench` for the frame rate, `make profile` for the script
functions, server passes and GPU passes behind it, and `make probe` for what the
frame is made of, with the render info split by pass, which says how many
triangles and draw calls the visible pass, the shadow pass and the canvas each
take, and with `--ablate` what every group of meshes costs in each. The rules below came out of those measurements,
with the numbers that put them there.

- **Particles cast no shadows, and are drawn as balls of six or eight segments.**
  A spark or a puff of smoke is a few pixels of one flat color; a `SphereMesh`
  comes with sixty-four segments and four thousand triangles, drawn once per
  particle and again into every split of the shadow map. Before the rule, the
  particles behind four karts were six of the seven million triangles in a frame:
  the nitro flame's smoke alone was 2.8 million in the shadow pass. After it, a
  frame is 430 thousand. `ParticleLook.ball` and `ParticleLook.no_shadows` are the
  rule in code, and a trail set to "none" is not simulated at all.
- **Nothing is rebuilt every frame that can be scaled, and a light on at nothing
  is hidden.** The disco beams were `CylinderMesh` cones given a new height and
  mouth every frame, six meshes of sixty-four segments regenerated and uploaded
  sixty times a second; they are unit cones now, scaled to the throw. A dark head
  hides its light: a spot light at zero energy is still a light to every surface
  in its range, and on a phone's renderer, which lights each mesh by the lights
  touching it, five dark heads were five passes over the table for nothing.
- **Paint on the floor casts no shadow, and the sun's map has two splits.** A pad
  disc, a rim, a turbo plate, a jackpot tile, a clock segment: each is a few
  centimeters proud of the felt, and its shadow is a line nobody sees, drawn into
  every split of the map. Sixty of them came out of the shadow pass. The
  directional light draws two splits rather than four: from where the camera
  stands the whole table is in the near ones, and the far two were the karts drawn
  twice more for the room behind the stands. Rims and discs are also cut at eight
  and thirty-two segments: a torus comes with two thousand triangles, and a rim
  the width of a finger shows none of them.
- **The HUD writes on a change, not on a frame.** A theme override is a change
  whether or not the value is new: every one has the label shape its text and its
  container lay itself out again. The scoreboard was setting four fonts and five
  colors on every row of every frame, each font a new `FontVariation`; the timer
  and the speed readout their colors; every heart a redraw. `Type.set_font` and
  `Type.ink` compare first, the three font variations are made once, and a
  setter that redraws returns if it was told what it already had. Script time in
  a frame went from 1.0 ms to 0.35 ms, under the profiler.
- **A thing drawn many times is one mesh, built once.** A chip was eight
  `MeshInstance3D`s -- the disc, the face, six notches -- each with a material of
  its own, so a floor of a dozen chips was a hundred draw calls and a death that
  dropped ten built eighty meshes and eighty materials in a frame. `Bake.tinted`
  merges the pieces once with their colors on the vertices, and every chip of a
  kind draws that one mesh in one shared material; `Bake.joined` does the same
  for pieces that share a material, an item box's straps and its five brands.
  The visible pass went from 381 draw calls to 271, the shadow pass from 238 to
  147, and the distinct materials in a frame from 234 to 146.
- **A primitive is cut to what its size shows.** `SphereMesh` comes at sixty-four
  segments by thirty-two rings, `TorusMesh` at sixty-four by thirty-two,
  `CylinderMesh` at sixty-four by four: four thousand triangles for a bullet, an
  aim dot, a bomb, a bulb, a marker on a roof. The rule is a segment count set
  wherever one of these is made: six or eight round a spark, a dot or a bullet,
  twelve round a bulb or a turret's head, sixteen round a bomb or a shield,
  twenty-four round a disc, and six or eight round the tube of any torus. A shot
  also builds nothing: bullets share their meshes by radius and their materials by
  color. Four aim guides went from 16,900 triangles to 320.
- **Textures are VRAM-compressed with mipmaps.** The materials are built in code,
  so the editor's "detect 3D" step, which would have switched a texture used on
  a mesh to a compressed one with mipmaps, never ran, and every surface texture
  was imported lossless and unmipped: six full-size reads per pixel of felt at
  the far end of the table, with no mip to read from. `compress/mode=2` and
  `mipmaps/generate=true` in every import under `assets/textures`, and
  `compress/normal_map=1` on the normal maps, put them in the formats a card
  samples in a quarter of the bandwidth, ETC2 or ASTC on a phone.
- **Many of the same thing that change one at a time are a MultiMesh.** The clock
  board's thirty segments were thirty `MeshInstance3D`s with a material each, and
  the seconds ticking over wrote three values into a dozen of them a second. They
  are one `MultiMesh`: the same bar placed and sized per instance, its color in
  the instance color and whether it is lit in the instance's custom data, drawn
  by `led_segment.gdshader`. One draw call rather than thirty, and a digit is a
  handful of buffer writes. Shaders live in `.gdshader` files beside the script
  that uses them, not in strings, so the editor checks them and the phone's
  shader baker sees them.
- **Everything painted on the felt that never moves is baked with the walls.**
  `Bake.merge` was run on the walls, the litter, the crates and the props; it runs
  on the coin pads, the power pads, the turbo pads, the spawn discs, the jackpot
  tiles, the tribune steps and the tanks' feet, caps and glass too, each container
  merged to one mesh a material. A flush pad's four frame bars wear its one
  material, which is what it recolors, so they bake to one mesh a pad that still
  takes the color; a zone's bulbs and a tank's fluid wear materials of their own,
  so the bake leaves them where they are and they go on being moved. A frame of
  Lucky Crossing with four karts is 344 draw calls: 713 before any of this, of
  which 306 were the shadow pass.
- **The crowd is made as cheap as a crowd gets before a phone thins it.** Eight
  hundred onlookers were 156 triangles each, 132,000 of the 196,000 triangles in
  the visible pass, lit by the full material path: the shadow map sampled and a
  specular term worked out on every pixel of a third of the screen, for figures a
  dozen pixels tall. They are already one `MultiMesh` in two draw calls, so what
  was left was the figure and its shader. A figure is 90 triangles now, five
  sides round with one ring to a cap, which reads the same from where the camera
  stands; the crowd shaders run `shadows_disabled, specular_disabled`, since
  nobody in the crowd is in a kart's shadow and nothing that small shows a
  highlight; and the booth's speakers and DJ are cut like the rest of the small
  things. Measured by hiding the crowd through its setting: its share of the
  GPU frame went from 0.18 ms of 1.88 to 0.12 on Forward+, and from 0.24 ms of
  1.69 to 0.07 on the mobile renderer. After that, what is left to give is
  people: the crowd size setting of 8.5 rolls half as many onto the table, and
  a phone starts there. It is cosmetic either way: nobody in the crowd touches a
  kart.
- **What is off the screen is culled in blocks, never one by one from script.**
  A `MultiMesh` is culled whole, so with the house in one the far side's people
  were run through the vertex shader and clipped whenever the camera zoomed onto
  a corner. Testing eight hundred people against the frustum in GDScript every
  frame would cost more than drawing them; putting the house up as four
  `MultiMesh`es, one a side of the table, each with its own bounding box, lets the
  engine drop a whole side for nothing. Measured with the camera pulled in on one
  kart: the crowd's submitted primitives fall from 80,000 to 3,000, and its cost
  on the mobile renderer from 0.19 ms to 0.07; framed on the whole table it costs
  six more draw calls and nothing else. Not done: ordering the instances near to
  far for the mobile renderer's early depth test.
- **On a phone's renderer, a big surface is lit in tiles.** Forward+ sorts the
  lights by screen tile itself, so a mesh's size costs nothing; the mobile
  renderer lights each mesh by every light whose reach touches it, so every pixel
  of the felt and the table, one mesh each covering the room, paid for the sun,
  the fill, the lamp and every lit disco head. Lights were two thirds of that
  renderer's frame, the two surfaces 0.84 ms of 2.37 with the rig at full. On that
  renderer the two slabs are cut three tiles a side, each tile lit by what reaches
  it: 0.84 ms became 0.57, for sixteen more draw calls. A finer cut buys little,
  since a head's cone reaches across most of the table. The desktop's renderer
  keeps the slabs whole and its draw calls. The felt casts no shadow either: it
  lies on the table with nothing under it.
- **A phone lights fewer disco heads.** Each lit head is a spot light over the
  whole table, and on the mobile renderer that is a pass over every pixel of it.
  The Disco lights setting has a middle, Few, that lights three heads at most
  however far up the meter the match is and whoever has won; a phone starts
  there. The rig still cycles, so the room keeps moving.
- **The shadow map reaches as far as the camera sees, not a fixed distance.** The
  sun's shadows were drawn 80 m out from the camera whatever it looked at, so a
  camera pulled in on one kart spent most of the map on the room behind the
  stands. Each frame the reach is fitted to the far corner of the floor from the
  camera, plus room for the stands and the tanks behind it, and never under 24 m:
  framed on the whole table it comes to about what it was, pulled in it is
  sharper for the same cost.
- **Shaders are compiled behind the title, not mid-race.** Godot compiles a
  shader the first time something wearing it is drawn, tens to hundreds of
  milliseconds on a phone, and every material here is built in code, so the
  export's shader baker has nothing to bake and the first bomb, the first nitro
  and the first chip each cost a frame. `ShaderWarmup` starts a match on a
  160-by-90 viewport behind the title with the screen's own passes, the room
  built a phase a frame the way the loading screen builds one, and puts one of
  everything into it a step a frame: karts in every dress, every effect,
  every pickup, the HUD's fire, and each room's light and air. Godot keeps what
  it compiled on disk, so the first start pays and every start after it runs
  the same steps in a moment. Measured in a fresh user directory: the title
  leaves 36 shader cache entries and a match after it adds none; a match from
  cold writes 32. One step a frame rather than a thread, since GDScript cannot
  compile shaders off the main thread: the pane over the title, `WarmupPane`, is
  drawn between steps. Once
  through, `ShaderWarmup` leaves `user://shader_warmup.cfg` saying for which
  build, renderer and card it ran and how many entries the shader cache held;
  while that matches and the cache is still at least that full, it does not run
  again, so the pane is seen once per build on a machine; a step added to the
  plan changes the stamp, so a machine that has stamped compiles the new step
  too. Shipping the compiled shaders in the export instead would need every
  material to be a resource the export's shader baker can see, which is a
  bigger change than the bar. Two things the check found that a reading of the
  code would not: a material is compiled once per vertex layout, so the table's
  wood on the arena's own slab, built without tangents, and the same wood on the
  finale's `BoxMesh` are two shaders; and a `Surfaces` set of its own, as the
  finale had, is a second set of every material, since the arena turns the
  culling off on its table's. The finale reuses the arena's surfaces now, and
  the warm-up lays the wood and the felt on a box. `make warmup-check` passes on
  both renderers: after the title a match, the results and the finale compile
  nothing, 37 cache entries on Forward+ and 46 on the mobile renderer. A close
  look films the room into a viewport of its own smoothed four times over
  whatever the screen is, see `CloseLook`, and on Vulkan a material is a pipeline
  of its own for every such target: the first feed in the Garage compiled 17
  pipelines for the dyno and 40 for the Showroom, which the shader cache does
  not count. So from its close looks on the warm-up films its match the same
  way and shows that picture through the feed, and it builds the Garage's own
  pieces in it, the rolling road, the trap, the bench, the floor's paint, the
  rail and the Showroom's bay: 8 and 14 left, counted by Godot's pipeline
  compilation monitors.
- **The fill light is ambient.** Every room had a second directional light, a
  cool fill from the other side, and on either renderer a directional light is
  a pass over every pixel: 0.07 ms of a 1.8 ms Forward+ frame here, and one of
  the three passes every pixel of a phone's floor paid for. Folded into the
  ambient term at half its energy, in its own color for its share, the shaded
  sides of karts and blocks come out within a hair of where they were, side by
  side in a screenshot, for nothing. `RoomLook` keeps the fill's color and
  strength; `ArenaEnvironment.FILL_AS_AMBIENT` is the half.

- **What is quadratic in the bullets is cheap per pair, and what every bullet
  asks is asked once.** Every pair of live bullets is checked for a meeting every
  tick, which is five thousand pairs at the budget's hundred bullets; the closest
  points between two sweeps allocate, so a pair is first rejected by the distance
  between the middles of the sweeps, which nearly every pair fails. The karts and
  the targets are read off their groups once a frame and shared, `FrameGroups`,
  rather than walked once a bullet a tick, and anything that reads the shared
  list checks each node is still alive. The bots and the turrets read the karts
  the same way: a bot used to walk the group up to four times a tick, looking
  for somebody to hunt, a rival about to win and the nearest kart to shoot.
- **The camera keeps the karts clear of the HUD a few times a second, a few
  slides a frame.** Measured on a desktop with four players at the screen and
  their karts against the corners, 8.2: the HUD said what it covered every frame,
  55 µs, and now does it ten times a second; a frame between looks cost 75 µs and
  now costs what the framing costs with nothing over the screen, 20 µs; a look
  with a kart nothing could clear took 985 µs in one frame and now takes about
  130 µs at most in each of the few it is spread over, its pairs of kart and panel
  that can never meet left out and its slides cut from twenty-five to ten. The aim's
  lift, worked out every frame, went from 20 µs to 9 µs: its heights and depths
  are worked out once rather than at every one of its halvings, and fourteen
  halvings rather than twenty-four already put it under a pixel. Smoothing it,
  8.2, costs about 8 µs a frame more with eight karts and four panels, 63 µs to
  71 µs for the rig's whole frame: where each kart counts for the framing is
  worked out once a frame however often the rig asks, kept from frame to frame
  in one run of numbers, and a kart's own record is only made as it comes into
  the shot; the two eases are a few multiplications each.

**Keeping it.** The rules above are how the frame was won back; this is how it
stays won. New code is held to these, and a pull that breaks one says why:

- A mesh made in code sets its segment counts. No `SphereMesh`, `CylinderMesh`,
  `TorusMesh` or `CapsuleMesh` at its defaults: six or eight round a spark, a
  dot or a bullet, twelve round a bulb, sixteen round a bomb, twenty-four round
  a disc, six or eight round the tube of a torus.
- A particle system goes through `ParticleLook.ball` and
  `ParticleLook.no_shadows`. Nothing that is a few pixels of flat color casts a
  shadow: paint on the floor, rims, plates, segments on a board, unshaded glows.
- Many of one thing is one draw call. Things that never move and share a
  material are baked with `Bake.merge`; a thing drawn many times is one mesh
  built once with `Bake.joined` or `Bake.tinted`; things that change one at a
  time are a `MultiMesh`, in chunks the camera can cull. A material is made
  per instance only where its color changes at runtime; otherwise it is shared
  through a static cache, as `Chip.paint_for` and `Bullet._glow` do.
- Anything placed every drawn frame off a kart (the aim guide, the free-aim
  arrow, a tag over its head, the tutorial's guide arrow) is placed from
  `get_global_transform_interpolated()`
  and has `physics_interpolation_mode` off. A kart moves on the physics tick and
  is drawn smoothed between ticks; placed from `global_position`, a thing jumps
  against it wherever the screen draws faster than the physics runs.
- The HUD writes on a change. Fonts and colors go through `Type.set_font` and
  `Type.ink`; a setter that redraws returns when told what it already had;
  nothing runs `_process` while hidden.
- Shaders live in `.gdshader` files beside the script that uses them, never in
  strings. A texture under `assets/` is imported VRAM-compressed with mipmaps,
  its normal map flagged as one.
- A light that is off is hidden, not left on at zero. The mobile renderer lights
  each mesh by every light touching it, eight of a kind at most, so a light
  over the whole table is a pass over every pixel of it there: big surfaces
  are tiled on that renderer, and a new light has to earn its place.
- Per tick, nothing asks the tree for a group once per object; the list is read
  once a frame and shared through `FrameGroups`, and freed nodes are checked
  for. What is quadratic is rejected cheaply before anything is allocated.
- Nothing finds a node every frame. A node a script works with is kept from when
  it is made, or asked of whoever made it and keeps it: the touch controls and
  the mouse ask the HUD for the hand, the pick, the standings and the corners,
  `MatchHud.hand_of` and the rest, rather than looking them up by name, and the
  pause menus and the style stalls each keep a list of themselves as they come
  and go for the questions asked of them every frame. A set that changes all
  the time, such as what is lying on the floor, is gone through once a frame
  however many ask, and a physics query is made once and pointed again.
- A menu's moving pictures are drawn once and moved. A control turned or scaled
  is drawn again by the engine every frame it turns, so what turns all the time is
  a `Node2D`, as the title's sunburst and seal are; many small pictures moving at
  once are a sheet drawn once and shown as sprites, as the title's chips are; and
  a picture is drawn again only when it changes, as the title's glow is. Before
  this the title drew its seal's 48 smoothed rings again every frame and ran at
  about 200 frames a second on the desktop; drawn once, it runs at about 1350, at
  0.2 ms of the renderer's time a frame.
- The cards of a hand and of a respawn pick, 8.3, show their face, its engraving,
  index, art, name and pips, from a picture of it, drawn for the size the card
  holds still at, once it has held it a few frames; sliding or growing, a card
  shows the picture it has, stretched for the moment. Its frame, the glow and the
  gold of a card lifted or going off, and what is laid over the face, a Copy Cat's
  copy and the eye of a card to read, stay drawn as themselves. The picture is
  laid on premultiplied, so its faint lines are not made fainter. A card was
  about 57 draw calls and a hand of four about 230, which with the rest of the
  HUD came to about 540 against its 320; the hand is now about 26, and the HUD
  with a hand open, its pay table and the card's pane about 310. Measured in a
  match being played, not in its countdown.
- A picture made of many shapes or many controls that does not change is drawn
  once and shown from that, `KeptPictures`: kept for the run by what it is and
  the screen's own pixels it is shown at, rounded up to a step so a window
  dragged to another size draws a few sizes rather than one for every pixel, and
  shown as itself until it is ready. An achievement's chip is about a hundred
  shapes, and a case of them was four of every five draw calls the achievements
  dialog, 8.10, made; a card in the catalog, 8.8, is a few dozen controls, and a
  page of them was six of every seven of the catalog's. Each chip is now drawn
  once at twice its pixels, each card once with its shadow, every card face down
  in the same back once for all of them, and the NEW tag once for every one
  wearing it. On the desktop at 1920 by 1080 the achievements dialog went from
  about 1,020 draw calls a frame to about 205, 1.26 ms a frame to 0.65, dressed as
  a card table, its leather rail one mesh and its rows faded through a mask; the
  catalog from about 3,300 to about 490, 1.45 ms to 0.75. The pictures are drawn
  the first time a dialog opens in a run, which makes that frame about 85 ms
  longer, behind the shade before the pane is dealt; every opening after uses
  them. The catalog's large picture by the pane is left drawn as itself: it is
  about 30 draws, and drawing a picture of each card as the cursor first came to
  it made the cursor stutter. The loyalty program's atlas cover, 8.9, its cloth,
  contours, rules and brass and the pencil and the dividers lying on it, is drawn
  once into a picture of the pane at its size, `AtlasCover`, drawn again only
  once a window dragged to another size has rested at it a moment, and the last
  one kept for the run; the tape, a photo corner, the pencil and the slip's coil
  are drawn once each; and its slip is
  left without a slip's engraved waves and arcs, which were a hundred draws a
  frame more and change with the cursor, so cannot be a picture, and the slip
  is plain paper drawn in a few shapes, its dotted line one line of dashes; the
  pencil that lies under it on a short screen is a picture too, so the slip
  growing from landmark to landmark draws nothing again. A page turning over the
  coil is a second slip saying the last landmark, drawn into a picture of its
  own only for the half second it turns, and laid over the first as a mesh
  bent round its roll, its face and its back a triangle array each, two draws.
  The program's card in its pocket is drawn from a picture of it, made once for
  what is printed on it (`LoyaltyCardView.KeptCard`), rather than its score of
  shapes; the map's NEW tags are drawn all together, their tags and then their
  words, so they batch; and Kit's pencil marks are one stroke of segments.
  Dressed, the dialog is
  about 95 draw calls a frame, against the 325 it was as the house's pane, and
  about 850 for the two frames its layout takes to settle before its picture is
  drawn.
  The catalog's press proof is drawn the same way, `ProofCover`:
  the mat, both sheets, their marks and what lies in the foot once into one picture
  of the pane that serves both pages, what each sheet says in its foot drawn over
  it as words, and the picture kept until the pane, the sheet or a place in the
  foot moves by a pixel or more, not for the hair a layout wobbles by as the
  column beside the cards changes; the loupe, the clip, the swatch fan and the job
  ticket once each; only the crop marks at the rows' edges drawn as themselves, a
  single batch, as they move with the cards. A card not taken is its die line,
  drawn once for all of them, and the spec sheet has no engraved waves. The Stack
  field's chips, a few dozen shapes each with their notches and flecks, are drawn
  once and faded by their tint. A pane's perforation, every pane's in the game,
  is one mesh of its holes rather than a draw for each of forty or so.
  And a picture whose drawing goes with the node that asked for it first has the
  rest that wait on it ask again: the catalog's first NEW tag went as the cursor
  landed on its card, and every other tag was drawn as itself for the rest of the
  run, about six draws each. Dressed, the catalog is about 135 draw calls a frame,
  against the 620 it was with the house's pane and the cards' backs, and the
  first turn to its other page draws nothing new.
  `make dialog-bench` opens each dialog in a user directory of its own, holds it,
  then scrolls the achievements, walks the catalog's cursor along its cards or
  drags the program's map, or hangs the kart dialog's rack of hats out and walks
  along it, and fails above 300 draw calls a frame for the achievements, 300 for
  the catalog, 300 for the program and 300 for the kart dialog, so a change that
  draws their art as itself again is caught: each is two to four times its
  budget then.
- The kart dialog of 4.4a is drawn the same way: the bay, its wall, lamps, lift,
  pegboards with every hook's outline, clip and tape, the shuffle's plate, storage,
  bench and frame, one picture of the screen's size, drawn again only once the dialog
  has held one size for two frames, the pegboards' holes two meshes and every shadow
  one; each can and key one picture a run for each way it looks, only the piece on a
  hook, the words on its tape, the shuffle's button and the die drawn as themselves,
  and only the rope of the hook looked at. A hat or a flag is filmed once in a small world of its own and shown
  from then on, never read back off the screen, which held a frame up a fiftieth
  of a second for each, and no more than one is filmed for the first time in a
  frame: a rack of hats hung out at once held one up for a fifteenth of a second.
  The kart is filmed every frame in the bay built in 3D, at the screen's own
  smoothing, which the shaders are warmed up for: every plain box of the bay one mesh
  with its colors on its vertices, the wall two quads of a small texture of blocks, the
  lamps' haze one mesh, and nothing of it casting a shadow but the kart, the lamps'
  lights casting none. About 25 draw calls a frame for the bay and the kart and 12 for its
  shadows, and about 95 for all that is drawn over them, some 140 in all; the keys, the
  rail's fobs and the learner's L each one picture drawn once.
- The HUD is kept as cheap, measured the same way: the HUD of the playground's
  match with three bots shown and hidden in turn, the room held still. A chip,
  `ChipArt`, is sixty-six draw calls drawn as its shapes, a disc, eight notches,
  a ring and twenty-six flecks of clay, and the standings had four of them and
  the score pills more, two thirds of the HUD's 660 draw calls a frame. A chip
  that stays up is a kept one, `ChipArt.kept_chip`, drawn once a run at its size
  on the screen and shown from then on as one draw, the number on a place's chip
  drawn over it as itself: the standings went from 346 draw calls to 90 and the
  HUD to about 340. Behind every menu screen the backdrop's waves and arcs were
  a draw call a line, some 230 a frame, and the title's seal, `LogoArt`, 373 with
  its fine print a draw a letter; each is now drawn once a run into a picture at
  its size on the screen, `Backdrop` and `LogoArt.kept`, the school's marks too.
  The title went from about 910 draw calls a frame to 280, the settings from 430
  to 210 and the driving school from 560 to 330. The match clock drew its board,
  bolts and every faint unlit segment, then the lit digits with their glow, about
  a hundred draws; its board and unlit segments are now a picture kept for how the
  time is laid out and its ink, each lit digit a picture of its own, and only the
  glass over them is drawn as itself, about ten. The HUD is about 250 draw calls a
  frame, from 660. The match settings of 9.6 are about 300 with their columns
  folded, as a newcomer sees them, and about 470 with both open, every row on the
  screen at once; the trophy and the stopwatch on their two big buttons are kept
  pictures, `GameModeArt.kept`, where they were some thirty shapes a frame, and a
  preset's poker chip is a kept chip. `make ui-bench` puts up each, the HUD, the
  pause menu and the match settings with both columns open over a match, measured
  against the match with them hidden, and the title, the settings and the driving
  school on their own, each in a user directory of its own, and fails above 320
  draw calls a frame for the HUD, 160 for the pause menu, 520 for the match
  settings, 400 for the title, 260 for the settings and 400 for the school, so a
  chip, a seal, the backdrop's lines or the clock's segments drawn as themselves
  again are caught.
- Every new shader a player can meet is compiled behind the title. A new
  effect, pickup, kart dress, HUD piece, room, light or material with a feature
  set the game did not have -- a texture where there was none, transparency,
  emission, a billboard, a particle trail -- is a shader of its own, and it is
  added to `ShaderWarmup`'s plan in the commit that adds it, or it compiles the
  first time a player sees it, mid-race. `make warmup-check` is the proof: it
  runs the title in a user directory of its own until the warm-up is done, then
  a match with one of everything, the results and the finale, every other room,
  and over the title what is looked at closer, on a profile that has its license
  and every note (`tools/closer_looks.gd`): the license, Kit's folder with a note
  held up to the eye, and the House's invitation turned over and taken with its
  golden ticket, and first of all, under them, the invitation of STORY.md 6.1a, up from the
  start and accepted at the end, its stub torn off; and fails if any of them compiled a shader
  the title had not.
  Until it opened those, the turn that holds a card up, the folder's page turn and
  the license's hologram were compiled the first time a player looked. It is run on the mobile renderer
  too, since each renderer compiles shaders of its own. When it fails, the plan
  is what is fixed, not the check.
- Every one of these is measured before it is believed: `make bench` on the
  three maps, `make profile` for where the frame goes, `make probe
  ARGS=--ablate` for what each group costs in the visible and shadow passes
  and in GPU time, and on a phone the recipe below. The numbers go into this
  section with the change; a rule without its number is a superstition.

What the rules bought, measured on the development machine (a desktop card and
a fast processor, which is why the frame rate moves less than the counts: a phone
pays for every one of these counts), Lucky Crossing with one player and three
bots, `make bench` and `make profile` on 2026-09-30:

| | Before | After |
|---|---|---|
| Draw calls a frame | 713 | 344 |
| Primitives a frame | 7,100,000 | 240,000 |
| Of which the shadow pass | 6,200,000 | 41,000 |
| Distinct materials a frame | 226 | 137 |
| Script time a frame, under the profiler | 1.0 ms | 0.34 ms |
| Render server time a frame, on the CPU | 0.42 ms | 0.25 ms |
| Frame rate, 1080p, Forward+ | 442 fps | 516 fps |
| Frame rate, 2400 by 1080, the mobile renderer | 408 fps | 651 fps |

And on a phone, a Pixel 7 at 1080 by 2400, both builds debug exports with the
phone's own defaults, read off Show FPS in screenshots taken over adb forty
seconds into a match against three bots on Lucky Crossing:

| | Before | After |
|---|---|---|
| In the match, eight readings | 21 to 42 fps, mostly the mid-thirties | 40 to 57 fps, mostly around fifty |
| In the lobby | 45 fps | 60 fps |

The phone's screen is 90 Hz with v-sync on, so the readings step between the
rates a frame time lands on. The recipe: `make android-install` (a debug build,
so `adb shell run-as com.timvisee.jackpotjunction` can write `files/settings.cfg`
with `show_fps=true` under `[video]`), `adb shell input tap` through the title
and `adb shell input motionevent DOWN`/`MOVE`/`UP` to hold the stick onto the
ready pad, then `adb exec-out screencap -p` and read the corner.

### 10.8 Steam

The game is released on Steam as well as on GitHub, and the two are the same game: the same
version plays the other over LAN, by address and at a server, 9.3. What Steam adds is Steam's:
saves that follow an account from machine to machine, achievements on its pages, what a player is
doing in the friends list, games with friends over Steam's own network, and later a supporter
pack. None of it is in a GitHub build, not even the library it needs. Asked for on 2026-10-15,
PLAN.md M19.

#### Two builds from one project

Steam is reached through GodotSteam, a GDExtension under the MIT license, pinned to one version
(4.23.1, Steamworks SDK 1.65): a library per platform beside Valve's `steam_api`, loaded by
Godot's own export templates, so no engine of our own is built. It is not in the repository.
`make steam-addon` fetches the pinned release, checks it against its checksum, and unpacks only
what the Steam builds use into `addons/godotsteam/`, which git ignores: Windows x86_64, Linux
x86_64 and ARM64, and macOS universal. GodotSteam's updater for the editor, which asks the
internet for news, is left out.

The Steam builds are export presets of their own, "Windows Steam", "Linux Steam", "Linux ARM64
Steam" and "macOS Steam", into `build/steam/`, each with the custom feature `steam`. Every other
preset leaves `addons/godotsteam/` out, and the release workflow fails if a zip it publishes holds
a Steam library, so a checkout that fetched the addon still exports clean GitHub builds. Windows
on ARM has no Steam build of its own: neither GodotSteam nor Valve's SDK has an ARM64 library for
Windows, and the x86_64 build runs there under Windows' own emulation, as Steam itself does.
Android is not on Steam.

No script names GodotSteam's classes. The extension registers `Steam` as an engine singleton, and
the one script that talks to it, `SteamStore`, takes it from `Engine.get_singleton`, so every
script compiles, and every test runs, with the addon missing. A script naming `Steam` would not
even parse in a GitHub checkout.

#### When Steam is on

In a Steam export, by its `steam` feature, or from a checkout with `--steam`. Never on a server,
`Game.serving`, nor in the booth demo of 9.8, and `--no-steam` turns it off in any build. The
tests never pass `--steam` and never run an export, so not one of them talks to Steam: they hand
`SteamStore` a fake of their own. `make steam-run` plays from a checkout with Steam on, and `make
steam-check` asks a running Steam client the few things this section needs and prints what it
answered; it is run by hand, never by `make check`.

The game starts as Steam app `STEAM_APP_ID`, written into the build by `make steam-export`
(`data/steam/app.cfg`, never committed), or 480 when nothing names one: Valve's Spacewar, which
every Steam account may run, used until the game has an app of its own. The id is always handed to
Steam, never left to the environment: the editor on the machine the game is made on is Godot's own
Steam app, 404790, and a game run from it inherits that id.

Steam starts in `Game._init`, before the settings are read, since the folder they are read from
depends on the account. A Steam build with an app of its own, started outside Steam, asks Steam to
start it instead and quits. When Steam is not running, or not logged in, the game plays on without
it: what Steam would have been told is told the next time it is there, and the Steam friends part
of Play Online says "Steam isn't running".

#### Saves

A Steam build keeps its settings and profiles in a folder of the account playing,
`user://steam/<SteamID64>/`, with `settings.cfg` and `profiles/` in it as the GitHub build has
them at `user://`. Two accounts on one machine do not share profiles, and the GitHub build on the
same machine keeps its own. Only the profiles go to Steam Cloud. The settings are the machine's,
its screen, sound and controls, and stay on it; a new machine starts on profile 1.

The syncing is Steam's Auto-Cloud, set up on Steamworks and not in code. The files are already
written whole and in place, `SafeFile`, and Steam reads them after the game quits and writes them
before it starts. The rule is `*.cfg` in `profiles/` under the account's folder, with Steam's
`{64BitSteamID}` standing for the account, so the `.bak` beside each stays on the machine. Each
platform needs a root of its own, since Godot's folder is `godot` in lowercase on Linux;
`docs/STEAM.md` has the exact settings and the quota.

The first time an account starts the game on a machine where it has no saves, after Steam has
brought down whatever its cloud holds, the GitHub build's settings and profiles there, if any, are
copied in, once and without a word. Copied, not moved: the GitHub build goes on with its own.

#### Achievements

As 8.10's "On a store" says: the profile playing's, by their ids in capitals, all told again at
start-up and on switching to another profile, and never fewer. Linked seats tell Steam nothing.
Seven of the eight bars go to Steam as a statistic each, `<ID>_COUNT`, which Steam draws as the
achievement's own bar. Know Every Street's has none there, since its target is the nearest
district's and moves. A target that grows with the game, more jokers in Full Deck, is a number to
change on Steamworks too. Steam asks not to be told every second, so it is told in batches: a
second after the last change, at most every five seconds, and at the whistle and on the way out.

Under app 480 a debug build gives a few achievements Spacewar's names, so Steam's own pop-up can be
seen before the game has an app. A debug build with an app of its own checks Steam's list against
the game's at start and says what either lacks.

#### Presence

What the friends list says a player is doing is Steam's rich presence: a token per kind of place,
with the words in `docs/steam/rich_presence.vdf`, uploaded to Steamworks whenever it changes.

| Where | Says |
|---|---|
| Title, settings, the Clubhouse's dialogs | In the menus |
| Garage | In the Garage |
| Driving School and the driving test | At the Driving School |
| A local lobby | In the lobby |
| An online lobby | In the lobby · 3/8 |
| A single map | Playing The Vault |
| A Grand Prix | Grand Prix 2/5 · The Vault |
| A showdown | Showdown |

An online map adds the people in it, "· 4 players", bots not counted, and keeps saying it through
the results. Friends in the same Steam game are grouped, Steam's player group being the lobby. Under
app 480 the words cannot be uploaded, so the keys are checked on Steam's test page instead.

#### Playing with Steam friends

A third way to play online beside LAN and the servers of 9.3a: over Steam's own network, which
finds a friend wherever they are, through any router, and never shows an address. A Steam game is
a Steam lobby, friends-only, or invite-only if the host says so in Lobby settings; there is no
list of strangers' games. Hosting makes the lobby and opens a session on it, and the lobby carries
the game's name, its version and how full it is. Friends join from the game, from Steam's friends
list (Join game), or by accepting an invite. A game Steam starts for a friend joins once the shader
warm-up is done. Inside, it is the same session as any other, 10.3: the same knock, the version and
the room checked by the host, the same seats, kicks and watchers. A Steam game has no password.

Play Online in a Steam build has three tabs, Steam friends, Servers and LAN, 9.3, Steam friends the
first time; the networks are never on one page, and every build has the other two. Steam friends is a box of friends' games, each with Join and Watch,
grayed out with the version it needs where it is not this one, and under it Host for friends and
Invite only; with Steam not there, the box says why. The list is read again every two seconds:
Steam keeps what each friend is playing up to date by itself, but a lobby the player is not in only
says how full it is and where it plays when asked, so each friend's lobby is asked again every five
seconds. A room shows where it runs with the House's gold
rubber stamp, PLAYED ON over STEAM and FRIENDS, LAN and THIS NETWORK, or SERVER and its name:
beside how friends come in at the foot of the waiting room, and on the corner of the pause menu's
ticket. In a Steam game everybody has Invite friends in the pause menu, the room's included, over Manage
players, which
opens Steam's invite dialog over the game, or with Steam's overlay off a list of the friends online
to invite one by one, a search field over it keeping to the names with what is typed in them. The host has it first of all in Lobby settings, the first thing up as a Steam
game's room opens, before Next and with the cursor on it, inviting being what a host does there. An invite accepted at the menus joins at once; in a room, a match or another
online game it asks first, "Leave this match to join Ann?". Joining goes to Play Online saying
"Joining Ann's game on Steam...", out of whatever room was up, and on to the game's waiting room
once Steam has let the player in, or back there saying why not. Manage players in a Steam game says
everybody's name on Steam beside where they stand, "Playing · bo_92 on Steam", the host's own too,
whatever they call their kart.

The host leaving ends the game for everybody, at once. Quitting the game closes its connections
before it goes, in any online game, so nobody is left waiting for theirs to give up; and in a Steam
game everybody watches the lobby as well, so the host leaving it, for the title or for good, or
losing Steam, hangs them up the moment Steam says so. They are back on Play Online saying the
connection to the game was lost. The game is not handed to anybody: Steam passes the lobby on to
another member by itself, but the match is played on the host's machine, every kart, bot, joker and
rule of it, and none of that is anywhere else to carry on from.

A game runs on one network: a LAN game is not also a Steam game. Under the session the peer is
GodotSteam's, wrapped in `SteamPeer` the way `NetLag` wraps ENet, for two things ENet did by itself.
Packets are compressed, Zstandard on anything past a few dozen bytes, since a busy snapshot is
about 14 KB and ENet's range coder sent a tenth of that. And an unreliable ordered packet, a
snapshot, stays unreliable, a sequence number dropping a late one, where GodotSteam would send it
reliably and hold everything up behind a lost one. `NetGuard` counts a Steam peer by its account,
rather than as the "somewhere" every peer without an address would share.

#### The overlay freezing a game

On Linux, Steam's overlay can freeze a game for good: each time the window changes size, the
overlay's part inside the game opens a new connection to the overlay's own process, which does not
always take them, and once ten are waiting the next stops the game where it stands. Found on
2026-10-16 with a game started through Steam freezing as its window was resized, and reproduced
with Steam's overlay put into a game started by hand: with the overlay in, the game froze within a
dozen resizes whether Steam was started in it or not; with only half of the overlay in, the
preloaded library or the Vulkan layer, never. The game's main thread waits in `connect()` in
`gameoverlayrenderer.so`, from the overlay layer's `vkQueuePresentKHR`. It is Steam's, ValveSoftware
steam-for-linux issue 13682, games under Proton freezing on alt-tab the same way, and nothing the
game does or could do differently; the overlay off for the game, in its Steam properties, is the
way round it.

#### The name, the overlay and the version

A profile made in a Steam build starts with the account's Steam name; profiles made before keep
theirs. Steam's overlay opened over an offline match pauses it, as the pause menu does; online
nothing pauses. The title's version reads "0.18.0 · Steam".

#### The keyboard on the screen

A Steam Deck, a Steam Machine or a television has no keyboard to type a name on, so in a Steam
build a box starting to be typed into brings up Steam's floating keyboard beside it, as a phone's
keyboard comes up, 4.2. Every box the game has gets it: a profile's and a seat's name, the kart's
name tape, a password, a lobby's title, a server's name, address and port, the search over the
friends to invite. Steam's keyboard types into the box as keys do, so the box hears it the way it
hears a keyboard, and Enter on it does what Enter does there. A box starts being typed into when it
is clicked or tapped, Tabbed to, or given the cursor by its screen, as the name dialog's box is. A
pad only walks the cursor onto a box, so A on one starts it and brings the keyboard, and brings it
back after Steam's own close has put it away. A port's box gets Steam's keypad, any other the
keyboard for a line of words, and Steam keeps it clear of the box. Steam is told where the box is
once it has come to rest, two frames standing still and drawn whole, or after 0.6 s whatever it
does: a box handed the cursor as its pane is made is not laid out yet, and a pane dealt in rises
into place, 8.1a. The keyboard goes as the box is done with, the box left as the player left it
with the cursor on it; the cursor going from one box straight to another keeps it up. Asked for on
2026-10-18.

It comes up only where Steam's keyboard is the way to type: on Steam's own hardware, a Steam Deck, a
Steam Machine or a Steam Frame, and wherever Steam is in Big Picture. And not for a player with a
keyboard in hand: once a key is pressed that Steam's keyboard did not type, boxes wait for a pad's
button or a finger on the screen before they bring it up again. The mouse counts for neither, since
a Steam Deck's screen and trackpads may be one. `SteamKeyboard`, made with Steam on, gives every box
this as it comes into the tree, the way `PointerHand` gives the hand, 8.1a, and `make steam-check`
says whether the keyboard comes up on the machine it runs on.

Steam's older full-screen box for text, which hands the words back whole rather than typing them, is
not used as a fallback. The floating keyboard came with Steamworks SDK 1.53, and a Steam client older
than that is too old for the SDK the game is built with: Steam does not start in the game at all,
and Play Online says Steam needs updating.

#### A supporter pack

Later, M19's S8: a Steam DLC, "Supporter Pack", unlocking one or two pieces of kart dress. The
pieces are in every build, so they show on anybody's kart in any build, as all dress does online;
only a Steam build lets them be worn, on Steam's word that the DLC is owned, asked at every start
and never saved. In a Steam build without it they stand in the kart dialog with the dashed outline
and a "Supporter Pack" tape, and picking one opens the DLC's store page in Steam's overlay. In a
GitHub build they are not in the dialog at all. No server of ours is needed, as microtransactions
would need one.

#### Releasing on Steam

`.github/workflows/steam.yml`, beside the release workflow and not part of it, so Steam never holds
up a GitHub release. On every `v*` tag, and by hand for any ref, it fetches the addon, exports the
Steam builds with the app id, and keeps them as the run's artifact for 7 days. With the
repository variable `STEAM_APP_ID` set it also uploads them as a Steam build: depots at the app id
plus 1 for Windows, 2 for Linux and 3 for macOS, and 4 for Linux ARM64 once `STEAM_LINUX_ARM64` says
Steamworks has a depot for it, set live on the beta branch `staging`. Never on the default branch: Steam
does not let a script do that, and going live is a person's decision, as tagging is, 10.5. The
upload is game-ci's `steam-deploy`, as a builder account that can do nothing but upload, from two
repository secrets: `STEAM_USERNAME`, and `STEAM_CONFIG_VDF`, the `config.vdf` of a steamcmd that
has logged in as that account, in base64. Until the variable is set, a run builds and keeps the
builds and uploads nothing. `docs/STEAM.md` is the list of everything to set up on Steamworks once
the game has an app: the depots and the branch, the achievements with their art from `make
achievement-art`, the statistics, Auto-Cloud, the presence file, and the builder account.

#### Licensing

The game is GPL-3.0, and a Steam build links Valve's `steam_api`, which is not free software. As an
additional permission under section 7 of the GPL, the game may be linked with the Steamworks SDK
and GodotSteam and conveyed that way. The notice is in the README beside the license, and
`THIRD_PARTY.md` lists both.

## 11. Roadmap

Milestones are built in order. M4 is the first release, a complete
single-player game. M5 and M6 are the local and online releases. There is no
deadline. The task-level plan with files and verification steps is in
`PLAN.md`.

| Milestone | Scope                                                                                   | Done when                                                                 |
|-----------|-----------------------------------------------------------------------------------------|---------------------------------------------------------------------------|
| M0 Gray-box  | Lucky Crossing blockout, camera, kart handling, drift, trails, turbo pads, walls     | The kart feels good on gamepad and keyboard, crossing takes about 3.6 s   |
| M1 Combat    | Cannon, bullets, bounce and cancel, aim assist, death, respawn, spawn protection, crates, pits | Two local karts can fight, every death is attributable                 |
| M2 Economy   | Chips, coin pads, mult, graze, Junction drain, Jackpot zones, death split, HUD, tally, timer, Last Call, results | A full 5 minute solo match plays end to end with a score |
| M3 Items     | Power-up pads, first set power-ups, turret ownership, joker pick, hold, drop and destroy, floor drops, the joker catalog | Items and jokers work in a solo match, scoring tests pass |
| M4 Bots and flow | Bot brain, traits, difficulty, title screen, control hints at match start, lobby with options, settings with rebinding, countdown, results, audio pass, art pass | First release: single-player against 3 bots, start to finish, looks and sounds like the game |
| M5 Local     | Input router, join in lobby and mid-match, 4 HUD blocks, color picking                            | 4 players on one screen                                                   |
| M6 Online    | ENet, spawners and synchronizers, host-authoritative rules                           | 4 players over direct IP                                                  |

## 12. Open questions and idea backlog

Open questions:

- None at the moment. Every rule in this document is decided; the numbers are
  starting values awaiting playtests.

Idea backlog:

- A crossroads map with crossing traffic as a moving hazard. Parked: it might
  feel like a different game.
- A Junction variant that opens in pulses, 10 s open every 30 s.
- A starting joker picked in the lobby, if the opening minute feels flat in
  playtests.
- Jokers that permanently change the cannon type.
- Daily seeded challenge with a leaderboard; and with it daily specials for the loyalty program
  of 8.9, three small bets a day drawn from the date, the same on every machine.
- Kart skins and body variants.
- Online join codes via a relay, client-side prediction.
- Publishing on itch.io. Steam is 10.8.
- Mobile build with on-screen controls, Compatibility renderer.
- Spectator camera and replays.
- Lobby rules for a whole table, every kart starting at ×3 mult and the like, as landmarks of the
  loyalty program's Strip, 8.9.
