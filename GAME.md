# Jackpot Junction

This document describes the game Jackpot Junction: its gameplay, mechanics,
presentation, technology and roadmap. It is the source of truth for
implementation and will be updated as development progresses with new ideas,
decisions and features.

Unless stated otherwise, every number in this document is a starting value for
tuning, not a fixed rule. Tuning happens in playtests. When a number changes in
the game, update it here.

## 1. Vision

Jackpot Junction is a top-down arena kart game for 1 to 4 players in which
every life is a hand of cards. You drive a small, drifty kart through a
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

## 2. Core loop

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

A match lasts 5 minutes or until someone banks the target score. The final 30 s
are Last Call: the Junction pays double. Pots still unbanked when the timer
ends are lost. The highest banked score wins.

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
- A pot that would win the match takes the ring over: banked plus pot at or past
  the target score, and it stops climbing the same scale and goes flat gold, on
  and off three times a second. That is a different thing to say, so it is said
  a different way rather than as more of the first. The same pot blinks as the
  `+N` beside its owner's score in the running order, for every player rather
  than only the ones on this screen: somebody else one cash-out from ending it is
  worth knowing about. Last Call pays double, so the blink comes on no later than
  it has to and never promises a win it cannot pay.
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
| Contested        | 2 or more karts inside: collection pauses for everyone          |
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
bullets cannot take both lives in the same moment. Standing on the Junction with
an empty pot restores the lost life, and so does banking a pot dry there, see 3.4;
so does taking somebody out.
Losing the last life is death. A kart that drives into a pit falls for 0.4 s,
uncontrollable, and dies whatever its lives. On death, in this order:

1. **Bank half**: `floor(0.5 * coins * mult)` is added to banked score.
2. **Drop coins**: `floor(0.3 * coins)` chips, at most 10, scatter up to 3.2 m
   around the death spot and vanish after 15 s.
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
   of spawn protection: invulnerable, cannot fire, bullets pass through. Picking
   up coins and items is allowed. Coming back opens a ring across the floor in
   the player's color with a column of light standing in it, gone inside a
   second. The blinking says something about that kart to whoever is already
   looking at it; the flare says to the whole room that somebody is back, and
   where.

### 3.7 Jokers

Jokers are passive rule modifiers held for the rest of the match.

- On every respawn the player is offered 3 jokers during the respawn delay and
  picks 1 or skips. Offers never include a joker the player already holds,
  except stackable jokers such as Rubber Bumpers, whose copies each apply again.
- A player holds at most 5 jokers, unless a joker in the hand says otherwise:
  Deep Pockets adds 2 slots and stands in one of them. A player with a full hand
  who wants a new one must first destroy or drop one: at the respawn pick,
  choosing a joker to discard destroys it; in the arena, the joker menu lets you
  drop one on the floor or destroy it.
- Jokers can drop on death, see 3.6. A joker on the floor can be picked up by
  any kart, including its previous owner, for 15 s.
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
  pressed when it ends, which is the press this is here to stop.
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
  destroy button goes back.
- Offer weights by rarity: common 60%, uncommon 30%, rare 10%.

The joker catalog is in section 7.3.

### 3.8 Match

| Parameter       | Starting value                                            |
|-----------------|-----------------------------------------------------------|
| Duration        | 5:00                                                      |
| Target score    | 3000 banked ends the match early                          |
| Last Call       | Final 30 s: Junction pays double, Jackpot accrues double  |
| Time out        | Sudden death, see 3.13, unless the lobby option turns it off; pots still unbanked when the match ends are lost |
| Countdown       | 3 s before the karts can move                             |
| Players         | 1 to 4 humans, bots fill the remaining slots to 4         |
| Tie-break       | Most kills, then fewest deaths                            |
| Names           | 1 to 16 characters each, or one off the funny list for anybody who does not set one |

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
score and kills, ranked, then offer a rematch or a return to the lobby (in a Grand
Prix, the next map instead, see 9.7), with the cursor already on Rematch: the screen arrives on its own rather than being opened,
so it points at what most people want next instead of waiting to be found. A client,
which does not get to decide there is another match, is pointed at the way out.

The screen is headed Podium and opens with one: the top three on three steps, the winner
in the middle on the tallest, second a little lower on one side and third lowest
on the other, each with their own kart standing on top of it turning slowly on the
spot. It is a small 3D scene of its own rather than a picture, lit by its own
light in a world of its own so nothing of the arena behind it leaks in. A match of
two fills two steps.

Below it, with air between the picture and the list, the screen is built like the
joker detail pane in 8.3, so the two read as the same game: a dark translucent card
with room to breathe and a bar of color along the top, here the winner's. Each player gets a row of their own rather than a line of
text, with their place and name on the left in their own color, their color down
the leading edge of the row, their kills and deaths in gray, and what they banked
on the right in gold. The row of whoever is reading the screen is lifted a shade
out of the rest. Under each player up to three awards pick out what they did most
compared with the others, as separate chips rather than run together into one
sentence, leaders first, ranked by how far ahead of the others' average they
are: Trigger Happy (shots fired), Butterfingers (coins lost), Vacuum Cleaner
(coins picked up), Card Shark (jokers taken), Road Warrior (distance driven),
Sideways Specialist (distance drifted), Close Shave (grazes), Regular Customer
(cash-outs), Big Spender (biggest cash-out), Gadgeteer (items used), Nitro
Junkie (nitro time), Pad Hopper (turbo pads), Multiplier Maniac (peak mult),
Demolition Crew (crates), Sharpshooter (targets), Pyrotechnician (bomb kills),
Royal Flush (flushes), Bounty Hunter (bounties collected), Comeback Kid (lives
restored), Spelunker (pit falls), Own Goal (self kills), Crash Test Dummy
(deaths), Vault Cracker (chips out of the Jackpot), Power Slide (drifts carried
to the boost), Card Counter (flush pads taken) and Banana Skin (spins on oil).
Stats with a value of zero never earn an award. The list follows the game: a
mechanic worth playing around is worth counting, so anything added to the floor
gets a line here, and a line here is counted the same on every machine in the
match. A statistic that only adds up on the host is a wrong number on somebody
else's results screen, see 10.3.

- **Names.** Every player may set one in the lobby, 1 to 16 characters, in a box
  of their own beside the player list, remembered between sessions per seat.
  Steering does not cycle colors while a box has the focus, since the letters
  somebody is typing are the same keys that steer. A seat that never sets one is handed a name off a
  list of silly ones when the match starts, and no two players in a room are ever
  handed the same one, because a results screen listing P1, P2, P3 and P4 says
  nothing about anybody. A name is trimmed, cut to length and stripped of square
  brackets on the way in, since the standings and the kill feed are drawn with
  BBCode and a name is a name rather than markup. Whoever is at the table keeps
  their name through a rematch. Bots are named after the way they drive and
  practice dummies after what they are, so neither takes a name off anybody.
  Online the host owns every name in the room, as it owns everything else that
  decides what a player sees: a client says what it is called once its seat is
  assigned and the name reaches every screen in the snapshot, see 10.3. The box
  is on the online screen as well as in the lobby, since somebody joining a
  friend's match never passes through the lobby.
- A room that has lost its host says so on a pane in the middle of the screen,
  built like the joker detail pane in 8.3, and has the screen to itself: the HUD
  stands down and takes any open joker pick, the standings, the blocks and the
  control hints with it. There is nothing left in that room to answer, and a card
  pick left open under the notice would be asking for a choice about a match that
  is not there any more.
- The title screen offers Play, Play LAN, the Garage, Settings and Quit. Play
  opens the lobby, whose first question is whether it is a Grand Prix of several
  maps or a quick match on one, see 9.7. There is no tutorial. At
  the start of a match the drive and fire controls are shown next to each
  human player's kart, from the countdown until that player has both driven
  and fired, or for 10 s at most.
- The lobby exposes match length, target score, bot count, one global bot
  difficulty, the item set (basic items or all items) and whether a kart's own
  bullets hurt it, with the values in this document as defaults. Every choice is
  remembered for the next match. A map runs 1, 3, 5 or 8 minutes; a debug build
  also offers 5 seconds, first in the list, straight through to the podium for
  somebody testing what comes after it.
- Pausing in single-player and local play freezes the match for everyone.
  Online it takes the whole room: opening the menu shows it at once and asks
  the others, and the match only stops once every machine has its menu open.
  While anybody is still playing the match runs on, and the moment one of them
  closes their menu it starts again for everyone. Somebody joining a stopped
  room starts it again, and somebody leaving can be the last one holding it up.

### 3.9 Royal Flush pads

Four pads spread around the arena, marked A, K, Q and J. Driving over a pad
paints its frame in your color and takes it from whoever held it.

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
- Holding all four at once is a Royal Flush: +3 mult, a full nitro tank, and the
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

### 3.10 Bounty

Now and then a price goes on the leader's head, to give everyone else a reason
to go after them.

- No bounty in the first 45 s. After that one is called every 25 to 50 s, at
  random, but only on a leader who is at least 120 banked points clear of second
  place and alive at that moment.
- The bounty stands for 20 s. Whoever kills the carrier banks 150 points on top
  of the usual kill reward. If nobody manages it, or the carrier dies some other
  way, it lapses.
- The carrier wears a gold crown, is marked on the standings, and both the
  calling and the collecting are announced in the kill feed.
- Bots go after the carrier ahead of whoever is nearest, as long as it is within
  their hunting range.

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
letters under the middle of the screen, in the player's own color, for a couple of
seconds.

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
- A kart that dies after the whistle is offered no joker pick either. A bomb
  already in the air or a fall already begun still lands once the match is over,
  and the pick that made sat open over the podium: a question about a match that
  has already been decided. The podium takes any pick still on screen down with
  it as well, whatever put it there.
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
  the whistle goes on the hour as it did before there was an overtime.

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

## 4. Kart

### 4.1 Handling

The kart is a CharacterBody3D driven by a hand-rolled arcade car model. Its
direction of travel is separate from its heading. Each physics tick the travel
direction turns toward the heading at a grip rate, so the steady slip angle is
about the yaw rate divided by the grip: a few degrees while driving. A drift
lowers the grip and quickens the yaw, so the nose leads the travel direction by
30 to 55 degrees and the kart visibly goes sideways with the rear swung out,
then hooks up and launches when the handbrake is released.

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
| Drift entry                   | handbrake held while steering, at over 40% of top speed; steering alone never drifts, and straightening up mid-drift turns it into a stop. The slide arrives over 0.18 s and hooks back up over 0.12 s rather than switching on: a drift that lands in one tick reads as the kart teleporting sideways. A switch turns the ramp off and puts that instant drift back |
| Drift yaw multiplier          | 1.55, so a drift turns about 15% tighter than the same steering with grip |
| Drift entry kick              | the nose turns an extra 15° into the turn over the first 0.15 s of a drift started while steering, and again when the drift changes sides |
| Drift style                   | **Oversteer**, which the kart uses. A flick of the handbrake breaks the rear loose and the wheel then asks the kart to sit at an angle rather than asking for more slide: full lock into the slide holds about 40°, half lock about 24°, a straight wheel none, and opposite lock asks for less than none, which catches it. The rear chases whatever was asked for, damped so it settles rather than wallows, so a wheel held over holds an angle instead of running away. Nothing the wheel does ends the drift, since straightening up and winding on opposite lock are how a slide is driven; it is over when the slide has been caught or has bled away, which pays the usual exit boost. Catching it ends it, so opposite lock held afterwards steers rather than throwing the kart the other way, though holding the handbrake through a catch does break the rear loose again, which is how a kart is thrown from side to side on purpose. The front keeps half its steering while the rear is out, a slide past 25° scrubs up to 13 m/s² off the speed, and the tires arrest the rotation at 88°, so a slide cannot become a spin: that is what oil is for |
| Drift style, the other one    | **Tighten**, which the kart used until the oversteer one replaced it, kept whole in `data/kart/feel_tighten.tres` and second on the driving room's list so it can be driven again. Holding the wheel over holds the slide and the kart simply turns tighter: grip drops to 4.8 rad/s, the yaw rate is multiplied by 1.55, the nose kicks 15° into the turn over 0.15 s, and straightening up or letting the handbrake go ends it. It is a good mechanic and an easy one; it was replaced because the oversteer one is worth more skill for the same effort, not because it was bad |
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
not, which would otherwise cost a kart carrying a fortune nothing at all.

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

**The tire model** was an experiment of the driving room, 9.5, and was driven against the model
above and rejected. It is kept for reference and is not what the game uses.

It lost for a reason worth writing down. At 10.5 m/s on a table 60 m across, an honest tire
model understeers everywhere unless the tires are given grip no vehicle has: holding a 5 m
radius at that speed needs 2.2 g, and the lock that would ask for it needs more grip still. It
also turned a kart crawling in a corner at 69°/s where the rate model turns it at 191, which
reads as understeer even though it is the realistic answer. And winding a wheel on at a rate,
however small, is lag on the one thing this game wants to be immediate. A rate model is not a
shortcut at this speed and this scale; it is the right tool.

What it is: The stick turns a front wheel rather than the kart: the wheel winds on at a rate and
its lock comes off with speed, each axle gets a slip angle from where the kart is actually
going against where it is pointing, and each pulls sideways in proportion to that slip up to a
grip limit it cannot exceed. Yaw is what is left over when the two axles pull by different
amounts, so understeer, oversteer and drift are what the numbers do rather than states to be
entered. The handbrake takes grip off the back axle, which is the same thing a real one does.
Rubber spent holding a corner cannot also drive, so a corner taken at the limit costs speed.

Two things about it matter more than the rest. The turn radius comes from the wheel instead of
from the speed, so half the lock is about twice the circle whatever the kart is doing, and a
crawling kart turns at a rate that comes from how fast it is rolling rather than whipping round
at 191 deg/s while it travels a few centimeters. Below walking pace it hands over to plain
geometry, and stopped it still pivots at 70 deg/s to line up a shot.

One set of numbers for it is kept, `data/kart/feel_grip.tres`, so the comparison can be made
again without writing it twice.

### 4.2 Controls

Steering is kart-relative: left and right turn the nose, throttle and brake
work along the heading. Aiming is forward-only by default. All bindings are
remappable. Every action exists once in the Godot input map; an input router
assigns physical devices to player slots, see 10.2.

| Action                      | Gamepad             | Keyboard and mouse        |
|-----------------------------|---------------------|---------------------------|
| Steer                       | Left stick X        | A / D, or Left / Right    |
| Throttle                    | Right trigger       | W, or Up                  |
| Brake, reverse              | Left trigger        | S, or Down                |
| Fire                        | A                   | Space                     |
| Handbrake, drift            | Left bumper         | Shift                     |
| Nitro                       | RB                  | Ctrl                      |
| Use power-up                | X                   | E                         |
| Joker menu, hold            | Y                   | Tab                       |
| Joker menu: select          | Left stick or D-pad left / right | Arrows, A / D, brackets or 1 to 5 |
| Respawn pick: take          | Fire or use power-up | Space or E                |
| Joker menu: drop            | A                   | E                         |
| Joker menu: destroy         | B                   | Q                         |
| Free aim, Swivel Cannon only| Right stick         | Mouse position on the arena plane |
| Pause                       | Start               | Esc                       |
| Join, in lobby or mid-match | Start               | J                         |
| Mute music                  |                     | M                         |
| Menus: press the button under the cursor | A      | Enter or Space            |
| Menus: back out                          | B      | Esc                       |

The pad is knocked as well as the speaker: taking a life, dying, a big cash-out,
hitting a wall and running into another kart all come through the hands, as hard
as the thing that caused them. Knocks are held to one every 0.3 s per player, since
grinding along a wall reports contact on every tick it is touching and a pad
buzzing continuously is a pad nothing else can be felt through. A box a kart
bounces off answers as a wall does; a box it goes straight through at ramming
speed does not stop it, so there is nothing to feel. The accessibility setting in
8.5 turns all of it off.

Where two actions are the opposite ends of one control, the hints name the control
rather than both of them: on a pad the two halves of a stick are a stick, and
"Left Stick X-Axis - / Left Stick X-Axis +" describes the input map rather than
anything a thumb does. On a keyboard they really are two keys and both are named.

A menu is driven with the pad as well as the keyboard: the stick and the D-pad walk
the cursor, A presses whatever is under it and B is the Back button. Back only backs
out of somewhere there is a way out of, which is the pause menu, the lobby, the
online screen and the settings, and not the title screen, where there is nowhere to
go. While the settings are listening for a new binding, B is a binding like any
other button.

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
on it, and not if the finger slid off it first.

The left thumb steers with a stick that comes to wherever it goes down in the lower left of the
screen, and waits in that corner while nobody has a thumb on it. It only steers, so its knob
only moves side to side, and how far it is pushed is how far the wheel is turned. The right
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
buttons say what they are on them. A hint that is shown, such as the signs along the test track
of 9.4a, names the button on the screen instead of a key: gas, fire, nitro, drift and the item
as a pill with the button's word on it, and steering as the stick under the left thumb. The
Garage's sign over the jokers says to hold one to read it rather than to press Tab. The
standings hang from the top right corner under the menu button rather than down the middle of
the right-hand side, which is the slider's and the item button's, and the kill feed hangs under
them and stops short of the buttons and the slider, dropping its oldest lines. The hand of
jokers keeps to the stretch between the stick's ring and the nearest button or the slider,
shrinking its cards when that is narrower than the hand, and the respawn pick moves up, and
shrinks its own cards a little if it has to, to keep its button above the hand.

The slider is one of two ways to drive, and the settings' Controls, first there on a touch
screen, have the other: Touch driving, Slider or Buttons, put up at once, a match under way or
not. Buttons is a round button each for gas, brake, nitro and drift in an arc round the bottom
right corner with fire, the gas the biggest and nearest the corner, each only itself: drift is
the handbrake alone and nitro the nitro alone. A thumb sliding from one button to the next lets
go of the first and presses the second, and one resting on the seam between gas and fire presses
both. The item button is further in, fire being at the bottom edge already, and the nitro tank
is a ring round the rim of its button. The four click, are grayed and say reverse as they do on
the slider.

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
  stop leaves the darkest mark of all.
  Marks fade out over 20 s. Segments are capped per kart to bound the cost. They
  are laid where the model's own rear wheels are, measured off it rather than
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
  for color-blind readability.
- Four more things a player picks in the lobby, beside their name, remembered per
  seat between sessions. None of them changes how the kart drives, and the player
  color is still the player color underneath all of it: these say whose kart it
  is a second time rather than instead.

| Choice | Options                                                            |
|--------|--------------------------------------------------------------------|
| Paint  | Solid, Stripes, Checks, Spots                                      |
| Hat    | None, Cap, Top hat, Crown, Party                                   |
| Flag   | None, Pennant, Banner, Checkered                                   |
| Trail  | Smoke, Sparks, Confetti, None                                      |

- **Paint** is a pattern laid over the color rather than a second color: a
  generated texture mapped triplanar, so the model needs no unwrapping and the
  pattern sits on the kart rather than on the world. Smoothed and mip-mapped
  rather than snapped to the pixel, since a kart is a painted toy and not a
  sprite, and the podium camera comes right down to it. A striped red kart is
  still unmistakably the red one.
- **Hats** sit on the crown of the driver's helmet, and the roof marker moves up
  over whichever one is worn rather than through it.
- **Flags** fly from a pole at the back, clear of the bodywork and streaming
  behind the kart rather than out of its side. All of them are the player's color
  except the checkered one, which is the color a checkered flag is.
- **Trails** replace the exhaust smoke: sparks or confetti in the player's color,
  or nothing at all. Whatever it is still thickens with the throttle and in a
  drift, see 4.3. Confetti is thrown as tumbling blocks rather than flat squares,
  which spend half a tumble edge-on and invisible, and there is twice as much of
  it, because it has to read as a trail from the other end of the room.
- A kart is dressed the same on every screen: the four choices ride with the kart
  in the snapshot, see 10.3, and a choice a machine has never heard of is the
  plain one rather than a crash.
- A Decoy Kart wears what its owner wears, hat and flag included. It is only worth
  anything for as long as somebody takes it for you, and a kart in your color
  with none of your things on it is not you.
- The podium at the end of a match shows each kart as its owner dressed it, see
  3.8, and so does the Garage.

## 5. Combat

### 5.1 Cannon and bullets

| Parameter                      | Starting value                                     |
|--------------------------------|----------------------------------------------------|
| Aim                            | Forward-only along the kart heading                |
| Trigger                        | Holding fire shoots at the cooldown rate           |
| Fire cooldown                  | 0.4 s                                              |
| Max live bullets per kart      | 3                                                  |
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
a shooting target pays. But none of that wins a match, so a kart always comes first: it is
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
can permanently modify the cannon's stats.

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
Junction in the middle, two Jackpot zones, two pits, four Royal Flush pads, four
spawn points, four turbo pads, coin pads, item pads and crates. What differs is
the shape of the room around them.

The lobby picks one and remembers it. Online it is the host's pick: the map rides
the wire with the rest of the host's settings, see 10.3, and a client builds
nothing at all until that message has landed rather than guessing from its own
lobby and driving round the wrong room.

#### Lucky Crossing

The open one. Long lanes top and bottom, short walls screening the Jackpots from
the center, and the pits directly above and below the Junction.

```
################################
#..............................#
#.S....C.....F..........C....S.#
#.....####..B......B..####.....#
#..P......T..........T......P..#
#....C.........XX.........C....#
#.......B....C.XX.C....B.......#
#........#....JJJJ....#........#
#...KK...#....JJJJ....#...KK.F.#
#.F.KK...#....JJJJ....#...KK...#
#........#....JJJJ....#........#
#.......B....C.XX.C....B.......#
#....C.........XX.........C....#
#..P......T..........T......P..#
#.....####..B......B..####.....#
#.S....C..........F.....C....S.#
#..............................#
################################

#  wall          S  spawn point      C  coin pad       P  power-up pad
J  Junction pad  K  Jackpot zone     T  turbo pad      X  pit
R  target        D  joker pad       O  portal
B  crate         .  floor            F  Royal Flush pad
```

Every element is optional. A map with no `J` in it has no Junction, and nothing
that reaches for one finds one: the test track in 9.4 is a road with corners on
it and nothing to bank.

- The four turbo pads point along the vertical lanes at columns 10 and 21,
  each toward the opposite pad, so karts can rocket past the Junction's flanks.
- The pits sit directly above and below the Junction, so approaching from the
  top or bottom means going around them, while the coin pads next to the pits
  reward the risk.
- The short vertical walls screen the Jackpot zones from the center, so a kart
  collecting the Jackpot can only be shot from the top or bottom lane, or by a
  bouncing bullet.
- The four Royal Flush pads sit on a ring: two on the top and bottom lanes and
  two behind the Jackpot zones, so a flush is a lap of the arena.

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
#..............................#
#........#####....#####........#
#.....XX.#.CB......BC.#........#
#.C...XX.#............#.B....P.#
#........#....JJJJ....#.B......#
#..KK.........JJJJ.........KK..#
#..KK.........JJJJ.........KK..#
#......B.#....JJJJ....#........#
#.P....B.#............#.XX...C.#
#........#.CB......BC.#.XX.....#
#........#####....#####........#
#..............................#
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
#.S...C.......KKKK.......C...S.#
#............######............#
#...P#...B................#P...#
#.v...#....C........C....#...^.#
#......#....B......B....#......#
#.......#.....JJJJ.....#.......#
#.C.F...X#....JJJJ....#X.......#
#.......X#....JJJJ....#X...F.C.#
#.......#.....JJJJ.....#.......#
#......#....B......B....#......#
#.^...#....C........C....#...v.#
#...P#................B...#P...#
#............######............#
#.S...C.......KKKK.......C...S.#
#.............KKKK..F..C.......#
################################
```

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
| Coin Magnet     | 15     | 8 s: pickup radius times 3, chips within it drift toward you at 6 m/s           |
| Oil Stain       | 20     | Leaves a slick 1.8 m behind you for 25 s. Any kart whose center crosses it, you included, spins out. It never kills. The slick lies a little above the floor, clear of the Junction, the Jackpot tiles and every pad: those all stand proud of the floor, and a slick at floor level vanishes inside whichever one it was dropped on, which is exactly where somebody wants to drop one |
| Bomb            | 20     | Drops a bomb 1.8 m behind you. It arms after 0.6 s and blows up when any kart, you included, drives over it, when a bullet hits it, or after 30 s. The 2.6 m blast kills karts, breaks crates and turrets and sets off other bombs. Kills credit you |

Later set, off by default and switched on per match in the lobby:

| Power-up        | Effect                                                                          |
|-----------------|---------------------------------------------------------------------------------|
| Decoy Kart      | Spawns a bot kart in your color with a random trait, see 9.1. Lives 20 s or 1 hit. Its kills and coins credit you. Can hit you |
| Spread Cannon   | Next 6 shots fire 3 bullets in a 20° fan. The live bullet allowance triples with the fan, so the fan counts as one shot |
| Swivel Cannon   | 12 s of free aim with the right stick or mouse, no aim assist                   |
| Bullet Wipe     | Erases every bullet within 8 m                                                  |

### 7.2 Owned turrets and decoys

- Everything a turret or decoy does is attributed to its owner: kills give the
  owner +1 mult, coins a decoy collects go into the owner's pot.
- A decoy cannot collect the Jackpot and does not count as somebody standing in
  it, the same as it cannot claim a Royal Flush pad in 3.9. Parking one on the pile
  was worth more than driving there for it, and it blocked whoever did.
- They can hurt their owner, who receives no credit for that.
- They are destroyed by one hit and count as targets for aim assist and grazes
  by other players.
- Decoys collide with karts like karts do. Ramming a decoy or a turret with
  Boost destroys it; without Boost it is only a bump.

### 7.3 Joker catalog

Mostly rule benders, some stat tweaks, a few cursed jokers with a big upside and
a real downside. Starting set; balance is untested.

| Joker            | Rarity   | Kind   | Effect                                                                    |
|------------------|----------|--------|---------------------------------------------------------------------------|
| Hair Trigger     | Common   | Stat   | Fire cooldown -30%                                                        |
| Big Tank         | Common   | Stat   | +2 max live bullets                                                       |
| Magnet Hubcaps   | Common   | Stat   | Pickup radius times 2                                                     |
| Nitro Habit      | Common   | Stat   | Drift exit boosts and turbo pads last three times as long                 |
| Slipstream       | Common   | Rule   | Grazes give +1.5 mult instead of +0.5                                     |
| Green Light      | Common   | Rule   | Turbo pads give +1 mult                                                   |
| Vulture          | Common   | Rule   | Chips dropped by other karts are worth 3 coins to you                     |
| Odometer         | Common   | Rule   | +1 coin for every 20 m you drive                                          |
| Insurance Policy | Uncommon | Rule   | Bank 100% of your pot on death                                            |
| Getaway Driver   | Uncommon | Rule   | Junction drain ramps twice as fast, D = 0.25 s                            |
| Pickpocket       | Uncommon | Rule   | Kills move 50% of the victim's coins into your pot; the victim drops none |
| Rubber Bumpers   | Uncommon | Rule   | Your bullets bounce off walls once more. Stacks: two copies bounce twice  |
| Comeback         | Uncommon | Rule   | Respawn with mult equal to half your mult at death, rounded up            |
| Loaded Dice      | Uncommon | Rule   | Every chip has a 25% chance to count as a gold chip                       |
| Toll Booth       | Uncommon | Rule   | Whenever another kart completes a cash-out, you bank 15% of it            |
| Tailslide        | Uncommon | Rule   | +1 coin for every 8 m you drift                                           |
| Jerry Can        | Uncommon | Stat   | Nitro refills 4x as fast                                                  |
| Direct Debit     | Uncommon | Rule   | 5 points of your pot bank themselves every second, wherever you are. Your mult is left alone |
| Payday           | Uncommon | Rule   | +1 coin every second, wherever you are and whatever you are doing        |
| High Roller      | Uncommon | Cursed | All mult gains are doubled, but death banks 0%                            |
| Curve Ball       | Uncommon | Rule   | Your bullets curve hard toward enemies: a 55° cone out to 22 m at 150°/s, and they keep curving after a bounce |
| Aimbot           | Rare     | Rule   | Every shot leaves the barrel turned up to 14° toward the nearest enemy within 20 m and in front of you |
| Backfire         | Uncommon | Rule   | Holding the brake points your cannon out of the back of the kart, so you can answer whoever is behind you without turning round and losing the ground. The aim guide follows it. Free aim overrules it: a hand on the Swivel Cannon has already said where the shot goes |
| Road Rage        | Uncommon | Cursed | Ramming above 90% of top speed kills without Boost, but top speed is -10% |
| Snake Eyes       | Uncommon | Cursed | Start every life with mult 3, but grazes give nothing                     |
| Lucky Seven      | Rare     | Rule   | Every 7th chip you collect gives +1 mult                                  |
| Hot Streak       | Rare     | Rule   | +0.5 mult every 10 seconds you stay on the floor                          |
| Deep Pockets     | Rare     | Rule   | +2 joker slots, one of which it stands in. Stacks                         |
| Wild Card        | Rare     | Rule   | Respawn offers 5 jokers instead of 3                                      |
| Glass Jackpot    | Rare     | Cursed | Completed cash-outs pay 150%, but dying drops all your chips and 2 jokers |

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
| The Garage | The practice rooms of 9.4 | Cool strip light on a concrete bay, no sun and no weather. The place the karts are fixed in: tires, chests, cans and a two-post lift round a bay marked out on the floor. The one room with nobody in it, so its clutter is stacked against the wall of the bay rather than standing behind stands that are not there. |

The lobby names the room under the arena it belongs to, so picking a map reads as
picking a place rather than a floor plan.

Rooms are data, not code: nothing in a room decides anything about play, which is
exactly why the same match can be played in three of them. Adding a fourth is a
resource file and a map that names it.

**The light.** Every room is lit the same way and differs only in the numbers: a
key, a fill from the other side so a shadow is a dark side rather than a hole, an optional lamp hung over the middle of the table, and an
ambient that says how much the room itself glows. A lamp is what separates a room
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
between them.

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
measurement reads three times slower than the same build warm.

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
  marking on a floor that is a warning rather than a decoration. None of it is in
  the way -- a pit kills whatever falls in long before any of it is touched.
- **Jackpot zone**: a vault floor tile with a chip pile that grows, a traffic light
  for its state, and its chip count painted on the floor of the zone, the way
  a Royal Flush pad wears its letter. The number belongs to the square a kart has to
  stand in, so it is on the square rather than floating over it, and like the pad
  letters it goes behind whatever is parked on top of it rather than being drawn
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
  metal rather than plastic, and a die for the mult die.
- **Item boxes**: gold crates with black bands, a big question mark and a beam of
  light, glowing and pulsing so they read at a glance.
- **Karts**: toy go-karts with a simple driver figure, body tinted in the
  player color, a roof marker shape per color. Painted and lacquered: the body
  takes a coat of clear over the color, so the lamp over the table runs along it
  as the kart turns, and a little of the light wraps round the edge so a kart still
  reads against a dark felt.
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
- **The mark**: the Junction seen from above. A gold poker chip with the notches
  round its rim, a crossroads cut through it so the gold is left in quarters, the
  painted lines down each arm, and the pad itself lit in the middle: a cyan ring
  with the pot sitting on it. The rim wears the Junction's magenta neon, and it
  sits on a dark rounded plate so a desktop has something to put it on. The name
  is a casino and a road, and so is the mark. It is drawn in code like every other
  picture here, see 8.3a, and `make logo` writes it out as the icon the project
  wears; changing the drawing and running that is the whole of changing the logo.
- **Buttons** are the pane in miniature: a dark card with rounded corners, a rim
  faint enough to say it is a button, and the house's gold round whichever one has
  the cursor. A menu driven with a stick has to say where the cursor is without
  being pointed at, so the focused state and the hovered state are the same state.
- **The title screen** wears the mark of 8.1 over the name, and has a carnival
  sunburst turning slowly behind it,
  with poker chips drifting up past it. Drawn rather than modeled: the menu is a
  flat screen with no match running behind it, so a scene would be a scene loaded
  to be looked at once. Dark on purpose; the point of the screen is the words on
  it.
- **The score tanks**: a glass tank per player standing on the table just outside
  the arena wall, off to one side of the far edge, filling with that player's own
  color as they bank and brim-full at the target score of 3.8. The standings say
  who is ahead in numbers; this says how close anybody is to being done, which is
  the question that decides whether a pot is worth carrying another lap. Four a
  third full is a match with a way to go; one brimming is somebody about to take
  it. The crowd leaves them a bay rather than standing in front of them, and a
  room with no clock and nothing to reach has no tanks, since one that can never
  fill is furniture.
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
  smaller rather than run off the edge of it. The clock board has something better
  than a number to say at the two moments it has one: READY and SET with the
  gantry lamps of 8.3, GO! in green as the flag drops, OVERTIME flashing red
  through sudden death, and the winner's name in their own color at the whistle.
  The flash holds still for anybody who has asked for fewer of them in 8.5.
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
  The Garage has none of it, the same as it has no disco lights.

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
The driving rooms of 9.4a are unaffected: they have no arena to hold and are
following a kart down a road on purpose.

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
| Smoothing        | Exponential, 0.6 s time constant for the pan and 1.2 s for the distance, applied every drawn frame. The distance is slower on purpose: a camera that pumps in and out with every bump is worse than one that is too far off. The rig opts out of the engine's physics interpolation for that reason: it follows karts that move on the physics tick, but the following is what this smoothing is, and having both would smooth an already smoothed camera |
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
movement: the one thing a corner block must not do is ask to be looked at.

- **Banked score**, large.
- **Pot** as `chips × mult = value`, updating live, with each half in a pill of
  its own color: chips in blue and mult in red, the same two colors wherever
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
  color with the joker's own picture and its name, and one, two or three pips
  under the name for how rare it is: steel for common, cyan for uncommon,
  magenta for rare.
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
  once the hand is full.
- **Lives**: two hearts in the player color under the kill count, drawn off the
  heart curve so they have the dip and the point that tell the shape apart at
  nineteen pixels. A square said one of something and left you to work out what.
  A lost life goes dark.
- **Held power-up**: the item's own picture beside its name, both in the item's
  color, see 8.3a. While the box is still opening the picture flicks through the
  other items, which says "not yet" in the same language as the rest of the row.
- **The type.** Everything in the game is set in Inter, in three cuts and on one
  scale. Weight carries the role rather than size carrying the importance:
  anything read at a glance mid-corner -- a banked score, the clock, a heading --
  is set in the display cut, names and buttons in the middle weight, and anything
  that is a sentence in the text cut. Anything that is a number that changes --
  a banked score, the clock, a speed, a place in the standings -- is set with
  tabular figures, so every digit is the same width and the line stays where it
  is while it counts. Proportional digits move the whole line sideways on every
  tick, and a number that moves is a number read twice. Sizes come off a scale where each step is
  about a quarter larger than the one below it, because a screen with nine sizes
  on it reads as nine screens. Display lines are tracked out a little: a heavy
  face set tight reads as a shout.
- **The pane** is the shape every panel in the game is cut from: a dark translucent
  card with room to breathe, rounded corners, a shadow under it and a bar of color
  along the top. The joker pane below was the first thing built this way; the
  podium screen, the pause menu and the online lobby all wear it too, so a panel
  looks like this game's panel wherever it turns up.
- **The joker pane** describes whichever card is under the cursor, and is the same
  pane everywhere a player reads about a joker: above the hand for the card lifted
  out of the fan, and under the row for the respawn pick and again for the card
  being destroyed. It is built like a standings row so the two read as the same
  game: a dark translucent card with room to breathe and a bar of the joker's own
  kind color along the top of it. The name, how rare the joker is and what kind it
  is share the first line, a rule separates them from what the joker actually does,
  and the buttons for whatever can be done from there sit at the foot in gray,
  drawn as buttons. Things told apart beats one paragraph they were all run into.
- **The respawn pick** shows the offered cards in a straight row, the one under
  the cursor risen and grown and nothing else: it grows about its own bottom
  center, so it stays where it was along the row rather than drifting sideways as
  it swells. It takes the middle of the screen when one player is on it:
  they are dead, and there is nobody else to block. With somebody else sharing the
  screen it shrinks and drops to the bottom of its own share, with the pane above
  the cards rather than below, so it stacks off the bottom edge instead of walling
  off the arena the others are still driving in.
- **Nitro tank** as a thin bar, lit while burning.
- **Speedometer** under it: a thin dial and a number in km/h, both turning the
  nitro color while the bottle is lit. The dial is full at a kart flat out on
  nitro, so the needle still has somewhere to go when it lights. The number is the
  kart's real speed scaled by 20, which puts a kart at about 210 km/h flat out and
  400 on nitro: the honest meters a second is a single figure and says nothing
  about how the driving feels. A dead kart reads zero.
- **Control hints**, on by default and switchable in 8.5: a line under each
  player's block showing the button that drifts, the one that burns nitro and
  the one that plays a held item. Each shows only while it is worth pressing, so
  a parked kart with a full tank sees the nitro reminder alone and an item still
  rolling in its roulette shows none. The button that opens the joker menu is
  drawn to the left of the joker hand, and shows only while cards are held.
  Driving and firing are left out: they already have the hint beside the kart at
  the start of a match.
- **Joker pictures**: every joker has a flat pictogram of its own, drawn in its
  kind's color on the dark of the card. A card is recognized across the table by
  its shape; two letters at that size are a shape that has to be read first. How
  they are built, and how to add one, is 8.3a.
- **Bindings are drawn, not written.** Everywhere the game names a control -- the
  hints above, the joker hand and pick, the signs on the test track in 9.4a, the
  hint beside the kart, the join line in the lobby and the rebinding rows in 8.5
  -- the binding is a picture of the thing being pressed. A key is a key cap with
  the key on it. A gamepad face button is the round one in the color everybody's
  pad has it in: A green, B red, X blue, Y yellow, with the letter on it in the
  dark the pad prints it in. A shoulder, a trigger, Start and the stick clicks
  are pills with their name on. A stick is the gate seen from above with an L or
  an R written inside it, and a solid head each way along the axis it reads, or
  one head when only half the axis is bound. The D-pad is a cross with the
  pressed arm lit. A face button, a stick and the D-pad are drawn as buttons
  rather than on one, since each is already a shape and a box around a button is
  a box around a button; everything else is a word, and a word needs something to
  be written on.
  Everything but a face button sits on a solid dark chip with a soft black edge
  and a rim in the color of the line it is in, so it is dark against the felt,
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
- **Match timer** at the top center, turning red during Last Call.
- **Start gantry**: the countdown is a horizontal rack of three lamps hung over the
  middle of the screen, the way a racing track starts a field, rather than a number.
  They fill up red left to right and the whole row turns green on the drop, under the
  GO. A driver on the grid watches the lights, not a clock. The rack and the start
  tones are one countdown rather than two: the first lamp lights with its tone as the
  field is held, each of the rest lights with its own, and the higher tone comes with
  the green. However long the countdown is set to, there are three of each, so what a
  player sees and what they hear never disagree; over the usual three seconds that is
  a lamp a second, which is the pace anyone counting a field down counts at.
- **Kill feed** in the top right: the last five kills, newest first, reading as
  "P1 shot P2", "P1 rammed P2", "P1 bombed P2", "P1 shoved P2 in" for a pit
  shove, "P2 fell in" for a fall nobody caused and "P2 wrecked itself" for a
  self kill. Names are in the players' colors. Lines hold for 6 s and fade.
  The feed drops below a player block that owns that corner.
- **Standings**: a ranked list down the right-hand side, one row per kart with
  its banked score and, in gold beside it, whatever it is still carrying around
  unbanked. Rows are ordered by what is banked alone, the same as the results
  screen in 3.8: a pot is worth nothing until it reaches the Junction, and a board
  that counted it put a player who had won nothing at the top and dropped them
  three places for being shot. The carried pot is still shown beside the score,
  so a hot lap is plain to read without being scored. The leader's
  row is the largest and last place the smallest, and the players on this screen
  are boxed in their own color. A carried pot that would win the match blinks,
  see 3.4. It stands down in three- and four-player shared-screen games, where
  every player already has a corner block.
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
  physics.
  Royal Flush pad frames glow and pulse in their holder's color; a flush shows
  ROYAL FLUSH over the kart.
  A life going shows a heart breaking over the kart and one handed back shows a
  whole one, rather than the words that were there before: two words have to be
  read, and a player who is reading is not driving.

The tally is the payoff moment and gets the polish budget. On a completed
cash-out, chips fly from the kart into the pad while a counter above the kart
counts up with rising slot-machine ticks: `coins × mult`, then `= total`, in
about 0.8 s. Cash-outs of 500 or more add a fanfare, confetti and screen shake.
Death shows a smaller gray tally marked as half. The in-world tally plays for
every kart, so everyone sees when an opponent cashes out.

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
  music loops without a gap. Intensity 1 plays by default and in the menus.
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
  keeps it there. Two more things skip the queue. Last Call stops listening to the meter and
  walks the room up on its own clock, one level every 2 s until it is at the top,
  so the finale arrives over about ten seconds as a build rather than as a switch;
  a room already halfway up gets there sooner. And every human player being dead
  drops the room to level 1 at once, except during Last Call, which is the finale
  whoever happens to be lying in a pit for the last few seconds of it.
- The music is not switched by Last Call either. It follows the levels like
  everything else, so the full mix arrives with level 6 partway through the climb.
- **Winding up between levels**: the music bus carries a low-pass filter and a
  gain stage that follow how far through the levels the room is, 0 at level 1 and
  1 at level 6. The filter sweeps from a muffled 1.7 kHz up to fully open and the
  gain from -7.5 dB to +1.5, so an opening lap sounds like a bar with music on
  somewhere and the finale sounds like the music. The early levels are meant to
  sit under the room rather than lead it. Both sit after the bus volume, so the audio settings keep full control.
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
  sideways with nobody asking, from 13 to 43 degrees of slip, and for a spin-out;
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
  crashes for a kart into a wall, the heavier one on top of a square hit; and its
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
  its own kart, found as soon as the host says which one it is. The engine goes to
  its own bus under SFX so it can be balanced against the one-shots.
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

### 8.5 Settings and accessibility

All settings are saved between sessions, see 10.2. Anything that is on or off is a
switch rather than a tick box, drawn by the game rather than taken from the engine's
theme: an empty tick box is a dark outline on a dark menu, and a row that was off
showed nothing at all beside it. The picture is drawn at four times the size it is
shown at, with soft edges rather than stepped ones, so a big display scaling the menu
up has something to scale: a switch drawn at its own size is a staircase round every
curve of it.

From the title the settings are a screen of their own. From the pause menu of a room they open
over the room instead, and Back comes back to the pause menu: the match, and online the
connection and everybody on it, carries on underneath untouched, and a room that goes while they
are open keeps whatever was changed in them. On a pad the shoulder buttons step through the tabs,
round at the ends, and a line beside Back says so; while a rebind is listening they are bindings
like any other button.

- **Controls**: rebinding per player for gamepad and keyboard, stick dead
  zone, rumble on or off, and on a touch screen, first, how it drives: by the
  slider or by a button each, see 4.2.
- **Audio**: master, music, effects and kart volume. The karts have their own
  because their engine and tires run the whole time rather than in bursts, so
  how loud that bed should sit is a matter of taste in a way the rest is not.
  The kart bus is under the effects bus, so the effects slider still scopes it.
  A switch turns off the music going under water when a player here dies, see 8.4,
  on by default.
- **Video**: window mode, vsync, render scale, UI scale, bloom and edge smoothing.
  A phone or a tablet starts full screen, with the system's own bars out of the
  way; a desktop starts in a window. Bloom and edge smoothing are the passes over
  the whole screen a room pays for, and they are the two things worth handing back
  on a card that cannot spare them: at 1080p on a mid card the bloom is about a
  tenth of The Vault's frame and the smoothing about a twentieth, and turning both
  off is most of the difference between that room and the others. Both are on by
  default, both take effect at once, and the smoothing falls back to the cheap
  screen-space pass rather than to nothing, since a room made of straight lines
  crawls without it. The UI scale draws every menu and the HUD bigger or smaller,
  from 75% to 200% of the size they were laid out at for a screen 1080 lines high,
  and leaves the room behind them as sharp as it was. It starts at 100% on a
  desktop and at 150% on a phone or a tablet, which is held close enough that a
  HUD laid out for a monitor across a desk is a HUD of things too small to press.
  It is picked from a list rather than slid, since a slider would grow and shrink
  the screen under the pointer dragging it, and it takes effect at once. `++
  --ui-scale=1.5` on the command line uses a size for that run alone and saves
  nothing. A screen drawn bigger than the window has room for still fits: a menu
  taller than the window scrolls, the podium shrinks to it, the title leaves out
  the mark over its name, and on a touch screen the pieces of the HUD keep off
  each other, see 4.2.
- **Accessibility**: screen shake on or off, flash reduction, aim assist
  strength from 0% to 100% of the default and never above it, per player, the
  aim guide on or off, the disco lights on or off, the control hints on or off,
  the crowd on or off, and the fixed camera on or off. The crowd is on by default;
  switching it off empties the stands and leaves the booth, since it is the
  thousand moving things around the table rather than the party that is worth
  being able to stop. The fixed camera is off by default and is described in 8.2:
  a camera that never goes anywhere is a smaller picture of the karts, which is a
  real cost, and a still one, which for some players is worth more.
  Color-blind roof markers are always on.

### 8.6 Loading a map

A room takes about a sixth of a second to put up: the floor, the walls, the
thousand people round it, the clutter of 8.1 and the bake that merges the lot.
Done in one go it is ten frames in which the last screen has stopped, which reads
as the game hanging rather than as the game working.

So a map goes up a phase at a time with a loading screen over it: the name of the
room, a bar, and what is being built. The phases are the real ones -- the same list
the room builds itself from -- so the bar moves when something has actually
happened, and a room that takes longer to build shows a bar that takes longer to
fill rather than one that lies faster. It is the same screen whether the match is
local, hosted, or a client waiting on the host to say which room it is.

Anything that cannot wait a frame -- the tests, the dev scenes -- builds the room
in one go as before, which is the same room by the time it is finished.

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
for the player who is one cash-out from winning.

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
after next is decided once per waypoint as well, since a ray that grazes a corner
answers differently from one frame to the next and each answer is a different way
to aim.

**Arriving**: waypoints get a bot to the right part of the arena, but the last few
meters are their own problem. Flat out, a kart turns in a wider circle than the pad
it is aiming for, so it sails past and comes round again, forever. Inside 6 m of the
goal itself a bot eases off, down to a quarter throttle at the goal, and stops
drifting, which shrinks the circle to something that fits. With the goal behind it
and under 4 m away it backs onto it instead, because no turning circle fits at that
range. On the Junction and the Jackpot it then holds position as before.

**Drifting**: the kart drifts the oversteer way, see 4.1, so a bot throws it into a tight
corner the way a driver would: the handbrake goes in for a flick of 0.18 s when the corner is
tighter than the trait's drift angle and the kart is above 60% of top speed, with a second or
so before another is allowed. Holding it would break the rear loose again every time the slide
was caught, and walk the kart down the road sideways.

Once the rear is out a bot steers where the kart is going rather than where its nose points,
which is the same thing as winding on opposite lock at the moment a driver would. That makes
the slides short, about a third of a second: the bot catches it as soon as the kart is pointed
down the new road, which is the tidy way to use one.

**Judging them**: `make bots` runs whole matches of four hard bots on several seeds and reports
what they achieved: banked score, cash-outs, coins collected and lost, deaths and what caused
them, and how the wheel was used. It is driven by the match clock rather than by a frame count,
so two readings can be held against each other, and it is not part of `make check` because it
takes minutes. Bot work is judged on those numbers rather than on how a match looked, because a
single match of four bots is mostly luck: the first three ideas tried against it all read as
clear wins on one match and as losses over three.

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
corner twice tries the other way out rather than rocking on the spot.

**Pits**: paths already go around them, but a pit stops nothing and blocks no
raycast, so a bot cutting a corner, sliding out of a drift or chasing a kart
across one would drive in regardless. A bot checks the ground a second and a bit
ahead of itself; if a hole is in the way it comes off the throttle, drops the
nitro and steers along the edge of the hole rather than trying to turn round,
and inside 6 m it brakes as well. Short cuts between waypoints are checked
against the holes too.

What it checks for is room for the whole kart, not for its middle. A kart goes
down when any corner of it touches the hole, so a bot aiming to miss the hole
itself is a bot aiming to clip it, which is how half of all bot deaths used to
happen on a map whose two holes sit either side of the Junction. The look-ahead
also starts a little in front of the nose rather than under it, so a bot parked
beside a hole is not forever fleeing one it is nowhere near entering.

**Dodging**: for each enemy bullet within 8 m, predict the closest approach
over the next second. If it is under 1.2 m, steer perpendicular to the bullet,
with the difficulty's dodge chance.

**Firing**: fire when the shot would go through an enemy within 18 m, after the
difficulty's reaction delay, leading the target by its velocity. That is 8° off
the heading plus however wide the target is from where the bot is standing, up to
63°: a fixed angle says less and less about a miss the nearer the target is, and a
bot shoving a kart along at arm's length should be shooting it rather than only
bumping it. With nobody in reach, the same shot goes into the nearest crate or
shooting target within 13 m instead: both pay whoever breaks them, see 6.2, and a bot with
nothing else to fire at may as well be paid.

**Traits**: each bot gets one trait that shifts its goal weights.

| Trait    | Weight | Behavior                                                              |
|----------|--------|------------------------------------------------------------------------|
| Balanced | 40     | Default weights, banks at a pot value of 120                           |
| Greedy   | 15     | Banks at 200 or during Last Call, prefers the Jackpot                  |
| Cautious | 15     | Banks at 60, dodge weight times 1.5, avoids fights                     |
| Hunter   | 15     | Hunt weight times 2, banks at 120                                      |
| Bumper   | 10     | Rams constantly, seeks Boost, rarely fires                             |
| Grazer   | 5      | Deliberately weaves close to bullets, banks at 100                     |

**Difficulty**, one global setting chosen in the lobby and applied to every
bot:

| Parameter        | Easy  | Normal | Hard  |
|------------------|-------|--------|-------|
| Reaction delay   | 0.5 s | 0.3 s  | 0.15 s|
| Aim error        | ±10°  | ±5°    | ±2°   |
| Dodge chance     | 40%   | 65%    | 85%   |
| Top speed        | 90%   | 100%   | 100%  |

Bots play at the pitch the players set, which the code calls the mirror. Every
few ticks the match reads the human players' own statistics from 3.8 and turns
them into four numbers the bots use:

| Reading | Taken from                             | What it changes                                               |
|---------|----------------------------------------|---------------------------------------------------------------|
| Items   | Items used per minute, 3 is all-in     | How long a bot sits on an item, from 30 s down to 2 s, and whether it plays items cleverly at all, which needs a reading above 0.3. Also how far it will go out of its way for an item box |
| Nitro   | Share of the match spent burning nitro, a twentieth is all-in | How full a bot wants its tank before burning any, from a full tank, meaning never, down to 30% |
| Drift   | Share of distance driven sideways, a quarter is all-in | The corner a bot will yank the handbrake in, from 137°, meaning never, down to 52° |
| Effort  | Live score between the best player and the best bot, banked plus whatever is still in the pot, 600 points is a full step, held between 0.7 and 1.3 | Throttle while ahead, aim error, how readily a bot goes hunting, and the pot it settles for before heading to the Junction |

The first 45 s are measured as if they lasted 45 s, so one early item does not
peg the whole match. Traits still apply over the top: a Bumper is a Bumper
whatever the players do, it just does its Bumper things at their pitch. Effort
never pushes a bot past its own top speed, only lets it lift off when it is
winning, so the bots close a gap by playing better rather than by cheating.
Because the gap is measured against the live score rather than the banked one, a
player carrying a fat pot counts as the leader they are about to become, and the
bots come after them before they reach the Junction.

### 9.2 Local multiplayer

Shared screen, up to 4 players, gamepads plus one keyboard and mouse player.
Players join in the lobby by pressing the join button on their device, Start
on a gamepad or J on the keyboard, and pick a color by steering left or
right. The first join press claims that device for P1; until then P1 plays on
any device. Bots fill empty slots if wanted. The second release.

Joining mid-match is allowed: a press on an unused device during a match adds
the player. If a bot kart exists, the joiner takes it over and inherits its
score, pot, jokers and item, so the match stays at 4 karts. Otherwise the joiner
spawns fresh with an empty pot and 0 banked score. With 4 humans present nobody
else can join. A player who leaves mid-match hands the kart back to a bot.

On a pad, Start is both the join button and the pause button, and which one a
press is depends on whose pad it is: on a pad nobody is driving it takes a seat,
on a pad somebody is driving it pauses. A P1 still playing on any device is
driving whichever device they last drove with. Every pad answers to the
bindings, not only the first one plugged in.

### 9.3 Online multiplayer

The third release. Godot's high-level multiplayer over ENet with a
host-authoritative listen server, joined by direct IP and port from the Play
online screen. The host waits in an online lobby that lists who is in and
shows the address to join at, and presses Start when everyone is there;
players may still join a running match. Up to 4 players, bots run on the
host, and a joining client takes over a bot's kart. Design details in 10.3. A join code needs a relay
service and Steam integration needs GodotSteam; both are backlog items.
Joining mid-match follows the local rule in 9.2. Pausing an online match takes
every machine in the room asking for it, see 3.8. The match is played by the
host's lobby settings: a joining client is sent the clock, the target score,
the number of lives and the rest of the numbers its own lobby could have moved,
and drops its own. Everybody says what they are called on the way in, see 3.8.

A window in the background keeps playing. A window the desktop has stopped
drawing can hold the main loop up on the frame it is waiting to present, and on
the host that is the whole room frozen until somebody clicks back into the game.
While a machine is in an online room an unfocused window stops waiting for the
desktop and runs free at 60 frames a second instead, and is given back whatever
it had the moment it comes back.

### 9.4 The Garage

A practice room reached straight from the title screen, before anybody starts a
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
#....R.......R.......R.........#
#.S..........................S.#
#..>........................<..#
#..............................#
#...BB..B..........B..B........#
#.F............CC.........F....#
#.............JJJJ.............#
#....P........JJJJ........KK...#
#....P........JJJJ........KK...#
#.............JJJJ.............#
#.F............CC.........F....#
#...BB..B..........B..B........#
#.......XX.........D...........#
#.S.....XX...................S.#
#..........................O...#
#..............................#
################################
```

Everything the game does is somewhere on the floor. Signs name the three things a
player could not name by looking at them -- the Junction, the Jackpot zones and the
joker pad -- and nothing else: a turbo pad, a crate, a target, a pit, a coin, an
item pad and a royal flush pad are each the thing they are called, and a label over
every one of them made a room to be read rather than driven.

- A long clear straight along the top and the bottom to wind the kart out on,
  with a turbo pad at either end of the top one pointing the other way.
- Crates to slalom through and shoot, coin pads, and three shooting targets
  along the top wall that pay coins, see 6.2.
- The Junction in the middle, a Jackpot zone, a pit, four Royal Flush pads and
  two item pads carrying the full item set rather than the first set.
- A joker pad that keeps a joker lying on it, so jokers can be tried out, kept,
  dropped and destroyed without dying for them.
- Two dummy karts, parked on the spawn points down the right-hand side. Nobody
  is driving them, so they never move and never shoot back. Each one carries a
  pot of coins with a mult on it and an item in the boot, so a kill scatters
  chips and often drops the item, and each comes back after the usual respawn
  delay carrying something new. They wear their own sign rather than a sign on
  the floor, since they are the one piece of furniture in here that moves.
- Pressing join brings a second player in on another device, the same as in a
  match, and takes an empty seat rather than one of the dummies. Pausing leads
  back to the title.
- Nitro comes back 25 times as fast as it does in a match: a tank in a few
  seconds rather than a minute and a half. The scarcity in 4.1 is a rule about
  matches, and a room for finding out what the button does is the one place it
  gets in the way.
- The camera holds the bay tighter than it holds an arena. It frames the same
  three karts it always does, with one meter of floor round them instead of four:
  that band is the room a crowd sits in, and there is no crowd in here to look at,
  so the karts may as well be bigger.
- The disco lights from 8.1 stay off in here: it is a place to look at the
  controls, not a nightclub.
- No standings either: there is no clock and nothing to reach, so a table of who
  is ahead would be a table about nothing, with two dummies ranked in it.
- A portal in the bottom right leads to the test track in 9.4a.

### 9.4a The test track

The room before the Garage: the first time anybody picks Garage from the title
they arrive here instead, and every time after that they arrive in the Garage
proper. Both rooms are the same scene on a different map and each has a portal to
the other, so going round once locks nothing away.

It is a road rather than an arena: no Junction, no coins, no Jackpot, no pits,
nothing to collect and nothing to score. The hint that rides beside a kart at
the start of a match, see 3.8, is off in here: this room teaches the controls a
sign at a time, and a second copy of the same three buttons following the player
about is the room saying it twice. Six signs, each of them the name of a
lesson and a line saying what to press and what it does: "Shift to lock the
wheels" rather than "DRIFT". The bindings are read off the input map, so a player
who has rebound something is told what they bound it to, and a pad is told about
the stick rather than about its two halves, see 8.3.

The road is 97.5 by 36.25 m with six-cell lanes, wide enough to get a corner wrong
and carry on rather than stop against a wall. The straight after the boxes is
most of that length on its own, because a bottle that lasts several seconds needs
somewhere to be emptied: a straight you run out of before the nitro does teaches
the opposite of what it is for. The camera does not frame the road: it follows
the player from 26 m back the way the driving room's does in 9.5, since a road
framed end to end puts the kart too far away to see what a control did.

```
##############################################################################
#............................###########################.....................#
#.S..........................###########################.....................#
#............................###########################.....................#
#.S..........................###########################.....................#
#............................###########################.....................#
#............................###########################.....................#
#######################......###########################.....................#
######.......................###########################.....................#
######.......................###########################.....................#
######.......................###########################...######............#
######.......................###########################...#....#............#
######.......................###########################........#............#
######.......................###########################.....O..#............#
######......############################################........#............#
######.........B.....................................###...#....#............#
######.........B.....................................###...######............#
######.........B.....................................###.....................#
######.........B.....................................###.....................#
######.........B.....................................###.....................#
######.........B.....................................###.....................#
###############################################......###.....................#
###############################################....##........................#
###############################################....##........................#
###############################################....##........................#
###############################################.........##...................#
###############################################.........##...................#
###############################################.........##...................#
##############################################################################
```

1. **Drive and steer.** A straight out of the start with DRIVE and STEER on it,
   then a corner, a lane back the other way and a second corner. None of them
   tight.
2. **Shoot.** A wall of boxes across the third lane, which cannot be driven
   through. SHOOT, and the way on is where they were.
3. **Nitro.** The long straight after the boxes, 45 m of it, with NITRO at the
   near end so there is road left to use it on.
4. **Drift.** A corner down into a chicane: two stubs of wall that have to be
   woven through, with HANDBRAKE at the mouth of it and DRIFT in the middle. The
   gap between the two stubs is three cells wide. One was a keyhole to be lined
   up and crept through, which is the opposite of a corner to be drifted.
5. **The room at the end.** 26 by 34 m of open floor to keep driving in, which is
   the only part of the track with room to get a drift wrong and go round again,
   with an island in the middle of it to lean on and one way into the middle,
   where the portal to the Garage stands.

### 9.5 The driving room

A development scene, `make drive`, holding one kart, one track and nothing else: no bots, no
bullets, no pickups, no clock and no countdown, since there is nothing here to start. Driving
has to be worth doing on its own before any of the rest is worth adding, and everything else in
the game gets in the way of judging that.

The track is 60 by 37.5 m and has the four things that tell you how a kart feels:

- A straight along the top with posts every 10 m, to wind the kart out and pick a braking
  point between.
- A slalom of single posts 7.5 m apart, alternating sides, for turn-in and change of direction.
- A ring of posts on the right, to hold a constant turn around the outside or thread the inside.
- A block of 2.5 m corridors on the left, for close quarters, which is where the handling is
  hardest to get right.

The camera follows the kart from close in rather than framing the arena, because a kart twenty
pixels tall tells you nothing. A readout gives speed, how far the wheel is turned, how far the
kart is sideways, how fast the nose is coming round and how hard the tires are working in g,
so "it feels off" can be turned into a number and chased. R puts the kart back on the line.

Tab swaps the handling under the kart without stopping it, which is the only honest way to tell
two of them apart: the same corner, half a second later. The sets it walks through are in
`data/kart/`, and each is kept for a reason rather than as a souvenir.

| Preset            | What it is                                                              |
|-------------------|-------------------------------------------------------------------------|
| `feel_shipped`    | the kart as it was before any of this, frozen, so every change is judged against the real thing |
| `default`         | the kart itself                                                          |
| `feel_tighten`    | the drift it had before the oversteer one, see 4.1                       |
| `feel_snapdrift`  | the kart with the drift ramp off, so the instant drift can be compared    |
| `feel_grip`       | the rejected tire model, kept so that experiment need not be written twice |

### 9.6 The waiting room

Where everybody stands before a match starts. A menu is a poor place to wait: there is nothing
to do in one, and it cannot tell four people which of them everybody is waiting for or whether
the one who has pressed nothing is thinking or has walked off. So the waiting is done in a room
that is driven in.

It is the corner of the garage of 9.4 -- the same concrete bay, the same light, the same things
round the walls -- and it is deliberately almost empty: a pad in the middle, four spawns and
four things standing on the floor to drift round while the last player finds their seat. A
stack of wheels, a cone, and a drum with a box opposite it down one side of the room -- two marks
a few lengths apart, which is a figure of eight for anybody who wants one. The box is the only
thing in here that breaks, and it comes back in seconds rather than the half minute a box takes
in a match: it is there to be driven round, not to be hidden behind. They are solid, unlike the
clutter in every other room, because driving through the one thing there is to drive round is
worse than having nothing there.

And a football, in front of the pad, to knock about. It rolls on the floor and nowhere else: its
height is held, so no kick lifts it, and the walls and props throw it back the way they throw
back a kart. It is not solid to karts. A kart that meets it is not stopped by it as by a wall; the
ball is kicked out of its way instead, off whichever side of the kart it met, with however fast
that side was coming at it, and rolls to a stop on the concrete. The kart is the heavy thing.
A kart on nitro kicks it twice as hard, and the ball may go twice as fast for it. A shot kicks
it too: 9 m/s on the way the shot was going, and the shot is spent on it. It is heard being hit,
by how suddenly its speed changes, which every machine can see the same way: a soft thump when a
kart is close enough to have kicked it and a knock off anything else, louder the harder the hit,
and nothing while it only rolls. It
is nobody's on the pad, and a ball ever found outside the room goes back to where it started.
Online the host kicks it and tells everybody where it went, often and without waiting for an
answer; a client draws it rolling on between one telling and the next.

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
single pad filling, which in a room of four says nothing about which of them it has taken.

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
no place and no score, since nothing in here is being played for. Each player's own block in
the corner is cut down the same way: their name, their lives, their nitro and their speed, and
nothing about scoring -- no banked chips, pot, mult, kills or deaths.

**What it says.** The count is written twice: at the top of the screen for the player at this
machine, as `1 / 2 PLAYERS READY`, and on a sign standing on top of the back wall, as `1 / 2`
with `PLAYERS READY` under it.

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

A seat taken in here goes through to the arena with everybody else, and as who it was in the
room: the same color, the same name, the same dress.

**Choosing the match.** Online, the host chooses what the match is going to be in here, from the
same rows the lobby puts in front of a local one: a Grand Prix or a quick match, see 9.7, then
how many maps or which arena, how long, the target, how many bots and how hard, the
items, own bullets and what the clock running out does. They come up over the
room the moment it is opened, again from the host's pause menu, and start on whatever the host
chose last time. The room is open while they are up -- friends join and drive around -- and the
host's own karts wait where they are, since the controls are working the menu.

Everybody in the room is told what is coming, under the count:
`Next: Crossfire · 5 min · first to 3000 · 2 bots`, or for a Grand Prix
`Next: Grand Prix of 3 maps · 5 min each · first to 3000 · 2 bots`, or that the host is still
choosing. On one machine the room says what the lobby chose on the way in. The room
does not go while the host is choosing, however ready everybody else is: a match that started
halfway through the menu would be the one that was set before they began.

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

**Setting up.** Play has one lobby, and its first row asks which: Grand Prix or Quick match. The
rows under it follow the answer. A quick match picks its arena; a Grand Prix asks instead how
many maps, 2 to 6, 3 to start with, since its arenas are not chosen, they are dealt, and what
jokers carry between them. The length row reads Time per map, since it is. The host's match
settings online, 9.6, are the same rows with the same first question. Whichever was chosen last
is where the row starts next time.

**The waiting room first.** Starting a Grand Prix does not start a map. Everybody goes to the
waiting room of 9.6, and the first map begins when everybody playing is parked on the pad --
on one machine as much as online, since a room of four people on one screen has the same
question of who is ready. Only then is the playlist dealt, when everybody who is going to play
it is there.

**The playlist.** Every arena comes round once before any comes round again, and no arena is
played twice running, so a run of three plays each of the three once and a run of six plays
each twice, never back to back. The run is the host's; each map is told which one of how many
it is, so a client knows as well as the host whether its podium leads on.

**Between maps.** A map that is not the last ends on its podium as any map does, with one way
on: Grand Prix results, the run's standings so far, see The end below, headed Standings after
map so many of so many. Those have one way on: Next map. There is no rematch of a map in the
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
| Pick one to keep    | The one each player picks as the next map starts                    |
| Keep one at random  | One of each hand, drawn at random -- the choice to start with       |
| Keep all            | The whole hand                                                      |

The podium of the map just finished says which rule the run is on. Choosing is done where a card
is always chosen: on the joker pick of 3.7, as the next map starts, with the jokers the player held
at the whistle, under "Keep which joker for this map?". It cannot be skipped, since the rule is
keep one. The karts are frozen on the grid and the lamps wait for everybody's pick, so the stick
that steers moves the cursor and nothing is driving while somebody reads. Nobody is waited for
past 15 s: a pick still open then keeps one of its jokers at random. A player with only one joker
keeps it without being asked, since a choice of one is not a choice, and every bot keeps one at
random, having nobody to choose for it. Online a client works its own pick the way it does a
respawn's and the host's answer is the one that counts; a seat kept for a client holds its pick
open until the client sits in it. Everybody else sees who the lamps are waiting on. The other
rules' jokers are in everybody's hands before the lamps go. Nothing is carried out of the last map.

**The same bots.** The bots are chosen once, when the playlist is dealt, and drive every map of
it: the same number, in the same seats and colors, each with the same way of driving and so the
same name. The Hunter in the second seat on the first map is the Hunter in the second seat on the
last. A seat kept for a player at another machine is dealt a way of driving too, for the maps it
spends as a bot -- before its player has sat down, or after they have left.

**Points.** Each map is won the way a single one is, on banked chips, and pays points by where
everybody finished it:

| Place  | 1st | 2nd | 3rd | 4th | 5th | 6th |
|--------|-----|-----|-----|-----|-----|-----|
| Points | 10  | 7   | 5   | 3   | 2   | 1   |

The run is won on points, by a bot as readily as by anybody. Level on points, whoever won more
maps is ahead, then whoever banked more over the whole run: a tie between a player who won a map
and one who never did is not one anybody watching would call even. Second on every map beats a
win and two lasts. Every podium in the middle of a run says, on each row, what that place paid
and what it makes over the run so far. The host scores each map at its whistle and tells the
room how the run stands, and every screen draws its podium from that.

**The end.** The last map ends on its own podium first, the same as every map before it: the
map's results, what each place paid and where that leaves everybody. Its one way on is Grand
Prix results, which is everybody's to press, a client's as much as the host's, since it only
changes what that screen shows.

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
moved is an arrow: green and up for a climb, red and down for a fall. Only then does the board in the arena, which
names the winner at every whistle, name the champion of the run instead of the last map's
winner. The run's podium's ways on are Back to lobby, to the waiting room online and to Play's
lobby on one machine, or back to the title.

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
| Performance budget  | 60 fps on a mid-range laptop iGPU with 4 karts, 100 live bullets and full trails |

### 10.2 Architecture

Scenes with a colocated script are the unit of composition. Data lives in
Resource files. Rules that need code, such as jokers, are a Resource paired
with a small script that implements hooks.

```
res://
├── addons/            gdUnit4 and other addons
├── assets/            models, textures, audio, fonts
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
├── GAME.md
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
  saved with ConfigFile under `user://`. Nothing else is persisted yet. Match
  history, statistics and unlocks wait until there is something to unlock.

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

The cost of a longer life is that nothing is cleaned up by a scene change any more. Whatever the
session holds is held until it is closed, so closing is somebody's job rather than something
that happens by itself. The one thing it lets go of on its own is the match it was playing: the
moment that match leaves with its room, the session holds nothing until the next room takes it
over, and ignores whatever arrives in between rather than handing it to a match that is gone. It is also the first half of what a dedicated server would need: such a
server runs room after room with the same clients connected throughout, which a session owned by
a scene can never do. The second half -- a match with no local seat, and no HUD or camera for
nobody to look at -- is separate work and untouched by this.

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

Seated is not the same as there. A client still has the room to build once it knows which one
it is, and a slower machine than the host's used to arrive to a countdown already running, or to
a match already going. So on arriving at a map the host holds the field on the grid, lamps dark,
until every client has said it has the room up. Every screen shows how many players it is still
waiting on, out of everybody playing, over a bar that fills as they arrive. Nobody is waited for
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
award itself anything, hurt anybody, or decide that it picked something up.

| Question | Answered by | How the other end finds out |
|----------|-------------|------------------------------|
| Where my own kart is | the client driving it | it sends its answer with its controls; the host follows it |
| Where anybody else's kart is | the host | the snapshot, thirty times a second |
| Two karts touching | the host | it takes the wheel off both for a moment, and says so |
| Nitro burning, and the tank | the client predicts, the host confirms | the message addressed to that client |
| A turbo pad's shove | the client predicts it | nothing to send: the pad is in the same place on both |
| Going down a hole | the client predicts the fall | the host decides the death, in the snapshot |
| Breaking a box by ramming it | the client predicts it | the host settles it within a second, in the snapshot |
| Pulling the trigger: cooldown and sound | the client | nothing to send; the host's word for it is dropped on the way in |
| The bullet itself | the host | the snapshot |
| Who hit whom, who died, lives | the host | the snapshot and relayed events |
| Coins, pots, cashing out, score | the host | the snapshot |
| What is on the floor and who took it | the host | the snapshot, as what changed |
| Items held and items used | the host | the snapshot |
| The joker pick in front of me | the client works its own | the host decides what is actually held |
| Statistics and awards | the host | the snapshot |
| The clock, the state, Last Call, overtime | the host | the snapshot |
| Jackpot, Royal Flush pads, the bounty | the host | the snapshot |
| Excitement, music, lights, the crowd, the announcer | every machine, for itself | nothing is sent; the same events arrive at both |
| Match rules: clock, target, lives | the host | sent once, before a slot is handed out |
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
- The connection uses ENet's range coder both ends. A snapshot is still bigger than
  one datagram: it is split against the MTU of 1392 bytes *before* the datagrams
  are compressed, and an unreliable packet in pieces is lost whenever any piece
  is. Fitting one in a single datagram is a job for a smaller snapshot, not a
  smaller wire, and is open. Measured on a four-bot match, a busy snapshot is
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
  second. Two things are still worth doing: write entries as plain values instead
  of dictionaries, and split the fast-changing sections from the slow ones so the
  slow half goes less often.
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
  The few pickups that are actually going somewhere — pulled in by a Coin Magnet,
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
- **The joker pick**, which is not physics at all. The cursor moves and the card
  is taken on the tick the key goes down, and the snapshot leaves that one pick
  alone while it is open rather than walking the cursor back to where the host had
  it a round trip ago.

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

  The cap on bullets in the air is the host's count, which is a round trip old, so
  a client counts the shots it has pulled since against the same limit. That makes
  it cautious: held down against a full sky it stops answering and waits, because a
  shot promised and not delivered is worse than one that arrives late. Firing at a
  sky with room in it, which is how anybody actually plays, is answered at once.

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

### 10.4 Conventions

- Static typing everywhere. The `untyped_declaration` warning is treated as an
  error in project settings.
- `snake_case` for files, functions, variables and signals. `PascalCase` class
  names via `class_name`. Signals are named in the past tense, `coin_collected`.
- One script per scene, colocated and named after it: `kart.tscn`, `kart.gd`.
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
| `tools/changelog release X.Y.Z` | Turns `Unreleased` into a dated `X.Y.Z`, sets `project.godot`, and fixes up the links at the foot |
| `tools/changelog extract X.Y.Z` | Prints one version's notes. The release workflow uses it            |

A release is therefore: cut it, read it over, commit, then tag `vX.Y.Z` and push
the tag. The tag starts the release workflow, which exports Linux, Windows and
macOS builds and publishes them with that version's changelog section as the
release notes, GitHub's own list of commits appended underneath. A tag whose
version has no section fails the workflow rather than publishing a release with
nothing written on it.

Tagging is a person's decision, not a step in a script: it says a build is worth
other people's time.

Android has an export preset of its own, `com.timvisee.jackpotjunction`, for
phones and tablets played by touch, 4.2: a 64-bit ARM build from Godot's own
template, landscape either way up, full screen, with the network permissions
online play needs. `make android` builds a debug APK in `build/android` and
`make android-install` puts it on the phone adb can see. It is signed with the
debug keystore the Godot editor's own settings name, and built with the Android
SDK and the JDK they name, all three on the machine rather than in the project,
so the release workflow does not build it and the preset holds no keys. Its
version code stays at 1 until a build goes anywhere but a phone on a desk.

### 10.6 Assets and licensing

- Use free resources: CC0 and similarly licensed models, textures, music and
  sound effects, starting with Kenney's kits. Custom audio and sound effects
  may be made later.
- Every third-party asset and library is recorded in `THIRD_PARTY.md` with its
  author, source, license, files and modifications, so licensing is arranged
  properly before release. Adding a file means adding a row.
- The game's source code is open source under the GPL-3.0. Third-party assets
  keep their own licenses. Assets made for the game are licensed separately
  under CC-BY-4.0.
- The repository lives on GitHub. GitHub Actions runs the headless gdUnit4
  tests on every push and produces export builds for Linux, Windows and macOS
  on tags. Builds are published as GitHub Releases only for now. Other channels
  such as itch.io and Steam are backlog items.

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
- Team mode, 2 against 2 with a shared banked score.
- Daily seeded challenge with a leaderboard.
- Kart skins and body variants.
- Online join codes via a relay, client-side prediction.
- Publishing on itch.io, and on Steam via GodotSteam.
- Mobile build with on-screen controls, Compatibility renderer.
- Spectator camera and replays.
