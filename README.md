# Jackpot Junction

A top-down arena kart game in which every life is a hand of cards. Drive a
drifty toy kart through a bullet-filled diorama, collect poker-chip coins and
multipliers, and decide when to cash out at the Junction before someone shoots
you.

Made with Godot 4.7 and GDScript. `GAME.md` holds the design, `PLAN.md` the
implementation plan with the status of every milestone, and `CHANGELOG.md` what
has changed in each release.

Three arenas, three rooms to play them in.

![A green felt arena on a workbench, lit by a lamp over it, with karts driving between low blocks and a machined steel plate set into the felt in the middle of it. Bundles of rod stock and stacks of planks lie about the bench around the table, and a crowd of onlookers rings the arena, packed at the rail and thinning outward. Glass tanks filled to different levels, a DJ booth, two lit hoardings and a board keeping the match clock stand at the far edge; the player's score sits on a dark card in the top left, the standings run down the right and a hand of joker cards along the bottom of the screen](docs/lucky-crossing.png)

*Lucky Crossing, on The Workbench.*

![A dark card room with a green baize arena on the table in the middle of it, the only lit thing in the room. A roulette wheel of red and black pockets is let into the baize at the center, with stacks of red chips and fanned playing cards round the walls and dice on the cloth beyond them. Neon signs hang over a crowd reduced to shapes with light along their edges, and the match clock glows orange above the far edge](docs/the-vault.png)

*The Vault, After Hours.*

![A concrete yard in late afternoon light, with an arena marked out on it and karts driving between pale blocks. A disc in the middle is bordered in black and yellow hazard stripes, hazard tape runs across the floor at the back, and the crowd stands on stepped tribunes behind a low fence, with lit hoardings and the match clock along the far edge](docs/crossfire.png)

*Crossfire, in The Yard.*

![A wide phone screen showing Crossfire in The Yard from above, the whole arena in view, with the touch controls drawn over it: a round stick in the lower left for the left thumb, and on the right a round Fire button beside a tall slider cut into Nitro, Gas, Reverse and Drift. The menu button sits in the top right corner with the standings under it, the player's score card is in the top left, and their hand of joker cards is along the bottom edge](docs/mobile.png)

*On a phone: the stick under the left thumb, Fire and the slider under the right.*

## Playing

- **Single-player**: Play opens the lobby with the match settings over it: a Grand
  Prix or one arena, match length, target score, bots and difficulty. Drive onto
  the pad in the middle to start. Bots use the same karts, items and jokers you do.
- **Local multiplayer**: in the lobby or mid-match, press Start on a gamepad or
  J on the keyboard to join. Dress your kart at the stalls along the lobby's back
  wall, and name each seat in Settings, Players.
- **LAN**: Play LAN, host on a port or join a friend's address directly.
  The host runs the match; joining players take over bot karts.
- **Garage**: a practice room with one of everything in it and two dummy karts to
  shoot at. The first visit goes to a test track that teaches the controls, and
  the two rooms have portals to each other.

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

## Development

Requires a Godot 4.7 binary. `tools/godot` finds it through `$GODOT`, the Steam
install, or `godot4` on the path. Lint and format use
[gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit): `pipx install gdtoolkit`.

```
make dev        # start the development scene
make drive      # start the driving room, for handling work
make jokers     # every joker and power-up icon on one screen, to see them as a set
make run        # start the game scene
make run ARGS=--touch=1  # the game with the touch controls, the mouse standing in for a finger
make run ARGS="--touch=1 --ui-scale=1.5"  # the same at a phone's UI scale, saving nothing
make check      # import, lint, format check, changelog, unit tests, smoke runs, multiplayer
make test       # unit tests only (gdUnit4, headless, a suite per process in parallel)
make multiplayer  # a whole Grand Prix online (two games, up to two clients) and on one screen
make export     # release builds for Linux, Windows and macOS in build/
make android    # a debug build for Android in build/android, see GAME.md 10.5
make android-install  # that build, installed on the phone adb can see
make android-release  # the release APK, signed with the release key, see GAME.md 10.5
```

`make run`, `make dev` and `make drive` hand `ARGS` to the game, after `--`.

`.godot` is a build cache, not source: Godot keeps its imported assets and its
register of every `class_name` there. The game cannot write it -- only an import
or the editor can -- so a fresh clone or a cleared `.godot` looks thoroughly
broken if it is started directly, with every script failing to parse because no
class is known. The targets above import first when it is missing, so `make run`
on a fresh clone works; `make import` does it on its own.

Anything a player would notice gets a line in the `## [Unreleased]` section of
`CHANGELOG.md` in the same commit, see GAME.md 10.4.

## Startup arguments

The game's own arguments go after `--` (or `++`), past Godot's:
`make run ARGS="--touch=1"`, or `./jackpot-junction.x86_64 -- --touch=1` for an
exported build. *Debug* is the game run from this checkout (`make run`, `make dev`,
the editor) or a debug export (`make android`); *release* is a release export
(`make export`, `make android-release`, and every published release).

### The game

Read on every scene, so they work in any build.

| Argument               | What it does                                                            | Debug | Release |
|------------------------|-------------------------------------------------------------------------|-------|---------|
| `--touch`, `--touch=1` | The touch controls on a desktop, the mouse standing in for a finger     | Yes   | Yes     |
| `--touch=0`            | No touch controls, even on a phone                                      | Yes   | Yes     |
| `--ui-scale=<scale>`   | The UI at this scale for this run alone, 0.5 to 3; saves nothing        | Yes   | Yes     |
| `--screenshot=<png>`   | Saves the screen after `--frames` frames and quits; needs a display     | Yes   | Yes     |
| `--frames=<n>`         | How many frames `--screenshot` waits, 8 unless given                    | Yes   | Yes     |
| `--bench=<n>`          | Runs n frames, prints the frame rate, draw calls and objects, and quits | Yes   | Yes     |

`--bench` leaves its first 120 frames out of the count, as the warm-up, so shader
compiles and the arena being built do not count against the frame rate.

### The development scene

`make dev ARGS="..."` starts `scenes/dev/playground.tscn`, a match on Lucky
Crossing with the debug overlay (F3) and the tuning panel (F4). The scene is left
out of every export, so these work from this checkout only: debug yes, release no.

| Argument            | What it does                                                    |
|---------------------|-----------------------------------------------------------------|
| `--players=<n>`     | Human players: the keyboard drives the first, gamepads the rest |
| `--bots=<n>`        | Bot karts after the humans, 1 unless given                      |
| `--difficulty=<d>`  | Bot difficulty: `easy`, `normal` or `hard`                      |
| `--map=<id>`        | Which map, by id (`lucky_crossing` unless given)                |
| `--jokers=<n>`      | Deals the first player this many random jokers                  |
| `--menu=<card>`     | Holds the first player's joker menu open on this card           |
| `--offer=1`         | Opens the respawn joker pick                                    |
| `--destroy=1`       | Opens the pick with a full hand, on the destroy step            |
| `--explosion=<s>`   | A bomb blast next to the player, this many seconds in           |
| `--flame=1`         | Shows the player's nitro flame                                  |
| `--oil=1`           | Drops an oil stain next to the player                           |
| `--burst=1`         | Pops a destruction burst next to the player                     |
| `--feed=1`          | Puts a few made-up kills in the kill feed                       |
| `--bounty=1`        | Puts a bounty on the second seat                                |
| `--banked=1`        | Spreads some banked score across the field                      |
| `--disco=<level>`   | Holds the excitement at this level, 1 to 6                      |
| `--results=1`       | Ends the match at once with made-up stats                       |
| `--fireworks=1`     | The winner's fireworks over the open-out camera                 |
| `--loading=1`       | Holds the lamps as if two players were still building the room  |
| `--finale=1`        | Ends a made-up two-map Grand Prix and stages its finale         |
| `--wide=1`          | Holds the camera on the whole room                              |
| `--back=<m>`        | Holds the camera this many meters back                          |
| `--clean=1`         | Hides the debug overlay, for screenshots of the game itself     |

### The tools

From this checkout only. `tools/godot` finds Godot through `$GODOT` first.

- `tools/trace_drive.gd`: `--out=<csv>`, `trace.csv` unless given, and
  `--program=launch`, `drift` or `nitro`, a lap unless given.
- `tools/multiplayer_check` takes none. `MPCHECK_PORT` picks the first port it
  uses, and `MPCHECK_LOGS=<dir>` keeps each role's whole log there.
- `tools/multiplayer_driver.gd` is started by `tools/multiplayer_check`, with
  `--role`, `--port`, `--clients`, `--locals`, `--jokers`, `--password`,
  `--wrong-first` and `--nameless`.

### Godot's own

Everything the recipes here use works in a release export too: `--path`,
`--resolution <W>x<H>`, `--fullscreen`, `--headless`, `--fixed-fps <fps>`,
`--max-fps <fps>`, `--disable-vsync`, `--time-scale <scale>`, `--print-fps` and
`-s <script>`. The debug drawing options, such as `--debug-collisions`,
`--debug-paths` and `--debug-navigation`, are for debug builds only. A template's
`--help` marks each option with R (every build) or D (debug only).

## Releasing

```
tools/changelog release 0.2.0     # cut Unreleased into a dated version, set project.godot
git commit -am "Release 0.2.0"
git tag -a v0.2.0 -m "Jackpot Junction 0.2.0" && git push --follow-tags
```

The tag starts the release workflow, which exports Linux, Windows and macOS
builds and publishes them with that version's changelog section as the release
notes. A tag whose version has no section fails rather than publishing a release
with nothing written on it. GAME.md 10.5 has the detail.

## License

The source code is licensed under the GPL-3.0, see `LICENSE`. Assets made for
the game are licensed under CC-BY-4.0. Third-party assets and libraries keep
their own licenses and are listed in `THIRD_PARTY.md`. The music is licensed
from Ovani Sound to this game's developer and is not covered by either
license.
