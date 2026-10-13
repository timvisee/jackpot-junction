# Implementation plan

GAME.md is the design and the source of truth for rules and numbers. This file
is the order of work: what gets built when, in which files, and how each step
is verified. Tick tasks off as they land. When implementation forces a design
change, change GAME.md first, then the code.

## Environment

| Item             | State                                                                                     |
|------------------|-------------------------------------------------------------------------------------------|
| Godot            | 4.7.2 stable via Steam: `~/.local/share/Steam/steamapps/common/Godot Engine/godot.x11.opt.tools.64`. Runs headless. `~/bin/godot` is 4.4.1 and must not touch this project |
| Export templates | The Steam Godot ships its own under `editor_data/export_templates`, so `make export` works locally; the release workflow downloads the official 4.7.2 templates |
| gdUnit4          | Not installed. Add to `addons/` in phase 0, pinned to a release that supports 4.7        |
| gdtoolkit        | Not installed. `pipx install gdtoolkit` for `gdlint` and `gdformat`                       |
| CI               | GitHub Actions, repo `timvisee/jackpot-junction`, branch `master`                         |
| Display          | A local display is available. Windowed runs from the agent sandbox render at about 1 frame per second, so screenshots use few frames: `tools/godot --path . --disable-vsync res://scenes/dev/playground.tscn ++ --screenshot=<png> --frames=8`. Handling feel still needs a human |

Headless commands used throughout, with `godot47` standing for the Steam binary:

```
godot47 --headless --path . --import                        # reimport assets, catch parse errors
godot47 --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests   # unit tests
godot47 --headless --path . res://scenes/dev/playground.tscn --quit-after 300  # scene smoke run
godot47 --headless --path . --doctool /tmp/godot-doc         # dump the 4.7 class reference when an API is in doubt
gdlint scenes scripts tests && gdformat --check scenes scripts tests
```

## Decisions fixed for implementation

These refine GAME.md without changing its rules.

- **Plane movement.** Karts are CharacterBody3D in floating motion mode with no
  gravity; all gameplay happens on the XZ plane. Falling into a pit is an
  animation, not physics. This keeps movement deterministic and easy to
  network.
- **Fixed tick.** All gameplay runs in `_physics_process` at 60 Hz. Rendering
  uses physics interpolation. Nothing gameplay-relevant reads `delta` from
  `_process`.
- **Arena from text.** The map is an `ArenaLayout` resource holding the ASCII
  grid from GAME.md 6.3. An `ArenaBuilder` turns it into geometry and markers at
  load: consecutive wall cells merge into segments, every letter becomes the
  matching element scene. Editing the map means editing text.
- **Identity by slot.** Players and bots are slots 0 to 3. Kills, ownership and
  scores reference slot ids, never node paths or instance ids.
- **One RNG.** All randomness goes through a RandomNumberGenerator owned by the
  Match and seeded at match start, so online play can replicate the seed.
- **Bullets step by cast.** Each tick a bullet casts a sphere from its previous
  to its next position against walls, karts, crates, turrets and other bullets,
  and resolves the first hit. No tunnelling at any speed.
- **Bots path on the grid.** AStarGrid2D over the 32 by 18 arena grid, cells of
  1.25 m, walls, crates and pits marked solid, with local steering and bullet
  dodging on top. No navmesh baking.
- **Physics layers.** 1 `world`, 2 `kart`, 3 `bullet`, 4 `pickup`, 5 `trigger`,
  6 `graze`, 7 `turret`. Spawn-protected karts move to a `protected` layer that
  bullets do not scan.
- **Events autoload.** Global signals: `coin_collected`, `mult_gained`,
  `grazed`, `kart_killed`, `kart_respawned`, `bank_started`, `bank_completed`,
  `jackpot_collected`, `jackpot_full`, `item_picked`, `item_used`,
  `joker_offered`, `joker_taken`, `match_state_changed`. HUD, audio, tally and
  jokers subscribe; gameplay code emits and never reaches into UI.
- **Resources.** `KartStats`, `CannonStats`, `PowerUp` and subclasses, `Joker`
  and subclasses, `BotTrait`, `BotDifficulty`, `ArenaLayout`. Every number in
  GAME.md lives in one of these or in an exported variable.
- **Joker menu selection** uses D-pad left and right to cycle slots on a
  gamepad, 1 to 5 on keyboard.

## Phase 0: project setup

Goal: a project that imports, lints, tests and runs headless with an empty
scene, plus the repository basics.

- [x] `project.godot`: name "Jackpot Junction", main scene, 1920 by 1080
      window, MSAA 2x, physics interpolation on, 60 Hz physics, Jolt, layer
      names, `untyped_declaration` warning as error, autoloads `Game`, `Events`,
      `Audio`.
- [x] Input map: `steer_left`, `steer_right`, `throttle`, `brake`, `fire`,
      `handbrake`, `use_item`, `joker_menu`, `joker_prev`, `joker_next`,
      `joker_select_1` to `joker_select_5`, `joker_drop`, `joker_destroy`,
      `aim_x`, `aim_y`, `pause`, bound as in GAME.md 4.2.
- [x] Folder layout from GAME.md 10.2, autoload scripts with empty bodies.
- [x] `LICENSE` with GPL-3.0, `README.md` with a paragraph, how to run, and the
      license split for code and assets.
- [x] gdUnit4 in `addons/`, row in `THIRD_PARTY.md`, one smoke test.
- [x] gdtoolkit installed, `.gdlintrc` with the project conventions.
- [x] `.github/workflows/ci.yml`: checkout, fetch Godot 4.7.2, import, lint,
      format check, run tests.
- [x] Dev harness `scenes/dev/playground.tscn`: empty floor, camera, loads in
      one command.

Verify: import, lint, tests and the smoke run all pass headless; CI is green
on the first push.

## M0: gray-box, camera, kart feel

Goal: drive a kart around Lucky Crossing and enjoy it. Everything here is a
gray box.

- [x] `ArenaLayout` resource and parser: grid validation, element positions,
      wall segment merging, symmetry check. `data/maps/lucky_crossing.tres`.
- [x] `ArenaBuilder`: floor, merged wall segments as StaticBody3D with box
      shapes and meshes, placeholder pads and zones as flat colored discs,
      spawn markers, pits as holes with a trigger, turbo pads with an arrow
      mesh and direction.
- [x] `KartStats` resource with every handling number from GAME.md 4.1;
      `data/kart/default.tres`.
- [x] `Kart` scene: CharacterBody3D, box collision, placeholder body and wheels
      tinted per slot, `KartMotor` implementing throttle, brake, reverse,
      speed-dependent yaw, grip model, drift entry and exit, exit boost, wall
      speed loss, kart bump response, turbo pad response.
- [x] `KartInput` base with fields for every action; `PlayerInput` reading the
      input map for one device.
- [x] `CameraRig`: fit the arena bounds at 55° pitch and 35° FOV, pan and zoom
      toward tracked karts within the limits in GAME.md 8.2, smoothing, a
      `shake(strength)` entry point.
- [x] Trails: tire mark ribbons per rear wheel with fade and a segment cap,
      exhaust smoke particles scaled by throttle with bursts on drift and boost.
- [x] Debug overlay on F3: speed, drift state, grip, arena crossing timer.
- [x] Optional tuning panel on F4 that edits the active `KartStats` live and
      can write it back to the resource.

Verify: tests for the layout parser, wall merging and the symmetry of the map;
tests for the motor's pure functions such as yaw rate by speed and drift entry.
Smoke run of the playground. Then a handling session with a gamepad and a
keyboard: crossing time close to 3.6 s, drift feels controllable, exit boost
noticeable. Expect two or three tuning rounds; write the final numbers into
GAME.md.

Status: built and checked headless (32 tests, smoke run, screenshot). The
handling session is still open: run `make dev`, F3 shows the readout, F4 the
tuning panel, and Save writes the numbers back to `data/kart/default.tres`.

## M1: combat

Goal: two karts on one machine can kill each other, and every death has a
clear cause.

- [x] `CannonStats` resource and `Cannon` component: cooldown, live bullet
      count, muzzle offset, forward-only fire; `data/cannons/default.tres`.
- [x] `Bullet`: sphere-cast stepping, one bounce with reflection, lifetime,
      owner slot, tint and trail, bullet against bullet cancel, aim assist
      steering inside the cone until the first bounce.
- [x] Kart death and respawn: `die(cause, killer_slot)`, 3 s delay, spawn point
      farthest from enemies, 2 s protection on the protected layer with firing
      disabled, own bullets deadly.
- [x] Crates: one hit destroys, respawn after 30 s, drops come in M2.
- [x] Pits: 0.4 s uncontrollable fall then death, last bump attribution within
      2 s.
- [x] Kart bumps with the bump rule; a `ramming` flag on the kart for Boost to
      set in M3.
- [x] `Match` skeleton: slot list, spawns karts, Playing state only, emits
      `kart_killed` and `kart_respawned`.
- [x] Minimal `InputRouter`: two devices, two slots, enough to test with two
      humans.

Verify: tests for reflection, aim assist cone and turn limit, spawn selection,
live bullet accounting. Smoke run with two karts driven by a scripted input
that drives and fires. A two-player session on one machine.

Status: built and checked headless, including an integration test in which a
bullet kills the kart ahead and the victim respawns protected. The two-player
session is still open: `tools/godot --path . res://scenes/dev/playground.tscn
++ --players=2` puts the keyboard on slot 0 and the first gamepad on slot 1.

## M2: economy

Goal: a complete solo match with a score, the Junction, the Jackpot, HUD and
tally.

- [x] `scoring.gd`: pure functions for pot value, death split, bank rate,
      amount banked over a time span in closed form, coins remaining after a
      drain, Jackpot collection over a span. Golden tests reproduce the tables
      in GAME.md 3.4 and 3.5.
- [x] `Pot` component: coins, mult, signals, reset.
- [x] Pickups: chip, gold chip, mult die, dropped chip with lifetime;
      `PickupArea` on the kart with the 0.9 m radius.
- [x] Coin pads with the weighted spawn table and 5 s respawn; crate drops.
- [x] `GrazeArea`: enemy bullets entering and leaving without a hit award +0.5
      with the cooldown.
- [x] `JunctionPad`: per-kart channel, drain per tick from the closed form,
      partial banking on leave, completion reset, Last Call doubling, progress
      ring.
- [x] `JackpotZone`: two zones, accrual and cap, single collector channel,
      contested pause, empty and switch, traffic light state.
- [x] Full death sequence from GAME.md 3.6 except item drops.
- [x] Match flow: countdown, timer, Last Call, target score, time out with
      unbanked pots lost, basic results screen, rematch.
- [x] HUD: player block with banked score and pot line, timer, standings
      strip, floating graze text, `TallyPopup` first version.

Verify: scoring tests including the timing tables, a drain simulation test
that ticks at 60 Hz and matches the closed form within one tick, a Jackpot
contested test. A 5 minute solo match end to end, headless smoke run of the
match scene, and a play session.

Status: built and checked headless. Scoring tests reproduce the GAME.md
tables; integration tests cover the countdown to results flow, banking at the
Junction, the death sequence, Jackpot collection and hand-over, coin pads and
grazing. The play session is still open.

## M3: items and jokers

Goal: power-ups and jokers work in a solo match, with drops and floor pickups.

- [x] `PowerUp` base resource, `ItemHolder` on the kart, power-up pads with the
      weighted table, roulette flicker, hold one rule.
- [x] First set: Boost with ram kills, Shield, Turret scene with owner
      attribution and lifetime, Ricochet Cannon as a `CannonStats` override for
      8 shots, Coin Magnet with attraction.
- [x] `Joker` base resource with the hooks listed in GAME.md 10.2,
      `JokerHolder` with per-holder instances, hook dispatch from Pot, Cannon,
      KartMotor, JunctionPad and the death sequence.
- [x] Respawn offer: 3 weighted offers without duplicates, pick or skip,
      respawn waits, swap when holding 5; `JokerPick` UI.
- [x] `JokerMenu` in the arena: cycle, drop to floor, destroy, kart stays
      controllable.
- [x] Death drops of a joker and the held item, floor pickups with 15 s
      lifetime.
- [x] The 20 jokers from GAME.md 7.3, one script and one `.tres` each.

Verify: a test per joker where the effect is numeric or rule based, offer
weighting and no-duplicate tests, power-up table weights. Play session.

Status: built and checked headless. Tests cover every power-up in the first
set, stat rebuilding, all twenty jokers' effects, offers with take, skip,
replace and the full-hand rule, floor drops and pickups. The play session is
still open.

## M4: bots and flow, first release

Goal: a complete single-player game against 3 bots, with menus, settings,
audio and art, published as a GitHub Release.

- [x] Grid pathfinding with AStarGrid2D, updated when crates die and respawn.
- [x] `BotBrain`: utility goals from GAME.md 9.1, path following, bullet dodge
      prediction, firing with lead, reaction delay and aim error, traits and
      difficulty resources, `BotInput`.
- [x] Title screen, lobby with options and color picking, countdown, control
      hints at match start, results with podium, settings with rebinding,
      audio, video and accessibility, persistence with ConfigFile.
- [x] `Audio` autoload with Master, Music and SFX buses; music loop and the
      sound set from GAME.md 8.4 from free sources, every file in
      `THIRD_PARTY.md`.
- [x] Art pass: kart model, blocks, chips, pad and zone visuals, palette,
      lighting, tally polish with flying chips and fanfare, camera shake.
- [x] Decoy Kart power-up once bots are stable, otherwise it slips to after
      the release.
- [x] `export_presets.cfg` for Linux, Windows and macOS, 4.7.2 templates
      installed, `.github/workflows/release.yml` building on tags and attaching
      the builds to a GitHub Release.
- [ ] Tag `v0.1.0`.

Verify: bot tests for goal selection with fixed inputs and for dodge
prediction; a full match against 3 bots on each difficulty; the performance
budget from GAME.md 10.1 checked with the profiler; export builds start on a
clean machine.

Status: built and checked headless. Bots, menus, settings, audio, the Kenney
kart model, the later power-up set and the export presets are in; `make
export` produces the three builds locally and the release workflow builds
them on a `v*` tag. Still open: the full match against bots on each
difficulty as a play session, the profiler pass, a clean-machine start of the
exports, and the `v0.1.0` tag itself, which is the user's call.

## M5: local multiplayer

- [x] Full `InputRouter`: join in the lobby and mid-match by pressing a button
      on an unused device, keyboard and mouse as one device, bot takeover on
      join, hand back on leave.
- [x] Four HUD blocks in the corners, joker pick inside the owner's block,
      pause freezing the match for everyone.
- [x] Camera pan toward the centroid of all karts.

Verify: four devices on one machine, join and leave during a match.

Status: built and checked headless. Tests cover lobby joining and color
cycling, colors reaching karts, mid-match takeover of a bot with the
any-device player settling on a device, fresh slots when no bot is free,
and handing a kart back to a bot. The four-device session is still open.

## M6: online multiplayer

- [x] Host and join screens with IP and port, ENet peer.
- [x] Replication by 30 Hz state snapshots instead of MultiplayerSpawner and
      MultiplayerSynchronizer: the host serializes karts, bullets, pickups,
      turrets, zones, slots and offers; clients render puppets and dead-reckon
      bullets. Chosen because every gameplay node is built in code.
- [x] `NetInput`: clients send input state per tick by unreliable ordered RPC;
      the host simulates, decides hits, pickups, banking and scoring, and
      relays gameplay events for HUD and audio.
- [x] Bots on the host, no pause, mid-match join by the local rule.
- [ ] Prediction and reconciliation for the local kart if latency tests call
      for it.

Verify: two machines on a LAN, then a WAN test over a direct IP.

Status: built and checked in one process with two multiplayer instances: a
client joins, takes over a bot, drives it on the host, sees the puppets follow,
and the kart goes back to a bot when the client leaves. The LAN and WAN
sessions are still open. Prediction is not implemented; the client feels its
own latency.

## M7: dedicated server

- [x] A host with nobody at it: the waiting room and the arena hosted with no
      seat, HUD or say in pausing at the host, and four clients seated in it.
- [x] The host's say over the wire, `HostControls`: the first player seated has
      it and it passes to whoever has been in longest; the match plan, the door,
      kicks, Pause game and where the room goes, each checked at the server.
- [x] The server, `--server`: a hall on 7777 listing its games, each game a
      headless process of its own on the next port, reporting to the hall over
      loopback, and one log for all of it.
- [x] An idle server near the engine's own footprint: the hall started without
      the game's autoloads by `GameTree`, behind a boot scene, at ten frames a
      second with no physics; about 90 MB in a release build.
- [x] Play Online in two screens, connecting and then the server's games, and a
      LAN game and a server telling each other apart at the door on 7777.
- [x] Make host in Manage players, handing the say to another player.
- [ ] Finding servers without typing an address, and join codes.

Verify: `make server-check`, then a server on a machine of its own reached over
the internet.

Status: built and checked on one machine: suites for the hall, a game's
process, the host's say and both screens, and `tools/server_check` with a real
server and three clients making, joining and watching a game, handing the say
on, and holding the idle server under 160 MB (the editor build's is 110). Also
run against the Linux release export as the server. Not yet tried over the
internet, or with a server full of games at once.

## M8: the story

STORY.md is the design of the story and GAME.md 8.7 says where it reaches the game; this is the
order of work to build it, every detail of STORY.md as a task, ticked off as it lands so the work can
stop and pick up again anywhere. A task names the STORY.md section it builds, in brackets, and the
files it touches as far as they are known before the work starts. When building a task changes what
the story says, STORY.md changes first, then GAME.md where the story reaches it, then the code.

Spoilers throughout, like STORY.md.

### Progress

| Phase | What | State |
|---|---|---|
| S0 | Story state, the clock and the switch | Done |
| S1 | Every line in one place, and the placeholders | Done |
| S2 | The hoardings, the posters and the road | Done |
| S3 | The payout slip | Done |
| S4 | Jokers: the pick's line and the terms | Done |
| S5 | Microprint, loading, statistics and About | Done |
| S6 | The driving school | Done |
| S7 | The rooms and the crowd | Done |
| S8 | Notes on the table | Done |
| S9 | The folder and the notes' pages | Done |
| S10 | The Count Room and House Rules | Done |
| S11 | The Final Hand | Done |
| S12 | After the ending | Done |
| S13 | Wrapping up | Done, but for the user's play-through |
| S14 | The first look, the user's notes | Done |
| S15 | The second look, the user's notes | Done |
| S16 | The third look, the user's notes | Done |
| S17 | The fourth look, the user's notes | Done |
| S18 | The fifth look, the user's notes | Done |
| S19 | The sixth look, the user's notes | Done |
| S20 | The seventh look, the user's notes | Done |
| S21 | The eighth look, the user's notes | Done |

Next up: the user's look at S21, then their play-through, S13's last task, and tuning the pace of
S0 after it. The phases are in the order they are best built, each standing on its own:
after S0 to S7 the story's margins are all in the game and could ship, the notes and the ending
after them. S10 can be built alongside anything before S11, which needs it. On picking the work up
again: this table, then the first unticked task of the phase in progress, then that task's sections
of STORY.md.

### Decisions fixed for implementation

These refine STORY.md without changing it.

- **One stage for a screen.** `Story.stage_here()` is the stage every surface at this machine shows:
  the profile playing's stage, or 0 when that profile has no license, has the story switched off, or
  the game is headless. Surfaces ask it as they are built; nothing listens for it changing, so a
  stage reached mid-match shows from the next room on.
- **Every line in one place.** All the story's words live in `scripts/story/story_lines.gd`, one
  constant per surface keyed by stage, and the notes' in `scripts/story/story_notes.gd`. No line of
  the story is written anywhere else, so it can be read and edited as a story.
- **A line holds until a later stage changes it.** `StoryLines.at(table, stage)` returns the entry
  for the highest stage at or under the one asked for, as STORY.md 6 reads.
- **The numbers are constants, together.** Stage starts, the Final Hand, the notes' spacing and every
  other number of the clock live at the top of `scripts/story/story.gd`, in seconds, so the pace is
  tuned in one place [5.1].
- **Never over the wire.** No story state, line or note goes into a snapshot, a plan or any message.
  A test holds it: no network payload has a key starting `story`.
- **Never headless.** A headless run shows stage 0, deals no notes and writes nothing, the way
  `MatchRecord` already writes no statistics headless, so tests and the dedicated server never touch
  a player's story. Tests that need a stage set it through `Story.override`.
- **The profile keeps it.** A `[story]` section in the profile's file, written by `Profile`; nothing
  in the machine's settings. Every profile is reset once by hand when the story ships, so no reading
  of older files is needed beyond the section being absent.
- **House Rules is a map like any other on the wire.** Its id goes on the end of `ArenaMaps.IDS`, so
  every machine has it and a client loads it when told to. Which maps a lobby offers is the only
  thing the story gates: a profile that has played the Final Hand sees House Rules in the quick
  match's list, and no Grand Prix ever deals it.
- **Notes are this machine's.** A note is a node only the machine that dealt it has, outside the
  pickups the host syncs, and only this machine's human karts can take it. Whichever seat here
  takes it, it is filed for the profile playing [5.2].
- **American English, the House's capitals.** House lines in capitals as STORY.md writes them, the
  game's own lines in the game's case, every line spelled as STORY.md spells it.

### S0: story state, the clock and the switch [5]

- [x] `scripts/story/story.gd`, `class_name Story`: the constants of 5.1 in seconds, stages starting
      at 0, 600, 2400, 4500 and 6600, the Final Hand at 9600; stage names Customer, Player,
      Participant, Number, Candidate, Operator; `stage_of(profile)`, `shown_of(profile)`,
      `stage_here()`, `on_here()`, `final_hand_due(profile)`, `minutes(profile)`, and `override`
      for tests and the command line.
- [x] `Profile.story`, a `StoryState` (`scripts/story/story_state.gd`) kept in a `[story]` section
      of the profile's file, loaded and saved with the rest: `on` (true), `seconds` (the clock),
      `maps`, `deaths`, `jokers` (counted only once licensed, for `{maps}`, `{hands}` and
      `{accepted}`), `quick_matches` (for the first note), `notes` and `notes_read` (numbers, for
      the New mark of S9), `note_waits` (the notes' schedule of S8), `final_hand` (the date the stamp
      came down, empty before), `final_seconds`, `shifts` (maps since), and `evaluation` (what the
      folder keeps of it, S11).
- [x] The clock runs in `MatchRecord` through `Story.count`: a room that counts as a map (`maps`)
      adds its `seconds`, the match clock's own time, to the clock of every profile at this machine
      it writes for, whistled or left, the first seat's and a linked seat's alike, never a guest's.
      Only for a profile with a license and the story on. The driving school and the waiting room
      run no clock, being no maps, and the Garage has no record at all.
- [x] The counters with it: `maps` for a map played to the whistle, `deaths` and `jokers` from the
      slot's statistics past what was already counted, as `LifetimeStats.add_play` counts them, only
      once licensed; `quick_matches` for a map that was no Grand Prix's; `shifts` for a map played
      after the stamp.
- [x] The switch [5.4]: on the License tab of the settings (`scenes/ui/license_tab.gd`), under the
      license or the word on where to get one, a switch of the house's, Story, for the profile
      playing, over "The small print, the notes, and where they lead.". Off stops the clock and the
      counters and makes `stage_here()` 0; on picks everything up where it was. In a room it can be
      switched too, and what is already printed there stays until the next room; it is kept as the
      settings are left.
- [x] Off, everything is the casino of stage 0, after the ending too: Play reads Play, the license is
      the Department's, no green line, the seal's print as it is, no folder, no flyer, no notes, no
      Final Hand. Each phase below checks its surface against the switch; ticked when the last has.
- [x] Debug builds only: `++ --story-stage=N` shows stage N without saving anything,
      `++ --story-final-hand` deals the Final Hand on the next Play, and `++ --story-note=N` lies
      note N on the next map's floor at once (`Story.read_arguments`, called from
      `scripts/autoload/game.gd`; the last two are read by S8 and S11). S7 added
      `++ --story-clock=SECONDS`, the clock read as that for what moves with it, and after S13
      `++ --story-license` licenses the profile playing at once and keeps it, in its first seat's
      name or a picked one, so a new profile can try the others (`Story.hand_license`), and
      `++ --story-notes` hands it every note, new, licensing it first (`Story.hand_notes`).
- [x] The F3 overlay (`scenes/dev/debug_overlay.gd`) shows the stage, the clock in minutes, how many
      notes are found and whether the Final Hand is due (`Story.debug_text`); S8 adds the next note.

Verify: `tests/test_story_clock.gd`: the stage at every boundary; a 1 minute map moves the clock a
fifth of a 5 minute one; nothing before the license; a linked seat's profile runs its own clock and a
guest's nothing; the switch stops it and starting again resumes it; headless writes nothing; the
section is absent from a fresh profile and round-trips through the file.

Status: built. `tests/test_story_clock.gd`, 7 tests: the stages at their boundaries, maps running
the clock by their own time, shifts, the screen's stage and the switch, the License tab's switch,
the profile's file, and a map at this machine running the profile playing's clock while a lobby runs
none. Linked seats go through `MatchRecord.profile_for` as statistics always have.

### S1: every line in one place, and the placeholders [6]

- [x] `scripts/story/story_lines.gd`, `class_name StoryLines`, with every table of STORY.md 6 as it
      is written there: the hoardings by stage and the Final Hand's [6.1], the posters [6.1], the
      road [6.1], the small print [6.2], the bulletins [6.2], the classification [6.2], the pick's
      line [6.3], the joker terms by joker id [6.3], the HUD's and the title's microprint [6.4], the
      loading line [6.5], the Statistics line [6.6], the Highway Code's edition and its revised
      lines [6.7], the Yard's sign [6.8], and the title's after the ending [8.6]; and the Final
      Hand's words with them, the flyer, the pane, the evaluation, the stamp and the last lines [8],
      the license after the ending [8.6] and About's sentence [3.11].
- [x] `StoryLines.at(table, stage)`: the line for the highest stage at or under `stage`, and
      `StoryLines.revise_code(text, stage)` for the Highway Code's revised lines.
- [x] `scripts/story/story_fill.gd`, `class_name StoryFill`: fills `{name}`, `{license}`,
      `{minutes}`, `{maps}`, `{hands}`, `{accepted}`, `{deaths}`, `{chips_lost}`, `{drifted_km}`,
      `{trait}`, `{shifts}`, `{place}`, `{models}`, `{deviation}` and `{date}` [6] from a profile and,
      where it has one, a match. `{date}` the way `LicenseCard.today()` writes it, `{drifted_km}` as
      the Statistics page writes kilometers, every count with thousands separated as the House prints
      them (1,204,388), a place as 1ST, 2ND and on, LEARNER for a license not yet earned. `{name}` is
      in capitals in a line the House prints in capitals and as written in any other, so the Final
      Hand's models are Ann 2 rather than ANN 2.

Verify: `tests/test_story_lines.gd`: every table answers for every stage 0 to 5; every placeholder
in every line fills; no House line contains NOTE; every joker in `data/jokers/catalog.tres` has a
term, so a joker added without one fails [6.3]; note 12's numbers equal the trait weights of
`data/ai/traits.tres` [7.3].

Status: built. `tests/test_story_lines.gd`, 7 tests: every table from the stage it begins at, every
placeholder filled, the name's case, no House line speaking of a note, a folder or Kit (taking notes
the way a House watches is allowed), every joker's term, the Code's revisions, and numbers and
places. Note 12's numbers are checked with the notes, S8.

### S2: the hoardings, the posters and the road [6.1]

- [x] The hoardings (`scenes/arena/billboard.gd`, `arena.gd` `_add_billboards`, `StoryBoards` in
      `scripts/story/story_boards.gd`): `Billboard.ADS` stays as stage 0's. A room draws one board
      from the newest stage reached and one from every stage reached, stage 0's included, never the
      same line twice, and at most one line with `{name}` in it, filled in for the profile playing.
      The Final Hand's two are fixed, FINAL HAND over GOOD LUCK, CANDIDATE and NOW HIRING over ONE
      POSITION, when `Arena.final_hand` is set (S11 sets it). A filled-in name too long for its
      board is drawn smaller, as now.
- [x] Stage 5's JACKPOT JUNCTION over GO ROUND AGAIN is a stage 5 line like the others, not a
      replacement for stage 0's JACKPOT over JUNCTION.
- [x] Posters (`scenes/story/story_dressing.gd`, `StoryDressing`, the node the arena adds after its
      props in every room a match is played in): pinned with two red pins on the board at the back
      of the bench across from the calendar; lit, a sign of the house's stock with its words in
      foil, on the card room's far wall in front of the drape and high enough over the table to be
      seen as the camera pulls out (the pictures' own height is under the table's edge); pasted
      across two panels of the Yard's hoarding beside the hard hat. One big line and a small one
      under it, by stage. Kept out of the bake. The Count Room's monitor is S10.
- [x] The road: one word in a box, in the road markings' paint, the letters stretched along the
      camera's line of sight, on every map a match is played on, the XL maps included: KEEP CLEAR,
      KEEP PLAYING from stage 2, HUMANS ONLY from stage 4, STAFF ONLY after the ending. Its place is
      found from the map's grid (`StoryDressing.road_spot`): six cells across and two deep, bare
      floor under all of it and no pit, Junction, Jackpot, gate or portal beside it, as near the
      near side as it fits with its bottom row kept off the near wall where it can be, and as near
      the middle as it goes. Eight across did not fit Lucky Crossing once the eight-player spawns
      stood in its near row, and a lane's depth of letters was too small to read pulled out. Flat on
      the floor, no collision. Not in the Garage, the waiting room or the school.
- [x] Switched off or unlicensed: stage 0's boards, PLAY RESPONSIBLY, KEEP CLEAR, since
      `Story.stage_here()` is 0 then.

Verify: `tests/test_story_boards.gd`: the draw rule per stage, one name line at most, the Final
Hand's pair; the road's box lies clear of every element on every map; every poster and road word
fits. Screenshots of each room at stages 0, 2, 4 and 5 with `--story-stage`, looked at for whether
the words read at the camera's distance and at the whistle's pull-out.

Status: built. `tests/test_story_boards.gd`, 4 tests: the draw over 200 seeds at every stage and the
Final Hand's pair, the road's place on all six maps, the rooms dressed for their stage and the
Garage and lobby not at all, and the hoardings carrying the stage's lines filled in. Screenshots
taken in the Workbench at stages 2 and 4, The Vault at 3 and the Yard at 5: the road's word reads
across the table, the posters read pulled out. `test_billboards`, `test_grand_prix` and `test_bake`
pass.

### S3: the payout slip [6.2]

- [x] The small print (`scenes/ui/results_screen.gd`, `SMALL_PRINT` is stage 0's) by stage, filled
      in, through `StorySlip` (`scripts/story/story_slip.gd`), which keeps the slip's story out of
      the screen's own code.
- [x] The bulletin: from stage 2, one line under the small print, drawn once a slip from the stage
      reached's pool with the player's own numbers, so a podium filled in again keeps it; a line
      naming a trait is drawn only when a bot of that trait sat at this table, and names one that
      did; never the same bulletin twice in a row.
- [x] The classification: `StorySlip.classify`, the trait the match's numbers come closest to, per
      minute of the match: kills to Hunter, rams to Bumper, grazes to Grazer, big cash-outs and
      Jackpot chips to Greedy, frequent small cash-outs with few deaths to Cautious, Balanced when
      nothing leans past a full lean. From stage 3, one line of microprint under the line of every
      human player at this machine on the slip, CLASSIFIED: {trait} · PROFILE UPDATED; bots and
      other machines' players get none.
- [x] The heading reads Payslip wherever the slip says Payout slip, once the profile playing is the
      Operator; a Grand Prix's run standings keep their own heading.
- [x] The Final Hand's evaluation goes on the slip in S11.

Verify: `tests/test_story_slip.gd`: the small print and the heading per stage; a bulletin's trait
was at the table; the classifier on made-up statistics, one per trait and a Balanced; everything fits
a phone's slip at the biggest UI scale, scrolling as the slip does.

Status: built, the evaluation waiting on S11. `tests/test_story_slip.gd`, 4 tests: small print and
heading by stage, the bulletin's traits and no repeats, the classifier, and a real slip carrying the
small print, a bulletin, one classification under the one human line, and Payslip after the ending.
`test_results_screen` passes. A slip at stage 3 looked at: the classification sits under the
player's awards in microprint and the small print fits beside the barcode. `trait` is a reserved
word in Godot 4.7, so no variable may be called that.

### S4: jokers, the pick's line and the terms [6.3]

- [x] The pick (`scenes/ui/joker_picker.gd`): from stage 1 a line of the house's small print under
      the cards, in its foil microprint in the gap the pane leaves under the row, by stage, filled
      in, CANDIDATE TERMS at the Final Hand (`Story.final_hand_on`, set by S11), STAFF TERMS after
      the ending; the Grand Prix's keep pick and the driving school's picks the same as any.
- [x] TERMS ACCEPTED: from stage 2, the moment a card is taken, the pick leaves a line saying TERMS
      ACCEPTED where its line was, hung off what holds the pick since the pick goes at once, for
      0.55 s as the card flies into the hand, fading over 0.35 s. A skip or a destroy says nothing.
      On a touch screen as on any other.
- [x] The terms (`scenes/ui/joker_detail.gd`): from stage 2, one line under the card's effect
      wherever the pane describes a card, the hand, the pick and the floor, from the table keyed by
      joker id, in the pane's gray. Wrapped at the pane's width; the effect above it never changes.

Verify: `tests/test_story_jokers.gd`: the line per stage and at the Final Hand; TERMS ACCEPTED on a
take and nothing on a skip or a destroy; every catalog joker's term fits one line of the pane at the
smallest width.

Status: built. `tests/test_story_jokers.gd`, 3 tests: the line by stage and at the Final Hand, a
card's term from the second stage, and TERMS ACCEPTED left by a take and gone after, and nothing for
a skip or a take at the first stage. A pick at stage 3 looked at: the line sits in foil under the
row and the term in gray under the effect. `test_jokers`, `test_joker_menu`, `test_mouse_jokers`,
`test_touch`, `test_hand_corners`, `test_joker_stacks` and `test_control_hints` pass.

### S5: microprint, loading, statistics and About [6.4, 6.5, 6.6, 3.11]

- [x] The HUD's corner blocks (`scenes/ui/hud_block.gd`, `MICRO` is stage 0's) by stage, SEAT n kept
      at the front, every block at this screen from the profile playing's stage.
- [x] The title's microprint (`scenes/ui/title.gd`, `MICROPRINT` is stage 0's) by stage.
- [x] The loading line (`scenes/ui/loading_screen.gd`, `LoadingScreen.building`) by stage, for maps
      and the rooms between them alike; at the Final Hand, when the arena is `final_hand`, the
      heading is FINAL HAND with the room's name under it, and the line Setting the final table.
- [x] The Statistics page (`scenes/ui/stats_tab.gd`): from stage 2 a line under its title, by stage;
      after the ending a Shifts row under Games, the profile's `story.shifts`. Notes are never
      counted on it.
- [x] About (`scenes/ui/about_tab.gd`): the last sentence is now "A human oversaw it: played it as
      it grew, made the calls no model would have made, and put their name on it.", for
      everybody, story on or off, and GAME.md 8.5 says it as it is.

Verify: the HUD, loading and Statistics tests extended for a stage each; `tests/test_about.gd` for the
new sentence; microprint at every UI scale.

Status: built. `tests/test_story_margins.gd`, 4 tests: the corner blocks' microprint by stage, the
loading line by stage and the Final Hand's, the Statistics page's line and Shifts row, and About's
sentence. `test_about`, `test_stats`, `test_profiles`, `test_flow`, `test_driving_school` and
`test_tutorial_rooms` pass.

### S6: the driving school [6.7]

- [x] Enroll (`scenes/tutorial/school/school_enrollment.gd`): under the big button, always, "Enrolling
      accepts the terms of the Dept. of Karts.", in the school's small print.
- [x] The edition (`scenes/tutorial/school/theory_text.gd`, `EDITION`): the 212th at stage 0, the
      213th to the 216th at stages 1 to 4, the 217th "approved by {name}" after the ending, on the
      title page; the running head, the front cover and the back's blurb count along with it; the
      back's price stays 212 chips.
- [x] The revised lines of the Code by stage, the seven of STORY.md 6.7, the roundabout's caption
      among them, and the colophon. The book lays its pages out from the text it is given, so a
      revised line moves nothing else; checked that no chapter heading lands at a page's foot.
- [x] After the ending: the examiner's signature on the back of a license issued or retaken is the
      holder's own name in the examiner's hand (`scenes/tutorial/school/license_card.gd`), and the
      examiner's booth over the last room (`school_props.gd`) has a figure standing at its lit
      window, built as the inspectors are.
- [x] The inspectors are left alone.

Verify: `tests/test_driving_school.gd` extended: the enrollment line; the edition and each revised
line at its stage; the book still turns to the 212th page at every stage.

Status: built. `tests/test_story_school.gd`, 4 tests: the line under Enroll; the edition, its mark
and the blurb by stage with the price unchanged, and each revised line before and from its stage;
the book at the last stage cut into pages with no heading at a foot and the read ending on its last
page; and after the ending the holder signing as examiner and somebody at the booth's window, nobody
before. Looked at: the line under Enroll, the title page's 217th edition, and the figure at the
booth, a suit and a head on the sill against the lit glass. `test_driving_school`, `test_tutorial`,
`test_tutorial_rooms` and `test_profiles` pass.

### S7: the rooms and the crowd [6.8, 6.9]

- [x] The Yard's sign (`room_shell.gd` `sign`): lettered on the lit board, LOADING BAY 4, AUTOMATED
      LOADING from stage 2, CREW REQUIRED: 0 from stage 4, UNDER NEW MANAGEMENT after the ending; in
      the sign's own light, legible when the camera pulls out at the whistle.
- [x] The Workbench's calendar (`room_shell.gd` `calendar`): a month's grid of days on its page; from
      stage 2 one day ringed in red, Kit's last day; once the last note is found, turned over: the
      next month's page, no ring.
- [x] After Hours' pictures (`room_shell.gd` `pictures`): dark until the ending; after it the left
      frame holds the player's kart as the license photo shows it, rendered once as the room goes up
      rather than every frame, over a small plate reading EMPLOYEE OF THE MONTH; the right stays
      dark.
- [x] The Yard's hard hat stays exactly where it is at every stage.
- [x] The crowd in step (`scenes/arena/crowd.gd` and its shaders): from stage 4 the spread of each
      figure's rolled point in the beat narrows with the clock, from all of it at the stage's start
      to none by the Final Hand, one uniform on the shader, so the house bobs and jumps as one.
- [x] The crowd at the Final Hand: every figure stops dancing, turns to face the candidate's kart and
      follows it round the table, the way `SchoolInspectors` follows a learner, turning in the
      vertex shader toward a point the room sets each frame; still until the whistle, then all
      applauding together. Crowd Half or Off as the setting says.

Verify: screenshots of the sign, the calendar and the frame at their stages; the crowd's spread at
stage 3, mid-stage 4 and at the Final Hand; `make bench` unchanged with the crowd in step.

Status: built. The shell only says where its sign, calendar and pictures are; `StoryDressing` puts
the words, the days and the picture on them in match rooms, and sets the crowd's spread as the room
goes up, from `Story.crowd_spread` and the clock (`++ --story-clock=SECONDS` in a debug build). The
pictures were hung on the wall behind the drape's folds and over the top of the picture, where nobody
ever saw them; they now hang in front of the drape either side of the House's poster, for everybody.
The figures are round, so turning to face the kart is a lean toward it, `Crowd.watch(kart)`, and the
whistle is `Crowd.applaud()`: both are S11's to call. `tests/test_story_rooms.gd`, 5 tests: the
sign at each stage and none in the Garage, the calendar's month, ring and turned page, the picture
and its plate only after the ending, the spread by stage and clock and on a room's crowd, and the
watch and the applause. Looked at: the sign at stages 0 and 5, the ringed calendar, the kart in its
frame, and the house leaning in toward a kart against one standing upright; a still cannot show a
house in step, which the test holds instead. The bench, warmed up, is 139, 137 and 138 fps on
Lucky Crossing, the Vault and Crossfire with the crowd's new shader and with the old.
`test_crowd`, `test_bake`, `test_room_kit`, `test_room_props`, `test_story_boards`,
`test_billboards`, `test_grand_prix`, `test_video_settings` and `test_waiting_room` pass.

### S8: notes on the table [7.1, 5.2]

- [x] The schedule, `scripts/story/story_notes.gd` with the texts of S9: the first note is due in the
      second quick match the profile plays after its license, never a Grand Prix map. After it, a
      stage's notes are spread across it, the i-th of k due at the stage's start plus i/k of its
      length; after the ending one every ten minutes of the clock. A note is never due before the one
      before it is found; they come in order.
- [x] Turning up: in a map a note is due for, an even chance; certain once it has been due for two
      maps without turning up; never more than one a match. At a moment drawn at random between
      twenty seconds in and a minute before the clock runs out, never at the countdown and never in
      overtime; a match ended early by the target before that moment simply had no note.
- [x] Missed: a note that turned up and was not taken is due again in a later map, as often as it
      takes.
- [x] Note 21 on the Final Hand's floor whatever the order, S11; missed, it is due again after the
      ending, before note 22.
- [x] Only in maps, quick or Grand Prix, offline or online, never in the Garage, the waiting room,
      the driving school or a Grand Prix's party. Never with the story off, never before the license,
      never headless.
- [x] Where: open floor from the arena's grid, not on a pad, the Junction, a Jackpot, near a pit or
      beside a spawn, somewhere a kart can drive to.
- [x] `scenes/story/story_note.gd`: a folded scrap lying flat among the litter, each room's paper,
      graph paper on the Workbench, a cocktail napkin After Hours, a page off a clipboard in the
      Yard, a strip of printout in the Count Room, where it is the only thing on the floor. A glint
      runs across it every few seconds, faint enough to pass for the light. Appearing, it is simply
      there: no sound, no light, no ring.
- [x] Taking it: this machine's human karts only, never a bot, a decoy or a dummy, at the radius a
      chip is taken at, unmoved by magnets, Chip Magnet and Magnet Hubcaps alike, by bombs or by
      anything else; bullets pass over it and aim assist never turns toward it. A soft rustle, the
      paper folds into that player's corner, and a torn scrap there says NOTE COLLECTED in pencil
      for two seconds: not on the house's tag, the one thing on the HUD the house did not print. It
      never says which or how many.
- [x] Filing: into the profile playing's notes at once, unread, whichever seat here took it, and
      saved there and then, so a game closed straight after keeps it. Whether linked profiles move
      on through the notes as well is open, STORY.md 13; build it so the filing is one function a
      later answer can change, and nothing else assumes one profile.
- [x] The house never knows: no line of the house's mentions a note, the Statistics page counts
      none, the evaluation counts none.

Verify: `tests/test_story_notes.gd`: the first note's quick match; spacing per stage; the even
chance, the certainty after two, the window inside the clock; order kept; a missed note again; note
21's exception; never on a pad or near a pit on every map; a bot driving over one leaves it; a
client's note exists on the client alone and no snapshot mentions it.

Status: built. `StoryNotes` keeps the schedule, its numbers beside the stages' in `Story`;
`NoteDealer`, added beside `MatchRecord` by the match scene and by the playground for
`++ --story-note=N`, decides as the flag drops, lays the `StoryNote` on the arena outside its
pickups, and files a take through `StoryNotes.file`, the one place a note is filed. A dealer made
with a note, `NoteDealer.add_to(match, 21)`, is how S11 deals the Final Hand's. Kept off any cell
beside a wall too, so a note is never hidden under the near wall. The scrap in the corner is
`NoteCollected`, in the license's handwriting font, beside the corner's block toward the middle of
the screen, clear of the control hints under it. The F3 line gives the next note and when it falls
due. `tests/test_story_notes.gd`, 5 tests: the first note's quick match, the spacing, order and the
Final Hand's exception, the even chance, the certainty after two and the window, a spot on every
map, and a live match in which a bot drives over the note and leaves it and the player takes it,
the note never a pickup and the floor the host sends never mentioning it. Looked at: the graph
paper, the napkin and the clipboard page, each glinting, the note from the match's camera, and the
scrap in the corner. `test_flow`, `test_online`, `test_online_sync`, `test_play_online`,
`test_online_protocol` and `test_kart_sound_wiring` pass.

### S9: the folder and the notes' pages [7.2, 7.3]

- [x] To start with, a plain Notes button on the title under the Garage, there once a note has been
      found, opening the folder.
- [x] Then the folder itself: a manila folder peeking in from the title's left edge as the license
      peeks from the right (`LicenseView`, `TiltedCard`), dog-eared, nothing printed on it, sliding
      out under the cursor and opening on a click or a tap; the menu's cursor reaches it from the
      buttons, and a pad opens it from there. Not house print: no foil, no engraving, no notches.
      Once it is in, the Notes button goes.
- [x] Inside: the notes found, in STORY.md 7.3's order rather than the order found, one to a page,
      turned the way the Highway Code's pages turn (`scenes/tutorial/school/page_turn.gdshader`),
      each with its title; no numbers and no empty pages. Back or Put it away closes it, on every
      device.
- [x] Each of the 26 notes drawn as STORY.md 7.3 describes it, in code like every picture in the
      game: the till receipt, graph paper with Kit's sketch, the Department's form filled in by hand
      and stamped RECEIVED, the torn flyer, the rota, the napkin, the terms pamphlet with Kit's
      pencil by clause 4, the yellowed first edition with Kit's margin, the clipboard report, the
      memos, the envelope, the statement roll, the blueprint (white lines on blue: the highway, the
      slip road, the roundabout round the pot, the title block with an inked signature and the
      Department's stamp), the organization chart, the form letter, the torn strip, the duties card,
      the staff record with one line struck through by hand, Kit's last letter and the calendar page.
- [x] Hands and faces: Kit's hand and the players' in a handwriting face (Homemade Apple, which the
      license already carries, or another kept in THIRD_PARTY.md), the House's documents in a
      receipt's monospace, the first edition in an old book face; any new face logged in
      THIRD_PARTY.md in the commit that adds it.
- [x] Placeholders filled as a page is read: the form letter's name and number, the terms
      pamphlet's count, the approvals' operator.
- [x] After the ending, at the back: the Final Hand's slip with its evaluation as it was stamped, from
      what the profile kept of it, and the card of Terms Accepted, S11. The folder never gains a
      stamp or a word of the house's.
- [x] New [7.2]: a note found but not yet read is new. A page counts as read once it has been open
      for a second, written into `story_notes_read` and saved then. While any note is new: on the
      title, a corner of the first new note's own paper sticks up out of the folder's top edge with
      an exclamation mark in pencil on it, and while the Notes button stands in for the folder the
      same pencil mark follows its word; inside, the folder opens at the first new note rather than
      the first page, and a new page carries the pencil mark in its top corner until it is read.
      Nothing counts the new notes or shows how many. The mark is drawn in the notes' pencil, never
      in the house's print, and holds still for fewer flashes.
- [x] After a map, offline [7.2]: when a note was taken in a map played on this machine alone, the
      folder peeks in from the left edge beside the payout slip with its mark, and opens over the
      slip on a click or a tap or on the button that opens the hand of jokers, drawn beside it for
      the device last touched, as the title opens the license. Put away, the slip is as it was, its
      cursor where it was, and the ways on still work. Between the maps of a Grand Prix too. Never
      online, hosting or joined, and never on the Final Hand's slip, whose note is read after the
      ending.

Verify: every page fits a phone held sideways at the biggest UI scale; the folder opens with a
mouse, a pad, a keyboard and a finger; screenshots of every page. `tests/test_story_folder.gd`: a
note taken is new until its page has been open a second; the corner and the button's mark come and
go with the new notes; the folder opens at the first new page; the folder beside the slip after an
offline map with a note in it, and not after one without, online, or at the Final Hand.

Status: built, but for the back of the folder, which waits for S11 to make what goes there. The
interim Notes button was skipped: the folder went in straight away. `StoryNotes.NOTES` holds every
note's title, paper and words, STORY.md's lines as written, dotted leaders laid out to the paper's
width; `NotePage` draws a page and `NotePaper` the papers, the clip, the stamps, Kit's sketch and
the blueprint. The House's paperwork is set in Courier Prime and the first edition in IM FELL
English, both new under the Open Font License, in THIRD_PARTY.md and the credits; every hand is
Homemade Apple, a letter at a time, wandering as much as the hand shakes, the mirror's gone over
twice, and note 21's first word torn through. Note 24's struck line is its prediction accuracy,
now said in STORY.md. `NotesFolder` is the open folder, `FolderPeek` the folder on the title and
`SlipFolder` the one beside the slip, put there by the dealer when a note is taken offline. The
arrows under the folder take a click or a tap, left and right turn it from a pad or the keys, a
click on a page turns it, and the cursor stays on Put it away. `tests/test_story_folder.gd`, 3
tests: the order, the first new page, a page read after a second and its mark gone, the turns and
their ends; the title's folder with its corner, reached going left from Play, the corner gone once
read; the folder up with the slip and opening over it, and none at the Final Hand. Online is held
by `SlipFolder.add_to` asking `Net.online()`. Looked at: all 26 pages, the title with the folder
peeking in, the folder open at its first new page, a leaf standing at the spine mid-turn, the
folder beside the slip with the hand's button, and the folder at UI scale 2.

### S10: the Count Room and House Rules [3.9, 8.2; GAME.md 6.3, 8.1]

- [x] `data/rooms/count_room.tres`, a `RoomLook` with id `count_room`: no sun, a hard green key off
      the racks and a terminal's green for the neon and the trim, the felt a dark gray-green, fog
      thin and green; bloom on the green as After Hours has it on its neon, within the frame budget
      of GAME.md 8.1.
- [x] Its shell and props (`room_props.gd`, `room_shell.gd`): a raised floor of square tiles; server
      racks in rows with lights winking, animated in a shader rather than per light; cable trays
      overhead; monitors scrolling numbers nobody reads, in a shader; everything exactly on the grid
      and square to the table, nothing a degree off, nothing stacked by hand, and no litter at all.
- [x] In the arena: walls as racks, their capping strip lit; breakable boxes as stacks of drives;
      the Junction painted as a processor seen from above, a square of gold pins round a die, the
      bank ring the same neon ring as every room's; the pits as lifted floor tiles with cable at the
      bottom; the Jackpot tiles as memory banks; the turbo pads as cooling vents. Looks only: every
      element plays as it does everywhere.
- [x] The crowd: exact rows, every figure the same height, no tribune, all undressed in one plain
      gray, no rolled faces or wardrobe; the booth a console with nobody at it; the disco rig green
      only.
- [x] The poster is a monitor on a rack reading HUMAN OVERSIGHT: 0 over a blinking cursor.
- [x] `data/maps/house_rules.tres` from the grid in GAME.md 6.3, naming the Count Room;
      `ArenaMaps` gains `house_rules`, "House Rules", on the end of its lists.
- [x] The lobby's map list (`scenes/ui/match_options.gd`) offers House Rules only to a profile
      playing that has played the Final Hand, offline or hosting; `GrandPrix.deal` never deals it.
      A client loads it whenever its host picks it.
- [x] The shader warm-up of GAME.md 10.7 includes the room's materials and shaders, so the Final
      Hand never hitches on its first frame.

Verify: `make bots` on House Rules: the bots reach both Jackpots in the rack aisles, bank, and stay
out of the lifted tiles; `make bench` holds the frame rate on it; screenshots of the room at the
whistle and from the loading screen; a test that the map is in no Grand Prix deal and in a quick
match's list only after the Final Hand.

Status: built. The room's look is data (`count_room.tres`, with a new `UNIFORM` dress and an
optional palette for the disco rig, `disco_colors`); its furniture is `CountKit`, which `RoomKit`
hands the walls, boxes, pits, Junction, Jackpots and turbo pads to, with no litter at all; its hall
is `CountRoom`, which `RoomProps` hands the room to; both are files of their own, `arena.gd` and
`room_props.gd` being near their limit, with a hook of a line in each. The racks wink in
`count_leds.gdshader` and the monitors scroll in `count_monitor.gdshader`, off the world position,
so a baked rack winks as before; a monitor's screen stands beside its bezel rather than under it,
since the bezels bake. The crowd's `UNIFORM` house stands every place or every other one for half,
faces the table, all the same size and gray and at the same point in the beat, with no stands and
no DJ. The poster is a monitor standing on the back row's middle rack. House Rules is on the end of
`ArenaMaps.IDS`, and `ArenaMaps.STORY_ONLY` keeps it out of every pool a Grand Prix deals from and,
through `ArenaMaps.offered`, out of the lobby's list until the profile playing has played the Final
Hand with its story on. GAME.md's grid gained the four starts past the corners every map has had
since rooms of eight, which it was drawn before. The warm-up gained a step for the story's rooms;
`tools/warmup_check` now plays After Hours, the Yard and House Rules after its match, and with them
it found a miss the S2 posters brought in: the story's lettering in its own light, After Hours'
poster, the Yard's sign and this monitor, is a shader of its own, now warmed too; 110 entries, and
no room adds one. `make bots` takes `BOT_MAP`: on House Rules three matches of four hard bots bank
1551 a match against 1938 on Lucky Crossing, cash out 38.7 times against 80, take 187 from the
Jackpots against 236, die in a hole 6.7 times against 10.7 and touch a wall 15% of the time against
6%: a tighter lattice, every Jackpot reached and the lifted tiles mostly kept out of. The bench on
House Rules is 134 fps against 137 to 139 on the other maps. `tests/test_story_count_room.gd`, 4
tests: the map's place and its gating, the room as built, the crowd's rows, the warm-up;
`test_arena_maps` holds seven maps. Looked at: the room in play and at the whistle, the processor,
the memory banks, the vents, the cables in the pits, a rack's monitor and the poster's. Not looked
at: the room behind the loading screen, which the playground does not put up.

### S11: the Final Hand [8]

- [x] Due once the clock reaches the Final Hand's constant, the story on and the stamp not yet down.
- [x] The flyer (`scenes/ui/house_ad.gd`, after `SchoolAd`): at Play, cut to an arrow like the
      school's, in the house's gold rather than the school's red, YOUR TABLE IS READY blinking in
      foil over "One more hand. Then we should talk." and "Attendance is voluntary.", fitted to the
      room there as the school's is, held still for fewer flashes. Gone once the stamp is down.
- [x] The house's pane: Play opens the lobby as ever, and before the match settings a pane comes up,
      FINAL HAND, "The House has set a table for you.", with Take your seat in foil under the cursor
      and Not now. Not now is the usual lobby and is not asked again until the game is next started.
- [x] Take your seat sets the match, `MatchConfig.final_hand`, local and never sent: a quick match on
      House Rules, 5 minutes, the target of GAME.md 3.8, the profile's last bot difficulty, all items,
      three bots, and every other setting at GAME.md 3.8's default. The settings are shown but cannot
      be changed, under a stamp reading SET BY THE HOUSE, and the lobby's remembered choices are left
      as they were.
- [x] Never online: Play Online and hosting a LAN game never deal it. Somebody else at this machine
      may join in the lobby or mid-match as anywhere, taking a bot's seat.
- [x] CANDIDATE: the profile playing's seat is printed CANDIDATE in the standings
      (`scenes/ui/scoreboard.gd`), the kill feed (`kill_feed.gd`), the announcer's plate
      (`call_banner.gd`, `scenes/match/announcer.gd`) and the board at the whistle
      (`scenes/arena/led_clock.gd`); its own corner block and the slip's lines keep the player's name.
- [x] The models: the three bots are named `{name} 2`, `{name} 3` and `{name} 4` in seat order, wear
      the profile's paint, hat, flag and trail in colors of their own, take plates from those names
      as any bot's are drawn, and their mirror (`scenes/bots/bot_mirror.gd`) starts from the
      profile's lifetime items, nitro and drift readings rather than measuring the match's first 45
      s; effort is the match's own. Traits dealt as ever.
- [x] The rest of the table: the two fixed hoardings, the monitor, the crowd watching
      (`Crowd.watch(kart)`, S7), CANDIDATE TERMS under the pick, and note 21 on the floor, S8.
- [x] The whistle (`scenes/match/match_end.gd` `spotlight`, `LedClock`): the rig onto the candidate's
      kart rather than the winner's, wherever it is, the fireworks in the candidate's color, the
      board naming CANDIDATE, the crowd applauding together (`Crowd.applaud()`, S7). The standings
      and the slip stay true.
- [x] The evaluation (`results_screen.gd`): under the lines, past a perforation, the section of
      STORY.md 8.4 line by line with dotted leaders, filled in. `{deviation}` from how far the
      candidate's items, nitro, drift and cash-outs over the match sat from the models' average,
      never under 1; `{models}` the bots still at the table at the whistle; `{trait}` the
      classification of S3; `{place}` as an ordinal. It scrolls with the slip on a short screen.
- [x] The house's stamp in place of the ways on: `RubberStamp` with a gold base, beside STATUS as the
      test's hangs off the license, the control that presses it drawn under it, "Click the stamp to
      make it official", or Tap, or Press, by the device last touched. Pressed, two gold rings with
      APPROVED, THE HOUSE over it and the date under it, slammed over STATUS askew and short of
      solid; any player at this machine may press it. Then one way on, Continue, in foil.
- [x] The stamp coming down writes `story_final_hand` and keeps the evaluation's numbers for the
      folder, and saves at once: Terms Accepted.
- [x] Walking away [8.8]: left before the whistle, or after it but before the stamp, the Final Hand
      stays due and the flyer stays; closed after the stamp, the game comes back to the Operator's
      title.
- [x] The last lines, `scenes/story/last_lines.gd`: Continue puts the slip away to the house's dark
      stock and nothing else; the music goes under as at a death (GAME.md 8.4) and stays under. A
      board of the clock's kind drops in on two bolts, HUMAN OVERSIGHT over one seven-segment digit,
      0; a second later it clicks over to 1 with the stamp's thud; OPERATIONS: NORMAL in small
      capitals under it; two seconds; the board fades. Then THE HOUSE DOESN'T NEED YOUR DECISIONS.
      IT NEEDS YOUR NAME ON THEM. alone in the middle in the condensed capitals and foil until a
      press; it fades; a breath; CONGRATULATIONS. YOUR TRIAL PERIOD IS OVER. until a press. Nothing
      says to press. A press only counts once a line has stood a second, and a button held from
      before does not count, as the joker pick's guard works.
- [x] Then the license in full over the stock as after the driving test, changed, S12; put away, the
      title.
- [x] Terms Accepted's card in the folder's back, S9: license-sized, the house's paper, the APPROVED
      stamp across it and TERMS ACCEPTED under it, with the date.

Verify: `tests/test_final_hand.gd`: due only at its time, licensed and on; offline only; the pane's
two ways and Not now held for the session; the locked settings; CANDIDATE everywhere listed and
nowhere else; the models' names, dress and mirror; the whistle's three overrides; every evaluation
line filled; the stamp writing the profile; walking away at each point; the last lines in order with
the press guard. A full run by hand on a fresh profile with `--story-final-hand`.

Status: built, but for the license and the title it comes home to, which are S12's. `FinalHand`
says when it is offered, sets its table (`MatchConfig.final_hand`, never in a plan or on the wire),
names the candidate and works out the evaluation; `FinalHandPane` is the House's question in the
lobby, asked offline alone, and `HostSettings.set_by_the_house` shows the table under a
`HouseStamp` and remembers none of it; `HouseAd` is `SchoolAd` dressed in the House's gold, held
still for fewer flashes as the school's now is too. `FinalHandTable`, put down by the match scene,
seats and dresses the models after the match starts (`Match` being at its line limit), holds the
mirror's habits at the profile's lifetime (`BotMirror.hold_habits`), has the house watch and
applaud, and at the whistle puts `HouseEvaluation` on the slip through
`ResultsScreen.take_the_house`. CANDIDATE is `FinalHand.name_of` in the standings, the kill feed and
the announcer's plate, and the board's word; the rig and fireworks follow `FinalHand.candidate`.
The deviation sets the candidate's items, nitro, drift and cash-outs against the models' average,
each against a floor so a habit nobody had divides by something. The slip scrolls down to the
evaluation a moment after it is up, the podium seen first, since the stamp was under the fold on a
1080p screen. `RubberStamp` takes a rubber color; `ApprovedStamp` is the House's mark, for the
slip, the license of S12 and the card. `LastLines` counts a line's standing time in the game's own
time, and a press is a fresh press of anything. The folder's back is two pages under the notes'
numbers, `StoryNotes.FINAL_SLIP` and `TERMS_CARD`, drawn by `FolderBack`. `tests/test_final_hand.gd`,
5 tests: when it is offered and the flyer, the House's table locked and nothing remembered,
CANDIDATE, the models, the watching house and the whistle, the evaluation, the stamp writing the
profile and Continue, and the last lines' order and press guard; the folder's back in
`tests/test_story_folder.gd`. Walked through by a script on a scratch profile due for it: the pane,
the locked settings, the table, the whistle, the slip, the stamp, the board, both lines and the
license; not by hand.

### S12: after the ending [8.6, 9]

- [x] The license (`license_card.gd`, everywhere it is drawn: the title's peek, the full view, the
      License tab and the license screen): the house's stamp, the gold rings of APPROVED askew over
      the lower left corner; CLASS K · Operator, fitted to its field; EXPIRES NEVER; on the back
      PROPERTY OF THE HOUSE and ISSUED BY A BOT, REVIEWED BY {name}. A retake keeps all of it.
- [x] The title (`title.gd`): Play reads Clock in and does what Play did, the one renamed word of
      STORY.md rule 1; along the foot, clear of the license's button in the bottom right, one line in
      the Count Room's green set as a terminal's, OPERATOR {license} · SHIFT {shifts} · STATUS
      NORMAL, a block cursor blinking at its end, held still for fewer flashes; the seal's fine
      print round the title's mark only (`scenes/ui/logo_art.gd`, the title's call of it), JACKPOT
      JUNCTION · THE HOUSE · UNDER HUMAN OVERSIGHT, the icon, the splash and `make logo` untouched;
      the flyer gone; the folder as it was.
- [x] Stage 5 everywhere through S1's tables: the hoardings, the poster, the road, the slip's small
      print, bulletins and Payslip, the pick's STAFF TERMS, microprint, loading, the Statistics
      line and Shifts, the 217th edition, the examiner, the Yard's sign, After Hours' frame.
- [x] Notes 22 to 26, every ten minutes of the clock; the last turns the Workbench's calendar over.
- [x] House Rules in the quick match's list, S10.
- [x] Switched off, all of it goes back to the Department's license and the title as it was, and
      comes back switched on.

Verify: tests for the license's back and face after the ending and after a retake, Clock in still
starting the lobby, the green line's text and its place at every UI scale and on a phone, and the
switch undoing each.

Status: built. The license is the Operator's when the profile playing's story has ended and is on
(`LicenseCard.approved`, the date the stamp came down): the House's APPROVED in gold through
`StampArt` over the lower left, CLASS K · Operator, EXPIRES NEVER, PROPERTY OF THE HOUSE, the back's
fine print reviewed by the holder, and the holder signing as examiner (S6), on every card
`LicenseCard.create` makes, a retake's too. The title's Play reads Clock in, the same button; the
green line is in Courier Prime and the Count Room's own green, its block cursor blinking unless
flashes are cut, and the menu's scroll stops short of it, which a big UI scale on a short screen
needs; `LogoArt.fine_print` is the title's seal's alone. Stage 5's lines are S1's tables and came
with them; notes 22 to 26 are S8's schedule, the calendar S7's, House Rules S10's.
`tests/test_story_after.gd`, 2 tests: the license as the Operator's, from the settings and as a
retake's would be, and the Department's before; the title's Clock in, green line and seal, and with
the story off the title, the folder and the license as they were. Looked at: the title at UI scale
1 and 2, the license's face and back. Not looked at on a phone.

### S13: wrapping up

- [x] GAME.md: the "planned" words come off 1.3, 6.3, 8.1 and 8.7 as each part lands, and anything
      built differently is written back first. STORY.md: "None of it is built yet" goes.
- [x] CHANGELOG.md: lines for players that give nothing away, one or two sentences each, "The tables
      have more to say, in the small print." rather than anything about the House, a note or the
      ending. The ending is never named in a changelog, a release note or the README.
- [x] THIRD_PARTY.md: every face and sound the story adds, in the commit that adds it.
- [x] The export presets still leave STORY.md out.
- [x] `make check` passes, and the story's tests run in it.
- [ ] A play-through by the user on a fresh profile, honest, at the real pace, with the stages
      noticed or not noticed written down; then the constants of S0 tuned, and STORY.md 5.1 and
      GAME.md 8.7 brought in line with them.

Verify: `make check`; the user's play-through.

Status: built, but for the user's play-through. GAME.md 1.3, 6.3 and 8.1 lost their "planned" as
their parts landed, and 8.7 lost its own now; STORY.md says it is all in the game. A profile from
before the story starts it from nothing, which is what the code does, the user resetting profiles
by hand, and both documents now say so rather than promising a reset. The Notes button that was to
stand in for the folder never had to, so its two lines are gone. STORY.md 11 names where the lines
live and what the tests hold; note 12's numbers against the trait table were promised there and in
S1 and had no test, so `test_story_notes.gd` has one now, the memo built from
`data/ai/traits.tres`. GAME.md 8.1 says the same match plays in any of the rooms rather than three.
CHANGELOG.md: one line under Added, "The tables have more to say, in the small print.", with where
to switch it off, and nothing about the House, a note or the ending; under Fixed, the driving
school's flyer no longer blinking with Reduce flashing on, which S11 changed for every flyer.
THIRD_PARTY.md has the story's two faces, Courier Prime and IM FELL English, from S9, and the story
adds no sound. All seven export presets leave STORY.md out. `make check`: 1228 tests passed, the
story's thirteen suites among them, and smoke; the multiplayer check stopped once on a client of
the room of eight leaving a sound behind at exit, the known artifact of quitting mid-sound, and
passed three times running after it, with the lag and server checks.

### S14: the first look, the user's notes

The user's first round of notes on the built story, 2026-10-07, answered with defaults but where
noted; STORY.md and GAME.md were brought in line first. One commit an item.

- [x] STORY.md and GAME.md: every decision below written in first.
- [x] Story Progression: the License tab's switch renamed, and switching it off asks first, saying it
      can be switched on again at any time [5.4].
- [x] The Final Hand asked again each time Play opens the lobby, rather than once a run [8.1].
- [x] House Rules: the gaps between the walls round the edge 2 cells at least, still point-symmetric
      with its 8 spawns; GAME.md 6.3's grid with it.
- [x] The Count Room's rack lights softer, slower, fewer and bigger, small ones settling into a glow
      rather than shimmering as the camera moves.
- [x] The road's box worn: flush with the floor, thin along the karts' line, chipped [6.1].
- [x] The title after the ending: the green line in the tagline's place, its cursor blinking in a
      slot of its own so the line never moves [8.6].
- [x] The title: the license reached going right from the buttons as the folder is going left; both
      slid out and marked under the cursor with the buttons' gold outline and chevron, for the user to
      judge against a slow gold glow turning round them [7.2].
- [x] Hands: Caveat for Kit, Kalam for the forklift driver (3, 7), Patrick Hand for the napkin and
      the envelope (8, 14), Permanent Marker for the folder; Homemade Apple for the license's
      signature alone; THIRD_PARTY.md and the credits [7.3].
- [x] Note 21 gone over in pen: Don't underlined three times, exclamation marks, a warning triangle,
      scribbles. Note 18 in boxes. Note 16 drawn as a road engineer draws, its title block fitting,
      Kit's margin line [7.3].
- [x] The folder: a note on each side of a leaf, two to a spread [7.2].
- [x] The folder comes out from the edge and its cover swings open; put away, the reverse. It opens
      on its first spread and turns quickly to the first new note, a press cutting it short [7.2].
- [x] The folder's front: DO NOT FILE in marker, a pencil K., an eye in pen crossed out [7.2].
- [x] A closer look: a note taken off its page, larger, zoomed and moved, turned over to its back,
      every back of 7.3 drawn [7.2, 7.3].
- [x] Sounds: Kenney's RPG Audio (CC0), its paper and book sounds, for the folder opening, shutting
      and turning, and for taking a note; THIRD_PARTY.md. The pack has no pencil, so the pencil's
      scratch is made here, `pencil-scratch.wav`, out of filtered noise.
- [x] A note on the floor easier to see: a soft breathing halo over the litter, a corner lifting,
      a glint every three seconds [7.1].
- [x] NOTE COLLECTED big in the middle, written on in pencil, then into the corner, after any call
      already up; with a rustle and a scratch [7.1].
- [x] The invitation: the Final Hand's pane a black card edged in gold, dealt face down and turned
      over; a look at a gold-edged ticket beside it for the user [8.1].
- [x] The match settings at the Final Hand: no SET BY THE HOUSE, every value under a marker bar of
      its own, drawn on in turn [8.1].
- [x] Debug builds: a Story tab last in the settings, where the story is and buttons to move it;
      the README's story arguments, under a spoiler heading: the user asked for them there, so the
      README names the Final Hand where S13 kept it from doing so.

Verify: the story's suites and `make check`; screenshots of each, sent to the user.

Status: built, every item; the play-through of S13 is still the user's. Choices made on the way:
the closer look draws each face into a picture at the size it is shown, oversampled, since scaling a
page up blurred its letters; Look closer has the folder's cursor, Put it away is Back, a click
beside it or its button; the folder's peek hides while the folder is out of it; the backs are a
table of their own, `StoryNotes.BACKS`, note 1's band added to STORY.md 7.3 and note 21's back read
whole rather than torn mid-line; the pencil's scratch is made here from filtered noise; NOTE
COLLECTED waits four seconds at most for a call; the room's name under the arena is blacked out
with the rest, and `HouseStamp` and its line are gone. The ticket of answer 14 (c) was drawn as a
mock for the user to compare, not built. `make check` passed, 1235 tests; on the runs before it,
the multiplayer check twice had a client leave something behind at exit and once a client time out
driving to a pad, flakes of the check's timing rather than of anything here, which runs headless
with the story off. Looked at: every item, screenshotted.

### S15: the second look, the user's notes

The user's second round of notes, 2026-10-07: the marker under the cursor is good as it is; the
invitation and the ticket both stay; the rest below. STORY.md and GAME.md first. One commit an item.

- [x] STORY.md and GAME.md: every decision below written in first.
- [x] The Final Hand in the lobby: Take your seat and Not now under the card, not on it; taken, the
      golden ticket comes up from behind the card, shows a moment and drops away; when the lobby is
      ready the ticket comes back and its ADMIT ONE is torn off, then the match begins [8.1].
- [x] After the ending the folder keeps the invitation and the torn ticket at the back too [7.2].
- [x] The title's folder upright, the way it opens, its front the cover's [7.2].
- [x] The folder: turned on to the first new note, it opens the closer look on it; a note is read
      only once looked at closer; a turn or any press stops the turning on; the arrows turn as fast
      as they are pressed; each page's number pencilled at its foot [7.2].
- [x] The closer look tilts toward the mouse, the stick or the phone and catches the light, as the
      license does; Look closer is a magnifying glass [7.2].
- [x] Notes: 9's pencil under the print with an arrow to clause 4; the roll's grey edges run to its
      torn ends; 16's signature a person's, over MINISTER OF KARTS; 13's back line turned a little;
      18 the Minister's box crossed through in red pen; 21's pen sharp, nothing drawn twice; 23 ends
      END OF REPORT; 26 the House's wall calendar page [7.3].
- [x] NOTE COLLECTED carries the new note's pencil mark [7.1].
- [x] The green line's cursor up a little, level with the letters [8.6].
- [x] The folder's shutting quieter, and only once it is shut.
- [x] The Story tab's buttons: Stage -, Stage +, Unlock all notes.

Verify: the story's suites and `make check`; screenshots of each, sent to the user.

Status: done, 2026-10-07. Built as planned, with these choices: the closer look draws each face
through the license's own tilt shader, `card_tilt.gdshader`, which gained a `sheen` (a soft patch of
light that moves as the card turns, the rest dimmed by half as much so white paper shows it) and
takes a `relief` per user; `TiltedCard.wanted` is shared, the note turns three quarters as far as
the license and less the closer it is looked at, and turns over in perspective as the license does.
Look closer is `HouseArt.magnifier`. The title's folder is 236 by 354, the cover's proportions, and
shows seven tenths of itself. The ticket is `GoldenTicket`, its stub a child that tears off along a
ragged edge shared by both outlines; both are filled as fans from their middles, since the engine's
own triangulation gives up on the ragged edge. `FinalHandPane.admit` is the door, from the lobby's
`_begin`; the tear's sound, `paper-tear.wav`, is made here from noise. The invitation is 600 tall
now that its buttons are under it. The back of the folder lays the invitation and the torn ticket
as children of their pages, `FolderBack.lay`, numbered -3 and -4. `make check` passed on its third run, 1236 tests;
the two before failed on timing alone, in suites S15 does not touch, each passing on its own: first
`test_online_seats`, reading the host's slot for a client's second seat before the host had made
it, then `test_driving_school`'s theory book and `test_play_online`'s four seconds to say nobody is
at an address. Looked at: every item, screenshotted; the user's third round of notes followed.

### S16: the third look, the user's notes

The user's third round of notes, 2026-10-07, taken as given with these defaults: the invitation's
room under its words, left once its buttons went under it, holds the R.S.V.P. an invitation has at
its foot; the pencil mark on an arrow means the very next spread or note is new; all the notes are
paper, so none keeps a gloss. STORY.md and GAME.md first. One commit an item.

- [x] STORY.md and GAME.md: every decision below written in first.
- [x] The invitation the size of a playing card again, 520 by 740, R.S.V.P. at its foot; the ticket
      hidden whole behind the card before it comes up, and held long enough to read [8.1].
- [x] Icons for the folder's and the closer look's buttons: a cross for Put it away and Put back,
      turning arrows for Turn over [7.2].
- [x] The closer look's light as paper takes it, soft and broad, no gloss [7.2].
- [x] A note is read as soon as it is taken out for a closer look [7.2].
- [x] The arrows to the spread or note either side carry the pencil mark when what they go to is
      new [7.2].
- [x] Notes: 13's back line turned further; 9's arrow a proper arrowhead [7.3].
- [x] NOTE COLLECTED's pencil mark lined up with its words, the mark's ! in its ring [7.1].

Verify: the story's suites and `make check`; screenshots of each, sent to the user.

Status: done, 2026-10-07. Built as planned, with these choices: the ticket starts at nine tenths of
the card's width, wholly behind it, slides out to the right until it is clear of the card, then
comes forward to its full size and is held 2.8 seconds. The icons are `HouseArt.cross` and
`HouseArt.turning`, the words kept as tooltips. The tilt shader's spot size is a uniform,
`sheen_tight`; the notes take sheen 0.08 spread at 4, relief 0.45. An arrow's pencil mark is
`NotePage.mark_button`, a scrap of paper at the button's corner, since pencil on a dark button
would not show. Note 9's arrow solves its bow so it keeps to the pamphlet's 18-pixel margin; note
13's back line turns about its middle. The mark's ! is drawn in strokes, and `FolderPeek`'s corner
draws the same mark. `make check`: the tests, 1236, and everything before the multiplayer check
passed; the multiplayer check had a client leave something behind at exit, its known flake, and the
multiplayer, lag and server checks then passed. Looked at: every item, screenshotted and sent.

### S17: the fourth look, the user's notes

The user's fourth round of notes, 2026-10-07, taken as given with these defaults: a page's note is
turned and moved by its own number, the same every time, and held by a clip, tape across its top,
tape at its two top corners or a staple; the pad turns the folder's pages with its shoulder buttons
as well as the d-pad, and the folded corners show the shoulder buttons on a pad and the arrow keys on
a keyboard; all four things kept at the back can be looked at closer, the ticket and the slip and
the card with backs of their own. STORY.md and GAME.md first. One commit an item.

- [x] STORY.md and GAME.md: every decision below written in first.
- [x] The ticket comes out from behind the card at a slant of its own [8.1].
- [x] A small copy of the ticket on the lobby's ticket at the top while the seat is taken [8.1].
- [x] Note 9's arrowhead aimed along the end of the curve, up a little [7.3].
- [x] Fast page turns show every leaf going over, quicker, rather than jumping [7.2].
- [x] Each page's note a little askew and off-center, under a clip, tape or a staple [7.2].
- [x] The pages' bottom corners folded where there is a leaf to turn, the button on the fold; the
      pad's shoulder buttons turn the pages and step the closer look [7.2].
- [x] What is kept at the back can be looked at closer and turned over [7.2].
- [x] The gold of the invitation and the ticket catches the light in the closer look [7.2].
- [x] The closer look grows up off its page and goes back down onto it [7.2].
- [x] The notes either side slide in and out in the closer look [7.2].

Verify: the story's suites and `make check`; screenshots of each, sent to the user.

Status: done, 2026-10-07. Built as planned, with these choices: a folder page lays its note on as a
child of its own, layer `lying`, with `NoteOnPage` over it for the clip, tape or staple, since the
notes' own drawing sets transforms of its own that an outer turn would lose; `NoteOnPage.lay` keeps
the turn and the shift clear of the page's edges. The folded corners are `TurnCorner`, shown from
`_mark_ends`, the bind redrawn when the device changes. Fast turns queue, three at most, the leaf
in flight sped up by `TURN / TURN_QUICK`. The kept things take `FolderBack.paper_rect` and are laid
at their own size on the closer look's layers; the ticket's back is `GoldenTicket.face_down`. The
tilt shader's `foil` makes only the gold catch the light. `NotesFolder.lift_of` says where a page's
note lies for the closer look to grow from and go back to; the view builds a card per note, so
the one before can slide away. Note 9's arrow comes in along `ARROW_RISE`. While testing, the
folder's suite failed now and then and once aborted, while the user had the game running from this
worktree and gdUnit could not clear `reports/one`; with that folder cleared it passed thirteen runs
in a row. `make check` passed, 1237 tests. Looked at: every item, screenshotted and sent.

### S18: the fifth look, the user's notes

The user's fifth round of notes, 2026-10-07, taken as given with these defaults: Play Online reads
Clock in online; the lobby's ticket is a small drawing of one rather than the ticket made small;
the license view goes the way of the folder and the closer look, its buttons mouse-only like theirs,
and the folder takes a right click to put it away as the other two do; the binds are drawn inside the
buttons, at their right; Enter still looks closer and turns over, as Tab and Y do; notes are kept by a
key of their own, a profile's numbers from before read as today's notes. DO NOT FILE stays until the
user picks a line from the suggestions. STORY.md and GAME.md first. One commit an item.

- [x] STORY.md and GAME.md: every decision below written in first.
- [x] The folded corners and their binds gone [7.2].
- [x] Play Online reads Clock in online after the ending [8.6].
- [x] The stick turns one page a push, let go between [7.2].
- [x] Putting a note back is quiet [7.2].
- [x] The folder stays where it is while a note is up [7.2].
- [x] On the title, Back takes the cursor off the folder or the license to the buttons [7.2].
- [x] A tiny drawn ticket on the lobby's ticket [8.1].
- [x] The license view, the folder and the closer look alike: icon buttons for the mouse only, a click
      turning over and a right click putting away, the hand's button looking closer in the folder,
      the binds drawn on the buttons with keys or a pad [7.2].
- [x] The House: the pits' cables each their own, red patch cables over the racks, less green [3.9].
- [x] Notes kept by a key of their own, gaps and all [5.2].
- [x] Later the same round: the folder's shutting heard a moment sooner; the next page no longer
      blinks up for a frame before a leaf turns; on the title Tab no longer shows the license, and
      hints at the folder and the license, for keys or a pad only, say how to reach and open them;
      accept, not the hand's button, takes a note out; A and D turn pages; a pad's triggers hold
      a note as close as they are pulled; the license grows up off the title's card and back; the
      arrows' binds left off where there is no page; the folder beside the slip comes out and
      opens its cover a little to draw the eye [7.2].

Verify: the story's suites and `make check`; screenshots of each, sent to the user.

Status: done, 2026-10-07. Built as planned, with these choices: `ButtonBinds` marks a button with
the action it answers to and hangs the bind under it while `Game.last_input_pointer` says keys or a
pad are in hand; the stick's latch is `NotesFolder.stick_way`, shared with the closer look; the
license view flies its stand from the card it was shown from, following it back as the title slides
it. Notes are kept by `StoryNotes.KEYS`. The Count Room's pits take the room's seeded RNG in turn.
While this round was built the user played from the same worktree with a pad, which Godot reads
even headless: suites failed in the theory book, the quiz and the tilt while it was in hand, and
the lag check once lost its clients; all passed with the pad idle. `make check` passed, 1238 tests.
The user's settings file changed once at 21:10 while their game was running from this worktree,
`match_seconds` from 5 to 180 and profile 1 saved with it; neither the test suites nor the probe
scripts write it. Looked at: every item, screenshotted and sent.

### S19: the sixth look, the user's notes

The user's sixth round of notes, 2026-10-07: the folder's front reads OFF THE BOOKS, their pick of
the suggestions. STORY.md and GAME.md first. One commit an item.

- [x] The folder's front: OFF THE BOOKS, as big as fits [7.2].
- [x] The line under the buttons says nothing the buttons' binds already say [7.2].
- [x] A click turns the license or a note over only on it; beside it, as a right click, it puts it
      away [7.2].
- [x] The license goes back to the title's corner smoothly, turned face up on the way [7.2].
- [x] On the title a click beside the folder or the license takes the cursor back to the buttons;
      the arrows of the folder and the closer look go, keeping their room, where there is nowhere
      to go [7.2].

Verify: the story's suites and `make check`; screenshots, sent to the user.

Status: done, 2026-10-07. The marker on the folder is sized to fit, `FolderCover.MARKER_SHARE`. The
lines under the buttons are empty with keys or a pad, but for the closer look's zooming and moving.
The license flies with `TiltedCard.calm` following the flight and its tint going from the peeking
card's dim to full, and turns face up in the flight's own time, `TiltedCard.turn_over(takes)`, as
the closer look now does too. The arrows at the ends keep their room, `ButtonBinds.show_arrow`. A
click beside the license or a note put it away at first, was made to do nothing on the user's word,
and then to put it away again on their next. `make check` passed, 1238 tests. Looked at: the
folder's front, the hints, the license going back face up; screenshots sent.

### S20: the seventh look, the user's notes

The user's seventh round of notes, 2026-10-07, after 0.14.0: the payout slip's pages as one long
bill, the things kept at the back of the folder held on their pages as the notes are, and the next
match blacked out in the lobby at the Final Hand. Their answers: the bill runs off the screen, its
torn edges going with it; its pages as tall as the tallest, each headed as now; the arrows and dots
upright beside the bill rather than on it; a turn a short scroll; the barcode and the small print
only at the foot of the last page; the run's final standings a page under the last map's, which
stays a scroll up; a watcher's countdown as before; each page's podium drawn only in view; the
House's evaluation a page of its own, turned to; the ways on along the foot of the screen, to try.
STORY.md and GAME.md first. One commit an item.

- [x] The invitation, the ticket, the Final Hand's slip and the card of Terms Accepted lie askew on
      their pages, held by a clip, tape, a staple and tape over two corners [7.2].
- [x] In the lobby, beside the tiny golden ticket, the next match is blacked out but for "Next:"
      [8.1].
- [x] The payout slip is one long bill: its pages one under another past a perforation, torn at the
      top and the foot of the whole, run off the screen and scrolled over; a turn brings a page to
      the middle; the pager upright beside it; the ways on along the foot of the screen [GAME.md 3.8,
      9.7].
- [x] The House's evaluation is a page of its own at the end of the Final Hand's bill, turned to
      with Continue, the cursor on the stamp once it is in view [8.4].

Verify: the story's suites, the results screen's and the Grand Prix's, and `make check`;
screenshots, sent to the user.

Status: done, 2026-10-07, on 0.14.0. The bill is `PayoutBill`: a `ScrollContainer` under a
gradient mask (`clip_children`), so the paper fades out at either end of what is shown, its pages
evened to the tallest; a page is `SlipPage`, with the rows that were the screen's. The pager stands
on the left of the bill, since the standings run down the right of the screen; it never takes the
cursor, and its binds hang on its arrows, `ButtonBinds`. On a screen the whole bill fits on, a test
window's, a turn sets the page with nothing to scroll. The House's evaluation and the bill went in
one commit, the evaluation being how the bill takes it. `make check` passed but for one run of the
multiplayer check, a client that did not reach its Royal Flush pad on map 1 before any slip was up;
it passed again. Looked at: every slip, the Final Hand to its stamp, the lobby, the folder's back;
screenshots sent.

### S21: the eighth look, the user's notes

The user's eighth round of notes, 2026-10-07, on S20's bill. STORY.md and GAME.md first. The items
went in as one commit, being one screen's.

- [x] The bill fades out only at its foot, over the ways on, and runs straight off the top of the
      screen [GAME.md 3.8].
- [x] The ways on stand on their own along the foot of the screen, with nothing under them
      [GAME.md 3.8].
- [x] The pages' arrows stand out: in foil, bigger, over the bill's left edge as far as its margin,
      the dots on a pill of the house's dark [GAME.md 3.8].
- [x] Up and down turn the pages, on the keys, a pad's cross or its stick, a push of the stick a
      page; a page taller than the screen shows the rest of itself first [GAME.md 3.8].
- [x] The cursor starts on the arrow down, and goes to the way on under the bill on the last page
      [GAME.md 3.8, 9.7]; at the Final Hand the arrow down goes on to the House's page, Continue on
      the slip's page gone [8.4].
- [x] "Click the stamp to make it official" is printed on the House's page under STATUS [8.4].

Verify: the results screen's, the Grand Prix's and the story's suites, and `make check`;
screenshots, sent to the user.

Status: done, 2026-10-07. The arrows reach 12 px onto the paper, no further than its margin: half
over it they covered the place chips and the evaluation's labels. The bill keeps where a page turn
put it however the pages are laid out after, `PayoutBill._on_target`, until it is moved by hand: a
bill that fitted the screen when it was turned and grew a little after went back to its first
page. The keys and the stick are heard in `ResultsScreen._input`, before the cursor would take
them, unless the cursor is somewhere over the slip or Kit's folder is open over it.

## M9: the catalog

GAME.md 8.8 is the design, STORY.md 6.6a its line of small print. Asked for by the user on
2026-10-07, after 0.14.0: every profile keeps which jokers and power-ups it ever took, and the title
opens a catalog of them, the ones never taken face down. Built in worktree `.claude/worktrees/catalog`,
branch `catalog`, from master at 2fc4801. A task names the GAME.md section it builds, in brackets.

### Progress

| Phase | What | State |
|---|---|---|
| C0 | The record: what a profile keeps, and who writes it | Done |
| C1 | Power-ups say what they do, and their numbers | Done |
| C2 | The dialog and its Jokers page | Done |
| C3 | The Power-ups page | Done |
| C4 | The title's way in, the NEW tags and the story's line | Done |
| C5 | Wrapping up | Done |
| C6 | The first look, the user's notes | Done |

### Questions, and the defaults built

Asked on 2026-10-07 with a default each. Answered the same day: the defaults, but for 1.

1. Where it opens: a Catalog button on the title, between Garage and Settings, a screen of its own
   (or a Settings tab beside Statistics). Answer: the title's button, but a large dialog over the
   screen rather than a screen of its own, so it can be laid over other places later.
2. Two pages, Jokers and Power-ups, as tabs like the settings', the shoulder buttons between them.
3. The count on each tab, Jokers 12/35, gold once complete.
4. What counts: every joker into a local seat's hand, from the pick or off the floor, and every
   power-up picked up, in every room, the Garage and the driving test too.
5. Who: the profile playing and every linked profile, offline and online; guests, bots and watchers
   nothing; nothing new on the wire.
6. A count per card, Taken 14 times, at the pane's foot.
7. Order: jokers by rarity, kind, name; power-ups first set then later set, in GAME.md 7.1's order.
8. Never taken: a face-down card with a question mark, no name, kind or rarity; its pane says only
   Not found yet. Power-ups: a gray chip with a question mark.
9. Details always on, Stacks up to ×3; Full stack, a button and the details key, shows the stack at
   its most. Starts at one copy.
10. The story: the term under the effect from stage 2, and a line under the title by stage, as on
    the Statistics page (or also "Terms accepted 12/35" from stage 2). Default: the line only.
11. The power-up pane: picture, name, a sentence, then facts read from the item's numbers.
12. The power-ups' sentences reworded to go without numbers.
13. No House small print on power-ups.
14. A NEW tag on a card found since the catalog last showed it, gone once highlighted; nothing on
    the title.
15. Profiles from before start empty.
16. `++ --catalog-all` in a debug build fills the playing profile's catalog.
17. From the title only, not the pause menu.

### Decisions fixed for implementation

- **`CatalogState` in the profile.** A `[catalog]` section in the profile's file, written by
  `Profile`: `jokers` and `items`, each a dictionary of id to times taken, and `fresh`, the ids found
  and not yet looked at. Ids this version does not know are kept as they are and never shown or
  counted, so a joker taken out of the game, or one from a newer version, loses nobody's record.
- **`CatalogRecord` writes it.** A node beside `MatchRecord` in every room a player here can take
  something in: the match scene, the lobby, the driving test and the Garage. It hears
  `Events.joker_taken` and `Events.item_picked`, which every machine already hears for its own seats,
  finds the seat's profile as `MatchRecord.profile_for` does, and keeps it in memory; it saves as the
  room is left, in `MatchRecord.GROUP`, so `Game.go_to_title` writes it before unlinking the seats.
  Same guards as `MatchRecord`: the current scene's, never headless, `anywhere` for a test.
- **Nothing on the wire.** No message, snapshot or plan carries it.
- **Facts from the item.** `PowerUp.facts()` returns the lines of numbers each item's pane shows,
  each subclass reading its own exports, so a number tuned in the data is the number the page says.
- **The pane is the match's.** The Jokers page shows `JokerDetail` itself, so the story's term and
  every rule of the pane are the same in both.
- **A dialog on a layer of its own.** `CatalogDialog` is a `CanvasLayer` over `PauseMenu.LAYER`,
  opened with `CatalogDialog.open(parent)` and `put_away` when it goes, the cursor back where it was;
  it swallows the keys and pad buttons it does not use, so nothing reaches the screen under it.

### C0: the record [8.8, 8.5]

- [x] `scripts/catalog_state.gd`, `class_name CatalogState`: `jokers`, `items`, `fresh`; `take_joker`,
      `take_item`, `times`, `found`, `is_fresh`, `look_at`; read and write the section, keeping
      unknown ids.
- [x] `Profile.catalog`, read and written with the rest.
- [x] `scenes/match/catalog_record.gd`, `class_name CatalogRecord`: added in the match scene (not on
      a dedicated server), the lobby, the driving test and the Garage; writes on leaving.
- [x] Tests (`tests/test_catalog.gd`): a pick and a floor joker and an item go into the seat's profile, a linked seat's into
      its own, a bot's and a guest's nowhere; the section reads back; unknown ids survive; headless
      writes nothing unless `anywhere`.

### C1: power-ups say what they do [7.1]

- [x] Each item's `description` one sentence without numbers.
- [x] `PowerUp.facts()` and each item's own lines.
- [x] Tests: every item has a sentence and its facts' numbers are its exports'.

### C2: the dialog and its Jokers page [8.8]

- [x] `scenes/ui/catalog_dialog.gd`, `class_name CatalogDialog`: the shade and the large pane, its
      title, tabs with counts, Back, the shoulder buttons, a click beside it.
- [x] The Jokers page: the grid in GAME.md 8.8's order, cards fitted to the room (`CardGrid`,
      `CatalogCell`), the face-down back (`CardBack`), the cursor lifting a card, `JokerDetail` beside
      it with details on and Taken N times (`JokerDetail.show_unknown` for a face-down one), Full
      stack on a switch and the details key, its bind hung under it (`ButtonBinds`).
- [x] Tests (`tests/test_catalog_dialog.gd`): the count, the order, a face-down card names nothing,
      Full stack, the grid fits.

### C3: the Power-ups page [8.8]

- [x] Cards in the sets' order (`ItemCard`, `PowerUp.ink_of` for a dark color), face down as the
      jokers', the pane (`PowerUpDetail`) with sentence, facts and the set.
- [x] Tests.

### C4: the title, NEW and the story [8.8, STORY.md 6.6a]

- [x] The title's Catalog button, `Title.show_catalog`.
- [x] NEW tags from `fresh`, cleared under the cursor and saved as the dialog goes.
- [x] `StoryLines.CATALOG_LINE` by stage under the title.
- [x] `++ --catalog-all` in a debug build, `CatalogDialog.read_arguments`.
- [x] Tests.

### C5: wrapping up

- [x] CHANGELOG, README's debug arguments, `make check`, screenshots for the user.

Status: built, 2026-10-07; merged into master and released in 0.14.1 the same day. `make check` passed, 1253 tests. Looked at
on a 1600x900 desktop and a 2400x1080 phone at UI scale 1.5: all 35 jokers fit without scrolling on
both, the power-ups' cards grow to 1.3 of their size.

### C6: the first look, the user's notes

The user's first round of notes, 2026-10-08, after 0.14.1 ("not satisfied yet"). GAME.md first.

- [x] Every gamepad bind in the row of tabs, at its right end, as the settings have them: the
      switches' buttons with their words on the jokers' page, then the shoulder buttons.
- [x] Every card on both pages the one size (`CardGrid.SCALE` 0.85 of a hand's), scrolling where
      they do not fit.
- [x] The cards in a well sunk into the pane, Play Online's (`ListBox.Well`).
- [x] The rows reach across the well from side to side, the room left over shared between the
      cards, a short last row from the left; no more centering.
- [x] More room round the joker's pane (`PANE_AROUND`, `SWITCHES_UNDER`).
- [x] A Detailed switch under the pane for what the details key shows, Stacks up to ×N and one
      copy's numbers, room for more later; Full stack moves to the hand's button, Tab or Y. Both
      off to start with and kept for the run (static).

Verify: the catalog's suites; screenshots on a desktop and a phone.

Status: done, 2026-10-08. The switches' binds are read in `_input`, before Tab can move the cursor.

Then, the same day:

- [x] A power-up counts once it is used, `Events.item_used` (its button, or spent by Guardian
      Angel), never as it is picked up; `CatalogState.use_item`, kept as "used", 0.14.1's "items"
      (pickups) left behind and dropped from `fresh`; its pane's foot says Used N times.
- [x] No lift in the catalog (the user did not like it there): the card under the cursor wears the
      cursor's frame, `FocusGlide.look()`, drawn by `CatalogCell` round its card, and the glide
      slides between cards, `FocusGlide.GROUP`.
- [x] The card under the cursor shown large over the pane (`CardPreview`, up to 1.8 of a card's
      size, left out under 0.95, a phone's short screen).
- [x] Full stack gone for a Stack field (minus, ×N, plus, "Held up to ×N" / "Does not stack"),
      as far as `CatalogState.best_stack`, the biggest stack held (`stacks`, kept by
      `CatalogRecord` watching the seat's `JokerHolder.changed`), never past `Joker.most`; the
      hand's button steps it, round at the end.
- [x] The Stack field's big minus and plus buttons looked out of place (the user): `StackStepper`,
      drawn as the switch is, the switch's lane a little longer with a chip at either end and the
      stack in gold between, a click on either half stepping it; the switch and the field in a
      grid, words before them, lined up.
- [x] The stack's field goes as far as the joker stacks, held or not (the user); the biggest held
      is said after the field and at the pane's foot, "Taken N times · Held up to ×N".
- [x] The switch's and the field's keys in the row of tabs while keys are in hand (Alt, Tab), a
      pad's buttons otherwise while one is plugged in (`_show_binds`, `_switch_hint(keyboard)`).
- [x] The large card stands at the top of its room and keeps one size (the user: it jumped as
      the pane's words changed): its room is reckoned with the pane at its tallest,
      `CatalogDialog.PANE_KEPT` 250, measured (Curve Ball, details on, whole stack, 242).
- [x] The large picture is the card's picture in its ring, not the whole card (the user: less
      room), `CardPreview` drawing it, at most 200 across, the pane right under it.
- [x] The question mark of a card face down centered by the mark itself (`CardBack.draw_mark`,
      by the cap height), not by its line.
- [x] The stack's field starts at every joker's whole stack (`CatalogDialog.WHOLE_STACK`).
- [x] A page with nothing found yet: no count on its tab, no cards, how to begin it in the middle
      of the well, no pane, the cursor on Back (`CatalogDialog.is_empty`, `NO_JOKERS`/`NO_ITEMS`);
      "to unlock this page".
- [x] The tabs one piece with their pages, no air between the row and the page, as the
      settings' (`Pages`, separation 0).
- [x] The title's Garage and Catalog behind one button, Extras, which puts them and Back in the
      buttons' place (`Title.show_extras`, `in_extras`); the back key brings the title's own back.
- [x] Catalog at the foot of the settings' License page (`LicenseTab.open_catalog`), over the
      settings, from a room's pause menu too; the tab's Tab is the catalog's while it is up.

## M10: the loyalty program

GAME.md 8.9 is the design, STORY.md 6.6b, 7.3's loose notes and 10 the story's side of it. Asked for
by the user on 2026-10-08, after 0.14.1: a progression system, a tree of objectives with no one path
through it, tied to the story, casino-like and driving-like, nothing in it an advantage at a table
(cosmetic, or the table's for everybody), a panel that shows it confidently, and something to do
forever at the end. Not achievements, which may come later and point at it. Built in worktree
`.claude/worktrees/progression`, branch `progression`, from local master at bcf4035. A task names the
GAME.md section it builds, in brackets.

### Progress

| Phase | What | State |
|---|---|---|
| L0 | The record: what a profile keeps, bets as data, the statistics' bets | Done |
| L1 | The map's grid: landmarks, roads, opening and keystones | Done |
| L2 | The bets of one map | Done |
| L3 | The table's deck and items | Done |
| L4 | The dress the program pays | Done |
| L5 | The dialog: the map, the cursor, the pane, the list | Done |
| L6 | The welcome | Done |
| L7 | Settling: BET WON, the slip's page, the words by stage | Done |
| L8 | Lost Property | Done |
| L9 | Off the books and the loose notes | Done |
| L10 | The Showroom | Done |
| L11 | The roundabout and editions | Done |
| L12 | Wrapping up | Done |

### Questions, and the answers

Asked on 2026-10-08 with a default each, after a first pitch. Answered the same day: the defaults,
with the remarks under them.

1. The concept: the house's loyalty program, drawn as a road map from the slip road to the
   roundabout. Default. The user: "I really dig the loyalty program concept."
2. Its name: Loyalty Program on the button, and the name and the heading changing with the story's
   stages (the user's own, over the default's Rewards). Built as STORY.md 6.6b's table.
3. Each landmark a bet with its reward, no currency. Default; comps kept for something else later.
4. A landmark opens once any road into it is won; a keystone needs every road in. Default.
5. Size: about 45 landmarks. Default, but aimed at about ten hours first rather than 15 to 25: the
   first map has 38 and its counts are set for ten hours to both keystones.
6. Dress is the seat's, the deck and items the table's (the host's online, the profile playing's at
   a shared screen); a guest wears what the profile playing has, a linked seat its own. Default.
7. The deck starts with the twenty plainest cards; the Strip adds the other fifteen, the economy
   cards last; the catalog says what is not in the deck yet. Default; more jokers later may move the
   split, so which deck a joker is in is its own data.
8. The later items added by the Strip, two at a time. Default.
9. Lobby rules for the whole table: room left for them, built later. Default.
10. No map locked; new maps may join the program later. Default.
11. The Showroom, a bay off the Garage, opened by the Department's keystone. Default.
12. New kinds of dress: plate frames, tire marks, card backs, and about 30 new pieces in all.
    Default. The user: plate frames are small and hard to see, and tire marks must not be extreme;
    GAME.md 8.9 has a frame as a thin rim for close-ups and tire marks as faint as the plain ones.
13. Nothing covers the player's color or marker, changes a kart's size or hides it. Default.
14. Counted as the statistics are, on each machine for its own seats, nothing on the wire. Default.
15. A profile from before has its statistics' bets counted. Default.
16. Accuracy in one map, 60% of 30 shots or more, not a rolling window. Default.
17. Lost Property: one thing per room, local like a note, story on or off. Default.
18. The story: the house's voice by stage, Kit's district, the roundabout as note 16's drawing; the
    program never moves the story. Default. The user: a few notes may come from the program, as long
    as it never holds the story back; built as three loose notes outside the story's order.
19. Story off: Kit's district hidden, its bets not counted. Default.
20. Kit's bets are strange, human choices, never ones that spoil a table for others. Default.
21. The roundabout: seven bets a lap, a lap on the license and an edition, half as much again each
    lap, nothing reset. Default.
22. Editions seen by everybody. Default.
23. Daily specials later, with the backlog's daily challenge. Default.
24. BET WON in the player's corner, the settling on a page of the slip. Default.
25. Opened from the title's Extras, the pause menu and the slip's page, a dialog like the catalog.
    Default.
26. A toy kart for a cursor, driving the roads; mouse and finger click and drag; progress on every
    open bet. Default.
27. No achievements yet. Default.
28. Written into GAME.md 8.9, STORY.md 6.6b and 10, and this milestone. Default.

The user's remarks with the answers:

- **Not at once.** The program is not shown at first. It is handed over as a reward after the
  profile's first real map, as the title comes back, with fanfare like the invitation's but its own:
  GAME.md 8.9, When it comes, and STORY.md 6.6b, The welcome.
- **Can the map grow?** Asked whether a road map still fits if many more bets are added or the
  program changes a lot during development. GAME.md 8.9, Growing it: the map is a grid in data as
  the arenas are, ids are stable, it grows outward and by districts, and the List switch reads the
  same however big it gets; hundreds of small goals would be achievements rather than roads.
- **Everybody's own program.** The host's program decides what the table is dealt, and every other
  seat and client still moves on through its own: GAME.md 8.9, Each profile's own.

Asked next, 2026-10-08, and answered the same day: the defaults, but for 34, and with remarks on 36,
38 and 39.

29. The program's names by stage: Loyalty Program, Loyalty Program, Participation Program, Retention
    Program, Selection Program, Staff Benefits; with the line under each, STORY.md 6.6b. Default.
30. The welcome: a form letter with the card glued on, Activate card, the card peeled off and turned
    over once, the map unfolding behind it on its first showing. Default.
31. Everything counts all along, so a bet met while closed is won the moment its road is. Default.
32. A closed landmark shows what it pays but not what it asks. Default.
33. Loyalty Program the first of Extras' buttons, above the Garage. Default.
34. A dedicated server's game: the default was the whole deck and every item. The user: use the
    unlocks of the player who made the game, or better, of whoever has the host's say now, switching
    when it moves, so a dedicated server never opens everything. Built as the second: each client
    sends its deck as it sits down, and the server deals the say's, taken as each map starts.
35. Bots wear only what everybody has. Default.
36. A bet off the books is a pencil tick in the corner and is left off the House's page. Default,
    with the user's addition: on the slip, a torn scrap taped over it with the bets written in
    pencil, as if Kit added it after the slip was printed.
37. Three loose notes, turning up only in maps with no story note due, kept in the folder's back
    pocket; drafts in STORY.md 7.3. Default.
38. A Department bet won is also an endorsement on the license. Yes, as long as there are not too
    many: four, Drift, Clean Record, Marksman and the keystone's Advanced, small red stamps on the
    license's back, since its front carries the exam's already.
39. Lost Property in every map of its room once open. Default, or an even chance or so, the user
    said: built as an even chance a map and certain after two misses, as a note turns up, with a
    manila tag beside the clock while it lies there.
40. The roundabout needs only the Strip's and the Department's keystones, so a player with the story
    off reaches it; off the books' keystone leads nowhere. Default.
41. Card backs are seen in the catalog and on the map; also deal the respawn pick face down and
    turn the cards over inside the half second nothing can be taken, so a card back is seen in a
    match. Default.

### Decisions fixed for implementation

- **`LoyaltyState` in the profile.** A `[loyalty]` section written by `Profile`: `welcomed`, `member`
  (the member number, the invitation's when there is one), `won` (landmark ids), `fresh` (won and not
  yet looked at), `feats` (ids of the bets of one map done, with the time), `found` (Lost Property
  taken), `ring` (the roundabout's seven bets, each a statistic and the count it started from),
  `laps`, `editions` (a piece of dress to its finish) and `card_back`. Ids this version does not know
  are kept and never shown, as the catalog's are.
- **Bets are data.** `data/loyalty/`: the grid as a string, the way `ArenaLayout.grid` holds a map,
  and a `LoyaltyLandmark` resource each: `id`, its character, district, `kind` (`stat`, `feat`,
  `find`, `notes`, `card`), the statistic or feat it reads, the count, and what it pays (a piece of
  dress, joker ids, item ids, a note key, the Showroom). A `stat` bet reads `LifetimeStats.value_of`
  of the profile directly, so there is no second count to drift and old profiles are counted at once.
- **Settling is one function.** `Loyalty.settle(profile)` opens and wins what the state and the
  statistics allow, and returns what it won; called after every write of the statistics, as the
  program opens and as the welcome finishes. Nothing is won anywhere else.
- **`LoyaltyRecord` hears the feats.** A node beside `MatchRecord` and `CatalogRecord`, in the rooms
  that count, watching `Events` for the bets of one map and the end of each map; it finds the seat's
  profile as `MatchRecord.profile_for` does, and writes in `MatchRecord.GROUP`. Same guards: the
  current scene's, never headless, `anywhere` for a test.
- **The deck is the table's.** `Joker` gets `starting_deck`; a `JokerCatalog` made by `dealing()`
  knows every joker by id but offers and throws only its deck's. The deck is worked out as each map
  starts, `Loyalty.deal_table`: the profile playing's, or the host's for a hosted game, which is
  where the picks are dealt anyway. The item pads' roll takes the table's items the same way. On a
  dedicated server it is the deck of the client with the host's say: every client tells the host its
  profile playing's added jokers and items, by name, in one message of their own
  (`HostControls.tell_unlocks`) as it comes in and after every map or room it writes down, the
  server keeps each one's in `NetDoor.unlocks`, drops names it does not know and takes the say's as
  a map starts; a client that has said nothing is the starting deck. The user said on 2026-10-08 that
  the protocol may break for this if it makes it better: a hello says only words, numbers and flags,
  and one message beats names squeezed into the hello and the plan. So the next release is a minor
  version.
- **Dress grows at the end.** `KartStyle` gets the frame, the tire marks and a finish for each part,
  sent as more numbers after the four; `from_array` already reads only what it knows and makes an
  unknown choice the plain one. Whether that plays with 0.14.x is checked against GAME.md 10.3,
  Versions, before anything is promised. The card back is the profile's and never sent.
- **A dialog on a layer of its own.** `LoyaltyDialog`, a `CanvasLayer` as `CatalogDialog` is, opened
  with `LoyaltyDialog.open(parent)`; the map drawn from the grid by `LoyaltyMapView`, the cursor a
  `LoyaltyCursor`, the pane the house's.
- **The welcome is the invitation's kind.** `LoyaltyWelcome` built on `HeldCard`, put up and drawn
  under the warm-up as `OpeningInvitation` is, from `Title`.
- **Every line in one place.** The program's names, lines and words by stage in `StoryLines`, with
  their stage-0 words for the story switched off; the loose notes in `StoryNotes` under keys of their
  own, never in `KEYS`, so the story's next note is never one of them.

### L0: the record [8.9, 8.5]

- [x] `scripts/loyalty/loyalty_state.gd`, `class_name LoyaltyState`, and `Profile.loyalty`, read
      and written with the rest, unknown ids kept.
- [x] `LoyaltyLandmark` and the bet kinds; `LoyaltyMap` with its roads joined by hand until L1
      reads them off the grid; `Loyalty.settle`, `is_open` and `is_met` for every kind, the feats and
      finds read from the state that L2 and L8 write; settled by `MatchRecord` after every write of
      the statistics.
- [x] Tests (`tests/test_loyalty.gd`): a statistic reaching its count wins an open bet and not a
      closed one; a closed one met wins as its road is won; an old profile's statistics are counted;
      nothing before the card; a keystone's roads; off the books with the first note and gone with
      the story off; the section reads back. Full suite 1293 green.

### L1: the map's grid [8.9]

- [x] `data/loyalty/map.tres` with the first map of GAME.md 8.9 and its 38 landmarks, the slip
      road's among them; ids by what each pays, `dealers_visor`, `card_shark`. Feats are kept by the
      landmark's id, so two landmarks can ask the same feat at different counts.
- [x] `LoyaltyMap` reads the grid: landmarks' places, roads through bends and crossings, ink into
      pencil, roads to the roundabout and off the grid's edge (the slip road's stub); opening by any
      road and a keystone by every road were L0's.
- [x] Tests (`tests/test_loyalty_map.gd`): `LoyaltyMap.problems()` empty for the first map, which
      checks every landmark reached from where its district opens, every road joining two ends,
      every character a landmark or a road, every landmark drawn once, ids and marks unique and the
      house's keystones on the roundabout; the drawing's roads; a broken grid says what is wrong;
      fifteen jokers paid once and the four later items; the whole map won in one settling.

### L2: the bets of one map [8.9]

- [x] `LoyaltyRecord` (`scenes/match/loyalty_record.gd`) in the match scene, the lobby and the
      driving school (not the Garage, not on a dedicated server), the profile found per seat as
      `MatchRecord` finds it, settled and written on leaving.
- [x] Each feat. In a moment: a cash-out at ×10 and one of exactly 7 chips (`bank_completed`), a
      full hand (polled), a rare card burned, a pot of 200 driven off every Junction alive (after
      `bank_started`, polled against the pads' radius). Over a map, from `MatchRecord.record` through
      `LoyaltyRecord.map_played`, counted from where the seat came in: no death or no shot in 3
      minutes, 60% of 30 shots, a win with an empty hand, a win not leading as Last Call began, every
      respawn pick turned down, and a win in each of the three rooms (`LoyaltyState.rooms`). A Grand
      Prix won is a statistic. Off the books counts only with the story on.
- [x] Two events heard only where they happen, nothing new on the wire: `Events.joker_answered`
      (a respawn pick taken from or skipped, never a keep pick) and `Events.joker_destroyed` (the
      menu's burn, a client's own included, and a card given up at a full pick), in
      `NetEvents.LOCAL`. The Yard's Lost Property bet names its room by its id, `the_yard`.
- [x] Tests (`tests/test_loyalty_record.gd`): each feat for a seat here, a linked seat into its own
      profile, a guest and a bot into nothing, a test's room nothing; off the books with the story
      off; a map written down keeps and settles its feats. A client hears the cash-outs it counts as
      relayed events and polls its own kart, so it counts as a host does. Full suite 1309 green.

### L3: the table's deck and items [8.9, 3.7, 7.1, 8.8]

- [x] `Joker.starting_deck` in the twenty cards' data; `JokerCatalog.dealing()`, so the offers, the
      hot table's throws and the Garage's joker pad deal the deck while every joker is still known
      by id; `Loyalty.deal_table` in the match scene, the lobby and the Garage (the driving school
      keeps its lesson's own catalog).
- [x] The item pads' roll from the table's later items (`Loyalty.items_from`); the lobby's Items row
      hidden, and Basic, until the profile has added one.
- [x] The catalog's face-down card that is not in the deck yet says so, with the program's name by
      stage and the bet that adds it (`StoryLines.PROGRAM`, `Loyalty.bet_of`).
- [x] Each client's additions told to the host as it comes in and after every map
      (`HostControls.tell_unlocks`, a new message); a dedicated server deals from the say's, taken
      as each map starts [9.3a].
- [x] Tests (`tests/test_loyalty_table.gd`): a fresh profile is never offered or thrown a card
      outside the twenty, and only the first set; won landmarks add their cards and items; a room
      deals the profile playing's table; names off the wire cleaned; the host keeps a let-in
      client's additions only; a dedicated server deals the say's deck, the next one's once the say
      moves, and the starting deck with nobody holding it; the lobby's Items row; bets read with
      their counts. A client's own program moving on in a host's game is L2's (its record counts
      its own seats whoever deals). Full suite 1318 green, `make multiplayer` and `make
      server-check` ok.

### L4: the dress the program pays [8.9, 4.4]

- [x] The new paints, hats, flags and trails of GAME.md 8.9 (`KartDress`, `ExhaustSmoke`): the
      paints as tones of the color never under the shade, each with a scale of its own so a suit or
      a pair of stripes reads (`PAINT_SCALES`); the hats and flags of primitives; the ace's face
      drawn per color. The gold plate frame (`KartVisuals.frame_plate`, a lit gold rather than a
      metal, which read brown); the chalk and dashed tire marks (`TireMarks.look_for`, a look per
      kind and the distance along a run in the second UV for the dashes); the card backs
      (`CardBack.STYLES`, the profile's `LoyaltyState.card_back` as far as won, `CardBack.worn`).
- [x] `KartStyle` grown to six parts (`FRAMES`, `MARKS`, `EVERYBODY`, `allowed`, `next`), read from
      four numbers as before; the stalls step a seat through `Loyalty.dress_of` its owner's, a
      client's from what it told the host (`HostControls.tell_unlocks` carries the dress too;
      `PeerSeats.peer_at`); bots the plain ones; six numbers on the wire.
- [x] The respawn pick dealt face down in the profile's card back, turning over inside its half
      second [3.7] (`JokerPicker._deal`, `_turned`); a keep pick is not dealt.
- [x] Looked at in pictures (scratch `dress_shot.gd`): every hat, paint and flag on display models,
      eight colors from the arena camera's distance, the frame from behind, the three tire marks,
      the three backs. Fixed on looking: the visor's band, the hard hat's dome, the goggles, the
      paper hat's size, the fin's, the dice's, the ace's face (a box spreads one picture over six
      faces), the frame's gold, the paints' scales, the pencil's strokes, chalk's brightness. The
      paints read at the podium's distance and hardly at the arena's, as the old ones do.
- [x] `++ --loyalty-all` and `++ --loyalty-won=<ids>` in a debug build (`Loyalty.read_arguments`).
- [x] Tests (`tests/test_loyalty_dress.gd`): what everybody has and what is won, by the names the
      map pays; the next choice skips what is not won; bots in what everybody has; whose dress a
      seat wears, here, a guest, a bot, a client at a host; a stall steps through what is won;
      every piece built, a pattern never under the shade; the frame on and off, none on the L; the
      marks' looks; a back worn once won; a fresh pick dealt face down and turned over inside the
      half second. Older tests now read six numbers. Full suite 1328 green, `make multiplayer`,
      `multiplayer-lag`, `server-check`, `smoke`, lint and format ok.
- [x] The user's notes on the pictures, 2026-10-08, not at the machine and judging by pictures:
      every hat pictured from the front and the side; the paper hat folded from newspaper, a
      pyramid of printed paper, a triangle across the head on its band; more contrast in the paints
      (`SHADE` 0.55 to 0.4, the patchwork's tones wider); the ace's spade always black; the dice on
      strings tied to a crossbar off the pole, pips on all six faces (a 3x2 atlas, as a box lays a
      picture over its faces); flags, the windsock and the dice moving (`DressSway`: cloth and the
      sock round to the wind with a spring, hanging when still, fluttering with speed; the dice
      pendulums thrown by the kart's change of speed); the gold plate the plate itself in gold
      (`LicensePlate.gold`) rather than a rim; the stalls early, seven in the lobby (from (4, 1)) and
      the Garage (from (6, 15)), the card back's this machine's own (`StyleStalls._turn_back`); and
      four old pieces made winnable, Checks, Top hat, Checkered and Confetti (`KartStyle.EVERYBODY`
      now lists who has what; `LoyaltyLandmark.also` pays them beside cards on B, I, M and n). Then,
      mid-round: no spikes on the crown (a band, a velvet cap, balls on the rim); the goggles face
      ahead; spots and suits were blurred, by triplanar blending (`uv1_triplanar_sharpness` 8 and
      anisotropic filtering) and by being drawn in pixels (now in proportions, four samples a pixel);
      the suits still showed none, a suit being bigger than the kart's parts (`PAINT_SCALES` 1.5,
      found by a picture of three scales), and then still did not read, dark color on color: now
      printed near black (`SUIT_INK`, the one pattern under the shade), chosen over cream suits on
      the color, which read as well but turned a kart half white. Pictures: scratch
      `dress_shot2..6.gd`, `suits_shot.gd`. The machine drew one frame a second with its screen
      locked, so the pictures count frames, few of them, under `--fixed-fps 60 --disable-vsync`.
- [x] The next notes, 2026-10-08: the paper hat a little lower; the ace's spade and the suits'
      had no stem, which was inside its own lobes (`_spade` drawn whole); one fuzzy die turned onto
      other faces than the other's; and the suits still a mess, so in place of a pattern three
      stickers, as the user asked, one on the nose and one on each side (`KartStickers`): a suit of
      `SuitArt`'s on a cream disc with an ink rim, laid on the body's own faces (those within
      `DEPTH` of the sticker that face its way, copied `LIFT` out, the picture projected on from
      the way it faces), the nose's lower slope and the slanted outside of each pod between the
      wheels. The flat panels beside the cockpit were tried first and were behind the driver's legs
      and the front wheels, found by rays into the model (scratch `kart_rays.gd`, `kart_rays2.gd`).
      The ace's spades are `SuitArt`'s now too, and `SUIT_INK` and the pattern's suits are gone.
      Pictures: scratch `views_shot.gd`.

### L5: the dialog [8.9]

- [x] `LoyaltyDialog` (`scenes/loyalty/`) over the title, the first of Extras' buttons once the
      profile is welcomed, and a room's pause menu, over Settings; the map, `LoyaltyMapView`, in
      the house print drawn at the zoom, columns and rows with landmarks wide and tall and the rest
      narrow and short; its districts named, the signs of `LoyaltyArt` (marquee, road sign,
      motorway sign, Kit's pencil box), closed pale, open with the bet's label and bar, won
      stamped; the house's roads double lines as bars (lines met with seams), faint ones one
      lighter line, Kit's in pencil; the creases; the roundabout's ring and pot. Off the books'
      rows are not laid out with the story off. `LoyaltyLandmark.title`, a name each, in the
      generator; `LoyaltyMap.runs()` and `path()`; `Loyalty.standing`, `progress`,
      `progress_text`, `nearness`, `has_fresh`.
- [x] The cursor, `LoyaltyCursor`: the profile playing's first kart on a sheet of its own, seen
      from above at a slant, turning to face the way it drives, quick, a long run no longer than
      0.8 s, standing before a sign on the road it came in by; the arrows, the stick or the cross
      drive it by the first step of each road, a click or a tap along the fewest roads. The mouse
      and a finger drag, the wheel, a trackpad and two fingers zoom, minus and plus or a pad's
      shoulders too. The pane, `LoyaltyPane`; the List switch with the details key, `LoyaltyList`;
      NEW tags on landmarks, Extras and its button (`CatalogCell.tag`). Where the cursor stood and
      whether the list is up kept for the run.
- [x] Tests (`tests/test_loyalty_dialog.gd`): the cursor's roads, a click's route, a road's cells,
      off the books with the story, the pane's words, a bet's progress in its units, the list's
      order and a row pressed, the NEW tags kept, the name by stage, Back keeping where the
      cursor stood, the pause menu's button. Full suite 1343 green. Pictures: scratch
      `loyalty_shot.gd` (`-- --story` for off the books) and `title_shot.gd`.
- [x] The user's first look, 2026-10-09: "looks quite bare bones and a bit too systematic". A second
      look: `LoyaltyMapLayout` works out where everything goes once as the map opens (landmarks
      and bends a little off the grid, roads through them wandering and rounded, signs as wide as
      their names, washes with a hand's edge, side streets, the little drawings clumped in the
      country, the compass, the legend, the title block); `LoyaltyMapArt` draws it under the
      zoom's transform; the words are printed at the zoom's own size. Roads gold inside, unopened
      ones dashed. Test: the layout's roads, washes, drawings clear of signs, the same each time.
- [ ] Open for the user: the landmarks' names (GAME.md 8.9's table), written for this phase; and
      whether the second look is the map they had in mind.

### L6: the welcome [8.9; STORY.md 6.6b]

- [x] `LoyaltyWelcome` (`scenes/loyalty/`): the dark table, the House's letter slid in from below,
      `LoyaltyLetter`, with the card glued to it, `LoyaltyCard` held as the invitation's is
      (`HeldCard`, its foil shining where its shine picture says), the invitation's two spotlights
      flickering on over it (`OpeningInvitation.draw_beams` and `draw_pool`, made static to be
      shared), and Activate card; a press brings it all at once, Back does nothing, the cursor stays
      on the button. Activated: `LoyaltyWelcome.join` (welcomed, the member number kept, settled,
      saved); the card peeled up off the letter from a corner and lifted, turned over once to its
      stripe and its signature, the letter dropped as the lights go out; the map opened unfolding
      (`LoyaltyDialog.open(parent, true)`), the card carried onto it on a layer of its own, turning
      back to its face, to its place in the map's corner (`LoyaltyDialog.card_corner`, over the
      pane, given up where the room is short). Due once the profile has played a map (the
      statistic `maps`) and is not welcomed, under the warm-up's pane, after the invitation and
      never with it; never where nothing is drawn. `++ --loyalty-welcome` shows it again.
- [x] The title's Extras gain the program's button once the map the welcome opened is put away.
      The letter's words in `StoryLines.WELCOME_LETTER`; `LoyaltyState.laps` read and written now
      for the card's LAP.
- [x] Tests (`tests/test_loyalty_welcome.gd`): due after the first map and not before, not
      welcomed twice; the member number the invitation's, or one like it, kept; joining settles;
      the ceremony to the map with the card in its corner; at the title after the invitation and
      the button after. Full suite 1349 green. Pictures: scratch `welcome_shot.gd`.

### L7: settling [8.9, 3.8; STORY.md 6.6b]

- [x] BET WON in the player's corner, `LoyaltyStamp`, beside the block as NOTE COLLECTED goes, for two
      seconds, a second one beside the first; a pencil tick on a scrap off the books. Known there
      and then by `LoyaltyRecord`, four times a second: a feat as it is done, a count as the room's
      own statistics take it past the bet (`Loyalty.is_met_live`, `LifetimeStats.live_value`,
      `MatchRecord.since_of`), once each, an open bet only and a welcomed profile's only; won as
      the room is written down, as before (`signal bet_won`).
- [x] The slip's page, `LoyaltySlipPage`, after the map's and the run's: `LoyaltyRecord` keeps each
      profile's program as the room finds it and, once `MatchRecord.record` has settled, reports
      each welcomed profile that won a bet or came nearer one (`settled`, `report_of`, `signal
      reported`), which the results screen prints a moment after the whistle, the House's bets
      won stamped WON with what they paid, the three nearest with their bars. Off the books,
      Kit's scrap of graph paper taped over the program's page or, with none, the map's, its bets
      in pencil (`tape_onto`: a strip of no height at the page's top, so it takes no room).
- [x] The four endorsements, `LoyaltyLandmark.endorsement` in the data (DRIFT, CLEAN RECORD,
      MARKSMAN, ADVANCED), stamped small in red in a row under the license's stripe
      (`LicenseCard.program_stamps`, `Loyalty.endorsements_of`).
- [x] The words by stage, `StoryLines.REWARD_DRESS`, `REWARD_CARDS` and `REWARD_ITEMS` through
      `Loyalty.reward_words`; the story off is stage 0 as everywhere. Power-ups, added to STORY.md
      6.6b at the user's word: NEW POWER-UPS ON YOUR TABLE, then the cards' words.
- [x] Tests (`tests/test_loyalty_settling.gd`): the words by stage, a statistic counted live, BET
      WON there and then once and not for a closed bet, the settling reported (House's, Kit's,
      nearer), the page and the scrap, the endorsements on the license, the stamp in the corner.
      Full suite 1356 green. Pictures: scratch `slip_shot.gd`.

### L8: Lost Property [8.9; STORY.md 6.6b]

- [x] `LostProperty` (`scenes/loyalty/`), in every map of the match scene and the driving school
      (as `LostProperty.SCHOOL`, the school being the Garage's room set for the test): as the flag
      drops it decides for the profile playing whether the thing of its room lies on the floor, once
      its landmark is open and not found, on an even chance or for certain after two misses
      (`LoyaltyState.lost_waits`, kept). Its spot is worked out, not drawn into the grids: bare floor
      in the karts' region, clear as a note's is, as far from the Junction as it lies and up against
      walls and crates, the same every time for the map (`spot_on`). The thing is the dress itself
      as it lies (`KartDress.lost`): the cone on its side, the hard hat upturned, the tape run out,
      the dice on their string; half as big again. Taken by this machine's human karts only, found
      for every profile here with it open, kept there and then; BET WON follows from the record.
- [x] The manila tag beside the clock, `LostTag`, off the left of the board as Kit's scrap is off
      the right: FOUND, the room and the thing, UNCLAIMED, from stage 2 the story's line
      (`StoryLines.LOST_*`); stamped CLAIMED once taken, and gone. The bets say roughly where. The
      Yard's hard hat blows off the hoarding once its landmark is open, its hook left empty
      (`RoomShell.hat_blown_down`).
- [x] Tests (`tests/test_lost_property.gd`): what was lost where, due once open and certain after two
      misses, a spot of its own, taken by this machine's kart and not a bot's, a miss counted, the
      hard hat blown down, each thing built. It lies outside the pickups the host keeps, so nothing
      is sent. Full suite 1363 green. Pictures: scratch `lost_shot.gd`.

### L9: off the books and the loose notes [8.9; STORY.md 6.6b, 7.3]

- [x] The pencil roads and ticks, shown only with the story on and a note found: the map's, L5, the
      corner's tick and Kit's scrap on the slip, L7; a bet off the books counts only with the story
      on, L2.
- [x] The loose notes, `StoryNotes.LOOSE_KEYS` numbered from `LOOSE_FROM` (101), keys of their own,
      never in `KEYS`, so never `next_of`: their words from STORY.md 7.3 in `NOTES`, Member No. on a
      new paper, `half_card`, the white back of a loyalty card cut in half with its stripe. Due in
      the order their bets were won, `loose_due`; dealt only with no note of the story due,
      `to_deal`, which `NoteDealer` deals by, turning up as any note does and filed as any is; in
      the folder after the story's notes in the order found, before the pages kept at the back
      (`NotesFolder.in_order`). The program's bets of notes found count the story's notes alone
      (`StoryState.story_notes`).
- [x] Tests (`tests/test_loose_notes.gd`): their own keys and never the next note, due once their bet
      is won and not with the story off, never in the story's place, the back pocket's order and the
      profile keeping them, not counted as the story's. Full suite 1368 green. Pictures: scratch
      `loose_shot.gd`.

### L10: the Showroom [8.9, 9.4]

- [x] `Showroom` (`scenes/loyalty/`), added by the Garage: shut, the roller door down across the
      middle of the Garage's back wall, corrugated with a gold band, under SHOWROOM, MEMBERS ONLY;
      open once the Department's keystone is won (`Loyalty.showroom_open`), the Garage is laid out
      as `data/maps/garage_showroom.tres` (written from the Garage's by scratch
      `make_showroom_map.py`): a bay as wide as the Garage, five rows deep, behind its old back wall
      made a partition with a six-cell way in, the door rolled up into its housing over it, a red
      carpet to a turntable under its own lamp. A kart of this machine's left standing on it is
      turned slowly round and looked at up close, `ShowroomView`: the kart in its dress and plate
      turning in a frame at the side of the screen, what it wears named under it. The stalls are
      the Garage's own along the front wall, moved down with the bay. The arena's camera is left
      alone: its close follow does not hand back cleanly, and the frame is the closer look. The
      user, 2026-10-09: keep it so for now; a camera zoom onto the turntable may come later.
- [x] Tests (`tests/test_showroom.gd`): open once its keystone is won, the bay's layout the Garage's
      with the partition and the way in, the door down when shut, the turntable turning a kart and
      showing it, what the kart wears. Full suite 1373 green. Pictures: scratch
      `showroom_shot.gd` (`-- --shut`).

### L11: the roundabout and editions [8.9]

- [x] The ring, `Loyalty.settle_ring` at the end of every settling: dealt as both keystones are won
      (`ring_open`), seven bets from `RING_POOL` (the Strip's and the Department's counts), drawn the
      same for the same member and lap, each counted from where its statistic was as it was dealt
      (`LoyaltyState.ring`, its `from`), counts half as much again each lap and rounded to two
      figures; all seven met is a lap: `laps` up, an edition `owed`, the ring dealt again; nothing
      reset. LAP on the card (`LoyaltyCard`), on the license's back after the endorsements, on the
      pot on the map, and on the slip's page (`report_of`'s `laps`).
- [x] The roundabout a stop of the cursor's (`Loyalty.ROUNDABOUT`), driven to from the keystones on
      its roads; its pane (`LoyaltyPane.show_roundabout`): how it opens, or its lap, its seven bets
      as they have come, what a lap pays and Choose an edition while one is owed; the ring's bets as
      badges over and under it on the map, filled as they come.
- [x] Editions, `LoyaltyEditions` over the map (A at the roundabout too): the profile's won paints,
      hats and flags, each to the finish it moves up to, `Loyalty.spend_edition`; kept in
      `LoyaltyState.editions`. The finishes, `finish.gdshader`, a sheen added over the piece as a
      second pass so the color stays the color: Foil a band of warm light and its edges lit,
      Holographic colors turning with the angle, Polychrome bands drifting; in the warm-up. On the
      wire as numbers after the style's six, only where there is one (`KartStyle.finishes`,
      `to_array`), put on a seat's style from its profile (`Settings.seat_style`,
      `Loyalty.with_finishes`), never kept with it, and told to the host with the unlocks
      (`editions`) so a stall's step at the host puts the piece in its finish
      (`Loyalty.finish_for`). The plate, the trail and the tire marks take a finish too, at the
      user's word (2026-10-09): the gold plate the sheen over it, the trail a color ramp
      (`ExhaustSmoke._finish`: Foil a gold glint, Holographic through the colors as a piece lives,
      Polychrome a color for every piece), the marks a faint tint in their shader.
- [x] Tests (`tests/test_roundabout.gd`): the ring dealt as it opens and counted from then, a lap half
      as much again with nothing reset, an edition up the three finishes and no further and kept,
      the finishes riding with the style, a finish as a sheen over the piece, the roundabout on the
      map and in the pane. Full suite 1379 green. Pictures: scratch `ring_shot.gd`
      (`-- --finishes`).

### L12: wrapping up

- [x] Debug arguments in a debug build, in the README: `++ --loyalty-all`, `++ --loyalty-won=<ids>`,
      `++ --loyalty-welcome`, `++ --loyalty-lap=<n>` (every landmark won, lap n, an edition owed a
      lap and the ring dealt for it; `test_roundabout.gd`).
- [x] CHANGELOG (Unreleased, Added), the branch rebased on master after 0.14.2, `make check`,
      screenshots for the user. The wire changed (the styles' finishes, the unlocks' editions), so
      the release it goes out in is a minor one.

### Play-test round 1 (2026-10-09)

The user's notes after playing it, and the answers to the questions after L12, all done:

- [x] Bets: D cash out 3,000 at once; N Crazy Eights, hold 8 jokers (`jokers_held`); three more of
      Kit's, left on the floor (graph-paper paint), no strings (pencil tire marks) and house money
      (the doodled card back), off the roads of empty handed and walk away. NEW POWER-UPS ON YOUR
      TABLE. Finishes for the plate, the trail and the tire marks too.
- [x] The map: Kit's district on a sheet of its own, graph paper (`LoyaltyMapLayout.Sheet`), its
      roads into the House's off its foot; tabs and Tab between the sheets; road-atlas roads on
      the House's, double pencil lines on Kit's; the legend's Kit's pencil drawn in by hand once it
      shows; the cursor a paper cut-out (`paper_cutout.gdshader`), slower and in the background, the
      pane saying a landmark at once; Select landmark in the binds; the roundabout at the head of
      the list for good; pinning (`LoyaltyState.pinned`, `PinnedStrip`, the pause menu's line).
- [x] The card: its lamp light and lines kept in its corners, the chip shining, the signature
      strip's stripes cut at its edges, its full view off the corner with the license's buttons
      (`LoyaltyCardView`), turning over as the license does (`HeldCard.turn_over`) and back face up
      on the way down.
- [x] The welcome: the lamps aimed at the card's rest (they were drawn once, mid-slide), the card
      glued on the letter's sheet and tilted with it, torn off in jerks with a peel
      (`HeldCard.peel`), its spot and torn paper on the letter, held longer front and back; "Members
      return."; the letter in Kit's folder with a barcode on its back.
- [x] Elsewhere: flags beat round the pole; the Showroom door framed, its grooves kept on it; Kit's
      scrap at the foot of the slip's page signed —K.; a pane dealt in after the frame that builds
      it (`MenuTheme.deal`); the Catalog's NEW tag; the debug page called Debug, with the loyalty
      program's buttons; `++ --loyalty-near` and `++ --loyalty-lost`.
- [x] Fixed on the way: a loyalty record left headless wrote the player's settings; a client's own
      dropped joker never heard (`Events.joker_left`, local); the debug arguments numbered no card.
- [ ] Later, the user's word: a camera zoom onto the Showroom's turntable.

### Play-test round 2 (2026-10-09)

The user's notes on the second build, all done:

- [x] The map's sheets as index tabs on its top edge (a `TabBar`, the settings' look), turned with
      Tab or a pad's shoulders drawn at their end; the pad's zoom on the triggers, a notch a pull.
- [x] Kit's two roads in pencil up off the top of the House's sheet to "to Kit's map" once his
      sheet is drawn, the doodles kept clear of the words.
- [x] The roundabout at the foot of the list; the kart redriven from where it is to a landmark
      chosen on the way, back the way it came if that is shorter (`_drive_from_here`).
- [x] An edition owed calls: NEW on the title, the program open on the roundabout, its rings going
      out (`LoyaltyBeacon`), its row saying it and opening the editions, accept's key on the
      edition's button.
- [x] What is pinned on a scrap of the map's paper under the pause menu (`PinnedNote`), and the
      strip beside the clock at 1880 logical pixels and wider.
- [x] The Showroom's turntable turns the kart itself; the loyalty card beside the license in the
      settings' License tab (`LoyaltyCardView.corner`).
- [x] Then: the roundabout printed pale until it opens; a click on the pause menu's note opens
      the program on the map at the pin (`LoyaltyDialog.open(parent, unfold, at)`).
- [x] Speed: the sheet drawn once into a picture at the zoom it rests at (`LoyaltyMapBake`), only
      what moves drawn over it; dashes as one multiline and dots and bulbs from one soft dot
      (`LoyaltyArt.dots`); the kart's sheets drawn only as it turns; the pinned note and strip
      drawn only when they change. Driving and scrolling went from 13-18 fps to the screen's 144.

## M11: achievements

GAME.md 8.10 is the design, STORY.md 8.7 the story's side of it. Asked for by the user on 2026-10-13,
after 0.15.3: achievements beside the loyalty program, earned in any order and at any time, paying
nothing, each a situation to get into and see through, with a title, a clear objective and a picture of
its own, a bar where one fits, a few hidden ones that are the story's and cannot be missed, kept in the
profile with linked seats earning their own, a dialog that lists and sorts them, a toast in a corner as
one is earned, and the stores later, with pictures for their pages. About 30; at most two related; one
or two really hard and no grind. Built in worktree `.claude/worktrees/achievements`, branch
`achievements`, from master at 63122598. A task names the GAME.md section it builds, in brackets.

### Progress

| Phase | What | State |
|---|---|---|
| A0 | The record: the list as data, what a profile keeps, earning and settling | Done |
| A1 | The moments of a map, and Parry's word from the host | Done |
| A2 | Chips, pins and a picture for each | Done |
| A3 | The toast | Done |
| A4 | The dialog, the Clubhouse and the License tab | Done |
| A5 | Credited already, and the story's four | Done |
| A6 | Debug arguments and the Debug tab | Done |
| A7 | Store pictures and the text file | Done |
| A8 | Wrapping up | Done |

### Questions, and the answers

Asked on 2026-10-13 with a default each, after a first list of 33. Answered the same day: the
defaults, with the remarks under them.

1. Outside the story, the same words at every stage and with it off; only the hidden four touch it.
   Default.
2. Commemorative chips. The user: chips, and enamel pins for special ones, the story's perhaps, or
   mixed up some other way. Built as pins for the story's four and chips for the rest, the chip's
   color its denomination: white, red, green and black by what it took.
3. One not yet earned shows its own picture in gray. Default.
4. Hidden ones share a scrap of Kit's graph paper taped shut, a pencil question mark on it. Default.
5. Achievements in the Clubhouse after the Catalog, and a section on the License tab, which is the
   pause menu's way in. Default.
6. A large dialog like the catalog's, a row each, no side pane. Default, and filling the screen on a
   small one as the other dialogs do.
7. Sort: in order by groups, Earned first, To do; remembered by the machine. Default.
8. Hidden ones as Hidden achievement rows at the end. Default.
9. NEW tags; the count with a gold tick. Default.
10. The toast: a chip tossed in, ACHIEVEMENT UNLOCKED and the name, 3.5 s, queued; beside the seat's
    corner in a room, the top right corner elsewhere. Default, with a sound.
11. Our toast as well as a store's own. Default.
12. Counted where the statistics count; the catalog's two where the catalog counts. Default.
13. The profile playing and each linked seat their own; guests and bots nothing; each machine its own
    seats. Default.
14. Credited from the records already kept, quietly, one toast saying how many. Default.
15. The story off earns none of its four and leaves Kit's district out. Default.
16. `[achievements]` in the profile, ids that never change, unknown ones kept. Default.
17. A store layer now. The user: later, but described: GAME.md 8.10, On a store.
18. The profile playing's alone to the store, said again as it starts playing. Default, and only
    ever more: switching to a profile with fewer takes nothing away from the store.
19. Bars to the store as statistics. Default.
20. `make achievement-art` for the stores' pictures. Default, with a text file of every id, name and
    objective as well.
21. All 33, no spares. The user: keep all for now, and add three of the spares, Long Shot, By a Nose
    and Full Table, with bots counting toward Full Table's eight.
22. A Real Handful at nine. Default.
23. Most Valued Member the House's thirty landmarks. Default.
24. A Fresh Start the story's 26 notes. Default.
25. Dressed to the Nines all seven parts at once. Default.
26. Parry's new word from the host, and with it a minor version. Default: the next release is 0.16.0.
27. GAME.md 8.10, STORY.md 8.7 and this milestone, then built. Default.

The user's remarks with the answers:

- **Too simple.** "Many of these achievements are a bit too simple. I feel like I can complete a big
  portion of them in a single map without paying too much attention." Every moment was made one to
  set out for: Flawless in place of Beginner's Luck (a first win against one kart), Bank Shot off two
  walls (a bullet bounces only with a card or an item, 5.1), Parry five in a life, Payback three times
  in a map, Untouchable at eight (was On Fire, five), Set and Forget two to one turret, Push Comes to
  Shove three in a map, A Pit. Do Not. with a pot of 1,000 in it, Stacked two full stacks at once,
  Asking for Trouble a win with them, Hit the Jackpot a pile of 100 or more, Most Wanted a cash-out of
  1,000 under a bounty, and against three or more for every win.
- **Two more.** Push Your Luck, a pot worth three times the target score; and Front Row, an online map
  watched from flag to whistle, "only if this is fun": kept, with an emote sent while watching so
  there is something to do.
- **Last Kart Standing** against three others or more.

### Decisions fixed for implementation

- **The list is data.** `Achievement` (`scripts/achievements/achievement.gd`), a resource: `id`,
  `title`, `objective`, `group`, `chip` (white, red, green, black, the House's pin, Kit's pin),
  `hidden`, `count` for a bar; every one in `data/achievements/list.tres` in its group's order, the
  way `data/loyalty/map.tres` holds the landmarks. The store's name is the id in capitals.
- **`AchievementState` in the profile.** A `[achievements]` section written by `Profile`: `earned`, id
  to the Unix time it was earned, and `fresh`, earned and not yet looked at; `credited`, once the
  records have been read for it. Ids this version does not know are kept and never shown.
- **Earning is one function.** `Achievements.earn(profile, id, slot)` writes it, marks it new, saves
  the profile at once (never headless) and says so on `Events.achievement_earned`, a local event; the
  toast hears that and nothing else. `Achievements.settle(profile)` earns whatever the records show,
  the profile's license, catalog, loyalty state, dress and story, and is called wherever those change
  and as the title comes up. `Achievements.progress(profile, achievement)` is a bar's count.
- **`AchievementRecord` hears the moments.** A node beside `MatchRecord`, `CatalogRecord` and
  `LoyaltyRecord`, in the match scene, the lobby and the driving test, with their guards: the current
  scene's, never headless, never on a dedicated server, `anywhere` for a test. It finds each seat's
  profile as `MatchRecord.profile_for` does, keeps a little state for each seat over a map and a life,
  hears `Events`, and reads the hand, the pot and the pad itself on a short beat for what no event
  says. A client hears what a host does: every event it needs is relayed already but one.
- **Parry's word.** `BulletSystem` cancels two bullets on the host only. `Events.bullets_met(a, b)`,
  the two owners, relayed to the clients with the rest, `NetEvents.RELAYED`: the one wire change, so
  the release after it is 0.16.0.
- **Pictures are drawn.** `AchievementArt` draws a chip, a pin, the gray of one not yet earned and the
  hidden scrap, each picture from `AchievementIcons` on `IconShapes` as `LandmarkIcons` does, so a
  picture serves a row, the toast and a store's page alike.
- **One toast for everything.** `AchievementToast` queues what is earned and puts each up beside the
  seat's corner block in a room, after a `LoyaltyStamp` there, or at the screen's top right corner
  anywhere else, on a layer of its own over the dialogs and under the loading screen.
- **A dialog on a layer of its own.** `AchievementsDialog`, a `CanvasLayer` as `CatalogDialog` is,
  opened with `AchievementsDialog.open(parent)`; its sort kept in the settings.

### A0: the record [8.10, 8.5]

- [x] `Achievement`, `data/achievements/list.tres` with the 39 of GAME.md 8.10; a bar's count is
      the game's own, every joker there is, so it grows with the game.
- [x] `AchievementState` and `Profile.achievements`, read and written with the rest, unknown ids kept.
- [x] `Achievements`: the list, `find`, `earn`, `settle`, `progress`, the records' achievements
      (license, endorsements, catalog, dress, districts, the House's map, the lap, the story's four),
      the story's four only with the story on.
- [x] Tests (`tests/test_achievements.gd`): the list is whole and its ids unique; earned once,
      written and read back, unknown ids kept; each record's achievement earned by its record and not
      before; a bar's count; the story's four off with the story off and earned as it comes back on.

### A1: the moments [8.10, 3.4-3.13, 5.1, 7.1, 7.3]

- [x] `AchievementRecord` in the match scene, the lobby and the driving test, the profile per seat;
      in the Garage too, settling the records alone, the cards found and the dress worn there.
- [x] Each moment: the wins (Flawless, Beat the House, Clean Sweep, Last Kart Standing, All In, By a
      Nose, Asking for Trouble), the tables' (Push Your Luck, Point of Sale, Hit the Jackpot, Most
      Wanted), the fights (Bank Shot, Parry, Long Shot, Payback, Untouchable, Two Birds, Set and
      Forget, Push Comes to Shove, A Pit. Do Not.), the hand (A Real Handful, Stacked) and company
      (Plus One, Long Distance, Full Table, Front Row).
- [x] `Events.bullets_met`, raised by `BulletSystem` and relayed; `Events.watched_emote`, local,
      for a watcher's own emote.
- [x] Tests (`tests/test_achievement_moments.gd`): each moment earned by its situation and not by one
      just short of it; a guest's and a bot's earn nothing, a linked seat's its own profile's.

### A2: chips, pins and pictures [8.10, 8.3a]

- [x] `AchievementArt`: the chip in its four colors, the House's pin and Kit's, the gray, the hidden
      scrap; `ChipArt.chip` takes the notches' color, a white chip's being blue.
- [x] `AchievementIcons`: a picture for each of the 39, no two alike. A kart is drawn from the
      side: from above, at a picture's size, it read as a blob.
- [x] A sheet of every one, earned and not, looked at: `make achievements`.

### A3: the toast [8.10, 8.3]

- [x] `AchievementToast`: tossed in, ACHIEVEMENT UNLOCKED and the name, queued, beside the seat's
      corner or at the top right, the profile's name for a linked seat, the clack and the chime;
      `AchievementToasts` under [Game], layer 45, puts them up one at a time, and the camera keeps
      the karts out from under one in a room (`HudCovers`).
- [x] Tests (`tests/test_achievement_toast.gd`): queued one at a time; beside the seat in a room,
      under a BET WON there; at the top right elsewhere.

### A4: the dialog [8.10, 3.8, 8.5]

- [x] `AchievementsDialog`: head, count and tick, Sort; the case and its rows, bars and days; groups;
      hidden rows; NEW tags; the cursor, the wheel, the stick and a finger; the short screen. The case
      is felt, flecked and stitched with brass corners, the headings brass plates, an earned row
      stamped EARNED in red (`AchievementRow`); the order kept in `Settings.achievement_order`.
- [x] Achievements in the Clubhouse after the Catalog with its NEW tag; the License tab's section
      beside Story, the cursor walking to it.
- [x] Tests (`tests/test_achievements_dialog.gd`): every row there in each order, hidden ones last;
      NEW gone once looked at; Back puts it away.

### A5: credited already, and the story's four [8.10; STORY.md 8.7]

- [x] Settled where the records change: the driving test's pass, a note found, the stamp, a map after
      the ending, the program's settling, a stall's dress, the catalog. The rooms settle every half
      second; the stamp and the test's pass at once; no toast over the ending's last lines
      (`LastLines.GROUP`).
- [x] A profile from before credited as the title comes up, one toast saying how many
      (`Achievements.arrive`, `AchievementState.credited`); a linked one as it first sits down.

### A6: debug [8.10]

- [x] `++ --achievements-all`, `++ --achievement=<ids>`, `++ --achievements-none` and
      `++ --achievement-toast=<ids>` in a debug build; the Debug tab's buttons; the README's rows.

### A7: store pictures and the text [8.10]

- [x] `make achievement-art` (`scenes/dev/achievement_export.tscn`): every chip and pin earned and
      not, and the hidden scrap, on the house's stock under a soft light, at 1024 px and cut to 256
      and 64, into `build/achievements/`, with `achievements.txt` and `achievements.csv` beside them
      and a `.gdignore` so the editor never imports them.

### A8: wrapping up

- [x] CHANGELOG (Unreleased, Added), `make check`, `make multiplayer` for Parry's word, pictures for
      the user.
- [x] The online check under a round trip (`make multiplayer-lag`) failed every time on the branch and
      passed on master: its clients never reached the ready pad or their flush pads. Bisected to the
      autoload naming the toasts' class: `Game` and `Achievements`, read as the game starts, named
      `AchievementToasts`, which compiled it and the rooms it reaches into with the autoloads, and a
      cycle among them set something up wrong without a word. `Game` makes the layer from its path,
      and `Achievements` reaches it through its group; the check passed twice in a row after.

### While wrapping up, the user's three asks (2026-10-13)

- [x] A switch in the dialog to hide what is earned: Hide earned, beside Sort, its bind the hand's
      button, remembered by the machine (`Settings.achievements_hide_earned`); the case says so
      when everything is earned.
- [x] Dressed to the Nines as soon as the cosmetics are on: a stall's change, and a card back turned,
      settle the seat's profile there and then rather than on the record's next half-second look.
- [x] One more achievement: get hit ten times without dying. Tough as Nails, Fighting, a green chip, a
      heart with a plaster across it; a hit is a life lost with another left or a shield popped,
      counted over a life. Thirty-nine now.

### The user's second round (2026-10-13)

- [x] The whole dialog in green felt (`FeltArt`): a mottled, grained and fibered nap, a dark edge, a
      stitched seam and brass corners, the rows in a darker tray pressed into it. Hide earned before
      Sort, which is only as wide as it says.
- [x] The cursor's frame round a row's paper label rather than the whole row, gliding from label to
      label (`FocusGlide` asks a control's `focus_frame`).
- [x] The toast slides in from off the screen and back out; beside a seat's corner it is scaled to fit
      between the corner and what stands in the middle of the edge, or goes under the corner; it
      waits while a loading screen is up.
- [x] A sound of its own, a bell run over a few chips (`tools/make_achievement_sound`), not the
      cash-out's chime.
- [x] Street Legal as the license is stamped, not as the test is passed. Point of Sale says Match
      Point.
- [x] The dialog drawn cheaply, and kept so: every chip drawn once a run into a picture at twice its
      pixels (`AchievementArt.drawn`), its size rounded up to a step of 32, and shown from that. About
      1,020 draw calls a frame down to about 210, 1.26 ms a frame to 0.6. `make achievements-bench`, now `make dialog-bench`,
      fails above 300, GAME.md 10.7.

### The card table (2026-10-13)

The felt inside felt read oddly. The user compared the felt alone, a walnut table (dropped: it read
as gray noise), a leather rail, and the menu's pane with the felt inside; then brown against black
leather, a fade against a printed line, and three button looks (leather tabs, printed on the felt,
casino plaques).

- [x] The pane a card table: felt inside a padded brown leather rail (`LeatherArt`, one mesh with
      gold stitching along both edges), cut by the screen's edges where the pane fills it.
- [x] A line printed round the rows as a blackjack table's are, its motto BRAGGING RIGHTS PAY 3 TO 2
      in its foot (`FeltArt.print_line`); the scroll bar clear inside it.
- [x] The rows fade out toward an edge only while there are more past it (`AchievementsDialog.Fade`).
- [x] Sort and Back printed on the felt (`FeltPrintStyle`); Hide earned a craps puck, OFF and ON.
- [x] Revisit the draw calls once the design is settled: this dialog, measured on its final look,
      and the catalog dialog's, about 3,300 a frame. See below.

### Draw calls (2026-10-13)

- [x] `KeptPictures`, one keeper of pictures drawn once a run for the chips, the catalog's cards and
      the NEW tag; `DrawnTexture`'s keeper waits for anything drawn rather than its middle.
- [x] The catalog's cards as pictures, every card face down in one back sharing one: about 3,300 draw
      calls a frame down to about 490. The large picture by its pane stays drawn as itself: as a
      picture for each card it stuttered the cursor for 30 draws saved.
- [x] `make dialog-bench` for both dialogs, budgets 300 and 800, with the opening's longest frame.

### The toast: opened from, a ticket, a stamp and a bell (2026-10-13)

- [x] A toast clicked with the mouse opens its achievement in the dialog: over a room's menu, put up
      first, on the title over it, in the dialog if one is up; a seat's toast, that seat's profile's.
      Not a finger's tap.
- [x] The pause menu and the dialog name each other only by group and by path: naming each other's
      classes is a cycle among the rooms' scripts, the kind that broke `make multiplayer-lag` when
      the toasts were named in `Game`.
- [x] The toast an admission ticket: a felt stub torn off along a perforation for the chip, its toss
      kept, EARNED stamped in red as it arrives; its sound the stamp and a small bell, C of the
      sounds the user heard; over a room's menu at the top right, through the pause.


## Pending

Known bugs parked for later. Each one is described well enough to pick up cold.

- [x] **Settings from the pause menu does not come back to the room it left.**
      `PauseMenu` sends Settings to `Game.go_to_settings(Game.MATCH_SCENE)`, and
      the settings screen's Back changes scene to that path. Every room that
      hangs a pause menu (match, garage, waiting room, the dev driving scene) is
      freed on the way out and a fresh match scene is built from
      `Game.pending_config` on the way back. In a match that throws the match
      away and starts a new one; from the garage it lands in a match. Online it
      is worse, because the connection outlives the scene (`Net`): a host in the
      waiting room comes back into an arena that re-seats every client without
      having told them to follow, and a client comes back to "Starting the
      match..." waiting for a host that never sends it. Likely fix: open the
      settings as an overlay over the room instead of a scene change, or at
      least return to the scene that opened it and never leave an online room
      this way.
      Fixed: the pause menu opens the settings screen as an overlay over the
      room, and its Back closes it and brings the menu back. Only the title still
      changes scene for it.
- [x] **A client that connects while the host is mid-match lands in the wrong
      room.** Found by reading the code, not reproduced yet. Joining always opens
      the waiting room (`online.gd` goes to `Game.go_to_waiting`), and the client's
      room builds the waiting-room layout before it has heard anything from the
      host. `NetSession._on_peer_connected` then seats it straight into whatever
      match the host is running, so a host in an arena seats it in the arena and
      sends the arena's rules and snapshots, and the client drives round a garage
      bay while the arena's karts are drawn in it. Nothing tells it to follow:
      `match_beginning` went out before it arrived. It is also not listening for
      `back_to_room` (only the match scene is), so when the host goes back to the
      room after the podium it is left behind, unseated. Likely fix: the host tells
      a newcomer which kind of room it is in on arrival, and a client in the wrong
      one follows the same way the others did.
      Fixed: a host in an arena no longer seats a newcomer on connecting. It sends
      it the `match_beginning` everybody else followed, and seats it once it asks
      from the match scene, which listens for `back_to_room`. A full match refuses
      it in the handshake, and snapshots only go to seated clients.

## Working method

- **One milestone per branch**, small commits, GAME.md updated in the same
  commit as any rule or number change.
- **Playtests are the user's job**, handling and readability cannot be judged
  headless. Each tuning round ends with numbers written back into GAME.md.
- **Every asset gets a row** in `THIRD_PARTY.md` in the commit that adds it.
- **API doubts** are settled against the 4.7 class reference dumped with
  `--doctool`, not from memory.

## Risks

| Risk                                        | Mitigation                                                         |
|---------------------------------------------|--------------------------------------------------------------------|
| Kart handling does not feel right           | Every number in `KartStats`, live tuning panel, tuning rounds budgeted in M0 |
| Bullet cancel and bounce edge cases         | Sphere cast per tick resolves the first hit only; unit tests for reflection and ordering |
| Bots read as dumb or unfair                 | Traits and difficulty as data, reaction delay as an input queue, dodge as a probability |
| Performance with trails and 100 bullets     | Segment caps, pooled bullets, profiler check in M4                 |
| Godot 4.7 API differs from expectation      | Dump the class reference with `--doctool` and check before use     |
| Export templates for 4.7.2 missing          | Install before M4; the release workflow downloads its own copy     |
