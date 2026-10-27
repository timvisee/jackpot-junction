<h1 align="center">
  <img src="assets/logo/banner.png" alt="Jackpot Junction" width="476">
</h1>

**Did someone say chaos?** Jackpot Junction is a top-down battle kart game on a
casino table. Drift, dodge bullets and scoop poker chips like your rent depends
on it, and try not to turn into roadkill. Challenge your friends, up to four at
one screen or eight online, to see who makes the biggest payday. Die before you
cash in and you lose bank. Easy, right? Yeah, good luck with that.

- **Collect** chips from the pads, the crates, the Jackpot and the karts you
  knock out.
- **Multiply** your pot by taking out your fellow karts.
- **Bend the rules** with 48 jokers and 21 power-ups. Get lucky, or cursed...
  who knows.
- **Cash out** by driving onto the Junction. Die on the way and lose all your
  hard work.

[Play it on itch.io](https://timvisee.itch.io/jackpot-junction), or see
[Installing](#installing).

Made with Godot 4.7 and GDScript, with the karts modeled in Blender. What changed in each
release is in [docs/CHANGELOG.md](docs/CHANGELOG.md); the rest of the documentation is listed
under [Documentation](#documentation).

![The House's invitation on a dark table under two spotlights. On the left lies a cream bulk-mail envelope from THE HOUSE, Jackpot Junction, addressed TO: YOU, with a box of presorted postage, a green road sign stuck over its window reading JACKPOT JUNCTION, NEXT EXIT, ALL ROADS LEAD HERE, and YOU MAY ALREADY BE A WINNER! in red across its foot. On the right, turned a little toward the light so its gold shines, stands a red velvet card edged in gold with rays fanning from its top: GRAND OPENING TONIGHT over JACKPOT JUNCTION in gold, the four suits, "Fast karts. Loud tables. Real chips.", YOU'RE ON THE LIST and "RSVP not required. You'll come.", a gold star sticker offering FREE CHIPS FOR NEW DRIVERS, and below a row of punched holes a gold stub, ADMIT ONE DRIVER, with its number. Under them a single button: Accept the invitation](docs/screenshots/opening-invitation.png)

*The invitation that brings you to the tables, the first time you start the game.*

Three arenas and a bigger XL one of each, every one in a room of its own.

![A dark card room with a green baize arena on the table in the middle of it, the only lit thing in the room. A roulette wheel of red and black pockets is let into the baize at the center, with low wooden walls round it, stacks of red chips against them and a slot machine on each of the inner walls, its reels showing sevens. Neon signs, BET THE FARM and SNAKE EYES, hang over a crowd picked out in pink, and the match clock glows orange above the far edge, FIRST TO 3000 on a tag hung under it. Three players share the screen, a corner each: the first's dashboard is in the top left, in red, the second's in the top right, in blue, and the third's in the bottom left, in yellow, each with their drive hint beside it, the keyboard's and two gamepads'; the first player's hand of jokers is tucked small along the top beside their corner](docs/screenshots/the-vault.png)

*The Vault, After Hours, three players at one screen.*

![The container yard round a table, a works yard turned into one and kept the way a yard is kept: corrugated-steel shipping containers in one plain paint stacked two high down the flanks and away in the far corners, set square with the table in rows, a gantry crane straddling the whole thing on its rails with its hook hung high over the roulette that stands in for the Junction in the open middle, and oil drums and crates about the striped asphalt with a pit at either end, the karts small against all that floor. The crowd rings it in rows. The match clock reads 4:58 above the table, FIRST TO 3000 on a tag under it, and beside it hangs a slim scrap of paper with a red map pin: the bet the player has pinned in the loyalty program, The Cashier's Cage, nought of twenty so far. The player's dashboard is in the top left, Bumper Betty with nothing banked yet and three lives, and their hand of three jokers runs along the bottom, each card marked with its suit](docs/screenshots/yard.png)

*Toy Box, in The Playroom: a bigger arena, with a loyalty program bet pinned by the clock.*

![The Your kart dialog, an old workshop bay in a steel frame with hazard stripes along its foot. Top left a red enamel sign reads YOUR KART, THE GARAGE, BAY 1; a timber rail of keys hangs along the top with the seat's key tag, Tail Light Tim, and a printed BACK plate sits top right. Two pegboards in red frames stand either side with a hook for each part of the kart, a picture of the piece worn hanging on it and its name on masking tape: Flag, Checkered; Hat, Top hat; Trail, Confetti; and Card back, The House's, on the left; Body, Racer; Paint, Racing stripes; Plate, None; and Marks, Plain, on the right, over a big red SHUFFLE push button in a plate of hazard stripes. In the middle the player's blue kart with racing stripes stands on the lift's turntable between its red posts under two green shop lamps, trying on a gold crown, a line of rope running from the Hat hook to it. Along the foot the rack of hats hangs over the bench, 16 of 16 won, None, Cap, Top hat marked ON, the crown picked out in gold, Party, Learner, Dealer's visor, Fedora and more past an arrow](docs/screenshots/your-kart.png)

*Your kart, in the Garage's bay: a hook for each part, and a rack of every piece to try on.*

![A wide phone screen showing Lucky Crossing from above: a green felt arena with low blocks, two pits of spikes and a machined plate in the middle, a slot machine on each of the inner walls, karts and chips on the cloth, and a crowd packed round it in the stands. The touch controls are drawn over it in the player's own red: a steering wheel in the lower left for the left thumb, and on the right a round Fire button beside a tall slider cut into Nitro, Gas, Reverse and Drift. The menu button sits in the top right corner over the standings strips, the player's dashboard is in the top left, and their hand of joker cards peeks up along the bottom edge](docs/screenshots/mobile.png)

*Lucky Crossing on a phone: the stick under the left thumb, Fire and the slider under the right.*

## Installing

Every release has the game for Linux, macOS, Windows and Android: download the
file for your system from the
[latest release](https://github.com/timvisee/jackpot-junction/releases/latest),
or from its page on [itch.io](https://timvisee.itch.io/jackpot-junction).
There is nothing to install beyond unpacking it.

| System       | Download                             | Then                                       |
|--------------|--------------------------------------|--------------------------------------------|
| Linux        | `jackpot-junction-…-linux.zip`       | Unzip it and run `./jackpot-junction`      |
| Linux on ARM | `jackpot-junction-…-linux-arm64.zip` | The same                                   |
| macOS        | `jackpot-junction-…-macos.zip`       | Unzip it and open the app                  |
| Windows      | `jackpot-junction-…-windows.zip`     | Unzip it and run `jackpot-junction.exe`    |
| Android      | `jackpot-junction-…-android.apk`     | Open it on the phone and allow the install |

The builds are not signed by a store, so the first start asks once: on macOS open
it, then allow it under System Settings, Privacy & Security, Open Anyway, or run
`xattr -dr com.apple.quarantine` on the app; on Windows choose More info and then
Run anyway; on Android let the browser or file manager you opened it from install
apps. To play online, everybody needs the same minor version. A dedicated server
is in the same release too, see [docs/SERVER.md](docs/SERVER.md).

## Playing

- **Single-player**: Play opens the lobby with the match settings over it: a Grand
  Prix or one arena, match length, target score, bots and difficulty. Drive onto
  the pad in the middle to start. Bots use the same karts, items and jokers you do.
- **Teams**: set Teams in the match settings to play in two to four teams that
  bank one score together. In the lobby, stop on a team's corner to join it, or
  use the team button on your switch in the pause menu.
- **Local multiplayer**: in the lobby or mid-match, press Start on a gamepad or
  J on the keyboard to join. Dress your kart at the stalls along the lobby's back
  wall, or with Customize kart in the pause menu's Clubhouse, and name each seat in Settings,
  Seats.
- **LAN**: Play LAN, host on a port or join a friend's address directly.
  The host runs the match; joining players take over bot karts.
- **Online**: Play Online, on a dedicated server: make a game there and host it
  from your own machine, or join one somebody else made. See
  [docs/SERVER.md](docs/SERVER.md) to run one.
- **Garage**, under Clubhouse: a practice room with an open floor to drift round the
  Junction on, a range of targets and two dummy karts to shoot at, and a dyno and a
  speed trap to time your kart. Stop on its lift to dress your kart.
- **Customize kart**: the bay door peeking in beside the Clubhouse, Customize kart in the pause
  menu's Clubhouse, or the Me page of Settings: your kart in the Garage's bay, a pegboard hook for
  each part to change it, and its color, name and plate.
- **Catalog**, under Clubhouse or on the License page of Settings: every joker and
  power-up you have found, the rest face down.
- **Demo**: start the game with `--demo` after `--`, as in `./jackpot-junction -- --demo`,
  to show it at a booth. It plays Grand Prix after Grand Prix by itself on settings of
  its own, and anybody walking past presses a button to take a seat. Escape opens its
  menu, with Quit to end it.

Default controls, all rebindable in Settings:

| Action               | Keyboard        | Gamepad          |
|----------------------|-----------------|------------------|
| Drive, brake, steer  | W, S, A, D      | Triggers, stick  |
| Fire                 | Space           | A                |
| Handbrake            | Shift           | LB               |
| Nitro                | Ctrl            | RB               |
| Use item             | E               | X                |
| Joker menu           | Tab, 1 to 5     | Y, D-pad         |
| Pause                | Escape          | Start            |

## Documentation

Everything else is in [`docs/`](docs):

| Document                                       | What it holds                                                            |
|------------------------------------------------|--------------------------------------------------------------------------|
| [DEVELOPMENT.md](docs/DEVELOPMENT.md)          | Building, running and testing from a checkout, startup and debug arguments, the tools, releasing |
| [SERVER.md](docs/SERVER.md)                    | Running a dedicated server, on its own or with Docker                     |
| [STEAM.md](docs/STEAM.md)                      | Setting the Steam app up on Steamworks, for the Steam builds              |
| [ITCH.md](docs/ITCH.md)                        | Setting the itch.io page up, for the releases published there             |
| [GAME.md](docs/GAME.md)                        | The design, which the code cites by section, "GAME.md 3.8"                |
| [STORY.md](docs/STORY.md)                      | The story under it (spoilers)                                            |
| [PLAN.md](docs/PLAN.md)                        | The implementation plan, with the status of every milestone              |
| [CHANGELOG.md](docs/CHANGELOG.md)              | What changed in each release                                             |
| [house-print](docs/house-print/index.html)     | The art direction of the UI, House Print                                 |

## License

The source code is licensed under the GPL-3.0, see `LICENSE`. Assets made for
the game are licensed under CC-BY-4.0. Third-party assets and libraries keep
their own licenses and are listed in `THIRD_PARTY.md`. The music is licensed
from Ovani Sound to this game's developer and is not covered by either
license.

Additional permission under GNU GPL version 3 section 7: if you modify this
program, or any covered work, by linking or combining it with the Steamworks
SDK (or a modified version of that library), containing parts covered by the
terms of the Steamworks SDK Access Agreement, the licensors of this program
grant you additional permission to convey the resulting work. The Steam builds
are made this way, through GodotSteam, see GAME.md 10.8.
