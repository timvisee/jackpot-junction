# Changelog

What changed in Jackpot Junction, for people who play it rather than for people
who read the commits. Every change a player would notice gets a line here in the
same commit that makes it, see GAME.md 10.4. The format is
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the versions are
[semantic](https://semver.org/spec/v2.0.0.html).

`tools/changelog` checks this file, cuts a release out of the Unreleased section
below, and hands the notes to the release workflow.

## [Unreleased]

### Fixed

- **Online: your own kart is yours until you touch somebody.** The host now takes
  a client's word for where its own kart ended each tick, rather than working it
  out again and correcting any difference, and only takes the wheel back for the
  things one end cannot settle alone: running into another kart, being hit, going
  down a hole, dying, coming back. On a wire dropping a packet in five that cut
  corrections from eleven snapshots in sixty to three. A claim further out than a
  few ticks of driving is refused, so this cannot be used to appear somewhere else.
- **Online: things a client does now happen when it does them.** Nitro burnt a
  round trip late, driving into a crate at ramming speed stopped the kart dead
  and then dragged it through, driving into another kart carried on through
  where they were standing, driving into a hole crossed it and then fell in
  backwards, and the joker cursor moved a round trip after the key. All of them
  are answered on the spot now and put right by the host afterwards. A kart that
  falls in a hole stays in it rather than being lifted back out to fall in again
  when the host catches up, and a box driven through at ramming speed comes off
  the floor rather than being ploughed through while still drawn.
- **Online: picking a joker on a client.** A player whose kart had died was not
  heard by the host at all, so no card could be picked, no cursor moved and
  nothing answered until the kart came back on its own. The same held on the
  grid during the countdown.

### Changed

- **Losing the host says so properly.** The notice now sits on a pane like the
  one that describes a joker, and has the screen to itself: the HUD stands down
  and takes any open joker pick, the standings and the control hints with it.

- **Online play: your own kart is yours.** A client used to send its controls to
  the host and wait for the kart to come back, so at any real ping the kart
  answered the stick late and driving felt like steering through treacle. A
  client now drives its own kart itself, on the frame the stick moves, and the
  host corrects it where the two ever disagree. Over 100 ms of round trip the
  kart answers at once instead of five ticks later, and through four seconds of
  driving, drifting and handbrake turns the host had nothing to correct. Knocked
  out of place it is put back; on a wire losing a packet in five the corrections
  are absorbed whole: the kart a player is looking at does not move for them at
  all. Everything that decides the game is still the host's: what you collected,
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

[Unreleased]: https://github.com/timvisee/jackpot-junction/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.1.0
