# Development

How to build, run, test and release Jackpot Junction from this checkout. The rest of the
documentation sits beside this file: [GAME.md](GAME.md) is the design, which the code cites by
section ("GAME.md 3.8"), [STORY.md](STORY.md) the story under it (spoilers), [PLAN.md](PLAN.md)
the implementation plan with the status of every milestone, [CHANGELOG.md](CHANGELOG.md) what
changed in each release, and [SERVER.md](SERVER.md) how to run a dedicated server.
[house-print/index.html](house-print/index.html) shows the art direction of the UI, House Print.

## Building and running

Requires a Godot 4.7 binary. `tools/godot` finds it through `$GODOT`, the Steam
install, or `godot4` on the path. Lint and format use
[gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit): `pipx install gdtoolkit`. Rebuilding
the karts takes Blender 5, `blender` on the path, see [The karts](#the-karts).

```
make dev        # start the development scene
make server     # a dedicated server, headless, see SERVER.md
make jokers     # every joker and power-up icon on one screen, to see them as a set
make run        # start the game scene
make run ARGS=--touch=1  # the game with the touch controls, the mouse standing in for a finger
make run ARGS="--touch=1 --ui-scale=1.5"  # the same at a phone's UI scale, saving nothing
make run ARGS=--settings=fresh.cfg  # the game as a new player sees it, its settings kept apart
make demo       # the demo for a booth: Grand Prix after Grand Prix on its own, GAME.md 9.8
make demo-soak  # the demo for several runs on end, failing if anything piles up between them
make check      # import, lint, format check, changelog, unit tests, smoke runs, multiplayer
make test       # unit tests only (gdUnit4, headless, a suite per process in parallel)
make bench      # the frame rate of a match on each map
make profile    # where a frame goes: script functions, server and GPU passes, from the profilers
make probe      # what a frame is made of: meshes, triangles, materials, lights, draw calls by pass
make warmup-check  # whether the shader warm-up behind the title covers everything a player meets
make dialog-bench  # the achievements dialog's and the catalog's draw calls a frame, against budgets
make ui-bench   # the HUD's, pause menu's, match settings', title's, settings' and school's draw calls, against budgets
                # (the performance rules these keep, and their numbers, are in GAME.md 10.7)
make multiplayer  # a whole Grand Prix online (two games, up to two clients) and on one screen
make server-check  # a game on a dedicated server, made, joined and watched by three clients
make export     # release builds for Linux, Windows and macOS, and the Linux server, in build/
make android    # a debug build for Android in build/android, see GAME.md 10.5
make android-install  # that build, installed on the phone adb can see
make android-release  # the release APK, signed with the release key, see GAME.md 10.5
make itch-art  # the itch.io page's cover and background in build/itch, see ITCH.md
make screenshots  # the README's shots in docs/screenshots, oversampled; GODOT_HIDDEN=1 for no window
make steam-addon  # GodotSteam into addons/godotsteam, pinned and checked, for the Steam builds
make steam-run  # the game with Steam on, as Spacewar (480); Steam must be running
make steam-check  # what the Steam client here answers: the account, presence, a lobby
make steam-export  # the Steam builds in build/steam, STEAM_APP_ID=<id> for an app of its own
```

`make run`, `make dev` and `make server` hand `ARGS` to the game, after `--`.

Steam, GAME.md 10.8, is never on unless asked for: only a Steam export, from
`make steam-export`, or `--steam` turns it on, so no test or tool ever talks to
Steam; the tests hand the game a fake of it, `tests/fake_steam.gd`. With Steam
running and logged in, `make steam-addon` once, then `make steam-run` plays as
Spacewar, app 480. `JJ_STEAM_PEER=1` in the environment sends every online game
through the Steam game's own connection, `SteamPeer`, over ENet on this machine:
`JJ_STEAM_PEER=1 make test multiplayer` plays the online suites and checks through
what a Steam game plays through, but for the checks of ENet itself.

Tests, checks and benches never touch your own settings and profiles: anything run as
a script, `-s`, which every gdUnit test and every tool in `tools/` is, plays on
`user://tests.cfg` and the profiles beside it, shared between them, and the tools
that start the game as a scene set `JJ_SETTINGS=tests.cfg` for it. Do the same for
anything run by hand in the background, a screenshot say:
`JJ_SETTINGS=tests.cfg make dev ARGS="--screenshot=shot.png"`. `--settings=<path>`
names another file for one run, and wins over both.

`GODOT_HIDDEN=1` runs anything that opens a window without one on the desktop, for
screenshots, benches and probes in the background: `tools/godot` runs it inside
[gamescope](https://github.com/ValveSoftware/gamescope)'s headless backend, still
on the GPU, at the `--resolution` asked for, and silent. `make check` needs none of
it, being headless already.

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
[CHANGELOG.md](CHANGELOG.md) in the same commit, see GAME.md 10.4.

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
| `--demo`               | The demo for a booth, GAME.md 9.8, on `user://demo.cfg` unless named    | Yes   | Yes     |
| `--demo-seats=<n>`     | With `--demo`: seats with a HUD and a bot at the wheel, 1 to 4, else 2  | Yes   | Yes     |
| `--demo-bots=<n>`      | With `--demo`: plain bots beside them, 2 unless given                   | Yes   | Yes     |
| `--intro=0`            | No opening on the title: the menu is there from the start               | Yes   | Yes     |
| `--intro`, `--intro=1` | The title's opening even where it is left out, a screenshot run say     | Yes   | Yes     |
| `--screenshot=<png>`   | Saves the screen after `--frames` frames and quits; needs a display     | Yes   | Yes     |
| `--frames=<n>`         | How many frames `--screenshot` waits, 8 unless given                    | Yes   | Yes     |
| `--screenshot-oversample=<n>` | Draws the shot n times oversize and brings it down, for smooth edges | Yes | Yes |
| `--no-countdown`       | Every map starts at once, with no countdown to wait out                 | Yes   | Yes     |
| `--show-clearance`     | Draws what the camera keeps the karts clear of: the HUD's panels        | Yes   | Yes     |
| `--bench=<n>`          | Runs n frames, prints the frame rate, draw calls and objects, and quits | Yes   | Yes     |
| `--run-frames=<n>`     | Runs n frames and quits the way a player does; `tools/smoke` uses it    | Yes   | Yes     |
| `--server`             | Runs a dedicated server instead of the game, see SERVER.md              | Yes   | Yes     |
| `--steam`              | Steam on as in a Steam build, GAME.md 10.8; needs `make steam-addon`    | Yes   | Yes     |
| `--no-steam`           | Steam off, even in a Steam build                                        | Yes   | Yes     |
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

`make dialog-bench` (`tools/dialog_bench`) opens the achievements dialog, the
catalog, the loyalty program's and the kart dialog, each in a user directory of
its own, holds each still and then scrolls it, walks its cursor along its cards,
drags its map or walks along its rack of hats, and says their draw calls and their
time a frame. It fails above 300 draw calls a frame for any of them, which is where
they would be again if their art were drawn as itself every frame rather than once
into pictures, GAME.md 10.7. Run it whenever a dialog or what is drawn in it
changes.

### The story (spoilers)

The story of [STORY.md](STORY.md) moves with time spent on maps once a profile
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
| `--story-letter`          | Shows the House's next letter owed over the title; filed once put away    | Yes   | No      |

In a debug build the pause menu at the Final Hand has Debug: skip to end, which blows the whistle
at once, with no overtime, and brings the payout slip straight up, to look at the House's page
without playing the table out. It is there wherever the match is this machine's to end.

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

The achievements, GAME.md 8.10, can be earned or taken back at once too, in a debug build alone:
`make run ARGS="--settings=achievements-test --achievements-none --story-license"`.

| Argument                     | What it does                                                          | Debug | Release |
|------------------------------|-----------------------------------------------------------------------|-------|---------|
| `--achievements-all`         | Earns the profile playing every achievement, each new; kept           | Yes   | No      |
| `--achievement=<ids>`        | Earns it the achievements named, a comma between them; kept           | Yes   | No      |
| `--achievements-none`        | Takes every one back, and credits the profile again at the title; kept | Yes   | No      |
| `--achievement-toast=<ids>`  | Puts each named up as a toast once the title is up; keeps nothing     | Yes   | No      |

A Grand Prix that ends level goes on to a showdown, GAME.md 9.7a; its map, Showdown, is last in a
quick match's arenas too, where it is a showdown for the whole room. A debug build can make a run end
level every time: `make run ARGS="--grand-prix-tie"`, then a Grand Prix of 2 maps at 5 s.

| Argument           | What it does                                                           | Debug | Release |
|--------------------|------------------------------------------------------------------------|-------|---------|
| `--grand-prix-tie` | Pays every seat the same points for every map, so every run ends level | Yes   | No      |

The demo for a booth, GAME.md 9.8, plays its maps for three minutes. A debug build can make them
shorter, to see a run through in little time or soak the demo over many:
`make demo ARGS="--settings=demo-test --demo-map-seconds=20"`.

| Argument                 | What it does                                                     | Debug | Release |
|--------------------------|------------------------------------------------------------------|-------|---------|
| `--demo-map-seconds=<s>` | With `--demo`: each map this many seconds long, at least 10      | Yes   | No      |

A debug build's settings also have a last tab, Debug, saying where the profile
playing is in the story, its stage, clock, notes and Final Hand, with buttons that
move it on or back, hand it every note or none, and start it over; and where it is
in the loyalty program, with buttons that give it the card at once, the welcome
again, every landmark, every bet a step short, Lost Property, a lap, an edition, or
the program over; and how many achievements it has, with buttons that earn every one,
take them back, credit it again as a profile from before them, or earn the next with
its toast. Every change is kept in the profile. In a match, F3's overlay has
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
| `--teams=<n>`       | Plays in this many teams, 2 to 4                                |
| `--friendly-fire=1` | Lets teammates hurt each other                                  |
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
| `--autopilot=1`     | A bot's brain drives the first player's kart, nothing offered   |
| `--house=<share>`   | The story's Final Hand on House Rules, its clock this far in    |

### The tools

From this checkout only. `tools/godot` finds Godot through `$GODOT` first.

- `tools/trace_drive.gd`: `--out=<csv>`, `trace.csv` unless given, and
  `--program=launch`, `drift` or `nitro`, a lap unless given.
- `tools/multiplayer_check` takes none. `MPCHECK_PORT` picks the first port it
  uses, a free block otherwise, see `tools/free_port`, and `MPCHECK_LOGS=<dir>`
  keeps each role's whole log there. Like `tools/server_check` and every run of
  `tools/test_parallel`, it has a user directory of its own, so checks and test
  runs at once from two checkouts or sessions keep out of each other's ports,
  settings and profiles; the network suites take free ports from
  `tests/free_ports.gd` the same way.
- `tools/multiplayer_driver.gd` is started by `tools/multiplayer_check`, with
  `--role`, `--port`, `--clients`, `--locals`, `--jokers`, `--password`,
  `--wrong-first` and `--nameless`.
- `tools/server_check` takes none. `SVCHECK_PORT` picks the server's port, a free
  block otherwise, and
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


## The karts

The karts, GAME.md 8.1b, are built in Blender from a script, one chassis under each of the bodies,
and their prints are drawn with Pillow; the tin's go into `assets/models/tin-kart/`, the other
bodies' into `assets/models/karts/`, and the game imports what they write. Change the script, run
both, then `make import`:

```
tools/make_kart_prints.py [body ...]                                # the hubs, driver and prints
blender -b --factory-startup --python tools/make_kart.py [-- body ...]   # a .glb for each body
```

With no body named, both do them all: tin, racer, woodie, streamliner and microcar. The prints
are seeded, so drawing them again draws the same pictures.

A player picks the body in the kart dialog from `KartStyle.BODIES`, the racer, woodie, streamliner
and microcar, each a model of `KartVisuals.BODIES` by its name in lower case; the tin is built but
offered to nobody. A body added to the script needs a name in both, a landmark of
`data/loyalty/map.tres` to pay it, and to be the same chassis under its shell: the collider in
`scenes/kart/kart.tscn` is one box for every body.

How the rooms are drawn, the Video page's Look, can be tried on the playground without the menu:
`make dev ARGS="--look=houseprint"`, or `--look-cycle=110` for every look in turn with its name on
the screen.


## Releasing

```
tools/changelog release 0.2.0     # cut Unreleased in docs/CHANGELOG.md into a version, set project.godot
git commit -am "Release 0.2.0"
git tag -a v0.2.0 -m "Jackpot Junction 0.2.0" && git push --follow-tags
```

The tag starts the release workflow, which exports Linux, Windows and macOS
builds, the Linux server build and the Android APK, the Linux ones for 64-bit
ARM as well, and publishes them with that version's changelog section as the
release notes, and the server's Docker image to Docker Hub. A tag whose version
has no section fails rather than publishing a release with nothing written on
it. GAME.md 10.5 has the detail, and the two secrets Docker Hub needs.
