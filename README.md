# Jackpot Junction

A top-down arena kart game in which every life is a hand of cards. Drive a
drifty toy kart through a bullet-filled diorama, collect poker-chip coins and
multipliers, and decide when to cash out at the Junction before someone shoots
you.

Made with Godot 4.7 and GDScript. `GAME.md` holds the design, `PLAN.md` the
implementation plan with the status of every milestone, and `CHANGELOG.md` what
has changed in each release.

Three arenas, three rooms to play them in, and an XL version of each with room to spare.

![A green felt arena on a workbench, lit by a lamp over it, with karts driving between low blocks and a machined steel plate set into the felt in the middle of it. Bundles of rod stock and stacks of planks lie about the bench around the table, and a crowd of onlookers rings the arena, packed at the rail and thinning outward. Glass tanks filled to different levels, a DJ booth, two lit hoardings and a board keeping the match clock stand at the far edge; the player's score sits on a dark card in the top left, the standings run down the right and a hand of joker cards along the bottom of the screen](docs/lucky-crossing.png)

*Lucky Crossing, on The Workbench.*

![A dark card room with a green baize arena on the table in the middle of it, the only lit thing in the room. A roulette wheel of red and black pockets is let into the baize at the center, with stacks of red chips and fanned playing cards round the walls and dice on the cloth beyond them. Neon signs hang over a crowd reduced to shapes with light along their edges, and the match clock glows orange above the far edge](docs/the-vault.png)

*The Vault, After Hours.*

![A concrete yard in late afternoon light seen from high above, with a far bigger arena marked out on it than the usual map: two long stepped walls of pale blocks curve toward each other across it, a pit edged in black and yellow hazard stripes sits in each of their bends, and a disc bordered in the same stripes lies in the open middle, with karts small against all that floor. The crowd fills stepped tribunes on every side, with a truck, stacked drums and a forklift beyond them, and lit hoardings and the match clock along the far edge](docs/crossfire-xl.png)

*Crossfire XL, in The Yard: the same room around a bigger arena.*

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
- **Online**: Play Online, on a dedicated server: make a game there and host it
  from your own machine, or join one somebody else made. See
  [Running a server](#running-a-server).
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
make server     # a dedicated server, headless, see Running a server
make drive      # start the driving room, for handling work
make jokers     # every joker and power-up icon on one screen, to see them as a set
make run        # start the game scene
make run ARGS=--touch=1  # the game with the touch controls, the mouse standing in for a finger
make run ARGS="--touch=1 --ui-scale=1.5"  # the same at a phone's UI scale, saving nothing
make check      # import, lint, format check, changelog, unit tests, smoke runs, multiplayer
make test       # unit tests only (gdUnit4, headless, a suite per process in parallel)
make bench      # the frame rate of a match on each map
make profile    # where a frame goes: script functions, server and GPU passes, from the profilers
make probe      # what a frame is made of: meshes, triangles, materials, lights, draw calls by pass
make warmup-check  # whether the shader warm-up behind the title covers everything a player meets
                # (the performance rules these keep, and their numbers, are in GAME.md 10.7)
make multiplayer  # a whole Grand Prix online (two games, up to two clients) and on one screen
make server-check  # a game on a dedicated server, made, joined and watched by three clients
make export     # release builds for Linux, Windows and macOS, and the Linux server, in build/
make android    # a debug build for Android in build/android, see GAME.md 10.5
make android-install  # that build, installed on the phone adb can see
make android-release  # the release APK, signed with the release key, see GAME.md 10.5
```

`make run`, `make dev`, `make drive` and `make server` hand `ARGS` to the game, after `--`.

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
| `--server`             | Runs a dedicated server instead of the game, see Running a server       | Yes   | Yes     |
| `--port=<port>`        | With `--server`: the port players connect to, 7777 unless given         | Yes   | Yes     |
| `--games=<n>`          | With `--server`: how many games it holds at once, 8 unless given        | Yes   | Yes     |

`--bench` leaves its first 120 frames out of the count, as the warm-up, so shader
compiles and the arena being built do not count against the frame rate, and it
ignores the Frame rate limit setting.

`make profile` (`tools/profile [frames] [playground args]`) runs the same match
under Godot's own profilers and prints where a frame goes: the script functions
by their own time with calls per frame, the physics and audio server passes, the
GPU passes as running timestamps within the frame, and the performance monitors.
`tools/profile_server.gd` stands in for the editor's debugger over the remote
debug protocol, so no editor is needed. `PROFILE_GODOT_ARGS="--rendering-method
mobile --resolution 2400x1080"` measures with a phone's renderer at its size, and
`PROFILE_OUT=<file>` keeps the profile. Profiling slows the scripts down, so read
the ranking rather than the numbers.

`make probe` (`tools/scene_probe.gd`) says what a frame is made of: every mesh
instance by the script that built it, with its triangles, the distinct meshes and
materials, the lights and particle systems, and the draw calls and primitives of
the visible pass, the shadow pass and the canvas. `make probe ARGS="--ablate"`
then hides one group at a time and prints what each costs in every pass.

`make warmup-check` (`tools/warmup_check`) runs the title in a user directory of
its own until the shader warm-up behind it has finished, then a match with one of
everything in it, the results and the Grand Prix finale, counting the shader
cache after each. It fails if anything compiled after the title: that is a shader
a player would meet as a stutter, and it belongs in `ShaderWarmup`'s plan, GAME.md
10.7. Run it whenever a new effect, pickup, dress, HUD piece, room or material
lands, on `--rendering-method mobile` too via `WARMUP_GODOT_ARGS`.

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
- `tools/server_check` takes none. `SVCHECK_PORT` picks the server's port and
  `SVCHECK_LOGS=<dir>` keeps every process's whole log there, the server's among
  them. It starts `tools/server_driver.gd` with `--role` (`maker`, `joiner` or
  `watcher`) and `--port`. `SVCHECK_SERVER=<binary>` plays against an exported
  server build rather than this checkout, which is the only way to see what a
  release build does that an editor build does not; it offers no match as short
  as the clients ask for, so `SVCHECK_LENGTH=60` goes with it, and its idle
  memory is a release build's, so `SVCHECK_IDLE_MB` wants raising. The check fails
  on any engine error in the server's log.

### Godot's own

Most of what the recipes here use works in a release export too:
`--resolution <W>x<H>`, `--fullscreen`, `--headless`, `--fixed-fps <fps>`,
`--max-fps <fps>`, `--disable-vsync`, `--time-scale <scale>` and `--print-fps`.
`--path`, `--main-pack`, `-s <script>` and a scene given on the command line are
the editor's alone: an export template refuses them, and always starts the
game's own first scene. The debug drawing options, such as `--debug-collisions`,
`--debug-paths` and `--debug-navigation`, are for debug builds only. A template's
`--help` marks each option with R (every build) or D (debug only).

## Running a server

A dedicated server holds games for players over the internet, so nobody's own
machine has to host, see GAME.md 9.3a. Every release has a Linux server build
for it, `jackpot-junction-server`: the game exported as a server, headless and
serving by itself, with its pictures and models stripped to their sizes and no
sound at all. The game itself serves too, told to:

```
./jackpot-junction-server.x86_64                                      # the server build
./jackpot-junction-server.x86_64 -- --port=7777 --games=8
./jackpot-junction.x86_64 --headless -- --server                      # the game, as a server
make server ARGS="--games=4"                                          # from this checkout
```

Players connect with Play Online, to the server's address and port. It
listens on 7777, as a LAN game does, unless given `--port`, and runs each game
in a process of its own on the ports after it, up to `--games` of them: 7778 to
7785 by default, so let UDP 7777 to 7785 through a firewall or router. A LAN
game on the same machine needs another port. A game is about a quarter of a
gigabyte of memory, and a server with no game running about 90 MB and next to
no processor: a game's process is only started when somebody makes a game.
Whoever makes a game has the host's say over it, passed on to whoever has been
in it longest when they leave, and a game ends by itself once everybody playing
has left it. The server logs every player coming and
going and every game's state to its output, one line each, with the time and
the game.

## Releasing

```
tools/changelog release 0.2.0     # cut Unreleased into a dated version, set project.godot
git commit -am "Release 0.2.0"
git tag -a v0.2.0 -m "Jackpot Junction 0.2.0" && git push --follow-tags
```

The tag starts the release workflow, which exports Linux, Windows and macOS
builds, the Linux server build and the Android APK, and publishes them with that
version's changelog section as the release notes. A tag whose version has no section fails rather than publishing a release
with nothing written on it. GAME.md 10.5 has the detail.

## License

The source code is licensed under the GPL-3.0, see `LICENSE`. Assets made for
the game are licensed under CC-BY-4.0. Third-party assets and libraries keep
their own licenses and are listed in `THIRD_PARTY.md`. The music is licensed
from Ovani Sound to this game's developer and is not covered by either
license.
