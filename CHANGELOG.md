# Changelog

What changed in Jackpot Junction, for people who play it rather than for people
who read the commits. Every change a player would notice gets a line here in the
same commit that makes it, see GAME.md 10.4. The format is
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the versions are
[semantic](https://semver.org/spec/v2.0.0.html).

`tools/changelog` checks this file, cuts a release out of the Unreleased section
below, and hands the notes to the release workflow.

## [Unreleased]

### Changed

- **The test track's nitro straight is long enough to use nitro on.** It ran out
  about when the bottle got going. It is 45 m now, with the sign at the near end
  of it.

- **The test track's chicane has a gap you can drift through.** The way between
  the two stubs of wall was one cell wide, which is a keyhole to be lined up and
  crept through. It is three wide now.

- **A turbo pad fires you down its arrow and holds the throttle.** The pad points
  your kart along the arrow, sends it off at 150% of top speed, and keeps your
  foot down for a second whether or not you are touching the trigger. The wheel,
  the handbrake and the brake are yours the whole time, so you steer and drift
  through the boost instead of either riding a rail or throwing the boost away by
  turning.

- **The DJ booth stands in the crowd.** It was out on its own behind the back
  row. It is a couple of rows in now, with people in front of it and people
  behind it.

- **The whistle gets a moment before the podium.** The karts roll to a halt and
  the lights swing onto the winner for a couple of seconds, the music steps back,
  and then the screen comes up.

## [0.3.0] - 2026-09-20

A room worth sitting in. The arena picked up a crowd a thousand strong on
tribunes, a DJ booth, and two more maps to choose between in the lobby; the karts
picked up paint, hats, flags and trails, and their drivers picked up names; the
end of a match picked up a podium; and the Garage picked up a test track in front
of it that teaches the controls a sign at a time. Underneath all that: seven new
jokers, a Junction that no longer patches you up for free, hard bots that come
after whoever is carrying the money, aim assist that looks at more than karts, and
a long list of smaller things that were wrong.

### Changed

- **Nitro is on the right shoulder.** On a gamepad nitro has moved off B onto the
  right shoulder button, opposite the handbrake. It is held rather than tapped,
  and holding a face button through a corner meant fighting the thumb that was
  steering through it.

- **The notice about a lost host says where you are going.** It said the title,
  which is what the first screen is called in the code. A player sees a menu.

- **Out of time says what happens.** The lobby offers Last one standing and Match
  ends where it used to offer Sudden death and Whistle on the hour. Both of those
  needed the rule explained before they meant anything.

- **The Junction only patches you up once every three seconds.** A wounded kart
  parked on the pad used to get its life back the instant it lost it, so the one
  place everybody has to visit was the one place nobody could be finished off.
  The wait runs whether the kart stays put or drives off and comes back.

- **The Junction refills your nitro four times as fast.** Cashing out parks you
  still and in the open in the middle of the arena, so the pad now hands you the
  one thing that gets you out of there again, on top of whatever the hot table is
  already giving you.

- **Big Tank is worth two bullets.** It gave one more bullet in the air, on top of
  three, which was hard to feel next to what the other common jokers do. It now
  gives two.

- **Six jokers hit harder.** Nitro Habit stretches drift boosts and turbo pads
  three times rather than twice, Slipstream grazes are worth +1.5 mult, Green
  Light pays a whole point of mult per turbo pad, Vulture makes a dropped chip
  worth three coins, Loaded Dice turns a quarter of your chips gold, and Toll
  Booth takes 15% of everybody else's cash-outs instead of 5%.

- **Aim assist aims at everything worth shooting.** Boxes, bombs and shooting
  targets bend a shot the way a kart always did, and nothing behind the shot can
  take the aim off what is in front of it any more. Karts still come first: a box
  has to be well inside a player to be chosen over one.

- **Hard bots come after a big pot.** They look further for whoever is carrying
  one, pick the richest kart in range over the nearest, and a pot big enough will
  take them off almost any errand. Easy and normal bots still fight whoever
  happens to be closest.

- **The results screen is laid out properly.** Everybody gets a row of their own
  built like the joker detail pane, with their colour down its leading edge, their
  score in gold on the right, and each award on a chip of its own rather than run
  together into one line. The row belonging to whoever is reading it stands out of
  the rest.

- **The name box says Player rather than A funny one.** The box is asking for a
  name, not describing what happens if you leave it empty.

- **The results screen is headed Podium.**

- **Bullet marks are round.** They were squares, which read as stickers rather
  than as holes.

- **The pause menu and the online lobby are built like the rest of the game.**
  Both sit on the same dark pane with a bar of colour along the top that the joker
  details and the podium use.

- **Nitro comes back almost at once in the Garage.** A tank in a few seconds
  rather than a minute and a half, so the button can actually be tried out.

- **Flags fly off the back of the kart** rather than out of its side.

- **The portal is smaller.** It was a wide pad for what is a door.

### Added

- **A one-minute match, in debug builds only.** Long enough to reach the Junction
  and the results screen, short enough to do it again straight away.

- **A new joker, Payday.** A coin every second, wherever you are and whatever you
  are doing. Uncommon.

- **A new joker, Hot Streak.** Half a point of mult every ten seconds you stay on
  the floor. Rare.

- **A new joker, Odometer.** A coin for every 20 m you drive. Common.

- **A new joker, Tailslide.** A coin for every 8 m you spend sideways. Uncommon.

- **A new joker, Jerry Can.** Nitro refills four times as fast. Uncommon.

- **A new joker, Direct Debit.** Five points of your pot bank themselves every
  second, wherever you are, and your mult is left alone. Uncommon.

- **A new joker, Deep Pockets.** Two more joker slots, one of which it stands in,
  and it stacks. Rare.

- **Joker cards say how rare they are.** One, two or three pips under the name,
  steel for common, cyan for uncommon, magenta for rare, and the pane that
  describes a joker names the rarity next to the kind.

- **Two dummy karts in the Garage.** Nobody is driving them, so they never shoot
  back. Each carries a pot of coins and an item, so shooting one scatters loot
  worth picking up, and each comes back after a moment carrying something new.

- **Taking a place in sudden death is called out.** A kill in overtime that puts
  you past the player you took out reads OVERTAKE across the middle of the
  screen, or TAKING THE LEAD when it puts you top of the board, and counts toward
  a Last Word award on the results.

- **Bullets leave marks on the walls they hit.** A small scorch in the shooter's
  colour, fading out over a few seconds, so a wall that has been shot at looks
  like one.

- **Players have names.** Anybody who has not set one is handed a silly one off a
  list, so the standings, the kill feed and the results screen read as a room full
  of people rather than P1 through P4. Names carry through a rematch and reach
  every screen online.

- **The lobby has a name box for every player.** Up to 16 characters each,
  remembered between sessions. Left empty, the match hands out one of the funny
  ones.

- **The results open on a victory podium.** The top three on three steps, the
  winner in the middle on the tallest, each with their own kart standing on top of
  it turning on the spot.

- **Online players can set their name.** The screen you host or join from asks
  what you are called, so somebody joining a friend never arrives under whatever
  name that machine last used.

- **You can see the Jackpot pile running out.** The kart collecting it wears the
  same progress ring the Junction draws, since the count on the floor is under the
  kart standing on it, and the pile going throws a handful of gold up off the tile.

- **A kart coming back says so.** A ring opens across the floor in the player's
  colour with a column of light in it, so a respawn reads from anywhere in the
  arena rather than only to whoever was watching that kart blink.

- **Menus answer the gamepad.** A presses the button under the cursor and B backs
  out, in the pause menu, the lobby, the online screen and the settings. The title
  screen has nowhere to back out to, so B does nothing there.

- **Ramming somebody knocks coins out of them.** A ram they live through spills a
  quarter of their coins, at most 8, onto the floor for anybody to pick up.

- **Crashes come through the pad.** Hitting a wall or another kart knocks the
  gamepad, as hard as the hit was, on top of the sound.

- **A test track, before the Garage.** The first time you pick Garage you arrive
  on a road instead: a straight, some corners, a wall of boxes to shoot through, a
  straight to open the bottle on, a chicane to drift and a room at the end. Each
  stretch has one word on it and the button it names. A portal at the end leads to
  the Garage, and the Garage has one back.

- **Dress your kart.** Four things to pick in the lobby beside your name: a paint
  pattern, a hat, a flag and what the kart leaves behind it. Your colour is still
  your colour underneath, and everybody sees the same kart online.

- **Two more arenas, and a choice of which to play.** The Vault puts the Junction
  in a walled box with four ways in; Crossfire leans four diagonals away from the
  middle so every approach is a corner. The lobby picks one, and online everybody
  plays the host's pick.

- **A crowd, and a DJ booth.** Small figures stand on the table all the way round
  the arena and get up on their feet when the room is going or when somebody is
  taken out. The booth's speakers pulse on the beat.

- **The title screen has something behind it.** A slow carnival sunburst with
  poker chips drifting up past it.

- **A chequered flag to fly.** A fourth flag, in the colours a chequered flag
  comes in rather than the player's.

- **You can read your hand while you are dead.** The joker menu opens and the
  cursor walks; dropping and destroying wait until you are back on the floor.

### Fixed

- **Shots are not bent toward what they cannot reach.** Aim assist, and Curve Ball
  most of all, would swing a bullet toward somebody standing safely behind a wall
  and bury it in the brickwork. Anything with a wall or a box in the way is now
  passed over for whatever is on this side of it.

- **The podium sits properly in its frame.** The karts were clipped along the top
  edge with empty space under the steps; the picture is aimed a little higher now.

- **An online match keeps running when the host looks at something else.** An
  unfocused window could hold the whole main loop up waiting for the desktop to
  take a frame, which froze every client in the room until somebody clicked back.

- **The joker pick cannot be answered for half a second.** You are killed with a
  thumb on the trigger and the cards open under it, so a card was being claimed
  before anybody had read it. Moving the cursor still works the whole time.

- **The joker hand goes away at the whistle.** It was lying across the bottom of
  the podium screen.

- **Hats sit down on the head.** They were perched level with the top of the
  helmet, which read as a hat hovering just above it.

- **A Decoy Kart is dressed like you.** It had your colour and none of the rest of
  your kart, which rather gave it away.

- **Kart paint has clean edges.** The patterns were drawn at sixteen pixels and
  snapped to them, which looked like it.

- **Confetti can be seen.** It was flat squares small enough to miss, half of them
  edge-on at any moment; it is tumbling blocks now, bigger and twice as many.

- **The podium steps wear their colour cleanly.** The grey of the step was showing
  through the coloured plate on top of it in patches.

- **The Garage portal is clear of the wall.** It was standing half inside the
  bottom one.

- **The joker hints name the stick, not the axes.** On a pad they read "Left stick
  cycle" rather than "Left Stick X-Axis - / Left Stick X-Axis + cycle".

- **A turbo shove can be steered.** Leaning on the wheel pulls the line round
  after the nose instead of doing nothing until the shove is thrown away
  altogether. Hands off, it still holds the arrow exactly.

- **The test track is bigger, and the camera comes down to it.** The lanes are
  half again as wide and the road is longer, so a corner taken badly leaves you
  room to carry on rather than parked against a wall. The camera follows your
  kart from close in instead of framing all sixty-five metres of road at once.

- **The test track's signs say what the button does.** They were a word and a
  key: "DRIFT" over "Shift". They now read "DRIFT" over "handbrake and turn",
  with a HANDBRAKE sign at the first stub of the chicane saying what locks the
  wheels.

- **The crowd is a crowd.** There was one person per two metres in a single line
  round the arena. There are now getting on for a thousand of them, four rows
  deep, no two the same height, colour or heading, standing where they like
  rather than on a grid, with gaps in the rows. The lot of them draw in two
  calls and cost nothing per frame, so a full house runs the same as an empty
  one did.

- **Tribunes round the table.** A stretch of each side of the crowd is up on
  steps behind a back wall, with everybody on it a step higher than the row in
  front.

- **The crowd can be sent home.** Accessibility settings has a Crowd switch, on
  by default. Off empties the stands and leaves the DJ booth where it is.

## [0.2.0] - 2026-09-18

Multiplayer. Online play worked before this and did not feel like it: every button
a player pressed went to the host and came back, so at any real ping the kart
answered late and driving felt like steering through treacle. A client now drives
its own kart and answers its own controls on the frame they are pressed, and the
host puts it right where the two ever disagree. Almost everything below follows
from that, one way or another.

### Fixed

- **Online: a client's kart comes back from a hole, and a dead kart is out of the
  way.** Falling down a hole on a client left the kart there for good: a respawn
  is the host's to place and a kart being driven here was ignoring the host's
  position, so it came back still standing in the hole and fell down it again.
  Separately, a kart somebody had just shot went invisible on every other screen
  but stayed solid where it died, so the spot could not be driven through until
  it respawned.
- **Online: a kart that has been down a hole is solid again.** Falling takes a
  kart's collisions away, and on a client the kart is dead, stood down and
  brought back between losing them and being driven again, so it came back able
  to drive through walls for the rest of the match.
- **Online play is written down.** GAME.md 10.3 opens with who decides what, as a
  table, along with what the arrangement guarantees and what it does not.
- **Online: pulling the trigger answers at once.** The cannon goes on cooldown and
  the shot is heard on the tick the button goes down; the bullet still comes from
  the host, because whether one lives depends on a bullet fired by somebody a
  client only sees where they were a round trip ago.
- **Online: the floor is sent as what changed.** Every chip on the ground went out
  thirty times a second whether or not it had moved, which was the largest part of
  a snapshot and most of why one did not fit in a single packet. A typical snapshot
  is now about a fifth smaller, and more on a busy floor.
- **Online: chips pulled in by a Coin Magnet move on every screen.** They sat
  where a client first saw them and blinked out from there, so both halves of the
  effect were missed.
- **Online: nitro stops flickering on a client.** It was lit on the tick the button
  went down and then put out again by the host'''s word for it, a round trip behind.
- **Online: a correction says so on screen.** A client that is put back where the
  host has it now shows how far it moved and how many times it has happened, so a
  bad connection reads as a bad connection rather than as a bad kart.
- **Online: a rematch starts fresh on every screen.** A client keeps its own
  excitement meter and announcer, and nothing told either of them the last match
  was over, so the new one opened at the old one's heat with the lights still
  going and somebody still on a killing spree they earned in a finished game.
- **Online: the Swivel Cannon aims where a client is aiming.** Free aim never
  crossed the wire when it came from a mouse, so the host asked where its own
  pointer was and fired the client's shot at that.
- **Online: a rematch keeps the players who are in it.** The host pressing
  Rematch started again from the lobby's list, so every connected player's kart
  was handed to a bot while they carried on steering it.
- **Online: a chip pulled in by the Coin Magnet flies into the kart.** On a
  client it blinked off the floor instead: the magnet triples how far a kart
  reaches, and a client judging who took something was still using the plain
  reach.
- **Online: turbo pads shove a client's kart again.** They had stopped working on
  clients altogether: the pad could not see a kart being driven there, and the
  host's shove lost to that machine's own answer about where its kart was.
- **Online: dropped chips fly out on every screen.** Coins and items thrown clear
  of a bursting kart or a breaking box only arced on the host; everybody else saw
  them appear on the floor already landed.
- **Online: things a client does now happen when it does them.** Nitro burnt a
  round trip late, driving into a crate at ramming speed stopped the kart dead
  and then dragged it through, driving into another kart carried on through
  where they were standing, driving into a hole crossed it and then fell in
  backwards, and the joker cursor moved a round trip after the key. All of them
  are answered on the spot now and put right by the host afterwards. A kart that
  falls in a hole stays in it rather than being lifted back out to fall in again
  when the host catches up, and a box driven through at ramming speed comes off
  the floor rather than being ploughed through while still drawn, and stays off
  it rather than being put back by the next snapshot under the kart that has
  already gone through it.
- **Online: picking a joker on a client.** A player whose kart had died was not
  heard by the host at all, so no card could be picked, no cursor moved and
  nothing answered until the kart came back on its own. The same held on the
  grid during the countdown.

### Changed

- **Losing the host says so properly.** The notice now sits on a pane like the
  one that describes a joker, and has the screen to itself: the HUD stands down
  and takes any open joker pick, the standings and the control hints with it.

- **Online play: your own kart is yours.** A client drives its own kart on the
  frame the stick moves, and the host takes its word for where that kart ended
  each tick rather than working it out again. The host takes the wheel back only
  for what one end cannot settle alone: running into another kart, being hit,
  oil, going down a hole, dying, coming back. Over 100 ms of round trip the kart
  answers at once instead of five ticks later, and through four seconds of
  driving, drifting and handbrake turns the host had nothing to correct at all.
  On a wire losing a packet in five the corrections are absorbed whole: the kart
  a player is looking at does not move for them. A claim further out than a few
  ticks of driving is refused, so this cannot be used to appear somewhere else,
  and everything that decides the game is still the host's: what you collected,
  who you hit, what it was worth.
## [0.1.0] - 2026-09-18

### Added

- **The table.** A top-down arena kart game for one to four players. Drive a
  drifty toy kart around a felt-topped diorama, collect poker-chip coins and
  multipliers, and decide when to cash out before somebody shoots you.
- **Push your luck.** Everything you are carrying is a pot of coins times a
  multiplier, and it is only yours once you have driven it onto the Junction and
  sat there while it drains. Dying hands half of it to the bank, scatters some on
  the floor and may cost you a joker.
- **The Junction.** The cash-out pad, paying faster the longer you hold it, and
  patching up a wounded kart with the last coin of a pot. Its ring blinks when
  you are carrying something worth protecting, and goes flat gold when you are
  one cash-out from winning.
- **The Jackpot.** A pile in the corner that grows on its own and pays whoever
  stands in it, contested to a standstill when two karts arrive at once.
- **Royal Flush pads.** Four pads that trickle coins to whoever holds them, and
  hand out a multiplier and a full nitro tank to anyone holding all four.
- **Jokers.** Cards that bend the rules, picked one of three when you die, held
  five at a time, dropped on death and lying on the floor for anyone to take.
- **Power-ups.** Held items used on a button: shields, bombs, oil, boost,
  turrets, decoys and cannon swaps, on pads around the table.
- **Combat.** A forward-firing cannon with bouncing, colour-coded bullets that
  cancel each other, grazing for multiplier, two lives, and spawn protection.
- **Driving.** Drift with a handbrake flick, a boost for carrying one all the
  way round, a nitro tank, turbo pads, tire marks, smoke and sparks.
- **Bots.** Three difficulties of opponent that pick real goals, navigate the
  room, drive on the limit and cash out on purpose. They watch how the humans in
  the room play and aim for that.
- **Local multiplayer.** Up to four players on one screen, joining in the lobby
  or mid-match by taking over a bot, each with their own corner of the HUD.
- **Online multiplayer.** Up to four players over direct IP, host-authoritative,
  with clients taking over bot karts and the host's match settings.
- **The finale.** Last Call doubles the payouts for the final thirty seconds,
  and overtime turns the whistle into sudden death where the last kart standing
  takes everything it is carrying.
- **A room that reacts.** Six levels of excitement that build through a match and
  drive the music, the lights and the camera, a hot table that speeds the room up
  at the top, and an announcer calling out what just happened.
- **Results.** Rankings, and up to three awards per player picked from twenty-six
  statistics for whatever they did most.
- **The Garage.** A practice room off the title screen with no clock, no score
  and nobody else in it.
- **Settings.** Full rebinding on keyboard and gamepad, volume per bus, and
  accessibility options: the aim guide, flash reduction and colour-blind roof
  markers.

[Unreleased]: https://github.com/timvisee/jackpot-junction/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.3.0
[0.2.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.2.0
[0.1.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.1.0
