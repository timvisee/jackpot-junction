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
when to drive to the Junction in the centre of the arena to cash your pot out.
Cashing out takes up to a few seconds, during which you are exposed. Dying banks
only half.

It is a relatively small but polished arcade game with no fixed deadline. It
is built in stages: single-player against bots first, then local shared-screen
multiplayer, then online multiplayer.

### 1.1 Design pillars

1. **Push your luck.** Everything you hold can be lost. Banking is a decision,
   not an event, and bigger pots take longer to bank.
2. **Readable chaos.** One screen, muted floor, bright colour-coded bullets.
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
| Pickup radius                   | 0.9 m from kart centre                  |
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

The Junction is a pad in the centre of the arena. Banking is a channel with a
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
- Standing on the Junction patches a wounded kart up to two lives, see 3.6, but a
  pot has to go in first: the life comes with the last coin of the cash-out, which
  is exactly when the kart is most worth shooting. A kart that rolls on with
  nothing to bank is owed the life straight away.

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
| Last Call        | Accrual doubles                                                 |
| Signal           | Traffic light on the zone: red below 20 chips, amber below 60, flashing green when full |

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
   that the held power-up drops, both a couple of metres clear of the wreck.
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
   up coins and items is allowed.

### 3.7 Jokers

Jokers are passive rule modifiers held for the rest of the match.

- On every respawn the player is offered 3 jokers during the respawn delay and
  picks 1 or skips. Offers never include a joker the player already holds,
  except stackable jokers such as Rubber Bumpers, whose copies each apply again.
- A player holds at most 5 jokers. A player holding 5 who wants a new one must
  first destroy or drop one: at the respawn pick, choosing a joker to discard
  destroys it; in the arena, the joker menu lets you drop one on the floor or
  destroy it.
- Jokers can drop on death, see 3.6. A joker on the floor can be picked up by
  any kart, including its previous owner, for 15 s.
- Players start a match with no jokers. The first offer comes with the first
  death.
- The offer stays open until the player picks or skips. Respawn waits for the
  choice, but never happens before the 3 s delay has passed. The match keeps
  running meanwhile.
- The joker menu can be opened while driving; the kart stays fully
  controllable.
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

The joker catalogue is in section 7.3.

### 3.8 Match

| Parameter       | Starting value                                            |
|-----------------|-----------------------------------------------------------|
| Duration        | 5:00                                                      |
| Target score    | 3000 banked ends the match early                          |
| Last Call       | Final 30 s: Junction pays double, Jackpot accrues double  |
| Time out        | Pots still unbanked when the timer ends are lost          |
| Countdown       | 3 s before the karts can move                             |
| Players         | 1 to 4 humans, bots fill the remaining slots to 4         |
| Tie-break       | Most kills, then fewest deaths                            |

Flow: Title screen, Lobby, Countdown, Playing, Last Call, Results. At the
whistle nobody is stopped dead: every driver lets go of the wheel and the karts
roll to a halt on their own, out of anyone's control and out of reach of pits,
hazards and the Junction alike, while the rig swings onto the winner. Results
show every player's banked score and kills, ranked, then offer a rematch or a
return to the lobby. Under each player up to three awards pick out what they did most compared with
the others, leaders first, ranked by how far ahead of the others' average they
are: Trigger Happy (shots fired), Butterfingers (coins lost), Vacuum Cleaner
(coins picked up), Card Shark (jokers taken), Road Warrior (distance driven),
Sideways Specialist (distance drifted), Close Shave (grazes), Regular Customer
(cash-outs), Big Spender (biggest cash-out), Gadgeteer (items used), Nitro
Junkie (nitro time), Pad Hopper (turbo pads), Multiplier Maniac (peak mult),
Demolition Crew (crates), Sharpshooter (targets), Pyrotechnician (bomb kills),
Royal Flush (flushes), Bounty Hunter (bounties collected), Comeback Kid (lives
restored), Spelunker (pit falls), Own Goal (self kills) and Crash Test Dummy
(deaths). Stats with a value of zero never earn an award.

- The title screen offers Play, Settings and Quit. There is no tutorial. At
  the start of a match the drive and fire controls are shown next to each
  human player's kart, from the countdown until that player has both driven
  and fired, or for 10 s at most.
- The lobby exposes match length, target score, bot count, one global bot
  difficulty, the item set (first set or all items) and whether a kart's own
  bullets hurt it, with the values in this document as defaults. Every choice is
  remembered for the next match.
- Pausing in single-player and local play freezes the match for everyone.
  Online matches cannot be paused.

### 3.9 Royal Flush pads

Four pads spread around the arena, marked A, K, Q and J. Driving over a pad
paints its frame in your colour and takes it from whoever held it.

- Every pad you hold pays you 1 coin a second into your pot, for as long as you
  hold it, so a single pad is worth taking and worth defending. The rate runs with
  the excitement level in 8.4: three times as fast at level 6 as at level 1, so
  the pads pay best exactly when the room is worth being out in. A holder who is
  dead, falling or rolling out the end of the match earns nothing while they are;
  the pad keeps their colour and waits for them.
- Every coin paid throws a ring of light off the pad in its holder's colour,
  growing outward and fading over 0.7 s, so four pads ticking over read as four
  pads ticking over from anywhere on the table. The ring is square like the pad
  and lined up with it, not stood on a corner.
- Holding all four at once is a Royal Flush. The bonus is unchanged by the
  trickle: +3 mult and a full nitro tank, announced to everyone with a fanfare.
- A claim lapses on its own after 30 s, the frame dimming over the last 12 s of it,
  and driving over your own pad again renews it for another 30 s. A flush has to be
  put together inside that window and then kept up; three pads cannot be banked for
  the whole match while their holder waits for a chance at the fourth.
- All four pads clear and stay disabled for 20 s after a flush, then come back
  neutral.
- Pads keep their colour when their holder dies, so a flush can be finished
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
| Yaw rate at top speed         | 128°/s, interpolated linearly by speed: 4.7 m of turning circle flat out, chosen between a 5.5 m one that would not place the kart and a 4.2 m one that turned in on itself |
| Minimum speed to steer        | none: turning on the spot at 85°/s and turning on the wheels are one control, mixed by speed and fully on the wheels by 2.2 m/s. A kart shuffling about in a corner crosses that range over and over, and the old hard switch at 0.5 m/s stepped from 70 to 195°/s every time it did |
| Grip, normal                  | travel direction turns toward the nose at 30 rad/s, so the kart goes where it is pointed within about 33 ms |
| Grip, drifting                | 4.8 rad/s, 35 to 55° of slip depending on speed       |
| Drift entry                   | handbrake held while steering, at over 40% of top speed; steering alone never drifts, and straightening up mid-drift turns it into a stop |
| Drift yaw multiplier          | 1.55, so a drift turns about 15% tighter than the same steering with grip |
| Drift entry kick              | the nose turns an extra 15° into the turn over the first 0.15 s of a drift started while steering |
| Drift speed decay             | 5% per second                                         |
| Drift exit boost              | +20% top speed for 0.8 s if the drift lasted 0.6 s or longer |
| Handbrake                     | with steering above 30% it starts a drift and scrubs speed at 4.2 m/s²; without steering it is a straight stop at 22 m/s², about half a second from top speed, that lays down skid marks |
| Nitro                         | held button, and a throttle in its own right: it pushes the kart forward whether or not the accelerator is held, though braking still overrules it. 190% top speed with 1.5 times the acceleration, steering at 60% and grip at 55%, so it is fast and a handful, kills on contact; a full tank burns 2 s and takes 90 s to refill from empty, starting 0.6 s after letting go; a kill refills half a tank; the tank is kept across deaths; cannot restart below 20% |
| Wounded                       | one life left: top speed 85%, body tinted darker until a cash-out or a kill restores the life |
| Spin-out                      | crossing an oil stain: the nose whips around at 420°/s for 1.1 s while grip drops to 0.8 rad/s, so the kart keeps its line and skids; steering and throttle do nothing and speed bleeds at 3 m/s² |
| Wall glance                   | hitting a wall within 35° of it turns the nose 60% of the way along the wall, nudges the kart 1.2 m/s off it and costs at most 15% speed; steeper hits are stopped by the wall and cost 30% speed above half of top speed |
| Turbo pad                     | fires once the kart's centre is on the pad, not when its bumper touches the edge; shoves along the pad's arrow at 150% top speed without turning the kart. Facing within 45° of the arrow, or straight against it, the shove lasts 1.0 s and the kart simply runs faster, forward or in reverse; crossing sideways gives a 0.15 s shove after which the tires slip and the kart slides most of it off, keeping enough to drive out of: the sideways slip friction that used to leave it standing was part of the kart fighting its driver. Steering halved while the shove lasts, and the shove ends the moment the driver asks for the kart back: braking, the handbrake or putting the wheel properly over hands it over at once with the speed still on it, so two pads pointing at each other are not a trap |
| Sideways slip friction        | outside a drift, sliding more than 10° sideways brakes at up to 7 m/s² at a right angle; past 20° of slip the grip fades to 4 rad/s. Both were harsher, and both read as the kart fighting the driver rather than as weight |
| Wall contact                  | velocity into the wall is cancelled; if that component exceeded 50% of top speed, total speed drops by 30% |
| Kart to kart bump             | both karts pushed apart at 6 m/s along the contact normal and lose 20% speed |

Ramming only kills when the rammer has the Boost power-up active, see 7.1, or
is burning nitro. Turbo pads do not enable ramming kills.

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
at 191 deg/s while it travels a few centimetres. Below walking pace it hands over to plain
geometry, and stopped it still pivots at 70 deg/s to line up a shot.

Four sets of numbers for it sit in `data/kart/feel_*.tres`, cycled with Tab in the driving
room: a grippy go-kart, a loose rally car, a forgiving arcade kart and a heavy one.

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
| Fire                        | Right bumper        | Space                     |
| Handbrake, drift            | Left bumper         | Shift                     |
| Nitro                       | B                   | Ctrl                      |
| Use power-up                | A                   | E                         |
| Joker menu, hold            | Y                   | Tab                       |
| Joker menu: select          | Left stick or D-pad left / right | Arrows, A / D, brackets or 1 to 5 |
| Joker menu: drop            | A                   | E                         |
| Joker menu: destroy         | X                   | Q                         |
| Free aim, Swivel Cannon only| Right stick         | Mouse position on the arena plane |
| Pause                       | Start               | Esc                       |
| Join, in lobby or mid-match | Start               | J                         |
| Mute music                  |                     | M                         |

### 4.3 Trails

- **Tire marks**: a ribbon mesh per rear wheel, drawn while the kart moves,
  darker and wider while drifting or braking. Straight driving leaves a barely
  visible trace; a full drift leaves a clear skid at just under half opacity.
  Marks fade out over 20 s. Segments are capped per kart to bound the cost.
- **Smoke**: a faint exhaust particle trail whose rate scales with throttle,
  with bursts on drift entry, drift exit boost, turbo pads and Boost.

- **Nitro**: a flickering blue-white flame from the exhaust with a warm glow on the
  floor, a trail of tiny glowing sparks left behind that fade over a second, and a
  thick plume of smoke thrown backward that swells as it drifts, much heavier than
  the faint exhaust trail of ordinary driving.

### 4.4 Customisation

- One kart body at first. Player colour is a material tint on the body
  and the bullets.
- 8 player colours, see 8.1. Each colour also has a distinct roof marker shape
  for colour-blind readability.
- Skins and body variants come later.

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
| Muzzle                         | 1.0 m ahead of the kart centre                     |
| Own bullets                    | Stopped by the owner and destroyed either way, harmless by default and deadly with the lobby option in 3.8 turned on. A kart's turret and decoy shoot its own bullets, so the same answer covers those |
| Bullet vs bullet               | Both destroyed, unless they came from the same cannon, which lets a spread leave the barrel |
| Bullet vs crate                | Both destroyed, crate drops its chips              |
| Bullet vs spawn-protected kart | Passes through                                     |
| Bullet vs shielded kart        | Shield pops, bullet destroyed                      |
| Bullet vs turret or decoy      | Target destroyed, bullet destroyed                 |

Bullets are Area3D nodes moved by raycast every physics tick so they cannot
tunnel through walls or karts at any speed. Every bullet knows its owner and is
tinted in the owner's colour with a short trail. Cannon types and jokers may
change any value in this table.

A shot whose muzzle sits inside a wall or a crate, because the kart or turret
is pressed against it, is checked from the shooter's centre: a crate in the
way still breaks, a wall just eats the bullet, and nothing passes through or
bounces back into the shooter.

### 5.2 Aim assist

To make forward-only aiming forgiving, bullets bend slightly toward targets. The bend stops
at the first bounce and the accessibility setting in 8.5 scales it, down to nothing. Two
jokers change this: Curve Ball bends much harder and keeps bending after a bounce, and
Aimbot turns the shot toward the nearest enemy as it leaves the barrel. Both work at their
own strength whatever the accessibility setting says.

| Parameter    | Starting value                                                  |
|--------------|-----------------------------------------------------------------|
| Cone         | Targets within 15° of the bullet heading                        |
| Range        | 15 m                                                            |
| Turn rate    | At most 50°/s                                                   |
| Active       | Until the first bounce                                          |
| Targets      | Enemy karts, decoys and turrets. Never the owner, never spawn-protected karts |

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
- The layout has two-fold rotational symmetry so that no spawn is favoured.
- The Junction is in the centre and reachable from all sides, with hazards or
  cover near it so that banking is never a free walk.
- Cover is partial. Bullets only bounce with Rubber Bumpers or a Ricochet Cannon,
  so cover is worth something, but no spot is safe from every angle.
- Keep it simple: a handful of wall segments, a few crates and pits, four turbo
  pads. No moving hazards in the first map.
- Maps are Godot scenes. Markers in the scene define spawns, pads, zones and
  the Jackpot spots. Adding a map means adding a scene.

### 6.2 Elements

| Element        | Behaviour                                                              |
|----------------|------------------------------------------------------------------------|
| Wall           | Solid, bounces bullets, stops karts                                    |
| Crate          | Destructible cover, see 3.2                                            |
| Pit            | A real hole: a shaft cut through the felt and the table. Karts that enter fall for 0.4 s and die, see 3.6. Bullets fly over it |
| Turbo pad      | Directional speed boost, see 4.1                                       |
| Coin pad       | Spawns chips, gold chips and mult dice, see 3.2                        |
| Power-up pad   | Spawns a held item, see 7.1                                            |
| Flush pad      | Takes the colour of the last kart over it; all four in one colour score a Royal Flush, see 3.9 |
| Target         | A shooting-gallery plate at bullet height. A bullet knocks it down and pays the shooter 3 coins; it comes back after 4 s. Karts bump into the post |
| Joker pad      | Keeps a joker lying on it, another one 6 s after it is taken. Used by the Garage in 9.4 |
| Junction pad   | Cash-out zone, circle of radius 2.5 m, see 3.4                         |
| Jackpot zone   | Growing chip pile, 2.5 m square, see 3.5                               |
| Spawn point    | 4 points near the corners                                              |

### 6.3 First map: Lucky Crossing

Grid of 32 by 18 cells, each 1.25 m. To be grey-boxed first and iterated in
playtests.

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
R  target        D  joker pad
B  crate         .  floor            F  Royal Flush pad
```

- The four turbo pads point along the vertical lanes at columns 10 and 21,
  each toward the opposite pad, so karts can rocket past the Junction's flanks.
- The pits sit directly above and below the Junction, so approaching from the
  top or bottom means going around them, while the coin pads next to the pits
  reward the risk.
- The short vertical walls screen the Jackpot zones from the centre, so a kart
  collecting the Jackpot can only be shot from the top or bottom lane, or by a
  bouncing bullet.
- The four Royal Flush pads sit on a ring: two on the top and bottom lanes and
  two behind the Jackpot zones, so a flush is a lap of the arena.

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
| Oil Stain       | 20     | Leaves a slick 1.8 m behind you for 25 s. Any kart whose centre crosses it, you included, spins out. It never kills |
| Bomb            | 20     | Drops a bomb 1.8 m behind you. It arms after 0.6 s and blows up when any kart, you included, drives over it, when a bullet hits it, or after 30 s. The 2.6 m blast kills karts, breaks crates and turrets and sets off other bombs. Kills credit you |

Later set, off by default and switched on per match in the lobby:

| Power-up        | Effect                                                                          |
|-----------------|---------------------------------------------------------------------------------|
| Decoy Kart      | Spawns a bot kart in your colour with a random trait, see 9.1. Lives 20 s or 1 hit. Its kills and coins credit you. Can hit you |
| Spread Cannon   | Next 6 shots fire 3 bullets in a 20° fan. The live bullet allowance triples with the fan, so the fan counts as one shot |
| Swivel Cannon   | 12 s of free aim with the right stick or mouse, no aim assist                   |
| Bullet Wipe     | Erases every bullet within 8 m                                                  |

### 7.2 Owned turrets and decoys

- Everything a turret or decoy does is attributed to its owner: kills give the
  owner +1 mult, coins a decoy collects go into the owner's pot.
- They can hurt their owner, who receives no credit for that.
- They are destroyed by one hit and count as targets for aim assist and grazes
  by other players.
- Decoys collide with karts like karts do. Ramming a decoy or a turret with
  Boost destroys it; without Boost it is only a bump.

### 7.3 Joker catalogue

Mostly rule benders, some stat tweaks, a few cursed jokers with a big upside and
a real downside. Starting set; balance is untested.

| Joker            | Rarity   | Kind   | Effect                                                                    |
|------------------|----------|--------|---------------------------------------------------------------------------|
| Hair Trigger     | Common   | Stat   | Fire cooldown -30%                                                        |
| Big Tank         | Common   | Stat   | +1 max live bullet                                                        |
| Magnet Hubcaps   | Common   | Stat   | Pickup radius times 2                                                     |
| Nitro Habit      | Common   | Stat   | Drift exit boosts and turbo pads last twice as long                       |
| Slipstream       | Common   | Rule   | Grazes give +1 mult instead of +0.5                                       |
| Green Light      | Common   | Rule   | Turbo pads give +0.5 mult                                                 |
| Vulture          | Common   | Rule   | Chips dropped by other karts are worth 2 coins to you                     |
| Insurance Policy | Uncommon | Rule   | Bank 100% of your pot on death                                            |
| Getaway Driver   | Uncommon | Rule   | Junction drain ramps twice as fast, D = 0.25 s                            |
| Pickpocket       | Uncommon | Rule   | Kills move 50% of the victim's coins into your pot; the victim drops none |
| Rubber Bumpers   | Uncommon | Rule   | Your bullets bounce off walls once more. Stacks: two copies bounce twice  |
| Comeback         | Uncommon | Rule   | Respawn with mult equal to half your mult at death, rounded up            |
| Loaded Dice      | Uncommon | Rule   | Every chip has a 10% chance to count as a gold chip                       |
| Toll Booth       | Uncommon | Rule   | Whenever another kart completes a cash-out, you bank 5% of it             |
| High Roller      | Uncommon | Cursed | All mult gains are doubled, but death banks 0%                            |
| Curve Ball       | Uncommon | Rule   | Your bullets curve hard toward enemies: a 55° cone out to 22 m at 150°/s, and they keep curving after a bounce |
| Aimbot           | Rare     | Rule   | Every shot leaves the barrel turned up to 14° toward the nearest enemy within 20 m and in front of you |
| Road Rage        | Uncommon | Cursed | Ramming above 90% of top speed kills without Boost, but top speed is -10% |
| Snake Eyes       | Uncommon | Cursed | Start every life with mult 3, but grazes give nothing                     |
| Lucky Seven      | Rare     | Rule   | Every 7th chip you collect gives +1 mult                                  |
| Wild Card        | Rare     | Rule   | Respawn offers 5 jokers instead of 3                                      |
| Glass Jackpot    | Rare     | Cursed | Completed cash-outs pay 150%, but dying drops all your chips and 2 jokers |

## 8. Presentation

### 8.1 Art direction

A toy diorama on a tabletop, like Wii Tanks, with casino accents and a few
road elements. Low-poly, flat or lightly gradiented colours, soft shadows,
subtle ambient occlusion. The arena floor is muted so bullets and chips pop.

- **Floor**: dark green felt with asphalt lanes and painted road markings.
- **Walls and crates**: sand-coloured wooden toy blocks.
- **Beyond the walls**: a warm wooden table surface, slightly out of focus.
- **Junction pad**: a slot-machine roundel with neon rings that light up while
  someone is banking, and a traffic light that turns green during a cash-out.
- **Jackpot zone**: a vault floor tile with a chip pile that grows, and a
  traffic light for its state, see 3.5.
- **Chips**: poker chips, gold for the gold chip, a die for the mult die.
- **Item boxes**: gold crates with black bands, a big question mark and a beam of
  light, glowing and pulsing so they read at a glance.
- **Karts**: toy go-karts with a simple driver figure, body tinted in the
  player colour, a roof marker shape per colour.
- **Bullets**: glowing spheres in the owner's colour with a short trail.
- **Traffic lights and road signs** as props at lane ends and near spawns.

Starting palette:

| Use                  | Colour                                        |
|----------------------|-----------------------------------------------|
| Felt floor           | `#2F5D45`                                     |
| Asphalt lanes        | `#3A3A40`                                     |
| Road markings        | `#E8D8A0` cream, `#E3B341` yellow             |
| Blocks               | `#E6D2B5` with `#C9AE86` edges                |
| Table                | `#8A5A3C`                                     |
| Chips                | `#F2C14E` gold, `#F7F3EA` and `#C4453C` stripes |
| Junction neon        | `#FF4FA3` magenta, `#35D0FF` cyan             |
| Disco heads          | magenta, cyan, white, gold, violet, green     |
| Player colours       | red `#E23D3D`, blue `#3D6FE2`, yellow `#F2D23D`, green `#43C463`, purple `#9B4FE2`, orange `#F28C3D`, cyan `#3DD9E2`, pink `#F26BB8` |

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
  11° as it goes so the table around them stays readable. A winner who is dead at
  the whistle has nothing to light, so the rig is left as it is.
- Each beam is cut to the distance it actually has to cross and widened to its
  own spot angle every frame, so however far across the table a head is
  pointing its cone ends in a lit pool on the floor rather than in mid-air.
- No head keeps one look. Each walks its own way through the six colours, holding
  one for 9 s at rest down to 3.5 s at the top and fading over to the next in 0.8 s,
  on its own staggered clock so the rig never changes colour all at once. Dark heads
  walk on too, so a head coming back on is not still wearing the colour it went out
  with. The colour changes are kept well away from the beat: a head that changed
  colour on the beat would read as a strobe rather than as a rig working the room.
- Each head also opens and closes its cone, 30% either side of the width its level
  asks for, each on its own clock and quicker the hotter the match is, so the beams
  keep working even while the level has been standing for a while. The winner's
  spotlight overrides both the width and the breathing.
- From level 3 every lit head flashes on the beat, harder on the first beat of
  the bar, faintly at first and hardest at level 6. The track is a steady 120 BPM
  in four, so the beat comes straight off the music's playback position. The
  lights cast no shadows and change nothing about play.

### 8.2 Camera

A single perspective camera looks down at the arena at a fixed tilt. It never
scrolls far; the whole arena stays visible.

| Parameter        | Starting value                                                    |
|------------------|-------------------------------------------------------------------|
| Projection       | Perspective, FOV 35°                                              |
| Pitch            | 55° below horizontal                                              |
| Framing          | The whole arena plus a 1 m margin fits the 16:9 view              |
| Pan              | Target is the arena centre moved 30% toward the centroid of alive karts, clamped to 2 m |
| Zoom             | FOV scaled between 93% and 107% by how spread out the karts are   |
| Smoothing        | Exponential, 0.6 s time constant                                  |
| Shake            | Small on deaths, larger on cash-outs of 500 or more               |
| Ultrawide        | Shows more table on the sides, never less arena                   |

In online play each client weights its own kart more heavily in the pan target.
In shared-screen play the camera is the same for everyone.

### 8.3 HUD and feedback

Each player has a HUD block. In shared-screen play the blocks sit in the four
corners, in single-player and online only the local block is shown.

- **Banked score**, large.
- **Pot** as `coins × mult = value`, updating live.
- **Joker hand**: the held jokers as a row of overlapping cards along the bottom
  of the screen, one hand per local player, each card framed in its kind's
  colour with the joker's initials and name. Three or more cards fan out, the
  middle riding higher and the ends tipping away, like a hand held in a fist.
  While the joker menu is open the selected card straightens up and lifts out of
  the fan with a bright frame, its name, description and the menu controls float
  above it, and the other cards dim. A count beside the hand reads how many of
  the five slots are taken, turning gold once the hand is full.
- **Lives**: two pips in the player colour under the kill count; a lost life
  goes dark.
- **Held power-up** icon. On pickup the item box arcs and shrinks into the kart
  that took it over 0.4 s, so everyone sees who got it, before the roulette
  flicker reveals the item.
- **Nitro tank** as a thin bar, lit while burning.
- **Speedometer** under it: a thin dial and a number in km/h, both turning the
  nitro colour while the bottle is lit. The dial is full at a kart flat out on
  nitro, so the needle still has somewhere to go when it lights. The number is the
  kart's real speed scaled by 20, which puts a kart at about 210 km/h flat out and
  400 on nitro: the honest metres a second is a single figure and says nothing
  about how the driving feels. A dead kart reads zero.
- **Control hints**, on by default and switchable in 8.5: a line under each
  player's block naming the button that drifts, the one that burns nitro and
  the one that plays a held item. Each shows only while it is worth pressing, so
  a parked kart with a full tank sees the nitro reminder alone and an item still
  rolling in its roulette shows none. A key cap to the left of the joker hand
  names the button that opens the joker menu, and shows only while cards are
  held. Driving and firing are left out: they already have the hint beside the
  kart at the start of a match.
- Every hint is named for the scheme that player is using: their own device when
  they are pinned to one, and otherwise whichever they last touched, which the
  game tracks from the input events themselves. The joker hand, the respawn
  picker and the start-of-match hint follow the same rule, so a player who picks
  up a pad mid-match sees gamepad buttons everywhere.
- **Match timer** at the top centre, turning red during Last Call.
- **Kill feed** in the top right: the last five kills, newest first, reading as
  "P1 shot P2", "P1 rammed P2", "P1 bombed P2", "P1 shoved P2 in" for a pit
  shove, "P2 fell in" for a fall nobody caused and "P2 wrecked itself" for a
  self kill. Names are in the players' colours. Lines hold for 6 s and fade.
  The feed drops below a player block that owns that corner.
- **Standings**: a ranked list down the right-hand side, one row per kart with
  its banked score and, in gold beside it, whatever it is still carrying around
  unbanked. Rows are ordered by the two added together, so a kart on a hot lap
  climbs before it reaches the Junction and drops back when it dies. The leader's
  row is the largest and last place the smallest, and the players on this screen
  are boxed in their own colour. It stands down in three- and four-player
  shared-screen games, where every player already has a corner block.
- **Destruction**: a kart, turret or crate that is destroyed leaves a burst of
  tumbling chunks in its own colour with a brief flash. A kart lost down a pit
  shrinks away instead. The Bomb keeps the one real explosion, see 7.1.
- In-world: a progress ring around the kart while banking or collecting the
  Jackpot, the chip count above the Jackpot zone, floating `+0.5` on grazes,
  and for local players an aim guide of four faint dots ahead of the cannon.
  Royal Flush pad frames glow and pulse in their holder's colour; a flush shows
  ROYAL FLUSH over the kart.

The tally is the payoff moment and gets the polish budget. On a completed
cash-out, chips fly from the kart into the pad while a counter above the kart
counts up with rising slot-machine ticks: `coins × mult`, then `= total`, in
about 0.8 s. Cash-outs of 500 or more add a fanfare, confetti and screen shake.
Death shows a smaller grey tally marked as half. The in-world tally plays for
every kart, so everyone sees when an opponent cashes out.

### 8.4 Audio

- **Music**: "Deceased Rodent" by Ovani Sound, one track in three intensities
  that all run in step and crossfade over 1 s at the same position. The fade
  is linear in amplitude so the level never dips. The files are cut to the
  track's 88 s loop with the decay tail folded under the start, so the music
  loops without a gap. Intensity 1 plays by default and in the menus.
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
  action. Two things skip the queue. Last Call stops listening to the meter and
  walks the room up on its own clock, one level every 2 s until it is at the top,
  so the finale arrives over about ten seconds as a build rather than as a switch;
  a room already halfway up gets there sooner. And every human player being dead
  drops the room to level 1 at once, except during Last Call, which is the finale
  whoever happens to be lying in a pit for the last few seconds of it.
- The music is not switched by Last Call either. It follows the levels like
  everything else, so the full mix arrives with level 6 partway through the climb.
- **Winding up between levels**: the music bus carries a low-pass filter and a
  gain stage that follow how far through the levels the room is, 0 at level 1 and
  1 at level 6, sweeping from a dulled 3.8 kHz up to fully open with 1.5 dB of
  lift. Both sit after the bus volume, so the audio settings keep full control.
  A kill shakes the camera by 0.2 plus half of that same share. The beat nudge at
  level 6 is shaped so it has fallen away again before the next beat. All shake
  obeys the accessibility toggle in 8.5.
- The F3 overlay shows the level and the meter with its two parts, the layer,
  both players' levels and positions, how far the filter is open, and the mute
  state.
- **Chips**: clink on pickup, pitch rising with rapid pickups.
- **Mult**: dice rattle on gain, a soft ping on graze.
- **Cash-out**: slot-machine ticks while draining, a jackpot chime on
  completion, fanfare on big pots.
- **Jackpot**: a soft tick per accrued chip when nearby, and a bell heard by
  everyone when the pile is full.
- **Karts**: engine hum pitched by speed, tire squeal on drift, whoosh on
  turbo and Boost.
- **Combat**: soft pop on fire, ricochet tick on bounce, thud and a short
  deflating sound on death.

### 8.5 Settings and accessibility

All settings are saved between sessions, see 10.2.

- **Controls**: rebinding per player for gamepad and keyboard, stick dead
  zone, rumble on or off.
- **Audio**: master, music and effects volume.
- **Video**: window mode, vsync, render scale.
- **Accessibility**: screen shake on or off, flash reduction, aim assist
  strength from 0% to 100% of the default and never above it, per player, and
  the aim guide on or off. Colour-blind roof markers are always on.

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
| Hunt            | An enemy is within 18 m and can be brought in front of the cannon             |
| Bank            | Pot value above the trait's threshold, or under 20 s left with a non-empty pot. A wounded bot halves its threshold, since a full cash-out is also its second life back, see 3.4 |
| Jackpot         | The active Jackpot has 20 or more chips and nobody is inside                  |
| Flush pad       | A Royal Flush pad is worth the detour: a pad held by nobody or by somebody else counts as 4 chips, the one that would complete the set as 24, and a pad of the bot's own with under 10 s left on its claim as 2.5, each divided by the distance to it |
| Grab item       | Holding nothing and a power-up pad is near                                    |
| Flee            | A Boosting enemy is within 6 m                                                |

**Arriving**: waypoints get a bot to the right part of the arena, but the last few
metres are their own problem. Flat out, a kart turns in a wider circle than the pad
it is aiming for, so it sails past and comes round again, forever. Inside 6 m of the
goal itself a bot eases off, down to a quarter throttle at the goal, and stops
drifting, which shrinks the circle to something that fits. With the goal behind it
and under 4 m away it backs onto it instead, because no turning circle fits at that
range. On the Junction and the Jackpot it then holds position as before.

**Getting unstuck**: driving at something solid pins a kart against it, and steering
toward a target on the far side only holds it there harder. A bot that is going
nowhere with the throttle down backs up for 0.7 s with the wheel over, which swings
its nose clear. It puts up with that for a second before deciding, unless it can
feel a wall right on its nose, which takes a third of a second. The turn is picked
once and held for the whole manoeuvre, and alternates, so a bot that backs into the
same corner twice tries the other way out rather than rocking on the spot.

**Pits**: paths already go around them, but a pit stops nothing and blocks no
raycast, so a bot cutting a corner, sliding out of a drift or chasing a kart
across one would drive in regardless. A bot checks the ground a second and a bit
ahead of itself; if a hole is in the way it comes off the throttle, drops the
nitro and steers along the edge of the hole rather than trying to turn round,
and inside 6 m it brakes as well. Short cuts between waypoints are checked
against the holes too.

**Dodging**: for each enemy bullet within 8 m, predict the closest approach
over the next second. If it is under 1.2 m, steer perpendicular to the bullet,
with the difficulty's dodge chance.

**Firing**: fire when an enemy is within 8° of the heading and within 18 m,
after the difficulty's reaction delay, leading the target by its velocity. With
nobody in reach, the same shot goes into the nearest crate or shooting target
within 13 m instead: both pay whoever breaks them, see 6.2, and a bot with
nothing else to fire at may as well be paid.

**Traits**: each bot gets one trait that shifts its goal weights.

| Trait    | Weight | Behaviour                                                              |
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
on a gamepad or J on the keyboard, and pick a colour by steering left or
right. The first join press claims that device for P1; until then P1 plays on
any device. Bots fill empty slots if wanted. The second release.

Joining mid-match is allowed: a press on an unused device during a match adds
the player. If a bot kart exists, the joiner takes it over and inherits its
score, pot, jokers and item, so the match stays at 4 karts. Otherwise the joiner
spawns fresh with an empty pot and 0 banked score. With 4 humans present nobody
else can join. A player who leaves mid-match hands the kart back to a bot.

### 9.3 Online multiplayer

The third release. Godot's high-level multiplayer over ENet with a
host-authoritative listen server, joined by direct IP and port from the Play
online screen. The host waits in an online lobby that lists who is in and
shows the address to join at, and presses Start when everyone is there;
players may still join a running match. Up to 4 players, bots run on the
host, and a joining client takes over a bot's kart. Design details in 10.3. A join code needs a relay
service and Steam integration needs GodotSteam; both are backlog items.
Joining mid-match follows the local rule in 9.2. Online matches cannot be
paused.

### 9.4 The Garage

A practice room reached straight from the title screen, before anybody starts a
real match. Nobody else is in it: no bots, no clock, no score to protect. It
runs an ordinary match on its own map with the timer switched off, so nothing
ever ends and the player can take as long as they like.

```
################################
#....R.......R.......R.........#
#.S............................#
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
#.S.....XX.....................#
#..............................#
#..............................#
################################
```

Everything the game does is somewhere on the floor, and a sign names each one:

- A long clear straight along the top and the bottom to wind the kart out on,
  with a turbo pad at either end of the top one pointing the other way.
- Crates to slalom through and shoot, coin pads, and three shooting targets
  along the top wall that pay coins, see 6.2.
- The Junction in the middle, a Jackpot zone, a pit, four Royal Flush pads and
  two item pads carrying the full item set rather than the first set.
- A joker pad that keeps a joker lying on it, so jokers can be tried out, kept,
  dropped and destroyed without dying for them.
- Pressing join brings a second player in on another device, the same as in a
  match, and pausing leads back to the title.
- The disco lights from 8.1 stay off in here: it is a place to look at the
  controls, not a nightclub.

### 9.5 The driving room

A development scene, `make drive`, holding one kart, one track and nothing else: no bots, no
bullets, no pickups, no clock. Driving has to be worth doing on its own before any of the rest
is worth adding, and everything else in the game gets in the way of judging that.

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
│   ├── kart/          kart.tscn, motor, cannon, pot, holders, trails
│   ├── bullet/
│   ├── pickups/       chip, gold chip, mult die, item box, floor joker, floor item
│   ├── zones/         junction pad, jackpot zone
│   ├── bots/          bot brain
│   ├── ui/            player hud, tally, joker pick, joker menu, lobby, results
│   ├── fx/            destruction bursts and other world effects
│   ├── garage/        the practice room from 9.4
│   └── match/         match state machine, snapshots, player stats
├── scripts/           shared code: autoloads, scoring math, input router
├── tests/             gdUnit4 tests
├── GAME.md
└── THIRD_PARTY.md
```

Key pieces:

- **Match**: state machine Lobby, Countdown, Playing, LastCall, Results. Owns
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

- ENetMultiplayerPeer, default port 7777. The host runs the server and plays.
- The host sends a state snapshot at 30 Hz: karts, bullets, pickups, turrets,
  zones, slots and joker offers. Clients keep a puppet match that renders the
  snapshots and dead-reckons bullets between them. Snapshots were chosen over
  MultiplayerSpawner and MultiplayerSynchronizer because every gameplay node
  is built in code.
- Clients send their input state to the server every physics tick with an
  unreliable ordered RPC. The server simulates all karts.
- Hits, pickups, banking and scoring are server-authoritative. The server seeds
  all randomness and relays gameplay events so clients' HUD and audio react.
- Client-side prediction and reconciliation for the local kart is a later step
  once latency is felt in tests.

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

### 10.5 Assets and licensing

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
| M0 Grey-box  | Lucky Crossing blockout, camera, kart handling, drift, trails, turbo pads, walls     | The kart feels good on gamepad and keyboard, crossing takes about 3.6 s   |
| M1 Combat    | Cannon, bullets, bounce and cancel, aim assist, death, respawn, spawn protection, crates, pits | Two local karts can fight, every death is attributable                 |
| M2 Economy   | Chips, coin pads, mult, graze, Junction drain, Jackpot zones, death split, HUD, tally, timer, Last Call, results | A full 5 minute solo match plays end to end with a score |
| M3 Items     | Power-up pads, first set power-ups, turret ownership, joker pick, hold, drop and destroy, floor drops, the joker catalogue | Items and jokers work in a solo match, scoring tests pass |
| M4 Bots and flow | Bot brain, traits, difficulty, title screen, control hints at match start, lobby with options, settings with rebinding, countdown, results, audio pass, art pass | First release: single-player against 3 bots, start to finish, looks and sounds like the game |
| M5 Local     | Input router, join in lobby and mid-match, 4 HUD blocks, colour picking                            | 4 players on one screen                                                   |
| M6 Online    | ENet, spawners and synchronisers, host-authoritative rules                           | 4 players over direct IP                                                  |

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
