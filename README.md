<h1 align="center">
  <img src="assets/logo/banner.png" alt="Jackpot Junction" width="476">
</h1>

A top-down arena kart game in which every life is a hand of cards. Drive a
drifty toy kart through a bullet-filled diorama, collect poker-chip coins and
multipliers, and decide when to cash out at the Junction before someone shoots
you.

Made with Godot 4.7 and GDScript. `GAME.md` holds the design, `STORY.md` the
story under it (spoilers), `PLAN.md` the implementation plan with the status of
every milestone, and `CHANGELOG.md` what has changed in each release.
`docs/house-print/index.html` shows the art direction of the UI, House Print.

![The House's invitation on a dark table under two spotlights. On the left lies a cream bulk-mail envelope from THE HOUSE, Jackpot Junction, addressed TO: YOU, with a box of presorted postage, a green road sign stuck over its window reading JACKPOT JUNCTION, NEXT EXIT, ALL ROADS LEAD HERE, and YOU MAY ALREADY BE A WINNER! in red across its foot. On the right, turned a little toward the light so its gold shines, stands a red velvet card edged in gold with rays fanning from its top: GRAND OPENING TONIGHT over JACKPOT JUNCTION in gold, the four suits, "Fast karts. Loud tables. Real chips.", YOU'RE ON THE LIST and "RSVP not required. You'll come.", a gold star sticker offering FREE CHIPS FOR NEW DRIVERS, and below a row of punched holes a gold stub, ADMIT ONE DRIVER, with its number. Under them a single button: Accept the invitation](docs/opening-invitation.png)

*The invitation that brings you to the tables, the first time you start the game.*

Three arenas, three rooms to play them in, and an XL version of each with room to spare.

![A dark card room with a green baize arena on the table in the middle of it, the only lit thing in the room. A roulette wheel of red and black pockets is let into the baize at the center, with stacks of red chips and fanned playing cards round the walls and dice on the cloth beyond them. Neon signs hang over a crowd reduced to shapes with light along their edges, and the match clock glows orange above the far edge. Three players share the screen, a corner each: the first's dashboard is in the top left, in red, the second's in the top right, in blue, and the third's in the bottom left, in yellow, each with their drive hint beside it, the keyboard's and two gamepads'; the first player's hand of jokers is tucked small along the top beside their corner](docs/the-vault.png)

*The Vault, After Hours, three players at one screen.*

![A concrete yard in late afternoon light seen from high above, with a far bigger arena marked out on it than the usual map: two long stepped walls of pale blocks curve toward each other across it, a pit edged in black and yellow hazard stripes sits in each of their bends, and a disc bordered in the same stripes lies in the open middle, with karts small against all that floor. The crowd fills stepped tribunes on every side, with a truck, stacked drums and a forklift beyond them, and lit hoardings and the match clock along the far edge. Beside the clock at the top hangs a slim scrap of paper with a red map pin: the bet the player has pinned in the loyalty program, The Cashier's Cage, 17 of 25 cash-outs along a little road filling in gold. The player's hand is along the bottom](docs/crossfire-xl.png)

*Crossfire XL, in The Yard: the same room around a bigger arena, a loyalty program bet pinned by the clock.*

![A wide phone screen showing Lucky Crossing on The Workbench from above: a green felt arena on a wooden bench, low blocks and pits of spikes about a machined plate in the middle, karts and chips on the cloth, and a crowd packed round it with planks and rod stock beyond. The touch controls are drawn over it in the player's own red: a steering wheel in the lower left for the left thumb, and on the right a round Fire button beside a tall slider cut into Nitro, Gas, Reverse and Drift. The menu button sits in the top right corner over the standings strips, the player's dashboard is in the top left, and their hand of joker cards is along the bottom edge](docs/mobile.png)

*Lucky Crossing on a phone: the stick under the left thumb, Fire and the slider under the right.*

## Installing

Every release has the game for Windows, macOS, Linux and Android: download the
file for your system from the
[latest release](https://github.com/timvisee/jackpot-junction/releases/latest).
There is nothing to install beyond unpacking it.

| System       | Download                             | Then                                       |
|--------------|--------------------------------------|--------------------------------------------|
| Windows      | `jackpot-junction-…-windows.zip`     | Unzip it and run `jackpot-junction.exe`    |
| macOS        | `jackpot-junction-…-macos.zip`       | Unzip it and open the app                  |
| Linux        | `jackpot-junction-…-linux.zip`       | Unzip it and run `./jackpot-junction`      |
| Linux on ARM | `jackpot-junction-…-linux-arm64.zip` | The same                                   |
| Android      | `jackpot-junction-…-android.apk`     | Open it on the phone and allow the install |

The builds are not signed by a store, so the first start asks once: on Windows
choose More info and then Run anyway; on macOS open it, then allow it under
System Settings, Privacy & Security, Open Anyway, or run
`xattr -dr com.apple.quarantine` on the app; on Android let the browser or file
manager you opened it from install apps. To play together online everybody needs
the same major and minor version, such as 0.14.x. A dedicated server is in the same
release too, see [Running a server](#running-a-server).

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
- **Garage**, under Clubhouse: a practice room with one of everything in it and two
  dummy karts to shoot at.
- **Catalog**, under Clubhouse or on the License page of Settings: every joker and
  power-up you have found, the rest face down.

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
make run ARGS=--settings=fresh.cfg  # the game as a new player sees it, its settings kept apart
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

`GODOT_HIDDEN=1` runs anything that opens a window without one on the desktop, for
screenshots, benches and probes in the background: `tools/godot` runs it inside
[gamescope](https://github.com/ValveSoftware/gamescope)'s headless backend, still
on the GPU, at the `--resolution` asked for. `make check` needs none of it, being
headless already.

```
GODOT_HIDDEN=1 make bench
GODOT_HIDDEN=1 tools/godot --path . --resolution 1600x900 res://scenes/ui/title.tscn \
	-- --frames=300 --screenshot=title.png
```

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
`make run ARGS="--touch=1"`, or `./jackpot-junction -- --touch=1` for an
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
| `--settings=<path>`    | Another settings file for this run, `user://`, absolute or a bare name  | Yes   | Yes     |
| `--intro=0`            | No opening on the title: the menu is there from the start               | Yes   | Yes     |
| `--intro`, `--intro=1` | The title's opening even where it is left out, a screenshot run say     | Yes   | Yes     |
| `--screenshot=<png>`   | Saves the screen after `--frames` frames and quits; needs a display     | Yes   | Yes     |
| `--frames=<n>`         | How many frames `--screenshot` waits, 8 unless given                    | Yes   | Yes     |
| `--no-countdown`       | Every map starts at once, with no countdown to wait out                 | Yes   | Yes     |
| `--show-clearance`     | Draws what the camera keeps the karts clear of: the HUD's panels        | Yes   | Yes     |
| `--bench=<n>`          | Runs n frames, prints the frame rate, draw calls and objects, and quits | Yes   | Yes     |
| `--run-frames=<n>`     | Runs n frames and quits the way a player does; `tools/smoke` uses it    | Yes   | Yes     |
| `--server`             | Runs a dedicated server instead of the game, see Running a server       | Yes   | Yes     |
| `--port=<port>`        | With `--server`: the port players connect to, 7777 unless given         | Yes   | Yes     |
| `--games=<n>`          | With `--server`: how many games it holds at once, 8 unless given        | Yes   | Yes     |
| `--game-ports=<a>-<b>` | With `--server`: its games' ports, the ones after `--port` unless given | Yes   | Yes     |
| `--name=<name>`        | With `--server`: the name players see it by, its address unless given   | Yes   | Yes     |
| `--password=<word>`    | With `--server`: a password players need to come in, none unless given  | Yes   | Yes     |

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

### The story (spoilers)

The story of `STORY.md` moves with time spent on maps once a profile
has its license, so it can be hurried along for trying it out. These are read as
the game starts, in a debug build alone. Try them on a profile of their own, so
your own story is left where it is:
`make run ARGS="--settings=story-test --story-notes --story-stage=3"`.

| Argument                  | What it does                                                              | Debug | Release |
|---------------------------|---------------------------------------------------------------------------|-------|---------|
| `--story-license`         | Licenses the profile playing at once, as the driving test would; kept     | Yes   | No      |
| `--story-notes`           | Every note found, the ones not found before new, licensing it first; kept | Yes   | No      |
| `--story-stage=<n>`       | Shows stage n, 0 to 5, for this run alone; saves nothing                  | Yes   | No      |
| `--story-clock=<seconds>` | Reads the story's clock as this for what moves with it; saves nothing     | Yes   | No      |
| `--story-final-hand`      | Deals the Final Hand on the next Play                                     | Yes   | No      |
| `--story-note=<n>`        | Lays note n on the next map's floor at once                               | Yes   | No      |
| `--story-invitation`      | Shows the first invitation over the title again, whatever the profile    | Yes   | No      |
| `--story-invitation=0`    | Leaves the first invitation out for this run alone; it comes next time   | Yes   | No      |

The catalog of every joker a profile took and every power-up it used, GAME.md 8.8, can be filled at once the same
way, in a debug build alone: `make run ARGS="--settings=catalog-test --catalog-all"`.

| Argument        | What it does                                                               | Debug | Release |
|-----------------|----------------------------------------------------------------------------|-------|---------|
| `--catalog-all` | Every joker taken, at its biggest stack, and power-up used once more; kept   | Yes   | No      |

The loyalty program, GAME.md 8.9, can be moved on at once too, in a debug build alone:
`make run ARGS="--settings=loyalty-test --loyalty-lap=2"`.

| Argument               | What it does                                                                 | Debug | Release |
|------------------------|------------------------------------------------------------------------------|-------|---------|
| `--loyalty-all`        | Welcomes the profile playing and wins it every landmark; kept                | Yes   | No      |
| `--loyalty-won=<ids>`  | Welcomes it and wins the landmarks named, a comma between them; kept         | Yes   | No      |
| `--loyalty-lap=<n>`    | Every landmark won and lap n of the roundabout, an edition owed a lap; kept  | Yes   | No      |
| `--loyalty-near`       | Every open bet, and the ring's, a step short of its count; kept              | Yes   | No      |
| `--loyalty-lost`       | Every open thing of Lost Property certain in its room's next map; kept       | Yes   | No      |
| `--loyalty-pin=<id>`   | Welcomes it and pins the landmark named, where it can be pinned; kept        | Yes   | No      |
| `--loyalty-welcome`    | Puts the welcome card up at the title whether or not it is due               | Yes   | No      |

A debug build's settings also have a last tab, Debug, saying where the profile
playing is in the story, its stage, clock, notes and Final Hand, with buttons that
move it on or back, hand it every note or none, and start it over; and where it is
in the loyalty program, with buttons that give it the card at once, the welcome
again, every landmark, every bet a step short, Lost Property, a lap, an edition, or
the program over. Every change is kept in the profile. In a match, F3's overlay has
a line on the story too.

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
sound at all. The game itself serves too, told to, and then loads no sound
either:

```
./jackpot-junction-server                                             # the server build
./jackpot-junction-server -- --port=7777 --games=8
./jackpot-junction --headless -- --server                             # the game, as a server
make server ARGS="--games=4"                                          # from this checkout
```

Players connect with Play Online, to the server's address and port. It
listens on 7777, as a LAN game does, unless given `--port`, and runs each game
in a process of its own on the ports after it, up to `--games` of them: 7778 to
7785 by default, so let UDP 7777 to 7785 through a firewall or router.
`--game-ports=9000-9015` puts the games on ports of their own instead. A LAN
game on the same machine needs another port. `--name="Friday night"` gives the
server a name, which players see over its games, and `--password=...` keeps it
to the people told: Play Online asks for it before it shows the server's games,
and the games turn away anybody who comes straight to their ports without it.

The same five can be set in the environment, which the command line overrides:

| Variable        | Argument       | Default                                  |
|-----------------|----------------|------------------------------------------|
| `JJ_PORT`       | `--port`       | `7777`                                   |
| `JJ_GAMES`      | `--games`      | `8`, or as many as `JJ_GAME_PORTS` holds |
| `JJ_GAME_PORTS` | `--game-ports` | the `JJ_GAMES` ports after `JJ_PORT`     |
| `JJ_NAME`       | `--name`       | none, so players see its address         |
| `JJ_PASSWORD`   | `--password`   | none, so anybody may come in             |

A game is about a quarter of a gigabyte of memory, and a server with no game
running about 90 MB and next to no processor: a game's process is only started
when somebody makes a game. Whoever makes a game has the host's say over it,
passed on to whoever has been in it longest when they leave, and a game ends by
itself once everybody playing has left it. The server logs where it listens as
it starts, every address of its machine, and then every player coming and going
and every game's state to its output, one line each, with the time and the game.

Anything that connects and does not say hello the way the game does is dropped
at once and logged with its address, `Dropped 1.2.3.4: said 18 bytes that are
not a Jackpot Junction hello`, and so are too many connections from one address;
a player who misbehaves once in is kicked, `Kicked Ann, from 1.2.3.4: ...`. A
flood of datagrams that are not the game's never reaches the game and cannot be
traced to a sender, so the server only logs that it is getting one, once a
minute: rate limiting UDP 7777 to 7785 in the firewall is the way to stop one.

### With Docker

Every release also publishes the server as a Docker image for x86_64 and ARM,
[`timvisee/jackpot-junction-server`](https://hub.docker.com/r/timvisee/jackpot-junction-server),
tagged with its version, such as `0.11.0`, and the newest as `latest`. It holds
the server build and the C library it runs on, and runs as a user of its own
rather than root. To run it:

```
docker run -d --name jackpot-junction --restart unless-stopped \
  -p 7777-7785:7777-7785/udp timvisee/jackpot-junction-server
```

Or with Docker Compose, from [`docker/compose.yaml`](docker/compose.yaml):

```
curl -O https://raw.githubusercontent.com/timvisee/jackpot-junction/master/docker/compose.yaml
docker compose up -d
docker compose logs -f                  # the server's log
docker compose pull && docker compose up -d     # to the newest release
```

The server is set with the environment variables above, `-e JJ_GAMES=4` or
`-e JJ_NAME="Friday night"`, or
with its arguments after the image's name,
`timvisee/jackpot-junction-server --games=4`. Publish every port as the same
number on the host as in the container, `-p 9000-9015:9000-9015/udp` for
`JJ_GAME_PORTS=9000-9015`: the server tells a player which port their game is
on, and they connect to that number. Players need the same major and minor
version as the server, so pin the tag, `:0.11.0`, to upgrade only when they do.
The log's times are UTC unless `TZ` is set, `-e TZ=Europe/Amsterdam`, and the
addresses it says it listens on are the container's own rather than the host's.
`make docker` builds the image from this checkout, for this machine.

## Releasing

```
tools/changelog release 0.2.0     # cut Unreleased into a dated version, set project.godot
git commit -am "Release 0.2.0"
git tag -a v0.2.0 -m "Jackpot Junction 0.2.0" && git push --follow-tags
```

The tag starts the release workflow, which exports Linux, Windows and macOS
builds, the Linux server build and the Android APK, the Linux ones for 64-bit
ARM as well, and publishes them with that version's changelog section as the
release notes, and the server's Docker image to Docker Hub. A tag whose version
has no section fails rather than publishing a release with nothing written on
it. GAME.md 10.5 has the detail, and the two secrets Docker Hub needs.

## License

The source code is licensed under the GPL-3.0, see `LICENSE`. Assets made for
the game are licensed under CC-BY-4.0. Third-party assets and libraries keep
their own licenses and are listed in `THIRD_PARTY.md`. The music is licensed
from Ovani Sound to this game's developer and is not covered by either
license.
