# Changelog

What changed in Jackpot Junction, for people who play it rather than for people
who read the commits. Every change a player would notice gets a line here in the
same commit that makes it, see GAME.md 10.4. The format is
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the versions are
[semantic](https://semver.org/spec/v2.0.0.html).

`tools/changelog` checks this file, cuts a release out of the Unreleased section
below, and hands the notes to the release workflow.

## [Unreleased]

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
